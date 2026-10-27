export type Credentials = {
  origin: string;
  accountName: string;
  installationId: string;
  clientCredential: string;
  clientExpiresAt: string;
  syncCredential?: string;
  syncExpiresAt?: string;
};

export type WebSession = { credential: string; expiresAt: string };

const IDS = { host: /^h[a-z0-9]{7}$/, workspace: /^w[a-z0-9]{7}$/ };
const EXPIRY_WARNING_MS = 7 * 24 * 60 * 60 * 1000;

export function credentialExpiresSoon(expiresAt: string, now = Date.now()): boolean {
  const remaining = Date.parse(expiresAt) - now;
  return Number.isFinite(remaining) && remaining > 0 && remaining <= EXPIRY_WARNING_MS;
}

export function credentialExpired(expiresAt: unknown, now = Date.now()): boolean {
  if (typeof expiresAt !== "string") return true;
  const expiry = Date.parse(expiresAt);
  return !Number.isFinite(expiry) || expiry <= now;
}

export function checkedId(kind: keyof typeof IDS, value: unknown): string {
  if (typeof value !== "string" || !IDS[kind].test(value)) throw new Error(`Invalid ${kind} ID`);
  return value;
}

export function portalOrigin(input: unknown): string {
  if (typeof input !== "string") throw new Error("Enter a Morde service address");
  const url = new URL(input.trim());
  const local = ["localhost", "portal.localhost", "127.0.0.1", "[::1]"].includes(url.hostname);
  if ((url.protocol !== "https:" && !(local && url.protocol === "http:")) || url.username || url.password ||
    url.pathname !== "/" || url.search || url.hash) {
    throw new Error("Use an HTTPS service origin, or HTTP on localhost/portal.localhost for development");
  }
  return url.origin;
}

export function desktopDownloadsURL(origin: unknown): string {
  return `${portalOrigin(origin)}/download`;
}

export function localGatewayOrigin(url: URL, serviceOrigin: string): boolean {
  const service = new URL(serviceOrigin);
  return service.protocol === "http:" && ["localhost", "portal.localhost", "127.0.0.1", "[::1]"].includes(service.hostname) &&
    url.protocol === "http:" && /^h[a-z0-9]{7}\.hosts\.localhost$/.test(url.hostname) && !url.port;
}

export function gatewayURL(value: unknown, serviceOrigin = ""): string {
  if (typeof value !== "string") throw new Error("Invalid Host ticket URL");
  const url = new URL(value);
  const next = url.searchParams.get("next");
  if ((url.protocol !== "https:" && !localGatewayOrigin(url, serviceOrigin)) || url.username || url.password || url.hash || url.pathname !== "/__ch/auth" ||
    url.searchParams.getAll("t").length !== 1 || !url.searchParams.get("t") ||
    url.searchParams.getAll("next").length > 1 ||
    [...url.searchParams.keys()].some((key) => key !== "t" && key !== "next") ||
    (next !== null && (!next.startsWith("/") || next.startsWith("//") || next.includes("\\")))) {
    throw new Error("Invalid Host ticket URL");
  }
  return url.href;
}

function validSession(value: unknown): WebSession {
  const response = value as Record<string, unknown>;
  if (!response || typeof response.web_session_credential !== "string" || !response.web_session_credential ||
    typeof response.web_session_expires_at !== "string" || credentialExpired(response.web_session_expires_at)) {
    throw new Error("Invalid Morde Web session response");
  }
  return { credential: response.web_session_credential, expiresAt: response.web_session_expires_at };
}

export class MordeAPI {
  constructor(private readonly credentials: () => Credentials | null) {}

  async login(originInput: unknown, name: unknown, password: unknown, key: string, renewalInstallationID?: string): Promise<{ credentials: Credentials; webSession: WebSession }> {
    const origin = portalOrigin(originInput);
    if (typeof name !== "string" || !name.trim() || typeof password !== "string" || !password ||
      !/^[A-Za-z0-9._~-]{1,128}$/.test(key)) throw new Error("Enter your Morde account and password");
    let response: Response;
    try {
      response = await fetch(`${origin}/api/auth/client-login`, {
        method: "POST",
        headers: { "content-type": "application/json", accept: "application/json", "Idempotency-Key": key },
        body: JSON.stringify({ name: name.trim(), password, platform: "desktop", display_name: "Morde Desktop",
          ...(renewalInstallationID ? { renewal_installation_id: renewalInstallationID } : {}) }),
        redirect: "error", signal: AbortSignal.timeout(20_000),
      });
    } catch { throw new Error("无法连接 Morde 服务，请检查网络和服务地址后重试。"); }
    if (!response.ok) {
      const body = await response.json().catch(() => null) as { error?: { code?: string } } | null;
      const messages: Record<string, string> = {
        unauthenticated: "用户名或密码错误，请重试。",
        account_pending: "账号正在等待管理员审核，通过后才能登录。",
        account_rejected: "账号审核未通过，请联系管理员。",
        account_disabled: "账号已被禁用，请联系管理员。",
        rate_limited: "登录尝试过于频繁，请稍后重试。",
        forbidden: "请先在管理后台修改密码，再登录客户端。",
      };
      throw new Error(messages[body?.error?.code ?? ""] ?? (response.status === 401 ? messages.unauthenticated : `Morde 登录失败（HTTP ${response.status}）。`));
    }
    const value = await response.json() as Record<string, unknown>;
    if (typeof value.installation_id !== "string" || !/^i[a-z0-9]{7}$/.test(value.installation_id) ||
      typeof value.client_credential !== "string" || !value.client_credential ||
      typeof value.client_expires_at !== "string" || credentialExpired(value.client_expires_at) ||
      typeof value.sync_credential !== "string" || !value.sync_credential ||
      typeof value.sync_expires_at !== "string" || credentialExpired(value.sync_expires_at)) {
      throw new Error("Invalid Morde client login response");
    }
    return {
      credentials: {
        origin, accountName: name.trim(), installationId: value.installation_id, clientCredential: value.client_credential,
        clientExpiresAt: value.client_expires_at, syncCredential: value.sync_credential,
        syncExpiresAt: value.sync_expires_at,
      },
      webSession: validSession(value),
    };
  }

  private async request(path: string, method = "GET"): Promise<unknown> {
    const auth = this.credentials();
    if (!auth || credentialExpired(auth.clientExpiresAt)) throw new Error("Log in to Morde again");
    const response = await fetch(`${auth.origin}${path}`, {
      method, headers: { authorization: `Bearer ${auth.clientCredential}`, accept: "application/json" },
      redirect: "error", signal: AbortSignal.timeout(20_000),
    });
    if (!response.ok) throw new Error(response.status === 401 ? "Authorization expired or revoked" : `Morde returned HTTP ${response.status}`);
    return response.status === 204 ? null : response.json();
  }

  async webSession(): Promise<WebSession> {
    return validSession(await this.request("/api/auth/client-web-session", "POST"));
  }

  async logout(): Promise<void> {
    await this.request("/api/auth/client-logout", "POST");
  }

  workspaces(): Promise<unknown> {
    return this.request("/api/workspaces");
  }

  workspace(id: unknown): Promise<unknown> {
    return this.request(`/api/workspaces/${checkedId("workspace", id)}`);
  }

  me(): Promise<unknown> {
    return this.request("/api/me");
  }

  host(id: unknown): Promise<unknown> {
    return this.request(`/api/hosts/${checkedId("host", id)}`);
  }

  sharedHosts(): Promise<unknown> {
    return this.request("/api/shared-hosts");
  }
}
