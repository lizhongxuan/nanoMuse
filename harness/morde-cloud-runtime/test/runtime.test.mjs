import assert from 'node:assert/strict'
import { createHash } from 'node:crypto'
import { spawn } from 'node:child_process'
import { once } from 'node:events'
import { createInterface } from 'node:readline'
import test from 'node:test'
import { modelCallID } from '../src/engine.mjs'

const start = {
  type: 'start', version: 1, task_id: 'task_123', owner_id: 'user_123',
  agent_id: 'agent_123', generation: 1, authorization_version: 1,
  session_id: 'session_456', model: 'test-model', prompt: 'Hello from a local test',
}

function launch(onFrame, extraEnv = {}) {
  const child = spawn(process.execPath, ['bin.mjs'], {
    cwd: new URL('..', import.meta.url),
    env: { PATH: process.env.PATH, LANG: 'C.UTF-8', ...extraEnv },
    stdio: ['pipe', 'pipe', 'pipe'],
  })
  const frames = []
  const lines = createInterface({ input: child.stdout })
  lines.on('line', line => {
    const frame = JSON.parse(line)
    frames.push(frame)
    onFrame(frame, child)
  })
  return { child, frames }
}

function send(child, frame) {
  child.stdin.write(`${JSON.stringify(frame)}\n`)
}

test('model ID has a stable cross-language test vector', () => {
  assert.equal(modelCallID('task_123', 'session_456', 7), 'mdl_2aef0005101ead56ee43e897a0c630a0c67e253476dbfb3fe3c0ae571c147b83')
  assert.throws(() => modelCallID('task\n123', 'session_456', 7))
})

test('real dsh runs only after worker confirms its events', async () => {
  let through = -1
  let calls = 0
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, start)
    if (frame.type === 'checkpoint') {
      const payload = JSON.parse(frame.payload)
      assert.equal(frame.from_seq, through + 1)
      assert.equal(payload.from_seq, frame.from_seq)
      assert.equal(payload.header.id, start.session_id)
      assert.equal(createHash('sha256').update(frame.payload).digest('hex'), frame.sha256)
      assert.equal(payload.events.at(-1).seq, frame.through_seq)
      through = frame.through_seq
      send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: through, sha256: frame.sha256 })
    }
    if (frame.type === 'model') {
      calls += 1
      assert.equal(frame.through_seq, through)
      assert.equal(frame.id, modelCallID(start.task_id, start.session_id, through))
      assert.equal(frame.sha256, createHash('sha256').update(JSON.stringify(frame.request)).digest('hex'))
      assert.equal(frame.request.model, start.model)
      assert.deepEqual(frame.request.tools, [])
      assert.ok(frame.request.messages.some(message => message.role === 'user' && message.content.some(block => block.text === start.prompt)))
      const chunks = [
        { type: 'block-start', index: 0, blockType: 'text' },
        { type: 'text-delta', index: 0, text: 'hello' },
        { type: 'block-end', index: 0, block: { type: 'text', text: 'hello' } },
        { type: 'usage', usage: { inputTokens: 2, outputTokens: 1 } },
        { type: 'finish', reason: { kind: 'stop' } },
      ]
      chunks.forEach((chunk, index) => send(proc, { type: 'model_chunk', id: frame.id, index, chunk }))
      send(proc, { type: 'model_end', id: frame.id, ok: true })
    }
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 0, `frames: ${frames.map(frame => frame.type).join(', ')}`)
  assert.equal(calls, 1)
  const settled = frames.find(frame => frame.type === 'settled')
  assert.equal(settled?.state, 'completed_candidate')
  assert.equal(settled.through_seq, through)
  assert.ok(frames.some(frame => frame.type === 'checkpoint' && JSON.parse(frame.payload).events.some(event => event.type === 'assistant/message')))
})

test('a refused checkpoint prevents a model call', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, start)
    if (frame.type === 'checkpoint') send(proc, { type: 'checkpoint_ack', id: frame.id, ok: false, through_seq: frame.through_seq, sha256: frame.sha256 })
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 1)
  assert.equal(frames.some(frame => frame.type === 'model'), false)
  assert.equal(frames.find(frame => frame.type === 'failed')?.code, 'runtime_unavailable')
})

