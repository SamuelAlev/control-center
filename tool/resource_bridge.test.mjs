import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import {MessageChannel, MessagePort} from 'node:worker_threads';
import {webcrypto} from 'node:crypto';
import vm from 'node:vm';

const script = readFileSync(new URL('../web/cc_resource_bridge.js', import.meta.url), 'utf8');
const tokenOf = base => new URL(base).pathname.split('/').at(-2);

function harness(t, path = '/app/') {
  const scope = new URL(path, 'https://app.example');
  const listeners = new Set();
  const tokens = new Set();
  const ports = [];
  const worker = {
    scriptURL: new URL('cc_resource_worker.js', scope).href,
    postMessage(_, transferred = []) {
      for (const port of transferred) {
        ports.push(port);
        port.unref();
      }
    },
  };
  const navigator = {serviceWorker: {
    controller: worker,
    ready: Promise.resolve(),
    register: async () => ({active: worker}),
    addEventListener(type, callback) {
      if (type === 'message') listeners.add(callback);
    },
  }};
  const window = {};
  vm.runInNewContext(script, {
    window, document: {baseURI: scope.href}, location: scope,
    isSecureContext: true, navigator, URL, crypto: webcrypto,
    MessageChannel, MessagePort, setTimeout, clearTimeout,
  }, {filename: 'cc_resource_bridge.js'});
  const bridge = window.ccResourceBridge;
  t.after(() => {
    for (const token of tokens) bridge.close(token);
    for (const port of ports) port.close();
  });
  return {
    bridge,
    async open() {
      const base = await bridge.open(() => {});
      tokens.add(tokenOf(base));
      return base;
    },
    rebind(token) {
      for (const callback of listeners) {
        callback({source: worker, data: {kind: 'cc-resource-rebind', token}});
      }
    },
  };
}

test('editor preserves its capability URL at root and nested app bases', async t => {
  for (const path of ['/', '/app/']) {
    const h = harness(t, path);
    const base = await h.open();
    const iframe = {src: 'about:blank'};
    const url = `${base}proxy/vscode/session/?folder=%2Fworkspace#editor`;
    assert.equal(await h.bridge.attachEditor(iframe, url), url);
    assert.equal(iframe.src, url);
    assert.equal(new URL(iframe.src).origin, 'https://app.example');
  }
});

test('foreign, unknown and non-editor capabilities cannot attach a document', async t => {
  const h = harness(t);
  const base = await h.open();
  const token = tokenOf(base);
  const unknown = (token[0] === '0' ? '1' : '0') + token.substring(1);
  const iframe = {src: 'about:blank'};
  for (const url of [
    base.replace('https://app.example', 'https://foreign.example') + 'proxy/vscode/session/',
    base.replace(token, unknown) + 'proxy/vscode/session/',
    base + 'blob',
    `https://app.example/_cc_resource/${token}/proxy/vscode/session/`,
  ]) {
    await assert.rejects(h.bridge.attachEditor(iframe, url), /live encrypted capability/);
    assert.equal(iframe.src, 'about:blank');
  }
});

test('detach, move and close revoke only the owning session documents', async t => {
  const h = harness(t);
  const first = await h.open();
  const second = await h.open();
  const firstURL = first + 'proxy/vscode/first/';
  const secondURL = second + 'proxy/vscode/second/';
  const moving = {src: ''};
  const remaining = {src: ''};
  const other = {src: ''};
  await h.bridge.attachEditor(moving, firstURL);
  await h.bridge.attachEditor(remaining, firstURL);
  await h.bridge.attachEditor(other, secondURL);
  h.bridge.detachEditor(moving);
  assert.equal(moving.src, 'about:blank');
  assert.equal(remaining.src, firstURL);
  await h.bridge.attachEditor(moving, secondURL);
  h.bridge.close(tokenOf(first));
  assert.equal(remaining.src, 'about:blank');
  assert.equal(moving.src, secondURL);
  assert.equal(other.src, secondURL);
  await assert.rejects(h.bridge.attachEditor(remaining, firstURL), /live encrypted capability/);
  h.bridge.close(tokenOf(second));
  assert.equal(moving.src, 'about:blank');
  assert.equal(other.src, 'about:blank');
});

test('worker rebind preserves editor ownership for session teardown', async t => {
  const h = harness(t);
  const base = await h.open();
  const iframe = {src: ''};
  await h.bridge.attachEditor(iframe, base + 'proxy/vscode/session/');
  h.rebind(tokenOf(base));
  h.bridge.close(tokenOf(base));
  assert.equal(iframe.src, 'about:blank');
});
