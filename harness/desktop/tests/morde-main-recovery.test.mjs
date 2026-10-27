import assert from 'node:assert/strict';
import { test } from 'node:test';
import { createHash } from 'node:crypto';
import { createRequire } from 'node:module';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const require = createRequire(import.meta.url);
const future = '2099-01-01T00:00:00Z';
const auth = { origin: 'https://portal.example', accountName: 'user', installationId: 'i1234567', clientCredential: 'client-secret', clientExpiresAt: future, syncCredential: 'sync-secret', syncExpiresAt: future };
const loginResponse = { installation_id: auth.installationId, client_credential: auth.clientCredential, client_expires_at: future, sync_credential: auth.syncCredential, sync_expires_at: future, web_session_credential: 'web-secret', web_session_expires_at: future };
const profileFile = (h, value, name) => join(h.userData, `${name}-${createHash('sha256').update(`${value.origin}\0${value.accountName}`).digest('hex')}.json`);

function harness(initialAuth = null) {
  const root = mkdtempSync(join(tmpdir(), 'morde-desktop-auth-'));
  const userData = join(root, 'Morde Client');
  const fs = require('node:fs');
  fs.mkdirSync(userData);
  if (initialAuth) writeFileSync(join(userData, 'credentials.bin'), JSON.stringify({ version: 2, credentials: initialAuth }));
  const handlers = new Map(), windows = [], views = [], partitions = [], appEvents = new Map(), shellURLs = [];
  class FakeContents {
    events = new Map();
    url = '';
    closed = false;
    on(name, fn) { this.events.set(name, fn); }
    setWindowOpenHandler(fn) { this.open = fn; }
    async loadURL(url) { this.url = url; }
    getURL() { return this.url; }
    isDestroyed() { return this.closed; }
    focus() { this.focused = true; }
    close() { this.closed = true; }
    send() {}
  }
  class FakeWindow {
    constructor(options) {
      this.options = options;
      this.events = new Map();
      this.webContents = options.webContents ?? new FakeContents();
      this.contentView = { attached: [], getBounds: () => ({ x: 0, y: 0, width: 0, height: 0 }), addChildView: (view) => this.contentView.attached.push(view), removeChildView: (view) => { this.contentView.attached = this.contentView.attached.filter((item) => item !== view); } };
      windows.push(this);
    }
    on(name, fn) { this.events.set(name, fn); }
    once(name, fn) { this.events.set(name, fn); }
    async loadFile(path) { this.path = path; }
    async loadURL(url) { this.webContents.url = url; }
    show() {}
    getContentBounds() { return { x: 0, y: 0, width: 1120, height: 760 }; }
    focus() { this.focused = true; }
    isDestroyed() { return this.destroyed || false; }
    close() { this.destroyed = true; this.events.get('closed')?.(); }
  }
  class FakeView {
    constructor(options) { this.options = options; this.webContents = new FakeContents(); views.push(this); }
    setBounds(bounds) { this.bounds = bounds; }
  }
  const fakeSession = { fromPartition(name) {
    const partition = {
      name, cookies: { values: [], async set(value) { this.values.push(value); } },
      webRequest: { onCompleted(_filter, fn) { this.completed = fn; } },
      events: new Map(), on(event, fn) { this.events.set(event, fn); },
      setPermissionRequestHandler(fn) { this.permissionRequest = fn; },
      async clearStorageData() { this.cleared = true; },
    };
    partitions.push(partition);
    return partition;
  } };
  const paths = { appData: root };
  const electron = {
    app: { setName() {}, getPath: (key) => paths[key] ?? root, setPath: (key, path) => { paths[key] = path; }, getLocale: () => 'en', requestSingleInstanceLock: () => true, isPackaged: false, whenReady: () => Promise.resolve(), on: (name, fn) => appEvents.set(name, fn), quit() {} },
    BrowserWindow: FakeWindow, WebContentsView: FakeView, session: fakeSession,
    ipcMain: { handle: (channel, fn) => handlers.set(channel, fn) },
    dialog: { showOpenDialog: async () => ({ canceled: true, filePaths: [] }), showMessageBox: async () => ({ response: 0 }) },
    Menu: { buildFromTemplate: (template) => template, setApplicationMenu() {} },
    safeStorage: { isEncryptionAvailable: () => true, getSelectedStorageBackend: () => 'gnome_libsecret', encryptString: (value) => Buffer.from(value), decryptString: (value) => value.toString() },
    shell: { openExternal: async (url) => { shellURLs.push(url); } },
    Tray: class { setToolTip() {} setContextMenu() {} on() {} },
  };
  const Module = require('node:module');
  const originalLoad = Module._load;
  const entry = require.resolve('../out/morde-main.js');
  Module._load = function (request, parent, isMain) { if (request === 'electron') return electron; return originalLoad.call(this, request, parent, isMain); };
  delete require.cache[entry];
  try { require(entry); } finally { Module._load = originalLoad; }
  return {
    root, userData, handlers, windows, views, partitions, appEvents, shellURLs,
    async ready() { await new Promise((resolve) => setImmediate(resolve)); await new Promise((resolve) => setImmediate(resolve)); },
    invoke(channel, ...args) { return handlers.get(channel)({ sender: windows.at(-1).webContents }, ...args); },
    cleanup() { delete require.cache[entry]; rmSync(root, { recursive: true, force: true }); },
  };
}

