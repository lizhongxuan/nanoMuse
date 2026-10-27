import { createHash } from 'node:crypto'
import { Context } from '@deepseek-ai/cordis'
import AgentRegistry from '@deepseek-ai/dsh-agent'
import AgentLoop from '@deepseek-ai/dsh-agent-loop'
import LlmRuntime, { LlmAdapter, createUserMessage } from '@deepseek-ai/dsh-llm'
import SessionStore, { SessionId, SessionLogOffset } from '@deepseek-ai/dsh-session'
import * as checkpointPolicy from '@deepseek-ai/dsh-session-checkpoint-policy'
import SessionPersistence, { assertContiguous, assertStoredId, assertVersion, materializeAppendBatch, materializeCreateHeader, validateStoredEvents } from '@deepseek-ai/dsh-session-persistence'
import SessionProjectionRegistry from '@deepseek-ai/dsh-session-projection'
import SystemPrompt from '@deepseek-ai/dsh-system-prompt'
import ToolRuntime from '@deepseek-ai/dsh-tools'

const MAX_CHECKPOINT_PAYLOAD_BYTES = 1024 * 1024
const MAX_RESTORE_BYTES = 8 * 1024 * 1024
const MAX_RESTORE_EVENTS = 100_000
const ID = /^[A-Za-z0-9_-]{1,128}$/
const TOOL_NAME = /^[A-Za-z][A-Za-z0-9_.-]{0,127}$/
const DIGEST = /^[a-f0-9]{64}$/
const SCHEMA_TYPES = new Set(['object', 'array', 'string', 'number', 'integer', 'boolean', 'null'])
const SCHEMA_ANNOTATIONS = new Set(['description', 'title', 'default', 'examples'])
const TOOL_OUTPUT_SCHEMA = {
  type: 'object',
  properties: {
    status: { type: 'string', enum: ['succeeded', 'failed'] },
    output: { type: 'string' },
  },
  required: ['status', 'output'],
  additionalProperties: false,
}

function freezeJSON(value) {
  const pending = [value]
  while (pending.length) {
    const item = pending.pop()
    if (item === null || typeof item !== 'object') continue
    for (const child of Object.values(item)) pending.push(child)
    Object.freeze(item)
  }
  return value
}