test('rejects an inherited secret-bearing environment before ready', async () => {
  const { child, frames } = launch(() => {}, { TEST_SECRET: 'not-for-child' })
  const [code] = await once(child, 'close')
  assert.equal(code, 1)
  assert.equal(frames.some(frame => frame.type === 'ready'), false)
})

test('rejects recovery without a pinned checkpoint and with a replayed prompt', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, { ...start, resume: true })
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 1)
  assert.equal(frames.some(frame => frame.type === 'model'), false)
})

test('cancelling before the agent starts does not dispatch a model', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') {
      send(proc, start)
      send(proc, { type: 'cancel' })
    }
    if (frame.type === 'checkpoint') send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: frame.through_seq, sha256: frame.sha256 })
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 0)
  assert.equal(frames.some(frame => frame.type === 'model'), false)
  assert.equal(frames.find(frame => frame.type === 'settled')?.state, 'cancelled')
})

test('cancelling an active model asks the worker to stop and drains the agent', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, start)
    if (frame.type === 'checkpoint') send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: frame.through_seq, sha256: frame.sha256 })
    if (frame.type === 'model') send(proc, { type: 'cancel' })
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 0)
  assert.ok(frames.some(frame => frame.type === 'model_cancel'))
  assert.equal(frames.find(frame => frame.type === 'settled')?.state, 'cancelled')
})

test('refuses a model-requested tool until its gate is available', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, start)
    if (frame.type === 'checkpoint') send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: frame.through_seq, sha256: frame.sha256 })
    if (frame.type === 'model') send(proc, { type: 'model_chunk', id: frame.id, index: 0, chunk: { type: 'tool-call-delta', index: 0, id: 'call_denied', name: 'not_registered', argumentsDelta: '{}' } })
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 0)
  assert.ok(frames.some(frame => frame.type === 'model_cancel'))
  assert.equal(frames.find(frame => frame.type === 'settled')?.state, 'failed')
  assert.equal(frames.filter(frame => frame.type === 'model').length, 1)
})

test('rejects a start tool with an open parameter schema', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, {
      ...start,
      tools: [{ name: 'file_read', description: 'Read a file.', parameters: { type: 'object', properties: {}, additionalProperties: true } }],
    })
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 1)
  assert.equal(frames.some(frame => frame.type === 'checkpoint' || frame.type === 'model'), false)
})

