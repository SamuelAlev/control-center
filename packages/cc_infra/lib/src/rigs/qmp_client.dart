// The event StreamController and the socket are closed in `close()` and
// `_onDone()`, which `close_sinks` cannot see across methods.
// ignore_for_file: close_sinks

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/rigs/domain/value_objects/rig_action.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// A QMP command failed on the hypervisor side.
class QmpException implements Exception {
  /// Creates a [QmpException].
  const QmpException(this.message, {this.qmpClass});

  /// What QEMU said.
  final String message;

  /// QEMU's own error class (`GenericError`, `DeviceNotFound`, …).
  final String? qmpClass;

  @override
  String toString() =>
      'QmpException${qmpClass == null ? '' : ' ($qmpClass)'}: $message';
}

/// The socket seam, so tests can drive the client without a hypervisor.
///
/// A real [Socket] satisfies this through [IoQmpSocket]; a fake in a test is a
/// handful of lines. Without the seam every input-ordering test would need
/// QEMU running, which in practice means the input path is untested.
abstract interface class QmpSocket {
  /// Bytes arriving from QEMU.
  Stream<List<int>> get stream;

  /// Completes (or fails) when the socket is finished. WRITE failures surface
  /// here rather than at the `write` call site.
  Future<void> get done;

  /// Writes one already-terminated payload.
  void write(String data);

  /// Closes the socket gracefully.
  Future<void> close();

  /// Drops the socket immediately.
  void destroy();
}

/// Where a [QmpClient] is in its connection lifecycle.
///
/// Exposed so a watchdog can tell "QEMU is gone" from "the control space
/// blinked". Those need different answers: the first must fail the rig, the
/// second must not — and today a QMP socket that dies while QEMU lives is
/// invisible, so the rig stays `ready` while every action fails.
enum QmpConnectionState {
  /// The socket is up and commands are being answered.
  connected,

  /// The socket died unexpectedly and a redial is in progress. Commands fail
  /// fast rather than queueing: an action that silently waits 30s for a socket
  /// is indistinguishable from a hung guest.
  reconnecting,

  /// Terminally closed — [QmpClient.close] was called, or the reconnect window
  /// was exhausted. There is no path back from here.
  closed,
}

/// How a dead QMP socket is re-established.
///
/// A policy is the whole difference between a client that survives a control
/// socket blip and one that does not. It is optional on purpose: a socket
/// handed in from outside ([QmpClient.over]) is one this client has no way to
/// reopen, so those instances stay single-shot unless the caller says
/// otherwise.
class QmpReconnectPolicy {
  /// Creates a policy that redials through [connect].
  const QmpReconnectPolicy({
    required this.connect,
    this.backoff = defaultBackoff,
    this.window = const Duration(seconds: 30),
    this.handshakeTimeout = const Duration(seconds: 10),
  });

  /// Opens a fresh socket to the same QMP endpoint.
  final Future<QmpSocket> Function() connect;

  /// The delay before each attempt. The last entry repeats once the list is
  /// exhausted, which is what makes this a cap rather than a schedule length.
  final List<Duration> backoff;

  /// How long redialling may go on before the client gives up for good.
  final Duration window;

  /// How long a reconnected socket has to produce its `QMP` greeting.
  final Duration handshakeTimeout;

  /// 250ms → 5s: fast enough that a blip is invisible to an agent, slow enough
  /// that a dead hypervisor is not hammered for the whole window.
  static const List<Duration> defaultBackoff = [
    Duration(milliseconds: 250),
    Duration(milliseconds: 500),
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 4),
    Duration(seconds: 5),
  ];
}

/// A [QmpSocket] over a real unix [Socket].
class IoQmpSocket implements QmpSocket {
  /// Wraps [_socket].
  IoQmpSocket(this._socket);

  final Socket _socket;

  @override
  Stream<List<int>> get stream => _socket;

  @override
  Future<void> get done => _socket.done;

  @override
  void write(String data) => _socket.write(data);

  @override
  Future<void> close() => _socket.close();

  @override
  void destroy() => _socket.destroy();
}

