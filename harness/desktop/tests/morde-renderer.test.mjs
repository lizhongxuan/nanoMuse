import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

class Element {
  childNodes = [];
  hidden = false;
  value = '';
  textContent = '';
  className = '';
  disabled = false;
  onclick;
  onsubmit;
  append(...children) { this.childNodes.push(...children); }
  replaceChildren(...children) { this.childNodes = [...children]; }
}

async function mount(api) {
  const elements = new Map();
  const document = {
    getElementById(id) { if (!elements.has(id)) elements.set(id, new Element()); return elements.get(id); },
    createElement() { return new Element(); },
  };
  for (const id of ['origin', 'name', 'password', 'submit']) document.getElementById(id);
  let uuid = 0;
  const source = await readFile(new URL('../resources/morde.js', import.meta.url), 'utf8');
  vm.runInNewContext(source, { window: { morde: api }, document, crypto: { randomUUID: () => `retry-${++uuid}` } }, { filename: 'morde.js' });
  await new Promise((resolve) => setImmediate(resolve));
  return elements;
}

test('login UI needs only address, account and password; retry keeps one in-memory key', async () => {
  const calls = [];
  const api = {
    state: async () => ({ authenticated: false, origin: 'https://portal.example', storageReady: true, mappings: [], view: 'web' }),
    login: async (...args) => { calls.push(args); if (calls.length === 1) throw new Error("Error invoking remote method 'morde:login': Error: 用户名或密码错误，请重试。"); return { authenticated: true, origin: 'https://portal.example', storageReady: true, mappings: [], view: 'web' }; },
    onState() {}, onSync() {},
  };
  const elements = await mount(api);
  elements.get('name').value = 'user';
  elements.get('password').value = 'secret';
  elements.get('login-form').onsubmit({ preventDefault() {} });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(elements.get('message').textContent, '用户名或密码错误，请重试。');
  elements.get('login-form').onsubmit({ preventDefault() {} });
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls.map((call) => call[3]), ['retry-1', 'retry-1']);
  assert.equal(elements.get('password').value, '');
  assert.equal(elements.get('login').hidden, true);
  assert.equal(elements.has('user-code'), false);
});

test('local synchronization appears only on request and public pages take the entered origin', async () => {
  const calls = [];
  let current = { authenticated: true, origin: 'https://portal.example', storageReady: true, mappings: [], view: 'web' };
  const api = {
    state: async () => current,
    showSync: async () => { current = { ...current, view: 'sync' }; },
    workspaces: async () => ({ items: [] }),
    publicPage: async (...args) => calls.push(args),
    onState() {}, onSync() {},
  };
  const elements = await mount(api);
  assert.equal(elements.get('sync-page').hidden, true);
  elements.get('local-sync').onclick();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(elements.get('sync-page').hidden, false);
  elements.get('origin').value = 'https://portal.example';
  elements.get('register').onclick();
  await new Promise((resolve) => setImmediate(resolve));
  assert.deepEqual(calls[0], ['register', 'https://portal.example']);
});

test('sync result shows revision, transferred bytes and file preservation without raw JSON', async () => {
  const current = { authenticated: true, origin: 'https://portal.example', storageReady: true, view: 'sync', syncState: 'idle',
    mappings: [{ workspaceId: 'w1234567', directory: '/tmp/morde-test' }] };
  const elements = await mount({
    state: async () => current,
    workspaces: async () => ({ items: [{ id: 'w1234567', name: '验收', state: 'ready' }] }),
    sync: async (_id, mode) => mode === 'download'
      ? { session: { state: 'completed', target_revision: 1, confirmed_bytes: 37 }, conflicts: [{ path: 'conflict.txt' }] }
      : { revision: 1 },
    onState() {}, onSync() {},
  });
  const controls = elements.get('workspaces').childNodes[0].childNodes;
  controls.find((node) => node.textContent === '只补缺失').onclick();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(elements.get('message').textContent, '同步发现冲突，已暂停 · 云端 v1 · 已传输 37 B · 1 个冲突，本机和云端文件均已保留：conflict.txt · 仅补缺失，已有文件不覆盖');
  assert.equal(elements.get('message').className, 'error');
  controls.find((node) => node.textContent === '交接检查点').onclick();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(elements.get('message').textContent, '交接检查点已保存：v1');
});

test('secure storage failures surface before login', async () => {
  const elements = await mount({ state: async () => ({ authenticated: false, storageReady: false, mappings: [], view: 'web' }), onState() {}, onSync() {} });
  assert.match(elements.get('message').textContent, /系统安全存储不可用/);
  assert.equal(elements.get('message').className, 'error');
});

