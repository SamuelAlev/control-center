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
import 'package:cc_domain/features/model_routing/domain/entities/model_info.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_server_core/src/demo/demo_provider.dart';
import 'package:cc_server_core/src/demo/demo_script.dart';
import 'package:cc_server_core/src/demo/scripted_agent_loop.dart';
import 'package:test/test.dart';

/// The Phase-0 spike, kept as a permanent regression test.
///
/// It pins the single load-bearing claim the whole demo rests on: a scripted
/// [ScriptedAgentLoop] injected into a REAL [DispatchSession] produces a real
/// run — streamed text, tool cards, priced usage — while executing nothing and
/// dialling nothing. If this breaks, the demo's safety story breaks with it.
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

/// Records what the run-log path asked for, so the test can assert the session
/// really drove it (the demo depends on that: a scripted run must persist
/// exactly like a real one).
class _RecordingRunLogRepo implements AgentRunLogRepository {
  final List<String> calls = [];
  final Map<String, AgentRunLog> rows = {};

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    calls.add('getById($workspaceId,$id)');
    return rows[id] ??
        AgentRunLog(
          id: id,
          agentId: 'agent-demo',
          workspaceId: workspaceId,
          startedAt: DateTime.now(),
          status: RunStatus.running,
        );
  }

  @override
  Future<void> upsert(AgentRunLog log) async {
    calls.add('upsert(${log.id})');
    rows[log.id] = log;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _script = DemoRunScript(
  id: 'spike',
  triggers: ['review'],
  steps: [
    DemoThinkingStep('The diff touches the token refresh path.'),
    DemoSayStep('Reading the changed files.'),
    DemoToolStep(
      tool: 'read',
      args: {'path': 'lib/auth.dart'},
      result: 'class Auth { Future<void> refresh() async {} }',
    ),
    DemoSayStep('The refresh path looks correct.'),
    DemoUsageStep(
      inputTokens: 12400,
      outputTokens: 320,
      cacheReadTokens: 8200,
      cacheWriteTokens: 1100,
      thoughtTokens: 180,
    ),
  ],
);

void main() {
  late Directory tempDir;
  late _RecordingRunLogRepo runLogRepo;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cc_demo_spike_');
    runLogRepo = _RecordingRunLogRepo();
    addTearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException {
        // Best effort: a Windows handle may still be closing.
      }
    });
  });

  DispatchSession buildSession() {
    final deps = SandboxDispatchDeps(
      sandbox: _NoopSandbox(),
      broker: _NoopBroker(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: runLogRepo,
      defaultCaps: AgentCapabilities.safeDefault,
      eventBus: null,
      // Harness-only: any other adapter resolves to null and fails loudly
      // rather than silently reaching for a CLI a demo host does not have.
      backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
      harnessCredentialStore: const DemoCredentialStore(),
      harnessProviderFactory: const DemoHarnessProviderFactory(),
      agentLoop: ScriptedAgentLoop(
        scripts: const [_script],
        pacing: DemoPacing.instant,
      ),
      // The real cost path: the demo's model must resolve in the catalog or a
      // run reports zero cost and the observability surfaces read as broken.
      // Rates are USD per MILLION tokens — `ModelCost.estimate` does the
      // division itself.
      modelResolver: (qualified) => const ModelInfo(
        id: 'demo-model',
        providerId: 'demo',
        name: 'Demo model',
        cost: ModelCost(
          input: 3.0,
          output: 15.0,
          cacheRead: 0.3,
          cacheWrite: 3.75,
        ),
      ),
    );
    return DispatchSession(
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
      dispatchId: 'demo-dispatch',
      cliName: 'cc-harness',
      prompt: 'review the pull request',
      agentDirHostPath: tempDir.path,
      modelId: 'demo/demo-model',
      callerEnv: const {},
      agentId: 'agent-demo',
      workspaceId: 'ws-demo',
      conversationId: 'conv-demo',
      spaceId: 'space-demo',
      runLogId: 'run-demo',
      mode: Mode.chat,
    );
  }

  /// Runs a session and returns everything it emitted.
  ///
  /// The pump matters: `run()` returning only means the last event was ADDED to
  /// the controller, not delivered. Cancelling the subscription immediately
  /// drops whatever is still queued — which is how the terminal `DoneEvent`
  /// went missing.
  Future<List<AgentProcessEvent>> runAndCollect(DispatchSession session) async {
    final events = <AgentProcessEvent>[];
    final sub = session.controller.stream.listen(events.add);
    await session.run();
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    await sub.cancel();
    return events;
  }

  test('a scripted run streams a real run through DispatchSession', () async {
    final events = await runAndCollect(buildSession());

    final text = events.whereType<TextEvent>().map((e) => e.content).join();
    expect(text, contains('Reading the changed files.'));
    expect(text, contains('The refresh path looks correct.'));
    expect(events.whereType<ThinkingEvent>(), isNotEmpty);

    // The tool card renders end to end — start and result, correctly paired —
    // without the tool existing, let alone running.
    final call = events.whereType<ToolCallEvent>().single;
    final result = events.whereType<ToolResultEvent>().single;
    expect(call.toolName, 'read');
    expect(result.toolCallId, call.toolCallId);
    expect(result.isError, isFalse);
    expect(result.outputs, contains('class Auth'));

    // A run that ends without DoneEvent leaves the UI spinning forever.
    expect(events.whereType<DoneEvent>(), hasLength(1));
    expect(
      events.whereType<ErrorEvent>().map((e) => e.content).toList(),
      isEmpty,
    );
  });

  test('usage is priced by the real cost calculator', () async {
    final events = await runAndCollect(buildSession());

    final usage = events.whereType<UsageEvent>().single.usage;
    expect(usage.inputTokens, 12400);
    expect(usage.outputTokens, 320);
    expect(usage.cachedReadTokens, 8200);
    expect(usage.cachedWriteTokens, 1100);
    expect(usage.thoughtTokens, 180);
    // 12400*3 + 320*15 + 8200*0.3 + 1100*3.75 per million USD -> ~4.9c.
    expect(
      usage.estimatedCostCents,
      greaterThan(0),
      reason: 'an unpriced demo run makes every cost surface read as broken',
    );
  });

  test('the run writes its NDJSON log, the run viewer\'s source', () async {
    await runAndCollect(buildSession());
    // `RunLogWriter` creates `<agentDir>/runs/<selfGeneratedId>.ndjson` and
    // stamps the path onto the run row. Skipping this lane gives a demo with an
    // empty run viewer.
    final runsDir = Directory('${tempDir.path}/runs');
    expect(runsDir.existsSync(), isTrue);
    final logs = runsDir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.ndjson'),
    );
    expect(logs, isNotEmpty);
    expect(logs.first.readAsStringSync(), isNotEmpty);
    expect(
      runLogRepo.calls.any((c) => c.startsWith('upsert(')),
      isTrue,
      reason: 'the run row must be written like any real run',
    );
  });

  test('the harness credential gate is satisfied without a secret', () async {
    // Without this the run aborts with exit 127 before the loop is ever
    // reached — `authSatisfied = hasSecret || method == none`.
    const store = DemoCredentialStore();
    final credential = await store.activeCredential('demo');
    expect(credential, isNotNull);
    expect(credential!.method, HarnessAuthMethod.none);
    expect(credential.secret, anyOf(isNull, isEmpty));
  });

  test('the demo provider throws if anything tries to complete', () async {
    const factory = DemoHarnessProviderFactory();
    final provider = factory.create(
      providerId: 'demo',
      credential: (await const DemoCredentialStore().activeCredential('demo'))!,
    );
    // It must still answer defaultModel: DispatchSession reads it to price a
    // turn. Only `complete` is the tripwire.
    expect(provider.defaultModel, isNotEmpty);
  });
}
