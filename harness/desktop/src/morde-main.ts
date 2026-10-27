import { app, BrowserWindow, dialog, ipcMain, Menu, safeStorage, session, shell, Tray, WebContentsView, type Session } from "electron";
import { createHash, randomUUID } from "node:crypto";
import { existsSync, readFileSync, writeFileSync, renameSync, mkdirSync, rmSync } from "node:fs";
import { join, posix, win32 } from "node:path";
import { MordeAPI, checkedId, credentialExpired, credentialExpiresSoon, gatewayURL, localGatewayOrigin, portalOrigin, type Credentials, type WebSession } from "./morde-core";
import { checkedDirectory, MordeSync, type Mapping, type SyncCheckpoint } from "./morde-sync";

app.setName("Morde");
const userData = join(app.getPath("appData"), "Morde Client");
mkdirSync(userData, { recursive: true, mode: 0o700 });
app.setPath("userData", userData);
const zh = (app.getLocale() || "").toLowerCase().startsWith("zh");
let mainWindow: BrowserWindow | null = null;
let tray: Tray | null = null;
let credentials: Credentials | null = null;
let lastOrigin: string | null = null;
let lastInstallation: { origin: string; name: string; id: string } | null = null;
let activeProfile: string | null = null;
let mappings: Mapping[] = [];
let syncCheckpoint: SyncCheckpoint | null = null;
let profileError: string | null = null;
let syncChildPid: number | undefined;
let webView: WebContentsView | null = null;
let webPartition: Session | null = null;
let webAttached = false;
let view: "web" | "sync" = "web";
let webRefreshTimer: NodeJS.Timeout | null = null;
let credentialExpiryTimer: NodeJS.Timeout | null = null;
let authorizationCheckTimer: NodeJS.Timeout | null = null;
let logoutInProgress = false;
let exitReady = false;
const hostWindows = new Set<BrowserWindow>();
const api = new MordeAPI(() => credentials);
const sync = new MordeSync(() => app.isPackaged ? join(process.resourcesPath, "bin", process.platform === "win32" ? "morde-sync.exe" : "morde-sync") : process.env.MORDE_SYNC_BINARY || "", (state, progress) => {
  if (syncCheckpoint && progress?.session_id && /^p[a-z0-9]{7}$/.test(progress.session_id) && progress.session_id !== syncCheckpoint.sessionId) {
    syncCheckpoint.sessionId = progress.session_id;
    try { savePrivate(profileFile("sync-checkpoint"), JSON.stringify(syncCheckpoint)); }
    catch { void sync.stop(); mainWindow?.webContents.send("morde:sync-state", { state: "shutdown_unknown", message: "Could not save the sync recovery point" }); }
  }
  mainWindow?.webContents.send("morde:sync-state", { state, progress });
}, (pid) => {
  if (!syncCheckpoint) throw new Error("Sync recovery point is missing");
  syncChildPid = pid;
  syncCheckpoint.childPid = pid;
  savePrivate(profileFile("sync-checkpoint"), JSON.stringify(syncCheckpoint));
});

export function isSystemDirectory(candidate: string, root: string): boolean {
  const path = root.includes("\\") || /^[A-Za-z]:/.test(root) ? win32 : posix;
  if (candidate === root) return true;
  if (path.normalize(root) === path.parse(root).root) return false;
  const relativePath = path.relative(root, candidate);
  return relativePath !== ".." && !relativePath.startsWith(`..${path.sep}`) && !path.isAbsolute(relativePath);
}

function childMayStillRun(checkpoint: SyncCheckpoint | null): boolean { return sync.checkpointMayOwnDirectory(checkpoint); }
function priorSyncChildMayStillRun(): boolean { return Boolean(syncCheckpoint?.childPid && syncCheckpoint.childPid !== syncChildPid && childMayStillRun(syncCheckpoint)); }
function clearConfirmedChild(): boolean {
  if (!syncCheckpoint?.childPid) return true;
  if (childMayStillRun(syncCheckpoint)) return false;
  const childPid = syncCheckpoint.childPid;
  const { childPid: _childPid, ...confirmed } = syncCheckpoint;
  savePrivate(profileFile("sync-checkpoint"), JSON.stringify(confirmed));
  syncCheckpoint = confirmed;
  if (syncChildPid === childPid) syncChildPid = undefined;
  return true;
}

