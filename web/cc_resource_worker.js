/* Only capability paths owned by a live, controlled tab reach the encrypted
 * MessageChannel. No CacheStorage, IndexedDB, remote fetch, or plaintext disk. */
const owners = new Map();
const reconnects = new Map();
const scopePath = new URL(self.registration.scope).pathname;
const prefix = `${scopePath}_cc_resource/`;
const encoder = new TextEncoder();

self.addEventListener('install', event => event.waitUntil(self.skipWaiting()));
self.addEventListener('activate', event => event.waitUntil(self.clients.claim()));
self.addEventListener('message', event => {
  const data = event.data;
  if (data?.kind === 'bind' && /^[0-9a-f]{64}$/.test(data.token) &&
      event.source?.id && event.ports.length === 1 &&
      new URL(event.source.url).pathname.startsWith(scopePath) &&
      !capability(new URL(event.source.url).pathname) &&
      event.source.frameType === 'top-level') {
    const old = owners.get(data.token);
    old?.port.close();
    const port = event.ports[0];
    owners.set(data.token, {clientId: event.source.id, port});
    port.onmessage = message => {
      if (message.data?.kind === 'unbind' &&
          owners.get(data.token)?.port === port) {
        owners.delete(data.token);
        port.close();
      }
    };
    port.onmessageerror = () => {
      if (owners.get(data.token)?.port === port) owners.delete(data.token);
      port.close();
    };
    port.start();
    reconnects.get(data.token)?.resolve(owners.get(data.token));
  } else if (data?.kind === 'unbind' && owners.get(data.token)?.clientId === event.source?.id) {
    owners.get(data.token).port.close();
    owners.delete(data.token);
  } else if (data?.kind === 'socket' && event.ports.length === 1) {
    event.waitUntil(openSocket(event));
  }
});

function capability(path) {
  if (!path.startsWith(prefix)) return null;
  const tail = path.substring(prefix.length);
  const cut = tail.indexOf('/');
  if (cut < 0) return null;
  return {token: tail.substring(0, cut), route: tail.substring(cut + 1)};
}

function codeServerRoot(path) {
  const match = path.match(/^(.*\/proxy\/vscode\/[^/]+\/)/);
  return match?.[1] || null;
}

