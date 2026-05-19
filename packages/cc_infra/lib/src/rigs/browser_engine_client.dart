// The protocol-neutral contract behind a browser rig, plus everything three
// engines can share.
//
// `BrowserRigDriver` used to hold a `CdpClient` by type, so "a browser rig"
// and "Chromium" were the same statement. They are not: Firefox answers
// WebDriver BiDi (its remote agent dropped CDP outright) and WebKit answers
// classic W3C WebDriver, and a page that renders in one and breaks in another
// is the whole reason someone opens a second rig. The driver now speaks to
// [BrowserEngineClient]; `CdpClient` is one implementation of it.
//
// Two things live here so the three engines cannot drift apart:
//
//  * The IN-PAGE scripts. Selection, clipboard, element geometry, the DOM and
//    accessibility digests are all JavaScript in the end — CDP has native
//    domains for some of them, the other two engines have `script.evaluate`
//    and `/execute/sync`. One copy of each script means one behaviour and one
//    place to fix a bug in it.
//  * The W3C INPUT vocabulary. BiDi's `input.performActions` and classic
//    WebDriver's `POST /actions` take a byte-identical payload, so pointer,
//    key and wheel input is built once here and posted by whichever subclass.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';

/// A browser engine refused a command, or answered one malformed.
///
/// One type across the three protocols on purpose: every caller does the same
/// thing with it (say what happened to a person or a model), and a
/// per-protocol hierarchy would only push that switch into the driver.
class BrowserEngineException implements Exception {
  /// Creates a [BrowserEngineException].
  const BrowserEngineException(this.message, {this.code});

  /// What the engine said.
  final String message;

  /// Its error code, when it supplied a numeric one.
  final int? code;

  @override
  String toString() =>
      'BrowserEngineException${code == null ? '' : ' ($code)'}: $message';
}

/// What a page said when asked for its clipboard.
///
/// Named a SNAPSHOT rather than a "read" because the domain already owns a
/// `BrowserClipboardRead` — that one is the VERB an agent sends, this one is
/// what came back.
///
/// [unavailable] is a first-class outcome, not an error: `navigator.clipboard`
/// exists only in a secure context, so a page served over plain `http://`
/// genuinely has no clipboard to read. Reporting that as an empty clipboard
/// would be a different — and false — claim, and the caller needs to be able
/// to tell a person which one it is.
class BrowserClipboardSnapshot {
  /// Creates a [BrowserClipboardSnapshot].
  const BrowserClipboardSnapshot({
    this.text,
    this.imageBase64,
    this.imageMediaType,
    this.unavailable,
  });

  /// Plain text on the clipboard, when there is any.
  final String? text;

  /// Base64 image bytes, when there are any.
  final String? imageBase64;

  /// The image's MIME type.
  final String? imageMediaType;

  /// Why the clipboard could not be reached, or null when it could.
  final String? unavailable;

  /// Whether the clipboard was readable at all.
  bool get ok => unavailable == null;
}

/// One frame off a live browser lane.
class BrowserFrame {
  /// Creates a [BrowserFrame].
  const BrowserFrame({
    required this.bytes,
    this.sessionId = -1,
    this.mediaType = 'image/jpeg',
  });

  /// The already-decoded image bytes.
  final Uint8List bytes;

  /// The engine's frame-acknowledgement token, or -1 when the engine has
  /// none. Chromium releases the next frame only once the previous one is
  /// acked, so this doubles as its backpressure token; a polled lane has
  /// nothing to ack and leaves it at -1.
  final int sessionId;

  /// What the bytes actually are. Not always JPEG: WebKit's driver returns
  /// PNG, and a lane that declared JPEG while shipping PNG is precisely the
  /// bug the codec-declaration rule exists to prevent.
  final String mediaType;
}

/// Something the page did that the chrome around it has to know about.
///
/// Deliberately tiny. The toolbar needs two facts — where the page is and
/// whether it is still loading — and every engine can report both, whereas
/// their raw event vocabularies have nothing in common.
sealed class BrowserPageEvent {
  const BrowserPageEvent();
}

/// The main frame is now at [url], however it got there.
class BrowserPageUrlChanged extends BrowserPageEvent {
  /// Creates a [BrowserPageUrlChanged].
  const BrowserPageUrlChanged(this.url);

  /// The main frame's new URL.
  final String url;
}

/// The main frame started ([loading] true) or finished loading.
class BrowserPageLoadingChanged extends BrowserPageEvent {
  /// Creates a [BrowserPageLoadingChanged].
  const BrowserPageLoadingChanged({required this.loading});

  /// Whether a load is in flight.
  final bool loading;
}