function settingsPath(name: string): string { return join(app.getPath("userData"), name); }
function profileID(auth: Credentials): string { return createHash("sha256").update(`${auth.origin}\0${auth.accountName}`).digest("hex"); }
function profileFile(name: "mappings" | "sync-checkpoint"): string {
  if (!activeProfile) throw new Error("Log in before changing local Workspace state");
  return `${name}-${activeProfile}.json`;
}
function savePrivate(name: string, value: string | Buffer): void {
  const target = settingsPath(name);
  mkdirSync(app.getPath("userData"), { recursive: true, mode: 0o700 });
  const pending = `${target}.${randomUUID()}.tmp`;
  writeFileSync(pending, value, { mode: 0o600 });
  renameSync(pending, target);
}
function readOptional(name: string): string | null {
  try { return readFileSync(settingsPath(name), "utf8"); }
  catch (error) { if ((error as NodeJS.ErrnoException).code === "ENOENT") return null; throw error; }
}

function safeStorageReady(): boolean {
  if (!safeStorage.isEncryptionAvailable()) return false;
  return process.platform !== "linux" || ["gnome_libsecret", "kwallet", "kwallet5", "kwallet6"].includes(safeStorage.getSelectedStorageBackend());
}

function loadProfile(auth: Credentials): void {
  activeProfile = profileID(auth);
  mappings = [];
  syncCheckpoint = null;
  profileError = null;
  // shortcut: Unscoped legacy files need matching installation metadata; otherwise the user must select the folder again.
  const legacy = lastInstallation?.origin === auth.origin && lastInstallation.name === auth.accountName && lastInstallation.id === auth.installationId;
  const mappingFile = profileFile("mappings");
  const checkpointFile = profileFile("sync-checkpoint");
  let source = mappingFile;
  try {
    let raw = readOptional(source);
    if (raw === null && legacy) { source = "mappings.json"; raw = readOptional(source); }
    if (raw !== null) {
      const saved = JSON.parse(raw) as Mapping[];
      if (!Array.isArray(saved) || !saved.every((m) => m && /^w[a-z0-9]{7}$/.test(m.workspaceId) && typeof m.directory === "string" && typeof m.dev === "string" && typeof m.ino === "string")) throw new Error("Invalid Workspace mapping");
      mappings = saved;
      if (source !== mappingFile) savePrivate(mappingFile, raw);
    }
  } catch { profileError = `本机同步配置无法读取：${settingsPath(source)}。同步已暂停，请备份并修复该文件。`; }
  source = checkpointFile;
  try {
    let raw = readOptional(source);
    if (raw === null && legacy) { source = "sync-checkpoint.json"; raw = readOptional(source); }
    if (raw !== null) {
      const saved = JSON.parse(raw) as SyncCheckpoint;
      if (!saved || typeof saved.installationId !== "string" || !/^w[a-z0-9]{7}$/.test(saved.workspaceId) || typeof saved.directory !== "string" || typeof saved.dev !== "string" || typeof saved.ino !== "string" || !/^[A-Za-z0-9._~-]{1,128}$/.test(saved.idempotencyKey) || !["upload", "download", "bidirectional", "live_sync", "handoff_checkpoint"].includes(saved.mode) || (saved.sessionId && !/^p[a-z0-9]{7}$/.test(saved.sessionId)) || (saved.childPid !== undefined && (!Number.isSafeInteger(saved.childPid) || saved.childPid <= 0))) throw new Error("Invalid sync recovery point");
      syncCheckpoint = saved;
      if (source !== checkpointFile) savePrivate(checkpointFile, raw);
    }
  } catch { profileError ??= `本机同步恢复点无法读取：${settingsPath(source)}。同步已暂停，请备份并修复该文件。`; }
}

function loadState(): void {
  try { lastOrigin = portalOrigin(readFileSync(settingsPath("service-origin.txt"), "utf8").trim()); } catch { lastOrigin = null; }
  try {
    const saved = JSON.parse(readFileSync(settingsPath("installation.json"), "utf8")) as typeof lastInstallation;
    if (saved && saved.origin === portalOrigin(saved.origin) && typeof saved.name === "string" && saved.name && /^i[a-z0-9]{7}$/.test(saved.id)) lastInstallation = saved;
  } catch { lastInstallation = null; }
  try {
    if (safeStorageReady() && existsSync(settingsPath("credentials.bin"))) {
      const saved = JSON.parse(safeStorage.decryptString(readFileSync(settingsPath("credentials.bin")))) as { version?: number; credentials?: Credentials };
      const auth = saved.version === 2 ? saved.credentials : null;
      if (auth && /^i[a-z0-9]{7}$/.test(auth.installationId) && typeof auth.clientCredential === "string" && auth.clientCredential && !credentialExpired(auth.clientExpiresAt)) {
        auth.origin = portalOrigin(auth.origin);
        if (!auth.accountName && lastInstallation?.origin === auth.origin && lastInstallation.id === auth.installationId) auth.accountName = lastInstallation.name;
        if (typeof auth.accountName !== "string" || !auth.accountName) throw new Error("Local account identity is missing");
        credentials = auth;
        lastOrigin = auth.origin;
      } else rmSync(settingsPath("credentials.bin"), { force: true });
    }
  } catch { credentials = null; }
  if (credentials) loadProfile(credentials);
}

