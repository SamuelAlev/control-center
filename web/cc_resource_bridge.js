/* Local, memory-only broker for an authenticated Flutter resource session.
 * This script never creates a network connection to the remote server. */
(() => {
  const owners = new Map();
  const editorViews = new WeakMap();
  const scope = new URL('.', document.baseURI);
  const workerURL = new URL('cc_resource_worker.js', scope);
  const randomCap = () => {
    const bytes = new Uint8Array(32);
    crypto.getRandomValues(bytes);
    return Array.from(bytes, b => b.toString(16).padStart(2, '0')).join('');
  };

  function bindPort(token, callback, worker) {
    const views = owners.get(token)?.views || new Set();
    owners.get(token)?.port.close();
    const channel = new MessageChannel();
    channel.port1.onmessage = event => {
      const message = event.data;
      if (message?.kind === 'request' && message.port instanceof MessagePort) {
        callback(JSON.stringify(message.meta), message.port);
      }
    };
    channel.port1.start();
    owners.set(token, {port: channel.port1, callback, views});
    worker.postMessage({kind: 'bind', token}, [channel.port2]);
  }

  navigator.serviceWorker?.addEventListener('message', event => {
    const token = event.data?.token;
    if (event.data?.kind !== 'cc-resource-rebind' ||
        event.source !== navigator.serviceWorker.controller ||
        !/^[0-9a-f]{64}$/.test(token || '')) return;
    const owner = owners.get(token);
    if (owner) bindPort(token, owner.callback, event.source);
  });

  function removeEditor(iframe) {
    const token = editorViews.get(iframe);
    if (!token) return;
    editorViews.delete(iframe);
    // Revoke the live document as well as its capability: otherwise the
    // decrypted editor and its scripts remain active after session teardown.
    iframe.src = 'about:blank';
    owners.get(token)?.views.delete(iframe);
  }

  async function attachEditor(iframe, src) {
    removeEditor(iframe);
    const source = new URL(src, location.href);
    const path = source.pathname.substring(scope.pathname.length);
    const match = source.origin === location.origin &&
      source.pathname.startsWith(scope.pathname) &&
      path.match(/^_cc_resource\/([0-9a-f]{64})\/(proxy\/vscode\/[^/]+\/.*)$/);
    if (!match || !owners.has(match[1])) {
      throw new Error('Code-server URL has no live encrypted capability');
    }
    const token = match[1];
    owners.get(token).views.add(iframe);
    editorViews.set(iframe, token);
    iframe.src = source.href;
    return source.href;
  }
  window.ccResourceBridge = {
    async open(callback) {
      if (!isSecureContext || !navigator.serviceWorker) {
        throw new Error('Encrypted resources require a secure Service Worker context');
      }
      await navigator.serviceWorker.register(workerURL.href, {scope: scope.href});
      await navigator.serviceWorker.ready;
      if (navigator.serviceWorker.controller?.scriptURL !== workerURL.href) {
        await new Promise((resolve, reject) => {
          const timer = setTimeout(() => {
            navigator.serviceWorker.removeEventListener('controllerchange', ready);
            reject(new Error('Encrypted resource worker did not take control'));
          }, 10000);
          function ready() {
            if (navigator.serviceWorker.controller?.scriptURL !== workerURL.href) return;
            clearTimeout(timer);
            navigator.serviceWorker.removeEventListener('controllerchange', ready);
            resolve();
          }
          navigator.serviceWorker.addEventListener('controllerchange', ready);
          ready();
        });
      }
      const token = randomCap();
      bindPort(token, callback, navigator.serviceWorker.controller);
      return new URL(`_cc_resource/${token}/`, scope).href;
    },
    close(token) {
      const owner = owners.get(token);
      if (!owner) return;
      for (const view of owner.views) removeEditor(view);
      owner.port.close();
      owners.delete(token);
      navigator.serviceWorker.controller?.postMessage({kind: 'unbind', token});
    },
    attachEditor,
    detachEditor: removeEditor,
    onPort(port, callback) {
      port.onmessage = event => {
        const value = event.data;
        callback(JSON.stringify({kind: value.kind, code: value.code,
          reason: value.reason, text: value.text, amount: value.amount}),
          value.bytes ? new Uint8Array(value.bytes) : null);
      };
      port.onmessageerror = () => callback('{"kind":"cancel"}', null);
      port.start();
    },
    send(port, metadata, bytes) {
      const message = JSON.parse(metadata);
      if (bytes) {
        const view = bytes.slice();
        message.bytes = view.buffer;
        port.postMessage(message, [view.buffer]);
      } else {
        port.postMessage(message);
      }
    },
    release(port) { port.close(); }
  };
})();