function validParameterSchema(root) {
  if (!root || typeof root !== 'object' || Array.isArray(root) || root.type !== 'object' || root.additionalProperties !== false ||
      !root.properties || typeof root.properties !== 'object' || Array.isArray(root.properties)) return false
  const pending = [{ schema: root, depth: 0 }]
  let visited = 0
  while (pending.length) {
    const { schema, depth } = pending.pop()
    if (!schema || typeof schema !== 'object' || Array.isArray(schema) || ++visited > 2048 || depth > 32 ||
        typeof schema.type !== 'string' || !SCHEMA_TYPES.has(schema.type)) return false
    const type = schema.type
    const allowed = new Set([...SCHEMA_ANNOTATIONS, 'type'])
    if (type === 'object') for (const key of ['properties', 'required', 'additionalProperties', 'minProperties', 'maxProperties']) allowed.add(key)
    if (type === 'array') for (const key of ['items', 'minItems', 'maxItems', 'uniqueItems']) allowed.add(key)
    if (type === 'string') for (const key of ['enum', 'const', 'pattern', 'format', 'minLength', 'maxLength']) allowed.add(key)
    if (type === 'number' || type === 'integer') for (const key of ['enum', 'const', 'minimum', 'maximum', 'exclusiveMinimum', 'exclusiveMaximum', 'multipleOf']) allowed.add(key)
    if (type === 'boolean' || type === 'null') for (const key of ['enum', 'const']) allowed.add(key)
    if (Object.keys(schema).some(key => !allowed.has(key))) return false
    if (Object.hasOwn(schema, 'description') && typeof schema.description !== 'string') return false
    if (Object.hasOwn(schema, 'title') && typeof schema.title !== 'string') return false
    if (type === 'object') {
      if (schema.additionalProperties !== false || (schema.properties !== undefined &&
          (!schema.properties || typeof schema.properties !== 'object' || Array.isArray(schema.properties)))) return false
      const properties = schema.properties ?? {}
      const required = schema.required ?? []
      if (!Array.isArray(required) || required.some((name, index) => typeof name !== 'string' || !Object.hasOwn(properties, name) || required.indexOf(name) !== index)) return false
      for (const child of Object.values(properties)) pending.push({ schema: child, depth: depth + 1 })
    }
    if (type === 'array') {
      if (!schema.items) return false
      pending.push({ schema: schema.items, depth: depth + 1 })
    }
    for (const key of ['minLength', 'maxLength', 'minItems', 'maxItems', 'minProperties', 'maxProperties']) {
      if (Object.hasOwn(schema, key) && (!Number.isSafeInteger(schema[key]) || schema[key] < 0)) return false
    }
    for (const key of ['minimum', 'maximum', 'exclusiveMinimum', 'exclusiveMaximum', 'multipleOf']) {
      if (Object.hasOwn(schema, key) && (typeof schema[key] !== 'number' || !Number.isFinite(schema[key]) || (key === 'multipleOf' && schema[key] <= 0))) return false
    }
    if (Object.hasOwn(schema, 'uniqueItems') && typeof schema.uniqueItems !== 'boolean') return false
    if (Object.hasOwn(schema, 'pattern')) {
      if (typeof schema.pattern !== 'string') return false
      try { new RegExp(schema.pattern) } catch { return false }
    }
    if (Object.hasOwn(schema, 'format') && typeof schema.format !== 'string') return false
    if (Object.hasOwn(schema, 'enum') && (!Array.isArray(schema.enum) || !schema.enum.length)) return false
    if (Object.hasOwn(schema, 'const') && schema.const === undefined) return false
    const matchesType = value => type === 'object' ? value !== null && typeof value === 'object' && !Array.isArray(value)
      : type === 'array' ? Array.isArray(value)
        : type === 'integer' ? Number.isSafeInteger(value)
          : type === 'number' ? typeof value === 'number' && Number.isFinite(value)
            : type === 'null' ? value === null : typeof value === type
    if (Object.hasOwn(schema, 'enum') && schema.enum.some(value => !matchesType(value))) return false
    if (Object.hasOwn(schema, 'const') && !matchesType(schema.const)) return false
    if (Object.hasOwn(schema, 'minLength') && Object.hasOwn(schema, 'maxLength') && schema.minLength > schema.maxLength) return false
    if (Object.hasOwn(schema, 'minItems') && Object.hasOwn(schema, 'maxItems') && schema.minItems > schema.maxItems) return false
    if (Object.hasOwn(schema, 'minProperties') && Object.hasOwn(schema, 'maxProperties') && schema.minProperties > schema.maxProperties) return false
  }
  return true
}

function validToolDefinition(tool) {
  if (!tool || typeof tool !== 'object' || Array.isArray(tool) ||
      Object.keys(tool).sort().join(',') !== 'description,name,parameters' ||
      typeof tool.name !== 'string' || !TOOL_NAME.test(tool.name) ||
      typeof tool.description !== 'string' || !tool.description.trim() || Buffer.byteLength(tool.description) > 2048) return false
  return validParameterSchema(tool.parameters) && Buffer.byteLength(JSON.stringify(tool.parameters)) <= 64 * 1024
}

function validTools(tools) {
  if (tools === undefined) return true
  if (!Array.isArray(tools) || tools.length > 64) return false
  const names = new Set()
  for (const tool of tools) {
    if (!validToolDefinition(tool) || names.has(tool.name)) return false
    names.add(tool.name)
  }
  return true
}

export function modelCallID(taskID, sessionID, throughSeq) {
  if (!ID.test(taskID) || !ID.test(sessionID) || !Number.isSafeInteger(throughSeq) || throughSeq < 0) {
    throw new Error('invalid model call identity')
  }
  const input = `morde-dsh-model-v1\n${taskID}\n${sessionID}\n${throughSeq}`
  return `mdl_${createHash('sha256').update(input, 'utf8').digest('hex')}`
}

function validStart(frame) {
  if (frame.version !== 1 || frame.type !== 'start') return false
  if (!['task_id', 'owner_id', 'agent_id', 'session_id'].every(key => typeof frame[key] === 'string' && ID.test(frame[key]))) return false
  if (!['generation', 'authorization_version'].every(key => Number.isSafeInteger(frame[key]) && frame[key] > 0)) return false
  if (typeof frame.model !== 'string' || !frame.model.trim() || Buffer.byteLength(frame.model) > 256) return false
  if (!validTools(frame.tools)) return false
  if (frame.checkpoint !== undefined || (frame.resume !== undefined && typeof frame.resume !== 'boolean')) return false
  if (frame.resume === true) {
    if (frame.prompt !== undefined || !Number.isSafeInteger(frame.checkpoint_through_seq) || frame.checkpoint_through_seq < 0 || !DIGEST.test(frame.checkpoint_sha256)) return false
  } else {
    if (frame.checkpoint_through_seq !== undefined || frame.checkpoint_sha256 !== undefined) return false
    if (typeof frame.prompt !== 'string' || !frame.prompt.trim() || Buffer.byteLength(frame.prompt) > MAX_CHECKPOINT_PAYLOAD_BYTES / 2) return false
  }
  return frame.max_tokens === undefined || (Number.isSafeInteger(frame.max_tokens) && frame.max_tokens > 0 && frame.max_tokens <= 1_000_000)
}