function publicState(): unknown {
  if (credentials && credentialExpired(credentials.clientExpiresAt)) clearAuthorization();
  return { authenticated: Boolean(credentials), origin: credentials?.origin ?? lastOrigin, installationId: credentials?.installationId ?? null, expiresAt: credentials?.clientExpiresAt ?? null, expiresSoon: credentials ? credentialExpiresSoon(credentials.clientExpiresAt) : false, mappings: credentials ? mappings : [], syncState: sync.snapshot(), syncCheckpoint: credentials && syncCheckpoint ? { workspaceId: syncCheckpoint.workspaceId, mode: syncCheckpoint.mode, installationId: syncCheckpoint.installationId } : null, profileError: credentials ? profileError : null, storageReady: safeStorageReady(), view };
}

function notifyState(): void { mainWindow?.webContents.send("morde:state", publicState()); }
function clearTimer(timer: NodeJS.Timeout | null): null { if (timer) clearTimeout(timer); return null; }
function closeHostWindows(): void { for (const window of hostWindows) window.close(); }

function detachWeb(): void {
  closeHostWindows();
  if (webView) {
    if (mainWindow && !mainWindow.isDestroyed() && webAttached) mainWindow.contentView.removeChildView(webView);
    webAttached = false;
    if (!webView.webContents.isDestroyed()) webView.webContents.close();
    webView = null;
  }
  if (webPartition) void webPartition.clearStorageData({ storages: ["cookies", "localstorage"] });
  webPartition = null;
  webRefreshTimer = clearTimer(webRefreshTimer);
}

function clearAuthorization(): void {
  if (!credentials) return;
  credentials = null;
  detachWeb();
  credentialExpiryTimer = clearTimer(credentialExpiryTimer);
  authorizationCheckTimer = clearTimer(authorizationCheckTimer);
  rmSync(settingsPath("credentials.bin"), { force: true });
  void sync.stop().then((stopped) => { if (stopped) clearConfirmedChild(); }).catch(() => undefined);
  notifyState();
}

function scheduleCredentialExpiry(): void {
  credentialExpiryTimer = clearTimer(credentialExpiryTimer);
  const auth = credentials;
  if (!auth) return;
  const expiry = Date.parse(auth.clientExpiresAt);
  if (!Number.isFinite(expiry) || expiry <= Date.now()) { clearAuthorization(); return; }
  credentialExpiryTimer = setTimeout(() => {
    if (credentials !== auth) return;
    if (credentialExpired(auth.clientExpiresAt)) clearAuthorization();
    else scheduleCredentialExpiry();
  }, Math.min(expiry - Date.now(), 2_147_483_647));
  credentialExpiryTimer.unref();
}

function scheduleAuthorizationCheck(): void {
  authorizationCheckTimer = clearTimer(authorizationCheckTimer);
  const auth = credentials;
  if (!auth) return;
  authorizationCheckTimer = setTimeout(() => {
    void api.me().catch((error: unknown) => { if (credentials === auth && String(error).includes("Authorization expired or revoked")) clearAuthorization(); })
      .finally(() => { if (credentials === auth) scheduleAuthorizationCheck(); });
  }, 60_000);
  authorizationCheckTimer.unref();
}

function sameOriginURL(value: string, origin: string): URL | null {
  try { const url = new URL(value); return url.origin === origin && !url.username && !url.password ? url : null; } catch { return null; }
}
function hostEntryURL(value: string, origin: string): { id: string; target: string | null } | null {
  const url = sameOriginURL(value, origin);
  if (!url || url.hash || !/^\/host-entry\/h[a-z0-9]{7}$/.test(url.pathname) || [...url.searchParams.keys()].some((key) => key !== "target") || url.searchParams.getAll("target").length > 1) return null;
  const target = url.searchParams.get("target");
  if (target && target !== "desktop" && target !== "terminal") return null;
  return { id: url.pathname.slice("/host-entry/".length), target };
}