/// The live navigation state, as the toolbar needs it.
typedef BrowserNavigationState = ({
  String url,
  bool canGoBack,
  bool canGoForward,
});

/// Drives one page in one browser, whatever protocol that browser speaks.
///
/// Every method here is something `BrowserRigDriver` asks for on behalf of a
/// domain verb, so the interface is the verb list and nothing else: no
/// protocol handles, no target ids, no session objects. An engine that cannot
/// do something answers honestly (false, null, an `unavailable` reason)
/// rather than throwing, because "this browser cannot" is a normal answer a
/// person or a model has to be told.
abstract interface class BrowserEngineClient {
  /// Which browser is on the other end.
  RigBrowserEngine get engine;

  /// Navigation lifecycle, normalised. Broadcast: the driver listens, and so
  /// may a second watcher.
  Stream<BrowserPageEvent> get pageEvents;

  /// Navigates to [url]. False means the navigation was accepted but the load
  /// event never arrived inside [timeout] — the page may still be fetching,
  /// which is not the same as a failure.
  Future<bool> navigate(String url, {Duration timeout});

  /// Reloads the current page. [ignoreCache] bypasses the HTTP cache.
  Future<void> reload({bool ignoreCache});

  /// Stops an in-flight load.
  Future<void> stopLoading();

  /// Navigates the session history by [delta] (negative = back). False when
  /// there is no entry that far away.
  Future<bool> goHistory(int delta);

  /// The live navigation state, read from the session history.
  Future<BrowserNavigationState> navigationState();

  /// The current page URL, or empty when unknown.
  Future<String> currentUrl();

  /// Captures the viewport (or the whole page) as base64 image data of
  /// [RigBrowserEngine.stillMediaType].
  Future<String> captureScreenshot({
    bool fullPage,
    int quality,
    int? maxWidth,
    int? maxHeight,
  });

  /// Resizes the page's viewport.
  ///
  /// [width]/[height] are CSS pixels; [deviceScaleFactor] is how many DEVICE
  /// pixels the guest renders per CSS pixel, which is what decides how sharp
  /// the watch lane is. NOT every engine can honour it — classic WebDriver has
  /// no such verb — so an implementation that cannot must say so in its own
  /// doc rather than appearing to apply it.
  Future<void> setViewport({
    required int width,
    required int height,
    bool mobile,
    double deviceScaleFactor,
  });

  /// Resolves [selector] to its viewport centre, or null when it does not
  /// match or is not laid out.
  Future<(int, int)?> centerOf(String selector);

  /// Moves the pointer. [dragging] keeps the primary button reported as held,
  /// which is what makes a drag extend a selection instead of ending it.
  Future<void> moveMouse(int x, int y, {bool dragging});

  /// Presses [button] at viewport coordinates. [clickCount] is what makes a
  /// second press a double-click rather than two clicks.
  Future<void> mouseDown(int x, int y, {String button, int clickCount});

  /// Releases [button] at viewport coordinates, repeating the press's
  /// [clickCount] the way a real mouse does.
  Future<void> mouseUp(int x, int y, {String button, int clickCount});

  /// Presses and releases in one go.
  Future<void> clickAt(int x, int y, {String button, int clickCount});

  /// Scrolls the page by a delta, with the pointer notionally at ([x], [y]).
  Future<void> scrollBy(int dx, int dy, {int x, int y});

  /// Scrolls with the pointer over [selector]'s centre. False when nothing
  /// matches — never a silent fall back to the page, which scrolls something
  /// else entirely.
  Future<bool> scrollAt(String selector, int dx, int dy);

  /// Types literal [text] into whatever has focus.
  Future<void> typeText(String text);

  /// Sets an input's value through real input events, so a framework that
  /// tracks its own state actually sees the change.
  Future<bool> fill(String selector, String text, {bool submit});

  /// Presses a DOM-named key (`Enter`, `ArrowDown`, `F5`) or inserts a single
  /// character. False when the name is not one this engine knows.
  Future<bool> pressKey(String key, {List<String> modifiers});

  /// Waits until [selector] matches, or gives up after [timeout].
  Future<bool> waitFor(String selector, Duration timeout);

  /// The page's accessibility tree as text.
  Future<String> accessibilitySnapshot({String? selector});

  /// A pruned view of the DOM. Null when [selector] matches nothing.
  Future<String?> domSnapshot({String? selector, int maxNodes});

  /// Console output captured since the last drain.
  List<String> drainConsole();

  /// What this engine's console lane cannot see, or null when it sees
  /// everything.
  ///
  /// Not every engine has a console FEED. WebKit's driver has no log endpoint
  /// at all, so its output is captured by hooking `console.*` in the page —
  /// which cannot exist before the document does. An empty console then means
  /// two different things ("the page logged nothing" and "the page logged
  /// before we could listen"), and a caller that reports the first when the
  /// second happened has sent someone hunting the wrong bug.
  String? get consoleCaveat;

