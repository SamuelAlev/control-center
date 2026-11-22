import 'dart:async';
import 'dart:io';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/ports/credential_broker_port.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_event.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_handle.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_process_event.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_backend.dart';
import 'package:cc_domain/features/dispatch/domain/ports/commit_signing_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_domain/features/guardrails/domain/entities/action_policy_rule.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/action_policy_repository.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/sandboxing/domain/host_execution_posture.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/agent_run_gateway.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:test/test.dart';

import '../helpers/windows_safe_delete.dart';

/// Pins the agent-lane forge-identity contract of [DispatchSession]:
///
///  - A run holds no forge token. It registers the repositories it works on
///    with the agent run gateway, which is what hands it a read token for one
///    of them when its git or `gh` asks.
///  - In a space those repositories are the server's record of the space's
///    checkouts; outside one, the checkout the run starts in.
///  - The forge of those repositories is what the run's commit identity is
///    resolved for.
class _NoopSandbox implements SandboxPort {
  @override
  SandboxBackend get backend => SandboxBackend.none;

  @override
  Stream<SandboxEvent> events(SandboxHandle handle) =>
      const Stream<SandboxEvent>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Records every mint, so the tests can assert that a run starting mints
/// nothing.
class _RecordingBroker implements CredentialBrokerPort {
  final List<({String? repoOwner, String? repoName})> mints = [];
  final List<ForgeTokenScope> scopes = [];

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
    mints.add((repoOwner: repoOwner, repoName: repoName));
    scopes.add(scope);
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
  _ScriptedLoop([this.whileRunning]);

  /// Runs once, while the dispatch is live (its lease open).
  final void Function()? whileRunning;

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
  }) {
    whileRunning?.call();
    return Stream.fromIterable(const [LoopDone(LoopDoneReason.completed)]);
  }
}

class _NoRules implements ActionPolicyRepository {
  @override
  Future<List<ActionPolicyRule>> rules(String workspaceId) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoApprover implements ConfirmationPort {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OneKey implements CommitSigningPort {
  _OneKey(this.publicKey);

  final String publicKey;

  @override
  Future<String?> publicKeyOf(String userId) async => publicKey;

  @override
  Future<String> sign(
    String userId,
    String publicKey,
    List<int> commit,
  ) async => 'unused';
}

/// Builds a session. With [spaceRepos], or [inSpace], it runs in a space:
/// its directory is a per-agent overlay (`<space>/agents/a`, with its own
/// config dir), and the lookup is what the server answers for that space.
({DispatchSession session, Directory agentDir}) _buildSession({
  GitRepoInspectorPort? inspector,
  Future<List<ForgeRemote>> Function(String workspaceId, String spaceId)?
  spaceRepos,
  bool? inSpace,
  String? requestedByUserId,
  AgentCommitIdentity Function(ForgeHost? forge)? identity,
  AgentRunGateway? gateway,
  void Function()? whileRunning,
  List<String?>? runLogIds,
}) {
  final tempDir = Directory.systemTemp.createTempSync('cc_forge_identity_');
  // Best-effort with retries: on Windows the dispatch harness can still hold
  // a handle inside the tree when teardown runs (errno 32), which must not
  // fail a test whose subject already passed.
  addTearDown(() => deleteDirBestEffort(tempDir));
  inSpace ??= spaceRepos != null;
  final agentDir = inSpace
      ? (Directory('${tempDir.path}/agents/a')..createSync(recursive: true))
      : tempDir;
  final deps = SandboxDispatchDeps(
    hostExecution: const HostExecutionGate(
      posture: HostExecutionPosture.offByOwner,
    ),
    sandbox: _NoopSandbox(),
    agentRepo: _UnusedAgentRepo(),
    runLogRepo: _UnusedRunLogRepo(),
    eventBus: null,
    resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async {
      runLogIds?.add(runLogId);
      return identity?.call(forge) ??
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          ));
    },
    backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
    harnessCredentialStore: _KeylessStore(),
    harnessProviderFactory: const HarnessProviderFactory(),
    agentLoop: _ScriptedLoop(whileRunning),
    repoInspector: inspector,
    spaceRepos: spaceRepos,
    agentRunGateway: gateway,
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
    agentDirHostPath: agentDir.path,
    agentConfigDir: inSpace ? '${tempDir.path}/config' : null,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: inSpace ? 'space-1' : null,
    runLogId: 'run-1',
    requestedByUserId: requestedByUserId,
    mode: Mode.chat,
  );
  return (session: session, agentDir: agentDir);
}