/// A pure-Dart client for QEMU's Machine Protocol.
///
/// QMP is a line-delimited JSON protocol over a unix socket. Every command
/// gets exactly one reply (`return` or `error`), and the server also pushes
/// unsolicited `event` objects, so replies are correlated by ORDER — QMP has
/// no request ids of its own unless you supply one, and we do
/// ([_nextId]) rather than trusting FIFO across an event storm.
///
/// This is the host-side input path: keyboard and pointer events are injected
/// through the hypervisor's own virtual input devices rather than by a daemon
/// inside the guest. That is deliberate — it means the guest agent never needs
/// root, and a compromised guest cannot fabricate input to itself from a
/// process we granted privileges to.
class QmpClient {
  QmpClient._(this._socket, {QmpReconnectPolicy? reconnect})
    : _reconnect = reconnect {
    _bind();
  }

  /// Builds a client over an already-open [socket], skipping the greeting
  /// handshake (tests, or a socket the caller negotiated itself).
  ///
  /// Single-shot unless [reconnect] is supplied — a socket this client did not
  /// open is one it cannot reopen.
  QmpClient.over(QmpSocket socket, {QmpReconnectPolicy? reconnect})
    : this._(socket, reconnect: reconnect);

  /// Connects to the QMP unix socket at [path] and completes the capability
  /// negotiation handshake.
  ///
  /// QEMU sends a `QMP` greeting and refuses every command until the client
  /// answers `qmp_capabilities`. Skipping that leaves the socket looking alive
  /// while every command fails, which reads like a hung VM.
  ///
  /// The returned client redials [path] on an unexpected socket death (pass
  /// `reconnect: false` to keep the old single-shot behaviour). Reconnection is
  /// armed only AFTER this first handshake succeeds: a client that never had a
  /// working session is not one to resurrect in the background, and the caller
  /// is already retrying the connect itself.
  static Future<QmpClient> connect(
    String path, {
    Duration timeout = const Duration(seconds: 10),
    bool reconnect = true,
    List<Duration>? backoff,
    Duration reconnectWindow = const Duration(seconds: 30),
  }) async {
    Future<QmpSocket> dial() async => IoQmpSocket(
      await Socket.connect(
        InternetAddress(path, type: InternetAddressType.unix),
        0,
      ).timeout(timeout),
    );

    final client = QmpClient._(await dial());
    // Every failure past this point must close the socket it opened. The
    // launch path retries this connect every 150 ms for up to 15 s while the
    // hypervisor comes up, so a greeting timeout that threw without closing
    // left one dangling unix socket PER ATTEMPT — a hundred of them for a VM
    // that never answered.
    try {
      await client._greeting.future.timeout(
        timeout,
        onTimeout: () => throw const QmpException('No QMP greeting from QEMU'),
      );
      await client.execute('qmp_capabilities');
    } on Object {
      await client.close();
      rethrow;
    }
    if (reconnect) {
      client._reconnect = QmpReconnectPolicy(
        connect: dial,
        backoff: backoff ?? QmpReconnectPolicy.defaultBackoff,
        window: reconnectWindow,
        handshakeTimeout: timeout,
      );
    }
    return client;
  }

  QmpSocket _socket;
  QmpReconnectPolicy? _reconnect;
  StreamSubscription<String>? _lines;
  Completer<void> _greeting = _freshGreeting();
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<QmpConnectionState> _states =
      StreamController<QmpConnectionState>.broadcast();
  QmpConnectionState _state = QmpConnectionState.connected;
  int _nextId = 0;

  /// Set once this machine has been asked to go away (or announced that it is
  /// going). A socket death after that is the expected outcome, not a fault to
  /// redial.
  bool _expectShutdown = false;

  /// Bumped on every socket swap so a dead socket's late `done`/`onError`
  /// cannot tear down the connection that replaced it.
  int _generation = 0;

  /// Asynchronous events QEMU pushes (`SHUTDOWN`, `RESET`, `STOP`, …).
  ///
  /// Survives a reconnect: consumers keep the same stream across a blink and
  /// only see it end when the client is terminally closed.
  Stream<Map<String, dynamic>> get events => _events.stream;

