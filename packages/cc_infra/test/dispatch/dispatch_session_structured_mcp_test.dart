import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:test/test.dart';
import '../helpers/windows_safe_delete.dart';

/// Records the argv passed to `exec` so the test can assert the structured
/// (Pi) transport does NOT forward `--mcp-config`. Only `exec`/`events`/
/// `backend` are exercised — the rest route through `noSuchMethod` and never
/// fire because the test supplies `onResolveHandle` directly.
class _RecordingSandbox implements SandboxPort {
  final List<List<String>> execArgs = [];

  @override
  SandboxBackend get backend => SandboxBackend.none;

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
  }) async {
    execArgs.add(argv);
    onPid?.call(4242);
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Mints empty credentials; the structured path needs a handle + env map only.
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

/// Never invoked — the test dispatches with a null agentId, so capability
/// lookup short-circuits to the default caps without touching the repo.
class _UnusedAgentRepo implements AgentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'structured (Pi) dispatch writes <cwd>/.mcp.json and passes no '
    '--mcp-config flag',
    () async {
      final tempDir = Directory.systemTemp.createTempSync('cc_dispatch_mcp_');
      addTearDown(() => deleteDirBestEffort(tempDir));

      final sandbox = _RecordingSandbox();
      final resolverCalledWith = <String>[];

      final deps = SandboxDispatchDeps(
        sandbox: sandbox,
        broker: _NoopBroker(),
        agentRepo: _UnusedAgentRepo(),
        runLogRepo: null,
        defaultCaps: AgentCapabilities.safeDefault,
        eventBus: null,
        backendRegistry: BackendRegistry({
          'echo': const StructuredCliBackend(cliName: 'echo'),
        }),
        // Mirrors cc_server's resolver: write `<cwd>/.mcp.json`, return its path.
        mcpConfigPathResolver:
            (cwd, {workspaceId, agentId, conversationId, spaceId}) async {
              resolverCalledWith.add(cwd);
              final file = File('$cwd/.mcp.json');
              await file.writeAsString(
                '{"mcpServers":{"control-center":'
                '{"type":"http","url":"http://127.0.0.1:9030/mcp"}}}',
              );
              return file.path;
            },
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
        cliName: 'echo',
        prompt: 'hello',
        agentDirHostPath: tempDir.path,
        modelId: null,
        callerEnv: const {},
        agentId: null,
        workspaceId: 'ws-1',
        conversationId: 'conv-1',
        runLogId: 'run-1',
        mode: Mode.chat,
      );

      // Drain the event stream so the session can complete cleanly.
      final drained = session.controller.stream.drain<void>();
      await session.run();
      await drained;

      // The resolver ran against the agent cwd (its side effect writes the file).
      expect(resolverCalledWith, [tempDir.path]);
      expect(
        File('${tempDir.path}/.mcp.json').existsSync(),
        isTrue,
        reason: 'the structured transport must write <cwd>/.mcp.json',
      );

      // But the flag itself is never spawned: `--mcp-config` is registered by
      // the `pi-mcp-adapter` extension, and pi's own option parser rejects an
      // unknown flag before the run starts ("Error: Unknown option:
      // --mcp-config", exit 1). The extension picks the written file up as the
      // project-scoped config on its own; without the extension the turn runs
      // degraded instead of failing.
      expect(sandbox.execArgs, hasLength(1));
      final argv = sandbox.execArgs.single;
      expect(
        argv,
        isNot(contains('--mcp-config')),
        reason: 'pi core rejects --mcp-config as an unknown option',
      );
    },
  );
}
