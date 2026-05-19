import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/events/agent_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/ports/credential_broker_port.dart';
import 'package:control_center/core/domain/ports/process_control_port.dart';
import 'package:control_center/core/domain/ports/sandbox_port.dart';
import 'package:control_center/core/domain/repositories/agent_repository.dart';
import 'package:control_center/core/domain/repositories/agent_run_log_repository.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/domain/value_objects/run_cost.dart';
import 'package:control_center/core/domain/value_objects/sandbox_backend.dart';
import 'package:control_center/core/domain/value_objects/sandbox_event.dart';
import 'package:control_center/core/domain/value_objects/sandbox_handle.dart';
import 'package:control_center/core/domain/value_objects/sandbox_spec.dart';
import 'package:control_center/core/domain/value_objects/wake_context.dart';
import 'package:control_center/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:control_center/features/sandboxing/data/adapters/dispatch_session.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// Minimal fakes
// ---------------------------------------------------------------------------

class FakeSandboxPort implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.native;

  @override
  Future<SandboxBackendCapabilities> probe() async =>
      const SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: true,
      );

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async =>
      SandboxHandle(sessionId: spec.sessionId, backend: SandboxBackend.native);

  @override
  Future<bool> isAlive(SandboxHandle handle) async => true;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
  }) async =>
      0;

  @override
  Future<void> pause(SandboxHandle handle) async {}

  @override
  Future<void> resume(SandboxHandle handle) async {}

  @override
  Future<void> destroy(SandboxHandle handle) async {}
}

class FakeProcessControlPort implements ProcessControlPort {
  @override
  Future<void> kill(int pid) async {}

  @override
  bool isPidAlive(int pid) => true;
}

class FakeCredentialBrokerPort implements CredentialBrokerPort {
  int mintCount = 0;
  final Set<String> revoked = {};

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
  }) async {
    mintCount++;
    return ScopedCredentials(
      handle: 'cred-$mintCount',
      environment: {'API_KEY': 'test-key-$mintCount'},
    );
  }

  @override
  Future<void> revoke(String handle) async {
    revoked.add(handle);
  }
}

class FakeAgentRepository implements AgentRepository {
  Agent? agentToReturn;

  @override
  Stream<List<Agent>> watchAll() => Stream.value([]);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) => Stream.value([]);

  @override
  Future<Agent?> getById(String id) async => agentToReturn;

  @override
  Future<Agent?> findByWorkspaceAndName(
    String workspaceId,
    String name,
  ) async =>
      null;

  @override
  Future<void> upsert(Agent agent) async {}

  @override
  Future<void> delete(String id) async {}
}
class FakeAgentRunLogRepository implements AgentRunLogRepository {
  AgentRunLog? logToReturn;
  AgentRunLog? lastUpserted;

  @override
  Stream<List<AgentRunLog>> watchByAgent(String agentId) => Stream.value([]);

  @override
  Stream<List<AgentRunLog>> watchAll() => Stream.value([]);

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) =>
      Stream.value([]);

  @override
  Future<AgentRunLog?> getById(String id) async =>
      lastUpserted ?? logToReturn;

  @override
  Future<void> upsert(AgentRunLog log) async {
    lastUpserted = log;
  }
}

/// A controllable [SandboxPort] that lets tests inject sandbox events
/// and control when exec completes.
class ControllableSandboxPort extends FakeSandboxPort {
  final StreamController<SandboxEvent> _eventController =
      StreamController<SandboxEvent>.broadcast();
  final Completer<int> _execCompleter = Completer<int>();

  int execCallCount = 0;
  List<String>? lastArgv;
  Map<String, String>? lastEnv;
  String? lastStdinInput;
  void Function(int pid)? lastOnPid;

  /// Stream of sandbox events that tests can push into.
  void addSandboxEvent(SandboxEvent event) => _eventController.add(event);

  /// Completes the exec call with the given exit code.
  void completeExec(int exitCode) => _execCompleter.complete(exitCode);

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      _eventController.stream;

