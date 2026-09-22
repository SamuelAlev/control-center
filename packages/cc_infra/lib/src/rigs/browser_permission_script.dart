/// In-page permission interceptor shared by Chromium, Firefox and WebKit.
///
/// Headless guests cannot present a doorhanger. This script wraps the
/// prompting APIs, asks the host, and only then calls through (or rejects).
/// Communication:
///  * Chromium: `Runtime.addBinding('ccBrowserPermission')`
///  * Firefox BiDi: `__ccPermChannel` from a preload-script channel
///  * WebKit: `__ccPermQueue` polled over `execute/sync`
library;

/// Binding / channel name. One string so the three engines cannot drift.
const String kBrowserPermissionBinding = 'ccBrowserPermission';

/// BiDi `script.message` channel id.
const String kBrowserPermissionChannel = 'cc-perm';

/// Installs the wrappers. Idempotent — a second run is a no-op.
const String kBrowserPermissionInstallScript = r'''
(() => {
  if (globalThis.__ccPermInstalled) return JSON.stringify({ok: true});
  globalThis.__ccPermInstalled = true;
  const pending = new Map();
  let n = 0;
  globalThis.__ccPermResolve = (id, allow) => {
    const r = pending.get(String(id));
    if (r) { pending.delete(String(id)); r(!!allow); }
  };
  function emit(payload) {
    try {
      if (typeof globalThis.ccBrowserPermission === 'function') {
        globalThis.ccBrowserPermission(payload);
        return;
      }
    } catch (e) {}
    try {
      if (typeof globalThis.__ccPermChannel === 'function') {
        globalThis.__ccPermChannel(payload);
        return;
      }
    } catch (e) {}
    (globalThis.__ccPermQueue ||= []).push(payload);
  }
  function ask(kind) {
    const id = String(++n);
    emit(JSON.stringify({
      id: id,
      kind: kind,
      origin: (typeof location !== 'undefined' && location.origin) || '',
    }));
    return new Promise((resolve) => pending.set(id, resolve));
  }
  function denied() {
    return new DOMException('Permission denied', 'NotAllowedError');
  }
  try {
    const storage = navigator.storage;
    if (storage && typeof storage.persist === 'function') {
      const orig = storage.persist.bind(storage);
      storage.persist = async function () {
        if (!(await ask('persistent-storage'))) return false;
        try { return await orig(); } catch (e) { return true; }
      };
    }
  } catch (e) {}
  try {
    if (typeof Notification !== 'undefined' && Notification.requestPermission) {
      const orig = Notification.requestPermission.bind(Notification);
      Notification.requestPermission = async function (cb) {
        const allow = await ask('notifications');
        const result = allow ? 'granted' : 'denied';
        if (typeof cb === 'function') try { cb(result); } catch (e) {}
        if (allow) { try { await orig(); } catch (e) {} }
        return result;
      };
    }
  } catch (e) {}
  try {
    const md = navigator.mediaDevices;
    if (md && typeof md.getUserMedia === 'function') {
      const orig = md.getUserMedia.bind(md);
      md.getUserMedia = async function (constraints) {
        const c = constraints || {};
        if (c.audio && !(await ask('microphone'))) throw denied();
        if (c.video && !(await ask('camera'))) throw denied();
        return orig(constraints);
      };
    }
    if (md && typeof md.getDisplayMedia === 'function') {
      const orig = md.getDisplayMedia.bind(md);
      md.getDisplayMedia = async function (constraints) {
        if (!(await ask('display-capture'))) throw denied();
        return orig(constraints);
      };
    }
  } catch (e) {}
  try {
    const geo = navigator.geolocation;
    if (geo && typeof geo.getCurrentPosition === 'function') {
      const wrap = (orig) => function (success, error, options) {
        ask('geolocation').then((allow) => {
          if (allow) orig.call(geo, success, error, options);
          else if (typeof error === 'function') {
            error({code: 1, message: 'Permission denied', PERMISSION_DENIED: 1});
          }
        });
      };
      geo.getCurrentPosition = wrap(geo.getCurrentPosition);
      if (typeof geo.watchPosition === 'function') {
        geo.watchPosition = wrap(geo.watchPosition);
      }
    }
  } catch (e) {}
  try {
    const clip = navigator.clipboard;
    if (clip && typeof clip.readText === 'function') {
      const orig = clip.readText.bind(clip);
      clip.readText = async function () {
        if (!(await ask('clipboard-read'))) throw denied();
        return orig();
      };
    }
    if (clip && typeof clip.read === 'function') {
      const orig = clip.read.bind(clip);
      clip.read = async function () {
        if (!(await ask('clipboard-read'))) throw denied();
        return orig();
      };
    }
  } catch (e) {}
  try {
    if (typeof navigator.requestMIDIAccess === 'function') {
      const orig = navigator.requestMIDIAccess.bind(navigator);
      navigator.requestMIDIAccess = async function (options) {
        if (!(await ask('midi'))) throw denied();
        return orig(options);
      };
    }
  } catch (e) {}
  return JSON.stringify({ok: true});
})()
''';

/// Firefox BiDi preload: binds the channel then installs the wrappers.
const String kBrowserPermissionPreloadFunction =
    '''
function (channel) {
  globalThis.__ccPermChannel = function (payload) {
    try { channel(payload); } catch (e) {}
  };
  $kBrowserPermissionInstallScript;
}
''';

/// Drains WebKit's queued probes. `{items: [payload, …]}`.
const String kBrowserPermissionDrainScript = r'''
(() => {
  const q = globalThis.__ccPermQueue || [];
  globalThis.__ccPermQueue = [];
  return JSON.stringify({items: q});
})()
''';

/// Resolves one parked interceptor promise in the page.
String browserPermissionResolveScript(String id, {required bool allow}) {
  final safeId = id.replaceAll(r'\', r'\\').replaceAll("'", r"\'");
  return '(() => { try { globalThis.__ccPermResolve && '
      "globalThis.__ccPermResolve('$safeId', $allow); } catch (e) {} "
      'return JSON.stringify({ok: true}); })()';
}