async function hostOrigin(id: string, shared: boolean, serviceOrigin: string): Promise<string> {
  const value = shared ? (await api.sharedHosts() as { items?: Array<{ id: string; url: string }> }).items?.find((item) => item.id === id) : await api.host(id) as { url?: string };
  if (!value?.url) throw new Error("Host is unavailable");
  const url = new URL(value.url);
  if ((url.protocol !== "https:" && !localGatewayOrigin(url, serviceOrigin)) || url.username || url.password) throw new Error("Invalid Host origin");
  return url.origin;
}

function guardHostWindow(win: BrowserWindow, entry: { id: string; target: string | null }, auth: Credentials): void {
  hostWindows.add(win);
  win.on("closed", () => hostWindows.delete(win));
  let allowedGateway: string | null = null;
  const returnToMain = () => {
    if (!win.isDestroyed()) win.close();
    if (credentials === auth && mainWindow && !mainWindow.isDestroyed()) { showView("web"); mainWindow.focus(); }
  };
  win.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  win.webContents.on("will-navigate", (event, value) => {
    const same = sameOriginURL(value, auth.origin);
    if (same?.pathname === `/host-entry/${entry.id}`) return;
    if (same?.pathname === "/hosts") { event.preventDefault(); returnToMain(); return; }
    try { if (allowedGateway && new URL(value).origin === allowedGateway) return; } catch { /* Reject malformed navigation. */ }
    let target: string;
    try { target = gatewayURL(value, auth.origin); } catch { event.preventDefault(); return; }
    const origin = new URL(target).origin;
    if (allowedGateway === origin && credentials === auth) return;
    event.preventDefault();
    void hostOrigin(entry.id, Boolean(entry.target), auth.origin).then((expected) => {
      if (expected !== origin || credentials !== auth || win.isDestroyed()) throw new Error("Host ticket target changed");
      allowedGateway = origin;
      return win.loadURL(target);
    }).catch((error: unknown) => { if (!win.isDestroyed()) void dialog.showMessageBox(win, { type: "error", message: String(error) }); });
  });
  win.webContents.on("will-redirect", (event, value) => {
    const url = sameOriginURL(value, auth.origin);
    if (url?.pathname === "/hosts") { event.preventDefault(); returnToMain(); return; }
    const portalEntry = url?.pathname === `/host-entry/${entry.id}`;
    try { if (!portalEntry && new URL(value).origin !== allowedGateway) event.preventDefault(); }
    catch { event.preventDefault(); }
  });
  win.webContents.on("did-navigate-in-page", (_event, value) => {
    if (sameOriginURL(value, auth.origin)?.pathname === "/hosts") returnToMain();
  });
}

function installDownloadAndClipboard(partition: Session, auth: Credentials): void {
  partition.on("will-download", (_event, item, contents) => {
    const source = contents.getURL();
    if (!sameOriginURL(source, auth.origin) && ![...hostWindows].some((win) => win.webContents === contents)) { item.cancel(); return; }
    item.setSaveDialogOptions({ title: "保存 Morde 文件" });
  });
  partition.setPermissionRequestHandler((contents, permission, callback) => {
    const trusted = Boolean(sameOriginURL(contents.getURL(), auth.origin)) || [...hostWindows].some((win) => win.webContents === contents);
    callback(trusted && permission === "clipboard-sanitized-write");
  });
}

function positionWeb(): void {
  if (!mainWindow || !webView) return;
  const bounds = mainWindow.getContentBounds();
  webView.setBounds({ x: 0, y: 64, width: bounds.width, height: Math.max(0, bounds.height - 64) });
}
function showView(next: "web" | "sync"): void {
  view = next;
  if (mainWindow && webView) {
    if (next === "web" && !webAttached) { mainWindow.contentView.addChildView(webView); webAttached = true; positionWeb(); webView.webContents.focus(); }
    if (next === "sync" && webAttached) { mainWindow.contentView.removeChildView(webView); webAttached = false; }
  }
  notifyState();
}

