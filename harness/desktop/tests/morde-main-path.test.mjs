import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createRequire } from 'node:module';

test('system directory protection handles Windows paths and filesystem roots', async () => {
  const root = mkdtempSync(join(tmpdir(), 'morde-system-path-'));
  const require = createRequire(import.meta.url);
  const Module = require('node:module');
  const originalLoad = Module._load;
  Module._load = function (request, parent, isMain) {
    if (request === 'electron') return {
      app: {
        setName() {},
        getPath: () => root,
        setPath() {},
        getLocale: () => 'en',
        requestSingleInstanceLock: () => false,
        quit() {},
      },
    };
    return originalLoad.call(this, request, parent, isMain);
  };

  try {
    const { isSystemDirectory } = await import('../out/morde-main.js');
    assert.equal(isSystemDirectory(String.raw`C:\Windows`, String.raw`C:\Windows`), true);
    assert.equal(isSystemDirectory(String.raw`c:\windows\Temp`, String.raw`C:\Windows`), true);
    assert.equal(isSystemDirectory(String.raw`C:\WindowsApps`, String.raw`C:\Windows`), false);
    assert.equal(isSystemDirectory(String.raw`D:\Temp`, String.raw`C:\Windows`), false);
    assert.equal(isSystemDirectory('/tmp', '/'), false);
  } finally {
    Module._load = originalLoad;
    rmSync(root, { recursive: true, force: true });
  }
});
