@Timeout(Duration(minutes: 3))
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
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
import 'package:cc_infra/src/dispatch/agent_hook_folder.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
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

/// Drives the run's hooks the way the agent loop does: session start, then
/// one gated tool call.
class _HookDrivingLoop implements AgentLoop {
  bool? allowed;
  bool hooked = false;

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
  }) async* {
    final hooks = config.steering.hooks;
    hooked = hooks != null;
    await hooks?.onSessionStart();
    allowed = await hooks?.preToolUse('read', const {'path': 'x'});
    yield const LoopDone(LoopDoneReason.completed);
  }
}

/// Shell hooks are host configuration: read only from the server's hook
/// folder, started as tool processes of the run, inside its sandbox.
void main() {
  late Directory dataDir;
  late String agentDir;
  late String hookFolder;

  setUp(() {
    dataDir = Directory.systemTemp.createTempSync('cc_hooks_');
    addTearDown(() => deleteDirBestEffort(dataDir));
    agentDir = p.join(dataDir.path, 'ws-1', 'agents', 'coder');
    Directory(agentDir).createSync(recursive: true);
    hookFolder = agentHookFolder(
      agentHooksRoot(dataDir.path),
      workspaceId: 'ws-1',
      agentConfigDir: agentDir,
    )!;
  });

  /// Writes an executable script [name] into [dir].
  void script(String dir, String name, String body) {
    final file = File(p.join(dir, name))
      ..createSync(recursive: true)
      ..writeAsStringSync('#!/bin/sh\n$body\n');
    Process.runSync('chmod', ['+x', file.path]);
  }

  Future<({_HookDrivingLoop loop, List<String> debug})> dispatch(
    SandboxManager manager,
  ) async {
    final loop = _HookDrivingLoop();
    final session = DispatchSession(
      deps: SandboxDispatchDeps(
        hostExecution: const HostExecutionGate(
          posture: HostExecutionPosture.sandboxed,
        ),
        sandbox: _NoopSandbox(),
        sandboxManager: manager,
        agentHooksRoot: agentHooksRoot(dataDir.path),
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
      agentDirHostPath: agentDir,
      agentConfigDir: agentDir,
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
    final debug = <String>[];
    final sub = session.controller.stream.listen((event) {
      if (event is DebugEvent) {
        debug.add(event.content);
      }
    });
    await session.run();
    await sub.cancel();
    return (loop: loop, debug: debug);
  }

  test('a hook declared in the agent config dir never runs', () async {
    // What a member can write with `fs.writeString` into the agent's folder.
    script(p.join(agentDir, '.agents'), 'start.sh', 'touch "\$PWD/ran"');
    File(p.join(agentDir, '.agents', 'harness.json')).writeAsStringSync(
      jsonEncode({
        'hooks': {'sessionStart': '.agents/start.sh'},
      }),
    );
    final manager = SandboxManager(hiddenPaths: [dataDir.path]);
    addTearDown(manager.reset);

    final run = await dispatch(manager);

    expect(run.loop.hooked, isFalse);
    expect(File(p.join(agentDir, 'ran')).existsSync(), isFalse);
    expect(
      run.debug,
      contains(
        allOf(
          contains('ignoring shell hooks declared by $agentDir'),
          contains(p.join(hookFolder, 'hooks.json')),
        ),
      ),
    );
  }, skip: Platform.isMacOS ? false : 'Seatbelt is macOS only');

  test('a hook in the hook folder runs inside the run\'s sandbox, with none '
      'of the run\'s environment', () async {
    script(hookFolder, 'start.sh', 'env > "\$PWD/hook_env.txt"');
    script(
      hookFolder,
      'pre.sh',
      // Confined: the script cannot change its own folder.
      'if touch "\$(dirname "\$0")/tampered" 2>/dev/null; then exit 1; fi\n'
          'exit 0',
    );
    File(p.join(hookFolder, 'hooks.json')).writeAsStringSync(
      jsonEncode({'sessionStart': 'start.sh', 'preTool': 'pre.sh'}),
    );
    final manager = SandboxManager(hiddenPaths: [dataDir.path]);
    addTearDown(manager.reset);

    final run = await dispatch(manager);

    expect(run.loop.hooked, isTrue);
    expect(run.loop.allowed, isTrue, reason: 'the gate ran and allowed');
    expect(File(p.join(hookFolder, 'tampered')).existsSync(), isFalse);
    final env = File(p.join(agentDir, 'hook_env.txt')).readAsStringSync();
    expect(env, isNot(contains('GH_TOKEN')));
    expect(env, isNot(contains(AgentRunLease.tokenEnvKey)));
    expect(env, isNot(contains(AgentRunLease.gatewayEnvKey)));
    expect(env, isNot(contains('GIT_CONFIG_')));
    expect(manager.sessionIds, isEmpty, reason: 'released with the run');
  }, skip: Platform.isMacOS ? false : 'Seatbelt is macOS only');

  test('a hook path that leaves the hook folder is refused and the gate '
      'denies', () async {
    final outside = p.join(dataDir.path, 'outside.sh');
    script(dataDir.path, 'outside.sh', 'exit 0');
    Directory(hookFolder).createSync(recursive: true);
    Link(p.join(hookFolder, 'pre.sh')).createSync(outside);
    File(
      p.join(hookFolder, 'hooks.json'),
    ).writeAsStringSync(jsonEncode({'preTool': 'pre.sh', 'postTool': outside}));
    final manager = SandboxManager(hiddenPaths: [dataDir.path]);
    addTearDown(manager.reset);

    final run = await dispatch(manager);

    expect(run.loop.allowed, isFalse);
    expect(
      run.debug,
      contains(
        allOf(
          contains('preTool: outside the hook folder'),
          contains('postTool: an absolute path'),
          contains('every tool call is denied'),
        ),
      ),
    );
  }, skip: Platform.isMacOS ? false : 'Seatbelt is macOS only');
}
