@Timeout(Duration(minutes: 3))
library;

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
import 'package:cc_domain/features/sandboxing/domain/sandbox_policy.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/loop.dart';
import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dispatch/backends/harness_backend.dart';
import 'package:cc_infra/src/dispatch/dispatch_session.dart';
import 'package:cc_infra/src/dispatch/host_execution_gate.dart';
import 'package:cc_infra/src/dispatch/read_only_worktrees.dart';
import 'package:cc_infra/src/sandboxing/process_sandbox.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config_builder.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Changing a repository's checkout takes Control Center's write grant on it.
/// A run whose person lacks it on one of its space's repositories gets that
/// worktree read-only: in the sandbox spec (so in every backend that binds
/// it), and in the harness's own file-changing tools.
void main() {
  late _Tree tree;

  setUp(() => tree = _Tree.create());
  tearDown(() => tree.root.deleteSync(recursive: true));

  group('sandbox spec', () {
    test('a worktree the person may not write is bound read-only, after the '
        'writable repos dir', () async {
      final spec = await tree
          .session(writable: (_) => [tree.beta])
          .sandboxSpecForTesting();
      final mounts = spec.bindMounts;
      final repos = mounts.indexWhere(
        (m) => m.hostPath == tree.repos && !m.readOnly,
      );
      final alpha = mounts.indexWhere((m) => m.hostPath == tree.alpha);
      expect(repos, isNot(-1));
      expect(alpha, greaterThan(repos));
      expect(mounts[alpha].readOnly, isTrue);
      expect(mounts.where((m) => m.hostPath == tree.beta), isEmpty);
      final policy = const SandboxPolicyResolver().resolve(
        spec: spec,
        homeDir: tree.root.path,
        runDir: processSandboxRunDir(spec),
      );
      expect(policy.readOnlyMounts, contains(tree.alpha));
      expect(policy.readOnlyMounts, isNot(contains(tree.beta)));
    });

    test('a person with write on every repository gets exactly today\'s '
        'spec', () async {
      final granted = await tree
          .session(writable: (_) => [tree.alpha, tree.beta])
          .sandboxSpecForTesting();
      final today = await tree.session().sandboxSpecForTesting();
      expect(granted, today);
      expect(
        granted.bindMounts.where((m) => m.readOnly && _inRepos(tree, m)),
        isEmpty,
      );
    });

    test('a workspace admin writes both (the server answers every '
        'worktree)', () async {
      final spec = await tree
          .session(writable: (_) => [tree.alpha, tree.beta])
          .sandboxSpecForTesting();
      expect(
        spec.bindMounts.where((m) => m.readOnly && _inRepos(tree, m)),
        isEmpty,
      );
    });

    test('asks for the person the run acts for, in its workspace and '
        'space', () async {
      final asked = <(String, String, String?)>[];
      await tree
          .session(
            requestedBy: 'olga',
            writable: (call) {
              asked.add(call);
              return const [];
            },
          )
          .sandboxSpecForTesting();
      expect(asked, [('ws-1', 'space-1', 'olga')]);
    });

    test('a failed grant lookup makes every worktree read-only', () async {
      final spec = await tree
          .session(writable: (_) => throw StateError('db closed'))
          .sandboxSpecForTesting();
      expect(
        {
          for (final m in spec.bindMounts)
            if (m.readOnly && _inRepos(tree, m)) m.hostPath,
        },
        {tree.alpha, tree.beta},
      );
    });

    test('a read-only run binds every worktree read-only and asks for no '
        'grant, even for a person who may write both', () async {
      final asked = <(String, String, String?)>[];
      for (final writable in <List<String> Function(
        (String, String, String?),
      )?>[
        (call) {
          asked.add(call);
          return [tree.alpha, tree.beta];
        },
        null,
      ]) {
        final spec = await tree
            .session(writable: writable, readOnly: true)
            .sandboxSpecForTesting();
        expect(
          {
            for (final m in spec.bindMounts)
              if (m.readOnly && _inRepos(tree, m)) m.hostPath,
          },
          {tree.alpha, tree.beta},
        );
      }
      expect(asked, isEmpty);
    });

    test('a grant change between two runs changes the spec, so no warm '
        'sandbox is reused', () async {
      final before = await tree
          .session(writable: (_) => [tree.beta])
          .sandboxSpecForTesting();
      final after = await tree
          .session(writable: (_) => [tree.alpha, tree.beta])
          .sandboxSpecForTesting();
      expect(before.sessionId, after.sessionId);
      expect(before, isNot(after));
    });
  });

  group('harness tools', () {
    test('a write into the read-only worktree is refused with the grant '
        'kind; the writable one still writes', () async {
      final loop = _WritingLoop([
        p.join(tree.overlay, 'repos', 'alpha', 'README'),
        p.join(tree.overlay, 'repos', 'beta', 'README'),
      ]);
      await tree.session(writable: (_) => [tree.beta], loop: loop).run();

      expect(loop.roots, [tree.alpha]);
      final alpha = loop.results[0]!;
      expect(alpha.isError, isTrue);
      expect(alpha.refusal, {'kind': 'repo_grant_required', 'level': 'write'});
      expect(alpha.content, contains('alpha is read-only for this run'));
      expect(loop.results[1]!.isError, isFalse);
      expect(File(p.join(tree.alpha, 'README')).readAsStringSync(), 'alpha\n');
      expect(File(p.join(tree.beta, 'README')).readAsStringSync(), 'changed\n');
    });

    test('with write on every repository nothing is read-only', () async {
      final loop = _WritingLoop([
        p.join(tree.overlay, 'repos', 'alpha', 'README'),
      ]);
      await tree
          .session(writable: (_) => [tree.alpha, tree.beta], loop: loop)
          .run();

      expect(loop.roots, isEmpty);
      expect(loop.results[0]!.isError, isFalse);
      expect(
        File(p.join(tree.alpha, 'README')).readAsStringSync(),
        'changed\n',
      );
    });
  });

  test('ReadOnlyWorktrees.containing resolves links on both sides', () {
    final via = p.join(tree.overlay, 'repos', 'alpha', 'new', 'file.txt');
    expect(ReadOnlyWorktrees.containing(via, [tree.alpha]), tree.alpha);
    expect(
      ReadOnlyWorktrees.containing(
        p.join(tree.overlay, 'repos', 'beta', 'README'),
        [tree.alpha],
      ),
      isNull,
    );
  });

  group('real Seatbelt', () {
    late SandboxManager manager;
    late SandboxSpec spec;
    late String runDir;

    setUp(() async {
      // As the server does: its data dir is hidden but for what a run is
      // handed, so the space dir above `repos/` is not writable.
      manager = SandboxManager(hiddenPaths: [tree.data]);
      spec = await tree
          .session(writable: (_) => [tree.beta])
          .sandboxSpecForTesting();
      runDir = processSandboxRunDir(spec)!;
      Directory(runDir).createSync(recursive: true);
    });

    tearDown(() => manager.disposeSession(spec.sessionId));

    Future<ProcessResult> sandboxed(String script) async {
      final config = await buildSandboxConfigFromPolicy(
        const SandboxPolicyResolver().resolve(
          spec: spec,
          homeDir: tree.root.path,
          runDir: runDir,
        ),
      );
      final wrap = await manager.wrap(
        config: config,
        argv: ['/bin/bash', '-c', script],
        workingDirectory: tree.overlay,
      );
      return Process.run(
        wrap.executable,
        wrap.argv,
        workingDirectory: tree.overlay,
        environment: {...wrap.environment, 'HOME': tree.root.path},
        includeParentEnvironment: false,
      );
    }

    Future<void> expectDenied(String script) async {
      final r = await sandboxed(script);
      expect(r.exitCode, isNot(0), reason: '`$script` was allowed');
      expect(
        '${r.stderr}',
        contains('Operation not permitted'),
        reason: '`$script` failed for another reason: ${r.stderr}',
      );
    }

    Future<String> expectAllowed(String script) async {
      final r = await sandboxed(script);
      expect(r.exitCode, 0, reason: '`$script`: ${r.stderr}');
      return '${r.stdout}'.trim();
    }

    test('the read-only worktree reads but does not change', () async {
      expect(await expectAllowed('cat repos/alpha/README'), 'alpha');
      await expectDenied('echo x >> repos/alpha/README');
      await expectDenied('echo x > repos/alpha/new.txt');
      await expectDenied('rm repos/alpha/README');
      await expectDenied('mkdir repos/alpha/sub');
      await expectDenied('mv repos/alpha/README README.moved');
      await expectDenied('mv "${tree.alpha}" "${tree.repos}/alpha.old"');
      await expectDenied('ln repos/alpha/README hardlink');
      // Moving the shared repos dir would carry the worktree out from under
      // the rule that names it.
      await expectDenied('mv "${tree.repos}" "${tree.space}/repos.old"');
      expect(File(p.join(tree.alpha, 'README')).readAsStringSync(), 'alpha\n');
      expect(File(p.join(tree.overlay, 'hardlink')).existsSync(), isFalse);
    });

    test('the writable worktree and the run\'s own directory still '
        'write', () async {
      expect(
        await expectAllowed(
          'echo b > repos/beta/new.txt && cat repos/beta/new.txt && '
          'echo own > own.txt && cat own.txt',
        ),
        'b\nown',
      );
    });
  }, skip: Platform.isMacOS ? false : 'real Seatbelt proof runs on macOS');
}