test('damaged local sync state is shown without offering sync actions', async () => {
  const warning = '本机同步恢复点无法读取，已暂停同步';
  const elements = await mount({
    state: async () => ({ authenticated: true, storageReady: true, mappings: [], view: 'sync', profileError: warning }),
    workspaces: async () => { throw new Error('must not fetch workspaces'); },
    onState() {}, onSync() {},
  });
  assert.equal(elements.get('workspaces').childNodes[0].textContent, warning);
  assert.equal(elements.get('workspaces').childNodes[0].className, 'error');
  assert.equal(elements.get('workspaces').childNodes.length, 1);
});

test('running LiveSync shows active state and prevents duplicate starts; uncertain stop keeps recovery warning', async () => {
  let onSync;
  let current = { authenticated: true, storageReady: true, view: 'sync', syncState: 'idle',
    syncCheckpoint: { workspaceId: 'w1234567', mode: 'live_sync' },
    mappings: [{ workspaceId: 'w1234567', directory: '/tmp/morde-test' }] };
  const elements = await mount({
    state: async () => current,
    workspaces: async () => ({ items: [{ id: 'w1234567', name: '验收', state: 'ready' }] }),
    stopSync: async () => { current = { ...current, syncState: 'shutdown_unknown' }; return false; },
    onState() {}, onSync: (handler) => { onSync = handler; },
  });
  onSync({ state: 'running', progress: { stage: 'watching' } });
  await new Promise((resolve) => setImmediate(resolve));
  let root = elements.get('workspaces');
  assert.equal(root.childNodes[0].textContent, '本机同步正在运行。');
  assert.equal(root.childNodes.some((node) => node.childNodes.some((child) => child.textContent.includes('尚待恢复'))), false);
  let controls = root.childNodes[1].childNodes;
  assert.equal(controls.find((node) => node.textContent === '实时同步').disabled, true);
  assert.equal(controls.find((node) => node.textContent === '停止同步').disabled, false);

  controls.find((node) => node.textContent === '停止同步').onclick();
  await new Promise((resolve) => setImmediate(resolve));
  root = elements.get('workspaces');
  assert.equal(root.childNodes[0].childNodes[0].textContent.includes('尚待恢复'), true);
  assert.equal(elements.get('message').textContent, '同步停止未确认，恢复点已保留');
  assert.equal(elements.get('message').className, 'error');
  controls = root.childNodes[1].childNodes;
  assert.equal(controls.find((node) => node.textContent === '实时同步').disabled, false);
  assert.equal(controls.find((node) => node.textContent === '停止同步').disabled, true);
});

test('a running sync remains stoppable while Workspace loading times out', async () => {
  let rejectWorkspaces, stopCount = 0;
  const request = new Promise((_, reject) => { rejectWorkspaces = reject; });
  const current = { authenticated: true, storageReady: true, view: 'sync', syncState: 'running', mappings: [] };
  const elements = await mount({
    state: async () => current,
    workspaces: async () => request,
    stopSync: async () => { stopCount++; return true; },
    onState() {}, onSync() {},
  });
  let root = elements.get('workspaces');
  assert.equal(root.childNodes[0].textContent, '正在读取 Workspace…');
  assert.equal(root.childNodes.find((node) => node.textContent === '停止同步').disabled, false);
  rejectWorkspaces(new Error('timeout'));
  await new Promise((resolve) => setImmediate(resolve));
  root = elements.get('workspaces');
  assert.equal(root.childNodes[0].textContent, '无法读取 Workspace，请检查网络或登录状态。');
  root.childNodes.find((node) => node.textContent === '停止同步').onclick();
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(stopCount, 1);
});

test('late Workspace response or error from a previous account cannot replace the current view', async () => {
  for (const failOld of [false, true]) {
    let onState, finishOld, rejectOld;
    const oldResponse = new Promise((resolve, reject) => { finishOld = resolve; rejectOld = reject; });
    let requests = 0;
    const elements = await mount({
      state: async () => ({ authenticated: true, origin: 'https://old.example', storageReady: true, mappings: [], view: 'sync' }),
      workspaces: async () => ++requests === 1 ? oldResponse : { items: [{ id: 'w1234567', name: '新账号目录', state: 'ready' }] },
      onState: (handler) => { onState = handler; }, onSync() {},
    });
    onState({ authenticated: true, origin: 'https://new.example', storageReady: true, mappings: [], view: 'sync' });
    await new Promise((resolve) => setImmediate(resolve));
    if (failOld) rejectOld(new Error('旧账号请求失败'));
    else finishOld({ items: [{ id: 'w7654321', name: '旧账号目录', state: 'ready' }] });
    await new Promise((resolve) => setImmediate(resolve));
    const contents = JSON.stringify(elements.get('workspaces').childNodes.map((card) => card.childNodes.map((item) => item.textContent)));
    assert.match(contents, /新账号目录/);
    assert.doesNotMatch(contents, /旧账号目录/);
    assert.doesNotMatch(elements.get('message').textContent, /旧账号请求失败/);
  }
});