class DurableSession {
  constructor(ipc, identity) {
    this.ipc = ipc
    this.identity = identity
    this.through = -1
    this.failure = undefined
    this.serial = Promise.resolve()
    this.restored = undefined
  }

  enqueue(action) {
    const result = this.serial.then(async () => {
      if (this.failure) throw this.failure
      await action()
    })
    this.serial = result.catch(error => { this.failure = error })
    return result
  }

  async write(header, events) {
    if (header.id !== this.identity.session_id) throw new Error('session identity mismatch')
    let cursor = 0
    while (cursor < events.length) {
      const from = this.through + 1
      const batch = []
      let payload
      while (cursor < events.length) {
        const event = events[cursor]
        if (event.seq !== from + batch.length) throw new Error('non-contiguous session events')
        const candidate = JSON.stringify({ header, from_seq: from, events: [...batch, event] })
        if (Buffer.byteLength(candidate) > MAX_CHECKPOINT_PAYLOAD_BYTES) {
          if (!batch.length) throw new Error('session event exceeds checkpoint limit')
          break
        }
        payload = candidate
        batch.push(event)
        cursor += 1
      }
      const through = from + batch.length - 1
      const digest = createHash('sha256').update(payload, 'utf8').digest('hex')
      await this.ipc.checkpoint(this.identity, from, through, payload, digest)
      this.through = through
      if (this.restored !== undefined) for (const event of batch) this.restored.events.push(event)
    }
  }

  append(header, events) {
    return this.enqueue(() => this.write(header, events))
  }

  flush(session) {
    if (session.id !== this.identity.session_id) return Promise.reject(new Error('session identity mismatch'))
    return this.enqueue(() => this.write(session.header, session.snapshotEvents(SessionLogOffset(this.through + 1))))
  }

  async restore(frame) {
    if (this.restored !== undefined || this.through !== -1) throw new Error('session recovery already started')
    let from = 0
    let header
    let serializedHeader
    let totalBytes = 0
    const events = []
    while (from <= frame.checkpoint_through_seq) {
      const page = await this.ipc.readCheckpoint(this.identity, from)
      if (this.ipc.cancelled || page.from_seq !== from || !Number.isSafeInteger(page.through_seq) ||
          page.through_seq < from || page.through_seq > frame.checkpoint_through_seq ||
          typeof page.payload !== 'string' || Buffer.byteLength(page.payload) > MAX_CHECKPOINT_PAYLOAD_BYTES ||
          typeof page.sha256 !== 'string' || !DIGEST.test(page.sha256) ||
          createHash('sha256').update(page.payload, 'utf8').digest('hex') !== page.sha256) throw new Error('invalid checkpoint page')
      totalBytes += Buffer.byteLength(page.payload)
      if (totalBytes > MAX_RESTORE_BYTES) throw new Error('checkpoint history exceeds restore limit')
      const body = JSON.parse(page.payload)
      if (JSON.stringify(body) !== page.payload || !body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).sort().join(',') !== 'events,from_seq,header' ||
          body.from_seq !== from || !Array.isArray(body.events) || body.events.length === 0 ||
          body.events.length !== page.through_seq - from + 1 || events.length + body.events.length > MAX_RESTORE_EVENTS) throw new Error('invalid checkpoint event range')
      const pageHeader = materializeCreateHeader(body.header)
      assertStoredId(this.identity.session_id, pageHeader)
      assertVersion(pageHeader)
      if (pageHeader.isSeeded !== false) throw new Error('seeded checkpoint recovery is unavailable')
      const encodedHeader = JSON.stringify(pageHeader)
      if (header !== undefined && encodedHeader !== serializedHeader) throw new Error('checkpoint header changed')
      header ??= freezeJSON(pageHeader)
      serializedHeader ??= encodedHeader
      assertContiguous(this.identity.session_id, body.events, from)
      for (const event of validateStoredEvents(header, body.events)) {
        if (event.type.startsWith('tool/') ||
            (event.type === 'request/header' && event.data.header?.tools?.length) ||
            (event.type === 'assistant/message' && event.data.message?.content?.some(block => block.type === 'tool-call'))) {
          throw new Error('tool history requires operation reconciliation')
        }
        events.push(freezeJSON(event))
      }
      if (page.through_seq === frame.checkpoint_through_seq && page.sha256 !== frame.checkpoint_sha256) throw new Error('checkpoint tail does not match pinned digest')
      from = page.through_seq + 1
    }
    this.through = frame.checkpoint_through_seq
    this.restored = { header, events }
    return this.restored
  }
}

