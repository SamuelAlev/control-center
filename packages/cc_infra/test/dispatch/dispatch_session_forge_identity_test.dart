import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
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

/// Pins the agent-lane forge-identity contract of [DispatchSession]:
///
///  - The credential broker is handed the run worktree's GitHub coordinates,
///    so it can mint a fine-grained App INSTALLATION token scoped to that one
///    repo — the App identity is what an agent acts as on the forge.
///  - A run requested by a human carries no trace of that human's own GitHub
///    credential: the broker's environment is the only credential surface.
///    The requesting member used to be injected as `GH_TOKEN`/`GITHUB_TOKEN`
///    over the broker env, which made every agent write on GitHub impersonate
///    the requester at their full personal-token scope.
class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every mint's arguments so the tests can assert what the broker was
/// (and was not) told about the run.
class _RecordingBroker implements CredentialBrokerPort {
  final List<({String? repoOwner, String? repoName})> mints = [];

  @override
  Future<ScopedCredentials> mint({
    required String conversationId,
    required AgentCapabilities capabilities,
    String? repoOwner,
    String? repoName,
    String? actingUserId,
  }) async {
    mints.add((repoOwner: repoOwner, repoName: repoName));
    return const ScopedCredentials(
      handle: 'h',
      environment: {'GH_TOKEN': 'broker-token', 'GITHUB_TOKEN': 'broker-token'},
    );
  }

  @override
  Future<void> revoke(String handle) async {}
}

class _FakeInspector implements GitRepoInspectorPort {
  _FakeInspector(this.info);

  final GitRepoInfo? info;
  int inspections = 0;

  @override
  Future<GitRepoInfo> inspect(String path) async {
    inspections++;
    final resolved = info;
    if (resolved == null) {
      throw const GitRepoInspectionException('not a git work tree');
    }
    return resolved;
  }
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

/// Keyless credential so the harness path clears its auth gate without a
/// secret.
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

class _ScriptedLoop implements AgentLoop {
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
  }) => Stream.fromIterable(const [LoopDone(LoopDoneReason.completed)]);
}

({DispatchSession session, _RecordingBroker broker}) _buildSession({
  required AgentCapabilities caps,
  GitRepoInspectorPort? inspector,
  String? requestedByUserId,
}) {
  final tempDir = Directory.systemTemp.createTempSync('cc_forge_identity_');
  // Best-effort with retries: on Windows the dispatch harness can still hold
  // a handle inside the tree when teardown runs (errno 32), which must not
  // fail a test whose subject already passed.
  addTearDown(() => deleteDirBestEffort(tempDir));
  final broker = _RecordingBroker();
  final deps = SandboxDispatchDeps(
    sandbox: _NoopSandbox(),
    broker: broker,
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: _UnusedRunLogRepo(),
    defaultCaps: caps,
    eventBus: null,
    backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
    harnessCredentialStore: _KeylessStore(),
    harnessProviderFactory: const HarnessProviderFactory(),
    agentLoop: _ScriptedLoop(),
    repoInspector: inspector,
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
    prompt: 'do the thing',
    agentDirHostPath: tempDir.path,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    runLogId: 'run-1',
    requestedByUserId: requestedByUserId,
    mode: Mode.chat,
  );
  return (session: session, broker: broker);
}

void main() {
  const githubCaps = AgentCapabilities(canCallGitHubApi: true);

  test('the broker mint receives the worktree GitHub coordinates', () async {
    final h = _buildSession(
      caps: githubCaps,
      inspector: _FakeInspector(
        const GitRepoInfo(
          path: '/tmp/worktree',
          forge: ForgeHost.github,
          owner: 'acme',
          repoName: 'widgets',
          branch: 'main',
        ),
      ),
      requestedByUserId: 'member-1',
    );

    await h.session.run();

    expect(h.broker.mints.single, (repoOwner: 'acme', repoName: 'widgets'));
  });

  test('a non-GitHub origin mints with no coordinates', () async {
    final h = _buildSession(
      caps: githubCaps,
      inspector: _FakeInspector(
        const GitRepoInfo(
          path: '/tmp/worktree',
          forge: ForgeHost.gitlab,
          owner: 'acme',
          repoName: 'widgets',
          branch: 'main',
        ),
      ),
    );

    await h.session.run();

    expect(h.broker.mints.single, (repoOwner: null, repoName: null));
  });

  test('a cwd that is not a repo still dispatches, uncoordinated', () async {
    final inspector = _FakeInspector(null);
    final h = _buildSession(caps: githubCaps, inspector: inspector);

    await h.session.run();

    expect(inspector.inspections, 1);
    expect(h.broker.mints.single, (repoOwner: null, repoName: null));
  });

  test('capabilities without GitHub access never inspect the repo', () async {
    final inspector = _FakeInspector(
      const GitRepoInfo(
        path: '/tmp/worktree',
        forge: ForgeHost.github,
        owner: 'acme',
        repoName: 'widgets',
        branch: 'main',
      ),
    );
    final h = _buildSession(
      caps: AgentCapabilities.safeDefault,
      inspector: inspector,
    );

    await h.session.run();

    expect(inspector.inspections, 0);
    expect(h.broker.mints.single, (repoOwner: null, repoName: null));
  });
}
