import { test } from 'node:test';
import assert from 'node:assert/strict';
import { MordeAPI, checkedId, credentialExpired, credentialExpiresSoon, gatewayURL, portalOrigin } from '../out/morde-core.js';

const future = '2099-01-01T00:00:00Z';
const credentials = { origin: 'https://portal.example', installationId: 'i1234567', clientCredential: 'client-secret', clientExpiresAt: future, syncCredential: 'sync-secret', syncExpiresAt: future };

test('expiry, origins, IDs and Host ticket URLs reject malformed values', () => {
  const now = Date.parse('2026-10-26T00:00:00Z');
  assert.equal(credentialExpiresSoon(new Date(now + 7 * 86400_000).toISOString(), now), true);
  assert.equal(credentialExpiresSoon(new Date(now + 7 * 86400_000 + 1).toISOString(), now), false);
  assert.equal(credentialExpired('invalid', now), true);
  assert.equal(portalOrigin('https://portal.example/'), 'https://portal.example');
  assert.equal(portalOrigin('http://localhost:8080'), 'http://localhost:8080');
  assert.equal(portalOrigin('http://portal.localhost'), 'http://portal.localhost');
  for (const value of ['http://portal.example', 'https://user:pass@portal.example', 'https://portal.example/path', 'https://portal.example?x=1']) assert.throws(() => portalOrigin(value));
  assert.equal(checkedId('host', 'h1234567'), 'h1234567');
  assert.throws(() => checkedId('host', '../admin'));
  assert.equal(gatewayURL('https://h1234567.example/__ch/auth?t=one-time'), 'https://h1234567.example/__ch/auth?t=one-time');
  assert.equal(gatewayURL('http://h1234567.hosts.localhost/__ch/auth?t=one-time', 'http://localhost'), 'http://h1234567.hosts.localhost/__ch/auth?t=one-time');
  assert.equal(gatewayURL('http://h1234567.hosts.localhost/__ch/auth?t=one-time', 'http://portal.localhost'), 'http://h1234567.hosts.localhost/__ch/auth?t=one-time');
  assert.throws(() => gatewayURL('http://h1234567.hosts.localhost/__ch/auth?t=one-time', 'https://portal.example'));
  assert.throws(() => gatewayURL('http://evil.hosts.localhost/__ch/auth?t=one-time', 'http://localhost'));
  for (const value of ['https://evil.example/__ch/auth?ticket=wrong', 'http://h1234567.example/__ch/auth?t=one-time', 'https://h1234567.example/__ch/auth?t=one&t=two', 'https://h1234567.example/__ch/auth?t=one&next=%2F%5Cevil.example']) assert.throws(() => gatewayURL(value));
});

test('account login sends one password request and receives separate Client, Sync and Web credentials', async () => {
  const originalFetch = globalThis.fetch;
  const calls = [];
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return new Response(JSON.stringify({ installation_id: 'i1234567', client_credential: 'client-secret', client_expires_at: future, sync_credential: 'sync-secret', sync_expires_at: future, web_session_credential: 'web-secret', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  };
  try {
    const result = await new MordeAPI(() => null).login('https://portal.example', ' user ', 'password', 'retry-1');
    assert.equal(calls.length, 1);
    assert.equal(calls[0].url, 'https://portal.example/api/auth/client-login');
    assert.equal(calls[0].options.headers['Idempotency-Key'], 'retry-1');
    assert.deepEqual(JSON.parse(calls[0].options.body), { name: 'user', password: 'password', platform: 'desktop', display_name: 'Morde Desktop' });
    assert.equal(result.credentials.clientCredential, 'client-secret');
    assert.equal(result.credentials.syncCredential, 'sync-secret');
    assert.equal(result.webSession.credential, 'web-secret');
    assert.equal('workspaceIds' in result.credentials, false);
    await new MordeAPI(() => null).login('https://portal.example', 'user', 'password', 'retry-2', 'i1234567');
    assert.equal(JSON.parse(calls[1].options.body).renewal_installation_id, 'i1234567');
  } finally { globalThis.fetch = originalFetch; }
});

test('web renewal and logout only use the fixed Client bearer routes', async () => {
  const originalFetch = globalThis.fetch;
  const calls = [];
  globalThis.fetch = async (url, options) => {
    calls.push({ url, options });
    return url.endsWith('client-logout') ? new Response(null, { status: 204 }) : new Response(JSON.stringify({ web_session_credential: 'new-web-secret', web_session_expires_at: future }), { headers: { 'content-type': 'application/json' } });
  };
  try {
    const api = new MordeAPI(() => credentials);
    assert.equal((await api.webSession()).credential, 'new-web-secret');
    await api.logout();
    assert.deepEqual(calls.map((call) => call.url), ['https://portal.example/api/auth/client-web-session', 'https://portal.example/api/auth/client-logout']);
    assert.ok(calls.every((call) => call.options.headers.authorization === 'Bearer client-secret'));
    assert.equal(calls.every((call) => !call.options.body), true);
  } finally { globalThis.fetch = originalFetch; }
});

test('invalid login responses and expired Client credentials fail closed', async () => {
  const originalFetch = globalThis.fetch;
  let calls = 0;
  globalThis.fetch = async () => { calls += 1; return new Response(JSON.stringify({ installation_id: 'i1234567', client_credential: 'secret', client_expires_at: future }), { headers: { 'content-type': 'application/json' } }); };
  try {
    await assert.rejects(() => new MordeAPI(() => null).login('https://portal.example', 'u', 'p', 'retry-1'), /Invalid Morde client login response/);
    await assert.rejects(() => new MordeAPI(() => ({ ...credentials, clientExpiresAt: 'invalid' })).workspaces(), /Log in to Morde again/);
    assert.equal(calls, 1);
  } finally { globalThis.fetch = originalFetch; }
});

test('client login explains account policy errors and offline failure', async () => {
  const originalFetch = globalThis.fetch;
  try {
    for (const [code, status, message] of [
      ['unauthenticated', 401, /用户名或密码错误/],
      ['account_pending', 403, /等待管理员审核/],
      ['account_rejected', 403, /审核未通过/],
      ['account_disabled', 403, /已被禁用/],
      ['rate_limited', 429, /过于频繁/],
      ['forbidden', 403, /修改密码/],
    ]) {
      globalThis.fetch = async () => new Response(JSON.stringify({ error: { code } }), { status, headers: { 'content-type': 'application/json' } });
      await assert.rejects(() => new MordeAPI(() => null).login('https://portal.example', 'user', 'password', 'retry-key'), message);
    }
    globalThis.fetch = async () => { throw new TypeError('connect failed'); };
    await assert.rejects(() => new MordeAPI(() => null).login('https://portal.example', 'user', 'password', 'retry-key'), /检查网络和服务地址/);
  } finally { globalThis.fetch = originalFetch; }
});