function persistencePlugin(durable, start) {
  return class WorkerSessionPersistence extends SessionPersistence {
    static inject = ['sessions', 'sessionProjections']

    constructor(ctx) {
      super(ctx)
      this.context = ctx
      ctx.on('session/flush', session => durable.flush(session))
    }

    async create(header) {
      if (header.id !== durable.identity.session_id) throw new Error('session identity mismatch')
      const context = this.context
      let closed = false
      return {
        id: header.id,
        header,
        inheritedEventCount: 0,
        access: 'write',
        async append(events) {
          if (closed || events.length) throw new Error('session seed not supported')
        },
        async flush() {
          if (closed) throw new Error('session handle closed')
          const session = context.sessions.get(header.id)
          if (session) await durable.flush(session)
        },
        async close() {
          if (closed) return
          const session = context.sessions.get(header.id)
          if (session) await durable.flush(session)
          closed = true
        },
      }
    }

    async open(id, access, options = {}) {
      if (start.resume !== true || id !== durable.identity.session_id || access !== 'write') throw new Error('session recovery is unavailable')
      options.signal?.throwIfAborted()
      const restored = await durable.restore(start)
      options.signal?.throwIfAborted()
      const context = this.context
      const preview = context.sessions.prepare(SessionId(id), {
        seed: [...restored.events], meta: structuredClone(restored.header), inheritedEventCount: 0, eventState: 'shared-frozen',
      })
      const inbox = context.sessionProjections.stateOf(preview, 'inbox')
      if (!inbox || !Array.isArray(inbox['next-turn']) || !Array.isArray(inbox['next-step']) ||
          inbox['next-turn'].length !== 0 || inbox['next-step'].length !== 0) throw new Error('pending session inputs require reconciliation')
      let closed = false
      return {
        id, header: restored.header, inheritedEventCount: 0, access: 'write',
        async read(offset = 0, length, readOptions = {}) {
          readOptions.signal?.throwIfAborted()
          if (closed || !Number.isSafeInteger(offset) || offset < 0 ||
              (length !== undefined && (!Number.isSafeInteger(length) || length < 0))) throw new Error('invalid session read')
          return { eventState: 'shared-frozen', events: restored.events.slice(offset, length === undefined ? undefined : offset + length) }
        },
        async append(events, appendOptions = {}) {
          appendOptions.signal?.throwIfAborted()
          if (closed) throw new Error('session handle closed')
          const batch = validateStoredEvents(restored.header, materializeAppendBatch(events)).map(freezeJSON)
          assertContiguous(id, batch, durable.through + 1)
          await durable.append(restored.header, batch)
        },
        async flush(flushOptions = {}) {
          flushOptions.signal?.throwIfAborted()
          if (closed) throw new Error('session handle closed')
          const session = context.sessions.get(id)
          if (session) await durable.flush(session)
          else await durable.serial
          if (durable.failure) throw durable.failure
        },
        async close() {
          if (closed) return
          const session = context.sessions.get(id)
          if (session) await durable.flush(session)
          else await durable.serial
          if (durable.failure) throw durable.failure
          closed = true
        },
      }
    }
    async flush() {
      const session = this.context.sessions.get(durable.identity.session_id)
      if (session) await durable.flush(session)
    }
    async stat() { throw new Error('session inspection is unavailable') }
    async list() { throw new Error('session listing is unavailable') }
  }
}