async function refreshWebSession(auth: Credentials, initial?: WebSession): Promise<void> {
  if (credentials !== auth || !webPartition) return;
  try {
    const next = initial ?? await api.webSession();
    if (credentials !== auth || !webPartition) return;
    await webPartition.cookies.set({ url: auth.origin, name: "ch_portal", value: next.credential, path: "/", httpOnly: true, secure: auth.origin.startsWith("https:"), sameSite: "strict", expirationDate: Date.parse(next.expiresAt) / 1000 });
    webRefreshTimer = clearTimer(webRefreshTimer);
    webRefreshTimer = setTimeout(() => { void refreshWebSession(auth).catch(() => undefined); }, Math.max(1000, Math.min(Date.parse(next.expiresAt) - Date.now() - 60_000, 2_147_483_647)));
    webRefreshTimer.unref();
  } catch (error) {
    if (credentials !== auth) return;
    if (String(error).includes("Authorization expired or revoked")) { clearAuthorization(); return; }
    webRefreshTimer = clearTimer(webRefreshTimer);
    webRefreshTimer = setTimeout(() => { void refreshWebSession(auth).catch(() => undefined); }, 30_000);
    webRefreshTimer.unref();
    throw error;
  }
}

async function openWeb(initial?: WebSession): Promise<void> {
  const auth = credentials;
  if (!auth) throw new Error("Log in to Morde first");
  if (!webPartition) {
    webPartition = session.fromPartition(`morde-user-${randomUUID()}`);
    installDownloadAndClipboard(webPartition, auth);
    webPartition.webRequest.onCompleted({ urls: [`${auth.origin}/api/auth/logout`] }, (details) => {
      if (credentials === auth && details.statusCode === 204 && details.method === "POST") clearAuthorization();
    });
  }
  await refreshWebSession(auth, initial);
  if (credentials !== auth) return;
  if (!webView) {
    const content = new WebContentsView({ webPreferences: { session: webPartition, contextIsolation: true, nodeIntegration: false, sandbox: true, webSecurity: true } });
    webView = content;
    const restoreFromLogin = () => {
      void refreshWebSession(auth).then(() => {
        if (credentials === auth && !content.webContents.isDestroyed()) return content.webContents.loadURL(auth.origin);
      }).catch(() => { if (credentials === auth) showView("sync"); });
    };
    content.webContents.setWindowOpenHandler((details) => {
      const entry = hostEntryURL(details.url, auth.origin);
      if (!entry || credentials !== auth) {
        const target = sameOriginURL(details.url, auth.origin);
        if (target?.pathname.startsWith("/admin")) void shell.openExternal(target.href);
        return { action: "deny" };
      }
      return { action: "allow", createWindow: (options) => {
        const win = new BrowserWindow({ ...options, width: 1280, height: 800, title: "Morde Host", webPreferences: { ...options.webPreferences, session: webPartition!, contextIsolation: true, nodeIntegration: false, sandbox: true, webSecurity: true } });
        guardHostWindow(win, entry, auth);
        return win.webContents;
      } };
    });
    const guardNavigation = (event: { preventDefault(): void }, value: string) => {
      const target = sameOriginURL(value, auth.origin);
      if (!target || target.pathname.startsWith("/admin") || target.pathname === "/login") {
        event.preventDefault();
        if (target?.pathname.startsWith("/admin")) void shell.openExternal(target.href);
        else if (target?.pathname === "/login") restoreFromLogin();
      }
    };
    content.webContents.on("will-navigate", guardNavigation);
    content.webContents.on("will-redirect", guardNavigation);
    content.webContents.on("did-navigate-in-page", (_event, value) => {
      const target = sameOriginURL(value, auth.origin);
      if (credentials !== auth) return;
      if (target?.pathname === "/login") restoreFromLogin();
      if (target?.pathname.startsWith("/admin")) { void shell.openExternal(target.href); void content.webContents.loadURL(auth.origin); }
    });
    await content.webContents.loadURL(auth.origin);
  }
  showView("web");
}

