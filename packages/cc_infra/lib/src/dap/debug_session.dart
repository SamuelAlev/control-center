import 'dart:async';

import 'package:cc_infra/src/dap/dap_adapter_registry.dart';
import 'package:cc_infra/src/dap/dap_client.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// Where a debuggee stopped.
class DebugStop {
  /// Creates a [DebugStop].
  const DebugStop({
    required this.reason,
    required this.threadId,
    this.description,
    this.text,
  });

  /// `breakpoint`, `step`, `exception`, `pause`, …
  final String reason;

  /// The thread that stopped, or null when the adapter did not say.
  final int? threadId;

  /// A human sentence from the adapter.
  final String? description;

  /// Extra detail (an exception message, typically).
  final String? text;
}

/// One live debug session: adapter process, capabilities, event state.
///
/// **Bounded like a rig, and for the same reason.** A debug adapter owns a
/// stopped process holding whatever that process holds — a port, a lock, a
/// database connection. A session nobody is driving is a leak that outlives
/// the turn that started it, so there is a hard TTL the debuggee cannot extend
/// and exactly ONE session per conversation: an agent that launches a second
/// without terminating the first has almost certainly lost track of the first.
class DebugSession {
  /// Creates a [DebugSession].
  DebugSession({
    required this.id,
    required this.adapter,
    required DapClient client,
    required this.workingDirectory,
    this.ttl = const Duration(minutes: 30),
  }) : _client = client,
       startedAt = DateTime.now() {
    _eventSub = _client.events.listen(_onEvent);
    // The adapter asks US to do things — `runInTerminal` above all. An
    // unanswered reverse request is how a launch silently never starts: the
    // adapter waits for a reply that is never coming and reports nothing, so
    // the honest answer is a refusal it can act on.
    _reverseSub = _client.reverseRequests.listen((req) {
      CcInfraLog.info('dap: refusing reverse request ${req.command}');
      _client.respond(req.seq, req.command);
    });
    _ttlTimer = Timer(ttl, () {
      CcInfraLog.info('dap: session $id hit its TTL');
      unawaited(terminate());
    });
  }

  /// Stable id, reported to the model.
  final String id;

  /// Which adapter is driving.
  final ResolvedDapAdapter adapter;

  /// The project root.
  final String workingDirectory;

  /// How long the session may live.
  final Duration ttl;

  /// When it started.
  final DateTime startedAt;

  final DapClient _client;
  late final StreamSubscription<DapEvent> _eventSub;
  late final StreamSubscription<
    ({String command, Map<String, dynamic> arguments, int seq})
  >
  _reverseSub;
  Timer? _ttlTimer;

  Map<String, dynamic> _capabilities = const {};
  final _initialized = Completer<void>();
  var _configured = false;
  int? _pendingEntryThread;

  /// Bumped on every REAL stop. A deferred entry-release captures the epoch
  /// when it is scheduled and must not fire if a real stop has landed since —
  /// see [_onEvent].
  int _stopEpoch = 0;
  final _unverifiedBreakpoints = <int>{};
  Completer<void>? _breakpointsSettled;
  DebugStop? _lastStop;
  bool _terminated = false;
  final _output = <String>[];
  final _stopped = StreamController<DebugStop>.broadcast();

  /// What the adapter said it supports.
  Map<String, dynamic> get capabilities => _capabilities;

  /// The most recent stop, or null while running.
  DebugStop? get lastStop => _lastStop;

  /// Whether the debuggee is stopped at a frame.
  bool get isStopped => _lastStop != null;

  /// Whether the session has ended.
  bool get isTerminated => _terminated || _client.isDead;

  /// Debuggee stdout/stderr, most recent last, bounded.
  List<String> get output => List.unmodifiable(_output);

  /// Fires on every `stopped` event.
  Stream<DebugStop> get stops => _stopped.stream;

  /// The underlying client, for requests this class does not wrap.
  DapClient get client => _client;

  /// Resolves when the adapter says it is ready for configuration.
  ///
  /// **The ordering this exists to enforce.** DAP's configuration sequence is
  /// `initialize` → wait for the `initialized` EVENT → `setBreakpoints` →
  /// `configurationDone`. Sending breakpoints before that event is the classic
  /// mistake: several adapters simply drop them, the program runs to
  /// completion, and the only symptom is a breakpoint that never fires —
  /// indistinguishable from code that never ran.
  ///
  /// Times out rather than hanging, because an adapter that never sends it is
  /// one we would otherwise wait on forever, and configuring late is better
  /// than not configuring.
  Future<void> waitInitialized({
    Duration timeout = const Duration(seconds: 15),
  }) => _initialized.future.timeout(timeout, onTimeout: () {});