  /// Reads the page's clipboard, or reports why it could not.
  Future<BrowserClipboardSnapshot> readClipboard();

  /// The page's current selection as plain text, or an empty string.
  Future<String> readSelectionText();

  /// Puts text or an image on the page's clipboard. Null on success, or the
  /// reason it failed.
  Future<String?> writeClipboard({
    String? text,
    String? imageBase64,
    String? imageMediaType,
  });

  /// Drops guest-side files onto the page at ([x], [y]) as a REAL drop event.
  ///
  /// False when this engine cannot synthesize one. Only Chromium can: CDP
  /// builds the `DataTransfer` from guest paths inside the browser, and
  /// nothing in BiDi or classic WebDriver has an equivalent — JavaScript
  /// cannot manufacture a `File` for a path it is not allowed to read.
  Future<bool> dropFiles({
    required List<String> guestPaths,
    required int x,
    required int y,
  });

  /// Points the `<input type=file>` matching [selector] at [guestPaths].
  Future<bool> setFileInputFiles({
    required String selector,
    required List<String> guestPaths,
  });

  /// Whether the engine PUSHES frames.
  ///
  /// False means the watch lane has to poll stills, which is a real
  /// difference and not an implementation detail: a screencast costs nothing
  /// while a page is static, and a poll costs a full capture per tick
  /// forever.
  bool get supportsScreencast;

  /// Pushed frames, when [supportsScreencast]. An engine without one leaves
  /// this empty rather than faking a lane.
  Stream<BrowserFrame> get screencastFrames;

  /// Starts the pushed lane. A no-op on an engine without one.
  Future<void> startScreencast({
    required int maxWidth,
    required int maxHeight,
    int quality,
    int everyNthFrame,
  });

  /// Stops the pushed lane.
  Future<void> stopScreencast();

  /// Acknowledges a pushed frame, releasing the next one.
  Future<void> ackScreencastFrame(int sessionId);

  /// Closes the client. The browser is not the client's to destroy.
  Future<void> close();
}

// ── Shared in-page scripts ───────────────────────────────────────────────────
//
// Each one evaluates to a JSON STRING, never to a structured value: CDP,
// BiDi and classic WebDriver each serialise objects differently (remote object
// handles, `RemoteValue` unions, JSON wire values), and stringifying in the
// page means one parse on this side for all three.

/// Reads the current selection. `{"text": "..."}`.
const String kBrowserReadSelectionScript = '''
JSON.stringify({ text: (window.getSelection && String(window.getSelection() || '')) || '' })
''';

/// Reads the clipboard, or says why it could not.
///
/// `navigator.clipboard` is gated on a secure context, so the `unavailable`
/// branch is a normal outcome on a plain-`http://` page rather than a
/// failure to report as an error.
const String kBrowserReadClipboardScript = '''
(async () => {
  try {
    if (!navigator.clipboard) {
      return JSON.stringify({ unavailable: 'this page has no clipboard API (it is not a secure context)' });
    }
    if (navigator.clipboard.read) {
      try {
        const items = await navigator.clipboard.read();
        for (const item of items) {
          const imageType = item.types.find((t) => t.startsWith('image/'));
          if (imageType) {
            const blob = await item.getType(imageType);
            const buf = new Uint8Array(await blob.arrayBuffer());
            let bin = '';
            for (let i = 0; i < buf.length; i++) bin += String.fromCharCode(buf[i]);
            return JSON.stringify({ image: btoa(bin), mime: imageType });
          }
        }
      } catch (e) { /* fall through to text */ }
    }
    const text = await navigator.clipboard.readText();
    return JSON.stringify({ text: text || '' });
  } catch (e) {
    return JSON.stringify({ unavailable: String((e && e.message) || e) });
  }
})()
''';

/// Puts [text] on the clipboard.
String browserWriteClipboardTextScript(String text) =>
    '''
(async () => {
  try {
    if (!navigator.clipboard) {
      return JSON.stringify({ unavailable: 'this page has no clipboard API (it is not a secure context)' });
    }
    await navigator.clipboard.writeText(${browserJsString(text)});
    return JSON.stringify({ ok: true });
  } catch (e) {
    return JSON.stringify({ unavailable: String((e && e.message) || e) });
  }
})()
''';