test('runs an authorized dsh tool through the parent and persists its result before the next model call', async () => {
  const tool = {
    name: 'file_write',
    description: 'Write a file in the task workspace.',
    parameters: {
      type: 'object',
      properties: {
        workspace_id: { type: 'string' },
        path: { type: 'string' },
        content: { type: 'string' },
      },
      required: ['workspace_id', 'path', 'content'],
      additionalProperties: false,
    },
  }
  const launchFrame = { ...start, tools: [tool] }
  let through = -1
  let modelCalls = 0
  const pages = []
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, launchFrame)
    if (frame.type === 'checkpoint') {
      const page = JSON.parse(frame.payload)
      pages.push(page)
      assert.equal(frame.from_seq, through + 1)
      through = frame.through_seq
      send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: through, sha256: frame.sha256 })
    }
    if (frame.type === 'model') {
      modelCalls += 1
      assert.equal(frame.through_seq, through)
      assert.deepEqual(frame.request.tools, [tool])
      if (modelCalls === 1) {
        const chunks = [
          { type: 'tool-call-delta', index: 0, id: 'call_write_1', name: tool.name, argumentsDelta: '{"workspace_id":"w1234567","path":"notes.txt","content":"saved"}' },
          { type: 'usage', usage: { inputTokens: 3, outputTokens: 2 } },
          { type: 'finish', reason: { kind: 'tool-calls' } },
        ]
        chunks.forEach((chunk, index) => send(proc, { type: 'model_chunk', id: frame.id, index, chunk }))
        send(proc, { type: 'model_end', id: frame.id, ok: true })
      } else {
        const resultMessage = frame.request.messages.find(message => message.role === 'tool' && message.toolCallId === 'call_write_1')
        assert.ok(resultMessage, 'next model request includes the persisted tool result message')
        assert.equal(resultMessage.content[0].text, '{"bytes_written":5}')
        const chunks = [
          { type: 'block-start', index: 0, blockType: 'text' },
          { type: 'text-delta', index: 0, text: 'file saved' },
          { type: 'block-end', index: 0, block: { type: 'text', text: 'file saved' } },
          { type: 'usage', usage: { inputTokens: 4, outputTokens: 2 } },
          { type: 'finish', reason: { kind: 'stop' } },
        ]
        chunks.forEach((chunk, index) => send(proc, { type: 'model_chunk', id: frame.id, index, chunk }))
        send(proc, { type: 'model_end', id: frame.id, ok: true })
      }
    }
    if (frame.type === 'tool_call') {
      assert.equal(frame.task_id, start.task_id)
      assert.equal(frame.owner_id, start.owner_id)
      assert.equal(frame.agent_id, start.agent_id)
      assert.equal(frame.generation, start.generation)
      assert.equal(frame.authorization_version, start.authorization_version)
      assert.equal(frame.session_id, start.session_id)
      assert.equal(frame.through_seq, through)
      assert.equal(frame.name, tool.name)
      assert.deepEqual(frame.arguments, { workspace_id: 'w1234567', path: 'notes.txt', content: 'saved' })
      const events = pages.flatMap(page => page.events)
      assert.ok(events.some(event => event.type === 'assistant/message' && event.data.message.content.some(block => block.type === 'tool-call')))
      assert.ok(events.some(event => event.type === 'tool/call' && event.data.callId === frame.call_id))
      assert.ok(!events.some(event => event.type === 'tool/result' && event.data.message?.toolCallId === frame.call_id))
      send(proc, {
        type: 'tool_result', id: frame.id,
        task_id: frame.task_id, owner_id: frame.owner_id, agent_id: frame.agent_id,
        generation: frame.generation, authorization_version: frame.authorization_version,
        session_id: frame.session_id, call_id: frame.call_id,
        status: 'succeeded', output: '{"bytes_written":5}',
      })
    }
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 0, `frames: ${frames.map(frame => frame.type).join(', ')}`)
  assert.equal(modelCalls, 2)
  const events = pages.flatMap(page => page.events)
  assert.ok(events.some(event => event.type === 'tool/result' && event.data.message?.toolCallId === 'call_write_1'))
  assert.equal(frames.find(frame => frame.type === 'settled')?.state, 'completed_candidate')
})

test('rejects an unknown tool result without starting another model call', async () => {
  const tool = {
    name: 'file_read', description: 'Read a workspace file.',
    parameters: { type: 'object', properties: {}, additionalProperties: false },
  }
  let modelCalls = 0
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, { ...start, tools: [tool] })
    if (frame.type === 'checkpoint') send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: frame.through_seq, sha256: frame.sha256 })
    if (frame.type === 'model') {
      modelCalls += 1
      const chunks = [
        { type: 'tool-call-delta', index: 0, id: 'call_unknown_1', name: tool.name, argumentsDelta: '{}' },
        { type: 'usage', usage: { inputTokens: 1, outputTokens: 1 } },
        { type: 'finish', reason: { kind: 'tool-calls' } },
      ]
      chunks.forEach((chunk, index) => send(proc, { type: 'model_chunk', id: frame.id, index, chunk }))
      send(proc, { type: 'model_end', id: frame.id, ok: true })
    }
    if (frame.type === 'tool_call') {
      send(proc, {
        type: 'tool_result', id: frame.id,
        task_id: frame.task_id, owner_id: frame.owner_id, agent_id: frame.agent_id,
        generation: frame.generation, authorization_version: frame.authorization_version,
        session_id: frame.session_id, call_id: frame.call_id,
        status: 'unknown', output: 'operation state is unknown',
      })
    }
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 1)
  assert.equal(modelCalls, 1)
  assert.equal(frames.some(frame => frame.type === 'settled'), false)
})

