import { createHash, randomUUID } from 'node:crypto'
import { once } from 'node:events'

const MAX_FRAME_BYTES = 4 * 1024 * 1024
const MAX_MODEL_QUEUE_BYTES = 1024 * 1024
const MAX_TOOL_OUTPUT_BYTES = 1024 * 1024
const CHECKPOINT_TIMEOUT_MS = 30_000
const TOOL_RESULT_TIMEOUT_MS = 6 * 60_000
const UTF8_DECODER = new TextDecoder('utf-8', { fatal: true, ignoreBOM: true })

function deferred() {
  let resolve, reject
  const promise = new Promise((ok, fail) => { resolve = ok; reject = fail })
  return { promise, resolve, reject }
}

function abortError() {
  return new Error('request cancelled')
}

function isObject(value) {
  return value !== null && typeof value === 'object' && !Array.isArray(value)
}

export class WorkerIPC {
  constructor(input, output) {
    this.input = input
    this.output = output
    this.start = deferred()
    this.pending = new Map()
    this.model = undefined
    this.failed = false
    this.started = false
    this.cancelled = false
    this.buffer = Buffer.alloc(0)
    this.writes = Promise.resolve()
    input.on('data', chunk => this.receive(chunk))
    input.on('end', () => this.fail('worker connection closed'))
    input.on('error', () => this.fail('worker connection failed'))
    output.on('error', () => this.fail('worker connection failed'))
  }

  async send(frame) {
    if (this.failed) throw new Error('worker connection unavailable')
    const encoded = Buffer.from(`${JSON.stringify(frame)}\n`)
    if (encoded.length > MAX_FRAME_BYTES) throw new Error('worker frame exceeds limit')
    const writing = this.writes.then(async () => {
      if (this.failed) throw new Error('worker connection unavailable')
      if (!this.output.write(encoded)) await once(this.output, 'drain')
    })
    this.writes = writing.catch(() => {})
    return writing
  }

