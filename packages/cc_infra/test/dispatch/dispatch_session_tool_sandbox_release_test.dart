@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
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
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:path/path.dart' as p;
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

class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UnusedRunLogRepo implements AgentRunLogRepository {
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
  }) async => false;

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

class _Approve implements ConfirmationPort {
  @override
  Future<bool> requestApproval(ConfirmationRequest request) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Runs `bash` and the project checker, then records which sandbox sessions
/// are open while the run is still going.
class _ToolCallingLoop implements AgentLoop {
  _ToolCallingLoop(this.manager, this.workdir);

  final SandboxManager manager;
  final String workdir;
  List<String> openDuringRun = const [];
  String bashOutput = '';

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
  }) async* {
    // `lsp` is not direct: it is script-only with `repl` and deferred
    // without, so it is looked up in every list the run gets.
    HarnessTool named(String name) => [
      ...tools,
      ...deferredTools,
      ...scriptTools,
    ].firstWhere((t) => t.name == name);
    final ctx = HarnessToolContext(workingDirectory: workdir);
    final echoed = await named(
      'bash',
    ).execute({'command': 'echo hi', 'description': 'say hi'}, ctx);
    bashOutput = echoed.content;
    await named('lsp').execute({'action': 'diagnostics', 'file': '*'}, ctx);
    openDuringRun = manager.sessionIds.toList();
    yield const LoopDone(LoopDoneReason.completed);
  }
}

/// A run's tool sandbox sessions (`bash` and the `eval` kernel, language
/// servers) are its own and end with it: after the run, the manager holds
/// none of them.
void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cc_tool_release_');
    File(p.join(tempDir.path, 'pubspec.yaml')).writeAsStringSync('name: x\n');
    addTearDown(() => deleteDirBestEffort(tempDir));
  });

  test('after a run ends, the manager holds no session for it', () async {
    final manager = SandboxManager(hiddenPaths: const []);
    addTearDown(manager.reset);
    final lsp = LspSupervisor();
    addTearDown(lsp.dispose);
    final loop = _ToolCallingLoop(manager, tempDir.path);
    final session = DispatchSession(
      freshHistory: false,
      readOnly: false,
      deps: SandboxDispatchDeps(
        hostExecution: const HostExecutionGate(
          posture: HostExecutionPosture.sandboxed,
        ),
        sandbox: _NoopSandbox(),
        sandboxManager: manager,
        confirmationPort: _Approve(),
        lspSupervisor: lsp,
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: _UnusedRunLogRepo(),
        eventBus: null,
        resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
            AgentCommitIdentity.person((
              name: 'Test User',
              email: 'test@example.test',
            )),
        backendRegistry: BackendRegistry({
          'cc-harness': const HarnessBackend(),
        }),
        harnessCredentialStore: _KeylessStore(),
        harnessProviderFactory: const HarnessProviderFactory(),
        agentLoop: loop,
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
      requestedByUserId: 'olga',
      mode: Mode.chat,
    );
    final sub = session.controller.stream.listen((_) {});
    await session.run();
    await sub.cancel();

    expect(loop.bashOutput, contains('hi'));
    expect(
      loop.openDuringRun,
      containsAll(['harness-agent-1::conv-1::d1', 'lsp-agent-1::conv-1::d1']),
      reason: 'both tools ran in their own per-run sessions',
    );
    expect(manager.sessionIds, isEmpty);
  }, skip: Platform.isMacOS ? false : 'Seatbelt is macOS only');
}
