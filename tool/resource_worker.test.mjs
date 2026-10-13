import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {test} from 'node:test';
import {MessageChannel} from 'node:worker_threads';
import vm from 'node:vm';
import {once} from 'node:events';

const worker = readFileSync(new URL('../web/cc_resource_worker.js', import.meta.url), 'utf8');
const token = 'a'.repeat(64);
const socketShim = readFileSync(
  new URL('../web/cc_resource_ws_shim.js', import.meta.url), 'utf8');
const base = `https://app.example/app/_cc_resource/${token}/`;

function harness() {
  const listeners = {};
  const clients = new Map([['owner', {id: 'owner',
    url: 'https://app.example/app/', frameType: 'top-level',
    postMessage() {}}]]);
  let networkFetches = 0;
  const self = {
    registration: {scope: 'https://app.example/app/'},
    location: {origin: 'https://app.example', href:
      'https://app.example/app/cc_resource_worker.js'},
    clients: {get: id => Promise.resolve(clients.get(id)),
      matchAll: async () => Array.from(clients.values())},
    addEventListener: (name, handler) => {listeners[name] = handler;},
  };
  const sandbox = {self, URL, Request, Response, Headers, ReadableStream,
    MessageChannel, TextEncoder, TextDecoder, setTimeout, clearTimeout,
    fetch: async () => {networkFetches++; return new Response('network');}};
  vm.runInNewContext(worker, sandbox, {filename: 'cc_resource_worker.js'});
  return {listeners, clients, get networkFetches() {return networkFetches;}};
}

function bind(h, port) {
  h.listeners.message({data: {kind: 'bind', token},
    source: h.clients.get('owner'), ports: [port]});
}

function fetchRoute(h, url, clientId = 'owner', init = {}) {
  let result;
  h.listeners.fetch({request: new Request(url, init), clientId,
    respondWith: value => {result = value;}});
  return result;
}

test('unknown capabilities fail closed without a network request', async () => {
  const h = harness();
  const result = await fetchRoute(h, base + 'blob?h=hash');
  assert.equal(result.status, 410);
  assert.equal(h.networkFetches, 0);
});

test('an iframe whose tab is gone cannot fall back to same-origin network', async () => {
  const h = harness();
  bind(h, {postMessage() {}, close() {}, start() {}});
  h.clients.set('iframe', {url: base + 'proxy/vscode/session/'});
  h.clients.delete('owner');
  const result = await fetchRoute(h, 'https://app.example/static/browser.js', 'iframe');
  assert.equal(result.status, 410);
  assert.equal(h.networkFetches, 0);
});

test('terminated worker rebinds its live owner before serving a resource', async () => {
  const h = harness();
  h.clients.get('owner').postMessage = message => {
    assert.equal(message.kind, 'cc-resource-rebind');
    assert.equal(message.token, token);
    bind(h, {start() {}, close() {}, postMessage(request) {
      request.port.postMessage({kind: 'headers', status: 204, headers: {}});
    }});
  };
  const response = await fetchRoute(h, base + 'proxy/vscode/session/');
  assert.equal(response.status, 204);
  assert.equal(h.networkFetches, 0);
});

test('owner unbind releases the old worker port before rebind', async () => {
  const h = harness();
  let rebinds = 0;
  h.clients.get('owner').postMessage = message => {
    assert.equal(message.kind, 'cc-resource-rebind');
    rebinds++;
    bind(h, {start() {}, close() {}, postMessage(request) {
      request.port.postMessage({kind: 'headers', status: 204, headers: {}});
    }});
  };
  const channel = new MessageChannel();
  bind(h, channel.port1);
  // `once` listens via addEventListener, which does not ref the port. Once the
  // worker closes port1, nothing else holds the event loop open, so Node can
  // drain before port2's 'close' arrives and cancel every remaining test.
  channel.port2.ref();
  const unbound = once(channel.port2, 'close');
  channel.port2.postMessage({kind: 'unbind'});
  await unbound;
  const response = await fetchRoute(h, base + 'proxy/vscode/session/');
  assert.equal(response.status, 204);
  assert.equal(rebinds, 1);
  channel.port2.close();
});

test('external redirects cannot leave the encrypted iframe capability', async () => {
  const h = harness();
  bind(h, {start() {}, close() {}, postMessage(message) {
    assert.equal(message.meta.path, '/proxy/vscode/session/');
    message.port.postMessage({kind: 'headers', status: 302,
      headers: {location: ['https://remote.example/sensitive']}});
  }});
  const result = await fetchRoute(h, base + 'proxy/vscode/session/');
  assert.equal(result.status, 502);
  assert.equal(h.networkFetches, 0);
});