AgentRunGateway _gateway({
  CommitSigningPort? signing,
  _RecordingBroker? broker,
}) => AgentRunGateway(
  guard: ActionGuardService(
    repository: _NoRules(),
    confirmationPort: _NoApprover(),
  ),
  broker: broker ?? _RecordingBroker(),
  loopbackBase: () async => Uri.parse('http://127.0.0.1:9'),
  signing: signing,
);

const _github = GitRepoInfo(
  path: '/tmp/worktree',
  forge: ForgeHost.github,
  owner: 'acme',
  repoName: 'widgets',
  branch: 'main',
);

const _gitlab = GitRepoInfo(
  path: '/tmp/worktree',
  forge: ForgeHost.gitlab,
  owner: 'acme',
  repoName: 'widgets',
  branch: 'main',
);

/// Runs the session [build] makes and answers the repositories it registered
/// with [gateway] while it was live, and whether its `gh` was in its shim
/// directory then.
Future<({List<ForgeRemote> repos, bool gh})> _registered(
  ({DispatchSession session, Directory agentDir}) Function(
    void Function() whileRunning,
  )
  build,
  AgentRunGateway gateway,
) async {
  var repos = const <ForgeRemote>[];
  var gh = false;
  late final ({DispatchSession session, Directory agentDir}) h;
  h = build(() {
    repos = gateway
        .openRuns(workspaceId: 'ws-1', conversationId: 'conv-1')
        .single
        .grant
        .repos;
    gh = File(
      '${h.agentDir.path}/.cc-runs/d1/bin/${AgentRunForgeTokens.ghShimName}',
    ).existsSync();
  });
  await h.session.run();
  return (repos: repos, gh: gh);
}

