// Drives an enclosed WebKit over classic W3C WebDriver.
//
// WebKitGTK speaks neither CDP nor BiDi. `WebKitWebDriver` — the driver
// shipped with the engine — implements the classic WebDriver HTTP protocol,
// so that is what this talks: a session id in the path, JSON in and
// `{"value": …}` out, one request per command.
//
// Classic WebDriver is older and thinner than the other two protocols, and
// three gaps have to be closed here rather than papered over:
//
//  * **No events.** Nothing tells the host that the page navigated. A link a
//    person clicked inside the guest would leave the address bar showing the
//    previous URL forever, so this client POLLS the URL on a slow timer and
//    publishes the change — the same lane Chromium and Firefox fill from real
//    events.
//  * **No console.** WebKit's driver has no log endpoint (the `/log` route
//    was dropped from the standard). Console output is captured by hooking
//    `console.*` in the page and read back on the same timer.
//  * **No viewport command.** `POST /window/rect` sizes the WINDOW, and
//    MiniBrowser's chrome eats the difference — asking for 800 measured a
//    762 px viewport. Every coordinate an agent sends is viewport-relative,
//    so the client measures the delta and re-sizes rather than letting clicks
//    land tens of pixels off.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';

/// A WebDriver command came back as an error.
class WebDriverException extends BrowserEngineException {
  /// Creates a [WebDriverException].
  const WebDriverException(super.message, {this.error}) : super();

  /// WebDriver's own error token (`no such element`, `stale element
  /// reference`, …), which is stable across implementations.
  final String? error;

  @override
  String toString() =>
      'WebDriverException${error == null ? '' : ' ($error)'}: $message';
}

/// Drives one WebKit window over classic W3C WebDriver.
class WebDriverClient extends ScriptedBrowserEngineClient {
  WebDriverClient._({
    required HttpClient http,
    required this.host,
    required this.port,
    required String sessionId,
  }) : _http = http,
       _sessionId = sessionId;

  /// The driver's host.
  final String host;

  /// The driver's port.
  final int port;

  final HttpClient _http;
  final String _sessionId;

  final StreamController<BrowserPageEvent> _pageEvents =
      StreamController<BrowserPageEvent>.broadcast();

  Timer? _watch;
  bool _closed = false;
  String _lastUrl = '';

  /// The client's model of the session history.
  ///
  /// Classic WebDriver's `back` and `forward` are silent no-ops at the ends of
  /// the history — they neither move nor complain — so nothing in the
  /// protocol can answer "may I offer back?". The index is kept here and
  /// checked against the URL actually reached, which is the one observable
  /// that distinguishes "moved" from "did nothing".
  int _historyIndex = 0;
  int _historyLength = 1;

  /// How often the URL and the page's console buffer are read back.
  ///
  /// Two small local requests per tick. Slow on purpose: this is the cost of
  /// an engine with no events, it runs for the life of every WebKit rig, and
  /// a person clicking a link can wait a beat for the address bar. Anything
  /// faster would be paying continuously for a rare event.
  static const Duration _watchInterval = Duration(seconds: 4);

  /// The element-reference key every W3C WebDriver response uses.
  static const String _elementKey = 'element-6066-11e4-a52e-4f735466cecc';

  /// Installs the console hook. Re-run after every navigation, because a new
  /// document is a new `window`.
  static const String _consoleHookScript = '''
(() => {
  if (window.__ccConsole) return "{}";
  window.__ccConsole = [];
  for (const level of ['log', 'info', 'warn', 'error', 'debug']) {
    const original = console[level];
    console[level] = function () {
      try {
        const parts = [];
        for (const a of arguments) {
          parts.push(typeof a === 'string' ? a : JSON.stringify(a));
        }
        window.__ccConsole.push('[' + level + '] ' + parts.join(' '));
        if (window.__ccConsole.length > 500) window.__ccConsole.shift();
      } catch (e) { /* a console hook must never break the page */ }
      return original.apply(console, arguments);
    };
  }
  window.addEventListener('error', (e) => {
    try { window.__ccConsole.push('[error] ' + (e.message || String(e))); } catch (x) {}
  });
  return "{}";
})()
''';

  /// Takes the page's captured console lines and clears them.
  static const String _consoleDrainScript = '''
(() => {
  const out = window.__ccConsole || [];
  window.__ccConsole = [];
  return JSON.stringify({ lines: out });
})()
''';