function inCodeServer(path, root) {
  if (path.startsWith(prefix)) return path;
  if (path.startsWith('/proxy/vscode/')) {
    const capBase = root.substring(0, root.indexOf('/proxy/vscode/') + 1);
    return capBase + path.substring(1);
  }
  return root + path.replace(/^\//, '');
}

async function ownerFor(token) {
  let owner = owners.get(token);
  if (owner) {
    const client = await self.clients.get(owner.clientId);
    if (client) return owner;
    owner.port.close();
    owners.delete(token);
  }
  if (reconnects.has(token)) return reconnects.get(token).promise;
  const candidates = await self.clients.matchAll({type: 'window'});
  const eligible = candidates.filter(client => {
    const path = new URL(client.url).pathname;
    return path.startsWith(scopePath) && !capability(path) &&
      client.frameType === 'top-level';
  });
  if (!eligible.length) return null;
  const pending = {};
  pending.promise = new Promise(resolve => {
    const timeout = setTimeout(() => resolve(null), 10000);
    pending.resolve = value => {clearTimeout(timeout); resolve(value);};
  }).finally(() => reconnects.delete(token));
  reconnects.set(token, pending);
  for (const client of eligible) {
    client.postMessage({kind: 'cc-resource-rebind', token});
  }
  return pending.promise;
}

async function openSocket(event) {
  const source = event.source;
  const port = event.ports[0];
  const page = source?.url && new URL(source.url);
  const bound = page && capability(page.pathname);
  const input = event.data;
  const target = input?.url && new URL(input.url, page);
  if (!bound || !target || !page || page.origin !== target.origin ||
      !codeServerRoot(page.pathname) || !Array.isArray(input.protocols) ||
      input.protocols.some(p => typeof p !== 'string' || p.length > 128)) {
    port.postMessage({kind: 'closed', code: 1008, reason: 'Invalid socket capability'});
    port.close();
    return;
  }
  const owner = await ownerFor(bound.token);
  if (!owner) {
    port.postMessage({kind: 'closed', code: 1008, reason: 'Resource session closed'});
    port.close();
    return;
  }
  const root = codeServerRoot(page.pathname);
  const route = inCodeServer(target.pathname, root);
  if (!route.startsWith(root) || capability(route)?.token !== bound.token) {
    port.postMessage({kind: 'closed', code: 1008, reason: 'Invalid socket route'});
    port.close();
    return;
  }
  owner.port.postMessage({kind: 'request', meta: {
    kind: 'socket', path: '/' + route.substring(prefix.length + bound.token.length + 1) + target.search,
    protocols: input.protocols
  }, port}, [port]);
}

function nonceFromPolicy(policy) {
  if (!policy) return null;
  const directives = policy.split(/[;,]/).map(directive => directive.trim());
  const source = directives.find(directive => directive.startsWith('script-src-elem ')) ||
    directives.find(directive => directive.startsWith('script-src '));
  return source?.match(/'nonce-([A-Za-z0-9+/_=-]+)'/)?.[1] || null;
}

function nonceFromScript(scriptTag) {
  const value = scriptTag?.match(/(?:^|\s)nonce\s*=\s*(?:"([A-Za-z0-9+/_=-]+)"|'([A-Za-z0-9+/_=-]+)'|([A-Za-z0-9+/_=-]+))/i);
  return value?.[1] || value?.[2] || value?.[3] || null;
}

self.addEventListener('fetch', event => {
  const url = new URL(event.request.url);
  if (url.origin !== self.location.origin) return;
  if (url.pathname.startsWith(prefix)) {
    event.respondWith(routeFetch(event, url));
    return;
  }
  // Root-relative code-server assets and redirect targets inherit the owning
  // iframe's capability, never the Flutter top-level tab's URL.
  event.respondWith((async () => {
    const client = event.clientId && await self.clients.get(event.clientId);
    const page = client?.url && new URL(client.url);
    const bound = page && capability(page.pathname);
    const root = bound && codeServerRoot(page.pathname);
    if (!root) return fetch(event.request);
    if (!await ownerFor(bound.token)) {
      return new Response('Resource session unavailable', {status: 410});
    }
    const rewritten = new URL(inCodeServer(url.pathname, root) + url.search, url.origin);
    return routeFetch(event, rewritten);
  })());
});

function localLocation(location, requested, bound) {
  const resolved = new URL(location, requested);
  if (resolved.origin !== requested.origin) return null;
  const virtual = capability(resolved.pathname);
  if (virtual) return virtual.token === bound.token ? resolved.href : null;
  const root = codeServerRoot(requested.pathname);
  if (!root) return null;
  return new URL(inCodeServer(resolved.pathname, root) + resolved.search + resolved.hash,
    requested.origin).href;
}

async function routeFetch(event, url) {
  const bound = capability(url.pathname);
  const owner = bound && await ownerFor(bound.token);
  if (!owner || !bound.route || bound.route.startsWith('_cc_resource/')) {
    return new Response('Resource session unavailable', {status: 410});
  }
  if (bound.route === '_cc_ws_shim.js') {
    return fetch(new URL('cc_resource_ws_shim.js', self.registration.scope));
  }
  const channel = new MessageChannel();
  const port = channel.port1;
  const request = event.request;
  const headers = {};
  for (const [name, value] of request.headers) headers[name] = [value];
  let ready, rejectReady;
  const responseReady = new Promise((resolve, reject) => {
    ready = resolve; rejectReady = reject;
  });
  let active = true;
  let controller;
  let pendingPull = 0;
  const chunks = [];
  let ended = false;
  const fail = error => {
    if (!active) return;
    active = false;
    rejectReady(error);
    reader?.cancel().catch(() => {});
    try { controller?.error(error); } catch (_) {}
    try { port.postMessage({kind: 'cancel'}); } catch (_) {}
    port.close();
  };
  const reader = request.body?.getReader();
  port.onmessage = message => {
    const data = message.data;
    if (data?.kind === 'uploadCredit' && reader) {
      reader.read().then(({value, done}) => {
        if (!active) return;
        if (done) port.postMessage({kind: 'uploadEnd'});
        else {
          const bytes = value.slice();
          port.postMessage({kind: 'uploadData', bytes: bytes.buffer}, [bytes.buffer]);
        }
      }).catch(fail);
    } else if (data?.kind === 'headers') {
      ready(data);
    } else if (data?.kind === 'data') {
      if (controller && pendingPull) {
        pendingPull--;
        controller.enqueue(new Uint8Array(data.bytes));
      } else chunks.push(new Uint8Array(data.bytes));
    } else if (data?.kind === 'end') {
      ended = true;
      if (controller && !chunks.length) {
        controller.close();
        active = false;
        port.close();
      }
    } else if (data?.kind === 'error') {
      fail(new Error('Encrypted resource failed'));
    }
  };
  port.onmessageerror = () => fail(new Error('Invalid resource frame'));
  port.start();
  owner.port.postMessage({kind: 'request', meta: {
    kind: 'http', method: request.method, hasBody: !!reader,
    path: '/' + bound.route + url.search,
    headers
  }, port: channel.port2}, [channel.port2]);
  const timer = setTimeout(() => fail(new Error('Resource response timed out')), 15000);
  try {
    const meta = await responseReady;
    clearTimeout(timer);
    const outputHeaders = new Headers();
    for (const [name, values] of Object.entries(meta.headers)) {
      if (/^(connection|transfer-encoding|content-encoding)$/i.test(name)) continue;
      for (const value of values) outputHeaders.append(name, value);
    }
    if (outputHeaders.has('location')) {
      const rewritten = localLocation(outputHeaders.get('location'), url, bound);
      if (!rewritten) throw new Error('External resource redirect denied');
      outputHeaders.set('location', rewritten);
    }
    outputHeaders.set('cache-control', 'no-store');
    if (codeServerRoot(url.pathname)) {
      outputHeaders.set('cross-origin-embedder-policy', 'credentialless');
    }
    const isHtml = /^text\/html\b/i.test(outputHeaders.get('content-type') || '') &&
      codeServerRoot(url.pathname) && meta.status === 200;
    if (isHtml) outputHeaders.delete('content-length');
    if (request.method === 'HEAD' || [204, 205, 304].includes(meta.status)) {
      active = false;
      reader?.cancel().catch(() => {});
      port.postMessage({kind: 'cancel'});
      port.close();
      return new Response(null, {status: meta.status, headers: outputHeaders});
    }
    const stream = new ReadableStream({
      start(c) { controller = c; },
      pull(c) {
        if (chunks.length) {
          c.enqueue(chunks.shift());
          if (ended && !chunks.length) {
            c.close();
            active = false;
            port.close();
          }
        } else if (ended) {
          c.close();
          active = false;
          port.close();
        } else { pendingPull++; port.postMessage({kind: 'credit'}); }
      },
      cancel() {
        active = false;
        port.postMessage({kind: 'cancel'});
        port.close();
        reader?.cancel().catch(() => {});
      }
    }, {highWaterMark: 0});
    let body = stream;
    if (isHtml) {
      // Insert the WebSocket shim *inside* head, before the first application
      // script. Never reinterpret or persist the rest of the HTML document.
      const source = stream.getReader();
      const policyNonce = nonceFromPolicy(outputHeaders.get('content-security-policy'));
      let initial = new Uint8Array();
      body = new ReadableStream({
        async pull(c) {
          if (initial !== null) {
            while (initial.length < 65536) {
              const next = await source.read();
              if (next.done) break;
              const merged = new Uint8Array(initial.length + next.value.length);
              merged.set(initial); merged.set(next.value, initial.length);
              initial = merged;
              const text = new TextDecoder().decode(initial);
              const head = /<head(?:\s[^>]*)?>/i.exec(text);
              if (!head) continue;
              const rest = text.substring(head.index + head[0].length);
              const firstScript = /<script\b[^>]*>/i.exec(rest);
              const headEnd = /<\/head\s*>/i.exec(rest);
              if (!policyNonce && !firstScript && !headEnd) continue;
              const nonce = policyNonce || nonceFromScript(firstScript?.[0]);
              // Only the CSP base64 alphabet enters the HTML attribute.
              const attribute = nonce ? ` nonce="${nonce}"` : '';
              const offset = encoder.encode(text.substring(0, head.index + head[0].length)).length;
              const script = encoder.encode(
                `<script${attribute} src="${prefix}${bound.token}/_cc_ws_shim.js"></script>`);
              c.enqueue(initial.subarray(0, offset)); c.enqueue(script);
              c.enqueue(initial.subarray(offset)); initial = null;
              return;
            }
            throw new Error('Code-server HTML has no bounded head');
          }
          const next = await source.read();
          if (next.done) c.close(); else c.enqueue(next.value);
        },
        cancel(reason) { source.cancel(reason); }
      }, {highWaterMark: 0});
    }
    return new Response(body, {status: meta.status, headers: outputHeaders});
  } catch (_) {
    fail(new Error('Encrypted resource unavailable'));
    return new Response('Resource unavailable', {status: 502});
  }
}
