// Drives an enclosed Firefox over WebDriver BiDi.
//
// Not "CDP with a different browser": Firefox's remote agent answers BiDi and
// NOTHING else — a current build 404s `/json/version`, so there is no CDP
// endpoint to fall back to. BiDi is a different shape as well as a different
// vocabulary: one WebSocket carrying `{id, method, params}` commands and
// `{type: event}` notifications, addressed to a BROWSING CONTEXT rather than
// to a target session.
//
// Three things about this transport are load-bearing and were each measured
// against a real rig rather than read off a spec:
//
//  * **The `Host` header must name the port Firefox itself listens on.** The
//    remote agent binds guest loopback unconditionally, so the host reaches it
//    through the guest's socat relay on a DIFFERENT port, and Firefox rejects
//    the upgrade with a bare `400` when the header's port is not its own.
//    `--remote-allow-hosts` does NOT fix this (its entries are host names; the
//    port check is separate and unconditional), so the client sends the
//    guest-side authority explicitly. Without it every Firefox rig fails to
//    attach with no diagnostic beyond "400".
//  * **BiDi has no screencast.** The live view polls stills. Firefox can
//    encode them as JPEG (`format: {type: 'image/jpeg'}`), which is why this
//    engine needs no host-side transcode — the frames are already what the
//    MJPEG lane carries.
//  * **BiDi has no "can I go back?"**. `browsingContext.traverseHistory` moves
//    and errors when there is no entry; nothing reports reachability. So the
//    client keeps its own index, corrected by what the engine actually does.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';

/// A BiDi command came back as an error.
class BidiException extends BrowserEngineException {
  /// Creates a [BidiException].
  const BidiException(super.message, {this.error}) : super();

  /// BiDi's own error token (`no such history entry`, `no such element`, …),
  /// which is stable across versions and is what callers branch on.
  final String? error;

  @override
  String toString() =>
      'BidiException${error == null ? '' : ' ($error)'}: $message';
}

/// Drives one Firefox browsing context over WebDriver BiDi.
class BidiClient extends ScriptedBrowserEngineClient {
  BidiClient._(this._socket, {required this.hostAuthority});

  /// The authority (`127.0.0.1:9223`) the remote agent believes it serves.
  ///
  /// Kept for diagnostics: it is the single most common reason an attach
  /// fails, and an error that names it saves the next person the hour this
  /// cost the first time.
  final String hostAuthority;

  final WebSocket _socket;

  StreamSubscription<dynamic>? _sub;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final StreamController<BrowserPageEvent> _pageEvents =
      StreamController<BrowserPageEvent>.broadcast();

  int _nextId = 1;
  String? _sessionId;
  String? _context;
  bool _closed = false;

  /// The client's model of the session history.
  ///
  /// BiDi reports neither the history length nor the current index, and the
  /// toolbar has to decide whether to offer back and forward BEFORE anyone
  /// presses them. So navigations push and traversals move an index here, and
  /// the engine stays authoritative at the moment of truth: [goHistory] asks
  /// it to move and believes the answer, correcting this model when the two
  /// disagree.
  int _historyIndex = 0;
  int _historyLength = 1;

  /// Whether a load is in flight, from the navigation events.
  bool _loading = false;

  /// The default per-command deadline. Generous: a BiDi command can be
  /// waiting on a page, not just on the agent.
  static const Duration _commandTimeout = Duration(seconds: 45);

  /// The BiDi events this client needs. Nothing else is subscribed: an
  /// unsubscribed event is never sent, and `network.*` on a busy page is a
  /// notification per request.
  static const List<String> _subscriptions = [
    'browsingContext.navigationStarted',
    'browsingContext.load',
    'browsingContext.fragmentNavigated',
    'log.entryAdded',
  ];

  @override
  RigBrowserEngine get engine => RigBrowserEngine.firefox;

  @override
  Stream<BrowserPageEvent> get pageEvents => _pageEvents.stream;

  /// The browsing context being driven, once the session exists.
  String? get contextId => _context;