test('fails closed when the parent disconnects before confirming a tool result', async () => {
  const tool = {
    name: 'file_read', description: 'Read a workspace file.',
    parameters: { type: 'object', properties: {}, additionalProperties: false },
  }
  let modelCalls = 0
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, { ...start, tools: [tool] })
    if (frame.type === 'checkpoint') send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: frame.through_seq, sha256: frame.sha256 })
    if (frame.type === 'model') {
      modelCalls += 1
      const chunks = [
        { type: 'tool-call-delta', index: 0, id: 'call_disconnected_1', name: tool.name, argumentsDelta: '{}' },
        { type: 'usage', usage: { inputTokens: 1, outputTokens: 1 } },
        { type: 'finish', reason: { kind: 'tool-calls' } },
      ]
      chunks.forEach((chunk, index) => send(proc, { type: 'model_chunk', id: frame.id, index, chunk }))
      send(proc, { type: 'model_end', id: frame.id, ok: true })
    }
    if (frame.type === 'tool_call') proc.stdin.end()
  })
  const [code] = await once(child, 'close')
  assert.equal(code, 1)
  assert.equal(modelCalls, 1)
  assert.equal(frames.some(frame => frame.type === 'settled'), false)
})

test('refuses invalid UTF-8 in a worker frame', async () => {
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') {
      const [prefix, suffix] = JSON.stringify({ ...start, prompt: 'utf8_marker' }).split('utf8_marker')
      proc.stdin.write(Buffer.concat([Buffer.from(prefix), Buffer.from([0xc3, 0x28]), Buffer.from(`${suffix}\n`)]))
    }
  })
  const timer = setTimeout(() => child.kill('SIGKILL'), 1500)
  const [code] = await once(child, 'close')
  clearTimeout(timer)
  assert.equal(code, 1)
  assert.equal(frames.some(frame => frame.type === 'checkpoint' || frame.type === 'model'), false)
})

async function captureSession({ interrupt = false } = {}) {
  const pages = []
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, start)
    if (frame.type === 'checkpoint') {
      pages.push({ from_seq: frame.from_seq, through_seq: frame.through_seq, payload: frame.payload, sha256: frame.sha256 })
      send(proc, { type: 'checkpoint_ack', id: frame.id, ok: true, through_seq: frame.through_seq, sha256: frame.sha256 })
    }
    if (frame.type === 'model') {
      if (interrupt) {
        proc.kill('SIGKILL')
        return
      }
      const chunks = [
        { type: 'block-start', index: 0, blockType: 'text' },
        { type: 'text-delta', index: 0, text: 'saved answer' },
        { type: 'block-end', index: 0, block: { type: 'text', text: 'saved answer' } },
        { type: 'usage', usage: { inputTokens: 2, outputTokens: 1 } },
        { type: 'finish', reason: { kind: 'stop' } },
      ]
      chunks.forEach((chunk, index) => send(proc, { type: 'model_chunk', id: frame.id, index, chunk }))
      send(proc, { type: 'model_end', id: frame.id, ok: true })
    }
  })
  const [code, signal] = await once(child, 'close')
  if (interrupt) assert.equal(signal, 'SIGKILL')
  else assert.equal(code, 0)
  assert.ok(pages.length > 0)
  assert.ok(frames.some(frame => frame.type === 'model'))
  return pages
}

function resumedStart(pages) {
  const { prompt, ...identity } = start
  assert.ok(prompt)
  const tail = pages.at(-1)
  return { ...identity, agent_id: 'agent_124', generation: 2, resume: true,
    checkpoint_through_seq: tail.through_seq, checkpoint_sha256: tail.sha256 }
}

function checkpointPage(request, page) {
  return { type: 'checkpoint_page', id: request.id, ok: true,
    task_id: request.task_id, owner_id: request.owner_id, agent_id: request.agent_id,
    generation: request.generation, authorization_version: request.authorization_version, session_id: request.session_id,
    from_seq: page.from_seq, through_seq: page.through_seq, payload: page.payload, sha256: page.sha256 }
}

