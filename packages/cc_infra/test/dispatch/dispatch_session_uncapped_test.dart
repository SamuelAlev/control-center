import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Pins the no-turn-ceiling contract of [DispatchSession]: every command
/// (plain chat, /plan, /goal, /loop) runs a single uncapped segment — the
/// run ends when the model stops, the in-session cost guard bites, or the
/// human stops it. Autonomous commands additionally get the priced cost
/// guard; cross-segment continuation is the goal supervisor's job, not the
/// session's.
class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoopBroker implements CredentialBrokerPort {
  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
  }) async => const ScopedCredentials(handle: 'h', environment: {});

  @override
  Future<void> revoke(String handle) async {}
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRunLogRepo implements AgentRunLogRepository {
  @override
  Future<void> upsert(AgentRunLog log) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Keyless credential so the harness path clears its auth gate without a secret.
class _KeylessStore implements ProviderCredentialStore {
  @override
  Future<ProviderCredential?> activeCredential(String providerId) async =>
      ProviderCredential(
        providerId: providerId,
        method: HarnessAuthMethod.none,
        baseUrl: 'http://127.0.0.1:1',
      );

  @override
  Future<List<ProviderCredential>> credentialsFor(String providerId) async => [
    (await activeCredential(providerId))!,
  ];

  @override
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

/// Plays back one scripted segment and records every user message + config
/// the session started the loop with.
class _RecordingLoop implements AgentLoop {
  _RecordingLoop(this.script);

  final List<AgentLoopEvent> script;
  final List<String> userMessages = [];
  final List<AgentLoopConfig> configs = [];

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) {
    userMessages.add(userMessage);
    configs.add(config);
    return Stream.fromIterable(script);
  }
}

({DispatchSession session, _RecordingLoop loop}) _buildSession({
  required List<AgentLoopEvent> script,
  String prompt = '/goal fix the bug',
}) {
  final tempDir = Directory.systemTemp.createTempSync('cc_uncapped_');
  addTearDown(() => deleteDirBestEffort(tempDir));
  final loop = _RecordingLoop(script);
  final deps = SandboxDispatchDeps(
    sandbox: _NoopSandbox(),
    broker: _NoopBroker(),
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: _UnusedRunLogRepo(),
    defaultCaps: AgentCapabilities.safeDefault,
    eventBus: null,
    backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
    harnessCredentialStore: _KeylessStore(),
    harnessProviderFactory: const HarnessProviderFactory(),
    agentLoop: loop,
  );
  final session = DispatchSession(
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
    dispatchId: 'd1',
    cliName: 'cc-harness',
    prompt: prompt,
    agentDirHostPath: tempDir.path,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    mode: Mode.chat,
  );
  return (session: session, loop: loop);
}

Future<List<AgentProcessEvent>> _collect(DispatchSession session) async {
  final events = <AgentProcessEvent>[];
  final sub = session.controller.stream.listen(events.add);
  await session.run();
  // Controller deliveries are microtasks: let the final events (DoneEvent
  // from the run's `finally`) flush before detaching the listener.
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await sub.cancel();
  return events;
}

void main() {
  test('/goal runs a single uncapped segment with the cost guard', () async {
    final h = _buildSession(
      script: [
        const LoopTextDelta('done'),
        const LoopDone(LoopDoneReason.completed),
      ],
    );

    final events = await _collect(h.session);

    expect(h.loop.userMessages, hasLength(1));
    final config = h.loop.configs.single;
    expect(config.maxTurns, isNull);
    expect(config.budget.isActive, isFalse);
    expect(config.externalBudgetExceeded, isNotNull);
    expect(events.whereType<DoneEvent>().single.outcome, isNull);
  });

  test('/loop also runs uncapped with the cost guard', () async {
    final h = _buildSession(
      prompt: '/loop polish the module',
      script: [const LoopDone(LoopDoneReason.completed)],
    );

    await _collect(h.session);

    final config = h.loop.configs.single;
    expect(config.maxTurns, isNull);
    expect(config.budget.isActive, isFalse);
    expect(config.externalBudgetExceeded, isNotNull);
  });

  test('/plan runs uncapped without the cost guard', () async {
    final h = _buildSession(
      prompt: '/plan sketch the migration',
      script: [const LoopDone(LoopDoneReason.completed)],
    );

    await _collect(h.session);

    final config = h.loop.configs.single;
    expect(config.maxTurns, isNull);
    expect(config.budget.isActive, isFalse);
    expect(config.externalBudgetExceeded, isNull);
  });

  test('plain chat runs uncapped without the cost guard', () async {
    final h = _buildSession(
      prompt: 'just answer this',
      script: [const LoopDone(LoopDoneReason.completed)],
    );

    await _collect(h.session);

    final config = h.loop.configs.single;
    expect(config.maxTurns, isNull);
    expect(config.budget.isActive, isFalse);
    expect(config.externalBudgetExceeded, isNull);
  });

  test('a ceiling end reason does not chain a second segment', () async {
    final h = _buildSession(script: [const LoopDone(LoopDoneReason.maxTurns)]);

    final events = await _collect(h.session);

    // No in-session chaining: one segment only and the turn finalizes as a
    // plain completion (the continuation of a /goal is the supervisor's
    // responsibility, driven by AgentRunCompleted).
    expect(h.loop.userMessages, hasLength(1));
    expect(events.whereType<DoneEvent>().single.outcome, isNull);
  });

  test('a budget-exhausted end is narrated and finalizes cleanly', () async {
    final h = _buildSession(
      script: [const LoopDone(LoopDoneReason.budgetExhausted)],
    );

    final events = await _collect(h.session);

    expect(h.loop.userMessages, hasLength(1));
    expect(
      events.whereType<DebugEvent>().map((e) => e.content).join('\n'),
      contains('budget exhausted'),
    );
    expect(events.whereType<DoneEvent>().single.outcome, isNull);
  });
}