  /// Connects to Firefox's remote agent at [host]:[port] and opens a session.
  ///
  /// [guestPort] is the port the agent listens on INSIDE the guest, which is
  /// not [port] when a relay sits between them. It becomes the `Host` header;
  /// see the library comment for why that is not optional.
  static Future<BidiClient> attach({
    required String host,
    required int port,
    required int guestPort,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final authority = '$host:$guestPort';
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        // Handed straight to the client, which closes it in `close()`.
        // ignore: close_sinks
        final socket = await WebSocket.connect(
          'ws://$host:$port/session',
          headers: {'Host': authority},
        ).timeout(const Duration(seconds: 15));
        final client = BidiClient._(socket, hostAuthority: authority);
        client._bind();
        await client._start();
        return client;
      } on BidiException catch (e) {
        // Firefox allows ONE BiDi session at a time and ties it to its
        // WebSocket, so this can only mean a previous client's socket is
        // still half-open — a server that restarted while the rig kept
        // running. Retrying cannot clear it, and the fix is to restart the
        // browser, so say that instead of spending the whole budget.
        if (e.error == 'session not created' &&
            e.message.contains('Maximum number of active sessions')) {
          throw BidiException(
            'Firefox already has a WebDriver BiDi session open and allows only '
            'one. Another client is still attached, or a previous one did not '
            'close cleanly. Close and reopen the rig to get a fresh browser.',
            error: e.error,
          );
        }
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      } on Object catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    throw BidiException(
      'Firefox did not accept a WebDriver BiDi session on $host:$port '
      '(Host: $authority) within ${timeout.inSeconds}s. Last error: '
      '$lastError',
    );
  }

  void _bind() {
    _sub = _socket.listen(
      _onFrame,
      onDone: _onDone,
      onError: (Object e) => _onDone(),
      cancelOnError: true,
    );
  }

  Future<void> _start() async {
    final session = await _send('session.new', {
      // An empty capability set on purpose. Everything this client needs is a
      // BiDi command, and a requested capability that Firefox cannot match
      // fails the whole session — a rig that refuses to open because of a
      // preference nobody reads is the worst possible trade.
      'capabilities': {'alwaysMatch': <String, dynamic>{}},
    });
    _sessionId = session['sessionId'] as String?;
    await _refreshContext();
    await _send('session.subscribe', {'events': _subscriptions});
  }

  /// Learns (or re-learns) which browsing context to drive.
  Future<void> _refreshContext() async {
    final tree = await _send('browsingContext.getTree', const {});
    final contexts = tree['contexts'];
    if (contexts is! List || contexts.isEmpty) {
      throw const BidiException(
        'Firefox reported no browsing context to drive',
      );
    }
    final first = contexts.first;
    if (first is! Map || first['context'] is! String) {
      throw const BidiException('Firefox reported a malformed context tree');
    }
    _context = first['context'] as String;
  }

  String get _ctx {
    final context = _context;
    if (context == null) {
      throw const BidiException('The BiDi session has no browsing context');
    }
    return context;
  }