async function resumeSession(pages, { alterStart = value => value, alterPage = value => value, stopRead = false, refuseCheckpoint = false } = {}) {
  const emitted = []
  const offsets = []
  const { child, frames } = launch((frame, proc) => {
    if (frame.type === 'ready') send(proc, alterStart(resumedStart(pages)))
    if (frame.type === 'checkpoint_read') {
      offsets.push(frame.from_seq)
      if (stopRead) {
        send(proc, { type: 'cancel' })
        return
      }
      const page = pages.find(item => item.from_seq === frame.from_seq)
      if (!page) {
        proc.stdin.end()
        return
      }
      send(proc, alterPage(checkpointPage(frame, page)))
    }
    if (frame.type === 'checkpoint') {
      emitted.push(frame)
      send(proc, { type: 'checkpoint_ack', id: frame.id, ok: !refuseCheckpoint, through_seq: frame.through_seq, sha256: frame.sha256 })
    }
  })
  const [code] = await once(child, 'close')
  return { code, frames, emitted, offsets }
}

test('restores a completed dsh session from verified pages without replaying the prompt', async () => {
  const pages = await captureSession()
  const result = await resumeSession(pages)
  assert.equal(result.code, 0, `frames: ${result.frames.map(frame => frame.type).join(', ')}`)
  assert.deepEqual(result.offsets, pages.map(page => page.from_seq))
  assert.equal(result.frames.find(frame => frame.type === 'settled')?.state, 'restored')
  assert.equal(result.frames.find(frame => frame.type === 'settled')?.session_id, start.session_id)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

test('persists dsh interrupted-turn closers before reporting a restored session', async () => {
  const pages = await captureSession({ interrupt: true })
  const result = await resumeSession(pages)
  assert.equal(result.code, 0, `frames: ${result.frames.map(frame => frame.type).join(', ')}`)
  assert.equal(result.frames.find(frame => frame.type === 'settled')?.state, 'restored')
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
  const events = result.emitted.flatMap(frame => JSON.parse(frame.payload).events)
  assert.ok(events.some(event => event.type === 'turn/end' && event.data.reason.kind === 'interrupted'))
  assert.equal(result.emitted[0].from_seq, pages.at(-1).through_seq + 1)
})

test('refuses recovery when interrupted-turn closers cannot be committed', async () => {
  const pages = await captureSession({ interrupt: true })
  const result = await resumeSession(pages, { refuseCheckpoint: true })
  assert.notEqual(result.code, 0)
  assert.ok(result.emitted.length > 0)
  assert.equal(result.frames.some(frame => frame.type === 'settled'), false)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

test('refuses damaged, missing, mismatched, or unauthorized checkpoint pages', async () => {
  const pages = await captureSession()
  const cases = [
    { name: 'wrong identity', alterPage: page => ({ ...page, owner_id: 'another_owner' }) },
    { name: 'wrong offset', alterPage: page => ({ ...page, from_seq: page.from_seq + 1 }) },
    { name: 'bad digest', alterPage: page => ({ ...page, sha256: '0'.repeat(64) }) },
    { name: 'bad pinned tail', alterStart: value => ({ ...value, checkpoint_sha256: '0'.repeat(64) }) },
    { name: 'oversized page', alterPage: page => ({ ...page, payload: 'x'.repeat(1024 * 1024 + 1) }) },
    { name: 'duplicate JSON key', alterPage: page => {
      const field = `"from_seq":${page.from_seq}`
      const payload = page.payload.replace(field, `${field},${field}`)
      return { ...page, payload, sha256: createHash('sha256').update(payload).digest('hex') }
    } },
    { name: 'noncontiguous events', alterPage: page => {
      const body = JSON.parse(page.payload)
      body.events[0].seq += 1
      const payload = JSON.stringify(body)
      return { ...page, payload, sha256: createHash('sha256').update(payload).digest('hex') }
    } },
    { name: 'unknown required event', alterPage: page => {
      const body = JSON.parse(page.payload)
      body.events[0].type = 'unknown/required'
      const payload = JSON.stringify(body)
      return { ...page, payload, sha256: createHash('sha256').update(payload).digest('hex') }
    } },
    { name: 'cancelled read', stopRead: true },
  ]
  for (const scenario of cases) {
    const result = await resumeSession(pages, scenario)
    assert.notEqual(result.code, 0, scenario.name)
    assert.equal(result.frames.some(frame => frame.type === 'model'), false, scenario.name)
    assert.equal(result.emitted.length, 0, scenario.name)
  }
})

test('refuses a checkpoint history with a missing final page', async () => {
  const pages = await captureSession()
  assert.ok(pages.length > 1)
  const tail = pages.at(-1)
  const result = await resumeSession(pages.slice(0, -1), { alterStart: value => ({ ...value,
    checkpoint_through_seq: tail.through_seq, checkpoint_sha256: tail.sha256 }) })
  assert.notEqual(result.code, 0)
  assert.equal(result.emitted.length, 0)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

test('refuses checkpoint headers that change between pages', async () => {
  const captured = await captureSession()
  const original = JSON.parse(captured[0].payload).header
  const pages = [original, { ...original, createdAt: original.createdAt + 1 }].map((header, seq) => {
    const payload = JSON.stringify({ header, from_seq: seq, events: [{ type: 'extension/test', seq, time: 1, data: {}, ignorable: true }] })
    return { from_seq: seq, through_seq: seq, payload, sha256: createHash('sha256').update(payload).digest('hex') }
  })
  const result = await resumeSession(pages)
  assert.notEqual(result.code, 0)
  assert.equal(result.emitted.length, 0)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

test('refuses history larger than the bounded dsh restore budget', async () => {
  const captured = await captureSession()
  const header = JSON.parse(captured[0].payload).header
  const pages = Array.from({ length: 10 }, (_, seq) => {
    const payload = JSON.stringify({ header, from_seq: seq,
      events: [{ type: 'extension/test', seq, time: 1, data: { padding: 'x'.repeat(900_000) }, ignorable: true }] })
    return { from_seq: seq, through_seq: seq, payload, sha256: createHash('sha256').update(payload).digest('hex') }
  })
  const result = await resumeSession(pages)
  assert.notEqual(result.code, 0)
  assert.equal(result.emitted.length, 0)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
  assert.ok(result.offsets.length >= 9)
})

test('refuses historical tool calls before any recovery rewrite', async () => {
  const captured = await captureSession({ interrupt: true })
  const pages = captured.map(page => ({ ...page }))
  const last = pages.at(-1)
  const body = JSON.parse(last.payload)
  const event = body.events.at(-1)
  event.type = 'tool/call'
  event.data = { turn: 1, step: 1, callId: 'call_1', name: 'shell', arguments: '{}' }
  last.payload = JSON.stringify(body)
  last.sha256 = createHash('sha256').update(last.payload).digest('hex')
  const result = await resumeSession(pages)
  assert.notEqual(result.code, 0)
  assert.equal(result.emitted.length, 0)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

test('refuses a validly hashed checkpoint for a different session', async () => {
  const captured = await captureSession()
  const pages = captured.map(page => ({ ...page }))
  const body = JSON.parse(pages[0].payload)
  body.header.id = 'other_session'
  pages[0].payload = JSON.stringify(body)
  pages[0].sha256 = createHash('sha256').update(pages[0].payload).digest('hex')
  const result = await resumeSession(pages)
  assert.notEqual(result.code, 0)
  assert.equal(result.emitted.length, 0)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

test('does not discard pending inbox input during recovery', async () => {
  const captured = await captureSession({ interrupt: true })
  const decoded = captured.flatMap(page => JSON.parse(page.payload).events)
  const pending = decoded.findIndex(event => event.type === 'agent/inbox/spliced' && event.data.inserted.length > 0)
  assert.ok(pending >= 0)
  const body = { header: JSON.parse(captured[0].payload).header, from_seq: 0, events: decoded.slice(0, pending + 1) }
  const payload = JSON.stringify(body)
  const page = { from_seq: 0, through_seq: body.events.at(-1).seq, payload, sha256: createHash('sha256').update(payload).digest('hex') }
  const result = await resumeSession([page])
  assert.notEqual(result.code, 0)
  assert.equal(result.emitted.length, 0)
  assert.equal(result.frames.some(frame => frame.type === 'model'), false)
})

