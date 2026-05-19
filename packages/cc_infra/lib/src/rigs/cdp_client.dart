// The event StreamController and the socket are closed in `close()` and
// `_onDone()`, which `close_sinks` cannot see across methods.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_browser_engine.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/rigs/browser_engine_client.dart';

/// A CDP command returned an error.
///
/// A [BrowserEngineException] so a caller that drives whichever browser the
/// rig happens to run catches ONE type: the driver's failure path is the same
/// sentence whether Chromium, Firefox or WebKit said no.
class CdpException extends BrowserEngineException {
  /// Creates a [CdpException].
  const CdpException(super.message, {super.code});

  @override
  String toString() =>
      'CdpException${code == null ? '' : ' ($code)'}: $message';
}

/// What a page said when asked for its clipboard.
///
/// An alias of the engine-neutral [BrowserClipboardSnapshot]: the answer is the
/// same shape whichever browser produced it, and two identical classes would
/// only mean a conversion at the driver boundary.
typedef CdpClipboard = BrowserClipboardSnapshot;

/// Host spellings that all name the loopback interface.
///
/// A DevTools endpoint polled at `127.0.0.1` legitimately reports its targets
/// as `ws://localhost:<port>/…`, so a byte comparison would refuse the normal
/// case. Every member here is still the same machine, which is the property
/// [requireDebuggerSocketUri] actually cares about.
const Set<String> _loopbackHostAliases = {
  'localhost',
  '127.0.0.1',
  '::1',
  '[::1]',
  '0:0:0:0:0:0:0:1',
};

bool _sameEndpointHost(String a, String b) {
  final x = a.toLowerCase();
  final y = b.toLowerCase();
  if (x == y) {
    return true;
  }
  return _loopbackHostAliases.contains(x) && _loopbackHostAliases.contains(y);
}

/// Parses a `webSocketDebuggerUrl` and refuses anything that is not a
/// WebSocket on the endpoint it was read from.
///
/// **Why this is not paranoia.** `/json/list` is fetched over loopback, but its
/// BODY is written by the browser inside the guest, and everything a guest
/// produces is untrusted data. Attaching to whatever address it names would let
/// a compromised guest point the host at `ws://attacker.example/…` — an
/// outbound connection the egress allowlist never sees, feeding attacker-chosen
/// frames straight into the screencast relay and the console/dialog buffers.
///
/// [host]/[port] are the endpoint being polled; omit them (the [CdpClient.connect]
/// case, where the caller supplied the URL) to check only the scheme.
Uri requireDebuggerSocketUri(
  String webSocketDebuggerUrl, {
  String? host,
  int? port,
}) {
  final uri = Uri.tryParse(webSocketDebuggerUrl);
  if (uri == null || (uri.scheme != 'ws' && uri.scheme != 'wss')) {
    throw CdpException(
      'Refusing a CDP debugger URL that is not a WebSocket: '
      '"$webSocketDebuggerUrl".',
    );
  }
  if (uri.host.isEmpty) {
    throw CdpException(
      'Refusing a CDP debugger URL with no host: "$webSocketDebuggerUrl".',
    );
  }
  if (uri.userInfo.isNotEmpty) {
    throw CdpException(
      'Refusing a CDP debugger URL carrying credentials: '
      '"$webSocketDebuggerUrl".',
    );
  }
  if (host == null || port == null) {
    return uri;
  }
  final uriPort = uri.hasPort ? uri.port : null;
  if (!_sameEndpointHost(uri.host, host) || uriPort != port) {
    throw CdpException(
      'Refusing a CDP debugger URL that points somewhere other than the '
      'endpoint it came from: "$webSocketDebuggerUrl" is not on $host:$port. '
      'A guest that reports a foreign attach address is compromised.',
    );
  }
  return uri;
}

/// The WebSocket seam, so tests can drive the client without a browser.
///
/// A real [WebSocket] satisfies this structurally; a fake in a test is a
/// handful of lines. Without the seam every CDP test would need Chromium
/// installed, which makes the protocol layer effectively untested.
abstract interface class CdpSocket {
  /// Frames arriving from the browser.
  Stream<dynamic> get stream;

  /// Sends one text frame.
  void add(String data);

  /// Closes the socket.
  Future<void> close();
}

/// A [CdpSocket] over a real [WebSocket].
class WebSocketCdpSocket implements CdpSocket {
  /// Wraps [_socket].
  WebSocketCdpSocket(this._socket);

  final WebSocket _socket;

  @override
  Stream<dynamic> get stream => _socket;

  @override
  void add(String data) => _socket.add(data);

  @override
  Future<void> close() => _socket.close();
}

/// Where a [CdpClient] is in its connection lifecycle.
///
/// The in-guest Chromium runs under `Restart=always`, so a dropped WebSocket is
/// very often a browser that is coming back rather than one that is gone —
/// treating every drop as terminal is what made a recoverable crash end the
/// session.
enum CdpConnectionState {
  /// The socket is up and commands are being answered.
  connected,

  /// The socket dropped (or a target switch is in flight) and a re-attach is in
  /// progress. Commands fail fast rather than queueing.
  reconnecting,

  /// Terminally closed — [CdpClient.close] was called, or the re-attach window
  /// was exhausted.
  closed,
}

/// One page target on the DevTools endpoint.
class CdpTarget {
  /// Creates a [CdpTarget].
  const CdpTarget({required this.id, required this.url, required this.title});

  /// The target id CDP addresses it by.
  final String id;

  /// Its current URL.
  final String url;

  /// Its document title.
  final String title;

  @override
  String toString() => 'CdpTarget($id, $url)';
}

/// A freshly opened CDP transport plus the target it belongs to.
class CdpAttachment {
  /// Creates a [CdpAttachment].
  const CdpAttachment(this.socket, {this.targetId});

  /// The transport to speak CDP over.
  final CdpSocket socket;

  /// The page target the socket is attached to, when the opener knows it.
  final String? targetId;
}

/// How a dropped CDP connection is re-established.
///
/// Optional on purpose: a socket handed in from outside ([CdpClient.over]) is
/// one this client cannot reopen, so those instances stay single-shot unless
/// the caller supplies a policy.
class CdpReconnectPolicy {
  /// Creates a policy that re-attaches through [attach].
  const CdpReconnectPolicy({
    required this.attach,
    this.backoff = defaultBackoff,
    this.window = const Duration(seconds: 60),
  });

  /// Opens a new transport, preferring the passed target id when the endpoint
  /// still has it. Returning a DIFFERENT target is allowed (that is what makes
  /// a reconnect after a page swap work) and reported back through
  /// [CdpAttachment.targetId], so an explicit switch can refuse it.
  final Future<CdpAttachment> Function(String? preferredTargetId) attach;

  /// The delay before each attempt; the last entry repeats.
  final List<Duration> backoff;

  /// How long re-attaching may go on before the client gives up for good.
  ///
  /// Longer than QMP's window: Chromium may be mid-restart, and a browser that
  /// takes 20s to come back is a browser worth waiting for.
  final Duration window;

  /// 250ms → 5s.
  static const List<Duration> defaultBackoff = [
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 5),
  ];
}

/// A JavaScript dialog the page opened, recorded as it was handled.
///
/// An unhandled `confirm()` blocks the renderer: the page stops answering, the
/// screencast freezes and every later action times out with nothing anywhere
/// saying why. Auto-dismissing unblocks it; recording it is what lets a driver
/// say "a confirm() appeared and was dismissed" instead of leaving the agent to
/// wonder what happened to its click.
class CdpDialogRecord {
  /// Creates a [CdpDialogRecord].
  const CdpDialogRecord({
    required this.type,
    required this.message,
    required this.url,
    required this.at,
    required this.accepted,
  });

  /// `alert`, `confirm`, `prompt` or `beforeunload`.
  final String type;

  /// The text the page passed to it.
  final String message;

  /// The page that opened it.
  final String url;

  /// When it was handled.
  final DateTime at;

  /// Whether it was accepted (OK) rather than dismissed (Cancel).
  final bool accepted;

  @override
  String toString() =>
      '$type${message.isEmpty ? '' : ' "$message"'} '
      '(${accepted ? 'accepted' : 'dismissed'})';
}

/// A minimal Chrome DevTools Protocol client.
///
/// Only what the browser surface needs: navigation, input, DOM/accessibility
/// snapshots, screenshots, screencast and console. Deliberately not a general
/// CDP binding — every method here is one an agent verb maps onto, so the
/// surface stays reviewable.
///
/// Notably absent: `Runtime.evaluate` with caller-supplied JavaScript. The
/// guest is enclosed, so arbitrary JS is not a containment problem, but it IS
/// an accountability one: an action log full of opaque script bodies cannot be
/// reviewed, and every verb here exists so the log says what happened.
class CdpClient implements BrowserEngineClient {
  CdpClient._(
    this._socket, {
    CdpReconnectPolicy? reconnect,
    String? targetId,
    this.autoDismissDialogs = true,
    this.requestTimeout = const Duration(seconds: 30),
  }) : _reconnect = reconnect,
       _currentTargetId = targetId {
    _bind();
  }

  /// Builds a client over an already-open [socket] (tests, or a socket the
  /// caller opened with its own options).
  ///
  /// Single-shot unless [reconnect] is supplied — a socket this client did not
  /// open is one it cannot reopen.
  CdpClient.over(
    CdpSocket socket, {
    CdpReconnectPolicy? reconnect,
    String? targetId,
    bool autoDismissDialogs = true,
    Duration requestTimeout = const Duration(seconds: 30),
  }) : this._(
         socket,
         reconnect: reconnect,
         targetId: targetId,
         autoDismissDialogs: autoDismissDialogs,
         requestTimeout: requestTimeout,
       );

