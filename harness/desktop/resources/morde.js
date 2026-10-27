const api = window.morde;
const $ = (id) => document.getElementById(id);
let state = null;
let pendingLogin = null;

function message(value, error = false) {
  $('message').textContent = value;
  $('message').className = error ? 'error' : '';
}
function errorMessage(error) { return (error?.message || String(error)).replace(/^Error invoking remote method '[^']+': Error: /, ''); }
async function run(action) {
  try { message(''); return await action(); }
  catch (error) { message(errorMessage(error), true); return null; }
}
function text(tag, value, className) {
  const element = document.createElement(tag);
  element.textContent = value;
  if (className) element.className = className;
  return element;
}
function button(label, action) {
  const element = text('button', label);
  element.type = 'button';
  element.onclick = () => void run(action);
  return element;
}
function items(value) { return Array.isArray(value?.items) ? value.items : Array.isArray(value) ? value : []; }
function syncSummary(result, mode) {
  if (mode === 'handoff_checkpoint' && Number.isInteger(result?.revision)) return `交接检查点已保存：v${result.revision}`;
  const session = result?.session;
  if (!session) return '同步结果无法确认，请检查工作区状态。';
  const conflicts = Array.isArray(result.conflicts) ? result.conflicts : [];
  const paths = conflicts.map((item) => item.path).filter(Boolean).slice(0, 3).join('、');
  return [conflicts.length || session.state === 'conflict' ? '同步发现冲突，已暂停' : session.state === 'completed' ? '同步完成' : `同步状态：${session.state || '未知'}`,
    Number.isInteger(session.target_revision) ? `云端 v${session.target_revision}` : '',
    Number.isInteger(session.confirmed_bytes) ? `已传输 ${session.confirmed_bytes} B` : '',
    conflicts.length ? `${conflicts.length} 个冲突，本机和云端文件均已保留${paths ? `：${paths}` : ''}` : '',
    mode === 'download' ? '仅补缺失，已有文件不覆盖' : ''].filter(Boolean).join(' · ');
}

function stopSyncButton() {
  const stop = button('停止同步', async () => {
    const stopped = await api.stopSync();
    renderState(await api.state());
    message(stopped ? '同步已停止' : '同步停止未确认，恢复点已保留', !stopped);
  });
  stop.disabled = state.syncState !== 'running';
  return stop;
}

function renderState(value) {
  state = value;
  $('login').hidden = value.authenticated;
  $('navigation').hidden = !value.authenticated;
  $('sync-page').hidden = !value.authenticated || value.view !== 'sync';
  $('account').textContent = value.authenticated ? value.origin : '';
  $('expiry-warning').hidden = !value.expiresSoon;
  if (!value.authenticated) {
    if (value.origin && !$('origin').value) $('origin').value = value.origin;
    if (!value.storageReady) message('系统安全存储不可用，请解锁 Keychain、GNOME Keyring 或 KDE Wallet。', true);
  } else if (value.view === 'sync') void renderWorkspaces();
}

async function renderWorkspaces() {
  const root = $('workspaces');
  const current = state;
  if (state.profileError) { root.replaceChildren(text('p', state.profileError, 'error')); return; }
  const status = text('p', '正在读取 Workspace…', 'muted');
  root.replaceChildren(status);
  if (state.syncState === 'running') root.append(text('p', '本机同步正在运行。', 'muted'), stopSyncButton());
  let data;
  try { message(''); data = await api.workspaces(); }
  catch (error) {
    if (state !== current) return;
    message(errorMessage(error), true);
    status.textContent = '无法读取 Workspace，请检查网络或登录状态。';
    status.className = 'error';
    return;
  }
  if (state !== current || !state.authenticated || state.view !== 'sync') return;
  if (data === null) { status.textContent = '无法读取 Workspace，请检查网络或登录状态。'; status.className = 'error'; return; }
  root.replaceChildren();
  const running = state.syncState === 'running';
  if (running) root.append(text('p', '本机同步正在运行。', 'muted'));
  else if (state.syncCheckpoint) {
    const warning = text('div', '', 'card');
    warning.append(text('p', `上次 ${state.syncCheckpoint.workspaceId} 的 ${state.syncCheckpoint.mode} 尚待恢复。请使用相同操作恢复，或明确放弃恢复点。`, 'error'));
    warning.append(button('放弃上次恢复点', async () => renderState(await api.discardSync())));
    root.append(warning);
  }
  for (const workspace of items(data)) {
    const card = text('div', '', 'card');
    const mapping = state.mappings.find((item) => item.workspaceId === workspace.id);
    card.append(text('strong', `${workspace.name || workspace.id} · ${workspace.state || ''}`));
    card.append(text('p', mapping?.directory || '尚未选择本机目录', 'muted'));
    if (workspace.state === 'ready') {
      const choose = button('选择目录', async () => { await api.chooseDirectory(workspace.id); renderState(await api.state()); });
      choose.disabled = running;
      card.append(choose);
      if (mapping) {
        for (const [label, mode] of [['上传', 'upload'], ['只补缺失', 'download'], ['双向补缺失', 'bidirectional'], ['实时同步', 'live_sync'], ['交接检查点', 'handoff_checkpoint']]) {
          const action = button(label, async () => {
            let result;
            try { result = await api.sync(workspace.id, mode); }
            finally { renderState(await api.state()); }
            message(syncSummary(result, mode), (Array.isArray(result?.conflicts) && result.conflicts.length > 0) || result?.session?.state === 'conflict' || (!result?.session && !(mode === 'handoff_checkpoint' && Number.isInteger(result?.revision))));
          });
          action.disabled = running;
          card.append(action);
        }
        card.append(stopSyncButton());
      }
    } else card.append(text('p', '此 Workspace 当前不可同步。', 'muted'));
    root.append(card);
  }
  if (!root.childNodes.length) root.append(text('p', '暂无 Workspace。'));
}

$('login-form').onsubmit = (event) => {
  event.preventDefault();
  void run(async () => {
    const origin = $('origin').value.trim(), name = $('name').value.trim(), password = $('password').value;
    if (!pendingLogin || pendingLogin.origin !== origin || pendingLogin.name !== name || pendingLogin.password !== password) pendingLogin = { origin, name, password, key: crypto.randomUUID() };
    $('submit').disabled = true;
    try {
      renderState(await api.login(origin, name, password, pendingLogin.key));
      $('password').value = '';
      pendingLogin = null;
    } finally { $('submit').disabled = false; }
  });
};
$('register').onclick = () => void run(() => api.publicPage('register', $('origin').value.trim()));
$('download').onclick = () => void run(() => api.publicPage('download', $('origin').value.trim()));
$('web').onclick = () => void run(async () => { await api.showWeb(); renderState(await api.state()); });
$('local-sync').onclick = () => void run(async () => { await api.showSync(); renderState(await api.state()); });
$('logout').onclick = () => void run(async () => { const warning = await api.logout(); renderState(await api.state()); if (warning) message(warning, true); });
api.onState(renderState);
api.onSync((value) => {
  message(value.message || `同步：${value.state}${value.progress?.stage ? ` · ${value.progress.stage}` : ''}`, value.state === 'offline' || value.state === 'shutdown_unknown');
  if (value.state === 'running' && state?.view === 'sync' && state.syncState !== 'running') {
    state.syncState = 'running';
    void renderWorkspaces();
  }
});
void run(async () => renderState(await api.state()));