  /// Whether commands can be sent right now.
  ///
  /// False while reconnecting — the client is not gone, but it also cannot
  /// carry an action, and reporting "connected" there is what made a rig look
  /// ready while every action failed.
  bool get isConnected => _state == QmpConnectionState.connected;

  /// The current connection state.
  QmpConnectionState get connectionState => _state;

  /// Connection-state transitions, starting with the CURRENT state.
  ///
  /// Replaying the current value on subscribe is deliberate: a watchdog that
  /// attaches to an already-reconnecting client must not have to guess.
  Stream<QmpConnectionState> get connectionStates async* {
    yield _state;
    yield* _states.stream;
  }

  /// Round-trips `query-status` and returns QEMU's own run state (`running`,
  /// `paused`, `prelaunch`, …).
  ///
  /// The cheap liveness probe: one command, no side effects, and it fails the
  /// same way every other command does when the space is gone — which is
  /// what makes a dead-but-undetected socket detectable at all.
  Future<String> ping({Duration timeout = const Duration(seconds: 5)}) async {
    final status = await execute('query-status', timeout: timeout);
    final state = status['status'];
    if (state is String && state.isNotEmpty) {
      return state;
    }
    return status['running'] == true ? 'running' : 'unknown';
  }

  /// Runs [command] with [arguments] and returns its `return` payload.
  ///
  /// Throws [QmpException] when QEMU answers with an error, when the socket
  /// closes with the command in flight, or when a reconnect is in progress —
  /// the message says which, because "try again in a moment" and "this rig is
  /// gone" are different instructions to whoever reads it.
  Future<Map<String, dynamic>> execute(
    String command, {
    Map<String, dynamic>? arguments,
    Duration timeout = const Duration(seconds: 20),
  }) => _execute(command, arguments: arguments, timeout: timeout);