  /// Connects to the page target at [webSocketDebuggerUrl].
  ///
  /// The DevTools endpoint is derived from the URL, so this client can re-poll
  /// `/json/list` and re-attach when the socket drops (pass `reconnect: false`
  /// for the old single-shot behaviour).
  static Future<CdpClient> connect(
    String webSocketDebuggerUrl, {
    Duration timeout = const Duration(seconds: 15),
    bool reconnect = true,
    bool autoDismissDialogs = true,
    Duration requestTimeout = const Duration(seconds: 30),
    List<Duration>? backoff,
    Duration reconnectWindow = const Duration(seconds: 60),
  }) async {
    // `ws://127.0.0.1:9222/devtools/page/<targetId>` — the id is the last
    // segment, and the host/port half is the same endpoint `/json/list` lives
    // on. Both are needed to find this page again after a drop. Parsed and
    // checked BEFORE the dial: a non-`ws` scheme here would have `WebSocket`
    // resolve something else entirely.
    final uri = requireDebuggerSocketUri(webSocketDebuggerUrl);
    final socket = await WebSocket.connect(uri.toString()).timeout(timeout);
    final targetId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
    return CdpClient._(
      WebSocketCdpSocket(socket),
      targetId: targetId,
      autoDismissDialogs: autoDismissDialogs,
      requestTimeout: requestTimeout,
      reconnect: reconnect
          ? CdpReconnectPolicy(
              attach: _endpointAttach(
                host: uri.host,
                port: uri.hasPort ? uri.port : 9222,
                timeout: timeout,
              ),
              backoff: backoff ?? CdpReconnectPolicy.defaultBackoff,
              window: reconnectWindow,
            )
          : null,
    );
  }

  /// Discovers the first page target on a DevTools endpoint and connects.
  ///
  /// Chromium exposes `/json/list` over plain HTTP on its debugging port; the
  /// page target's `webSocketDebuggerUrl` is what CDP actually speaks.
  static Future<CdpClient> attachToFirstPage({
    required String host,
    required int port,
    Duration timeout = const Duration(seconds: 20),
    bool reconnect = true,
    bool autoDismissDialogs = true,
    Duration requestTimeout = const Duration(seconds: 30),
    List<Duration>? backoff,
    Duration reconnectWindow = const Duration(seconds: 60),
  }) async {
    final attach = _endpointAttach(host: host, port: port, timeout: timeout);
    final attachment = await attach(null);
    return CdpClient._(
      attachment.socket,
      targetId: attachment.targetId,
      autoDismissDialogs: autoDismissDialogs,
      requestTimeout: requestTimeout,
      reconnect: reconnect
          ? CdpReconnectPolicy(
              attach: attach,
              backoff: backoff ?? CdpReconnectPolicy.defaultBackoff,
              window: reconnectWindow,
            )
          : null,
    );
  }