async function login(origin: unknown, name: unknown, password: unknown, key: unknown): Promise<unknown> {
  if (credentials) throw new Error("Sign out before changing accounts");
  if (sync.snapshot() !== "idle" || childMayStillRun(syncCheckpoint)) throw new Error("Finish the previous Workspace sync before changing accounts");
  if (!safeStorageReady()) throw new Error("Secure operating system storage is unavailable");
  if (typeof key !== "string") throw new Error("Invalid login request");
  const normalizedOrigin = portalOrigin(origin);
  const normalizedName = typeof name === "string" ? name.trim() : "";
  const previousID = lastInstallation?.origin === normalizedOrigin && lastInstallation.name === normalizedName ? lastInstallation.id : undefined;
  const result = await api.login(normalizedOrigin, name, password, key, previousID);
  const previousInstallation = lastInstallation;
  const previousProfile = activeProfile, previousMappings = mappings, previousCheckpoint = syncCheckpoint, previousProfileError = profileError, previousChildPid = syncChildPid;
  credentials = result.credentials;
  try {
    loadProfile(result.credentials);
    if (activeProfile !== previousProfile) syncChildPid = undefined;
    savePrivate("credentials.bin", safeStorage.encryptString(JSON.stringify({ version: 2, credentials: result.credentials })));
    savePrivate("service-origin.txt", result.credentials.origin);
    savePrivate("installation.json", JSON.stringify({ origin: result.credentials.origin, name: normalizedName, id: result.credentials.installationId }));
    lastOrigin = credentials.origin;
    lastInstallation = { origin: credentials.origin, name: normalizedName, id: credentials.installationId };
    scheduleCredentialExpiry();
    scheduleAuthorizationCheck();
    await openWeb(result.webSession);
    return publicState();
  } catch (error) {
    void new MordeAPI(() => result.credentials).logout().catch(() => undefined);
    clearAuthorization();
    activeProfile = previousProfile;
    mappings = previousMappings;
    syncCheckpoint = previousCheckpoint;
    profileError = previousProfileError;
    syncChildPid = previousChildPid;
    lastInstallation = previousInstallation;
    try {
      if (previousInstallation) savePrivate("installation.json", JSON.stringify(previousInstallation));
      else rmSync(settingsPath("installation.json"), { force: true });
    } catch { /* Login still fails closed when local metadata cannot be restored. */ }
    throw error;
  }
}

async function logout(): Promise<string | null> {
  if (!credentials) return null;
  if (logoutInProgress) throw new Error("Sign-out is already in progress");
  logoutInProgress = true;
  let warning: string | null = null;
  try {
    try { await api.logout(); } catch { warning = "本机已退出。网络请求未完成，请在 Portal 的客户端列表中撤销此设备。"; }
    const stopped = priorSyncChildMayStillRun() ? false : await sync.stop();
    if (stopped) { try { if (!clearConfirmedChild()) warning = `${warning ?? ""} 同步进程仍可能持有目录；恢复点已保留。`.trim(); } catch { warning = `${warning ?? ""} 同步恢复点保存失败，请检查本机目录。`.trim(); } }
    else warning = `${warning ?? ""} 同步进程停止状态未确认；恢复点已保留。`.trim();
    clearAuthorization();
    lastInstallation = null;
    rmSync(settingsPath("installation.json"), { force: true });
    return warning;
  } finally { logoutInProgress = false; }
}

function sendError(error: unknown): never {
  const message = error instanceof Error ? error.message : "Morde request failed";
  if (message.includes("Authorization expired or revoked")) clearAuthorization();
  else if (message.includes("HTTP 403")) void sync.stop();
  throw new Error(message);
}
function handler<T extends unknown[]>(channel: string, fn: (...args: T) => Promise<unknown> | unknown): void {
  ipcMain.handle(channel, async (event, ...args: T) => {
    if (!mainWindow || event.sender !== mainWindow.webContents) throw new Error("Invalid desktop window");
    if (logoutInProgress && channel !== "morde:logout") throw new Error("Sign-out is in progress");
    if (credentials && credentialExpired(credentials.clientExpiresAt)) clearAuthorization();
    try { return await fn(...args); } catch (error) { return sendError(error); }
  });
}