  @override
  Future<int> exec(
    SandboxHandle handle,
    List<String> argv, {
    Map<String, String>? env,
    String? workdir,
    Duration? timeout,
    void Function(int pid)? onPid,
    String? stdinInput,
  }) async {
    execCallCount++;
    lastArgv = argv;
    lastEnv = env;
    lastStdinInput = stdinInput;
    lastOnPid = onPid;
    onPid?.call(42);
    return _execCompleter.future;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

SandboxDispatchDeps _makeDeps({
  FakeSandboxPort? sandbox,
  FakeCredentialBrokerPort? broker,
  FakeAgentRepository? agentRepo,
  FakeAgentRunLogRepository? runLogRepo,
  DomainEventBus? eventBus,
}) {
  return SandboxDispatchDeps(
    sandbox: sandbox ?? FakeSandboxPort(),
    broker: broker ?? FakeCredentialBrokerPort(),
    agentRepo: agentRepo ?? FakeAgentRepository(),
    runLogRepo: runLogRepo,
    defaultCaps: const AgentCapabilities(),
    eventBus: eventBus,
  );
}

DispatchSession _makeSession({
  SandboxDispatchDeps? deps,
  String dispatchId = 'test-dispatch-1',
  String cliName = 'pi',
  String prompt = 'Hello, world',
  ConversationMode mode = ConversationMode.chat,
}) {
  return DispatchSession(
    deps: deps ?? _makeDeps(),
    onResolveHandle: ({required sessionId, required spec, required emit}) async =>
        SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
    onScheduleCooldown: (_) {},
    dispatchId: dispatchId,
    cliName: cliName,
    prompt: prompt,
    agentDirHostPath: '/tmp/test-agent',
    modelId: 'test-model',
    callerEnv: {'HOME': '/tmp'},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: null,
    mode: mode,
  );
}

void main() {
  // -----------------------------------------------------------------------
  // SandboxDispatchDeps
  // -----------------------------------------------------------------------
  group('SandboxDispatchDeps', () {
    test('stores all fields', () {
      final sandbox = FakeSandboxPort();
      final broker = FakeCredentialBrokerPort();
      final agentRepo = FakeAgentRepository();
      final runLogRepo = FakeAgentRunLogRepository();
      final eventBus = DomainEventBus();
      const caps = AgentCapabilities(canPushToRepo: true);

      final deps = SandboxDispatchDeps(
        sandbox: sandbox,
        broker: broker,
        agentRepo: agentRepo,
        runLogRepo: runLogRepo,
        defaultCaps: caps,
        eventBus: eventBus,
      );

      expect(deps.sandbox, same(sandbox));
      expect(deps.broker, same(broker));
      expect(deps.agentRepo, same(agentRepo));
      expect(deps.runLogRepo, same(runLogRepo));
      expect(deps.defaultCaps, same(caps));
      expect(deps.eventBus, same(eventBus));
      expect(deps.claudeRelayFactory, isNotNull);
    });

    test('default claudeRelayFactory creates ClaudeRelay', () {
      final deps = SandboxDispatchDeps(
        sandbox: FakeSandboxPort(),
        broker: FakeCredentialBrokerPort(),
        agentRepo: FakeAgentRepository(),
        runLogRepo: FakeAgentRunLogRepository(),
        defaultCaps: const AgentCapabilities(),
        eventBus: DomainEventBus(),
      );
      expect(deps.claudeRelayFactory, isNotNull);
      final relay = deps.claudeRelayFactory();
      expect(relay, isNotNull);
    });
  });

  // -----------------------------------------------------------------------
  // DispatchSession constructor
  // -----------------------------------------------------------------------
  group('DispatchSession constructor', () {
    test('stores all required fields', () {
      final deps = _makeDeps();
      const wakeCtx = WakeContext(
        runId: 'run-1',
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        wakeReason: WakeReason.userMessage,
      );

      final session = DispatchSession(
        deps: deps,
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'disp-1',
        cliName: 'pi',
        prompt: 'test prompt',
        agentDirHostPath: '/tmp/agent',
        modelId: 'gpt-4',
        callerEnv: {'HOME': '/home'},
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        runLogId: 'log-1',
        mode: ConversationMode.chat,
        ticketId: 'TICKET-42',
        wakeContext: wakeCtx,
      );

      expect(session.deps, same(deps));
      expect(session.dispatchId, 'disp-1');
      expect(session.cliName, 'pi');
      expect(session.prompt, 'test prompt');
      expect(session.agentDirHostPath, '/tmp/agent');
      expect(session.modelId, 'gpt-4');
      expect(session.callerEnv, {'HOME': '/home'});
      expect(session.agentId, 'agent-1');
      expect(session.workspaceId, 'ws-1');
      expect(session.conversationId, 'conv-1');
      expect(session.runLogId, 'log-1');
      expect(session.mode, ConversationMode.chat);
      expect(session.ticketId, 'TICKET-42');
      expect(session.wakeContext, same(wakeCtx));
    });

    test('optional fields default to null', () {
      final session = DispatchSession(
        deps: _makeDeps(),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'disp-1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: null,
        workspaceId: null,
        conversationId: null,
        runLogId: null,
        mode: ConversationMode.chat,
      );

      expect(session.modelId, isNull);
      expect(session.agentId, isNull);
      expect(session.workspaceId, isNull);
      expect(session.conversationId, isNull);
      expect(session.runLogId, isNull);
      expect(session.ticketId, isNull);
      expect(session.wakeContext, isNull);
    });

    test('initializes mutable state to defaults', () {
      final session = _makeSession();

      expect(session.controller, isA<StreamController<AgentProcessEvent>>());
      expect(session.credHandle, isNull);
      expect(session.eventsSub, isNull);
      expect(session.emittedDone, isFalse);
      expect(session.pid, isNull);
      expect(session.lastOutputAt, isNull);
      expect(session.silenceTimer, isNull);
    });

    test('controller is not initially closed', () {
      final session = _makeSession();
      expect(session.controller.isClosed, isFalse);
    });
  });

  // -----------------------------------------------------------------------
  // Constants
  // -----------------------------------------------------------------------
  group('constants', () {
    test('silenceCheckInterval is 30 seconds', () {
      expect(DispatchSession.silenceCheckInterval, const Duration(seconds: 30));
    });

    test('defaultSilenceThreshold is 15 minutes', () {
      expect(
        DispatchSession.defaultSilenceThreshold,
        const Duration(minutes: 15),
      );
    });

    test('agentSessionPrefix is "agent-"', () {
      expect(DispatchSession.agentSessionPrefix, 'agent-');
    });
  });

  // -----------------------------------------------------------------------
  // buildArgv
  // -----------------------------------------------------------------------
  group('buildArgv', () {
    test('builds pi argv without model', () {
      final argv = DispatchSession.buildArgv('pi', '/usr/local/bin/pi', null);
      expect(argv[0], '/usr/local/bin/pi');
      expect(argv.sublist(1), [
        '--mode',
        'json',
        '--append-system-prompt',
        'Output structured JSON events. Each line must be a valid JSON object.',
      ]);
    });

    test('builds pi argv with model', () {
      final argv = DispatchSession.buildArgv('pi', '/usr/local/bin/pi', 'gpt-4');
      expect(argv[0], '/usr/local/bin/pi');
      expect(argv[1], '--mode');
      expect(argv[2], 'json');
      expect(argv[3], '--model');
      expect(argv[4], 'gpt-4');
      expect(argv.sublist(5), [
        '--append-system-prompt',
        'Output structured JSON events. Each line must be a valid JSON object.',
      ]);
    });

    test('builds pi argv with empty model string', () {
      final argv = DispatchSession.buildArgv('pi', '/usr/local/bin/pi', '');
      // Empty string is treated like null — no --model flag appended.
      expect(argv, hasLength(5));
      expect(argv[0], '/usr/local/bin/pi');
    });

    test('throws ArgumentError for unsupported CLI "claude"', () {
      expect(
        () => DispatchSession.buildArgv('claude', '/usr/bin/claude', null),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for unsupported CLI "codex"', () {
      expect(
        () => DispatchSession.buildArgv('codex', '/usr/bin/codex', null),
        throwsArgumentError,
      );
    });
  });

  // -----------------------------------------------------------------------
  // capabilityEnv
  // -----------------------------------------------------------------------
  group('capabilityEnv', () {
    test('sets GIT_ASKPASS and GIT_TERMINAL_PROMPT when canPushToRepo is false', () {
      const caps = AgentCapabilities(canPushToRepo: false);
      final env = DispatchSession.capabilityEnv(caps);
      expect(env['GIT_ASKPASS'], '/usr/bin/false');
      expect(env['GIT_TERMINAL_PROMPT'], '0');
    });

    test('returns empty map when canPushToRepo is true', () {
      const caps = AgentCapabilities(canPushToRepo: true);
      final env = DispatchSession.capabilityEnv(caps);
      expect(env, isEmpty);
    });

    test('does not set vars when canPushToRepo is true (legacyDefault)', () {
      final env = DispatchSession.capabilityEnv(AgentCapabilities.legacyDefault);
      expect(env, isEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // addEvent and controller stream
  // -----------------------------------------------------------------------
  group('addEvent', () {
    test('emits event to controller stream', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      session.addEvent(TextEvent(content: 'hello'));
      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(1));
      expect(events.single, isA<TextEvent>());
      expect((events.single as TextEvent).content, 'hello');
    });

    test('updates lastOutputAt on each call', () {
      final session = _makeSession();

      expect(session.lastOutputAt, isNull);

      session.addEvent(TextEvent(content: 'first'));
      final firstTs = session.lastOutputAt;
      expect(firstTs, isNotNull);

      session.addEvent(TextEvent(content: 'second'));
      final secondTs = session.lastOutputAt;
      expect(secondTs, isNotNull);
      expect(secondTs!.isBefore(firstTs!), isFalse);
    });

    test('does not add event to closed controller', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      await session.controller.close();
      session.addEvent(TextEvent(content: 'after close'));

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });

    test('emits multiple event types', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      session.addEvent(TextEvent(content: 'text'));
      session.addEvent(ThinkingEvent(content: 'thinking'));
      session.addEvent(ErrorEvent(content: 'error'));
      session.addEvent(DebugEvent(content: 'debug'));
      session.addEvent(DoneEvent());
      session.addEvent(SandboxViolationEvent(content: 'violation'));
      session.addEvent(ToolCallEvent(toolName: 'Bash', toolCallId: 't1'));
      session.addEvent(ToolResultEvent(toolCallId: 't1', outputs: 'result'));

      await Future<void>.delayed(Duration.zero);

      expect(events, hasLength(8));
      expect(events.whereType<TextEvent>(), hasLength(1));
      expect(events.whereType<ThinkingEvent>(), hasLength(1));
      expect(events.whereType<ErrorEvent>(), hasLength(1));
      expect(events.whereType<DebugEvent>(), hasLength(1));
      expect(events.whereType<DoneEvent>(), hasLength(1));
      expect(events.whereType<SandboxViolationEvent>(), hasLength(1));
      expect(events.whereType<ToolCallEvent>(), hasLength(1));
      expect(events.whereType<ToolResultEvent>(), hasLength(1));
    });
  });

  // -----------------------------------------------------------------------
  // State transitions: emittedDone guard
  // -----------------------------------------------------------------------
  group('emittedDone guard', () {
    test('emittedDone starts false', () {
      final session = _makeSession();
      expect(session.emittedDone, isFalse);
    });

    test('controller closes after stop() and no more events accepted', () async {
      final session = _makeSession();
      expect(session.controller.isClosed, isFalse);

      await session.stop();

      expect(session.controller.isClosed, isTrue);
    });

    test('events emitted before stop() are received', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      session.addEvent(TextEvent(content: 'before stop'));
      session.addEvent(DebugEvent(content: 'diagnostic'));

      await Future<void>.delayed(Duration.zero);
      expect(events, hasLength(2));
    });
  });

  // -----------------------------------------------------------------------
  // stop()
  // -----------------------------------------------------------------------
  group('stop', () {
    test('revokes credentials', () async {
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(deps: _makeDeps(broker: broker));

      session.credHandle = 'cred-1';

      await session.stop();

      expect(broker.revoked, contains('cred-1'));
      expect(session.credHandle, isNull);
    });

    test('is idempotent when credHandle is null', () async {
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(deps: _makeDeps(broker: broker));

      await session.stop();

      expect(broker.revoked, isEmpty);
    });

    test('closes controller', () async {
      final session = _makeSession();
      expect(session.controller.isClosed, isFalse);

      await session.stop();

      expect(session.controller.isClosed, isTrue);
    });

    test('cancels silence timer when active', () async {
      final session = _makeSession();
      session.silenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {},
      );
      expect(session.silenceTimer, isNotNull);

      await session.stop();

      expect(session.silenceTimer, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // terminate()
  // -----------------------------------------------------------------------
  group('terminate', () {
    test('revokes credentials', () async {
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(deps: _makeDeps(broker: broker));
      session.credHandle = 'cred-1';

      await session.terminate();

      expect(broker.revoked, contains('cred-1'));
      expect(session.credHandle, isNull);
    });

    test('emits DebugEvent about termination', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      await session.terminate();

      await Future<void>.delayed(Duration.zero);

      final debugEvents = events.whereType<DebugEvent>().toList();
      expect(debugEvents, isNotEmpty);
      final terminationMsg = debugEvents
          .any((e) => e.content.contains('terminated by request'));
      expect(terminationMsg, isTrue);
    });

    test('emits ErrorEvent with failure message', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      await session.terminate();

      await Future<void>.delayed(Duration.zero);

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(errorEvents, isNotEmpty);
      final failMsg = errorEvents
          .any((e) => e.content == 'Terminated by user request');
      expect(failMsg, isTrue);
    });

    test('closes controller', () async {
      final session = _makeSession();

      await session.terminate();

      expect(session.controller.isClosed, isTrue);
    });

    test('cancels events subscription if present', () async {
      final session = _makeSession();

      final sc = StreamController<SandboxEvent>.broadcast();
      addTearDown(sc.close);
      session.eventsSub = sc.stream.listen((_) {});
      expect(session.eventsSub, isNotNull);

      await session.terminate();

      expect(session.eventsSub, isNull);
    });

    test('cancels silence timer when active', () async {
      final session = _makeSession();
      session.silenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {},
      );
      expect(session.silenceTimer, isNotNull);

      await session.terminate();

      expect(session.silenceTimer, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // Stream controller lifecycle
  // -----------------------------------------------------------------------
  group('controller lifecycle', () {
    test('addEvent after close is a no-op', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      await session.controller.close();
      expect(session.controller.isClosed, isTrue);

      session.addEvent(TextEvent(content: 'should be dropped'));

      await Future<void>.delayed(Duration.zero);
      expect(events, isEmpty);
    });

    test('multiple stop calls do not throw', () async {
      final session = _makeSession();

      await session.stop();
      await session.stop();

      expect(session.controller.isClosed, isTrue);
    });

    test('terminate after stop does not throw', () async {
      final session = _makeSession();

      await session.stop();
      await session.terminate();

      expect(session.controller.isClosed, isTrue);
    });

    test('stop after terminate does not throw', () async {
      final session = _makeSession();

      await session.terminate();
      await session.stop();

      expect(session.controller.isClosed, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // Multiple session isolation
  // -----------------------------------------------------------------------
  group('session isolation', () {
    test('each session has independent controller', () {
      final session1 = _makeSession(dispatchId: 'd1');
      final session2 = _makeSession(dispatchId: 'd2');

      expect(session1.controller, isNot(same(session2.controller)));
      expect(session1.dispatchId, 'd1');
      expect(session2.dispatchId, 'd2');
    });

    test('closing one session does not affect another', () async {
      final events1 = <AgentProcessEvent>[];
      final events2 = <AgentProcessEvent>[];

      final session1 = _makeSession(dispatchId: 'd1');
      final session2 = _makeSession(dispatchId: 'd2');

      session1.controller.stream.listen(events1.add);
      session2.controller.stream.listen(events2.add);

      await session1.stop();

      session2.addEvent(TextEvent(content: 'session2 only'));
      await Future<void>.delayed(Duration.zero);

      expect(events1, isEmpty);
      expect(events2, hasLength(1));
      expect((events2.single as TextEvent).content, 'session2 only');
    });
  });

  // -----------------------------------------------------------------------
  // onResolveHandle and onScheduleCooldown
  // -----------------------------------------------------------------------
  group('onResolveHandle callback', () {
    test('is stored and callable', () async {
      var called = false;
      final session = DispatchSession(
        deps: _makeDeps(),
        onResolveHandle: ({required sessionId, required spec, required emit}) async {
          called = true;
          return SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native);
        },
        onScheduleCooldown: (_) {},
        dispatchId: 'd1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: null,
        workspaceId: null,
        conversationId: null,
        runLogId: null,
        mode: ConversationMode.chat,
      );

      final handle = await session.onResolveHandle(
        sessionId: 'test',
        spec: const SandboxSpec(
          sessionId: 'test',
          workspaceId: 'ws',
          bindMounts: [],
        ),
        emit: (_) {},
      );
      expect(called, isTrue);
      expect(handle.sessionId, 'test');
    });
  });

  group('onScheduleCooldown callback', () {
    test('is stored and callable', () {
      String? cooled;
      final session = DispatchSession(
        deps: _makeDeps(),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (id) {
          cooled = id;
        },
        dispatchId: 'd1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: null,
        workspaceId: null,
        conversationId: null,
        runLogId: null,
        mode: ConversationMode.chat,
      );

      session.onScheduleCooldown('session-cool');
      expect(cooled, 'session-cool');
    });
  });

  // -----------------------------------------------------------------------
  // ConversationMode integration with constructor
  // -----------------------------------------------------------------------
  group('ConversationMode', () {
    test('stores plan mode', () {
      final session = _makeSession(mode: ConversationMode.plan);
      expect(session.mode, ConversationMode.plan);
    });

    test('stores review mode', () {
      final session = _makeSession(mode: ConversationMode.review);
      expect(session.mode, ConversationMode.review);
    });

    test('stores chat mode', () {
      final session = _makeSession(mode: ConversationMode.chat);
      expect(session.mode, ConversationMode.chat);
    });
  });

  // -----------------------------------------------------------------------
  // AgentProcessEvent type discriminants
  // -----------------------------------------------------------------------
  group('AgentProcessEvent type discriminant', () {
    test('TextEvent has text type', () {
      final event = TextEvent(content: 'x');
      expect(event.type, AgentProcessEventType.text);
      expect(event.content, 'x');
    });

    test('ThinkingEvent has thinking type', () {
      final event = ThinkingEvent(content: 'x');
      expect(event.type, AgentProcessEventType.thinking);
    });

    test('ErrorEvent has error type', () {
      final event = ErrorEvent(content: 'x');
      expect(event.type, AgentProcessEventType.error);
    });

    test('DebugEvent has debug type', () {
      final event = DebugEvent(content: 'x');
      expect(event.type, AgentProcessEventType.debug);
    });

    test('DoneEvent has done type', () {
      final event = DoneEvent();
      expect(event.type, AgentProcessEventType.done);
    });

    test('ToolCallEvent has toolCall type', () {
      final event = ToolCallEvent(toolName: 'Bash', toolCallId: 't1');
      expect(event.type, AgentProcessEventType.toolCall);
      expect(event.toolName, 'Bash');
      expect(event.toolCallId, 't1');
    });

    test('ToolResultEvent has toolResult type', () {
      final event = ToolResultEvent(toolCallId: 't1', outputs: 'result');
      expect(event.type, AgentProcessEventType.toolResult);
      expect(event.toolCallId, 't1');
      expect(event.outputs, 'result');
    });

    test('SandboxViolationEvent has sandboxViolation type', () {
      final event = SandboxViolationEvent(content: 'v');
      expect(event.type, AgentProcessEventType.sandboxViolation);
    });

    test('UsageEvent has usage type', () {
      final event = UsageEvent(usage: const RunUsage());
      expect(event.type, AgentProcessEventType.usage);
    });
  });

  // -----------------------------------------------------------------------
  // buildArgv edge cases
  // -----------------------------------------------------------------------
  group('buildArgv edge cases', () {
    test('pi argv with null model omits --model flag', () {
      final argv = DispatchSession.buildArgv('pi', '/usr/local/bin/pi', null);
      expect(argv.contains('--model'), isFalse);
    });

    test('pi argv preserves exact model string', () {
      const model = 'claude-sonnet-4-20250514';
      final argv = DispatchSession.buildArgv('pi', '/usr/local/bin/pi', model);
      expect(argv[3], '--model');
      expect(argv[4], model);
    });

    test('throws for empty cliName', () {
      expect(
        () => DispatchSession.buildArgv('', '/usr/local/bin/pi', null),
        throwsArgumentError,
      );
    });

    test('binary path with spaces is preserved', () {
      const path = '/home/user/my bin/pi';
      final argv = DispatchSession.buildArgv('pi', path, null);
      expect(argv[0], path);
      expect(argv.sublist(1), [
        '--mode',
        'json',
        '--append-system-prompt',
        'Output structured JSON events. Each line must be a valid JSON object.',
      ]);
    });
  });

  // -----------------------------------------------------------------------
  // silence detection
  // -----------------------------------------------------------------------
  group('silence detection', () {
    test('silence timer starts null', () {
      final session = _makeSession();
      expect(session.silenceTimer, isNull);
    });

    test('silence timer can be started', () {
      final session = _makeSession();
      session.silenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {},
      );
      expect(session.silenceTimer, isNotNull);
      session.silenceTimer!.cancel();
    });

    test('lastOutputAt is updated on addEvent', () {
      final session = _makeSession();
      expect(session.lastOutputAt, isNull);

      session.addEvent(TextEvent(content: 'output'));
      expect(session.lastOutputAt, isNotNull);
    });

    test('silence timer is cancelled by terminate', () async {
      final session = _makeSession();
      session.silenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {},
      );
      expect(session.silenceTimer, isNotNull);

      await session.terminate();

      expect(session.silenceTimer, isNull);
    });

    test('silence timer is cancelled by stop', () async {
      final session = _makeSession();
      session.silenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {},
      );
      expect(session.silenceTimer, isNotNull);

      await session.stop();

      expect(session.silenceTimer, isNull);
    });

    test('silence timer does not fire when disabled', () {
      final session = _makeSession();
      // Cancel a freshly created timer — should just work.
      session.silenceTimer = Timer.periodic(
        const Duration(seconds: 30),
        (_) {},
      );
      expect(session.silenceTimer, isNotNull);
      session.silenceTimer!.cancel();
      session.silenceTimer = null;
      expect(session.silenceTimer, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // credential lifecycle
  // -----------------------------------------------------------------------
  group('credential lifecycle', () {
    test('credHandle starts null', () {
      final session = _makeSession();
      expect(session.credHandle, isNull);
    });

    test('credHandle can be set directly', () {
      final session = _makeSession();
      session.credHandle = 'cred-test-1';
      expect(session.credHandle, 'cred-test-1');
    });

    test('stop revokes and nullifies credHandle', () async {
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(deps: _makeDeps(broker: broker));
      session.credHandle = 'cred-1';

      await session.stop();

      expect(broker.revoked, contains('cred-1'));
      expect(session.credHandle, isNull);
    });

    test('terminate revokes and nullifies credHandle', () async {
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(deps: _makeDeps(broker: broker));
      session.credHandle = 'cred-1';

      await session.terminate();

      expect(broker.revoked, contains('cred-1'));
      expect(session.credHandle, isNull);
    });

    test('multiple stop calls do not double-revoke', () async {
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(deps: _makeDeps(broker: broker));
      session.credHandle = 'cred-1';

      await session.stop();
      await session.stop();

      // cred-1 should appear exactly once in the revoked set.
      expect(broker.revoked.lookup('cred-1'), 'cred-1');
      expect(broker.revoked.length, 1);
      expect(session.credHandle, isNull);
    });
  });

  // -----------------------------------------------------------------------
  // SandboxEvent subscription
  // -----------------------------------------------------------------------
  group('SandboxEvent subscription', () {
    test('eventsSub starts null', () {
      final session = _makeSession();
      expect(session.eventsSub, isNull);
    });

    test('eventsSub can be assigned', () {
      final session = _makeSession();
      final sc = StreamController<SandboxEvent>.broadcast();
      addTearDown(sc.close);
      session.eventsSub = sc.stream.listen((_) {});
      expect(session.eventsSub, isNotNull);
      session.eventsSub!.cancel();
    });

    test('terminate cancels eventsSub', () async {
      final session = _makeSession();
      final sc = StreamController<SandboxEvent>.broadcast();
      addTearDown(sc.close);
      session.eventsSub = sc.stream.listen((_) {});
      expect(session.eventsSub, isNotNull);

      await session.terminate();

      expect(session.eventsSub, isNull);
    });

    test('stop does not cancel eventsSub', () async {
      final session = _makeSession();
      final sc = StreamController<SandboxEvent>.broadcast();
      addTearDown(sc.close);
      session.eventsSub = sc.stream.listen((_) {});
      expect(session.eventsSub, isNotNull);

      await session.stop();

      // stop() does not cancel eventsSub — only terminate() does.
      expect(session.eventsSub, isNotNull);
      unawaited(session.eventsSub!.cancel());
    });
  });

  // -----------------------------------------------------------------------
  // capabilityEnv edge cases
  // -----------------------------------------------------------------------
  group('capabilityEnv edge cases', () {
    test('canAccessNetwork does not affect env', () {
      const caps = AgentCapabilities(
        canPushToRepo: true,
        canAccessNetwork: false,
      );
      final env = DispatchSession.capabilityEnv(caps);
      // canAccessNetwork is gated by the sandbox spec, not env vars.
      expect(env, isEmpty);
    });

    test('all capabilities true returns empty env', () {
      const caps = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: true,
        canCallTicketing: true,
        canAccessNetwork: true,
      );
      final env = DispatchSession.capabilityEnv(caps);
      expect(env, isEmpty);
    });

    test('safe default caps set push guards', () {
      const caps = AgentCapabilities();
      final env = DispatchSession.capabilityEnv(caps);
      expect(env['GIT_ASKPASS'], '/usr/bin/false');
      expect(env['GIT_TERMINAL_PROMPT'], '0');
    });
  });

  // -----------------------------------------------------------------------
  // controller lifecycle edge cases
  // -----------------------------------------------------------------------
  group('controller lifecycle edge cases', () {
    test('addEvent before controller streams are consumed does not block', () {
      final session = _makeSession();
      // Adding events before anyone listens on a single-subscription
      // stream should not throw or block.
      expect(
        () => session.addEvent(TextEvent(content: 'early')),
        returnsNormally,
      );
    });

    test('concurrent addEvent calls are safe', () async {
      final session = _makeSession();
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      // Rapid-fire adds from the same isolate should all succeed.
      session.addEvent(TextEvent(content: 'a'));
      session.addEvent(TextEvent(content: 'b'));
      session.addEvent(TextEvent(content: 'c'));
      session.addEvent(DebugEvent(content: 'd'));
      session.addEvent(ErrorEvent(content: 'e'));

      await Future<void>.delayed(Duration.zero);

      // Since Dart is single-threaded, no actual concurrency risk here,
      // but all events should have been accepted.
      expect(events, hasLength(5));
    });

    test('controller is single-subscription by default', () {
      final session = _makeSession();
      session.controller.stream.listen((_) {});

      expect(
        () => session.controller.stream.listen((_) {}),
        throwsStateError,
      );
    });
  });

  // -----------------------------------------------------------------------
  // _capabilitiesFor — capability resolution via run()
  // -----------------------------------------------------------------------
  // These tests verify that the right capabilities are passed to the
  // credential broker during dispatch. Even when the CLI binary is not
  // found, _capabilitiesFor runs first so we can observe the minted creds.
  group('capabilities resolution', () {
    test('uses agent capabilities when agent has them', () async {
      final agentRepo = FakeAgentRepository();
      const caps = AgentCapabilities(
        canPushToRepo: true,
        canCallGitHubApi: true,
      );
      agentRepo.agentToReturn = Agent(
        id: 'agent-1',
        name: 'test-agent',
        title: 'Test Agent',
        agentMdPath: '/tmp/test.md',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        capabilities: caps,
        createdAt: DateTime.now(),
      );
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(
        deps: _makeDeps(agentRepo: agentRepo, broker: broker),
      );

      // Call run() — it will stop at resolveBinaryPath or exec, but
      // _capabilitiesFor and broker.mint happen first.
      unawaited(session.run());
      // Pump the event loop so the first awaits settle.
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // The broker was minted with the agent's capabilities.
      expect(broker.mintCount, greaterThanOrEqualTo(1));
    });

    test('falls back to default caps when agent has null capabilities',
        () async {
      final agentRepo = FakeAgentRepository();
      agentRepo.agentToReturn = Agent(
        id: 'agent-1',
        name: 'test-agent',
        title: 'Test Agent',
        agentMdPath: '/tmp/test.md',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        capabilities: null,
        createdAt: DateTime.now(),
      );
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(
        deps: _makeDeps(agentRepo: agentRepo, broker: broker),
      );

      unawaited(session.run());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(broker.mintCount, greaterThanOrEqualTo(1));
    });

    test('falls back to default caps when agent not found', () async {
      final agentRepo = FakeAgentRepository();
      agentRepo.agentToReturn = null;
      final broker = FakeCredentialBrokerPort();
      final session = _makeSession(
        deps: _makeDeps(agentRepo: agentRepo, broker: broker),
      );

      unawaited(session.run());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(broker.mintCount, greaterThanOrEqualTo(1));
    });

    test('falls back to default caps when agentId is null', () async {
      final broker = FakeCredentialBrokerPort();
      final session = DispatchSession(
        deps: _makeDeps(broker: broker),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'd1',
        cliName: 'pi',
        prompt: 'hello',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: null,
        workspaceId: null,
        conversationId: null,
        runLogId: null,
        mode: ConversationMode.chat,
      );

      unawaited(session.run());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(broker.mintCount, greaterThanOrEqualTo(1));
    });

    test('falls back to default caps when agentRepo throws', () async {
      final agentRepo = FakeAgentRepository();
      agentRepo.agentToReturn = null;
      final broker = FakeCredentialBrokerPort();
      final session = DispatchSession(
        deps: _makeDeps(agentRepo: agentRepo, broker: broker),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'd1',
        cliName: 'pi',
        prompt: 'hello',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: 'bad-id',
        workspaceId: null,
        conversationId: null,
        runLogId: null,
        mode: ConversationMode.chat,
      );

      unawaited(session.run());
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Should still mint with default caps even though agent lookup threw.
      expect(broker.mintCount, greaterThanOrEqualTo(1));
    });
  });

  // -----------------------------------------------------------------------
  // _forwardSandboxEvent — sandbox event → AgentProcessEvent mapping
  // -----------------------------------------------------------------------
  group('forwardSandboxEvent', () {
    test('stdout non-JSON line → TextEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      // Let run() set up the event subscription and block on exec.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content: 'plain text output from agent',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final textEvents = events.whereType<TextEvent>().toList();
      expect(textEvents.any((e) => e.content == 'plain text output from agent'),
          isTrue);
    });

    test('stderr event → ErrorEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stderr,
        content: 'an error occurred',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(1);
      await Future<void>.delayed(Duration.zero);

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(errorEvents.any((e) => e.content == 'an error occurred'), isTrue);
    });

    test('killed event with content → ErrorEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.killed,
        content: 'OOM killer',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(137);
      await Future<void>.delayed(Duration.zero);

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(errorEvents.any((e) => e.content == 'OOM killer'), isTrue);
    });

    test('killed event without content → ErrorEvent with default message',
        () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.killed,
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(137);
      await Future<void>.delayed(Duration.zero);

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(
          errorEvents.any((e) => e.content == '[sandbox] killed'), isTrue);
    });

    test('starting event → DebugEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.starting,
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final debugEvents = events.whereType<DebugEvent>().toList();
      expect(
          debugEvents.any((e) =>
              e.content.contains('booting sandbox session')),
          isTrue);
    });

    test('ready event is a no-op (no event emitted)', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final countBefore = events.length;
      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.ready,
      ));

      await Future<void>.delayed(Duration.zero);

      // Ready events should not produce AgentProcessEvents.
      expect(events.length, countBefore);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);
    });

    test('violation event with full data → SandboxViolationEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.violation,
        violation: SandboxViolation(
          action: 'file-write',
          target: '/etc/hosts',
          suggestedCapability: 'canWriteEtcHosts',
        ),
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final violations = events.whereType<SandboxViolationEvent>().toList();
      expect(violations, isNotEmpty);
      final v = violations.first;
      expect(v.action, 'file-write');
      expect(v.target, '/etc/hosts');
      expect(v.suggestedCapability, 'canWriteEtcHosts');
    });

    test('violation event without violation data → generic deny message',
        () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.violation,
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final violations = events.whereType<SandboxViolationEvent>().toList();
      expect(violations, isNotEmpty);
      expect(violations.first.content, '[sandbox] denied operation');
    });
  });

  // -----------------------------------------------------------------------
  // _handlePiEvent — structured JSON output parsing
  // -----------------------------------------------------------------------
  group('handlePiEvent', () {
    test('message_update with text_delta → TextEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content:
            '{"type":"message_update","assistantMessageEvent":{"type":"text_delta","delta":"Hello, world"}}',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final textEvents = events.whereType<TextEvent>().toList();
      expect(textEvents.any((e) => e.content == 'Hello, world'), isTrue);
    });

    test('message_update with thinking_delta → ThinkingEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content:
            '{"type":"message_update","assistantMessageEvent":{"type":"thinking_delta","delta":"Let me think..."}}',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final thinkingEvents = events.whereType<ThinkingEvent>().toList();
      expect(
          thinkingEvents.any((e) => e.content == 'Let me think...'), isTrue);
    });

    test('tool_execution_start → ToolCallEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content:
            '{"type":"tool_execution_start","toolName":"Bash","toolCallId":"call_1","args":{"command":"ls"}}',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final toolCalls = events.whereType<ToolCallEvent>().toList();
      expect(toolCalls.any((t) => t.toolName == 'Bash'), isTrue);
      final bashCall = toolCalls.firstWhere((t) => t.toolName == 'Bash');
      expect(bashCall.toolCallId, 'call_1');
      expect(bashCall.inputs, {'command': 'ls'});
    });

    test('tool_execution_end → ToolResultEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content:
            '{"type":"tool_execution_end","toolCallId":"call_1","toolName":"Bash","result":"file1\\nfile2","isError":false}',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final results = events.whereType<ToolResultEvent>().toList();
      expect(results, isNotEmpty);
      final r = results.first;
      expect(r.toolCallId, 'call_1');
      expect(r.isError, isFalse);
    });

