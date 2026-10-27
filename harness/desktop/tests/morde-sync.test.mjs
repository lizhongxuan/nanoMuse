import { test } from 'node:test';
import assert from 'node:assert/strict';
import { chmod, mkdtemp, mkdir, realpath, rm, symlink, writeFile } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { join, parse } from 'node:path';
import { checkedDirectory, MordeSync, verifyMapping } from '../out/morde-sync.js';

test('sync directory identity and overlap reject nested and aliased roots', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-desktop-'));
  try {
    const a = join(root, 'a'), nested = join(a, 'nested'), b = join(root, 'b'), alias = join(root, 'alias');
    await mkdir(nested, { recursive: true }); await mkdir(b); await symlink(a, alias);
    const first = { ...await checkedDirectory(a, []), workspaceId: 'w1234567' };
    assert.equal((await checkedDirectory(b, [first])).directory, await realpath(b));
    await assert.rejects(() => checkedDirectory(nested, [first]), /overlap/);
    await assert.rejects(() => checkedDirectory(alias, [first]), /overlap/);
    await assert.rejects(() => checkedDirectory(parse(root).root, []), /filesystem root/);
    await verifyMapping(first);
    const stale = { ...first, ino: '0' };
    await assert.rejects(() => verifyMapping(stale), /identity changed/);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('the Go stdio boundary receives the stored retry key and never a client credential', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-fake-'));
  try {
    const directory = join(root, 'project'), binary = join(root, 'fake-sync');
    await mkdir(directory);
    await writeFile(binary, `#!/usr/bin/env node
process.stdin.once('data', chunk => { const req = JSON.parse(String(chunk).trim()); process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:req.id,result:{session:{state:'completed'},params:req.params}})+'\\n'); process.exit(0); });
`);
    await chmod(binary, 0o700);
    const mapping = { ...await checkedDirectory(directory, []), workspaceId: 'w1234567' };
    let childPid;
    const sync = new MordeSync(() => binary, () => {}, (pid) => { childPid = pid; });
    const result = await sync.run({ origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: '2099-01-01T00:00:00Z' }, mapping, 'upload', [], { installationId: 'inst', ...mapping, mode: 'upload', idempotencyKey: 'same-key', sessionId: 'p1234567' });
    assert.equal(result.params.idempotency_key, 'same-key');
    assert.equal(result.params.session_id, 'p1234567');
    assert.equal(result.params.bearer_token, 'sync-secret');
    assert.ok(!JSON.stringify(result.params).includes('client-secret'));
    assert.ok(Number.isSafeInteger(childPid) && childPid > 0);
    assert.equal(sync.snapshot(), 'idle');
    assert.throws(() => process.kill(childPid, 0), { code: 'ESRCH' });
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('a missing or expired sync credential cannot start the sync child', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-credential-'));
  try {
    const mapping = { ...await checkedDirectory(root, []), workspaceId: 'w1234567' };
    const sync = new MordeSync(() => { throw new Error('child should not start'); }, () => {});
    await assert.rejects(() => sync.run({ origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z' }, mapping, 'upload'), /not authorized/);
    await assert.rejects(() => sync.run({ origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: 'invalid' }, mapping, 'upload'), /not authorized/);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('logout during folder verification cannot start a stale sync child', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-logout-race-'));
  try {
    const mapping = { ...await checkedDirectory(root, []), workspaceId: 'w1234567' };
    const auth = { origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: '2099-01-01T00:00:00Z' };
    let authorized = true;
    const sync = new MordeSync(() => { throw new Error('stale child must not start'); }, () => {});
    const running = sync.run(auth, mapping, 'upload', [], undefined, () => authorized);
    authorized = false;
    await assert.rejects(running, /authorization changed/);
    assert.equal(sync.snapshot(), 'idle');
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('a held directory lock is visible and does not leave the client stuck', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-lock-'));
  try {
    const binary = join(root, 'locked-sync');
    await writeFile(binary, `#!/usr/bin/env node
process.stdin.once('data', chunk => { const req = JSON.parse(String(chunk).trim()); process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:req.id,error:{code:-32010,message:'another Morde sync operation is active for this directory'}})+'\\n'); process.stdin.resume(); });
`);
    await chmod(binary, 0o700);
    const mapping = { ...await checkedDirectory(root, []), workspaceId: 'w1234567' };
    const auth = { origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: '2099-01-01T00:00:00Z' };
    const sync = new MordeSync(() => binary, () => {});
    await assert.rejects(() => sync.run(auth, mapping, 'live_sync'), /already syncing/);
    assert.equal(sync.snapshot(), 'idle');
    await assert.rejects(() => sync.run(auth, mapping, 'live_sync'), /already syncing/);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('a reused live PID does not block recovery when no Morde operation lock is held', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-pid-reuse-'));
  try {
    const binary = join(root, 'fake-sync'), lockPath = join(root, 'locked');
    await writeFile(binary, `#!/usr/bin/env node
const fs = require('node:fs');
if (process.argv[2] === '--probe-operation-lock') process.exit(fs.existsSync(${JSON.stringify(lockPath)}) ? 3 : 0);
process.stdin.resume();
`);
    await chmod(binary, 0o700);
    const checkpoint = { childPid: process.pid, directory: root };
    const sync = new MordeSync(() => binary, () => {});
    assert.equal(sync.checkpointMayOwnDirectory(checkpoint), false);
    assert.equal(sync.discardCheckpoint(checkpoint), true);
    await writeFile(lockPath, 'held');
    assert.equal(sync.checkpointMayOwnDirectory(checkpoint), true);
    assert.equal(sync.discardCheckpoint(checkpoint), false);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('sync shutdown is confirmed only after the child acknowledges cancellation', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-stop-'));
  try {
    const directory = join(root, 'project');
    await mkdir(directory);
    const mapping = { ...await checkedDirectory(directory, []), workspaceId: 'w1234567' };
    const auth = { origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: '2099-01-01T00:00:00Z' };
    for (const acknowledged of [true, false]) {
      const binary = join(root, acknowledged ? 'ack-sync' : 'unacked-sync');
      await writeFile(binary, `#!/usr/bin/env node
let buffer='', requestId;
process.stdin.on('data', chunk => { buffer += chunk; let end; while ((end = buffer.indexOf('\\n')) >= 0) { const line = buffer.slice(0,end); buffer = buffer.slice(end+1); const req = JSON.parse(line); if (req.method === 'sync') requestId = req.id; if (req.method === 'cancel') { ${acknowledged ? "process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:req.id,result:{cancelled:true}})+'\\n');" : ''} process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:requestId,error:{code:-32010,message:'sync cancelled'}})+'\\n'); } } });
`);
      await chmod(binary, 0o700);
      let started;
      const ready = new Promise((resolve) => { started = resolve; });
      const sync = new MordeSync(() => binary, () => {}, started);
      const running = sync.run(auth, mapping, 'upload');
      await ready;
      assert.equal(await sync.stop(), acknowledged);
      await assert.rejects(running, /Sync failed/);
      assert.equal(sync.snapshot(), acknowledged ? 'idle' : 'shutdown_unknown');
    }
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('an unacknowledged stop keeps its checkpoint and recovers idempotently after the child exits', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-recovery-'));
  try {
    const directory = join(root, 'project'), unackedBinary = join(root, 'unacked-sync'), successBinary = join(root, 'success-sync');
    await mkdir(directory);
    await writeFile(unackedBinary, `#!/usr/bin/env node
if (process.argv[2] === '--probe-operation-lock') process.exit(3);
let buffer='', requestId;
process.stdin.on('data', chunk => { buffer += chunk; let end; while ((end = buffer.indexOf('\\n')) >= 0) { const line = buffer.slice(0,end); buffer = buffer.slice(end+1); const req = JSON.parse(line); if (req.method === 'sync') requestId = req.id; if (req.method === 'cancel') process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:requestId,error:{code:-32010,message:'sync cancelled'}})+'\\n'); } });
`);
    await writeFile(successBinary, `#!/usr/bin/env node
process.stdin.once('data', chunk => { const req = JSON.parse(String(chunk).trim()); process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:req.id,result:{session:{state:'completed'},params:req.params}})+'\\n'); process.exit(0); });
`);
    await chmod(unackedBinary, 0o700);
    await chmod(successBinary, 0o700);
    const mapping = { ...await checkedDirectory(directory, []), workspaceId: 'w1234567' };
    const auth = { origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: '2099-01-01T00:00:00Z' };
    const checkpoint = { installationId: 'inst', ...mapping, mode: 'upload', idempotencyKey: 'stable-recovery-key', sessionId: 'p1234567' };
    let checkpointForStart = checkpoint;
    let invocation = 0;
    const sync = new MordeSync(() => invocation++ === 0 ? unackedBinary : successBinary, () => {}, (pid) => { checkpointForStart.childPid = pid; });

    const firstRun = sync.run(auth, mapping, 'upload', [], checkpoint);
    while (!checkpoint.childPid) await new Promise((resolve) => setImmediate(resolve));
    const firstPid = checkpoint.childPid;
    assert.equal(await sync.stop(), false);
    await assert.rejects(firstRun, /Sync failed/);
    assert.equal(sync.snapshot(), 'shutdown_unknown');
    assert.equal(checkpoint.childPid, firstPid);
    assert.throws(() => process.kill(firstPid, 0), { code: 'ESRCH' });

    const persisted = { ...checkpoint };
    const liveCheckpoint = { ...checkpoint, childPid: process.pid };
    await assert.rejects(() => sync.run(auth, mapping, 'upload', [], liveCheckpoint), /prior shutdown is unverified/);
    assert.equal(await sync.stop(), false);

    checkpointForStart = persisted;
    const recovered = await sync.run(auth, mapping, 'upload', [], persisted);
    assert.equal(recovered.params.idempotency_key, persisted.idempotencyKey);
    assert.equal(recovered.params.session_id, persisted.sessionId);
    assert.notEqual(persisted.childPid, firstPid);
    assert.equal(sync.snapshot(), 'idle');
    assert.equal(invocation, 2);
  } finally { await rm(root, { recursive: true, force: true }); }
});

test('discard releases only a matching shutdown checkpoint after its child exits', async () => {
  const root = await mkdtemp(join(tmpdir(), 'morde-sync-discard-'));
  const originalKill = process.kill;
  try {
    const directory = join(root, 'project'), unackedBinary = join(root, 'unacked-sync'), successBinary = join(root, 'success-sync');
    await mkdir(directory);
    await writeFile(unackedBinary, `#!/usr/bin/env node
if (process.argv[2] === '--probe-operation-lock') process.exit(3);
let buffer='', requestId;
process.stdin.on('data', chunk => { buffer += chunk; let end; while ((end = buffer.indexOf('\\n')) >= 0) { const line = buffer.slice(0,end); buffer = buffer.slice(end+1); const req = JSON.parse(line); if (req.method === 'sync') requestId = req.id; if (req.method === 'cancel') process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:requestId,error:{code:-32010,message:'sync cancelled'}})+'\\n'); } });
`);
    await writeFile(successBinary, `#!/usr/bin/env node
process.stdin.once('data', chunk => { const req = JSON.parse(String(chunk).trim()); process.stdout.write(JSON.stringify({jsonrpc:'2.0',id:req.id,result:{session:{state:'completed'},params:req.params}})+'\\n'); process.exit(0); });
`);
    await chmod(unackedBinary, 0o700);
    await chmod(successBinary, 0o700);
    const mapping = { ...await checkedDirectory(directory, []), workspaceId: 'w1234567' };
    const auth = { origin: 'https://portal.example', installationId: 'inst', clientCredential: 'client-secret', clientExpiresAt: '2099-01-01T00:00:00Z', syncCredential: 'sync-secret', syncExpiresAt: '2099-01-01T00:00:00Z' };
    const checkpoint = { installationId: 'inst', ...mapping, mode: 'upload', idempotencyKey: 'discarded-key' };
    let checkpointForStart = checkpoint;
    let invocation = 0;
    const sync = new MordeSync(() => invocation++ === 0 ? unackedBinary : successBinary, () => {}, (pid) => { checkpointForStart.childPid = pid; });

    const firstRun = sync.run(auth, mapping, 'upload', [], checkpoint);
    while (!checkpoint.childPid) await new Promise((resolve) => setImmediate(resolve));
    const firstPid = checkpoint.childPid;
    assert.equal(await sync.stop(), false);
    await assert.rejects(firstRun, /Sync failed/);
    assert.equal(sync.snapshot(), 'shutdown_unknown');

    process.kill = (pid, signal) => pid === firstPid && signal === 0 ? true : originalKill(pid, signal);
    assert.equal(sync.discardCheckpoint(checkpoint), false);
    assert.equal(sync.snapshot(), 'shutdown_unknown');
    process.kill = originalKill;
    assert.equal(sync.discardCheckpoint({ ...checkpoint, childPid: process.pid }), false);
    assert.equal(sync.snapshot(), 'shutdown_unknown');
    assert.equal(sync.discardCheckpoint(checkpoint), true);
    assert.equal(sync.snapshot(), 'idle');

    const restarted = { installationId: 'inst', ...mapping, mode: 'upload', idempotencyKey: 'fresh-key' };
    checkpointForStart = restarted;
    const result = await sync.run(auth, mapping, 'upload', [], restarted);
    assert.equal(result.params.idempotency_key, 'fresh-key');
    assert.notEqual(restarted.childPid, firstPid);
    assert.equal(sync.snapshot(), 'idle');
    assert.equal(invocation, 2);
  } finally {
    process.kill = originalKill;
    await rm(root, { recursive: true, force: true });
  }
});