function register(): void {
  handler("morde:state", () => publicState());
  handler("morde:login", login);
  handler("morde:logout", logout);
  handler("morde:show-web", async () => { try { await openWeb(); } catch (error) { showView("sync"); throw error; } });
  handler("morde:show-sync", () => { if (!credentials) throw new Error("Log in to Morde first"); showView("sync"); });
  handler("morde:public-page", (path: unknown, requestedOrigin?: unknown) => {
    if (path !== "register" && path !== "download") throw new Error("Invalid public page");
    const origin = credentials?.origin ?? (requestedOrigin ? portalOrigin(requestedOrigin) : lastOrigin);
    if (!origin) throw new Error("Enter a service address and log in first");
    const partition = session.fromPartition(`morde-public-${randomUUID()}`);
    partition.on("will-download", (_event, item) => item.setSaveDialogOptions({ title: "保存 Morde 安装包" }));
    partition.setPermissionRequestHandler((_contents, _permission, callback) => callback(false));
    const window = new BrowserWindow({ width: 960, height: 720, title: "Morde", webPreferences: { session: partition, contextIsolation: true, nodeIntegration: false, sandbox: true, webSecurity: true } });
    window.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
    window.webContents.on("will-navigate", (event, value) => {
      const target = sameOriginURL(value, origin);
      if (target?.pathname === "/login") { event.preventDefault(); window.close(); mainWindow?.focus(); return; }
      if (!target || (target.pathname !== "/register" && target.pathname !== "/download")) { event.preventDefault(); if (value.startsWith("https://")) void shell.openExternal(value); }
    });
    window.webContents.on("will-redirect", (event, value) => {
      const target = sameOriginURL(value, origin);
      if (!target || (target.pathname !== "/register" && target.pathname !== "/download")) event.preventDefault();
      if (target?.pathname === "/login") { window.close(); mainWindow?.focus(); }
    });
    window.webContents.on("did-navigate-in-page", (_event, value) => {
      if (sameOriginURL(value, origin)?.pathname === "/login") { window.close(); mainWindow?.focus(); }
    });
    void window.loadURL(`${origin}/${path}`);
  });
  handler("morde:workspaces", () => api.workspaces());
  handler("morde:choose-directory", async (workspaceId: unknown) => {
    const auth = credentials;
    if (!auth) throw new Error("Log in to Morde first");
    if (profileError) throw new Error(profileError);
    const id = checkedId("workspace", workspaceId);
    if (sync.snapshot() !== "idle" || syncCheckpoint) throw new Error("Finish or discard the prior sync recovery point before changing folders");
    const workspace = await api.workspace(id) as { state?: string };
    if (workspace.state !== "ready") throw new Error("Workspace is not ready for sync");
    const picked = await dialog.showOpenDialog(mainWindow!, { properties: ["openDirectory"] });
    if (picked.canceled || !picked.filePaths[0]) return null;
    const appData = app.getPath("userData");
    const systemRoots = process.platform === "win32" ? [process.env.SystemRoot, process.env.ProgramFiles].filter((value): value is string => Boolean(value)) : ["/", "/System", "/Applications", "/Library", "/private", "/usr", "/etc", "/var", "/bin", "/sbin", "/dev", "/proc", "/sys", "/run"];
    const candidate = await checkedDirectory(picked.filePaths[0], [...mappings.filter((item) => item.workspaceId !== id), { workspaceId: "", directory: appData, dev: "", ino: "" }]);
    if (systemRoots.some((root) => root && isSystemDirectory(candidate.directory, root))) throw new Error("Choose a project folder outside system directories");
    if (credentials !== auth) throw new Error("Authorization changed while selecting a folder");
    const mapping = { ...candidate, workspaceId: id };
    const nextMappings = [...mappings.filter((item) => item.workspaceId !== id), mapping];
    savePrivate(profileFile("mappings"), JSON.stringify(nextMappings));
    mappings = nextMappings;
    notifyState();
    return mapping;
  });
  handler("morde:sync", async (workspaceId: unknown, mode: Parameters<MordeSync["run"]>[2]) => {
    if (profileError) throw new Error(profileError);
    if (!["upload", "download", "bidirectional", "live_sync", "handoff_checkpoint"].includes(mode)) throw new Error("Unsupported sync mode");
    const id = checkedId("workspace", workspaceId);
    const auth = credentials;
    const mapping = mappings.find((item) => item.workspaceId === id);
    if (!auth || !mapping) throw new Error("Log in and choose a folder first");
    const workspace = await api.workspace(id) as { state?: string };
    if (credentials !== auth || workspace.state !== "ready") throw new Error("Workspace is not ready for sync");
    if (childMayStillRun(syncCheckpoint)) throw new Error("A prior sync process may still hold this folder. Stop it before recovery");
    if (syncCheckpoint && (syncCheckpoint.installationId !== auth.installationId || syncCheckpoint.workspaceId !== id || syncCheckpoint.mode !== mode || syncCheckpoint.directory !== mapping.directory || syncCheckpoint.dev !== mapping.dev || syncCheckpoint.ino !== mapping.ino)) throw new Error("An earlier sync needs recovery or explicit discard before starting another");
    if (!syncCheckpoint) {
      syncCheckpoint = { installationId: auth.installationId, workspaceId: id, directory: mapping.directory, dev: mapping.dev, ino: mapping.ino, mode, idempotencyKey: randomUUID() };
      try { savePrivate(profileFile("sync-checkpoint"), JSON.stringify(syncCheckpoint)); }
      catch (error) { syncCheckpoint = null; throw error; }
    }
    let result: unknown;
    try { result = await sync.run(auth, mapping, mode, [], syncCheckpoint, () => credentials === auth && !logoutInProgress); }
    finally { if (sync.snapshot() === "idle" && !childMayStillRun(syncCheckpoint)) clearConfirmedChild(); }
    const outcome = result as { session?: { state?: string }; conflicts?: unknown[] } | null;
    if (!outcome?.session || (outcome.session.state === "completed" && !outcome.conflicts?.length)) { syncCheckpoint = null; rmSync(settingsPath(profileFile("sync-checkpoint")), { force: true }); }
    return result;
  });
  handler("morde:sync-stop", async () => {
    if (priorSyncChildMayStillRun()) throw new Error("A prior sync process may still hold this folder. Its recovery point was kept");
    const stopped = await sync.stop();
    if (stopped && !clearConfirmedChild()) throw new Error("A prior sync process may still hold this folder. Its recovery point was kept");
    return stopped;
  });
  handler("morde:sync-discard", () => {
    if (profileError) throw new Error(profileError);
    if (sync.snapshot() === "running") throw new Error("Stop sync before discarding its recovery point");
    if (childMayStillRun(syncCheckpoint)) throw new Error("A prior sync process may still hold this folder");
    if (!sync.discardCheckpoint(syncCheckpoint)) throw new Error("A prior sync process may still hold this folder");
    syncCheckpoint = null;
    rmSync(settingsPath(profileFile("sync-checkpoint")), { force: true });
    return publicState();
  });
}