/// Puts a base64 image on the clipboard.
String browserWriteClipboardImageScript(String base64, String mediaType) =>
    '''
(async () => {
  try {
    if (!navigator.clipboard || !navigator.clipboard.write || typeof ClipboardItem === 'undefined') {
      return JSON.stringify({ unavailable: 'this page cannot accept an image on its clipboard' });
    }
    const bin = atob(${browserJsString(base64)});
    const buf = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) buf[i] = bin.charCodeAt(i);
    const blob = new Blob([buf], { type: ${browserJsString(mediaType)} });
    await navigator.clipboard.write([new ClipboardItem({ [${browserJsString(mediaType)}]: blob })]);
    return JSON.stringify({ ok: true });
  } catch (e) {
    return JSON.stringify({ unavailable: String((e && e.message) || e) });
  }
})()
''';

/// Resolves a selector to its viewport centre. `null` when it does not match
/// or has no layout box.
///
/// Scrolls the element into view first, exactly as CDP's `DOM.getBoxModel`
/// path does not: a centre computed for something below the fold is a
/// coordinate the pointer can never reach, and clicking it hits whatever
/// happens to be at that y instead.
String browserCenterOfScript(String selector) =>
    '''
(() => {
  const el = document.querySelector(${browserJsString(selector)});
  if (!el) return JSON.stringify(null);
  if (el.scrollIntoView) el.scrollIntoView({ block: 'center', inline: 'center' });
  const r = el.getBoundingClientRect();
  if (!r || (r.width === 0 && r.height === 0)) return JSON.stringify(null);
  return JSON.stringify({ x: Math.round(r.x + r.width / 2), y: Math.round(r.y + r.height / 2) });
})()
''';

/// Selects everything in the focused editable, or the whole document.
const String kBrowserSelectAllScript = '''
(() => {
  const el = document.activeElement;
  if (el && typeof el.select === 'function') { el.select(); return JSON.stringify({ ok: true }); }
  if (el && el.isContentEditable) {
    const range = document.createRange();
    range.selectNodeContents(el);
    const sel = window.getSelection();
    sel.removeAllRanges();
    sel.addRange(range);
    return JSON.stringify({ ok: true });
  }
  return JSON.stringify({ ok: false });
})()
''';

/// Whether a selector currently matches. `{"found": bool}`.
String browserExistsScript(String selector) =>
    '''
JSON.stringify({ found: !!document.querySelector(${browserJsString(selector)}) })
''';

/// The DOM digest, in the same line shape the CDP path emits.
///
/// A pruned view — interactive elements and visible text with the selectors
/// needed to act on them — because a real page's markup is mostly framework
/// scaffolding and 400 KB of `div` spends a context window without teaching
/// anything.
String browserDomSnapshotScript(String? selector, int maxNodes) =>
    '''
(() => {
  const root = ${selector == null || selector.isEmpty ? 'document.documentElement' : 'document.querySelector(${browserJsString(selector)})'};
  if (!root) return JSON.stringify(null);
  const skipped = new Set(['script', 'style', 'noscript', 'meta', 'link', 'head', 'template', 'svg', 'path']);
  const keep = ['id', 'name', 'type', 'href', 'aria-label', 'placeholder', 'value', 'role', 'class'];
  const lines = [];
  let count = 0;
  const walk = (node, depth) => {
    if (count >= $maxNodes) return;
    if (node.nodeType === 3) {
      const text = (node.nodeValue || '').trim();
      if (text) { lines.push('  '.repeat(depth) + '"' + text + '"'); count++; }
      return;
    }
    if (node.nodeType !== 1) return;
    const tag = node.nodeName.toLowerCase();
    if (!skipped.has(tag)) {
      let out = '  '.repeat(depth) + '<' + tag;
      for (const key of keep) {
        let v = node.getAttribute ? node.getAttribute(key) : null;
        if (key === 'value' && !v && typeof node.value === 'string') v = node.value;
        if (v) {
          if (v.length > 60) v = v.slice(0, 60) + '\\u2026';
          out += ' ' + key + '="' + v + '"';
        }
      }
      lines.push(out + '>');
      count++;
    } else {
      return;
    }
    for (const child of node.childNodes) walk(child, depth + 1);
  };
  walk(root, 0);
  if (count >= $maxNodes) lines.push('[\\u2026truncated at $maxNodes nodes]');
  return JSON.stringify({ text: lines.join('\\n') });
})()
''';