bool _inRepos(_Tree tree, SandboxBindMount m) =>
    p.isWithin(tree.repos, m.hostPath);

/// Writes each of [targets] with the run's own `write` tool, in the context
/// the session hands its tools.
class _WritingLoop implements AgentLoop {
  _WritingLoop(this.targets);

  final List<String> targets;
  final Map<int, HarnessToolResult> results = {};
  List<String>? roots;

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
    roots = [for (final r in context!.readOnlyRoots) r.path];
    final write = [
      ...tools,
      ...deferredTools,
    ].firstWhere((t) => t.name == 'write');
    for (final (i, target) in targets.indexed) {
      results[i] = await write.execute({
        'path': target,
        'content': 'changed\n',
      }, context);
    }
    yield const LoopDone(LoopDoneReason.completed);
  }
}

/// A space with two repositories, `alpha` and `beta`, and an agent overlay
/// that reaches them through its `repos` link: the provisioner's layout.
final class _Tree {
  _Tree._(this.root);

  factory _Tree.create() {
    final root = Directory(
      Directory.systemTemp
          .createTempSync('cc-ro-worktrees-')
          .resolveSymbolicLinksSync(),
    );
    final t = _Tree._(root);
    for (final (dir, content) in [(t.alpha, 'alpha'), (t.beta, 'beta')]) {
      File(p.join(dir, 'README'))
        ..createSync(recursive: true)
        ..writeAsStringSync('$content\n');
    }
    Directory(t.configDir).createSync(recursive: true);
    Directory(t.overlay).createSync(recursive: true);
    Link(p.join(t.overlay, 'repos')).createSync(p.join('..', '..', 'repos'));
    return t;
  }

