import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

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
  int mints = 0;

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required ForgeTokenScope scope,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
    String? workspaceId,
    bool personal = false,
  }) async {
    mints++;
    return const ScopedCredentials(handle: 'h', environment: {});
  }

  @override
  Future<void> revoke(String handle) async {}
}

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// One active row, `run-1`, and the terminal write it gets.
class _RunLogRepo implements AgentRunLogRepository {
  AgentRunLog? completed;

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async =>
      completed ??
      AgentRunLog(
        id: id,
        agentId: 'agent-1',
        workspaceId: workspaceId,
        startedAt: DateTime(2026),
        status: RunStatus.running,
      );

  @override
  Future<bool> completeIfActive(
    AgentRunLog completed, {
    bool writeCost = true,
  }) async {
    this.completed ??= completed;
    return true;
  }

  @override
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  }) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedLoop implements AgentLoop {
  _ScriptedLoop(this.script);

  final List<AgentLoopEvent> script;

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    required LlmProviderPort provider,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) => Stream.fromIterable(script);
}

/// The dispatch chokepoint under each host execution posture: with no
/// sandbox backend, a run starts only when the server owner is accountable
/// for it (the acting person; for automation the workspace owner), and
/// anyone else is refused before anything of the run starts.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cc_host_exec_');
    addTearDown(() => deleteDirBestEffort(tempDir));
  });

  Future<
    ({
      bool started,
      int mints,
      List<String> errors,
      List<String?> codes,
      AgentRunLog? runLog,
    })
  >
  dispatch(
    HostExecutionPosture posture, {
    required String? requestedBy,
    required String workspaceOwner,
  }) async {
    final broker = _NoopBroker();
    final runLogs = _RunLogRepo();
    final deps = SandboxDispatchDeps(
      hostExecution: HostExecutionGate(
        posture: posture,
        ownerAccountable:
            ({required workspaceId, required requestedByUserId}) async =>
                (requestedByUserId ?? workspaceOwner) == 'olga',
      ),
      sandbox: _NoopSandbox(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: runLogs,
      eventBus: null,
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
      backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
      harnessCredentialStore: _KeylessStore(),
      harnessProviderFactory: const HarnessProviderFactory(),
      agentLoop: _ScriptedLoop(const [LoopDone(LoopDoneReason.completed)]),
    );
    final session = DispatchSession(
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
      dispatchId: 'd1',
      cliName: 'cc-harness',
      prompt: 'do the thing',
      agentDirHostPath: tempDir.path,
      modelId: 'openai/test-model',
      callerEnv: const {},
      agentId: 'agent-1',
      workspaceId: 'ws-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      runLogId: 'run-1',
      requestedByUserId: requestedBy,
      mode: Mode.chat,
    );
    var started = false;
    session.onHarnessStarted = () => started = true;
    final errors = <String>[];
    final codes = <String?>[];
    final done = Completer<void>();
    final sub = session.controller.stream.listen((event) {
      if (event is ErrorEvent) {
        errors.add(event.content);
        codes.add(event.code);
      }
      if (event is DoneEvent && !done.isCompleted) {
        done.complete();
      }
    });
    await session.run();
    // Stream delivery is asynchronous: read up to the run's last event.
    await done.future.timeout(const Duration(seconds: 30));
    await sub.cancel();
    // The refusal's run-log write is fire-and-forget; give it its turns.
    for (var i = 0; i < 50 && runLogs.completed == null; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    return (
      started: started,
      mints: broker.mints,
      errors: errors,
      codes: codes,
      runLog: runLogs.completed,
    );
  }

  /// A refusal reaches the client as its code, on the turn's error and on
  /// the run log row, so the client can show its own notice for it.
  void expectRefused(
    ({
      List<String> errors,
      List<String?> codes,
      AgentRunLog? runLog,
      bool started,
      int mints,
    })
    run,
  ) {
    expect(run.errors, [HostSandboxUnavailableException.refusal]);
    expect(run.codes, [ErrorSegment.sandboxUnavailableCode]);
    expect(run.runLog?.status, RunStatus.error);
    expect(run.runLog?.summary, HostSandboxUnavailableException.refusal);
    expect(run.runLog?.errorCode, ErrorSegment.sandboxUnavailableCode);
  }

  for (final posture in HostExecutionPosture.values) {
    final refusesOthers = posture == HostExecutionPosture.unavailable;
    group(posture.name, () {
      test('the owner, interactive, runs', () async {
        final run = await dispatch(
          posture,
          requestedBy: 'olga',
          workspaceOwner: 'eve',
        );
        expect(run.started, isTrue);
      });

      test('automation the owner is accountable for runs', () async {
        final run = await dispatch(
          posture,
          requestedBy: null,
          workspaceOwner: 'olga',
        );
        expect(run.started, isTrue);
      });

      test('another member, interactive, '
          '${refusesOthers ? 'is refused' : 'runs'}', () async {
        final run = await dispatch(
          posture,
          requestedBy: 'eve',
          workspaceOwner: 'olga',
        );
        expect(run.started, !refusesOthers);
        if (refusesOthers) {
          expect(run.mints, 0, reason: 'refused before anything starts');
          expectRefused(run);
        }
      });

      test('automation another member is accountable for '
          '${refusesOthers ? 'is refused' : 'runs'}', () async {
        final run = await dispatch(
          posture,
          requestedBy: null,
          workspaceOwner: 'eve',
        );
        expect(run.started, !refusesOthers);
        if (refusesOthers) {
          expect(run.mints, 0);
          expectRefused(run);
        }
      });
    });
  }
}