  /// Builds the attach function for a DevTools endpoint: poll `/json/list`,
  /// prefer the asked-for target, open a socket to whatever page is there.
  ///
  /// One function for the first attach, a reconnect and a target switch — they
  /// differ only in which target they prefer, and three copies of this loop
  /// would drift.
  static Future<CdpAttachment> Function(String?) _endpointAttach({
    required String host,
    required int port,
    required Duration timeout,
  }) => (String? preferredTargetId) async {
    final deadline = DateTime.now().add(timeout);
    Object? lastError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final targets = await _listPageTargets(host, port);
        if (targets.isNotEmpty) {
          final chosen = targets.firstWhere(
            (t) => t.id == preferredTargetId,
            orElse: () => targets.first,
          );
          // `webSocketDebuggerUrl` is GUEST-SUPPLIED data. The listing is read
          // over loopback, but its contents are whatever the browser in the VM
          // chose to write: a compromised guest that answers
          // `ws://attacker.example/…` would have the HOST dial out to it and
          // then parse attacker-chosen "CDP frames" into the screencast relay,
          // the dialog buffer and the console buffer. Everything extracted
          // from a guest is untrusted, and that includes the address it hands
          // back to attach to.
          final uri = requireDebuggerSocketUri(
            chosen.webSocketDebuggerUrl,
            host: host,
            port: port,
          );
          final socket = await WebSocket.connect(
            uri.toString(),
          ).timeout(timeout);
          return CdpAttachment(WebSocketCdpSocket(socket), targetId: chosen.id);
        }
      } on CdpException {
        // A refused attach address is a VERDICT, not a transient miss:
        // retrying it for the rest of the deadline would bury the one signal
        // that says this guest is lying about where its debugger lives.
        rethrow;
      } on Object catch (e) {
        lastError = e;
      }
      // Chromium's debugging port accepts connections a moment before it has a
      // page target, so a miss here is normal during boot rather than fatal.
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw CdpException(
      'No CDP page target on $host:$port after ${timeout.inSeconds}s'
      '${lastError == null ? '' : ' (last error: $lastError)'}',
    );
  };

  static Future<List<_DevToolsTarget>> _listPageTargets(
    String host,
    int port,
  ) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(
        Uri.parse('http://$host:$port/json/list'),
      );
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(body);
      if (decoded is! List) {
        return const [];
      }
      return [
        for (final t in decoded)
          if (t is Map &&
              t['type'] == 'page' &&
              t['webSocketDebuggerUrl'] is String)
            _DevToolsTarget(
              id: '${t['id'] ?? ''}',
              url: '${t['url'] ?? ''}',
              title: '${t['title'] ?? ''}',
              webSocketDebuggerUrl: t['webSocketDebuggerUrl'] as String,
            ),
      ];
    } finally {
      client.close(force: true);
    }
  }

  CdpSocket _socket;
  CdpReconnectPolicy? _reconnect;
  StreamSubscription<dynamic>? _sub;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final StreamController<CdpEvent> _events =
      StreamController<CdpEvent>.broadcast();

  final StreamController<CdpScreencastFrame> _screencastFrames =
      StreamController<CdpScreencastFrame>.broadcast();
  final StreamController<CdpConnectionState> _states =
      StreamController<CdpConnectionState>.broadcast();
  final List<String> _consoleBuffer = [];
  final List<CdpDialogRecord> _dialogBuffer = [];
  final Map<String, CdpTarget> _targets = <String, CdpTarget>{};
  CdpConnectionState _state = CdpConnectionState.connected;
  String? _currentTargetId;
  int _nextId = 0;

  /// Bumped on every socket swap so a dead socket's late `onDone`/`onError`
  /// cannot tear down the connection that replaced it.
  int _generation = 0;

  // Session state, re-applied after a re-attach. A reconnected client that
  // silently lost its viewport override or its screencast is worse than one
  // that stayed down: the human's watch lane goes black and nothing reports a
  // failure.
  bool _domainsEnabled = false;
  _CdpViewport? _viewport;
  _CdpScreencast? _screencast;

  /// Whether a `javascript dialog opening` is answered automatically.
  final bool autoDismissDialogs;

  /// The default deadline for a command with no explicit timeout.
  final Duration requestTimeout;

  /// Protocol events (`Page.screencastFrame`, `Runtime.consoleAPICalled`, …).
  ///
  /// Survives a re-attach: a viewer holding this stream sees a gap in frames,
  /// not an end-of-stream, which is what keeps a watch lane open across a
  /// browser restart.
  Stream<CdpEvent> get events => _events.stream;

  @override
  RigBrowserEngine get engine => RigBrowserEngine.chromium;

  /// Chromium feeds the console from `Runtime.consoleAPICalled` and
  /// `Log.entryAdded`, which are live from the moment the domains are
  /// enabled — nothing is missed, so there is nothing to warn about.
  @override
  String? get consoleCaveat => null;

  /// Chromium is the one engine that PUSHES frames. The other two are polled
  /// by the driver, which is a real cost difference and not a detail: a
  /// screencast is silent while the page is static.
  @override
  bool get supportsScreencast => true;

  StreamController<BrowserPageEvent>? _pageEventsController;

  /// Cancelled in [close], not on the last listener leaving: the reduction
  /// carries the main frame's id, and rebuilding it after a viewer detached
  /// would lose that until the next full navigation.
  // ignore: cancel_subscriptions
  StreamSubscription<CdpEvent>? _pageEventsSub;

  /// The navigation lifecycle, reduced to the two facts the chrome needs.
  ///
  /// The reduction lives HERE rather than in the driver because it is
  /// CDP-specific: `Page.frameNavigated` carries a frame tree, and telling the
  /// main frame from a subframe (an ad iframe navigates constantly) is
  /// knowledge about this protocol, not about browsers.
  @override
  Stream<BrowserPageEvent> get pageEvents {
    final existing = _pageEventsController;
    if (existing != null) {
      return existing.stream;
    }
    final controller = StreamController<BrowserPageEvent>.broadcast();
    _pageEventsController = controller;
    String? mainFrameId;
    void emit(BrowserPageEvent event) {
      if (!controller.isClosed) {
        controller.add(event);
      }
    }

    _pageEventsSub = events.listen((event) {
      switch (event.method) {
        case 'Page.frameNavigated':
          final frame = event.params['frame'];
          if (frame is Map && frame['parentId'] == null) {
            mainFrameId = frame['id'] as String?;
            // A committed navigation IS a load starting; the matching
            // frameStartedLoading may already have fired before this frame's
            // id was known (the first navigation after attach), so commit is
            // the catch-all and frameStoppedLoading the release.
            emit(const BrowserPageLoadingChanged(loading: true));
            final url = frame['url'];
            if (url is String) {
              emit(BrowserPageUrlChanged(url));
            }
          }
        case 'Page.navigatedWithinDocument':
          // pushState/hash navigations fire per frame; only the main frame's
          // is the address bar's business.
          if (mainFrameId != null && event.params['frameId'] == mainFrameId) {
            final url = event.params['url'];
            if (url is String) {
              emit(BrowserPageUrlChanged(url));
            }
          }
        case 'Page.frameStartedLoading':
          if (event.params['frameId'] == mainFrameId) {
            emit(const BrowserPageLoadingChanged(loading: true));
          }
        case 'Page.frameStoppedLoading':
          if (event.params['frameId'] == mainFrameId) {
            emit(const BrowserPageLoadingChanged(loading: false));
          }
      }
    });
    return controller.stream;
  }

  /// Screencast frames, already base64-decoded, on their own lane.
  ///
  /// Kept off [events] on purpose. A frame is 50–500 KB of base64 arriving at
  /// 10–30 fps; routing it through the generic event path meant a full
  /// `jsonDecode` of the whole frame (materializing the base64 string AND the
  /// metadata map) on the server's main isolate for every one of them. This
  /// lane extracts the two fields it needs lexically and decodes the base64
  /// straight out of the socket frame, so nothing intermediate is allocated.
  @override
  Stream<CdpScreencastFrame> get screencastFrames => _screencastFrames.stream;

  /// Whether commands can be sent right now (false while re-attaching).
  bool get isConnected => _state == CdpConnectionState.connected;

  /// The current connection state.
  CdpConnectionState get connectionState => _state;

  /// Connection-state transitions, starting with the CURRENT state.
  Stream<CdpConnectionState> get connectionStates async* {
    yield _state;
    yield* _states.stream;
  }

  /// The page target this client is driving, when known.
  String? get currentTargetId => _currentTargetId;

  /// Every live page target the browser has reported, oldest first.
  ///
  /// Populated from `Target.targetCreated`/`targetDestroyed`, which
  /// [enableDomains] subscribes to — a popup or a `target=_blank` link is
  /// otherwise completely invisible to this client.
  List<CdpTarget> get pageTargets => List.unmodifiable(_targets.values);

  /// JavaScript dialogs handled since the client attached (newest last).
  ///
  /// Non-destructive, unlike [drainConsole]: a driver may want to mention the
  /// same dialog in more than one result.
  List<CdpDialogRecord> get dialogs => List.unmodifiable(_dialogBuffer);

  /// Takes the recorded dialogs and clears the buffer.
  List<CdpDialogRecord> drainDialogs() {
    final out = List<CdpDialogRecord>.from(_dialogBuffer);
    _dialogBuffer.clear();
    return out;
  }

  /// Console messages buffered since the last [drainConsole].
  ///
  /// Buffered rather than streamed to the agent: a page that logs in a loop
  /// would otherwise be able to spend the whole context window, and console
  /// output is something an agent asks for, not something it should be
  /// interrupted by.
  @override
  List<String> drainConsole() {
    final out = List<String>.from(_consoleBuffer);
    _consoleBuffer.clear();
    return out;
  }

  /// Sends [method] with [params] and returns its result.
  ///
  /// [timeout] defaults to [requestTimeout].
  Future<Map<String, dynamic>> send(
    String method, {
    Map<String, dynamic>? params,
    Duration? timeout,
  }) => _send(method, params: params, timeout: timeout);

  Future<Map<String, dynamic>> _send(
    String method, {
    Map<String, dynamic>? params,
    Duration? timeout,
    bool duringHandshake = false,
  }) {
    if (_state == CdpConnectionState.closed) {
      return Future.error(CdpException('CDP socket closed (method: $method)'));
    }
    if (_state == CdpConnectionState.reconnecting && !duringHandshake) {
      return Future.error(
        CdpException(
          'CDP connection dropped; a re-attach is in progress '
          '(method: $method)',
        ),
      );
    }
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    try {
      _socket.add(
        jsonEncode({
          'id': id,
          'method': method,
          if (params != null && params.isNotEmpty) 'params': params,
        }),
      );
    } on Object catch (e) {
      _pending.remove(id);
      return Future.error(CdpException('CDP write failed: $e'));
    }
    return completer.future.timeout(
      timeout ?? requestTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw CdpException('CDP method "$method" timed out');
      },
    );
  }

  /// Enables the domains the browser surface relies on. Idempotent.
  ///
  /// Remembered, so a re-attach re-enables them: CDP domains are per
  /// connection, and a reconnected client that skipped this receives no load
  /// events, no console and no screencast frames while looking perfectly fine.
  Future<void> enableDomains() async {
    _domainsEnabled = true;
    await _enableDomains();
  }

  Future<void> _enableDomains({bool duringHandshake = false}) async {
    for (final domain in const [
      'Page.enable',
      'Runtime.enable',
      'DOM.enable',
      'Log.enable',
    ]) {
      await _send(domain, duringHandshake: duringHandshake);
    }
    // Target discovery is what makes a popup or a `target=_blank` link exist
    // for this client at all. Best effort: an endpoint that refuses it still
    // drives the page it is attached to, and losing tab tracking must not
    // fail the attach.
    try {
      await _send(
        'Target.setDiscoverTargets',
        params: {'discover': true},
        duringHandshake: duringHandshake,
      );
    } on Object catch (e) {
      CcInfraLog.debug('rig/cdp: target discovery unavailable: $e');
    }
  }

  /// Navigates to [url] and waits for the load event (or [timeout]).
  ///
  /// A navigation that never fires `Page.loadEventFired` is not treated as a
  /// failure: plenty of real pages keep a request open forever, and the agent
  /// can still read and act on what rendered. The timeout is reported in the
  /// result text so a slow page is visible rather than silently "fine".
  @override
  Future<bool> navigate(
    String url, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final loaded = Completer<void>();
    final sub = events.listen((e) {
      if (e.method == 'Page.loadEventFired' && !loaded.isCompleted) {
        loaded.complete();
      }
    });
    try {
      final result = await send('Page.navigate', params: {'url': url});
      final errorText = result['errorText'];
      if (errorText is String && errorText.isNotEmpty) {
        throw CdpException('Navigation failed: $errorText');
      }
      await loaded.future.timeout(
        timeout,
        onTimeout: () => throw TimeoutException('load'),
      );
      return true;
    } on TimeoutException {
      return false;
    } finally {
      await sub.cancel();
    }
  }

  /// Captures the viewport (or the whole page) as base64 JPEG.
  @override
  Future<String> captureScreenshot({
    bool fullPage = false,
    int quality = 80,
    int? maxWidth,
    int? maxHeight,
  }) async {
    final clip = (maxWidth == null || maxHeight == null)
        ? null
        : await _agentClip(
            fullPage: fullPage,
            maxWidth: maxWidth,
            maxHeight: maxHeight,
          );
    final result = await send(
      'Page.captureScreenshot',
      params: {
        'format': 'jpeg',
        'quality': quality.clamp(1, 100),
        if (fullPage) 'captureBeyondViewport': true,
        'clip': ?clip,
      },
    );
    final data = result['data'];
    if (data is! String || data.isEmpty) {
      throw const CdpException('Screenshot returned no data');
    }
    return data;
  }

  /// How much taller than the ceiling an explicit full-page capture may be.
  ///
  /// Scaling a 20 000 px page down until its HEIGHT also fits 800 px would
  /// leave a 32 px-wide sliver — technically within budget, useless as a
  /// picture. So the width is what fits, and the height is clipped instead:
  /// the model gets the top of the page at a readable scale, and is told the
  /// rest was cut.
  static const int _fullPageHeightMultiple = 4;

  /// The `clip` that keeps a capture inside the model's image budget.
  ///
  /// **Why the browser lane needed this at all.** The computer and mobile
  /// lanes downscale in the guest before the bytes ever leave it; this lane
  /// shipped whatever Chromium encoded, and the viewport is only clamped to
  /// the 2560×1600 NEGOTIATION ceiling — four times the agent ceiling's
  /// pixels. With `fullPage: true` there was no bound at all: an infinite-
  /// scroll page is an arbitrarily large image riding into the provider
  /// request. `capToolImages` caps the COUNT of images, never their size.
  Future<Map<String, dynamic>?> _agentClip({
    required bool fullPage,
    required int maxWidth,
    required int maxHeight,
  }) async {
    final metrics = await _layoutMetrics();
    if (metrics == null) {
      return null;
    }
    final (width, contentHeight) = metrics;
    if (width <= 0 || contentHeight <= 0) {
      return null;
    }
    final height = fullPage
        ? (contentHeight < maxHeight * _fullPageHeightMultiple
              ? contentHeight
              : (maxHeight * _fullPageHeightMultiple).toDouble())
        : contentHeight;
    // Fit the WIDTH; on a non-full-page capture the height fits with it,
    // because the viewport is at most the negotiation ceiling's aspect.
    var scale = maxWidth / width;
    if (!fullPage && height * scale > maxHeight) {
      scale = maxHeight / height;
    }
    if (scale >= 1) {
      // Already inside the budget — no clip, so Chromium takes its normal
      // (cheaper) path and nothing is resampled for no reason.
      return null;
    }
    return {'x': 0, 'y': 0, 'width': width, 'height': height, 'scale': scale};
  }

  /// `(cssWidth, cssHeight)` of the page's content, or null when Chromium did
  /// not answer with usable metrics.
  Future<(double, double)?> _layoutMetrics() async {
    try {
      final result = await send('Page.getLayoutMetrics');
      final content = result['cssContentSize'] ?? result['contentSize'];
      if (content is Map) {
        final w = content['width'];
        final h = content['height'];
        if (w is num && h is num) {
          return (w.toDouble(), h.toDouble());
        }
      }
    } on Object catch (e) {
      // An unbudgeted screenshot beats no screenshot: without metrics there
      // is nothing to compute a scale from, and the capture still works.
      CcInfraLog.warning('rig/cdp: could not read layout metrics: $e');
    }
    return null;
  }

  /// Sets the emulated viewport.
  ///
  /// Remembered and re-applied after a re-attach: the agent's coordinates are
  /// viewport-relative, so a browser that came back at its default size makes
  /// every remembered click land somewhere else.
  @override
  Future<void> setViewport({
    required int width,
    required int height,
    bool mobile = false,
    double deviceScaleFactor = 1,
  }) async {
    final viewport = _CdpViewport(
      width: width,
      height: height,
      mobile: mobile,
      scale: deviceScaleFactor,
    );
    _viewport = viewport;
    await _applyViewport(viewport);
  }

  Future<void> _applyViewport(
    _CdpViewport viewport, {
    bool duringHandshake = false,
  }) async {
    await _send(
      'Emulation.setDeviceMetricsOverride',
      params: {
        'width': viewport.width,
        'height': viewport.height,
        // The compositor renders at width*scale x height*scale while layout
        // stays at width x height CSS pixels, so the screencast carries real
        // device pixels instead of the viewer upscaling a 1x render. Input
        // stays in CSS pixels, so no click coordinate moves.
        'deviceScaleFactor': viewport.scale,
        'mobile': viewport.mobile,
      },
      duringHandshake: duringHandshake,
    );
    await _send(
      'Emulation.setTouchEmulationEnabled',
      params: {'enabled': viewport.mobile},
      duringHandshake: duringHandshake,
    );
  }

  /// Starts the screencast — the human watch lane for this surface.
  ///
  /// Chromium encodes and throttles the frames itself, so nothing on the host
  /// decodes video: frames arrive as `Page.screencastFrame` events carrying
  /// base64 JPEG, get acked, and are relayed onward as bytes.
  /// The request is remembered until [stopScreencast], so a re-attach re-arms
  /// it: the viewers hold a stream fed from [events], and re-attaching without
  /// restarting the cast would leave them subscribed to a lane that never
  /// produces another frame.
  @override
  Future<void> startScreencast({
    required int maxWidth,
    required int maxHeight,
    int quality = 70,
    int everyNthFrame = 1,
  }) async {
    final cast = _CdpScreencast(
      maxWidth: maxWidth,
      maxHeight: maxHeight,
      quality: quality.clamp(1, 100),
      everyNthFrame: everyNthFrame < 1 ? 1 : everyNthFrame,
    );
    _screencast = cast;
    await _applyScreencast(cast);
  }

  Future<void> _applyScreencast(
    _CdpScreencast cast, {
    bool duringHandshake = false,
  }) async {
    await _send(
      'Page.startScreencast',
      params: {
        'format': 'jpeg',
        'quality': cast.quality,
        'maxWidth': cast.maxWidth,
        'maxHeight': cast.maxHeight,
        'everyNthFrame': cast.everyNthFrame,
      },
      duringHandshake: duringHandshake,
    );
  }

  /// Acknowledges a screencast frame. Chromium stops sending frames until the
  /// previous one is acked, which is what bounds the in-flight backlog.
  ///
  /// Never throws. Acks are fired and forgotten by the relay, so an ack that
  /// failed because the socket is mid-re-attach would otherwise surface as an
  /// unhandled zone error per dropped frame — a log flood on the exact path
  /// that is already having a bad time. A lost ack costs one frame.
  @override
  Future<void> ackScreencastFrame(int sessionId) async {
    try {
      await send('Page.screencastFrameAck', params: {'sessionId': sessionId});
    } on Object catch (e) {
      CcInfraLog.debug('rig/cdp: screencast ack dropped: $e');
    }
  }

  /// Stops the screencast, and stops re-arming it after a re-attach.
  @override
  Future<void> stopScreencast() async {
    _screencast = null;
    await send('Page.stopScreencast');
  }

  /// Reloads the current page. [ignoreCache] bypasses the HTTP cache.
  @override
  Future<void> reload({bool ignoreCache = false}) =>
      send('Page.reload', params: {'ignoreCache': ignoreCache}).then((_) {});

  /// Aborts the in-flight page load — the browser's stop button.
  @override
  Future<void> stopLoading() => send('Page.stopLoading').then((_) {});

  /// The CDP `buttons` bitmask for [button] (left=1, right=2, middle=4).
  static int _buttonMask(String button) => switch (button) {
    'right' => 2,
    'middle' => 4,
    _ => 1,
  };

  /// The CDP modifier bitmask for named modifiers (Alt=1, Ctrl=2, Meta=4,
  /// Shift=8). Unknown names are skipped — the action parser already refused
  /// them loudly, so by the time a list reaches here it is known-good.
  static int modifierMask(List<String> modifiers) {
    var mask = 0;
    for (final m in modifiers) {
      mask |= switch (m) {
        'alt' => 1,
        'ctrl' => 2,
        'meta' => 4,
        'shift' => 8,
        _ => 0,
      };
    }
    return mask;
  }

  /// Moves the pointer without pressing anything — hover.
  ///
  /// [dragging] keeps the primary button's bit set on the event: while a drag
  /// is in flight Chromium extends the selection under a moving pointer ONLY
  /// when the move reports the button still held.
  @override
  Future<void> moveMouse(int x, int y, {bool dragging = false}) => send(
    'Input.dispatchMouseEvent',
    params: {
      'type': 'mouseMoved',
      'x': x,
      'y': y,
      'button': 'none',
      'buttons': dragging ? 1 : 0,
    },
  ).then((_) {});

  /// Presses [button] at viewport coordinates.
  ///
  /// [clickCount] is how Chromium derives double/triple clicks: a second
  /// press at the same spot must SAY it is the second — two press/release
  /// pairs with count 1 are two clicks, never a double-click, and a word
  /// selection never happens.
  @override
  Future<void> mouseDown(
    int x,
    int y, {
    String button = 'left',
    int clickCount = 1,
  }) => send(
    'Input.dispatchMouseEvent',
    params: {
      'type': 'mousePressed',
      'x': x,
      'y': y,
      'button': button,
      'buttons': _buttonMask(button),
      'clickCount': clickCount,
    },
  ).then((_) {});

  /// Releases [button] at viewport coordinates.
  ///
  /// [clickCount] must MATCH the press it answers: a real mouse repeats the
  /// count on release, and Chromium takes the DOM `click`/`dblclick` event's
  /// `detail` from the RELEASE — Blink's native word selection keys off the
  /// press, but a web app's own double-click handler only ever sees the
  /// count the release carried.
  @override
  Future<void> mouseUp(
    int x,
    int y, {
    String button = 'left',
    int clickCount = 1,
  }) => send(
    'Input.dispatchMouseEvent',
    params: {
      'type': 'mouseReleased',
      'x': x,
      'y': y,
      'button': button,
      'buttons': 0,
      'clickCount': clickCount,
    },
  ).then((_) {});

  /// Clicks at viewport coordinates.
  @override
  Future<void> clickAt(
    int x,
    int y, {
    String button = 'left',
    int clickCount = 1,
  }) async {
    await mouseDown(x, y, button: button, clickCount: clickCount);
    await mouseUp(x, y, button: button, clickCount: clickCount);
  }

  /// Scrolls the page by a delta.
  @override
  Future<void> scrollBy(int dx, int dy, {int x = 10, int y = 10}) => send(
    'Input.dispatchMouseEvent',
    params: {'type': 'mouseWheel', 'x': x, 'y': y, 'deltaX': dx, 'deltaY': dy},
  ).then((_) {});

  /// Scrolls with the pointer over [selector]'s centre, or returns false when
  /// nothing matches.
  ///
  /// A wheel event scrolls whatever is UNDER the pointer, so scrolling a named
  /// container is a matter of aiming the event rather than addressing the
  /// element — which is also why an unresolved selector cannot quietly fall
  /// back to the page: that scrolls something else entirely.
  @override
  Future<bool> scrollAt(String selector, int dx, int dy) async {
    final center = await centerOf(selector);
    if (center == null) {
      return false;
    }
    await scrollBy(dx, dy, x: center.$1, y: center.$2);
    return true;
  }

  /// Types literal [text] into whatever has focus.
  ///
  /// One `Input.insertText` rather than a key event per character: it is a
  /// single round trip instead of N, and it handles anything outside the BMP
  /// (emoji, CJK) that a synthesized `char` event mangles.
  @override
  Future<void> typeText(String text) async {
    if (text.isEmpty) {
      return;
    }
    await send('Input.insertText', params: {'text': text});
  }

  /// Selects everything in the focused field (ctrl+A in the Linux guest).
  Future<void> selectAll() async {
    const ctrl = 2; // CDP modifier bitmask: Alt=1, Ctrl=2, Meta=4, Shift=8.
    for (final type in ['keyDown', 'keyUp']) {
      await send(
        'Input.dispatchKeyEvent',
        params: {
          'type': type,
          'key': 'a',
          'code': 'KeyA',
          'windowsVirtualKeyCode': 65,
          'nativeVirtualKeyCode': 65,
          'modifiers': ctrl,
        },
      );
    }
  }

  /// Presses a named key (`Enter`, `Escape`, `Tab`, `ArrowDown`, `F5`, …), or
  /// inserts a single literal character, with [modifiers] held when given.
  ///
  /// Returns false when [key] is neither — never silently no-ops. A
  /// `dispatchKeyEvent` with no `text` and no virtual-key code produces a
  /// keydown the page can see and NO character anywhere, which is what made
  /// human take-over typing look like it worked and insert nothing.
  ///
  /// A printable character takes the `Input.insertText` path rather than a
  /// synthesized key event: which physical key produces "€" is a property of
  /// the LAYOUT, which the browser does not expose, so there is no honest
  /// virtual-key code to send. WITH modifiers the calculus flips — `ctrl+c`
  /// must be a real key event or nothing copies — so a letter or digit is
  /// dispatched with its US-layout code, the one layout assumption a shortcut
  /// chord can survive (the page reads `key`, not the glyph).
  @override
  Future<bool> pressKey(String key, {List<String> modifiers = const []}) async {
    final mask = modifierMask(modifiers);
    final spec = _namedKeys[key.toLowerCase()];
    if (spec == null) {
      if (key.runes.length == 1 && !_isControlChar(key.runes.first)) {
        if (mask == 0) {
          await send('Input.insertText', params: {'text': key});
          return true;
        }
        final chord = _chordForChar(key);
        if (chord == null) {
          return false;
        }
        await send(
          'Input.dispatchKeyEvent',
          params: {'type': 'keyDown', 'modifiers': mask, ...chord},
        );
        await send(
          'Input.dispatchKeyEvent',
          params: {'type': 'keyUp', 'modifiers': mask, ...chord},
        );
        return true;
      }
      return false;
    }
    final params = {
      'key': spec.key,
      'code': spec.code,
      'windowsVirtualKeyCode': spec.vk,
      'nativeVirtualKeyCode': spec.vk,
      // A chorded named key inserts nothing: shift+Tab does not type a tab,
      // and sending `text` anyway would both insert one AND reverse the
      // field focus.
      if (spec.text.isNotEmpty && mask == 0) 'text': spec.text,
      if (mask != 0) 'modifiers': mask,
    };
    await send(
      'Input.dispatchKeyEvent',
      params: {'type': 'keyDown', ...params},
    );
    await send('Input.dispatchKeyEvent', params: {'type': 'keyUp', ...params});
    return true;
  }

  // ── Clipboard and file drops ────────────────────────────────────────────
  //
  // These are the ONLY methods here that evaluate JavaScript, and the scripts
  // are constants in this file — never anything a caller supplied. The rule
  // above ("no caller-supplied JS") is about accountability: an action log
  // full of opaque script bodies cannot be reviewed. A fixed script behind a
  // named verb keeps the log meaningful, because the verb still says what
  // happened.
  //
  // There is no way around the Clipboard API here. The browser surface is
  // headless: no X server, no system clipboard, nothing for a `xclip`
  // equivalent to talk to. What a page can reach IS the clipboard, so it is
  // the page that has to be asked.

  /// Reads the page's clipboard, or reports why it could not.
  ///
  /// [CdpClipboard.unavailable] is the honest half. `navigator.clipboard`
  /// only exists in a SECURE CONTEXT, so a page served over plain `http://`
  /// has no clipboard to read — and the caller needs to be able to say that
  /// instead of reporting an empty clipboard, which is a different claim.
  @override
  Future<CdpClipboard> readClipboard() async {
    await _prepareClipboard();
    final value = await _evaluate(_readClipboardScript);
    if (value == null) {
      return const CdpClipboard(unavailable: 'the page did not answer');
    }
    final unavailable = value['unavailable'];
    if (unavailable is String && unavailable.isNotEmpty) {
      return CdpClipboard(unavailable: unavailable);
    }
    final image = value['image'];
    final mime = value['mime'];
    return CdpClipboard(
      text: value['text'] is String ? value['text'] as String : null,
      imageBase64: image is String && image.isNotEmpty ? image : null,
      imageMediaType: mime is String && mime.isNotEmpty ? mime : null,
    );
  }

  /// The page's current selection as plain text, or an empty string.
  ///
  /// The fallback when the clipboard cannot be read, and the honest answer to
  /// "copy what I have selected": no permission, no secure context and no
  /// user activation are required to read a selection, because the page's own
  /// content is not privileged information to the thing driving the page.
  @override
  Future<String> readSelectionText() async {
    final value = await _evaluate(_readSelectionScript);
    final text = value?['text'];
    return text is String ? text : '';
  }

  /// Puts [text] (or [imageBase64] of [imageMediaType]) on the page's
  /// clipboard. Returns null on success, or the reason it failed.
  @override
  Future<String?> writeClipboard({
    String? text,
    String? imageBase64,
    String? imageMediaType,
  }) async {
    await _prepareClipboard();
    final script = imageBase64 != null && imageBase64.isNotEmpty
        ? _writeClipboardImageScript(imageBase64, imageMediaType ?? 'image/png')
        : _writeClipboardTextScript(text ?? '');
    final value = await _evaluate(script);
    if (value == null) {
      return 'the page did not answer';
    }
    final unavailable = value['unavailable'];
    if (unavailable is String && unavailable.isNotEmpty) {
      return unavailable;
    }
    return null;
  }

  /// Drops the guest-side files at [guestPaths] onto the page at ([x], [y]).
  ///
  /// A REAL drop: the page's `dragenter`/`dragover`/`drop` handlers fire with
  /// a populated `DataTransfer`, so a dropzone behaves exactly as it would
  /// for a person. That matters because the alternative — setting the files
  /// on an `<input type=file>` — only works when there IS such an input, and
  /// most upload zones are a div with a drop handler.
  ///
  /// Returns false when the page refused the drop (nothing at that point
  /// accepts files), which is a real answer and not an error.
  @override
  Future<bool> dropFiles({
    required List<String> guestPaths,
    required int x,
    required int y,
  }) async {
    if (guestPaths.isEmpty) {
      return false;
    }
    // Chromium refuses `Input.dispatchDragEvent` unless drag interception is
    // on. It is turned on for the duration of this drop ONLY: leaving it on
    // makes the browser report every in-page HTML5 drag to us instead of
    // performing it, which would silently break dragging inside a page — a
    // regression nobody would connect to a file-drop feature.
    await send('Input.setInterceptDrags', params: {'enabled': true});
    try {
      final data = {
        'items': [
          for (final path in guestPaths)
            {
              'mimeType': 'application/octet-stream',
              'data': path,
              'title': path.split('/').last,
            },
        ],
        'files': guestPaths,
        // 1 = copy. A drop that offered `move` would invite the page to
        // believe it may delete the source.
        'dragOperationsMask': 1,
      };
      for (final type in ['dragEnter', 'dragOver', 'drop']) {
        await send(
          'Input.dispatchDragEvent',
          params: {'type': type, 'x': x, 'y': y, 'data': data},
        );
      }
      return true;
    } on CdpException catch (e) {
      CcInfraLog.warning('rig/cdp: drop refused at ($x, $y): ${e.message}');
      return false;
    } finally {
      // Restored even when the drop threw: the page must not be left in
      // intercept mode because one drop failed.
      try {
        await send('Input.setInterceptDrags', params: {'enabled': false});
      } on Object {
        // The socket went away mid-drop; the page went with it.
      }
    }
  }

  /// Sets [guestPaths] on the file input matching [selector].
  ///
  /// The other half of "attach a file", for the case a real drop cannot
  /// serve: a hidden `<input type=file>` behind a styled button, which has no
  /// drop target at all.
  @override
  Future<bool> setFileInputFiles({
    required String selector,
    required List<String> guestPaths,
  }) async {
    final nodeId = await _resolveNodeId(selector);
    if (nodeId == null) {
      return false;
    }
    try {
      await send(
        'DOM.setFileInputFiles',
        params: {'nodeId': nodeId, 'files': guestPaths},
      );
      return true;
    } on CdpException catch (e) {
      CcInfraLog.warning('rig/cdp: setFileInputFiles failed: ${e.message}');
      return false;
    }
  }

  /// Grants the page its own clipboard and pins focus.
  ///
  /// Both are needed and neither is optional. The Clipboard API refuses a
  /// document that is not focused, and headless has no window manager to
  /// focus one — `Emulation.setFocusEmulationEnabled` is what makes the page
  /// believe it is frontmost. The permission grant is per-origin, so it is
  /// re-issued on every call rather than cached: the page may have navigated
  /// since the last one.
  ///
  /// Failures are swallowed on purpose. Both commands are best-effort
  /// preparation; if either is unsupported the evaluate that follows returns
  /// a NAMED reason ("NotAllowedError"), which is a better error than one
  /// from a setup step the caller never asked for.
  Future<void> _prepareClipboard() async {
    try {
      await send(
        'Emulation.setFocusEmulationEnabled',
        params: {'enabled': true},
      );
    } on Object {
      // Old build, or a target that does not support emulation.
    }
    try {
      await send(
        'Browser.grantPermissions',
        params: {
          'permissions': ['clipboardReadWrite', 'clipboardSanitizedWrite'],
        },
      );
    } on Object {
      // Grants are per browser context and can be refused; the evaluate below
      // then reports NotAllowedError, which says more than this would.
    }
  }

  /// Runs one of this file's FIXED scripts and returns its object value.
  ///
  /// `awaitPromise` because every clipboard script is async, and
  /// `returnByValue` because the alternative is a remote object handle this
  /// client would then have to release.
  Future<Map<String, dynamic>?> _evaluate(String script) async {
    final result = await send(
      'Runtime.evaluate',
      params: {
        'expression': script,
        'awaitPromise': true,
        'returnByValue': true,
        // The clipboard scripts call `navigator.clipboard.read`, which some
        // builds gate behind a user gesture even with the permission granted.
        'userGesture': true,
      },
    );
    final exception = result['exceptionDetails'];
    if (exception is Map) {
      CcInfraLog.warning(
        'rig/cdp: clipboard script threw: ${exception['text']}',
      );
      return null;
    }
    final value = (result['result'] as Map?)?['value'];
    return value is Map ? value.cast<String, dynamic>() : null;
  }

  /// Embeds [value] as a JavaScript string literal.
  ///
  /// JSON is a subset of JavaScript for everything except U+2028 and U+2029,
  /// which JSON leaves raw and which older parsers read as line terminators
  /// inside a string literal — so a clipboard containing one would produce a
  /// syntax error rather than a paste. Escaping them costs nothing and the
  /// failure it prevents is impossible to diagnose from the outside.
  static String _jsString(String value) => jsonEncode(
    value,
  ).replaceAll('\u2028', r'\u2028').replaceAll('\u2029', r'\u2029');

  static const String _readSelectionScript = '''
(() => {
  const s = window.getSelection();
  return { text: s ? s.toString() : '' };
})()
''';

  static const String _readClipboardScript = '''
(async () => {
  try {
    if (!navigator.clipboard || !navigator.clipboard.read) {
      return { unavailable: 'this page has no clipboard API (it is not a secure context)' };
    }
    const items = await navigator.clipboard.read();
    let text = null, image = null, mime = null;
    for (const item of items) {
      for (const type of item.types) {
        if (type === 'text/plain' && text === null) {
          text = await (await item.getType(type)).text();
        } else if (type.indexOf('image/') === 0 && image === null) {
          const buf = new Uint8Array(await (await item.getType(type)).arrayBuffer());
          // Chunked: String.fromCharCode.apply blows the argument limit at a
          // few hundred thousand elements, and a screenshot is millions.
          let out = '';
          for (let i = 0; i < buf.length; i += 8192) {
            out += String.fromCharCode.apply(null, buf.subarray(i, i + 8192));
          }
          image = btoa(out);
          mime = type;
        }
      }
    }
    return { text: text, image: image, mime: mime };
  } catch (e) {
    return { unavailable: String((e && e.name) || e) };
  }
})()
''';

  static String _writeClipboardTextScript(String text) =>
      '''
(async () => {
  try {
    if (!navigator.clipboard || !navigator.clipboard.writeText) {
      return { unavailable: 'this page has no clipboard API (it is not a secure context)' };
    }
    await navigator.clipboard.writeText(${_jsString(text)});
    return { ok: true };
  } catch (e) {
    return { unavailable: String((e && e.name) || e) };
  }
})()
''';

  static String _writeClipboardImageScript(String base64, String mediaType) =>
      '''
(async () => {
  try {
    if (!navigator.clipboard || !navigator.clipboard.write ||
        typeof ClipboardItem === 'undefined') {
      return { unavailable: 'this page has no clipboard API (it is not a secure context)' };
    }
    const bin = atob(${_jsString(base64)});
    const arr = new Uint8Array(bin.length);
    for (let i = 0; i < bin.length; i++) { arr[i] = bin.charCodeAt(i); }
    const type = ${_jsString(mediaType)};
    await navigator.clipboard.write([
      new ClipboardItem({ [type]: new Blob([arr], { type: type }) }),
    ]);
    return { ok: true };
  } catch (e) {
    return { unavailable: String((e && e.name) || e) };
  }
})()
''';

  /// The `code`/`keyCode` pair for a letter or digit, or null for anything
  /// else — only those have a layout-independent physical identity.
  static Map<String, dynamic>? _chordForChar(String char) {
    final rune = char.runes.first;
    if (rune >= 0x30 && rune <= 0x39) {
      // 0-9
      return {
        'key': char,
        'code': 'Digit$char',
        'windowsVirtualKeyCode': rune,
        'nativeVirtualKeyCode': rune,
      };
    }
    final lower = char.toLowerCase();
    final letter = lower.runes.first;
    if (letter >= 0x61 && letter <= 0x7a) {
      // a-z
      final vk = letter - 0x20;
      return {
        'key': lower,
        'code': 'Key${String.fromCharCode(vk)}',
        'windowsVirtualKeyCode': vk,
        'nativeVirtualKeyCode': vk,
      };
    }
    return null;
  }

  static bool _isControlChar(int rune) => rune < 0x20 || rune == 0x7f;

  /// The document's accessibility tree as text, rooted at [selector] when one
  /// is given.
  @override
  Future<String> accessibilitySnapshot({String? selector}) async {
    await send('Accessibility.enable');
    final result = await send('Accessibility.getFullAXTree');
    final nodes = result['nodes'];
    if (nodes is! List) {
      return '';
    }
    final lines = <String>[];
    for (final n in nodes) {
      if (n is! Map) {
        continue;
      }
      if (n['ignored'] == true) {
        continue;
      }
      final role = _axValue(n['role']);
      final name = _axValue(n['name']);
      if (role.isEmpty && name.isEmpty) {
        continue;
      }
      final value = _axValue(n['value']);
      lines.add(
        '$role${name.isEmpty ? '' : ': "$name"'}'
        '${value.isEmpty ? '' : ' = "$value"'}',
      );
    }
    if (selector != null && selector.isNotEmpty) {
      // The AX tree has no selector filter of its own; note the request rather
      // than silently returning the whole document as if it were the subtree.
      lines.insert(
        0,
        '[full document — subtree filtering by selector is not '
        'supported by the accessibility tree]',
      );
    }
    return lines.join('\n');
  }

  /// A pruned view of the DOM: interactive elements and visible text with the
  /// selectors needed to act on them.
  ///
  /// Not the raw HTML. A real page's markup is mostly framework scaffolding,
  /// and handing an agent 400 KB of `div` is a way to spend a context window
  /// without learning anything.
  /// Returns null when [selector] matches nothing — never the whole document
  /// under a subtree label, which reads as "this is all there is in there".
  @override
  Future<String?> domSnapshot({String? selector, int maxNodes = 400}) async {
    final Map<dynamic, dynamic>? root;
    if (selector != null && selector.isNotEmpty) {
      final nodeId = await _resolveNodeId(selector);
      if (nodeId == null) {
        return null;
      }
      final described = await send(
        'DOM.describeNode',
        params: {'nodeId': nodeId, 'depth': -1},
      );
      final node = described['node'];
      root = node is Map ? node : null;
    } else {
      final doc = await send('DOM.getDocument', params: {'depth': -1});
      final docRoot = doc['root'];
      root = docRoot is Map ? docRoot : null;
    }
    if (root == null) {
      return '';
    }
    final lines = <String>[];
    var count = 0;

    void walk(Map<dynamic, dynamic> node, int depth) {
      if (count >= maxNodes) {
        return;
      }
      final nodeName = node['nodeName'] as String? ?? '';
      final nodeType = node['nodeType'] as int? ?? 0;
      if (nodeType == 3) {
        final text = (node['nodeValue'] as String? ?? '').trim();
        if (text.isNotEmpty) {
          lines.add('${'  ' * depth}"$text"');
          count++;
        }
      } else if (nodeType == 1) {
        final tag = nodeName.toLowerCase();
        if (!_skippedTags.contains(tag)) {
          final attrs = _attrMap(node['attributes']);
          final descriptor = StringBuffer('${'  ' * depth}<$tag');
          for (final key in const [
            'id',
            'name',
            'type',
            'href',
            'aria-label',
            'placeholder',
            'value',
            'role',
            'class',
          ]) {
            final v = attrs[key];
            if (v != null && v.isNotEmpty) {
              final trimmed = v.length > 60 ? '${v.substring(0, 60)}…' : v;
              descriptor.write(' $key="$trimmed"');
            }
          }
          descriptor.write('>');
          lines.add(descriptor.toString());
          count++;
        }
        final children = node['children'];
        if (children is List) {
          for (final c in children) {
            if (c is Map) {
              walk(c, depth + 1);
            }
          }
        }
        return;
      }
      final children = node['children'];
      if (children is List) {
        for (final c in children) {
          if (c is Map) {
            walk(c, depth + 1);
          }
        }
      }
    }

    walk(root, 0);
    if (count >= maxNodes) {
      lines.add('[…truncated at $maxNodes nodes]');
    }
    if (selector != null && selector.isNotEmpty) {
      lines.insert(0, '[subtree of $selector]');
    }
    return lines.join('\n');
  }

  /// Resolves [selector] to a node id, or null when nothing matches.
  Future<int?> _resolveNodeId(String selector) async {
    final doc = await send('DOM.getDocument');
    final rootId = (doc['root'] as Map?)?['nodeId'];
    if (rootId is! int) {
      return null;
    }
    final query = await send(
      'DOM.querySelector',
      params: {'nodeId': rootId, 'selector': selector},
    );
    final nodeId = query['nodeId'];
    // CDP answers a miss with nodeId 0, not with an error.
    return nodeId is int && nodeId != 0 ? nodeId : null;
  }

  /// Resolves [selector] to its viewport centre, or null when it does not
  /// match or is not laid out.
  @override
  Future<(int, int)?> centerOf(String selector) async {
    final nodeId = await _resolveNodeId(selector);
    if (nodeId == null) {
      return null;
    }
    final box = await send('DOM.getBoxModel', params: {'nodeId': nodeId});
    final model = box['model'];
    if (model is! Map) {
      return null;
    }
    final content = model['content'];
    if (content is! List || content.length < 8) {
      return null;
    }
    final xs = <num>[
      content[0] as num,
      content[2] as num,
      content[4] as num,
      content[6] as num,
    ];
    final ys = <num>[
      content[1] as num,
      content[3] as num,
      content[5] as num,
      content[7] as num,
    ];
    final cx = xs.reduce((a, b) => a + b) / 4;
    final cy = ys.reduce((a, b) => a + b) / 4;
    return (cx.round(), cy.round());
  }

  /// Sets an input's value and dispatches the events a framework listens for.
  ///
  /// Focus + select-all + type, rather than assigning `.value`: React and
  /// friends track their own state and ignore a value that arrives without
  /// input events, so the direct assignment "works" and then submits empty.
  @override
  Future<bool> fill(String selector, String text, {bool submit = false}) async {
    final center = await centerOf(selector);
    if (center == null) {
      return false;
    }
    await clickAt(center.$1, center.$2);
    await selectAll();
    await pressKey('Delete');
    if (text.isNotEmpty) {
      await typeText(text);
    }
    if (submit) {
      await pressKey('Enter');
    }
    return true;
  }

  /// Waits until [selector] matches, or gives up after [timeout].
  @override
  Future<bool> waitFor(String selector, Duration timeout) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (await centerOf(selector) != null) {
        return true;
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    return false;
  }

  /// Navigates the session history by [delta] (negative = back).
  @override
  Future<bool> goHistory(int delta) async {
    final history = await send('Page.getNavigationHistory');
    final entries = history['entries'];
    final current = history['currentIndex'];
    if (entries is! List || current is! int) {
      return false;
    }
    final target = current + delta;
    if (target < 0 || target >= entries.length) {
      return false;
    }
    final entry = entries[target];
    if (entry is! Map || entry['id'] is! int) {
      return false;
    }
    await send('Page.navigateToHistoryEntry', params: {'entryId': entry['id']});
    return true;
  }

  /// The session history position: current URL plus whether back/forward
  /// have anywhere to go.
  ///
  /// Throws on a protocol failure — unlike [currentUrl], which swallows one
  /// because the URL is context in a result text, a caller asking for
  /// navigation STATE is answering "may I offer back?" and a silent empty
  /// answer would disable working buttons.
  @override
  Future<({String url, bool canGoBack, bool canGoForward})>
  navigationState() async {
    final history = await send('Page.getNavigationHistory');
    final entries = history['entries'];
    final current = history['currentIndex'];
    if (entries is! List || current is! int) {
      throw const CdpException('Page.getNavigationHistory answered malformed');
    }
    var url = '';
    if (current >= 0 && current < entries.length) {
      final entry = entries[current];
      if (entry is Map && entry['url'] is String) {
        url = entry['url'] as String;
      }
    }
    return (
      url: url,
      canGoBack: current > 0,
      canGoForward: current >= 0 && current < entries.length - 1,
    );
  }

  /// The current page URL, or empty when unknown.
  @override
  Future<String> currentUrl() async {
    try {
      return (await navigationState()).url;
    } on Object {
      // Best effort — the URL is context, never the answer.
    }
    return '';
  }

  /// Closes the client.
  ///
  /// Deliberate: this is what distinguishes a teardown from a dropped socket,
  /// so no re-attach is attempted afterwards and an in-flight one stops.
  @override
  Future<void> close() async {
    if (_state == CdpConnectionState.closed) {
      return;
    }
    _setState(CdpConnectionState.closed);
    await _sub?.cancel();
    await _pageEventsSub?.cancel();
    _pageEventsSub = null;
    try {
      await _socket.close();
    } on Object {
      // Already gone.
    }
    _failPending(const CdpException('CDP socket closed'));
    final pageEvents = _pageEventsController;
    _pageEventsController = null;
    if (pageEvents != null && !pageEvents.isClosed) {
      await pageEvents.close();
    }
    if (!_events.isClosed) {
      await _events.close();
    }
    if (!_screencastFrames.isClosed) {
      await _screencastFrames.close();
    }
  }

  // ── Connection lifecycle ────────────────────────────────────────────────

  void _bind() {
    final generation = _generation;
    _sub = _socket.stream.listen(
      _onFrame,
      onDone: () {
        if (generation == _generation) {
          _handleDrop('The browser closed the CDP connection');
        }
      },
      onError: (Object e) {
        if (generation == _generation) {
          _handleDrop('CDP socket error: $e');
        }
      },
    );
  }

  /// The socket dropped on its own. Re-attach when there is an endpoint to
  /// re-attach through, otherwise go terminal exactly as before.
  void _handleDrop(String reason) {
    if (_state != CdpConnectionState.connected) {
      // Already closed, or already re-attaching — a dying socket reports
      // itself through more than one space and only the first is news.
      return;
    }
    final policy = _reconnect;
    if (policy == null) {
      _terminate(CdpException(reason));
      return;
    }
    _setState(CdpConnectionState.reconnecting);
    _failPending(CdpException('$reason; a CDP re-attach is in progress'));
    CcInfraLog.warning('rig/cdp: $reason — re-attaching');
    unawaited(_reattach(policy));
  }

  Future<void> _reattach(CdpReconnectPolicy policy) async {
    final deadline = DateTime.now().add(policy.window);
    var attempt = 0;
    while (_state == CdpConnectionState.reconnecting) {
      final delay = policy.backoff.isEmpty
          ? Duration.zero
          : policy.backoff[attempt.clamp(0, policy.backoff.length - 1)];
      attempt++;
      await Future<void>.delayed(delay);
      if (_state != CdpConnectionState.reconnecting) {
        // `close()` won the race; a teardown must not be undone.
        return;
      }
      try {
        final attachment = await policy.attach(_currentTargetId);
        if (_state != CdpConnectionState.reconnecting) {
          // `close()` won while we were attaching. Adopting now would revive a
          // client the caller already tore down.
          unawaited(attachment.socket.close().catchError((Object _) {}));
          return;
        }
        await _adopt(attachment);
        _setState(CdpConnectionState.connected);
        CcInfraLog.info('rig/cdp: re-attached after $attempt attempt(s)');
        return;
      } on Object catch (e) {
        // The FIRST failure is the diagnosis; the rest are the same failure
        // once per backoff step, and logging them all buries it.
        if (attempt == 1) {
          CcInfraLog.warning('rig/cdp: re-attach failed: $e');
        } else {
          CcInfraLog.debug('rig/cdp: re-attach attempt $attempt failed: $e');
        }
      }
      if (!DateTime.now().isBefore(deadline)) {
        break;
      }
    }
    if (_state != CdpConnectionState.reconnecting) {
      return;
    }
    _terminate(
      CdpException(
        'CDP re-attach gave up after ${policy.window.inSeconds}s '
        '($attempt attempt(s))',
      ),
    );
  }

  /// Points this client at another page target — a popup, a new tab, or the
  /// survivor of a `window.close()`.
  ///
  /// Throws when this client has no DevTools endpoint to attach through, or
  /// when the endpoint no longer has [targetId]: silently landing on a
  /// DIFFERENT page would make every later action address something the caller
  /// never asked for.
  Future<void> attachToTarget(String targetId) async {
    final policy = _reconnect;
    if (policy == null) {
      throw const CdpException(
        'This CDP client has no DevTools endpoint, so it cannot switch target.',
      );
    }
    if (_state == CdpConnectionState.closed) {
      throw const CdpException('CDP client is closed.');
    }
    final previous = _state;
    _setState(CdpConnectionState.reconnecting);
    try {
      final attachment = await policy.attach(targetId);
      if (attachment.targetId != null && attachment.targetId != targetId) {
        try {
          await attachment.socket.close();
        } on Object {
          // Best effort; we are throwing anyway.
        }
        throw CdpException('The browser no longer has target $targetId.');
      }
      await _adopt(attachment, targetId: targetId);
      _setState(CdpConnectionState.connected);
    } on Object {
      if (_state == CdpConnectionState.reconnecting) {
        // Put the client back where it was: a failed switch must not leave it
        // wedged in a state where every command fails fast forever.
        _setState(previous);
      }
      rethrow;
    }
  }

  /// Swaps in [attachment] and replays the session state onto it.
  Future<void> _adopt(CdpAttachment attachment, {String? targetId}) async {
    await _sub?.cancel();
    // Not awaited (a dead socket may never finish closing) and its failure is
    // swallowed rather than left to become an unhandled zone error: the old
    // socket being unclosable is why we are opening a new one.
    unawaited(_socket.close().catchError((Object _) {}));
    _generation++;
    _socket = attachment.socket;
    _currentTargetId = targetId ?? attachment.targetId ?? _currentTargetId;
    _bind();
    await _restoreSession();
  }

  /// Re-applies everything that lives on the CONNECTION rather than the page:
  /// enabled domains, the viewport override and a running screencast.
  Future<void> _restoreSession() async {
    if (_domainsEnabled) {
      await _enableDomains(duringHandshake: true);
    }
    final viewport = _viewport;
    if (viewport != null) {
      await _applyViewport(viewport, duringHandshake: true);
    }
    final cast = _screencast;
    if (cast != null) {
      await _applyScreencast(cast, duringHandshake: true);
    }
  }

  void _terminate(CdpException error) {
    if (_state == CdpConnectionState.closed) {
      return;
    }
    _setState(CdpConnectionState.closed);
    _failPending(error);
    if (!_events.isClosed) {
      unawaited(_events.close());
    }
    if (!_screencastFrames.isClosed) {
      unawaited(_screencastFrames.close());
    }
  }

  void _setState(CdpConnectionState state) {
    if (_state == state || _state == CdpConnectionState.closed) {
      // `closed` is terminal by contract: nothing may revive a client whose
      // caller has already torn it down.
      return;
    }
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
      if (state == CdpConnectionState.closed) {
        // Delivered first: a broadcast controller flushes what was added
        // before it closes.
        unawaited(_states.close());
      }
    }
  }

  void _onFrame(dynamic frame) {
    if (frame is! String) {
      return;
    }
    // Defence in depth: the fast path is an optimization, and NOTHING it does
    // may be able to take the frame loop down — an exception escaping here
    // leaves every in-flight command hanging until its timeout.
    try {
      if (_tryFastScreencastFrame(frame)) {
        return;
      }
    } on Object catch (e) {
      CcInfraLog.warning('rig/cdp: screencast fast path failed: $e');
    }
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(frame);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      message = decoded;
    } on FormatException {
      CcInfraLog.warning('rig/cdp: dropping unparseable frame');
      return;
    }
    final id = message['id'];
    if (id is int) {
      final completer = _pending.remove(id);
      if (completer == null) {
        return;
      }
      final error = message['error'];
      if (error is Map) {
        completer.completeError(
          CdpException(
            error['message'] as String? ?? 'Unknown CDP error',
            code: error['code'] as int?,
          ),
        );
        return;
      }
      final result = message['result'];
      completer.complete(
        result is Map<String, dynamic> ? result : <String, dynamic>{},
      );
      return;
    }
    final method = message['method'];
    if (method is! String) {
      return;
    }
    final params = message['params'];
    final event = CdpEvent(
      method,
      params is Map<String, dynamic> ? params : const {},
    );
    switch (method) {
      case 'Page.screencastFrame':
        // The lexical fast path did not recognize this frame (an unexpected
        // field order, say). Decode it the slow way rather than dropping it.
        _emitScreencastFrame(event.params);
        return;
      case 'Runtime.consoleAPICalled' || 'Log.entryAdded':
        _bufferConsole(event);
      case 'Target.targetCreated' || 'Target.targetInfoChanged':
        _rememberTarget(event.params['targetInfo']);
      case 'Target.targetDestroyed':
        _forgetTarget(event.params['targetId']);
      case 'Page.javascriptDialogOpening':
        _handleDialog(event.params);
      default:
        break;
    }
    if (!_events.isClosed) {
      _events.add(event);
    }
  }

  /// Recognizes a `Page.screencastFrame` frame and emits it without parsing
  /// the whole thing. Returns false when the frame is anything else, or when
  /// its shape is not the one Chromium emits — the caller then takes the
  /// ordinary decode path, so this can only ever be a shortcut, never a
  /// behaviour change.
  ///
  /// Only the method name, the `data` field and `sessionId` are read. The
  /// `metadata` block (page scale, scroll offsets, timestamp) is not used by
  /// any consumer, and it is the reason the generic path had to build a map.
  bool _tryFastScreencastFrame(String frame) {
    // The method name is near the front of every event frame; bound the probe
    // so a huge non-event frame is not scanned end to end for nothing.
    // `lastIndexOf(needle, start)` searches BACKWARD from `start`, which is
    // what bounds the probe — a plain `indexOf` would scan a 500 KB frame end
    // to end before concluding it is not an event.
    //
    // `start` MUST be clamped to the frame length: `lastIndexOf` throws a
    // RangeError for a start past the end, and an exception here escapes
    // `_onFrame` and kills the whole frame loop — every pending command then
    // hangs. Most frames are short, so the unclamped form broke everything.
    const probeLimit = 200;
    final probeStart = frame.length < probeLimit ? frame.length : probeLimit;
    if (frame.lastIndexOf('"Page.screencastFrame"', probeStart) < 0) {
      return false;
    }
    const dataKey = '"data":"';
    final dataStart = frame.indexOf(dataKey);
    if (dataStart < 0) {
      return false;
    }
    final valueStart = dataStart + dataKey.length;
    final valueEnd = frame.indexOf('"', valueStart);
    if (valueEnd < 0) {
      return false;
    }
    const sessionKey = '"sessionId":';
    final sessionStart = frame.indexOf(sessionKey);
    var sessionId = -1;
    if (sessionStart >= 0) {
      var i = sessionStart + sessionKey.length;
      while (i < frame.length && frame.codeUnitAt(i) == 0x20) {
        i++;
      }
      var value = 0;
      var digits = 0;
      while (i < frame.length) {
        final c = frame.codeUnitAt(i);
        if (c < 0x30 || c > 0x39) {
          break;
        }
        value = value * 10 + (c - 0x30);
        digits++;
        i++;
      }
      if (digits > 0) {
        sessionId = value;
      }
    }
    final Uint8List bytes;
    try {
      // Decoded straight out of the socket frame — no substring, so the
      // base64 payload is never copied.
      bytes = base64.decoder.convert(frame, valueStart, valueEnd);
    } on FormatException {
      return false;
    }
    if (!_screencastFrames.isClosed) {
      _screencastFrames.add(
        CdpScreencastFrame(bytes: bytes, sessionId: sessionId),
      );
    }
    return true;
  }

  /// Emits a screencast frame decoded from an already-parsed params map.
  void _emitScreencastFrame(Map<String, dynamic> params) {
    final data = params['data'];
    if (data is! String) {
      return;
    }
    final sessionId = params['sessionId'];
    final Uint8List bytes;
    try {
      bytes = base64Decode(data);
    } on FormatException {
      return;
    }
    if (!_screencastFrames.isClosed) {
      _screencastFrames.add(
        CdpScreencastFrame(
          bytes: bytes,
          sessionId: sessionId is int ? sessionId : -1,
        ),
      );
    }
  }

  void _rememberTarget(Object? info) {
    if (info is! Map || info['type'] != 'page') {
      return;
    }
    final id = info['targetId'];
    if (id is! String || id.isEmpty) {
      return;
    }
    // Assigning an existing key keeps its position, so `targetInfoChanged`
    // updates a tab in place rather than promoting it to "newest".
    _targets[id] = CdpTarget(
      id: id,
      url: '${info['url'] ?? ''}',
      title: '${info['title'] ?? ''}',
    );
  }

  void _forgetTarget(Object? rawId) {
    if (rawId is! String) {
      return;
    }
    _targets.remove(rawId);
    if (rawId != _currentTargetId) {
      return;
    }
    // The page we were driving is gone. Following the newest survivor is what
    // makes `window.close()` recoverable and a popup that replaced the page
    // drivable, instead of leaving the client attached to nothing.
    unawaited(_followNewestSurvivor());
  }

  Future<void> _followNewestSurvivor() async {
    if (_targets.isEmpty || _reconnect == null) {
      // Nothing to follow to: the socket drop that follows a target's death
      // takes it from here, and re-attaching would race that.
      return;
    }
    final survivor = _targets.values.last;
    try {
      await attachToTarget(survivor.id);
      CcInfraLog.info('rig/cdp: followed to target ${survivor.id}');
    } on Object catch (e) {
      CcInfraLog.warning('rig/cdp: could not follow to a surviving target: $e');
    }
  }

  /// Answers a modal dialog and records it.
  ///
  /// A dialog blocks the renderer until it is answered: the page stops
  /// responding, the screencast freezes and every later action times out with
  /// nothing saying why. Dismissed by default rather than accepted — accepting
  /// is a decision an agent's click never made — except `beforeunload`, where
  /// dismissing CANCELS the navigation and wedges the page on a form it can
  /// never leave.
  void _handleDialog(Map<String, dynamic> params) {
    final type = '${params['type'] ?? 'alert'}';
    final accept = type == 'beforeunload';
    _dialogBuffer.add(
      CdpDialogRecord(
        type: type,
        message: '${params['message'] ?? ''}',
        url: '${params['url'] ?? ''}',
        at: DateTime.now(),
        accepted: accept,
      ),
    );
    // Bounded, like the console buffer: a page in an alert loop must not grow
    // the host's memory.
    if (_dialogBuffer.length > _maxBufferedDialogs) {
      _dialogBuffer.removeRange(0, _dialogBuffer.length - _maxBufferedDialogs);
    }
    if (!autoDismissDialogs) {
      return;
    }
    unawaited(
      send(
        'Page.handleJavaScriptDialog',
        params: {'accept': accept},
      ).catchError((Object e) {
        CcInfraLog.debug('rig/cdp: dialog dismissal failed: $e');
        return <String, dynamic>{};
      }),
    );
  }

  static const int _maxBufferedDialogs = 200;

  void _bufferConsole(CdpEvent event) {
    // Bounded: a page in a logging loop must not grow the host's memory.
    const maxBuffered = 200;
    final text = switch (event.method) {
      'Log.entryAdded' =>
        (event.params['entry'] as Map?)?['text'] as String? ?? '',
      _ => [
        for (final a in (event.params['args'] as List? ?? const []))
          if (a is Map) '${a['value'] ?? a['description'] ?? ''}',
      ].where((s) => s.isNotEmpty).join(' '),
    };
    if (text.isEmpty) {
      return;
    }
    final level = switch (event.method) {
      'Log.entryAdded' =>
        (event.params['entry'] as Map?)?['level'] as String? ?? 'log',
      _ => event.params['type'] as String? ?? 'log',
    };
    _consoleBuffer.add('[$level] $text');
    if (_consoleBuffer.length > maxBuffered) {
      _consoleBuffer.removeRange(0, _consoleBuffer.length - maxBuffered);
    }
  }

  void _failPending(CdpException error) {
    final pending = _pending.values.toList();
    _pending.clear();
    for (final c in pending) {
      if (!c.isCompleted) {
        c.completeError(error);
      }
    }
  }

  static String _axValue(Object? raw) {
    if (raw is Map) {
      final v = raw['value'];
      return v == null ? '' : '$v';
    }
    return raw == null ? '' : '$raw';
  }

  static Map<String, String> _attrMap(Object? raw) {
    // CDP encodes attributes as a flat [k, v, k, v, …] list.
    if (raw is! List) {
      return const {};
    }
    final out = <String, String>{};
    for (var i = 0; i + 1 < raw.length; i += 2) {
      out['${raw[i]}'] = '${raw[i + 1]}';
    }
    return out;
  }

  static const Set<String> _skippedTags = {
    'script',
    'style',
    'noscript',
    'meta',
    'link',
    'head',
    'svg',
    'path',
  };

  /// Special keys, looked up case-insensitively so `enter`/`Enter`/`Return`
  /// all reach the same event.
  ///
  /// A page reads `key`, `code` and `keyCode` for different things (shortcut
  /// libraries overwhelmingly use `keyCode`), so all three are sent. Keys that
  /// insert a character carry `text` as well; the ones that do not must NOT,
  /// or Escape types an escape character into the field.
  static const Map<String, _CdpKey> _namedKeys = {
    'enter': _CdpKey(key: 'Enter', code: 'Enter', vk: 13, text: '\r'),
    'return': _CdpKey(key: 'Enter', code: 'Enter', vk: 13, text: '\r'),
    'tab': _CdpKey(key: 'Tab', code: 'Tab', vk: 9, text: '\t'),
    'space': _CdpKey(key: ' ', code: 'Space', vk: 32, text: ' '),
    'spacebar': _CdpKey(key: ' ', code: 'Space', vk: 32, text: ' '),
    'escape': _CdpKey(key: 'Escape', code: 'Escape', vk: 27),
    'esc': _CdpKey(key: 'Escape', code: 'Escape', vk: 27),
    'backspace': _CdpKey(key: 'Backspace', code: 'Backspace', vk: 8),
    'delete': _CdpKey(key: 'Delete', code: 'Delete', vk: 46),
    'del': _CdpKey(key: 'Delete', code: 'Delete', vk: 46),
    'insert': _CdpKey(key: 'Insert', code: 'Insert', vk: 45),
    'arrowup': _CdpKey(key: 'ArrowUp', code: 'ArrowUp', vk: 38),
    'up': _CdpKey(key: 'ArrowUp', code: 'ArrowUp', vk: 38),
    'arrowdown': _CdpKey(key: 'ArrowDown', code: 'ArrowDown', vk: 40),
    'down': _CdpKey(key: 'ArrowDown', code: 'ArrowDown', vk: 40),
    'arrowleft': _CdpKey(key: 'ArrowLeft', code: 'ArrowLeft', vk: 37),
    'left': _CdpKey(key: 'ArrowLeft', code: 'ArrowLeft', vk: 37),
    'arrowright': _CdpKey(key: 'ArrowRight', code: 'ArrowRight', vk: 39),
    'right': _CdpKey(key: 'ArrowRight', code: 'ArrowRight', vk: 39),
    'home': _CdpKey(key: 'Home', code: 'Home', vk: 36),
    'end': _CdpKey(key: 'End', code: 'End', vk: 35),
    'pageup': _CdpKey(key: 'PageUp', code: 'PageUp', vk: 33),
    'pagedown': _CdpKey(key: 'PageDown', code: 'PageDown', vk: 34),
    'f1': _CdpKey(key: 'F1', code: 'F1', vk: 112),
    'f2': _CdpKey(key: 'F2', code: 'F2', vk: 113),
    'f3': _CdpKey(key: 'F3', code: 'F3', vk: 114),
    'f4': _CdpKey(key: 'F4', code: 'F4', vk: 115),
    'f5': _CdpKey(key: 'F5', code: 'F5', vk: 116),
    'f6': _CdpKey(key: 'F6', code: 'F6', vk: 117),
    'f7': _CdpKey(key: 'F7', code: 'F7', vk: 118),
    'f8': _CdpKey(key: 'F8', code: 'F8', vk: 119),
    'f9': _CdpKey(key: 'F9', code: 'F9', vk: 120),
    'f10': _CdpKey(key: 'F10', code: 'F10', vk: 121),
    'f11': _CdpKey(key: 'F11', code: 'F11', vk: 122),
    'f12': _CdpKey(key: 'F12', code: 'F12', vk: 123),
  };
}

