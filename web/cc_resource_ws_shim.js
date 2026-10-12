/* Inserted by the local resource worker before code-server's first script.
 * Native WebSocket cannot be intercepted by a Service Worker. */
(() => {
  if (!/^\/(?:.*\/)?_cc_resource\/[0-9a-f]{64}\/proxy\/vscode\/[^/]+\//.test(location.pathname)) return;
  class EncryptedWebSocket extends EventTarget {
    static CONNECTING = 0; static OPEN = 1; static CLOSING = 2; static CLOSED = 3;
    CONNECTING = 0; OPEN = 1; CLOSING = 2; CLOSED = 3;
    constructor(url, protocols = []) {
      super();
      this.url = String(url);
      this.readyState = 0;
      this.protocol = '';
      this.extensions = '';
      this.bufferedAmount = 0;
      this.binaryType = 'blob';
      this.onopen = this.onmessage = this.onerror = this.onclose = null;
      this._sendQueue = Promise.resolve();
      const requested = Array.isArray(protocols) ? protocols : [protocols];
      const target = new URL(this.url, location.href);
      const converted = target.protocol === 'wss:' ? 'https:' :
        target.protocol === 'ws:' ? 'http:' : '';
      if (!converted || target.host !== location.host) {
        throw new DOMException('Only the encrypted local resource endpoint is available', 'SecurityError');
      }
      target.protocol = converted;
      const channel = new MessageChannel();
      this._port = channel.port1;
      this._port.onmessage = event => {
        const frame = event.data;
        if (frame.kind === 'open' && this.readyState === 0) {
          this.readyState = 1;
          this.protocol = frame.protocol || '';
          this._emit(new Event('open'));
        } else if (frame.kind === 'message' && this.readyState === 1) {
          const data = frame.bytes ?
            (this.binaryType === 'arraybuffer' ? frame.bytes : new Blob([frame.bytes])) : frame.text;
          this._emit(new MessageEvent('message', {data}));
        } else if (frame.kind === 'closed') {
          if (this.readyState === 3) return;
          this.readyState = 3;
          this._emit(new CloseEvent('close', {code: frame.code || 1000,
            reason: frame.reason || '', wasClean: frame.code === 1000}));
          this._port.close();
        } else if (frame.kind === 'error') {
          this._emit(new Event('error'));
        }
      };
      this._port.onmessageerror = () => {
        this._emit(new Event('error'));
        this.close();
      };
      navigator.serviceWorker.controller.postMessage({kind: 'socket',
        url: target.href, protocols: requested}, [channel.port2]);
      this._port.start();
    }
    _emit(event) {
      this.dispatchEvent(event);
      const listener = this[`on${event.type}`];
      if (typeof listener === 'function') listener.call(this, event);
    }
    send(data) {
      if (this.readyState !== 1) throw new DOMException('WebSocket is not open', 'InvalidStateError');
      if (typeof data === 'string') {
        const size = new TextEncoder().encode(data).length;
        this.bufferedAmount += size;
        this._sendQueue = this._sendQueue.then(() => {
          this._port.postMessage({kind: 'send', text: data});
          this.bufferedAmount -= size;
        });
      } else if (data instanceof ArrayBuffer || ArrayBuffer.isView(data) || data instanceof Blob) {
        this._sendQueue = this._sendQueue.then(async () => {
          const buffer = data instanceof Blob ? await data.arrayBuffer() :
            data instanceof ArrayBuffer ? data.slice(0) :
            data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
          this.bufferedAmount += buffer.byteLength;
          this._port.postMessage({kind: 'send', bytes: buffer}, [buffer]);
          this.bufferedAmount -= buffer.byteLength;
        });
      } else throw new TypeError('WebSocket.send accepts strings, blobs, and binary buffers');
    }
    close(code = 1000, reason = '') {
      if (this.readyState >= 2) return;
      if (code !== 1000 && (code < 3000 || code > 4999)) throw new DOMException('Invalid close code', 'InvalidAccessError');
      if (new TextEncoder().encode(reason).length > 123) throw new DOMException('Close reason too long', 'SyntaxError');
      this.readyState = 2;
      this._sendQueue.then(() => this._port.postMessage({kind: 'close', code, reason}));
    }
  }
  window.WebSocket = EncryptedWebSocket;
})();