/// A role/name digest of the page, derived from the DOM.
///
/// Explicitly NOT the browser's own accessibility tree: neither BiDi nor
/// classic WebDriver exposes one, so this computes roles from tags and ARIA
/// and names from labels, `aria-label`, `alt` and text. It is close enough to
/// navigate by and it is honest about being a derivation — the caller labels
/// it as such rather than letting a model believe it read the platform tree.
String browserA11ySnapshotScript(String? selector, int maxNodes) =>
    '''
(() => {
  const root = ${selector == null || selector.isEmpty ? 'document.body || document.documentElement' : 'document.querySelector(${browserJsString(selector)})'};
  if (!root) return JSON.stringify(null);
  const implicit = {
    a: 'link', button: 'button', input: 'textbox', select: 'combobox', textarea: 'textbox',
    h1: 'heading', h2: 'heading', h3: 'heading', h4: 'heading', h5: 'heading', h6: 'heading',
    img: 'image', nav: 'navigation', main: 'main', header: 'banner', footer: 'contentinfo',
    form: 'form', table: 'table', ul: 'list', ol: 'list', li: 'listitem', label: 'label',
    summary: 'button', dialog: 'dialog', progress: 'progressbar', option: 'option',
  };
  const roleOf = (el) => {
    const explicit = el.getAttribute('role');
    if (explicit) return explicit;
    const tag = el.nodeName.toLowerCase();
    if (tag === 'input') {
      const t = (el.getAttribute('type') || 'text').toLowerCase();
      if (t === 'checkbox') return 'checkbox';
      if (t === 'radio') return 'radio';
      if (t === 'button' || t === 'submit' || t === 'reset') return 'button';
      if (t === 'range') return 'slider';
      return 'textbox';
    }
    return implicit[tag] || '';
  };
  const nameOf = (el) => {
    const aria = el.getAttribute('aria-label');
    if (aria) return aria.trim();
    const labelled = el.getAttribute('aria-labelledby');
    if (labelled) {
      const target = document.getElementById(labelled);
      if (target) return (target.textContent || '').trim();
    }
    if (el.labels && el.labels.length) return (el.labels[0].textContent || '').trim();
    const alt = el.getAttribute('alt');
    if (alt) return alt.trim();
    const placeholder = el.getAttribute('placeholder');
    if (placeholder) return placeholder.trim();
    const title = el.getAttribute('title');
    if (title) return title.trim();
    return (el.textContent || '').trim().slice(0, 120);
  };
  const hidden = (el) => {
    if (el.getAttribute('aria-hidden') === 'true') return true;
    const style = window.getComputedStyle(el);
    return style.display === 'none' || style.visibility === 'hidden';
  };
  const lines = [];
  let count = 0;
  const walk = (el) => {
    if (count >= $maxNodes || !el || el.nodeType !== 1) return;
    if (hidden(el)) return;
    const role = roleOf(el);
    if (role) {
      const name = nameOf(el);
      const value = (typeof el.value === 'string' && el.value) ? el.value : '';
      lines.push(role + (name ? ': "' + name + '"' : '') + (value ? ' = "' + value + '"' : ''));
      count++;
    }
    for (const child of el.children) walk(child);
  };
  walk(root);
  if (count >= $maxNodes) lines.push('[\\u2026truncated at $maxNodes nodes]');
  return JSON.stringify({ text: lines.join('\\n') });
})()
''';

/// A JS string literal for [value], safe to interpolate into a script.
String browserJsString(String value) => jsonEncode(value)
    .replaceAll('<', r'\u003C')
    .replaceAll('\u2028', r'\u2028')
    .replaceAll('\u2029', r'\u2029');

// ── The W3C action vocabulary ────────────────────────────────────────────────

/// Builds W3C `actions` source objects — the payload shape BiDi's
/// `input.performActions` and classic WebDriver's `POST /actions` share
/// byte-for-byte.
// ignore: avoid_classes_with_only_static_members
abstract final class W3cActions {
  /// The mouse button numbers the W3C spec uses.
  static int buttonNumber(String button) => switch (button) {
    'right' => 2,
    'middle' => 1,
    _ => 0,
  };

  /// A pointer source carrying [actions].
  static Map<String, dynamic> pointer(List<Map<String, dynamic>> actions) => {
    'type': 'pointer',
    'id': 'cc-mouse',
    'parameters': {'pointerType': 'mouse'},
    'actions': actions,
  };

  /// A key source carrying [actions].
  static Map<String, dynamic> keys(List<Map<String, dynamic>> actions) => {
    'type': 'key',
    'id': 'cc-keyboard',
    'actions': actions,
  };

  /// A wheel source carrying [actions].
  static Map<String, dynamic> wheel(List<Map<String, dynamic>> actions) => {
    'type': 'wheel',
    'id': 'cc-wheel',
    'actions': actions,
  };

  /// Moves the pointer to viewport coordinates.
  static Map<String, dynamic> move(int x, int y, {int durationMs = 0}) => {
    'type': 'pointerMove',
    'x': x,
    'y': y,
    'duration': durationMs,
    'origin': 'viewport',
  };