  @override
  RigBrowserEngine get engine => RigBrowserEngine.webkit;

  @override
  Stream<BrowserPageEvent> get pageEvents => _pageEvents.stream;

  @override
  String? get consoleCaveat =>
      'WebKit has no console feed, so this is captured by hooking console.* '
      'in the page after each navigation — anything the page logged while it '
      'was still loading is not here.';

  /// Opens a WebDriver session against the driver at [host]:[port].
  ///
  /// [browserName] is `MiniBrowser`, which is what `WebKitWebDriver` matches
  /// its own browser against. Named explicitly rather than left blank: a
  /// blank `browserName` matches whatever the driver happens to default to,
  /// and a rig that silently launched a different browser than the tab
  /// promises is the one outcome this feature cannot have.
  static Future<WebDriverClient> attach({
    required String host,
    required int port,
    String browserName = 'MiniBrowser',
    Duration timeout = const Duration(seconds: 90),
  }) async {
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final result = await _request(
          http,
          host,
          port,
          'POST',
          '/session',
          body: {
            'capabilities': {
              'alwaysMatch': {'browserName': browserName},
            },
          },
          timeout: const Duration(seconds: 60),
        );
        final sessionId = result is Map ? result['sessionId'] : null;
        if (sessionId is! String || sessionId.isEmpty) {
          throw const WebDriverException(
            'The WebKit driver created a session with no id',
          );
        }
        final client = WebDriverClient._(
          http: http,
          host: host,
          port: port,
          sessionId: sessionId,
        );
        await client._afterNavigation();
        client._startWatch();
        return client;
      } on Object catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
    http.close(force: true);
    throw WebDriverException(
      'The WebKit driver did not open a session on $host:$port within '
      '${timeout.inSeconds}s. Last error: $lastError',
    );
  }

  // ── Transport ───────────────────────────────────────────────────────────

  static Future<Object?> _request(
    HttpClient http,
    String host,
    int port,
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    final request = await http
        .openUrl(method, Uri.parse('http://$host:$port$path'))
        .timeout(timeout);
    // A body goes on POSTs and NOWHERE else. Classic WebDriver requires one on
    // every POST, even a command that takes no arguments (`POST /back` with no
    // body is a 400 on some drivers) — but `dart:io` fixes `content-length` at
    // 0 for a GET, so writing `{}` there throws before the request is even
    // sent. That failure looked like a driver error and cost every read
    // command: url, screenshot, navigation state.
    if (method == 'POST' || method == 'PUT') {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body ?? const <String, dynamic>{}));
    }
    final response = await request.close().timeout(timeout);
    final text = await response.transform(utf8.decoder).join().timeout(timeout);
    final Object? decoded;
    try {
      decoded = text.isEmpty ? null : jsonDecode(text);
    } on FormatException {
      throw WebDriverException(
        'The WebKit driver answered $method $path with something that is not '
        'JSON (${response.statusCode})',
      );
    }
    final value = decoded is Map ? decoded['value'] : decoded;
    if (response.statusCode >= 400 ||
        (value is Map && value['error'] != null)) {
      final error = value is Map ? value['error'] as String? : null;
      final message = value is Map ? value['message'] : null;
      throw WebDriverException(
        '${message ?? 'the command failed'} (${response.statusCode})',
        error: error,
      );
    }
    return value;
  }

  Future<Object?> _call(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Duration timeout = const Duration(seconds: 45),
  }) {
    if (_closed) {
      return Future.error(
        const WebDriverException('The WebKit driver client is closed'),
      );
    }
    return _request(
      _http,
      host,
      port,
      method,
      '/session/$_sessionId$path',
      body: body,
      timeout: timeout,
    );
  }

  // ── The slow lane that stands in for events ─────────────────────────────

  void _startWatch() {
    _watch = Timer.periodic(_watchInterval, (_) => unawaited(_tick()));
  }

  Future<void> _tick() async {
    if (_closed) {
      return;
    }
    try {
      final url = await _call(
        'GET',
        '/url',
        timeout: const Duration(seconds: 8),
      );
      if (url is String && url.isNotEmpty && url != _lastUrl) {
        _lastUrl = url;
        // Reached without a command of ours — a link, a redirect, a script.
        // It is a new history entry as far as anything here can tell.
        _historyIndex += 1;
        _historyLength = _historyIndex + 1;
        _emit(BrowserPageUrlChanged(url));
      }
      final drained = await evaluateJson(_consoleDrainScript);
      if (drained is Map && drained['lines'] is List) {
        for (final line in drained['lines'] as List) {
          if (line is String && line.isNotEmpty) {
            recordConsole(line);
          }
        }
      }
    } on Object {
      // A tick is best effort. The browser may be mid-navigation, and a
      // failed poll must never surface as an error in a surface nobody asked
      // to poll.
    }
  }

  void _emit(BrowserPageEvent event) {
    if (!_pageEvents.isClosed) {
      _pageEvents.add(event);
    }
  }

  /// Re-installs the console hook and publishes where the page landed.
  Future<void> _afterNavigation() async {
    try {
      await evaluateJson(_consoleHookScript);
      final url = await _call('GET', '/url');
      if (url is String && url.isNotEmpty) {
        _lastUrl = url;
        _emit(BrowserPageUrlChanged(url));
      }
    } on Object {
      // Best effort: the URL is published again by the next tick.
    }
  }

  // ── The scripted primitives ─────────────────────────────────────────────

  @override
  Future<Object?> evaluateJson(String expression) async {
    try {
      // `execute/sync` takes a FUNCTION BODY, not an expression: the driver
      // wraps the script in a function and runs it, so the value has to be
      // returned explicitly. Every shared script is an expression, hence the
      // `return`.
      final value = await _call(
        'POST',
        '/execute/sync',
        body: {'script': 'return ($expression);', 'args': const <Object>[]},
      );
      return ScriptedBrowserEngineClient.decodeScriptResult(value);
    } on WebDriverException catch (e) {
      CcInfraLog.debug('rig/webdriver: execute failed: $e');
      return null;
    }
  }

  @override
  Future<void> performActions(List<Map<String, dynamic>> sources) async {
    await _call('POST', '/actions', body: {'actions': sources});
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  @override
  Future<bool> navigate(
    String url, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _emit(const BrowserPageLoadingChanged(loading: true));
    try {
      await _call('POST', '/url', body: {'url': url}, timeout: timeout);
      _historyIndex += 1;
      _historyLength = _historyIndex + 1;
      return true;
    } on Object {
      // Same reading as the other engines: a navigate that did not finish is
      // not a navigate that failed.
      return false;
    } finally {
      _emit(const BrowserPageLoadingChanged(loading: false));
      await _afterNavigation();
    }
  }

  @override
  Future<void> reload({bool ignoreCache = false}) async {
    // Classic WebDriver has no cache-bypassing reload. Said in the log rather
    // than silently doing a normal one, because "hard reload" that quietly
    // served the cache is a debugging session spent on the wrong hypothesis.
    if (ignoreCache) {
      CcInfraLog.debug(
        'rig/webdriver: WebKit has no cache-bypassing reload; reloading '
        'normally',
      );
    }
    await _call('POST', '/refresh');
    await _afterNavigation();
  }

  @override
  Future<void> stopLoading() async {
    await evaluateJson('(() => { window.stop(); return "{}"; })()');
    _emit(const BrowserPageLoadingChanged(loading: false));
  }

  @override
  Future<bool> goHistory(int delta) async {
    if (delta == 0) {
      return false;
    }
    // The model refuses first. `back` at the start of the history is a silent
    // no-op here — the driver returns success and nothing moves — so without
    // this the toolbar would report a move that never happened.
    if (delta < 0 && _historyIndex <= 0) {
      return false;
    }
    if (delta > 0 && _historyIndex >= _historyLength - 1) {
      return false;
    }
    final before = await _call('GET', '/url');
    final steps = delta.abs();
    for (var i = 0; i < steps; i++) {
      await _call('POST', delta < 0 ? '/back' : '/forward');
    }
    final after = await _call('GET', '/url');
    await _afterNavigation();
    if (before is String && after is String && before == after) {
      // Nothing moved. Two adjacent entries CAN share a URL, so this is not
      // proof — but the model already said the move was available, and
      // reporting a move that produced no change is worse than reporting
      // none.
      return false;
    }
    _historyIndex = (_historyIndex + delta).clamp(0, _historyLength - 1);
    return true;
  }

  @override
  Future<BrowserNavigationState> navigationState() async {
    final url = await _call('GET', '/url');
    return (
      url: url is String ? url : '',
      canGoBack: _historyIndex > 0,
      canGoForward: _historyIndex < _historyLength - 1,
    );
  }

  // ── Capture and viewport ────────────────────────────────────────────────

  @override
  Future<String> captureScreenshot({
    bool fullPage = false,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    // PNG, always — classic WebDriver has no format or quality parameter, so
    // `quality` is accepted and ignored rather than pretended. This is why
    // the WebKit watch lane is the one that needs a host transcode.
    //
    // `fullPage` has no endpoint either. Screenshotting the `<html>` element
    // is the closest thing the protocol offers and it is what other WebKit
    // drivers do, so a caller asking for a full page gets one when the
    // document resolves and the viewport otherwise.
    if (fullPage) {
      try {
        final element = await _findElement('html');
        if (element != null) {
          final data = await _call('GET', '/element/$element/screenshot');
          if (data is String && data.isNotEmpty) {
            return data;
          }
        }
      } on Object {
        // Fall through to the viewport capture below.
      }
    }
    final data = await _call('GET', '/screenshot');
    if (data is! String || data.isEmpty) {
      throw const WebDriverException('Screenshot returned no data');
    }
    return data;
  }

  /// [deviceScaleFactor] is ACCEPTED AND IGNORED, and that is the honest
  /// answer rather than an oversight: classic W3C WebDriver has no device-
  /// emulation surface at all, so there is no verb that would change how many
  /// device pixels this guest paints per CSS pixel. A WebKit rig's resolution
  /// is fixed by the X screen its Xvfb was booted with and the GTK scale of
  /// the browser inside it, both of which are decided when the machine
  /// starts — see `buildSmolvmWebkitWorkload`. Throwing here instead would
  /// break every resize on the surface to report something the caller cannot
  /// act on mid-session.
  @override
  Future<void> setViewport({
    required int width,
    required int height,
    bool mobile = false,
    double deviceScaleFactor = 1,
  }) async {
    // Two passes. The first sizes the WINDOW; the second corrects for the
    // chrome around the page, which is what the pointer coordinates in every
    // later action are relative to. Measured on WebKitGTK's MiniBrowser: an
    // 800 px window is a 762 px viewport, so a click aimed near the bottom of
    // an uncorrected page lands 38 px above where it was meant to.
    await _call(
      'POST',
      '/window/rect',
      body: {'width': width, 'height': height},
    );
    final measured = await evaluateJson(
      'JSON.stringify({ w: window.innerWidth, h: window.innerHeight })',
    );
    if (measured is! Map) {
      return;
    }
    final innerWidth = measured['w'];
    final innerHeight = measured['h'];
    if (innerWidth is! num || innerHeight is! num) {
      return;
    }
    final dw = width - innerWidth.round();
    final dh = height - innerHeight.round();
    if (dw == 0 && dh == 0) {
      return;
    }
    await _call(
      'POST',
      '/window/rect',
      body: {'width': width + dw, 'height': height + dh},
    );
  }

  // ── Files ───────────────────────────────────────────────────────────────

  @override
  Future<bool> setFileInputFiles({
    required String selector,
    required List<String> guestPaths,
  }) async {
    if (guestPaths.isEmpty) {
      return false;
    }
    try {
      final element = await _findElement(selector);
      if (element == null) {
        return false;
      }
      // The W3C way to fill a file input: send the paths as the element's
      // value, newline-separated for a multiple input.
      await _call(
        'POST',
        '/element/$element/value',
        body: {'text': guestPaths.join('\n')},
      );
      return true;
    } on WebDriverException catch (e) {
      CcInfraLog.debug('rig/webdriver: setting file input failed: $e');
      return false;
    }
  }

  Future<String?> _findElement(String selector) async {
    try {
      final value = await _call(
        'POST',
        '/element',
        body: {'using': 'css selector', 'value': selector},
      );
      if (value is Map && value[_elementKey] is String) {
        return value[_elementKey] as String;
      }
    } on WebDriverException {
      // `no such element` is a normal answer, not a failure.
    }
    return null;
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _watch?.cancel();
    _watch = null;
    try {
      await _request(
        _http,
        host,
        port,
        'DELETE',
        '/session/$_sessionId',
        timeout: const Duration(seconds: 10),
      );
    } on Object {
      // The driver may already be gone. Closing the HTTP client below is what
      // actually releases anything of ours.
    }
    _http.close(force: true);
    if (!_pageEvents.isClosed) {
      await _pageEvents.close();
    }
  }
}