  /// Performs the DAP handshake and returns the adapter's capabilities.
  Future<Map<String, dynamic>> initialize() async {
    _capabilities = await _client.request('initialize', {
      'clientID': 'control-center',
      'clientName': 'Control Center',
      'adapterID': adapter.spec.id,
      'pathFormat': 'path',
      'linesStartAt1': true,
      'columnsStartAt1': true,
      'supportsVariableType': true,
      'supportsRunInTerminalRequest': false,
    });
    return _capabilities;
  }

  /// Records breakpoints the adapter accepted but has not yet bound.
  ///
  /// **Why this has to be tracked at all.** A `setBreakpoints` response can
  /// come back `verified: false, reason: pending` — the adapter has taken the
  /// request but the VM has not mapped it to a real location yet, and it
  /// confirms later with a `breakpoint` event. Resuming the entry pause before
  /// that confirmation lets the program run straight past the breakpoint, and
  /// the symptom is a `launch` that reports the program exiting with no
  /// explanation of why the breakpoint never fired.
  void noteBreakpoints(Iterable<({int id, bool verified})> breakpoints) {
    for (final breakpoint in breakpoints) {
      if (!breakpoint.verified) {
        _unverifiedBreakpoints.add(breakpoint.id);
      }
    }
  }

  /// Waits for every pending breakpoint to bind, or [timeout].
  ///
  /// Times out rather than hanging: a breakpoint on a line that will never
  /// compile stays pending forever, and refusing to start the program over it
  /// would be worse than starting without it.
  Future<void> waitForBreakpoints({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_unverifiedBreakpoints.isEmpty) {
      return;
    }
    final settled = _breakpointsSettled ??= Completer<void>();
    await settled.future.timeout(timeout, onTimeout: () {});
  }

  /// Sends `configurationDone` when the adapter asked for it.
  ///
  /// Conditional on the capability, not sent blindly: an adapter that did not
  /// advertise it answers with an error, and an error here reads as "the launch
  /// failed" when the launch was fine.
  Future<void> configurationDone() async {
    if (_capabilities['supportsConfigurationDoneRequest'] == true) {
      await _client.request('configurationDone');
    }
    _configured = true;
    // An `entry` pause that arrived while we were still configuring is
    // released now — see [_onEvent] for why it is never surfaced as a stop.
    final thread = _pendingEntryThread;
    _pendingEntryThread = null;
    if (thread != null) {
      // Held until the breakpoints bind: releasing the isolate first is what
      // makes it run past them.
      final epoch = _stopEpoch;
      await waitForBreakpoints();
      // A real stop (a breakpoint, usually) may have landed for this thread
      // while the breakpoints settled — the release must not drive the
      // thread THROUGH it, leaving a stop nobody can read a stack from.
      if (_stopEpoch == epoch) {
        await _resume(thread);
      }
    }
  }

  /// Continues [threadId], swallowing an adapter that has already moved on.
  Future<void> _resume(int threadId) async {
    try {
      await _client.request('continue', {'threadId': threadId});
    } on Object {
      // The program may have terminated between the stop and this call; that
      // is a finished run, not a failure to report.
    }
  }

  /// Ends the session and kills the adapter.
  ///
  /// Best-effort in order: ask politely (`disconnect`), then kill. An adapter
  /// that will not disconnect must not keep the debuggee's process alive —
  /// that is a stopped process holding a port with nobody watching it.
  Future<void> terminate() async {
    if (_terminated) {
      return;
    }
    _terminated = true;
    _ttlTimer?.cancel();
    _ttlTimer = null;
    try {
      await _client.request('disconnect', {
        'terminateDebuggee': true,
      }, const Duration(seconds: 5));
    } on Object {
      // Expected often enough not to be worth a log line: an adapter that has
      // already exited cannot answer its own disconnect.
    }
    await _eventSub.cancel();
    await _reverseSub.cancel();
    await _client.close();
    await _stopped.close();
  }

