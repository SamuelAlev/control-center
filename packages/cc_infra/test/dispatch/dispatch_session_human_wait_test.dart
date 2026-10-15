import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/task_lifecycle_events.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:clock/clock.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

class _WaitingClaude implements SandboxPort {
  final started = Completer<void>();
  final _exited = Completer<int>();
  final _events = StreamController<SandboxEvent>.broadcast();
  bool destroyed = false;
  final destroying = Completer<void>();
  Completer<void>? destroyRelease;

  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) => _events.stream;

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
  }) {
    stdinStream?.listen((_) {});
    onPid?.call(42);
    started.complete();
    return _exited.future;
  }

  Future<void> finish() async {
    _events.add(
      SandboxEvent(
        type: SandboxEventType.stdout,
        content: jsonEncode({
          'type': 'result',
          'is_error': false,
          'result': 'ok',
        }),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    _exited.complete(0);
  }

  @override
  Future<void> destroy(SandboxHandle handle) async {
    destroyed = true;
    if (!_exited.isCompleted) {
      _exited.complete(-15);
    }
    destroying.complete();
    await destroyRelease?.future;
  }

  Future<void> dispose() => _events.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Fixture {
  _Fixture(this.temp, this.now, this.bus, this.sandbox);

  final Directory temp;
  DateTime now;
  final DomainEventBus bus;
  final _WaitingClaude sandbox;
  Timer? timer;
  void Function(Timer)? tickCallback;

  void tick() {
    final callback = tickCallback;
    final activeTimer = timer;
    expect(callback, isNotNull);
    expect(activeTimer, isNotNull);
    callback!(activeTimer!);
  }

  void advance(Duration elapsed) => now = now.add(elapsed);

  AgentAwaitingInput question(
    String id, {
    String workspace = 'ws-1',
    String conversation = 'conv-1',
    String agent = 'agent-1',
    AgentInputKind kind = AgentInputKind.question,
  }) => AgentAwaitingInput(
    workspaceId: workspace,
    waitId: id,
    kind: kind,
    summary: 'Need an answer',
    conversationId: conversation,
    agentId: agent,
    occurredAt: now,
  );

  AgentInputResolved resolved(String id, {String workspace = 'ws-1'}) =>
      AgentInputResolved(workspaceId: workspace, waitId: id, occurredAt: now);

  DispatchSession session() => DispatchSession(
    deps: SandboxDispatchDeps(
      sandbox: sandbox,
      broker: _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: null,
      eventBus: bus,
      resolveGitIdentity: (_, {workspaceId}) async =>
          (name: 'Test User', email: 'test@example.test'),
      backendRegistry: BackendRegistry({'claude': const ClaudeCliBackend()}),
    ),
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
    dispatchId: 'dispatch-1',
    cliName: 'claude',
    prompt: 'hello',
    agentDirHostPath: temp.path,
    modelId: null,
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    mode: Mode.chat,
    resolveBinary: (name) async => '/usr/local/bin/$name',
  );
}

Future<void> _exercise(Future<void> Function(_Fixture) scenario) async {
  final temp = Directory.systemTemp.createTempSync('cc_human_wait_');
  final bus = DomainEventBus();
  final sandbox = _WaitingClaude();
  final fixture = _Fixture(temp, DateTime.utc(2026, 10, 12), bus, sandbox);
  try {
    await withClock(
      Clock(() => fixture.now),
      () => runZoned(
        () => scenario(fixture),
        zoneSpecification: ZoneSpecification(
          createPeriodicTimer: (self, parent, zone, duration, callback) {
            if (duration == DispatchSession.silenceCheckInterval) {
              fixture.tickCallback = callback;
              // Drive only the watchdog; never wait fifteen real minutes.
              return fixture.timer = parent.createPeriodicTimer(
                zone,
                const Duration(days: 365),
                callback,
              );
            }
            return parent.createPeriodicTimer(zone, duration, callback);
          },
        ),
      ),
    );
  } finally {
    bus.dispose();
    await sandbox.dispose();
    await deleteDirBestEffort(temp);
  }
}

Future<void> _deliver() => Future<void>.delayed(Duration.zero);

void main() {
  test(
    'a genuine unanswered question survives silence and a normal answer resumes the run',
    () => _exercise((f) async {
      final session = f.session();
      final events = <AgentProcessEvent>[];
      final sub = session.controller.stream.listen(events.add);
      final run = session.run();
      await f.sandbox.started.future;
      f.bus.publish(f.question('question-1'));
      await _deliver();

      f.advance(const Duration(minutes: 31));
      f.tick();
      expect(f.sandbox.destroyed, isFalse);
      expect(
        events.whereType<ErrorEvent>().where(
          (e) => e.content.contains('Agent silent'),
        ),
        isEmpty,
      );

      f.bus.publish(f.resolved('question-1'));
      await _deliver();
      f.advance(const Duration(minutes: 14));
      f.tick();
      expect(f.sandbox.destroyed, isFalse);

      await f.sandbox.finish();
      await run;
      expect(f.sandbox.destroyed, isFalse);
      expect(session.silenceTimer, isNull);
      // Terminal cleanup must leave no watchdog behind for later waits.
      f.bus.publish(f.question('after-completion'));
      f.advance(const Duration(hours: 2));
      expect(session.silenceTimer, isNull);
      await sub.cancel();
    }),
  );

  test(
    'overlapping waits reset silence only after the final matching resolution',
    () => _exercise((f) async {
      final session = f.session();
      final run = session.run();
      await f.sandbox.started.future;
      f.bus.publish(f.question('first'));
      f.bus.publish(f.question('second'));
      await _deliver();
      f.advance(const Duration(minutes: 16));
      f.bus.publish(f.resolved('first'));
      await _deliver();
      f.tick();
      expect(f.sandbox.destroyed, isFalse);
      f.advance(const Duration(minutes: 16));
      f.tick();
      expect(f.sandbox.destroyed, isFalse);
      f.bus.publish(f.resolved('second', workspace: 'ws-2'));
      await _deliver();
      f.tick();
      expect(f.sandbox.destroyed, isFalse);

      f.bus.publish(f.resolved('second'));
      await _deliver();
      f.tick();
      expect(f.sandbox.destroyed, isFalse);
      final timedOut = f.bus.on<TaskMessage>().firstWhere(
        (event) => event.content.startsWith('Silent run'),
      );
      f.advance(const Duration(minutes: 15));
      f.tick();
      await run;
      await timedOut;
      expect(f.sandbox.destroyed, isTrue);
      expect(session.silenceTimer, isNull);
    }),
  );

  test(
    'unrelated waits do not shield a genuinely silent agent',
    () => _exercise((f) async {
      final session = f.session();
      final run = session.run();
      await f.sandbox.started.future;
      f.bus.publish(f.question('wrong-workspace', workspace: 'ws-2'));
      f.bus.publish(f.question('wrong-conversation', conversation: 'conv-2'));
      f.bus.publish(f.question('wrong-agent', agent: 'agent-2'));
      f.bus.publish(f.question('approval', kind: AgentInputKind.approval));
      f.bus.publish(f.resolved('unknown'));
      await _deliver();
      final timedOut = f.bus.on<TaskMessage>().firstWhere(
        (event) => event.content.startsWith('Silent run'),
      );
      f.advance(const Duration(minutes: 16));
      f.tick();
      await run;
      await timedOut;
      expect(f.sandbox.destroyed, isTrue);
      expect(session.silenceTimer, isNull);
    }),
  );

  test(
    'stop cancels subscriptions and watchdog while a question is pending',
    () => _exercise((f) async {
      final session = f.session();
      final run = session.run();
      await f.sandbox.started.future;
      f.bus.publish(f.question('question-1'));
      await _deliver();
      await session.stop();
      expect(session.silenceTimer, isNull);
      f.bus.publish(f.resolved('question-1'));
      f.bus.publish(f.question('after-stop'));
      await _deliver();
      f.advance(const Duration(hours: 2));
      expect(f.sandbox.destroyed, isFalse);
      await f.sandbox.finish();
      await run;
    }),
  );

  test(
    'manual stop owns the result when SIGTERM exits before teardown finishes',
    () => _exercise((f) async {
      final release = Completer<void>();
      f.sandbox.destroyRelease = release;
      final session = f.session();
      final events = <AgentProcessEvent>[];
      final streamDone = session.controller.stream
          .listen(events.add)
          .asFuture<void>();
      final lifecycle = <TaskLifecycleEvent>[];
      final subscription = f.bus.on<TaskLifecycleEvent>().listen(lifecycle.add);
      final run = session.run();
      await f.sandbox.started.future;
      final stop = session.terminate();
      try {
        await f.sandbox.destroying.future;
        // The process exits while sandbox destruction is still draining.
        await run;
        f.sandbox._events.add(
          const SandboxEvent(
            type: SandboxEventType.stdout,
            content: '{"type":"stream_event"}',
          ),
        );
        f.sandbox._events.add(
          const SandboxEvent(
            type: SandboxEventType.stderr,
            content: 'shutdown stderr',
          ),
        );
        f.sandbox._events.add(
          const SandboxEvent(type: SandboxEventType.killed),
        );
        await _deliver();
      } finally {
        release.complete();
        await stop;
        await streamDone;
        await _deliver();
        await subscription.cancel();
      }

      expect(events.whereType<ErrorEvent>().map((e) => e.content), [
        contains('user request'),
      ]);
      expect(events.whereType<TextEvent>(), isEmpty);
      expect(events.whereType<DoneEvent>(), hasLength(1));
      expect(
        lifecycle.whereType<TaskFailed>().single.errorMessage,
        contains('user request'),
      );
      expect(lifecycle.whereType<TaskCompleted>(), isEmpty);
    }),
  );

  test(
    'SIGTERM without a stop request remains a process failure',
    () => _exercise((f) async {
      final session = f.session();
      final events = <AgentProcessEvent>[];
      final streamDone = session.controller.stream
          .listen(events.add)
          .asFuture<void>();
      final run = session.run();
      await f.sandbox.started.future;
      f.sandbox._exited.complete(-15);
      await run;
      await streamDone;

      expect(events.whereType<ErrorEvent>().map((e) => e.content), [
        contains('exited with code -15'),
      ]);
      expect(events.whereType<DoneEvent>(), hasLength(1));
    }),
  );

  test(
    'terminate drops a pending question without leaving a watchdog behind',
    () => _exercise((f) async {
      final session = f.session();
      final run = session.run();
      await f.sandbox.started.future;
      f.bus.publish(f.question('question-1'));
      await _deliver();
      await session.terminate();
      await run;
      expect(session.silenceTimer, isNull);
      expect(f.sandbox.destroyed, isTrue);
      f.bus.publish(f.resolved('question-1'));
      f.bus.publish(f.question('after-termination'));
      await _deliver();
      expect(session.silenceTimer, isNull);
    }),
  );
}