export async function runAgent(ipc, frame) {
  if (!validStart(frame)) throw new Error('invalid start request')
  const identity = Object.fromEntries(['task_id', 'owner_id', 'agent_id', 'generation', 'authorization_version', 'session_id'].map(key => [key, frame[key]]))
  const durable = new DurableSession(ipc, identity)
  const ctx = new Context()
  const plugins = [SessionStore, SessionProjectionRegistry, AgentRegistry, SystemPrompt, ToolRuntime, LlmRuntime, persistencePlugin(durable, frame), AgentLoop, checkpointPolicy]
  for (const plugin of plugins) await ctx.plugin(plugin)

  let previousModelSeq = -1
  let activeAgent
  let toolFailure = false
  class WorkerModel extends LlmAdapter {
    async *stream(options) {
      if (frame.resume === true) throw new Error('model execution requires recovery reconciliation')
      if (options.provider !== 'morde' || options.model !== frame.model || options.sessionId !== identity.session_id) {
        throw new Error('model route is not authorized')
      }
      if (toolFailure) throw new Error('tool result is unavailable')
      if (durable.through <= previousModelSeq) throw new Error('model request has no new durable prefix')
      previousModelSeq = durable.through
      const request = {
        provider: options.provider,
        model: options.model,
        messages: options.messages,
        tools: options.tools ?? [],
        ...(options.maxTokens === undefined ? {} : { max_tokens: options.maxTokens }),
      }
      const id = modelCallID(identity.task_id, identity.session_id, durable.through)
      yield* ipc.streamModel(identity, id, durable.through, request, options.signal)
    }
  }
  ctx.llm.registerAdapter(['morde'], new WorkerModel())
  const tools = frame.tools ?? []
  const toolNames = new Set(tools.map(tool => tool.name))
  for (const tool of tools) {
    ctx.tools.register({
      name: tool.name,
      description: tool.description,
      parameters: tool.parameters,
      output: {
        schema: TOOL_OUTPUT_SCHEMA,
        render: (_args, value) => [{ type: 'text', text: value.status === 'failed' ? `Tool failed: ${value.output}` : value.output }],
      },
      async execute(args, exec) {
        if (!args || typeof args !== 'object' || Array.isArray(args)) throw new Error('tool arguments must be an object')
        try {
          return await ipc.toolCall(identity, durable.through, exec.callId, tool.name, args, exec.signal)
        } catch (error) {
          if (!ipc.cancelled) {
            toolFailure = true
            activeAgent?.cancel({ kind: 'hook', reason: 'tool result unavailable' })
          }
          throw error
        }
      },
    })
  }

  let failed = false
  ctx.on('agent/error', () => { failed = true })
  ctx.on('tools/pre-execute', async exec => {
    if (toolNames.has(exec.name)) return { kind: 'allow' }
    toolFailure = true
    activeAgent?.cancel({ kind: 'hook', reason: 'tool authorization is unavailable' })
    return { kind: 'deny', reason: 'tool authorization is unavailable' }
  })
  const agentOptions = { provider: 'morde', model: frame.model, ...(frame.max_tokens === undefined ? {} : { maxTokens: frame.max_tokens }) }
  const handle = frame.resume === true
    ? await ctx.agents.resume({ resumeSessionId: SessionId(identity.session_id), agentOptions })
    : await ctx.agents.create({ sessionId: SessionId(identity.session_id), agentOptions })
  const agent = handle.agent
  activeAgent = agent
  let cancelled = false
  ipc.onCancel = () => { cancelled = true; agent.cancel({ kind: 'user' }) }
  ipc.onFailure = () => agent.cancel({ kind: 'hook', reason: 'worker connection unavailable' })
  try {
    if (ipc.cancelled) {
      await handle.dispose()
      return { type: 'settled', ...identity, state: 'cancelled', through_seq: durable.through }
    }
    if (frame.resume === true) {
      await agent.whenIdle()
      if (!await ctx.sessions.flush(agent.session)) throw new Error('checkpoint listener unavailable')
      await handle.dispose()
      if (failed || ipc.cancelled) throw new Error('session recovery did not remain idle')
      return { type: 'settled', ...identity, state: 'restored', through_seq: durable.through }
    }
    agent.followup(createUserMessage({ content: [{ type: 'text', text: frame.prompt }], source: { kind: 'user' } }))
    await agent.whenIdle()
    if (!await ctx.sessions.flush(agent.session)) throw new Error('checkpoint listener unavailable')
    const end = agent.session.snapshotEvents().findLast(event => event.type === 'turn/end')
    const reason = end?.data?.reason?.kind
    const state = toolFailure || failed ? 'failed' : cancelled || reason === 'aborted' ? 'cancelled' : reason === 'completed' ? 'completed_candidate' : 'failed'
    await handle.dispose()
    return { type: 'settled', ...identity, state, through_seq: durable.through }
  } finally {
    ipc.onCancel = undefined
    ipc.onFailure = undefined
    await handle.dispose().catch(() => {})
  }
}