  void _onEvent(DapEvent event) {
    switch (event.event) {
      case 'initialized':
        if (!_initialized.isCompleted) {
          _initialized.complete();
        }
      case 'stopped':
        final stop = DebugStop(
          reason: event.body['reason'] as String? ?? 'unknown',
          threadId: (event.body['threadId'] as num?)?.toInt(),
          description: event.body['description'] as String?,
          text: event.body['text'] as String?,
        );
        // **An `entry` pause is configuration, not a place anyone asked to
        // look.** Several adapters (Dart's among them) pause the isolate at
        // entry so a client can set breakpoints, then continue. Surfacing it
        // as THE stop is a bug with a confusing symptom: `launch` reports
        // "Stopped: entry", the adapter resumes a moment later, and the very
        // next `stack` fails with "thread is not paused" — which reads as a
        // broken debugger rather than as an answer about the wrong pause.
        // So it is released rather than reported, and the caller waits for
        // the breakpoint it actually set.
        if (stop.reason == 'entry') {
          final thread = stop.threadId;
          if (thread == null) {
            break;
          }
          if (_configured) {
            final epoch = _stopEpoch;
            unawaited(
              waitForBreakpoints().then((_) {
                // A real stop for this thread since scheduling means the
                // isolate is already somewhere worth looking; the release
                // would resume it THROUGH that stop.
                if (_stopEpoch == epoch) {
                  _resume(thread);
                }
              }),
            );
          } else {
            // Breakpoints are not in yet; releasing now would run past them.
            _pendingEntryThread = thread;
          }
          break;
        }
        _stopEpoch++;
        _lastStop = stop;
        // A real stop supersedes any deferred entry-release still pending for
        // that thread — configurationDone checks the epoch before resuming.
        if (_pendingEntryThread == stop.threadId) {
          _pendingEntryThread = null;
        }
        if (!_stopped.isClosed) {
          _stopped.add(stop);
        }
      case 'breakpoint':
        final breakpoint = event.body['breakpoint'];
        if (breakpoint is Map && breakpoint['verified'] == true) {
          final id = (breakpoint['id'] as num?)?.toInt();
          if (id != null) {
            _unverifiedBreakpoints.remove(id);
          }
          if (_unverifiedBreakpoints.isEmpty) {
            final settled = _breakpointsSettled;
            if (settled != null && !settled.isCompleted) {
              settled.complete();
            }
          }
        }
      case 'continued':
        _lastStop = null;
      case 'output':
        final text = event.body['output'];
        if (text is String && text.isNotEmpty) {
          // Bounded: a debuggee in a print loop would otherwise grow this
          // without limit for the whole TTL.
          if (_output.length >= 500) {
            _output.removeAt(0);
          }
          _output.add(text.trimRight());
        }
      case 'terminated':
      case 'exited':
        _lastStop = null;
        _terminated = true;
        if (!_initialized.isCompleted) {
          // An adapter that died before configuring must not leave a launch
          // waiting on an event that can no longer arrive.
          _initialized.complete();
        }
    }
  }
}

/// Owns the debug sessions on this host, one per conversation.
class DebugSessionSupervisor {
  /// Creates a [DebugSessionSupervisor].
  DebugSessionSupervisor({this.ttl = const Duration(minutes: 30)});

  /// How long a session may live.
  final Duration ttl;

  final Map<String, DebugSession> _sessions = {};

  /// The live session for [key], or null.
  DebugSession? sessionFor(String key) {
    final session = _sessions[key];
    if (session == null) {
      return null;
    }
    if (session.isTerminated) {
      _sessions.remove(key);
      return null;
    }
    return session;
  }

  /// Every live session.
  List<DebugSession> get sessions =>
      _sessions.values.where((s) => !s.isTerminated).toList();

  /// Starts an adapter for [key], replacing nothing: an existing live session
  /// is an error, not something to silently discard.
  Future<DebugSession> start({
    required String key,
    required ResolvedDapAdapter adapter,
    required String workingDirectory,
    Map<String, String>? environment,
  }) async {
    final existing = sessionFor(key);
    if (existing != null) {
      throw StateError(
        'a debug session is already running here (${existing.adapter.spec.id}) '
        '— terminate it first',
      );
    }
    final client = await DapClient.start(
      command: adapter.executable,
      args: adapter.spec.args,
      workingDirectory: workingDirectory,
      environment: environment,
      name: 'dap:${adapter.spec.id}',
    );
    final session = DebugSession(
      id: '${adapter.spec.id}-${_sessions.length + 1}',
      adapter: adapter,
      client: client,
      workingDirectory: workingDirectory,
      ttl: ttl,
    );
    _sessions[key] = session;
    try {
      await session.initialize();
    } on Object {
      _sessions.remove(key);
      await session.terminate();
      rethrow;
    }
    return session;
  }

  /// Ends the session for [key], if any.
  Future<void> stop(String key) async {
    final session = _sessions.remove(key);
    await session?.terminate();
  }

  /// Ends every session. Call on server shutdown — an orphaned adapter holds a
  /// stopped debuggee and answers to nobody.
  Future<void> dispose() async {
    final all = List.of(_sessions.values);
    _sessions.clear();
    for (final session in all) {
      await session.terminate();
    }
  }
}
