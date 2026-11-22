// The fake `claude` binary is a `#!/bin/sh` script, which Windows cannot
// exec.
@TestOn('!windows')
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';
import 'package:clock/clock.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Claude Code's own background Bash tasks (defect 24): a turn that ends
/// while one is live keeps stdin open, with the silence watchdog paused only
/// while the run is idle, up to 600 s from the turn's end; the run yields
/// to waiting work and a stop ends the wait at once; the tasks never open an
/// agent row.

/// A `claude` that answers its first prompt with [firstTurn] and runs until
/// its stdin closes; the test prints the rest.
class _Sandbox implements SandboxPort {
  _Sandbox(this.firstTurn);

  final List<String> firstTurn;
  StreamController<SandboxEvent>? _events;
  Completer<int>? _running;
  int prompts = 0;
  bool stdinClosed = false;

  /// Every frame written to stdin, by `type` (and control `subtype`).
  final frames = <String>[];

  void print(String line) =>
      _events?.add(SandboxEvent(type: SandboxEventType.stdout, content: line));

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) {
    // ignore: close_sinks, lives as long as the fake run.
    final controller = StreamController<SandboxEvent>.broadcast();
    _events = controller;
    return controller.stream;
  }

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
    Stream<String>? stdinStream,
  }) async {
    final running = Completer<int>();
    _running = running;
    stdinStream?.listen(
      (raw) {
        final frame = jsonDecode(raw) as Map<String, dynamic>;
        final request = frame['request'];
        frames.add(
          request is Map
              ? '${frame['type']}:${request['subtype']}'
              : '${frame['type']}',
        );
        if (frame['type'] == 'user' && prompts++ == 0) {
          scheduleMicrotask(() => firstTurn.forEach(print));
        }
      },
      onDone: () {
        stdinClosed = true;
        if (!running.isCompleted) {
          running.complete(0);
        }
      },
    );
    onPid?.call(4242);
    final code = await running.future;
    await Future<void>.delayed(Duration.zero);
    _events?.add(const SandboxEvent(type: SandboxEventType.exit));
    return code;
  }

  @override
  Future<void> destroy(SandboxHandle handle) async {
    final running = _running;
    if (running != null && !running.isCompleted) {
      running.complete(-15);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _init() => jsonEncode({
  'type': 'system',
  'subtype': 'init',
  'session_id': 'sess-1',
  'tools': ['Bash'],
  'mcp_servers': const [],
});

String _success() => jsonEncode({
  'type': 'result',
  'is_error': false,
  'result': 'ok',
  'usage': {'input_tokens': 1, 'output_tokens': 1},
  'total_cost_usd': 0.25,
});

// The task lifecycle lines as `claude_subagent_runs_test.dart` records them.
String _bashStarted(String taskId) => jsonEncode({
  'type': 'system',
  'subtype': 'task_started',
  'task_id': taskId,
  'tool_use_id': 'tu_$taskId',
  'task_type': 'local_bash',
});

String _bashNotified(String taskId) => jsonEncode({
  'type': 'system',
  'subtype': 'task_notification',
  'task_id': taskId,
  'tool_use_id': 'tu_$taskId',
  'status': 'completed',
});

/// Lets the session's timers tick a few times in real time.
Future<void> _ticks() => Future<void>.delayed(const Duration(milliseconds: 30));

Future<void> _until(bool Function() condition) async {
  for (var i = 0; i < 400 && !condition(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(condition(), isTrue);
}

void main() {
  late Directory temp;
  late String claude;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('cc_claude_background_');
    final file = File('${temp.path}/claude')
      ..writeAsStringSync('#!/bin/sh\necho "2.1.316 (Claude Code)"\n');
    Process.runSync('/bin/chmod', ['+x', file.path]);
    claude = file.path;
  });

  tearDown(() => deleteDirBestEffort(temp));

  DispatchSession build(_Sandbox sandbox) {
    final deps = SandboxDispatchDeps(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: sandbox,
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: null,
      eventBus: null,
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
    );
    return DispatchSession(
      freshHistory: false,
      readOnly: false,
      deps: deps,
      onResolveHandle:
          ({
            required String sessionId,
            required SandboxSpec spec,
            required void Function(AgentProcessEvent) emit,
          }) async => SandboxHandle(
            sessionId: sessionId,
            backend: SandboxBackend.none,
            state: SandboxState.warm,
          ),
      onScheduleCooldown: (_) {},
      dispatchId: 'd-claude-bg',
      cliName: 'claude',
      prompt: 'run the tests in the background',
      agentId: null,
      userText: 'run the tests in the background',
      agentDirHostPath: temp.path,
      modelId: null,
      callerEnv: const {},
      workspaceId: 'ws-1',
      spaceId: 'space-1',
      conversationId: 'conv-1',
      runLogId: 'run-1',
      mode: Mode.chat,
      // A one-minute window: the waits below last up to an hour.
      silenceTimeoutMinutes: 1,
      resolveBinary: (_) async => claude,
    )..silenceCheckEvery = const Duration(milliseconds: 5);
  }

  /// Runs [session] on a clock the test moves; returns its events and the
  /// run's future.
  ({Future<List<AgentProcessEvent>> events, Future<void> done}) start(
    DispatchSession session,
    DateTime Function() now,
  ) {
    final events = session.controller.stream.toList();
    final done = withClock(
      Clock(now),
      () => session.run(),
    ).timeout(const Duration(seconds: 30));
    return (events: events, done: done);
  }

  List<String> debug(List<AgentProcessEvent> events) => [
    for (final e in events.whereType<DebugEvent>()) e.content,
  ];

  test('the parser reports a Bash task and opens no agent row', () {
    final subagent = <ClaudeSubagentEvent>[];
    final tasks = <ClaudeBackgroundTaskEvent>[];
    ClaudeStreamJsonParser(
        ClaudeStreamJsonCallbacks(
          onSubagent: subagent.add,
          onBackgroundTask: tasks.add,
        ),
      )
      ..process(jsonDecode(_bashStarted('b1')) as Map<String, dynamic>)
      ..process({
        'type': 'system',
        'subtype': 'task_updated',
        'task_id': 'b1',
        'patch': {'status': 'running'},
      })
      ..process({
        'type': 'system',
        'subtype': 'task_updated',
        'task_id': 'b1',
        'patch': {'status': 'killed'},
      })
      ..process(jsonDecode(_bashNotified('b1')) as Map<String, dynamic>);
    expect(subagent, isEmpty);
    expect(tasks, hasLength(2));
    expect(tasks.first, isA<ClaudeBackgroundTaskStarted>());
    expect(
      tasks.last,
      isA<ClaudeBackgroundTaskEnded>().having(
        (e) => e.status,
        'status',
        'killed',
      ),
    );
  });

  test('stdin stays open past the turn until task_notification, and the '
      'watchdog does not fire meanwhile', () async {
    var now = DateTime.utc(2026, 11, 19, 9);
    final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
    final session = build(sandbox);
    final run = start(session, () => now);

    await _until(() => session.parked);
    expect(session.acceptsSteering, isTrue);
    expect(session.heldForBackgroundOnly, isTrue);
    // Nine minutes of nothing: far past the one-minute window.
    for (var minute = 0; minute < 9; minute++) {
      now = now.add(const Duration(minutes: 1));
      await _ticks();
    }
    expect(sandbox.stdinClosed, isFalse, reason: 'held for the task');
    expect(session.parked, isTrue);

    // The task finishes and the CLI continues by itself with a turn.
    sandbox
      ..print(_bashNotified('b1'))
      ..print(_success());
    await run.done;
    final events = await run.events;
    const waiting =
        '[claude] waiting for 1 background task(s) to finish before the turn '
        'ends (at most 10 min).';

    expect(sandbox.stdinClosed, isTrue);
    expect(session.parked, isFalse);
    final done = events.whereType<DoneEvent>().single;
    expect(done.endReason, isNot(RunEndReason.silence));
    expect(
      debug(events),
      containsAll([
        '[claude] background task b1 started',
        waiting,
        '[claude] background task b1 ended (completed)',
      ]),
    );
  });

  test(
    'a task that never ends: the run settles 600 s after the turn',
    () async {
      var now = DateTime.utc(2026, 11, 19, 9);
      final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
      final session = build(sandbox);
      final run = start(session, () => now);

      await _until(() => session.parked);
      now = now.add(const Duration(seconds: 599));
      await _ticks();
      expect(sandbox.stdinClosed, isFalse);
      now = now.add(const Duration(seconds: 1));
      await run.done;
      final events = await run.events;

      expect(sandbox.stdinClosed, isTrue);
      expect(
        debug(events),
        contains(
          '[claude] background tasks still running 10 min after the turn; '
          'ending the turn.',
        ),
      );
      expect(
        events.whereType<DoneEvent>().single.endReason,
        isNot(RunEndReason.silence),
      );
    },
  );

  test('a task that ends with no further turn closes stdin after the '
      'grace', () async {
    var now = DateTime.utc(2026, 11, 19, 9);
    final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
    final session = build(sandbox);
    final run = start(session, () => now);

    await _until(() => session.parked);
    sandbox.print(_bashNotified('b1'));
    await _ticks();
    now = now.add(const Duration(seconds: 30));
    await _ticks();
    expect(sandbox.stdinClosed, isFalse, reason: 'inside the grace');
    now = now.add(const Duration(seconds: 31));
    await run.done;
    expect(sandbox.stdinClosed, isTrue);
  });

  test('a turn with no live task closes stdin at its result', () async {
    final sandbox = _Sandbox([
      _init(),
      _bashStarted('b1'),
      _bashNotified('b1'),
      _success(),
    ]);
    final session = build(sandbox);
    final run = start(session, DateTime.now);
    await run.done;
    final events = await run.events;
    expect(sandbox.stdinClosed, isTrue);
    expect(debug(events), isNot(contains(startsWith('[claude] waiting'))));
  });

  test('steering restarts the watchdog: a turn that then goes silent ends '
      'on silence; the run is not held meanwhile', () async {
    var now = DateTime.utc(2026, 11, 19, 9);
    final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
    final session = build(sandbox);
    final run = start(session, () => now);

    await _until(() => session.parked);
    // As the steering queue service pushes it: on the server's one clock.
    expect(
      withClock(
        Clock(() => now),
        () => session.steer('and then?', source: null),
      ),
      isTrue,
    );
    await _until(() => !session.parked);
    expect(session.heldForBackgroundOnly, isFalse, reason: 'a turn runs');
    // The steered turn prints nothing for past the one-minute window.
    for (var i = 0; i < 3 && !sandbox.stdinClosed; i++) {
      now = now.add(const Duration(minutes: 1));
      await _ticks();
    }
    await run.done;
    final events = await run.events;
    expect(
      events.whereType<DoneEvent>().single.endReason,
      RunEndReason.silence,
    );
  });

  test('a line of the CLI during the wait is a turn: the watchdog runs '
      "again; its result holds again from that turn's end", () async {
    var now = DateTime.utc(2026, 11, 19, 9);
    final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
    final session = build(sandbox);
    final run = start(session, () => now);

    await _until(() => session.parked);
    now = now.add(const Duration(minutes: 8));
    await _ticks();
    sandbox.print(
      jsonEncode({
        'type': 'assistant',
        'message': {
          'role': 'assistant',
          'content': [
            {'type': 'text', 'text': 'still waiting'},
          ],
        },
      }),
    );
    await _until(() => !session.parked);
    sandbox.print(_success());
    await _until(() => session.parked);
    // Eight more minutes: inside the new turn's bound.
    now = now.add(const Duration(minutes: 8));
    await _ticks();
    expect(sandbox.stdinClosed, isFalse);
    now = now.add(const Duration(minutes: 2));
    await run.done;
    expect(sandbox.stdinClosed, isTrue);
  });

  test('a yield ends the wait at once and the run settles; it reports '
      'itself held until then', () async {
    final now = DateTime.utc(2026, 11, 19, 9);
    final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
    final session = build(sandbox);
    final run = start(session, () => now);

    await _until(() => session.parked);
    session.yieldBackgroundHold();
    expect(session.heldForBackgroundOnly, isTrue);
    expect(session.acceptsSteering, isFalse);
    await run.done;
    final events = await run.events;
    expect(sandbox.stdinClosed, isTrue);
    expect(
      events.whereType<DoneEvent>().single.endReason,
      isNot(RunEndReason.silence),
    );
    expect(
      debug(events),
      contains(
        '[claude] work is waiting for this agent: ending the wait for '
        'background tasks.',
      ),
    );
  });

  test('a stop ends the wait at once, with no interrupt to wait out', () async {
    final now = DateTime.utc(2026, 11, 19, 9);
    final sandbox = _Sandbox([_init(), _bashStarted('b1'), _success()]);
    final session = build(sandbox);
    final run = start(session, () => now);

    await _until(() => session.parked);
    final watch = Stopwatch()..start();
    await session.terminate();
    await run.done;
    final events = await run.events;
    expect(watch.elapsed, lessThan(const Duration(seconds: 2)));
    expect(sandbox.stdinClosed, isTrue);
    expect(sandbox.frames, isNot(contains('control_request:interrupt')));
    expect(
      events.whereType<DoneEvent>().single.endReason,
      RunEndReason.stoppedByUser,
    );
  });
}