  /// Presses a button.
  static Map<String, dynamic> down(String button) => {
    'type': 'pointerDown',
    'button': buttonNumber(button),
  };

  /// Releases a button.
  static Map<String, dynamic> up(String button) => {
    'type': 'pointerUp',
    'button': buttonNumber(button),
  };

  /// A pointer pause, which is how a double-click is expressed: the spec has
  /// no click COUNT, so the count comes from how quickly the presses arrive.
  static Map<String, dynamic> pause(int ms) => {
    'type': 'pause',
    'duration': ms,
  };

  /// A key press.
  static Map<String, dynamic> keyDown(String value) => {
    'type': 'keyDown',
    'value': value,
  };

  /// A key release.
  static Map<String, dynamic> keyUp(String value) => {
    'type': 'keyUp',
    'value': value,
  };

  /// A wheel scroll anchored at ([x], [y]).
  static Map<String, dynamic> scroll(int x, int y, int dx, int dy) => {
    'type': 'scroll',
    'x': x,
    'y': y,
    'deltaX': dx,
    'deltaY': dy,
    'duration': 0,
    'origin': 'viewport',
  };

  /// The W3C key value for a DOM key name, or null when it is not a named
  /// key.
  ///
  /// The spec addresses special keys by codepoints in a private-use block
  /// (`` is Enter), which is why a name table is unavoidable — sending
  /// the literal string "Enter" types five characters.
  static String? namedKey(String key) => _w3cNamedKeys[key.toLowerCase()];

  /// The W3C key value for a modifier name, or null.
  static String? modifierKey(String modifier) =>
      _w3cModifiers[modifier.toLowerCase()];
}

/// DOM key name → W3C key value. Keyed lowercase so `enter`, `Enter` and
/// `ENTER` all resolve.
const Map<String, String> _w3cNamedKeys = {
  'enter': '\u{E007}',
  'return': '\u{E007}',
  'tab': '\u{E004}',
  'escape': '\u{E00C}',
  'esc': '\u{E00C}',
  'backspace': '\u{E003}',
  'delete': '\u{E017}',
  'insert': '\u{E016}',
  'space': '\u{E00D}',
  ' ': '\u{E00D}',
  'arrowup': '\u{E013}',
  'arrowdown': '\u{E015}',
  'arrowleft': '\u{E012}',
  'arrowright': '\u{E014}',
  'up': '\u{E013}',
  'down': '\u{E015}',
  'left': '\u{E012}',
  'right': '\u{E014}',
  'home': '\u{E011}',
  'end': '\u{E010}',
  'pageup': '\u{E00E}',
  'pagedown': '\u{E00F}',
  'f1': '\u{E031}',
  'f2': '\u{E032}',
  'f3': '\u{E033}',
  'f4': '\u{E034}',
  'f5': '\u{E035}',
  'f6': '\u{E036}',
  'f7': '\u{E037}',
  'f8': '\u{E038}',
  'f9': '\u{E039}',
  'f10': '\u{E03A}',
  'f11': '\u{E03B}',
  'f12': '\u{E03C}',
};

/// Modifier name → W3C key value.
///
/// `meta` and `control` are separate entries rather than one
/// platform-dependent "primary": the guest is Linux in every rig, so `ctrl+c`
/// is the copy chord and silently translating a `meta` request to it would
/// hide a caller's mistake.
const Map<String, String> _w3cModifiers = {
  'alt': '\u{E00A}',
  'option': '\u{E00A}',
  'control': '\u{E009}',
  'ctrl': '\u{E009}',
  'shift': '\u{E008}',
  'meta': '\u{E03D}',
  'command': '\u{E03D}',
  'cmd': '\u{E03D}',
};

// ── The scripted base ────────────────────────────────────────────────────────

/// Everything an engine gets for free once it can evaluate a script and post
/// W3C actions.
///
/// Firefox (BiDi) and WebKit (classic WebDriver) differ in their transport and
/// in about six calls; the other twenty are the same JavaScript and the same
/// action payloads. Putting them here is what stops "clicking in Firefox" and
/// "clicking in WebKit" from becoming two behaviours nobody compares.
abstract class ScriptedBrowserEngineClient implements BrowserEngineClient {
  /// Evaluates [expression] in the page and parses the JSON STRING it
  /// produces, or returns null when the page did not answer.
  Future<Object?> evaluateJson(String expression);

  /// Posts W3C action [sources] to the page.
  Future<void> performActions(List<Map<String, dynamic>> sources);

  /// Console lines captured since the last drain.
  final List<String> consoleBuffer = <String>[];

  /// How many console lines are retained before the oldest are dropped.
  static const int consoleBufferLimit = 500;