  // ── Transport ───────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _send(
    String method,
    Map<String, dynamic> params, {
    Duration? timeout,
  }) {
    if (_closed) {
      return Future.error(const BidiException('The BiDi client is closed'));
    }
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _socket.add(jsonEncode({'id': id, 'method': method, 'params': params}));
    return completer.future.timeout(
      timeout ?? _commandTimeout,
      onTimeout: () {
        // The pending entry is dropped here, not left behind: a page that
        // never settles would otherwise pin one completer per attempt for the
        // life of the rig.
        _pending.remove(id);
        throw BidiException('$method timed out');
      },
    );
  }

  void _onFrame(dynamic raw) {
    if (raw is! String) {
      return;
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map) {
      return;
    }
    final message = decoded.cast<String, dynamic>();
    switch (message['type']) {
      case 'success':
        final completer = _pending.remove(message['id'] as int?);
        final result = message['result'];
        completer?.complete(
          result is Map ? result.cast<String, dynamic>() : <String, dynamic>{},
        );
      case 'error':
        final completer = _pending.remove(message['id'] as int?);
        completer?.completeError(
          BidiException(
            '${message['message'] ?? 'the command failed'}',
            error: message['error'] as String?,
          ),
        );
      case 'event':
        _onEvent(
          message['method'] as String? ?? '',
          message['params'] is Map
              ? (message['params'] as Map).cast<String, dynamic>()
              : const <String, dynamic>{},
        );
    }
  }

  void _onEvent(String method, Map<String, dynamic> params) {
    // Every browsing-context event names its context. A subframe's navigation
    // is not the address bar's business, and an ad iframe navigates
    // constantly — filtering here is what keeps the toolbar showing the page
    // a person is actually on.
    final isMainContext = params['context'] == _context;
    switch (method) {
      case 'browsingContext.navigationStarted':
        if (isMainContext) {
          _loading = true;
          _emit(const BrowserPageLoadingChanged(loading: true));
        }
      case 'browsingContext.load':
        if (isMainContext) {
          _loading = false;
          _emit(const BrowserPageLoadingChanged(loading: false));
          final url = params['url'];
          if (url is String) {
            _pushHistory();
            _emit(BrowserPageUrlChanged(url));
          }
        }
      case 'browsingContext.fragmentNavigated':
        if (isMainContext) {
          final url = params['url'];
          if (url is String) {
            _pushHistory();
            _emit(BrowserPageUrlChanged(url));
          }
        }
      case 'log.entryAdded':
        final text = params['text'];
        if (text is String && text.isNotEmpty) {
          recordConsole('[${params['level'] ?? 'log'}] $text');
        }
    }
  }

  void _emit(BrowserPageEvent event) {
    if (!_pageEvents.isClosed) {
      _pageEvents.add(event);
    }
  }

  /// Records a forward navigation in the history model.
  ///
  /// A new entry truncates whatever was ahead of it, exactly as a browser's
  /// own history does — navigating after going back is what makes "forward"
  /// stop being offered.
  void _pushHistory() {
    if (_traversing) {
      return;
    }
    _historyIndex += 1;
    _historyLength = _historyIndex + 1;
  }

  /// Set across a [goHistory] so the `load` event a traversal produces moves
  /// the index instead of pushing a new entry.
  bool _traversing = false;

  void _onDone() {
    if (_closed) {
      return;
    }
    _closed = true;
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const BidiException('The Firefox BiDi socket closed'),
        );
      }
    }
    _pending.clear();
    if (!_pageEvents.isClosed) {
      unawaited(_pageEvents.close());
    }
  }

  // ── The scripted primitives ─────────────────────────────────────────────

  @override
  Future<Object?> evaluateJson(String expression) async {
    try {
      final result = await _send('script.evaluate', {
        'expression': expression,
        'target': {'context': _ctx},
        // Every shared script is (or may be) an async IIFE — the clipboard
        // ones certainly are — and without this the result is a Promise
        // handle rather than the JSON the caller parses.
        'awaitPromise': true,
      });
      if (result['type'] == 'exception') {
        final detail = result['exceptionDetails'];
        CcInfraLog.debug(
          'rig/bidi: page script threw: '
          '${detail is Map ? detail['text'] : detail}',
        );
        return null;
      }
      final value = result['result'];
      if (value is! Map) {
        return null;
      }
      return ScriptedBrowserEngineClient.decodeScriptResult(value['value']);
    } on BidiException catch (e) {
      CcInfraLog.debug('rig/bidi: script.evaluate failed: $e');
      return null;
    }
  }

  @override
  Future<void> performActions(List<Map<String, dynamic>> sources) async {
    await _send('input.performActions', {'context': _ctx, 'actions': sources});
  }

  // ── Navigation ──────────────────────────────────────────────────────────

  @override
  Future<bool> navigate(
    String url, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    try {
      await _send('browsingContext.navigate', {
        'context': _ctx,
        'url': url,
        'wait': 'complete',
      }, timeout: timeout);
      return true;
    } on BidiException {
      // A navigate that did not finish is not a navigate that failed: the
      // page may still be fetching, and what has rendered is usable. The
      // caller says exactly that; throwing here would turn a slow page into
      // an error.
      return false;
    }
  }

  @override
  Future<void> reload({bool ignoreCache = false}) async {
    // `ignoreCache` is in the BiDi spec and Firefox rejects it outright
    // ("Argument \"ignoreCache\" is not supported yet"), which fails the whole
    // command — so a hard reload here is a normal reload, said out loud. It is
    // never sent conditionally either: a flag that works on some pages and
    // errors on others is worse than one that is honestly absent.
    if (ignoreCache) {
      CcInfraLog.debug(
        'rig/bidi: Firefox does not implement BiDi cache-bypassing reload; '
        'reloading normally',
      );
    }
    await _send('browsingContext.reload', {
      'context': _ctx,
      'wait': 'complete',
    });
  }

  @override
  Future<void> stopLoading() async {
    // BiDi has no stop command. `window.stop()` is the page-level equivalent
    // and is what the browser's own stop button ultimately calls.
    await evaluateJson('(() => { window.stop(); return "{}"; })()');
    _loading = false;
    _emit(const BrowserPageLoadingChanged(loading: false));
  }

  @override
  Future<bool> goHistory(int delta) async {
    if (delta == 0) {
      return false;
    }
    _traversing = true;
    try {
      await _send('browsingContext.traverseHistory', {
        'context': _ctx,
        'delta': delta,
      });
      _historyIndex = (_historyIndex + delta).clamp(0, _historyLength - 1);
      return true;
    } on BidiException catch (e) {
      // The engine is authoritative about where the history actually ends.
      // Its refusal also corrects the model, so a toolbar that offered a
      // button one step too far stops offering it.
      if (e.error == 'no such history entry') {
        if (delta < 0) {
          _historyIndex = 0;
        } else {
          _historyLength = _historyIndex + 1;
        }
        return false;
      }
      rethrow;
    } finally {
      // Held briefly past the command: the `load` the traversal causes
      // arrives just after, and it must move the index rather than push.
      Timer(const Duration(milliseconds: 750), () => _traversing = false);
    }
  }

  @override
  Future<BrowserNavigationState> navigationState() async {
    final tree = await _send('browsingContext.getTree', {'root': _ctx});
    final contexts = tree['contexts'];
    var url = '';
    if (contexts is List && contexts.isNotEmpty) {
      final first = contexts.first;
      if (first is Map && first['url'] is String) {
        url = first['url'] as String;
      }
    }
    return (
      url: url,
      canGoBack: _historyIndex > 0,
      canGoForward: _historyIndex < _historyLength - 1,
    );
  }

  /// Whether the page is mid-load, from the navigation events.
  bool get loading => _loading;

  // ── Capture and viewport ────────────────────────────────────────────────

  @override
  Future<String> captureScreenshot({
    bool fullPage = false,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final result = await _send('browsingContext.captureScreenshot', {
      'context': _ctx,
      'origin': fullPage ? 'document' : 'viewport',
      'format': {
        'type': 'image/jpeg',
        // BiDi takes quality as a 0..1 fraction, unlike CDP's 1..100.
        'quality': (quality.clamp(1, 100)) / 100,
      },
      // The agent ceiling, applied as a CLIP because BiDi cannot scale. The
      // width is left alone (the viewport is already at or under the ceiling)
      // and the height is cut, which is the same trade the CDP path makes:
      // scaling a 20 000 px page until its height fits would leave a
      // legible-to-nobody sliver.
      if (fullPage && maxWidth != null && maxHeight != null)
        'clip': {
          'type': 'box',
          'x': 0,
          'y': 0,
          'width': maxWidth,
          'height': maxHeight * 4,
        },
    });
    final data = result['data'];
    if (data is! String || data.isEmpty) {
      throw const BidiException('Screenshot returned no data');
    }
    return data;
  }

  @override
  Future<void> setViewport({
    required int width,
    required int height,
    bool mobile = false,
    double deviceScaleFactor = 1,
  }) async {
    // BiDi's own knob, and the one thing this surface CAN emulate: the
    // viewport stays in CSS pixels while Firefox paints `ratio` device pixels
    // per CSS pixel, so a screenshot poll returns real resolution instead of
    // something the viewer has to upscale. `mobile` still forces 2 — that is
    // the one part of device emulation BiDi expresses, and a touch device
    // with a 1x screen is not a device anyone has.
    final ratio = mobile ? 2.0 : deviceScaleFactor;
    await _send('browsingContext.setViewport', {
      'context': _ctx,
      'viewport': {'width': width, 'height': height},
      // The rest of `mobile` has no BiDi equivalent — there is no
      // device-emulation surface here at all. The size still applies, which
      // is what the coordinates in every later action depend on; pretending
      // the touch emulation happened would be the lie.
      if (ratio != 1) 'devicePixelRatio': ratio,
    });
  }

  // ── Files ───────────────────────────────────────────────────────────────

  @override
  Future<bool> setFileInputFiles({
    required String selector,
    required List<String> guestPaths,
  }) async {
    try {
      final handle = await _send('script.evaluate', {
        'expression': 'document.querySelector(${browserJsString(selector)})',
        'target': {'context': _ctx},
        'awaitPromise': false,
        // Without a root ownership the node comes back as a bare descriptor
        // with no `sharedId`, and `input.setFiles` has nothing to address.
        'resultOwnership': 'root',
      });
      final value = handle['result'];
      if (value is! Map || value['sharedId'] is! String) {
        return false;
      }
      await _send('input.setFiles', {
        'context': _ctx,
        'element': {'sharedId': value['sharedId']},
        'files': guestPaths,
      });
      return true;
    } on BidiException catch (e) {
      CcInfraLog.debug('rig/bidi: setFiles failed: $e');
      return false;
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      if (_sessionId != null) {
        await _send(
          'session.end',
          const {},
          timeout: const Duration(seconds: 5),
        );
      }
    } on Object {
      // The browser may already be gone; the socket close below is what
      // actually matters.
    }
    await _sub?.cancel();
    _sub = null;
    try {
      await _socket.close();
    } on Object {
      // Already gone.
    }
    _onDone();
  }
}

/// Decodes a base64 screenshot into frame bytes.
///
/// Shared with the polled watch lane, which needs the same decode per tick and
/// must not build an intermediate string per frame beyond this one.
Uint8List decodeBrowserStill(String base64Data) => base64Decode(base64Data);