  final Directory root;

  String get data => p.join(root.path, 'data');
  String get workspace => p.join(data, 'ws-1');
  String get configDir => p.join(workspace, 'agents', 'agent-1');
  String get space => p.join(workspace, 'spaces', 'space-1');
  String get overlay => p.join(space, 'agents', 'agent-1');
  String get repos => p.join(space, 'repos');
  String get alpha => p.join(repos, 'alpha');
  String get beta => p.join(repos, 'beta');

  /// A harness dispatch of agent-1 in space-1. [writable] answers the
  /// server's grant lookup; null is a host without one.
  DispatchSession session({
    List<String> Function((String, String, String?) call)? writable,
    String? requestedBy = 'olga',
    AgentLoop? loop,
    bool readOnly = false,
  }) => DispatchSession(
    freshHistory: false,
    deps: SandboxDispatchDeps(
      hostExecution: const HostExecutionGate(
        posture: HostExecutionPosture.offByOwner,
      ),
      sandbox: _NoopSandbox(),
      agentRepo: _UnusedAgentRepo(),
      runLogRepo: _QuietRunLogRepo(),
      eventBus: null,
      writableWorktrees: writable == null
          ? null
          : (ws, space, acting) async => writable((ws, space, acting)),
      resolveCommitIdentity: (_, {workspaceId, runLogId, forge}) async =>
          AgentCommitIdentity.person((
            name: 'Test User',
            email: 'test@example.test',
          )),
      backendRegistry: BackendRegistry({'cc-harness': const HarnessBackend()}),
      harnessCredentialStore: _KeylessStore(),
      harnessProviderFactory: const HarnessProviderFactory(),
      agentLoop: loop ?? const AgentLoopRunner(),
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
    prompt: 'change the readme',
    agentDirHostPath: overlay,
    agentConfigDir: configDir,
    modelId: 'openai/test-model',
    callerEnv: const {},
    agentId: 'agent-1',
    workspaceId: 'ws-1',
    conversationId: 'conv-1',
    spaceId: 'space-1',
    runLogId: 'run-1',
    requestedByUserId: requestedBy,
    mode: Mode.chat,
    readOnly: readOnly,
  );
}

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

class _QuietRunLogRepo implements AgentRunLogRepository {
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