/// One special key's DOM identity, as `Input.dispatchKeyEvent` wants it.
class _CdpKey {
  const _CdpKey({
    required this.key,
    required this.code,
    required this.vk,
    this.text = '',
  });

  /// The `KeyboardEvent.key` value.
  final String key;

  /// The `KeyboardEvent.code` (physical key) value.
  final String code;

  /// The legacy `keyCode`/`which` value.
  final int vk;

  /// The character this key inserts, empty when it inserts nothing.
  final String text;
}

/// A page target as `/json/list` describes it, with the URL CDP speaks over.
class _DevToolsTarget {
  const _DevToolsTarget({
    required this.id,
    required this.url,
    required this.title,
    required this.webSocketDebuggerUrl,
  });

  final String id;
  final String url;
  final String title;
  final String webSocketDebuggerUrl;
}

/// The viewport override to re-apply after a re-attach.
class _CdpViewport {
  const _CdpViewport({
    required this.width,
    required this.height,
    required this.mobile,
    this.scale = 1,
  });

  final int width;
  final int height;
  final bool mobile;

  /// Device pixels per CSS pixel. Remembered with the size because a
  /// re-attach re-applies the whole override, and coming back at 1x would
  /// silently halve the watch lane's resolution mid-session.
  final double scale;
}

/// The screencast request to re-arm after a re-attach.
class _CdpScreencast {
  const _CdpScreencast({
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
    required this.everyNthFrame,
  });

  final int maxWidth;
  final int maxHeight;
  final int quality;
  final int everyNthFrame;
}

/// One protocol event.
class CdpEvent {
  /// Creates a [CdpEvent].
  const CdpEvent(this.method, this.params);

  /// The event name (`Page.screencastFrame`).
  final String method;

  /// Its payload.
  final Map<String, dynamic> params;
}

/// One decoded screencast frame off [CdpClient.screencastFrames].
///
/// An alias of the engine-neutral [BrowserFrame]. Chromium is the only engine
/// that pushes frames, but the watch lane relays bytes from all three, and a
/// Chromium-only frame type would have forced a conversion in the one place
/// that must not allocate per frame.
typedef CdpScreencastFrame = BrowserFrame;