/// Expects [path] to be gone. A run that ends on its own closes its lease
/// and removes its shim directory without `run()` waiting for it.
Future<void> _expectRemoved(String path) async {
  bool there() =>
      FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
  for (var i = 0; i < 300 && there(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(there(), isFalse, reason: '$path is removed with the run');
}

void main() {
  group('outside a space', () {
    test(
      'the run works on the checkout it starts in, and mints nothing',
      () async {
        final broker = _RecordingBroker();
        final gateway = _gateway(broker: broker);
        final inspector = _FakeInspector(_github);

        final seen = await _registered(
          (whileRunning) => _buildSession(
            inspector: inspector,
            requestedByUserId: 'member-1',
            gateway: gateway,
            whileRunning: whileRunning,
          ),
          gateway,
        );

        expect(inspector.inspections, 1);
        expect(seen.repos, [
          (forge: ForgeHost.github, owner: 'acme', name: 'widgets'),
        ]);
        expect(
          broker.mints,
          isEmpty,
          reason: 'a token is minted when asked for',
        );
        expect(
          gateway.openRuns(workspaceId: 'ws-1', conversationId: 'conv-1'),
          isEmpty,
          reason: 'the lease, and every token under it, ends with the run',
        );
      },
    );

    test('a GitLab checkout fetches through the gateway, with no gh', () async {
      final gateway = _gateway();
      late final Future<List<AgentProcessEvent>> events;

      final seen = await _registered((whileRunning) {
        final h = _buildSession(
          inspector: _FakeInspector(_gitlab),
          gateway: gateway,
          whileRunning: whileRunning,
        );
        events = h.session.controller.stream.toList();
        return h;
      }, gateway);

      expect(seen.repos, [
        (forge: ForgeHost.gitlab, owner: 'acme', name: 'widgets'),
      ]);
      expect(seen.gh, isFalse);
      expect(
        (await events).whereType<DebugEvent>().map((e) => e.content),
        contains(
          '[forge] GitLab and Bitbucket: acme/widgets fetch through Control '
          'Center on a token the run never sees; agents publish there with '
          'stack_publish.',
        ),
      );
    });

    test('a cwd that is not a checkout still dispatches, and says the run '
        'reads no forge', () async {
      final gateway = _gateway();
      final inspector = _FakeInspector(null);
      late final Future<List<AgentProcessEvent>> events;

      final seen = await _registered((whileRunning) {
        final h = _buildSession(
          inspector: inspector,
          gateway: gateway,
          whileRunning: whileRunning,
        );
        events = h.session.controller.stream.toList();
        return h;
      }, gateway);

      expect(inspector.inspections, 1);
      expect(seen.repos, isEmpty);
      expect(
        (await events).whereType<DebugEvent>().map((e) => e.content),
        contains(
          '[forge] This run works on no linked repository, so Control '
          'Center fetches none for it.',
        ),
      );
    });
  });

  group('in a space', () {
    test('the run works on the space\'s checkouts as the server recorded '
        'them, and the directory it starts in is never asked', () async {
      final gateway = _gateway();
      // What git would answer in the overlay directory: whatever repository
      // encloses the data directory.
      final inspector = _FakeInspector(
        const GitRepoInfo(
          path: '/tmp/enclosing',
          forge: ForgeHost.github,
          owner: 'someone',
          repoName: 'enclosing',
          branch: 'main',
        ),
      );
      final asked = <(String, String)>[];
      late final Future<List<AgentProcessEvent>> events;

      final seen = await _registered((whileRunning) {
        final h = _buildSession(
          inspector: inspector,
          spaceRepos: (workspaceId, spaceId) async {
            asked.add((workspaceId, spaceId));
            return const [
              (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
              (forge: ForgeHost.github, owner: 'acme', name: 'api-server'),
            ];
          },
          gateway: gateway,
          whileRunning: whileRunning,
        );
        events = h.session.controller.stream.toList();
        return h;
      }, gateway);

      expect(asked, [('ws-1', 'space-1')]);
      expect(inspector.inspections, 0);
      expect(seen.repos, [
        (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
        (forge: ForgeHost.github, owner: 'acme', name: 'api-server'),
      ]);
      expect(
        (await events).whereType<DebugEvent>().map((e) => e.content),
        contains(
          '[forge] GitHub: acme/shop-ui, acme/api-server fetch through '
          'Control Center on a read-only token, which gh gets on request; '
          'pushes go through Control Center.',
        ),
      );
    });

    test(
      'its gh is in its shim directory while it runs, and gone after',
      () async {
        final gateway = _gateway();
        late final Directory agentDir;

        final seen = await _registered((whileRunning) {
          final h = _buildSession(
            spaceRepos: (_, _) async => const [
              (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
            ],
            gateway: gateway,
            whileRunning: whileRunning,
          );
          agentDir = h.agentDir;
          return h;
        }, gateway);

        expect(seen.gh, isTrue);
        await _expectRemoved('${agentDir.path}/.cc-runs/d1');
      },
      skip: Platform.isWindows ? 'the shim is a shell script' : false,
    );

    test('every forge\'s checkouts are the gateway\'s', () async {
      final gateway = _gateway();
      late final Future<List<AgentProcessEvent>> events;

      final seen = await _registered((whileRunning) {
        final h = _buildSession(
          spaceRepos: (_, _) async => const [
            (forge: ForgeHost.gitlab, owner: 'acme/group', name: 'tools'),
            (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
          ],
          gateway: gateway,
          whileRunning: whileRunning,
        );
        events = h.session.controller.stream.toList();
        return h;
      }, gateway);

      expect(seen.repos, [
        (forge: ForgeHost.gitlab, owner: 'acme/group', name: 'tools'),
        (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
      ]);
      expect(seen.gh, Platform.isWindows ? isFalse : isTrue);
      final said = (await events)
          .whereType<DebugEvent>()
          .map((e) => e.content)
          .where((c) => c.startsWith('[forge]'))
          .single;
      expect(said.split('\n'), [
        startsWith('[forge] GitHub: acme/shop-ui fetch'),
        startsWith('[forge] GitLab and Bitbucket: acme/group/tools fetch'),
      ]);
    });

    test('a lookup that fails leaves the run with no repository', () async {
      final gateway = _gateway();

      final seen = await _registered(
        (whileRunning) => _buildSession(
          spaceRepos: (_, _) async => throw StateError('database closed'),
          gateway: gateway,
          whileRunning: whileRunning,
        ),
        gateway,
      );

      expect(seen.repos, isEmpty);
      expect(seen.gh, isFalse);
    });

    test('a host that keeps no record gives the run no repository', () async {
      final gateway = _gateway();
      final inspector = _FakeInspector(_github);

      final seen = await _registered(
        (whileRunning) => _buildSession(
          inspector: inspector,
          inSpace: true,
          gateway: gateway,
          whileRunning: whileRunning,
        ),
        gateway,
      );

      expect(seen.repos, isEmpty);
      expect(inspector.inspections, 0);
    });
  });

  group(
    'the identity resolver learns the forge of the run\'s repositories',
    () {
      Future<List<ForgeHost?>> forgesFor({
        GitRepoInspectorPort? inspector,
        Future<List<ForgeRemote>> Function(String, String)? spaceRepos,
      }) async {
        final forges = <ForgeHost?>[];
        final h = _buildSession(
          inspector: inspector,
          spaceRepos: spaceRepos,
          identity: (forge) {
            forges.add(forge);
            return AgentCommitIdentity.automation();
          },
        );
        await h.session.run();
        return forges;
      }

      test('the checkout\'s, outside a space', () async {
        expect(await forgesFor(inspector: _FakeInspector(_gitlab)), [
          ForgeHost.gitlab,
        ]);
      });

      test('the one forge of a space\'s checkouts', () async {
        expect(
          await forgesFor(
            spaceRepos: (_, _) async => const [
              (forge: ForgeHost.bitbucket, owner: 'acme', name: 'shop-ui'),
              (forge: ForgeHost.bitbucket, owner: 'acme', name: 'api-server'),
            ],
          ),
          [ForgeHost.bitbucket],
        );
      });

      test('none when a space mixes forges, or has no checkout', () async {
        expect(
          await forgesFor(
            spaceRepos: (_, _) async => const [
              (forge: ForgeHost.github, owner: 'acme', name: 'shop-ui'),
              (forge: ForgeHost.gitlab, owner: 'acme', name: 'tools'),
            ],
          ),
          [null],
        );
        expect(await forgesFor(spaceRepos: (_, _) async => const []), [null]);
      });

      test('a requested run whose requester no forge vouches for says '
          'so', () async {
        final h = _buildSession(
          inspector: _FakeInspector(_gitlab),
          requestedByUserId: 'member-1',
          identity: (_) => AgentCommitIdentity.automation(),
        );
        final events = h.session.controller.stream.toList();

        await h.session.run();

        expect(
          (await events).whereType<DebugEvent>().map((e) => e.content),
          contains(
            allOf(
              startsWith("[identity] Commits from this run are the agent's"),
              contains('GitLab'),
            ),
          ),
        );
      });
    },
  );

  group('commit signing', () {
    const key =
        'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKeyKey';
    AgentCommitIdentity signedIdentity(ForgeHost? _) =>
        AgentCommitIdentity.person(
          (name: 'Ada', email: '7+ada@users.noreply.github.com'),
          creditAgent: true,
          signingKey: key,
        );

    test(
      'a run whose requester has a key gets git\'s signer in its own '
      'directory, registered with the gateway, and loses it at the end',
      () async {
        final gateway = _gateway(signing: _OneKey(key));
        AgentCommitIdentity? registered;
        FileStat? shim;
        late final ({DispatchSession session, Directory agentDir}) h;
        String shimPath() =>
            '${h.agentDir.path}/.cc-runs/d1/bin/${AgentRunSigning.shimName}';
        final runLogIds = <String?>[];
        h = _buildSession(
          requestedByUserId: 'member-1',
          identity: signedIdentity,
          gateway: gateway,
          runLogIds: runLogIds,
          whileRunning: () {
            registered = gateway
                .openRuns(workspaceId: 'ws-1', conversationId: 'conv-1')
                .single
                .grant
                .identity;
            shim = File(shimPath()).statSync();
          },
        );

        await h.session.run();

        expect(runLogIds, ['run-1'], reason: 'the resolver learns the run');
        expect(registered?.signingKey, key);
        expect(shim?.type, FileSystemEntityType.file);
        if (!Platform.isWindows) {
          expect(shim!.mode & 0x49, 0x49, reason: 'executable');
        }
        await _expectRemoved(shimPath());
        expect(
          gateway.openRuns(workspaceId: 'ws-1', conversationId: 'conv-1'),
          isEmpty,
        );
      },
      skip: Platform.isWindows ? 'the signer is a shell script' : false,
    );

    test('with a gateway that signs nothing the run is unsigned: no signer '
        'is written and its identity drops the key', () async {
      final gateway = _gateway();
      AgentCommitIdentity? registered;
      var shimExists = true;
      late final ({DispatchSession session, Directory agentDir}) h;
      h = _buildSession(
        requestedByUserId: 'member-1',
        identity: signedIdentity,
        gateway: gateway,
        whileRunning: () {
          registered = gateway
              .openRuns(workspaceId: 'ws-1', conversationId: 'conv-1')
              .single
              .grant
              .identity;
          shimExists = File(
            '${h.agentDir.path}/.cc-runs/d1/bin/${AgentRunSigning.shimName}',
          ).existsSync();
        },
      );

      await h.session.run();

      expect(registered, isNotNull);
      expect(registered!.signingKey, isNull);
      expect(registered!.author.name, 'Ada');
      expect(shimExists, isFalse);
    });
  });
}