function makeWindow(): BrowserWindow {
  const win = new BrowserWindow({ width: 1120, height: 760, minWidth: 720, minHeight: 520, title: "Morde", show: false, webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true, webSecurity: true, preload: join(__dirname, "morde-preload.js") } });
  win.webContents.setWindowOpenHandler(() => ({ action: "deny" }));
  win.webContents.on("will-navigate", (event) => event.preventDefault());
  win.on("resize", positionWeb);
  void win.loadFile(join(__dirname, "../resources/morde.html"));
  win.once("ready-to-show", () => win.show());
  win.on("closed", () => { detachWeb(); mainWindow = null; });
  return win;
}
function showWindow(): void {
  if (!mainWindow) {
    mainWindow = makeWindow();
    if (credentials) void openWeb().catch((error: unknown) => { mainWindow?.webContents.send("morde:sync-state", { state: "offline", message: String(error) }); showView("sync"); });
  } else mainWindow.show();
  mainWindow.focus();
}

if (!app.requestSingleInstanceLock()) app.quit();
else {
  app.on("second-instance", showWindow);
  app.whenReady().then(() => {
    loadState();
    scheduleCredentialExpiry();
    scheduleAuthorizationCheck();
    register();
    Menu.setApplicationMenu(Menu.buildFromTemplate([{ label: "Morde", submenu: [{ label: zh ? "打开" : "Open", click: showWindow }, { label: zh ? "退出" : "Quit", click: () => app.quit() }] }]));
    showWindow();
    try { tray = new Tray(join(__dirname, "../resources/morde-icon.png")); tray.setToolTip("Morde"); tray.setContextMenu(Menu.buildFromTemplate([{ label: zh ? "打开 Morde" : "Open Morde", click: showWindow }, { label: zh ? "退出" : "Quit", click: () => app.quit() }])); tray.on("double-click", showWindow); } catch { tray = null; }
  });
  app.on("activate", showWindow);
  app.on("window-all-closed", () => { if (process.platform !== "darwin" && !tray) app.quit(); });
  app.on("before-quit", (event) => {
    if (exitReady) return;
    event.preventDefault();
    const stopping = priorSyncChildMayStillRun() ? Promise.resolve(false) : sync.stop();
    void stopping.then((stopped) => {
      let cleared = false;
      try { cleared = stopped && clearConfirmedChild(); } catch { /* Keep the recovery point when it cannot be saved. */ }
      if (!cleared) void dialog.showMessageBox({ type: "warning", message: "Sync shutdown was not confirmed, or a prior sync process may still be running. The recovery point was kept." });
      exitReady = true;
      app.quit();
    });
  });
}