test('root-relative iframe assets stay under its code-server session', async () => {
  const h = harness();
  bind(h, {start() {}, close() {}, postMessage(message) {
    assert.equal(message.meta.path, '/proxy/vscode/session/static/app.js');
    message.port.postMessage({kind: 'headers', status: 204, headers: {}});
  }});
  h.clients.set('iframe', {url: base + 'proxy/vscode/session/'});
  const result = await fetchRoute(h, 'https://app.example/static/app.js', 'iframe');
  assert.equal(result.status, 204);
  assert.equal(h.networkFetches, 0);
});

function assertShimNonce(body, expected) {
  const scripts = [...body.matchAll(/<script\b([^>]*)>/gi)].map(match =>
    Object.fromEntries([...match[1].matchAll(/([\w-]+)="([^"]*)"/g)]
      .map(([, name, value]) => [name, value])));
  const index = scripts.findIndex(script => script.src?.endsWith('/_cc_ws_shim.js'));
  assert.notEqual(index, -1, 'the editor receives a socket shim');
  assert.equal(new URL(scripts[index].src, base).href, base + '_cc_ws_shim.js');
  assert.equal(scripts[index].nonce, expected);
  assert.ok(index < scripts.findIndex(script => script.src === '/app.js'),
    'the CSP-authorized shim runs before application scripts');
}

test('editor shim inherits a strict-dynamic CSP nonce before application scripts', async () => {
  const h = harness();
  bind(h, {start() {}, close() {}, postMessage(message) {
    message.port.postMessage({kind: 'headers', status: 200, headers: {
      'content-type': ['text/html'],
      'content-security-policy': ["script-src 'nonce-UHJveHlOb25jZQ==' 'strict-dynamic'"],
    }});
    message.port.postMessage({kind: 'data',
      bytes: new TextEncoder().encode('<html><head><script src=\"/app.js\"></script></head></html>').buffer});
    message.port.postMessage({kind: 'end'});
  }});
  const response = await fetchRoute(h, base + 'proxy/vscode/session/');
  const body = await response.text();
  assertShimNonce(body, 'UHJveHlOb25jZQ==');
  assert.equal(h.networkFetches, 0);
});

test('editor shim finds HTML script nonce across stream chunks without CSP header', async () => {
  const h = harness();
  bind(h, {start() {}, close() {}, postMessage(message) {
    message.port.postMessage({kind: 'headers', status: 200,
      headers: {'content-type': ['text/html']}});
    for (const chunk of ['<html><head><scr',
      'ipt nonce="SGVhZE5vbmNl" src="/app.js"></script></head></html>']) {
      message.port.postMessage({kind: 'data', bytes: new TextEncoder().encode(chunk).buffer});
    }
    message.port.postMessage({kind: 'end'});
  }});
  const response = await fetchRoute(h, base + 'proxy/vscode/session/');
  const body = await response.text();
  assertShimNonce(body, 'SGVhZE5vbmNl');
  assert.equal(h.networkFetches, 0);
});

test('a bodyless early response cancels the unfinished upload', {timeout: 2000}, async () => {
  const h = harness();
  let cancelUpload;
  const cancelled = new Promise(resolve => { cancelUpload = resolve; });
  const upload = new ReadableStream({cancel: () => cancelUpload()});
  bind(h, {start() {}, close() {}, postMessage(message) {
    message.port.postMessage({kind: 'headers', status: 204, headers: {}});
  }});
  const response = await fetchRoute(h, base + 'blob', 'owner', {
    method: 'POST', body: upload, duplex: 'half',
  });
  assert.equal(response.status, 204);
  assert.equal(response.body, null);
  await cancelled;
  assert.equal(h.networkFetches, 0);
});

test('socket shim activates for root and nested editor capability paths only', () => {
  for (const path of [
    `/_cc_resource/${token}/proxy/vscode/session/index.html`,
    `/app/_cc_resource/${token}/proxy/vscode/session/index.html`,
    '/proxy/vscode/session/index.html',
  ]) {
    class NativeWebSocket {}
    const window = {WebSocket: NativeWebSocket};
    vm.runInNewContext(socketShim, {
      window, location: {pathname: path}, EventTarget,
    }, {filename: 'cc_resource_ws_shim.js'});
    assert.equal(window.WebSocket.name,
      path.includes('_cc_resource/') ? 'EncryptedWebSocket' : 'NativeWebSocket');
  }
});
