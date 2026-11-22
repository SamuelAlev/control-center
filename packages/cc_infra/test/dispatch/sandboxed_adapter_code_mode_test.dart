import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_infra/src/code_mode/bundled_code_runner.dart';
import 'package:cc_infra/src/code_mode/code_execution_service.dart';
import 'package:cc_infra/src/code_mode/code_sandbox_process.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/sandboxed_agent_dispatch_adapter.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../code_mode/code_mode_test_support.dart'
    show MemoryExecutions, MemoryStore;
import '../helpers/windows_safe_delete.dart';

/// The built runner, from `CC_CODEMODE_RUNNER` or the repository's release
/// build, or null when neither exists.
String? _runner() {
  final named = Platform.environment[BundledCodeRunner.environmentOverride];
  if (named != null && named.isNotEmpty) {
    return File(named).existsSync() ? named : null;
  }
  final built = p.normalize(
    p.join(
      Directory.current.path,
      '..',
      '..',
      'build',
      'cargo',
      'codemode',
      'release',
      Platform.isWindows ? 'cc_codemode.exe' : 'cc_codemode',
    ),
  );
  return File(built).existsSync() ? built : null;
}

class _Sandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Future<SandboxHandle> launch(SandboxSpec spec) async => SandboxHandle(
    sessionId: spec.sessionId,
    backend: SandboxBackend.none,
    state: SandboxState.warm,
  );

  @override
  Future<bool> isAlive(SandboxHandle handle) async => true;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused implements CredentialBrokerPort, AgentRepository {
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
  Future<void> save(ProviderCredential credential) async {}

  @override
  Future<void> remove(
    String providerId, {
    String? accountLabel,
    String? credentialId,
  }) async {}
}

/// Calls `repl` once when the model is offered it, then answers in text;
/// records the tool names each request offered.
class _Provider extends LlmProviderPort {
  final offered = <List<String>>[];

  @override
  String get displayName => 'adapter code mode scenario';
  @override
  String get defaultModel => 'test-model';
  @override
  Future<List<ProviderModel>> listModels() async => const [];

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    final names = [for (final t in tools) t.name];
    offered.add(names);
    if (offered.length == 1 && names.contains('repl')) {
      yield LlmToolUseDelta(
        id: 'call_repl',
        name: 'repl',
        argumentsJson: jsonEncode({
          'code': 'return 6 * 7;',
          'description': 'multiply',
        }),
      );
      yield const LlmDone(stopReason: LlmStopReason.toolUse);
    } else {
      yield const LlmTextDelta('Done.');
      yield const LlmDone(stopReason: LlmStopReason.endTurn);
    }
  }
}

/// The real loop, with [provider] in place of the one the run built.
class _Loop implements AgentLoop {
  _Loop(this.provider);

  final _Provider provider;

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
  }) => const AgentLoopRunner().run(
    history: history,
    userMessage: userMessage,
    tools: tools,
    deferredTools: deferredTools,
    scriptTools: scriptTools,
    provider: this.provider,
    context: context,
    config: config,
    cancel: cancel,
  );
}

void main() {
  final runner = _runner();
  final skip = runner == null
      ? 'the code mode runner is not built: build it with '
            '`CARGO_TARGET_DIR=build/cargo/codemode cargo build --release '
            '--locked --manifest-path '
            'packages/cc_natives/native/codemode/Cargo.toml`, or set '
            'CC_CODEMODE_RUNNER to its absolute path'
      : null;

  late Directory dir;
  late MemoryExecutions executions;
  late CodeExecutionService service;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('cc_adapter_code_mode_');
    final process = CodeSandboxProcess(executable: runner!);
    expect((await process.selfTest()).isAvailable, isTrue);
    executions = MemoryExecutions();
    service = CodeExecutionService(
      sandbox: process,
      executions: executions,
      store: MemoryStore(),
      serverProcessCap: 2,
    );
  });

  tearDown(() async {
    await service.dispose();
    await deleteDirBestEffort(dir);
  });

  /// Dispatches one harness run in [workspaceId] through an adapter built
  /// the way the server builds it, and returns what it streamed.
  Future<List<AgentProcessEvent>> dispatch(
    _Provider provider,
    String workspaceId, {
    bool withService = true,
    String? runLogId = 'run-1',
  }) async {
    final adapter = SandboxedAgentDispatchAdapter(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: _Sandbox(),
      agentRepository: _Unused(),
      harnessCredentialStore: _KeylessStore(),
      agentLoop: _Loop(provider),
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
      codeExecutions: withService ? service : null,
      codeModeLimits: (_) async => CodeModeLimits.defaults,
    );
    addTearDown(adapter.shutdown);
    final handle = adapter.start(
      wakeContext: const WakeContext.userMessage(),
      freshHistory: false,
      readOnly: false,
      cliName: 'cc-harness',
      prompt: 'go',
      workingDirectory: dir.path,
      modelId: 'openai/test-model',
      workspaceId: workspaceId,
      runLogId: runLogId,
    );
    return handle.events.toList().timeout(const Duration(seconds: 60));
  }

  test(
    'a run gets repl on the real service; a server without one gives none',
    () async {
      final hybrid = _Provider();
      final events = await dispatch(hybrid, 'ws-1');
      expect(hybrid.offered.first.first, 'repl');
      final result = events.whereType<ToolResultEvent>().singleWhere(
        (e) => e.toolCallId == 'call_repl',
      );
      expect(result.isError, isFalse, reason: result.outputs);
      expect(result.outputs, startsWith('Script completed in'));
      expect(result.outputs, contains('42'));
      expect(result.outcome, CodeExecutionStatus.completed.wire);
      // Recorded under the run's row, begun before it ran.
      final saved = executions.rows['run-1/call_repl']!;
      expect(saved.execution.status, CodeExecutionStatus.completed);
      expect(saved.payload?.source, 'return 6 * 7;');

      final off = _Provider();
      await dispatch(off, 'ws-1', withService: false);
      expect(off.offered.single, isNot(contains('repl')));
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a run with no run-log row gets no repl: its scripts could not be '
    'recorded',
    () async {
      final provider = _Provider();
      await dispatch(provider, 'ws-1', runLogId: null);
      expect(provider.offered.first, isNot(contains('repl')));
      expect(executions.rows, isEmpty);
      expect(executions.begins, isEmpty);
    },
    skip: skip,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