  /// Records one console line, bounding the buffer.
  void recordConsole(String line) {
    consoleBuffer.add(line);
    if (consoleBuffer.length > consoleBufferLimit) {
      consoleBuffer.removeRange(0, consoleBuffer.length - consoleBufferLimit);
    }
  }

  @override
  List<String> drainConsole() {
    final drained = List<String>.from(consoleBuffer);
    consoleBuffer.clear();
    return drained;
  }

  @override
  String? get consoleCaveat => null;

  @override
  bool get supportsScreencast => false;

  @override
  Stream<BrowserFrame> get screencastFrames => const Stream.empty();

  @override
  Future<void> startScreencast({
    required int maxWidth,
    required int maxHeight,
    int quality = 70,
    int everyNthFrame = 1,
  }) async {
    // Nothing to start. The driver polls this engine instead, and checks
    // `supportsScreencast` before it gets here — this stays a no-op rather
    // than a throw so a caller that does not check simply gets no lane.
  }

  @override
  Future<void> stopScreencast() async {}

  @override
  Future<void> ackScreencastFrame(int sessionId) async {}

  @override
  Future<bool> dropFiles({
    required List<String> guestPaths,
    required int x,
    required int y,
  }) async =>
      // No engine but Chromium can build a `DataTransfer` from host-named
      // paths. Reported as "the page did not take it" rather than thrown: the
      // caller's fallback (the files are in the machine, point a file input
      // at them) is the honest outcome and it already has words for it.
      false;

  @override
  Future<(int, int)?> centerOf(String selector) async {
    final value = await evaluateJson(browserCenterOfScript(selector));
    if (value is! Map) {
      return null;
    }
    final x = value['x'];
    final y = value['y'];
    if (x is! num || y is! num) {
      return null;
    }
    return (x.round(), y.round());
  }

  @override
  Future<void> moveMouse(int x, int y, {bool dragging = false}) async {
    // `dragging` needs no bookkeeping here. W3C pointer state is held by the
    // ENGINE across `performActions` calls, so a button pressed by an earlier
    // call is still down for this move — which is exactly what makes a drag
    // extend a selection. CDP has to be told (its `buttons` mask) because
    // each of its input events is independent.
    await performActions([
      W3cActions.pointer([W3cActions.move(x, y)]),
    ]);
  }

  @override
  Future<void> mouseDown(
    int x,
    int y, {
    String button = 'left',
    int clickCount = 1,
  }) async {
    await performActions([
      W3cActions.pointer([
        W3cActions.move(x, y),
        // A double-click is not a count in this vocabulary — it is two
        // presses close enough together for the engine to coalesce. The
        // leading presses are replayed here so the second (or third) press
        // carries the `detail` a page's own handler reads.
        for (var i = 1; i < clickCount; i++) ...[
          W3cActions.down(button),
          W3cActions.up(button),
          W3cActions.pause(16),
        ],
        W3cActions.down(button),
      ]),
    ]);
  }

  @override
  Future<void> mouseUp(
    int x,
    int y, {
    String button = 'left',
    int clickCount = 1,
  }) async {
    await performActions([
      W3cActions.pointer([W3cActions.move(x, y), W3cActions.up(button)]),
    ]);
  }

  @override
  Future<void> clickAt(
    int x,
    int y, {
    String button = 'left',
    int clickCount = 1,
  }) async {
    await performActions([
      W3cActions.pointer([
        W3cActions.move(x, y),
        for (var i = 0; i < (clickCount < 1 ? 1 : clickCount); i++) ...[
          W3cActions.down(button),
          W3cActions.up(button),
          if (i + 1 < clickCount) W3cActions.pause(16),
        ],
      ]),
    ]);
  }

  @override
  Future<void> scrollBy(int dx, int dy, {int x = 10, int y = 10}) =>
      performActions([
        W3cActions.wheel([W3cActions.scroll(x, y, dx, dy)]),
      ]);

  @override
  Future<bool> scrollAt(String selector, int dx, int dy) async {
    final centre = await centerOf(selector);
    if (centre == null) {
      return false;
    }
    await scrollBy(dx, dy, x: centre.$1, y: centre.$2);
    return true;
  }

  @override
  Future<void> typeText(String text) async {
    if (text.isEmpty) {
      return;
    }
    // One key source, one keyDown/keyUp pair per RUNE — not per UTF-16 code
    // unit. Splitting an emoji into its surrogate halves sends two keys that
    // are not characters, and the page receives neither.
    await performActions([
      W3cActions.keys([
        for (final rune in text.runes) ...[
          W3cActions.keyDown(String.fromCharCode(rune)),
          W3cActions.keyUp(String.fromCharCode(rune)),
        ],
      ]),
    ]);
  }