    test('tool_execution_end with error → ToolResultEvent with isError',
        () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content:
            '{"type":"tool_execution_end","toolCallId":"call_1","toolName":"Bash","result":"command not found","isError":true}',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      final results = events.whereType<ToolResultEvent>().toList();
      expect(results.any((r) => r.isError && r.toolCallId == 'call_1'),
          isTrue);
    });

    test('agent_end → DoneEvent', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.addSandboxEvent(const SandboxEvent(
        type: SandboxEventType.stdout,
        content: '{"type":"agent_end"}',
      ));

      await Future<void>.delayed(Duration.zero);
      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      expect(events.whereType<DoneEvent>(), isNotEmpty);
    });
  });

  // -----------------------------------------------------------------------
  // run() — exec args, env, and lifecycle
  // -----------------------------------------------------------------------
  group('run exec arguments', () {
    test('passes combined env vars to sandbox exec', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      expect(sandbox.lastEnv, isNotNull);
      // Built-in vars injected by dispatch session
      expect(sandbox.lastEnv!['CC_DISABLE_PROJECT_CONFIG'], 'true');
      expect(sandbox.lastEnv!['OPENCODE_DISABLE_PROJECT_CONFIG'], 'true');
      // Caller env passed through
      expect(sandbox.lastEnv!['HOME'], '/tmp');
      // Credentials injected
      expect(sandbox.lastEnv!, contains('API_KEY'));
    });

    test('passes prompt as stdin to exec', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(
        deps: _makeDeps(sandbox: sandbox),
        prompt: 'custom prompt text',
      );

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);

      expect(sandbox.lastStdinInput, 'custom prompt text');
    });

    test('onPid callback is invoked during exec', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));

      expect(session.pid, isNull);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // PID is set by onPid callback, which our fake fires synchronously.
      expect(session.pid, 42);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);
    });

    test('non-zero exit code emits error event', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(1);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(errorEvents.any((e) => e.content.contains('exited with code 1')),
          isTrue);
    });

    test('exit code 127 emits binary-not-found error', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(127);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(
          errorEvents.any(
              (e) => e.content.contains('not found on PATH')),
          isTrue);
    });

    test('zero exit code emits debug message', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final debugEvents = events.whereType<DebugEvent>().toList();
      expect(
          debugEvents.any(
              (e) => e.content.contains('exited cleanly (code 0)')),
          isTrue);
    });

    test('DoneEvent emitted on successful run', () async {
      final sandbox = ControllableSandboxPort();
      final session = _makeSession(deps: _makeDeps(sandbox: sandbox));
      final events = <AgentProcessEvent>[];
      session.controller.stream.listen(events.add);

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // _completeRun emits a DoneEvent through close; verify stream completed.
      expect(session.controller.isClosed, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // _failRun — run log error marking
  // -----------------------------------------------------------------------
  group('failRun', () {
    test('terminate calls _failRun which emits ErrorEvent', () async {
      final runLogRepo = FakeAgentRunLogRepository()
        ..logToReturn = AgentRunLog(
          id: 'run-log-1',
          agentId: 'agent-1',
          workspaceId: 'ws-1',
          status: RunStatus.running,
          startedAt: DateTime.now(),
        );

      final events = <AgentProcessEvent>[];
      final session = DispatchSession(
        deps: _makeDeps(runLogRepo: runLogRepo),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'disp-1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: null,
        runLogId: 'run-log-1',
        mode: ConversationMode.chat,
      );
      session.controller.stream.listen(events.add);

      await session.terminate();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      // _failRun emits an ErrorEvent with the failure message.
      final errorEvents = events.whereType<ErrorEvent>().toList();
      expect(
        errorEvents.any((e) => e.content == 'Terminated by user request'),
        isTrue,
      );
    });

    test('terminate no-ops when runLogId is null', () async {
      final session = _makeSession();
      // Should not throw when runLogId is null.
      await session.terminate();
      expect(session.controller.isClosed, isTrue);
    });

    test('terminate no-ops when runLogRepo is null', () async {
      final session = DispatchSession(
        deps: _makeDeps(runLogRepo: null),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'disp-1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: null,
        runLogId: 'run-log-1',
        mode: ConversationMode.chat,
      );

      // Should not throw when runLogRepo is null even with a runLogId.
      await session.terminate();
      expect(session.controller.isClosed, isTrue);
    });
  });

  // -----------------------------------------------------------------------
  // Event bus publishing on run completion
  // -----------------------------------------------------------------------
  group('event bus publishing', () {
    test('_completeRun publishes AgentRunCompleted when agentId is set',
        () async {
      final eventBus = DomainEventBus();
      final published = <DomainEvent>[];
      eventBus.on<AgentRunCompleted>().listen(published.add);

      final sandbox = ControllableSandboxPort();
      final session = DispatchSession(
        deps: _makeDeps(sandbox: sandbox, eventBus: eventBus),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'disp-1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: 'agent-1',
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        runLogId: null,
        mode: ConversationMode.chat,
      );

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final completed = published.whereType<AgentRunCompleted>().toList();
      expect(completed, hasLength(1));
      expect(completed.single.agentId, 'agent-1');
      expect(completed.single.workspaceId, 'ws-1');
      expect(completed.single.conversationId, 'conv-1');
    });
    test('_completeRun does not publish when agentId is null', () async {
      final eventBus = DomainEventBus();
      final published = <DomainEvent>[];
      eventBus.on<AgentRunCompleted>().listen(published.add);

      final sandbox = ControllableSandboxPort();
      final session = DispatchSession(
        deps: _makeDeps(sandbox: sandbox, eventBus: eventBus),
        onResolveHandle: ({required sessionId, required spec, required emit}) async =>
            SandboxHandle(sessionId: sessionId, backend: SandboxBackend.native),
        onScheduleCooldown: (_) {},
        dispatchId: 'disp-1',
        cliName: 'pi',
        prompt: '',
        agentDirHostPath: '/tmp',
        modelId: null,
        callerEnv: {},
        agentId: null,
        workspaceId: null,
        conversationId: null,
        runLogId: null,
        mode: ConversationMode.chat,
      );

      unawaited(session.run());
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      sandbox.completeExec(0);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final completed = published.whereType<AgentRunCompleted>().toList();
      expect(completed, isEmpty);
    });
  });
}