  receive(chunk) {
    if (this.failed) return
    try {
      const incoming = Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk)
      this.buffer = Buffer.concat([this.buffer, incoming])
      for (;;) {
        const end = this.buffer.indexOf(10)
        if (end === -1) {
          if (this.buffer.length >= MAX_FRAME_BYTES) throw new Error('worker frame exceeds limit')
          break
        }
        if (end >= MAX_FRAME_BYTES) throw new Error('worker frame exceeds limit')
        const line = this.buffer.subarray(0, end)
        this.buffer = this.buffer.subarray(end + 1)
        const frame = JSON.parse(UTF8_DECODER.decode(line))
        if (!isObject(frame) || typeof frame.type !== 'string') throw new Error('invalid worker frame')
        this.dispatch(frame)
      }
    } catch {
      this.fail('invalid worker frame')
    }
  }

  dispatch(frame) {
    if (frame.type === 'start' && !this.started) {
      this.started = true
      this.start.resolve(frame)
      return
    }
    if (!this.started) throw new Error('runtime has not started')
    if (frame.type === 'cancel') {
      this.cancel()
      return
    }
    if (frame.type === 'checkpoint_ack') {
      const pending = this.pending.get(frame.id)
      if (!pending || pending.kind !== 'checkpoint_ack') throw new Error('unknown checkpoint response')
      this.pending.delete(frame.id)
      clearTimeout(pending.timer)
      if (frame.ok !== true || frame.through_seq !== pending.through || frame.sha256 !== pending.digest) {
        pending.reject(new Error('checkpoint not confirmed'))
      } else {
        pending.resolve()
      }
      return
    }
    if (frame.type === 'checkpoint_page') {
      const pending = this.pending.get(frame.id)
      if (!pending || pending.kind !== 'checkpoint_page') throw new Error('unknown checkpoint page')
      this.pending.delete(frame.id)
      clearTimeout(pending.timer)
      if (frame.ok !== true || !Object.entries(pending.identity).every(([key, value]) => frame[key] === value)) {
        pending.reject(new Error('checkpoint page not authorized'))
      } else {
        pending.resolve(frame)
      }
      return
    }
    if (frame.type === 'tool_result') {
      const pending = this.pending.get(frame.id)
      if (!pending || pending.kind !== 'tool_result') throw new Error('unknown tool response')
      this.pending.delete(frame.id)
      clearTimeout(pending.timer)
      const expectedKeys = ['agent_id', 'authorization_version', 'call_id', 'generation', 'id', 'output', 'owner_id', 'session_id', 'status', 'task_id', 'type']
      const actualKeys = Object.keys(frame).sort()
      const valid = actualKeys.length === expectedKeys.length && actualKeys.every((key, index) => key === expectedKeys[index]) &&
        Object.entries(pending.identity).every(([key, value]) => frame[key] === value) &&
        frame.call_id === pending.callID && ['succeeded', 'failed'].includes(frame.status) &&
        typeof frame.output === 'string' && Buffer.byteLength(frame.output) <= MAX_TOOL_OUTPUT_BYTES
      if (!valid) {
        pending.reject(new Error('tool result not authorized'))
        throw new Error('invalid tool response')
      }
      pending.resolve({ status: frame.status, output: frame.output })
      return
    }
    if (frame.type === 'model_chunk' || frame.type === 'model_end') {
      if (!this.model || frame.id !== this.model.id) throw new Error('unknown model response')
      this.model.receive(frame)
      return
    }
    throw new Error('unknown worker message')
  }

  cancel() {
    this.cancelled = true
    for (const [id, pending] of this.pending) {
      if (pending.kind !== 'checkpoint_page' && pending.kind !== 'tool_result') continue
      this.pending.delete(id)
      clearTimeout(pending.timer)
      pending.reject(abortError())
    }
    this.onCancel?.()
  }

  async checkpoint(identity, from, through, payload, digest) {
    const id = randomUUID()
    const result = deferred()
    const timer = setTimeout(() => {
      this.pending.delete(id)
      result.reject(new Error('checkpoint confirmation timed out'))
    }, CHECKPOINT_TIMEOUT_MS)
    this.pending.set(id, { ...result, timer, kind: 'checkpoint_ack', through, digest })
    try {
      await this.send({ type: 'checkpoint', id, ...identity, from_seq: from, through_seq: through, payload, sha256: digest })
      await result.promise
    } finally {
      clearTimeout(timer)
      this.pending.delete(id)
    }
  }

  async readCheckpoint(identity, from) {
    if (this.cancelled) throw abortError()
    if (!Number.isSafeInteger(from) || from < 0) throw new Error('invalid checkpoint offset')
    const id = randomUUID()
    const result = deferred()
    void result.promise.catch(() => {})
    const timer = setTimeout(() => {
      this.pending.delete(id)
      result.reject(new Error('checkpoint read timed out'))
    }, CHECKPOINT_TIMEOUT_MS)
    this.pending.set(id, { ...result, timer, kind: 'checkpoint_page', identity })
    try {
      await this.send({ type: 'checkpoint_read', id, ...identity, from_seq: from })
      return await result.promise
    } finally {
      clearTimeout(timer)
      this.pending.delete(id)
    }
  }

  async toolCall(identity, through, callID, name, args, signal) {
    if (this.cancelled) throw abortError()
    if (!Number.isSafeInteger(through) || through < 0 || typeof callID !== 'string' || !callID ||
        Buffer.byteLength(callID) > 256 || typeof name !== 'string' || !name || !isObject(args)) {
      throw new Error('invalid tool call')
    }
    signal?.throwIfAborted()
    const id = randomUUID()
    const result = deferred()
    void result.promise.catch(() => {})
    const timer = setTimeout(() => {
      this.pending.delete(id)
      result.reject(new Error('tool result timed out'))
    }, TOOL_RESULT_TIMEOUT_MS)
    const abort = () => {
      this.pending.delete(id)
      clearTimeout(timer)
      result.reject(abortError())
    }
    this.pending.set(id, { ...result, timer, kind: 'tool_result', identity, callID })
    signal?.addEventListener('abort', abort, { once: true })
    try {
      await this.send({ type: 'tool_call', id, ...identity, through_seq: through, call_id: callID, name, arguments: args })
      return await result.promise
    } catch (error) {
      if (this.pending.delete(id)) clearTimeout(timer)
      throw error
    } finally {
      signal?.removeEventListener('abort', abort)
      if (this.pending.delete(id)) clearTimeout(timer)
    }
  }

  async *streamModel(identity, id, through, request, signal) {
    if (this.model) throw new Error('model request already active')
    signal?.throwIfAborted()
    const queue = []
    let queuedBytes = 0
    let nextIndex = 0
    let finished = false
    let ended = false
    let cancelSent = false
    let failure
    let wake = deferred()
    const notify = () => { wake.resolve(); wake = deferred() }
    const notifyCancel = () => {
      if (cancelSent) return
      cancelSent = true
      void this.send({ type: 'model_cancel', id, ...identity }).catch(() => {})
    }
    const receive = frame => {
      if (ended) throw new Error('model response already ended')
      if (frame.type === 'model_end') {
        ended = true
        if (frame.ok !== true || !finished) failure = new Error('model request failed')
        notify()
        return
      }
      if (frame.index !== nextIndex++ || !isObject(frame.chunk) || typeof frame.chunk.type !== 'string' || finished) {
        throw new Error('invalid model response')
      }
      const chunk = frame.chunk
      const allowed = ['block-start', 'text-delta', 'reasoning-delta', 'tool-call-delta', 'block-end', 'usage', 'finish']
      if (!allowed.includes(chunk.type) || chunk.blockType === 'tool-call' || chunk.block?.type === 'tool-call') {
        failure = new Error('model returned an unavailable tool')
        ended = true
        notifyCancel()
        notify()
        return
      }
      if (chunk.type === 'tool-call-delta' && !request.tools.length) {
        failure = new Error('model returned an unavailable tool')
        ended = true
        notifyCancel()
        notify()
        return
      }
      if (chunk.type === 'finish') finished = true
      const size = Buffer.byteLength(JSON.stringify(chunk))
      if (queuedBytes + size > MAX_MODEL_QUEUE_BYTES) throw new Error('model response exceeds queue limit')
      queuedBytes += size
      queue.push({ chunk, size })
      notify()
    }
    const cancel = () => {
      if (!ended) {
        ended = true
        failure = abortError()
        notifyCancel()
        notify()
      }
    }
    this.model = { id, receive, cancel }
    signal?.addEventListener('abort', cancel, { once: true })
    try {
      const digest = createHash('sha256').update(JSON.stringify(request), 'utf8').digest('hex')
      await this.send({ type: 'model', id, ...identity, through_seq: through, request, sha256: digest })
      for (;;) {
        signal?.throwIfAborted()
        if (queue.length) {
          const item = queue.shift()
          queuedBytes -= item.size
          yield item.chunk
          continue
        }
        if (failure) throw failure
        if (ended) return
        await wake.promise
      }
    } finally {
      signal?.removeEventListener('abort', cancel)
      if (!ended) cancel()
      this.model = undefined
    }
  }

  fail(reason) {
    if (this.failed) return
    this.failed = true
    this.start.reject(new Error(reason))
    for (const pending of this.pending.values()) {
      clearTimeout(pending.timer)
      pending.reject(new Error(reason))
    }
    this.pending.clear()
    this.model?.cancel()
    this.onFailure?.()
  }
}