  Future<Map<String, dynamic>> _execute(
    String command, {
    Map<String, dynamic>? arguments,
    Duration timeout = const Duration(seconds: 20),
    bool duringHandshake = false,
  }) {
    if (_state == QmpConnectionState.closed) {
      return Future.error(
        QmpException('QMP socket is closed (command: $command)'),
      );
    }
    if (_state == QmpConnectionState.reconnecting && !duringHandshake) {
      return Future.error(
        QmpException(
          'QMP socket died; a reconnect is in progress (command: $command)',
        ),
      );
    }
    final id = _nextId++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    final payload = jsonEncode({
      'execute': command,
      if (arguments != null && arguments.isNotEmpty) 'arguments': arguments,
      'id': id,
    });
    try {
      _socket.write('$payload\n');
    } on Object catch (e) {
      _pending.remove(id);
      return Future.error(QmpException('QMP write failed: $e'));
    }
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        throw QmpException('QMP command "$command" timed out');
      },
    );
  }

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /// Pauses the guest's vCPUs. Frees CPU, NOT memory — a stopped guest still
  /// holds its RAM, which is why the reaper counts megabytes rather than VMs.
  Future<void> stop() async {
    await execute('stop');
  }

  /// Resumes a stopped guest.
  Future<void> cont() async {
    await execute('cont');
  }

  /// Asks the guest to power down through ACPI. Polite: a guest that ignores
  /// it stays up, so callers follow with a hard [quit] on a deadline.
  Future<void> systemPowerdown() async {
    _expectShutdown = true;
    await execute('system_powerdown');
  }

  /// Terminates the QEMU process immediately.
  ///
  /// The reply never arrives — QEMU exits while answering — so a timeout here
  /// is the expected case, not a failure.
  Future<void> quit() async {
    _expectShutdown = true;
    try {
      await execute('quit', timeout: const Duration(seconds: 2));
    } on Object {
      // Expected: the process died before it could answer.
    }
  }

  /// Whether the guest is currently running (as opposed to paused/stopped).
  Future<bool> isRunning() async {
    final status = await execute('query-status');
    return status['running'] as bool? ?? false;
  }

  // ── Input injection ─────────────────────────────────────────────────────

  /// Moves the pointer to absolute guest coordinates.
  ///
  /// Absolute positioning needs a `virtio-tablet` (or usb-tablet) in the
  /// machine: a plain PS/2 mouse only reports deltas, so "click at (412, 180)"
  /// is unimplementable and the pointer drifts. The backend always adds one.
  Future<void> moveTo({
    required int x,
    required int y,
    required int displayWidth,
    required int displayHeight,
  }) async {
    // The absolute axis is a fixed 0..32767 range regardless of the guest's
    // resolution, so coordinates are scaled rather than passed through.
    int scale(int value, int extent) {
      if (extent <= 1) {
        return 0;
      }
      final scaled = (value * 32767 / (extent - 1)).round();
      return scaled.clamp(0, 32767);
    }

    await _sendInputEvents([
      {
        'type': 'abs',
        'data': {'axis': 'x', 'value': scale(x, displayWidth)},
      },
      {
        'type': 'abs',
        'data': {'axis': 'y', 'value': scale(y, displayHeight)},
      },
    ]);
  }

  /// Presses or releases a mouse button.
  Future<void> mouseButton(RigMouseButton button, {required bool down}) =>
      _sendInputEvents([
        {
          'type': 'btn',
          'data': {'down': down, 'button': _qemuButton(button)},
        },
      ]);

  /// Presses [qemuKeys] and LEAVES THEM DOWN.
  ///
  /// `send-key` is press-and-release in one command, so it cannot express a
  /// modifier held across a separate event. `input-send-event` key events can:
  /// they carry an explicit `down`, which is the only way a ctrl-click is a
  /// ctrl-click rather than a ctrl press followed by a plain click.
  ///
  /// Every hold must be paired with a [releaseKeys] — a modifier left down
  /// stays down for the rest of the VM's life, and every later keystroke in
  /// that guest is silently a different chord.
  Future<void> holdKeys(List<String> qemuKeys) =>
      _sendKeyEvents(qemuKeys, down: true);

  /// Releases [qemuKeys], in reverse press order.
  Future<void> releaseKeys(List<String> qemuKeys) =>
      _sendKeyEvents(qemuKeys.reversed.toList(), down: false);

  /// Clicks with [modifierKeys] held down for the whole click.
  Future<void> clickWithModifiers(
    RigMouseButton button, {
    required List<String> modifierKeys,
    int clicks = 1,
  }) async {
    if (modifierKeys.isEmpty) {
      return click(button, clicks: clicks);
    }
    await holdKeys(modifierKeys);
    try {
      await click(button, clicks: clicks);
    } finally {
      try {
        await releaseKeys(modifierKeys);
      } on Object catch (e) {
        // Swallowed on purpose: when the click failed, ITS error is the
        // actionable one, and letting a release failure replace it would
        // report a broken control space as the reason the click did not
        // land. The space is already gone, so the modifier is moot.
        CcInfraLog.warning('rig/qmp: modifier release failed: $e');
      }
    }
  }

  /// Presses and releases a mouse button [clicks] times.
  Future<void> click(RigMouseButton button, {int clicks = 1}) async {
    for (var i = 0; i < clicks; i++) {
      await mouseButton(button, down: true);
      await mouseButton(button, down: false);
      if (i + 1 < clicks) {
        // Between the presses of a double/triple click. Comfortably under the
        // usual 400-500ms double-click threshold, comfortably above the
        // event-loop noise floor.
        await Future<void>.delayed(const Duration(milliseconds: 60));
      }
    }
  }

  /// Whether this QEMU accepts the horizontal wheel buttons.
  ///
  /// `wheel-left`/`wheel-right` only entered QEMU's `InputButton` enum in 7.1;
  /// an older build rejects them with a QMP parameter error and the scroll
  /// silently does nothing. Probed once on first use rather than parsed out of
  /// `-version` (a distro build's version string is not a reliable statement
  /// about which enum members it carries) and remembered, so a host that lacks
  /// them costs one failed command per session, not one per scroll.
  bool? _horizontalWheel;

  /// Scrolls by [amount] wheel clicks in [direction].
  Future<void> scroll(RigScrollDirection direction, {int amount = 3}) async {
    final horizontal =
        direction == RigScrollDirection.left ||
        direction == RigScrollDirection.right;
    if (horizontal && _horizontalWheel == false) {
      await _scrollHorizontalWithShift(direction, amount);
      return;
    }
    final button = switch (direction) {
      RigScrollDirection.up => 'wheel-up',
      RigScrollDirection.down => 'wheel-down',
      RigScrollDirection.left => 'wheel-left',
      RigScrollDirection.right => 'wheel-right',
    };
    for (var i = 0; i < amount; i++) {
      try {
        await _sendInputEvents([
          {
            'type': 'btn',
            'data': {'down': true, 'button': button},
          },
          {
            'type': 'btn',
            'data': {'down': false, 'button': button},
          },
        ]);
      } on QmpException catch (e) {
        if (!horizontal) {
          rethrow;
        }
        // The one recoverable case: this QEMU has no horizontal wheel.
        _horizontalWheel = false;
        CcInfraLog.info(
          'rig/qmp: this QEMU has no $button button ($e) — using '
          'shift+wheel for horizontal scroll instead.',
        );
        await _scrollHorizontalWithShift(direction, amount - i);
        return;
      }
      if (horizontal) {
        _horizontalWheel = true;
      }
    }
  }

  /// Horizontal scroll on a QEMU with no horizontal wheel.
  ///
  /// Shift+wheel is the X11/GTK convention every desktop toolkit in the guest
  /// images honours, so it moves the same content the real button would. It is
  /// a fallback, not the default: it goes through the guest's key handling and
  /// an application that rebinds shift+wheel will do that instead.
  Future<void> _scrollHorizontalWithShift(
    RigScrollDirection direction,
    int amount,
  ) async {
    if (amount <= 0) {
      return;
    }
    // Shift+wheel-down scrolls right in the GTK/Qt convention.
    final button = direction == RigScrollDirection.right
        ? 'wheel-down'
        : 'wheel-up';
    await holdKeys(const ['shift']);
    try {
      for (var i = 0; i < amount; i++) {
        await _sendInputEvents([
          {
            'type': 'btn',
            'data': {'down': true, 'button': button},
          },
          {
            'type': 'btn',
            'data': {'down': false, 'button': button},
          },
        ]);
      }
    } finally {
      try {
        await releaseKeys(const ['shift']);
      } on Object catch (e) {
        // Same reasoning as the modifier click above: the scroll's own error
        // is the actionable one, and a stuck shift on a dead space is moot.
        CcInfraLog.warning('rig/qmp: shift release failed: $e');
      }
    }
  }

  /// Sends a key combination expressed in QEMU key names (already translated
  /// from the X11-style names the action layer accepts).
  ///
  /// [holdMs] keeps the keys down; QEMU's own `hold-time` is what makes an
  /// auto-repeat happen inside the guest rather than us faking N presses.
  Future<void> sendKeys(List<String> qemuKeys, {int? holdMs}) async {
    if (qemuKeys.isEmpty) {
      return;
    }
    await execute(
      'send-key',
      arguments: {
        'keys': [
          for (final k in qemuKeys) {'type': 'qcode', 'data': k},
        ],
        'hold-time': ?holdMs,
      },
    );
  }

  /// Writes the current framebuffer to [path] as PPM.
  ///
  /// The FALLBACK capture path only. The guest agent's own capture is
  /// preferred because it can scale in the guest and encode there; screendump
  /// writes a full-size uncompressed file to the host's disk on every frame,
  /// which is fine for one screenshot and ruinous for a stream.
  Future<void> screendump(String path) =>
      execute('screendump', arguments: {'filename': path});

  /// Closes the socket.
  ///
  /// Deliberate: this is what distinguishes a teardown from a socket death, so
  /// no reconnect is attempted afterwards and an in-flight redial stops.
  Future<void> close() async {
    if (_state == QmpConnectionState.closed) {
      return;
    }
    _setState(QmpConnectionState.closed);
    await _lines?.cancel();
    try {
      await _socket.close();
    } on Object {
      // Already gone.
    }
    _socket.destroy();
    _failPending(const QmpException('QMP socket closed'));
    if (!_greeting.isCompleted) {
      _greeting.completeError(const QmpException('QMP socket closed'));
    }
    if (!_events.isClosed) {
      await _events.close();
    }
  }

  Future<void> _sendInputEvents(List<Map<String, dynamic>> events) async {
    await execute('input-send-event', arguments: {'events': events});
  }

  Future<void> _sendKeyEvents(
    List<String> qemuKeys, {
    required bool down,
  }) async {
    if (qemuKeys.isEmpty) {
      return;
    }
    await _sendInputEvents([
      for (final k in qemuKeys)
        {
          'type': 'key',
          'data': {
            'down': down,
            'key': {'type': 'qcode', 'data': k},
          },
        },
    ]);
  }

  static String _qemuButton(RigMouseButton button) => switch (button) {
    RigMouseButton.left => 'left',
    RigMouseButton.right => 'right',
    RigMouseButton.middle => 'middle',
  };

  void _onLine(String line) {
    if (line.trim().isEmpty) {
      return;
    }
    Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(line);
      if (decoded is! Map<String, dynamic>) {
        return;
      }
      message = decoded;
    } on FormatException {
      CcInfraLog.warning('rig/qmp: dropping unparseable line: $line');
      return;
    }

    if (message.containsKey('QMP')) {
      if (!_greeting.isCompleted) {
        _greeting.complete();
      }
      return;
    }
    if (message.containsKey('event')) {
      if (message['event'] == 'SHUTDOWN') {
        // QEMU is on its way out and says so. The socket death that follows is
        // that exit, so there is nothing to reconnect to.
        _expectShutdown = true;
      }
      if (!_events.isClosed) {
        _events.add(message);
      }
      return;
    }

    final id = message['id'];
    final completer = id is int ? _pending.remove(id) : null;
    if (completer == null) {
      // A reply with no matching id: either a race with a timed-out command or
      // a QEMU build that echoes something unexpected. Neither is actionable,
      // but silence would hide a protocol drift.
      CcInfraLog.debug('rig/qmp: reply with no pending command: $line');
      return;
    }
    final error = message['error'];
    if (error is Map) {
      completer.completeError(
        QmpException(
          error['desc'] as String? ?? 'Unknown QMP error',
          qmpClass: error['class'] as String?,
        ),
      );
      return;
    }
    final result = message['return'];
    completer.complete(
      result is Map<String, dynamic> ? result : <String, dynamic>{},
    );
  }

  // ── Connection lifecycle ────────────────────────────────────────────────

  /// Wires the current socket's stream and failure paths.
  ///
  /// The socket's WRITE failures surface on its `done` future, not at the
  /// `write()` call site — a teardown against a QEMU that already died (EPIPE)
  /// otherwise becomes an uncaught zone error that survives every try/catch
  /// around `execute`, crashing the server on shutdown.
  void _bind() {
    final generation = _generation;
    final socket = _socket;
    unawaited(
      socket.done.catchError((Object e) {
        if (generation == _generation) {
          _handleDeath('QMP socket died: $e');
        }
      }),
    );
    _lines = utf8.decoder
        .bind(socket.stream)
        .transform(const LineSplitter())
        .listen(
          _onLine,
          onDone: () {
            if (generation == _generation) {
              _handleDeath('QEMU closed the QMP socket');
            }
          },
          onError: (Object e) {
            if (generation == _generation) {
              _handleDeath('QMP socket error: $e');
            }
          },
        );
  }

  /// The socket died on its own. Redial when there is somewhere to redial to,
  /// otherwise go terminal exactly as before.
  void _handleDeath(String reason) {
    if (_state != QmpConnectionState.connected) {
      // Already closed, or already redialling — a dying socket reports itself
      // through several spaces (done, onDone, onError) and only the first
      // one is news.
      return;
    }
    final policy = _reconnect;
    if (policy == null) {
      _terminate(QmpException(reason));
      return;
    }
    if (_expectShutdown) {
      // We asked this machine to go away (or QEMU announced its own SHUTDOWN),
      // so the socket dying is the answer, not a fault. Redialling it would
      // spend the whole window failing against a process that is gone and log
      // a warning on every ordinary teardown.
      CcInfraLog.debug('rig/qmp: $reason (expected — QEMU is shutting down)');
      _terminate(QmpException('$reason (QEMU is shutting down)'));
      return;
    }
    _setState(QmpConnectionState.reconnecting);
    // The message has to say a reconnect is under way: the caller's next move
    // ("retry" vs "give up on this rig") depends on it.
    _failPending(QmpException('$reason; a QMP reconnect is in progress'));
    CcInfraLog.warning('rig/qmp: $reason — reconnecting');
    unawaited(_redial(policy));
  }

  Future<void> _redial(QmpReconnectPolicy policy) async {
    final deadline = DateTime.now().add(policy.window);
    var attempt = 0;
    while (_state == QmpConnectionState.reconnecting) {
      final delay = policy.backoff.isEmpty
          ? Duration.zero
          : policy.backoff[attempt.clamp(0, policy.backoff.length - 1)];
      attempt++;
      await Future<void>.delayed(delay);
      if (_state != QmpConnectionState.reconnecting) {
        // `close()` won the race; a teardown must not be undone by a redial.
        return;
      }
      try {
        final socket = await policy.connect();
        if (_state != QmpConnectionState.reconnecting) {
          // `close()` won while we were dialling. Adopting now would revive a
          // client the caller already tore down.
          socket.destroy();
          return;
        }
        await _adopt(socket, policy);
        _setState(QmpConnectionState.connected);
        CcInfraLog.info('rig/qmp: reconnected after $attempt attempt(s)');
        return;
      } on Object catch (e) {
        // The FIRST failure is the diagnosis; the rest are the same failure
        // once per backoff step, and logging them all buries it.
        if (attempt == 1) {
          CcInfraLog.warning('rig/qmp: reconnect failed: $e');
        } else {
          CcInfraLog.debug('rig/qmp: reconnect attempt $attempt failed: $e');
        }
      }
      if (!DateTime.now().isBefore(deadline)) {
        break;
      }
    }
    if (_state != QmpConnectionState.reconnecting) {
      return;
    }
    _terminate(
      QmpException(
        'QMP reconnect gave up after ${policy.window.inSeconds}s '
        '($attempt attempt(s))',
      ),
    );
  }

  /// Swaps in [socket] and replays the greeting/`qmp_capabilities` handshake.
  ///
  /// A fresh QEMU socket refuses every command until the handshake runs, so a
  /// reconnect that skips it hands back a client that looks alive and answers
  /// nothing.
  Future<void> _adopt(QmpSocket socket, QmpReconnectPolicy policy) async {
    await _lines?.cancel();
    try {
      _socket.destroy();
    } on Object {
      // The old socket is why we are here.
    }
    _generation++;
    _socket = socket;
    _greeting = _freshGreeting();
    _bind();
    await _greeting.future.timeout(
      policy.handshakeTimeout,
      onTimeout: () =>
          throw const QmpException('No QMP greeting on the reconnected socket'),
    );
    await _execute('qmp_capabilities', duringHandshake: true);
  }

  void _terminate(QmpException error) {
    if (_state == QmpConnectionState.closed) {
      return;
    }
    _setState(QmpConnectionState.closed);
    _failPending(error);
    if (!_greeting.isCompleted) {
      _greeting.completeError(error);
    }
    if (!_events.isClosed) {
      unawaited(_events.close());
    }
  }

  void _setState(QmpConnectionState state) {
    if (_state == state || _state == QmpConnectionState.closed) {
      // `closed` is terminal by contract: nothing may revive a client whose
      // caller has already torn it down.
      return;
    }
    _state = state;
    if (!_states.isClosed) {
      _states.add(state);
      if (state == QmpConnectionState.closed) {
        // Delivered first: a broadcast controller flushes what was added
        // before it closes.
        unawaited(_states.close());
      }
    }
  }

  /// A greeting completer nobody is required to await.
  ///
  /// `QmpClient.over` skips the handshake, so the greeting future often has no
  /// listener — and a completer completed with an error and no listener is
  /// reported as an unhandled zone error, which would turn a socket death into
  /// a crash.
  static Completer<void> _freshGreeting() {
    final completer = Completer<void>();
    unawaited(completer.future.catchError((Object _) {}));
    return completer;
  }

  void _failPending(QmpException error) {
    final pending = _pending.values.toList();
    _pending.clear();
    for (final c in pending) {
      if (!c.isCompleted) {
        c.completeError(error);
      }
    }
  }
}