test('one desktop login stores Client and Sync only, injects an HttpOnly Web cookie in an isolated view', async () => {
  const originalFetch = globalThis.fetch;
  const calls = [];
  globalThis.fetch = async (url, options) => { calls.push({ url, options }); return new Response(JSON.stringify(loginResponse), { headers: { 'content-type': 'application/json' } }); };
  const h = harness();
  try {
    await h.ready();
    const state = await h.invoke('morde:login', 'https://portal.example', 'user', 'password', 'retry-key');
    assert.equal(state.authenticated, true);
    assert.equal(calls.length, 1);
    assert.equal(h.partitions.length, 1);
    assert.match(h.partitions[0].name, /^morde-user-/);
    assert.deepEqual(h.partitions[0].cookies.values.map((item) => ({ name: item.name, httpOnly: item.httpOnly, secure: item.secure, sameSite: item.sameSite })), [{ name: 'ch_portal', httpOnly: true, secure: true, sameSite: 'strict' }]);
    assert.equal(h.views[0].options.webPreferences.preload, undefined);
    assert.equal(h.views[0].options.webPreferences.sandbox, true);
    assert.equal(h.windows[0].contentView.attached[0], h.views[0]);
    assert.deepEqual(h.views[0].bounds, { x: 0, y: 64, width: 1120, height: 696 });
    const persisted = JSON.parse(readFileSync(join(h.userData, 'credentials.bin'), 'utf8'));
    assert.equal(persisted.version, 2);
    assert.equal(JSON.stringify(persisted).includes('password'), false);
    assert.equal(JSON.stringify(persisted).includes('web-secret'), false);
    assert.equal(h.handlers.has('morde:pair'), false);
    assert.equal(h.handlers.has('morde:submit'), false);
    await assert.rejects(h.handlers.get('morde:state')({ sender: h.views[0].webContents }), /Invalid desktop window/);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('closing a window after login does not touch its destroyed Web view', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify(loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:login', auth.origin, 'user', 'password', 'retry-key');
    h.windows[0].contentView.removeChildView = () => { throw new Error('Object has been destroyed'); };
    h.views[0].webContents.closed = true;
    h.views[0].webContents.close = () => { throw new Error('Object has been destroyed'); };
    assert.doesNotThrow(() => h.windows[0].close());
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('Host popups are limited to the same-origin entry and Admin opens an independent browser', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify(loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:login', auth.origin, 'user', 'password', 'retry-key');
    const open = h.views[0].webContents.open;
    assert.equal(open({ url: 'https://evil.example/' }).action, 'deny');
    assert.equal(open({ url: 'https://portal.example/client-authorize' }).action, 'deny');
    assert.equal(open({ url: 'https://portal.example/host-entry/h1234567?target=desktop' }).action, 'allow');
    assert.equal(open({ url: 'https://portal.example/host-entry/h1234567?target=invalid' }).action, 'deny');
    assert.equal(open({ url: 'https://portal.example/admin/' }).action, 'deny');
    let blocked = false;
    h.views[0].webContents.events.get('will-navigate')({ preventDefault() { blocked = true; } }, 'https://portal.example/admin/');
    assert.equal(blocked, true);
    assert.deepEqual(h.shellURLs, ['https://portal.example/admin/', 'https://portal.example/admin/']);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('trusted Web downloads show a save dialog and clipboard access stays scoped', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify(loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:login', auth.origin, 'user', 'password', 'retry-key');
    const partition = h.partitions[0];
    const download = partition.events.get('will-download');
    let saveOptions, cancelled = false;
    download({}, { setSaveDialogOptions: (options) => { saveOptions = options; } }, h.views[0].webContents);
    assert.deepEqual(saveOptions, { title: '保存 Morde 文件' });
    const foreign = { getURL: () => 'https://evil.example/' };
    download({}, { cancel: () => { cancelled = true; } }, foreign);
    assert.equal(cancelled, true);
    let allowed;
    partition.permissionRequest(h.views[0].webContents, 'clipboard-sanitized-write', (value) => { allowed = value; });
    assert.equal(allowed, true);
    partition.permissionRequest(foreign, 'clipboard-sanitized-write', (value) => { allowed = value; });
    assert.equal(allowed, false);
    partition.permissionRequest(h.views[0].webContents, 'clipboard-read', (value) => { allowed = value; });
    assert.equal(allowed, false);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('public registration returns to the local login when its SPA link changes route', async () => {
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:public-page', 'register', 'https://portal.example');
    const register = h.windows.at(-1);
    assert.equal(register.webContents.url, 'https://portal.example/register');
    register.webContents.events.get('did-navigate-in-page')({}, 'https://portal.example/login');
    assert.equal(register.isDestroyed(), true);
    assert.equal(h.windows[0].isDestroyed(), false);
  } finally { h.cleanup(); }
});

test('remote Web and public page reject cross-origin HTTP redirects', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify(loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:login', auth.origin, 'user', 'password', 'retry-key');
    let blocked = false;
    h.views[0].webContents.events.get('will-redirect')({ preventDefault() { blocked = true; } }, 'https://evil.example/login');
    assert.equal(blocked, true);
    await h.invoke('morde:public-page', 'download');
    blocked = false;
    h.windows.at(-1).webContents.events.get('will-redirect')({ preventDefault() { blocked = true; } }, 'https://evil.example/download');
    assert.equal(blocked, true);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('Host window checks a one-time ticket against the Host origin before navigation', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => new Response(JSON.stringify(url.endsWith('/api/hosts/h1234567') ? { url: 'https://host.example/' } : loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:login', auth.origin, 'user', 'password', 'retry-key');
    const popup = h.views[0].webContents.open({ url: 'https://portal.example/host-entry/h1234567' });
    const guest = new h.views[0].webContents.constructor();
    const contents = popup.createWindow({ webContents: guest, webPreferences: { sandbox: true } });
    const win = h.windows.at(-1);
    assert.equal(contents, win.webContents);
    assert.equal(contents, guest);
    assert.equal(win.options.webPreferences.sandbox, true);
    assert.equal(win.options.webPreferences.preload, undefined);
    let blocked = false;
    win.webContents.events.get('will-navigate')({ preventDefault() { blocked = true; } }, 'https://evil.example/__ch/auth?t=secret');
    assert.equal(blocked, true);
    blocked = false;
    win.webContents.events.get('will-navigate')({ preventDefault() { blocked = true; } }, 'https://host.example/__ch/auth?t=secret');
    assert.equal(blocked, true);
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(win.webContents.url, 'https://host.example/__ch/auth?t=secret');
    blocked = false;
    win.webContents.events.get('will-navigate')({ preventDefault() { blocked = true; } }, 'https://host.example/__ch/wb/');
    assert.equal(blocked, false);
    const download = h.partitions[0].events.get('will-download');
    let saveOptions, cancelled = false;
    download({}, { setSaveDialogOptions: (options) => { saveOptions = options; } }, win.webContents);
    assert.deepEqual(saveOptions, { title: '保存 Morde 文件' });
    win.close();
    download({}, { cancel: () => { cancelled = true; } }, win.webContents);
    assert.equal(cancelled, true);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('Host entry failure returns to the usable main Web window', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify(loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness();
  try {
    await h.ready();
    await h.invoke('morde:login', auth.origin, 'user', 'password', 'retry-key');
    const popup = h.views[0].webContents.open({ url: 'https://portal.example/host-entry/h1234567' });
    popup.createWindow({});
    const win = h.windows.at(-1);
    h.windows[0].focused = false;
    win.webContents.events.get('did-navigate-in-page')({}, 'https://portal.example/hosts');
    assert.equal(win.isDestroyed(), true);
    assert.equal(h.windows[0].focused, true);
    assert.equal(h.windows[0].contentView.attached[0], h.views[0]);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('restart renews the Web session, while logout preserves local folder mapping and recovery point', async () => {
  const originalFetch = globalThis.fetch;
  const calls = [];
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return url.endsWith('client-logout') ? new Response(null, { status: 204 }) : new Response(JSON.stringify({ web_session_credential: 'renewed-web', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  };
  const h = harness(auth);
  const mappingsFile = profileFile(h, auth, 'mappings');
  const checkpointFile = profileFile(h, auth, 'sync-checkpoint');
  writeFileSync(join(h.userData, 'installation.json'), JSON.stringify({ origin: auth.origin, name: auth.accountName, id: auth.installationId }));
  writeFileSync(join(h.userData, 'mappings.json'), JSON.stringify([{ workspaceId: 'w1234567', directory: '/tmp/example', dev: '1', ino: '2' }]));
  writeFileSync(join(h.userData, 'sync-checkpoint.json'), JSON.stringify({ installationId: auth.installationId, workspaceId: 'w1234567', directory: '/tmp/example', dev: '1', ino: '2', mode: 'upload', idempotencyKey: 'same-key' }));
  try {
    await h.ready();
    assert.equal((await h.invoke('morde:state')).mappings[0].directory, '/tmp/example');
    assert.equal(existsSync(mappingsFile), true);
    assert.equal(existsSync(checkpointFile), true);
    assert.equal(h.partitions[0].cookies.values[0].value, 'renewed-web');
    assert.equal(calls[0].url, 'https://portal.example/api/auth/client-web-session');
    await h.invoke('morde:logout');
    assert.equal(existsSync(join(h.userData, 'credentials.bin')), false);
    assert.equal(existsSync(mappingsFile), true);
    assert.equal(existsSync(checkpointFile), true);
    assert.equal(h.partitions[0].cleared, true);
    assert.equal(h.views[0].webContents.closed, true);
    assert.equal(calls.at(-1).url, 'https://portal.example/api/auth/client-logout');
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('scheduled Web session refresh keeps the desktop running during a network outage', async () => {
  const originalFetch = globalThis.fetch;
  const unhandled = [];
  const onUnhandled = (error) => unhandled.push(error);
  process.on('unhandledRejection', onUnhandled);
  let requests = 0;
  globalThis.fetch = async () => {
    requests++;
    if (requests > 1) throw new TypeError('network offline');
    return new Response(JSON.stringify({ web_session_credential: 'first-web', web_session_expires_at: new Date(Date.now() + 61_000).toISOString() }), { headers: { 'content-type': 'application/json' } });
  };
  const h = harness(auth);
  try {
    await h.ready();
    await new Promise((resolve) => setTimeout(resolve, 1600));
    assert.equal(requests, 2);
    assert.deepEqual(unhandled, []);
    assert.equal((await h.invoke('morde:state')).authenticated, true);
    assert.equal(h.partitions[0].cookies.values[0].value, 'first-web');
  } finally {
    h.windows[0].close();
    process.off('unhandledRejection', onUnhandled);
    globalThis.fetch = originalFetch;
    h.cleanup();
  }
});

test('switching accounts or services cannot reuse another profile’s local Workspace mapping', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async (url) => url.endsWith('client-logout')
    ? new Response(null, { status: 204 })
    : new Response(JSON.stringify(url.endsWith('client-web-session')
      ? { web_session_credential: 'renewed-web', web_session_expires_at: future }
      : loginResponse), { headers: { 'content-type': 'application/json' } });
  const h = harness(auth);
  const mappingsFile = profileFile(h, auth, 'mappings');
  const checkpointFile = profileFile(h, auth, 'sync-checkpoint');
  writeFileSync(mappingsFile, JSON.stringify([{ workspaceId: 'w1234567', directory: '/tmp/owner-one', dev: '1', ino: '2' }]));
  writeFileSync(checkpointFile, JSON.stringify({ installationId: auth.installationId, workspaceId: 'w1234567', directory: '/tmp/owner-one', dev: '1', ino: '2', mode: 'upload', idempotencyKey: 'same-key' }));
  try {
    await h.ready();
    assert.equal((await h.invoke('morde:state')).mappings[0].directory, '/tmp/owner-one');
    await h.invoke('morde:logout');
    assert.deepEqual((await h.invoke('morde:state')).mappings, []);
    await h.invoke('morde:login', 'https://another.example', 'other', 'password', 'retry-other');
    assert.deepEqual((await h.invoke('morde:state')).mappings, []);
    assert.equal((await h.invoke('morde:state')).syncCheckpoint, null);
    assert.equal(existsSync(mappingsFile), true);
    assert.equal(existsSync(checkpointFile), true);
    await h.invoke('morde:logout');
    await h.invoke('morde:login', auth.origin, auth.accountName, 'password', 'retry-owner');
    assert.equal((await h.invoke('morde:state')).mappings[0].directory, '/tmp/owner-one');
    assert.equal((await h.invoke('morde:state')).syncCheckpoint.workspaceId, 'w1234567');
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('damaged sync recovery point preserves the file and blocks new local operations', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({ web_session_credential: 'renewed-web', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  const h = harness(auth);
  const checkpointFile = profileFile(h, auth, 'sync-checkpoint');
  writeFileSync(profileFile(h, auth, 'mappings'), JSON.stringify([{ workspaceId: 'w1234567', directory: '/tmp/example', dev: '1', ino: '2' }]));
  writeFileSync(checkpointFile, '{damaged');
  try {
    await h.ready();
    const state = await h.invoke('morde:state');
    assert.equal(state.authenticated, true);
    assert.match(state.profileError, /同步恢复点无法读取/);
    await assert.rejects(h.invoke('morde:choose-directory', 'w1234567'), /同步已暂停/);
    await assert.rejects(h.invoke('morde:sync', 'w1234567', 'upload'), /同步已暂停/);
    await assert.rejects(h.invoke('morde:sync-discard'), /同步已暂停/);
    assert.equal(readFileSync(checkpointFile, 'utf8'), '{damaged');
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('invalid local Workspace mapping is preserved instead of being replaced on folder selection', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({ web_session_credential: 'renewed-web', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  const h = harness(auth);
  const mappingsFile = profileFile(h, auth, 'mappings');
  const damaged = JSON.stringify([{ workspaceId: 'w1234567', dev: '1', ino: '2' }]);
  writeFileSync(mappingsFile, damaged);
  try {
    await h.ready();
    assert.match((await h.invoke('morde:state')).profileError, /同步配置无法读取/);
    await assert.rejects(h.invoke('morde:choose-directory', 'w1234567'), /同步已暂停/);
    assert.equal(readFileSync(mappingsFile, 'utf8'), damaged);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('closing and reopening the macOS window restores the authenticated Web view', async () => {
  const originalFetch = globalThis.fetch;
  globalThis.fetch = async () => new Response(JSON.stringify({ web_session_credential: 'renewed-web', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  const h = harness(auth);
  try {
    await h.ready();
    h.windows[0].close();
    h.appEvents.get('activate')();
    await new Promise((resolve) => setImmediate(resolve));
    assert.equal(h.windows.length, 2);
    assert.equal(h.views.length, 2);
    assert.equal(h.windows[1].contentView.attached[0], h.views[1]);
    assert.equal((await h.invoke('morde:state')).authenticated, true);
  } finally { globalThis.fetch = originalFetch; h.cleanup(); }
});

test('completed server session with a file conflict keeps the desktop recovery point', async () => {
  const originalFetch = globalThis.fetch;
  const Sync = require('../out/morde-sync.js').MordeSync;
  const originalRun = Sync.prototype.run;
  globalThis.fetch = async (url) => new Response(JSON.stringify(url.endsWith('/api/workspaces/w1234567')
    ? { state: 'ready' }
    : { web_session_credential: 'renewed-web', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  Sync.prototype.run = async () => ({ session: { state: 'completed', target_revision: 1 }, conflicts: [{ path: 'shared.txt' }] });
  const h = harness(auth);
  const checkpointFile = profileFile(h, auth, 'sync-checkpoint');
  writeFileSync(profileFile(h, auth, 'mappings'), JSON.stringify([{ workspaceId: 'w1234567', directory: '/tmp/example', dev: '1', ino: '2' }]));
  try {
    await h.ready();
    const result = await h.invoke('morde:sync', 'w1234567', 'live_sync');
    assert.equal(result.conflicts[0].path, 'shared.txt');
    assert.equal((await h.invoke('morde:state')).syncCheckpoint.mode, 'live_sync');
    assert.equal(existsSync(checkpointFile), true);
  } finally { Sync.prototype.run = originalRun; globalThis.fetch = originalFetch; h.cleanup(); }
});