  @override
  Future<bool> pressKey(String key, {List<String> modifiers = const []}) async {
    final held = <String>[
      for (final m in modifiers) ?W3cActions.modifierKey(m),
    ];
    if (held.length != modifiers.length) {
      return false;
    }
    final named = W3cActions.namedKey(key);
    final String value;
    if (named != null) {
      value = named;
    } else if (key.runes.length == 1) {
      value = key;
    } else {
      return false;
    }
    await performActions([
      W3cActions.keys([
        for (final m in held) W3cActions.keyDown(m),
        W3cActions.keyDown(value),
        W3cActions.keyUp(value),
        for (final m in held.reversed) W3cActions.keyUp(m),
      ]),
    ]);
    return true;
  }

  @override
  Future<bool> fill(String selector, String text, {bool submit = false}) async {
    final centre = await centerOf(selector);
    if (centre == null) {
      return false;
    }
    // Click, select all, delete, type — never an assignment to `.value`.
    // React and friends track their own state and ignore a value that arrives
    // without input events, so the direct assignment "works" and then submits
    // empty.
    await clickAt(centre.$1, centre.$2);
    await evaluateJson(kBrowserSelectAllScript);
    await pressKey('Delete');
    if (text.isNotEmpty) {
      await typeText(text);
    }
    if (submit) {
      await pressKey('Enter');
    }
    return true;
  }

  @override
  Future<bool> waitFor(String selector, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final value = await evaluateJson(browserExistsScript(selector));
      if (value is Map && value['found'] == true) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return false;
  }

  @override
  Future<String> accessibilitySnapshot({String? selector}) async {
    final value = await evaluateJson(browserA11ySnapshotScript(selector, 400));
    if (value is! Map) {
      return '';
    }
    final text = value['text'];
    if (text is! String || text.isEmpty) {
      return '';
    }
    // Said out loud on every snapshot. This is a DOM-derived approximation,
    // not the platform accessibility tree — a model that believes it read the
    // real one will trust a computed role it should have verified.
    return '[derived from the DOM — ${engine.label} exposes no accessibility '
        'tree over its automation protocol]\n$text';
  }

  @override
  Future<String?> domSnapshot({String? selector, int maxNodes = 400}) async {
    final value = await evaluateJson(
      browserDomSnapshotScript(selector, maxNodes),
    );
    if (value == null) {
      return null;
    }
    if (value is! Map) {
      return '';
    }
    final text = value['text'];
    final body = text is String ? text : '';
    if (selector != null && selector.isNotEmpty) {
      return '[subtree of $selector]\n$body';
    }
    return body;
  }

  @override
  Future<BrowserClipboardSnapshot> readClipboard() async {
    final value = await evaluateJson(kBrowserReadClipboardScript);
    if (value is! Map) {
      return const BrowserClipboardSnapshot(
        unavailable: 'the page did not answer',
      );
    }
    final unavailable = value['unavailable'];
    if (unavailable is String && unavailable.isNotEmpty) {
      return BrowserClipboardSnapshot(unavailable: unavailable);
    }
    final image = value['image'];
    final mime = value['mime'];
    return BrowserClipboardSnapshot(
      text: value['text'] is String ? value['text'] as String : null,
      imageBase64: image is String && image.isNotEmpty ? image : null,
      imageMediaType: mime is String && mime.isNotEmpty ? mime : null,
    );
  }

  @override
  Future<String> readSelectionText() async {
    final value = await evaluateJson(kBrowserReadSelectionScript);
    final text = value is Map ? value['text'] : null;
    return text is String ? text : '';
  }

  @override
  Future<String?> writeClipboard({
    String? text,
    String? imageBase64,
    String? imageMediaType,
  }) async {
    final script = imageBase64 != null && imageBase64.isNotEmpty
        ? browserWriteClipboardImageScript(
            imageBase64,
            imageMediaType ?? 'image/png',
          )
        : browserWriteClipboardTextScript(text ?? '');
    final value = await evaluateJson(script);
    if (value is! Map) {
      return 'the page did not answer';
    }
    final unavailable = value['unavailable'];
    return unavailable is String && unavailable.isNotEmpty ? unavailable : null;
  }

  @override
  Future<String> currentUrl() async {
    try {
      return (await navigationState()).url;
    } on Object {
      // Best effort — the URL is context in a result text, never the answer.
      return '';
    }
  }

  /// Parses the JSON string an in-page script produced.
  ///
  /// Tolerant: a page that threw, or an engine that answered with something
  /// other than a string, reads as "no answer" rather than as an exception
  /// out of a verb the caller expected a boolean from.
  static Object? decodeScriptResult(Object? raw) {
    if (raw is! String || raw.isEmpty) {
      return null;
    }
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
