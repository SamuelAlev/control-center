import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/repo_isolation_port.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_infra/src/repos/repo_workspace_provisioner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;

import '../../fakes/fake_filesystem_port.dart';

class _FakeIsolation implements RepoIsolationPort {
  final List<String> destroyed = [];
  final List<_ProvisionCall> provisions = [];

  /// Fired inside [provision], so a test can stop the run at the exact moment
  /// a clone is under way.
  void Function()? onProvision;

  @override
  bool get isCowAvailable => false;

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    bool pristine = false,
    required String destParentDir,
    required String name,
    required String branch,
    String? authUrl,
    String baseRef = '',
    String? headRef,
    CancellationToken? cancel,
  }) async {
    provisions.add(
      _ProvisionCall(
        sourcePath: sourcePath,
        destParentDir: destParentDir,
        name: name,
        branch: branch,
        authUrl: authUrl,
      ),
    );
    // The clone is under way when the hook fires; a cancellation that lands
    // now kills it, exactly as the real adapter reports it.
    onProvision?.call();
    cancel?.throwIfCancelled();
    return RepoIsolationResult(
      path: '$destParentDir/$name',
      backend: RepoIsolationBackend.rift,
    );
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async => destroyed.add(path);
}

class _ProvisionCall {
  const _ProvisionCall({
    required this.sourcePath,
    required this.destParentDir,
    required this.name,
    required this.branch,
    this.authUrl,
  });
  final String sourcePath;
  final String destParentDir;
  final String name;
  final String branch;
  final String? authUrl;
}

class _FakeRegistry implements IsolatedRepoRepository {
  final List<IsolatedRepo> rows = [];

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => rows
      .where((r) => r.workspaceId == workspaceId && r.spaceId == spaceId)
      .toList();

  @override
  Future<List<IsolatedRepo>> forSpaceAcrossWorkspaces(String spaceId) async =>
      rows.where((r) => r.spaceId == spaceId).toList();

  @override
  Future<List<IsolatedRepo>> forTicket(
    String workspaceId,
    String ticketId,
  ) async => rows
      .where((r) => r.workspaceId == workspaceId && r.ticketId == ticketId)
      .toList();

  @override
  Future<List<IsolatedRepo>> forTicketAcrossWorkspaces(String ticketId) async =>
      rows.where((r) => r.ticketId == ticketId).toList();

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async => rows
      .where(
        (r) =>
            r.workspaceId == workspaceId &&
            r.spaceId == spaceId &&
            r.repoId == repoId,
      )
      .firstOrNull;

  @override
  Stream<List<IsolatedRepo>> watchForWorkspace(String workspaceId) =>
      Stream.value(rows.where((r) => r.workspaceId == workspaceId).toList());

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    rows.removeWhere((r) => r.id == repo.id);
    rows.add(repo);
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async =>
      rows.removeWhere((r) => r.id == id);
}

class _FakeWorkspaces implements WorkspaceRepository {
  _FakeWorkspaces(this._repos);
  final List<Repo> _repos;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      Stream.value(_repos);

  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => _repos.any((r) => r.id == repoId);

  @override
  Stream<List<Workspace>> watchAll() => const Stream.empty();
  @override
  Future<List<Workspace>> getAll() async => const [];
  @override
  Future<Workspace?> getById(String id) async => null;
  @override
  Future<String> upsert(Workspace workspace) async => workspace.id;
  @override
  Future<void> delete(String id) async {}
  @override
  Future<void> setReposForWorkspace(
    String workspaceId,
    List<String> repoIds,
  ) async {}
  @override
  Future<void> unlinkRepoFromWorkspace(
    String workspaceId,
    String repoId,
  ) async {}

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
}

IsolatedRepo _row(String id, String ws, String ch, {String? ticketId}) =>
    IsolatedRepo(
      id: id,
      workspaceId: ws,
      spaceId: ch,
      repoId: 'r-1',
      path: '/iso/$id',
      branch: 'feature/$id',
      backend: RepoIsolationBackend.rift,
      sourcePath: '/src',
      ticketId: ticketId,
      createdAt: DateTime(2026),
    );

Repo _makeRepo({
  String id = 'r-1',
  String name = 'owner/repo',
  String path = '/tmp/test-repo',
  String remoteOwner = 'owner',
  String remoteName = 'repo',
}) => Repo(
  id: id,
  name: name,
  path: path,
  remoteOwner: remoteOwner,
  remoteName: remoteName,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);

/// Builds a provisioner with plain fakes (no real filesystem).
RepoWorkspaceProvisioner _build({
  required IsolatedRepoRepository registry,
  required RepoIsolationPort isolation,
  List<Repo> repos = const [],
  FakeFilesystemPort? filesystem,
  Future<String?> Function()? githubToken,
  // Workspace-scoped and async, mirroring the port: the template is workspace
  // POLICY read from that workspace's settings store, not a device-local
  // preference.
  Future<String> Function(String workspaceId)? branchTemplate,
  Future<SpaceCheckoutScope?> Function(String workspaceId, String spaceId)?
  spaceCheckoutScope,
}) => RepoWorkspaceProvisioner(
  filesystem: filesystem ?? FakeFilesystemPort(),
  isolation: isolation,
  registry: registry,
  workspaces: _FakeWorkspaces(repos),
  githubToken: githubToken ?? (() async => ''),
  branchTemplate: branchTemplate ?? ((_) async => '{type}/{ticket-key}-{slug}'),
  spaceCheckoutScope: spaceCheckoutScope,
);

void main() {
  group('RepoWorkspaceProvisioner — the space owns its checkout scope', () {
    // A dispatch into an existing space passes NO allowlist. Before the space
    // could answer for itself, that meant "every repo in the workspace, on its
    // default branch" — so a PR review space scoped to one repo at the PR head
    // grew a full clone of every other repo the moment an agent was sent in,
    // once per agent.

    late Directory tempDir;
    late FakeFilesystemPort fs;

    setUp(() {
      // A real directory: the provisioner creates `<spaceRoot>/repos` before it
      // clones anything, and the fake port's default base is not creatable — so
      // without this every case silently returns the fallback dir having
      // provisioned nothing, and would pass an "is empty" assertion for the
      // wrong reason.
      tempDir = Directory.systemTemp.createTempSync('provisioner_scope_');
      fs = FakeFilesystemPort()..baseDir = tempDir.path;
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('a dispatch with no allowlist honours the space scope', () async {
      final isolation = _FakeIsolation();
      final p = _build(
        registry: _FakeRegistry(),
        isolation: isolation,
        filesystem: fs,
        repos: [
          _makeRepo(id: 'r-1', remoteName: 'under-review'),
          _makeRepo(id: 'r-2', remoteName: 'other'),
          _makeRepo(id: 'r-3', remoteName: 'another'),
        ],
        spaceCheckoutScope: (_, _) async =>
            const SpaceCheckoutScope(repoIds: {'r-1'}),
      );

      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'space-pr',
        agentSlug: 'qa',
        fallbackDir: '/agent/dir',
      );

      expect(isolation.provisions.map((c) => c.name), ['under-review']);
    });

    test('widening the space scope clones only the repo that was added', () async {
      // The space repo editor: a space already checked out `r-1` and the save
      // adds `r-2`, which `messaging.setSpaceRepos` answers by re-provisioning.
      // That run must materialize ONLY `r-2` — a second CoW copy of `r-1`
      // would re-pay its clone, re-run its setup script and throw away
      // whatever uncommitted work is sitting in the worktree the operator has
      // been using.
      final isolation = _FakeIsolation();
      final registry = _FakeRegistry();
      var selection = const SpaceCheckoutScope(repoIds: {'r-1'});
      final p = _build(
        registry: registry,
        isolation: isolation,
        filesystem: fs,
        repos: [
          _makeRepo(id: 'r-1', remoteName: 'first'),
          _makeRepo(id: 'r-2', remoteName: 'second'),
        ],
        spaceCheckoutScope: (_, _) async => selection,
      );

      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'ch',
        agentSlug: 'dev',
        fallbackDir: '/fallback',
      );
      expect(isolation.provisions.map((c) => c.name), ['first']);
      // The fake isolation port records the call without touching disk, and
      // the reuse check reads the REAL filesystem — so stand the worktree up
      // the way an actual clone would have left it.
      await Directory(registry.rows.single.path).create(recursive: true);

      selection = const SpaceCheckoutScope(repoIds: {'r-1', 'r-2'});
      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'ch',
        agentSlug: 'dev',
        fallbackDir: '/fallback',
      );

      // `first` appears exactly once across both runs: the second run reused it.
      expect(isolation.provisions.map((c) => c.name), ['first', 'second']);
      expect(isolation.destroyed, isEmpty);
      expect(
        registry.rows.map((r) => r.repoId),
        unorderedEquals(['r-1', 'r-2']),
      );
    });

    test('a PR space checks the repo out at the PR head', () async {
      final isolation = _FakeIsolation();
      final p = _build(
        registry: _FakeRegistry(),
        isolation: isolation,
        filesystem: fs,
        repos: [_makeRepo(id: 'r-1', remoteName: 'under-review')],
        spaceCheckoutScope: (_, _) async => const SpaceCheckoutScope(
          repoIds: {'r-1'},
          prHeadRef: 'refs/pull/42/head',
          prHeadRepoFullName: 'owner/under-review',
          prBranch: 'pr/42',
        ),
      );

      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'space-pr',
        agentSlug: 'qa',
        fallbackDir: '/agent/dir',
      );

      // The branch is the PR's, not a `conv/<id>` scratch branch — the agent
      // has to be able to commit and push the pull request it is reviewing.
      expect(isolation.provisions.single.branch, 'pr/42');
    });

    test('an explicit allowlist still wins over the space scope', () async {
      final isolation = _FakeIsolation();
      final p = _build(
        registry: _FakeRegistry(),
        isolation: isolation,
        filesystem: fs,
        repos: [
          _makeRepo(id: 'r-1', remoteName: 'one'),
          _makeRepo(id: 'r-2', remoteName: 'two'),
        ],
        spaceCheckoutScope: (_, _) async =>
            const SpaceCheckoutScope(repoIds: {'r-1'}),
      );

      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'space-1',
        agentSlug: 'dev',
        fallbackDir: '/agent/dir',
        repoAllowlist: const {'r-2'},
      );

      expect(isolation.provisions.map((c) => c.name), ['two']);
    });

    test('a space that selected no repos provisions none', () async {
      final isolation = _FakeIsolation();
      final p = _build(
        registry: _FakeRegistry(),
        isolation: isolation,
        filesystem: fs,
        repos: [_makeRepo(id: 'r-1')],
        // An EMPTY selection is "deliberately nothing" and must not read as
        // "no opinion" — that distinction is the whole reason the scope is
        // nullable rather than just a set.
        spaceCheckoutScope: (_, _) async =>
            const SpaceCheckoutScope(repoIds: <String>{}),
      );

      final dir = await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'space-1',
        agentSlug: 'dev',
        fallbackDir: '/agent/dir',
      );

      expect(isolation.provisions, isEmpty);
      expect(dir, '/agent/dir');
    });

    test('no scope resolver keeps the every-repo behaviour', () async {
      final isolation = _FakeIsolation();
      final p = _build(
        registry: _FakeRegistry(),
        isolation: isolation,
        filesystem: fs,
        repos: [
          _makeRepo(id: 'r-1', remoteName: 'one'),
          _makeRepo(id: 'r-2', remoteName: 'two'),
        ],
      );

      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'space-1',
        agentSlug: 'dev',
        fallbackDir: '/agent/dir',
      );

      expect(isolation.provisions.map((c) => c.name), ['one', 'two']);
    });

    test(
      'a resolver that throws degrades to every repo, not to none',
      () async {
        // Wasteful but correct. Refusing to provision would strand the agent
        // with no worktree at all, which is the worse of the two failures.
        final isolation = _FakeIsolation();
        final p = _build(
          registry: _FakeRegistry(),
          isolation: isolation,
          filesystem: fs,
          repos: [_makeRepo(id: 'r-1', remoteName: 'one')],
          spaceCheckoutScope: (_, _) async => throw StateError('db down'),
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'space-1',
          agentSlug: 'dev',
          fallbackDir: '/agent/dir',
        );

        expect(isolation.provisions.map((c) => c.name), ['one']);
      },
    );
  });

  group('RepoWorkspaceProvisioner', () {
    // ── Guard paths ──────────────────────────────────────────────────────

    test(
      'returns the fallback dir when the workspace has no linked repos',
      () async {
        final p = _build(
          registry: _FakeRegistry(),
          isolation: _FakeIsolation(),
        );
        final dir = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/agent/dir',
        );
        expect(dir, '/agent/dir');
      },
    );

    test('returns the fallback dir when workspaceId is empty', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(
        await p.ensureSpaceWorkspace(
          workspaceId: '',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        ),
        '/fallback',
      );
    });

    test('returns the fallback dir when spaceId is empty', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(
        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: '',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        ),
        '/fallback',
      );
    });

    // ── Provisioning flow (filesystem-backed) ────────────────────────────

    test(
      'provisions repos into space dir and returns the per-agent cwd',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_provision_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final isolation = _FakeIsolation();
          final registry = _FakeRegistry();
          final repo = _makeRepo();

          final p = _build(
            registry: registry,
            isolation: isolation,
            repos: [repo],
            filesystem: fs,
          );

          final dir = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch-12345678',
            agentSlug: 'dev',
            fallbackDir: '/fallback',
          );

          // cwd is the per-agent overlay, NOT the space root.
          expect(dir, '${tempDir.path}/w-1/spaces/ch-12345678/agents/dev');
          expect(isolation.provisions, hasLength(1));
          expect(isolation.provisions.first.sourcePath, repo.path);
          expect(
            isolation.provisions.first.destParentDir,
            '${tempDir.path}/w-1/spaces/ch-12345678/repos',
          );
          expect(isolation.provisions.first.name, 'repo');
          // Without ticket key/title, branch defaults to conv/<short-space>
          expect(isolation.provisions.first.branch, 'conv/ch-12345');
          expect(registry.rows, hasLength(1));
          expect(registry.rows.first.workspaceId, 'w-1');
          expect(registry.rows.first.spaceId, 'ch-12345678');
          expect(registry.rows.first.repoId, 'r-1');
          expect(registry.rows.first.branch, 'conv/ch-12345');
          expect(registry.rows.first.backend, RepoIsolationBackend.rift);
          expect(registry.rows.first.sourcePath, repo.path);
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test('releaseSpace removes the space dir (mcp.json + overlays)', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_release_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();
        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        final cwd = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch-12345678',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );
        // Simulate cc_server writing the token-bearing config into the overlay.
        File(
          path.join(cwd, '.mcp.json'),
        ).writeAsStringSync('{"Authorization":"Bearer secret"}');
        final convRoot = '${tempDir.path}/w-1/spaces/ch-12345678';
        expect(Directory(convRoot).existsSync(), isTrue);

        await p.releaseSpace(workspaceId: 'w-1', spaceId: 'ch-12345678');

        // Worktrees destroyed AND the whole space dir (overlays + the
        // token-bearing .mcp.json) is gone — no orphaned secret, no disk leak.
        expect(isolation.destroyed, hasLength(1));
        expect(registry.rows, isEmpty);
        expect(Directory(convRoot).existsSync(), isFalse);
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });

    test('branch naming uses ticket key/title when provided', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_branch_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch-12345678',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
          ticketKey: 'OMP-42',
          ticketTitle: 'Fix the thing',
          branchType: 'bugfix',
        );

        // BranchTemplateResolver renders {type}/{ticket-key}-{slug}
        // → bugfix/OMP-42-fix-the-thing
        expect(
          isolation.provisions.first.branch,
          'bugfix/OMP-42-fix-the-thing',
        );
        expect(registry.rows.first.ticketId, null); // ticketId not passed
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('the branch template is resolved for the CALLING workspace', () async {
      // The template is workspace POLICY — everyone working in a workspace
      // produces the same branch shape — so the provisioner must ask for THIS
      // workspace's template, not a global one. The callback used to take no
      // arguments and the server wired it to the built-in default, which meant
      // a template configured in the UI never reached the branch name at all;
      // this pins both halves (the id is threaded and the answer is used).
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_ws_template_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final asked = <String>[];

        final p = _build(
          registry: _FakeRegistry(),
          isolation: isolation,
          repos: [_makeRepo()],
          filesystem: fs,
          branchTemplate: (workspaceId) async {
            asked.add(workspaceId);
            return 'ws-$workspaceId/{ticket-key}';
          },
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-77',
          spaceId: 'ch-12345678',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
          ticketKey: 'OMP-42',
          ticketTitle: 'Fix the thing',
          branchType: 'bugfix',
        );

        expect(asked, ['w-77'], reason: 'the workspace id was not threaded');
        expect(isolation.provisions.first.branch, 'ws-w-77/OMP-42');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('branch naming uses ticketId when passed', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_ticket_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch-12345678',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
          ticketId: 't-42',
          ticketKey: 'OMP-42',
          ticketTitle: 'Fix the thing',
        );

        expect(registry.rows.first.ticketId, 't-42');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('slugifies repo name for worktree directory', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_slugify_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo(
          name: 'My Awesome Repo!!',
          remoteName: 'my-awesome-repo!!',
        );

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        // slugify('my-awesome-repo!!') → 'my-awesome-repo'
        expect(isolation.provisions.first.name, 'my-awesome-repo');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('fallback repo name to id when slug is empty', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_empty_slug_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo(name: '!!!', remoteName: '', id: 'my-repo-id');

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions.first.name, 'my-repo-id');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'passes authUrl when repo has GitHub remote and token is available',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_auth_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final isolation = _FakeIsolation();
          final registry = _FakeRegistry();
          final repo = _makeRepo(remoteOwner: 'alice', remoteName: 'widgets');

          final p = _build(
            registry: registry,
            isolation: isolation,
            repos: [repo],
            filesystem: fs,
            githubToken: () async => 'ghp_token',
          );

          await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'dev',
            fallbackDir: '/fallback',
          );

          expect(
            isolation.provisions.first.authUrl,
            'https://x-access-token:ghp_token@github.com/alice/widgets.git',
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test('does not pass authUrl when token is empty', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_no_auth_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
          githubToken: () async => '',
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions.first.authUrl, isNull);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('safeToken catches exceptions from token provider', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_token_err_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
          githubToken: () async => throw Exception('auth failed'),
        );

        final dir = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        // Should not crash; authUrl will be null since token is null
        expect(dir, isNot('/fallback'));
        expect(isolation.provisions.first.authUrl, isNull);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Worktree reuse ───────────────────────────────────────────────────

    test(
      'reuses existing worktree when registry entry and directory exist',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_reuse_',
        );
        try {
          // Create the "existing" worktree directory on disk
          final worktreePath = '${tempDir.path}/w-1/spaces/ch/repos/owner-repo';
          await Directory(worktreePath).create(recursive: true);

          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final isolation = _FakeIsolation();
          final registry = _FakeRegistry()
            ..rows.add(
              IsolatedRepo(
                id: 'existing-id',
                workspaceId: 'w-1',
                spaceId: 'ch',
                repoId: 'r-1',
                path: worktreePath,
                branch: 'conv/ch',
                backend: RepoIsolationBackend.rift,
                sourcePath: '/tmp/test-repo',
                createdAt: DateTime(2026),
              ),
            );
          final repo = _makeRepo();

          final p = _build(
            registry: registry,
            isolation: isolation,
            repos: [repo],
            filesystem: fs,
          );

          final dir = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'dev',
            fallbackDir: '/fallback',
          );

          expect(dir, '${tempDir.path}/w-1/spaces/ch/agents/dev');
          // Should NOT have provisioned — reuse
          expect(isolation.provisions, isEmpty);
          // Registry should still have just the original entry
          expect(registry.rows, hasLength(1));
          expect(registry.rows.first.id, 'existing-id');
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test(
      'destroys stale entry and reprovisions when worktree directory gone',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_stale_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final isolation = _FakeIsolation();
          // Path points to nonexistent dir — stale
          final stalePath = '${tempDir.path}/w-1/spaces/ch/repos/owner-repo';
          final registry = _FakeRegistry()
            ..rows.add(
              IsolatedRepo(
                id: 'stale-id',
                workspaceId: 'w-1',
                spaceId: 'ch',
                repoId: 'r-1',
                path: stalePath,
                branch: 'old-branch',
                backend: RepoIsolationBackend.gitWorktree,
                sourcePath: '/tmp/test-repo',
                createdAt: DateTime(2026),
              ),
            );
          final repo = _makeRepo();

          final p = _build(
            registry: registry,
            isolation: isolation,
            repos: [repo],
            filesystem: fs,
          );

          final dir = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'dev',
            fallbackDir: '/fallback',
          );

          expect(dir, '${tempDir.path}/w-1/spaces/ch/agents/dev');

          // Stale entry destroyed
          expect(isolation.destroyed, contains(stalePath));

          // Reprovisioned
          expect(isolation.provisions, hasLength(1));
          expect(isolation.provisions.first.name, 'repo');

          // Old row deleted, new one upserted
          expect(registry.rows.where((r) => r.id == 'stale-id'), isEmpty);
          expect(registry.rows, hasLength(1));
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    // ── Per-repo failure isolation ───────────────────────────────────────

    test('one repo failing to provision does not block others', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_partial_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final r1Path = '${tempDir.path}/w-1/spaces/ch-12/repos/repo';
        // ThrowingIsolation throws on destroy for r1's stale path, simulating
        // a failed _ensureRepo for r-1. r-2 should still provision fine.
        final isolation = _ThrowingIsolation(failOnPath: r1Path);
        final registry = _FakeRegistry();
        final repo1 = _makeRepo(id: 'r-1');
        final repo2 = _makeRepo(id: 'r-2', remoteName: 'other-repo');

        // Pre-populate a stale row for r-1 so destroy is called and throws
        registry.rows.add(
          IsolatedRepo(
            id: 'stale',
            workspaceId: 'w-1',
            spaceId: 'ch-12',
            repoId: 'r-1',
            path: r1Path,
            branch: 'old',
            backend: RepoIsolationBackend.rift,
            sourcePath: '/tmp/test-repo',
            createdAt: DateTime(2026),
          ),
        );

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo1, repo2],
          filesystem: fs,
        );

        final dir = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch-12',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        // Should still return the per-agent cwd (not fallback)
        expect(dir, '${tempDir.path}/w-1/spaces/ch-12/agents/dev');

        // Provision should have happened only for the second repo
        expect(isolation.provisions, hasLength(1));
        expect(isolation.provisions.first.name, 'other-repo');

        // Registry should have only repo2's entry (stale was deleted, r-1 failed)
        expect(registry.rows.where((r) => r.repoId == 'r-2'), hasLength(1));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Top-level exception resilience ───────────────────────────────────

    test(
      'ensureSpaceWorkspace returns fallbackDir on top-level error',
      () async {
        // WorkspaceRepository that throws on watchReposForWorkspace
        final thrower = _ThrowingWorkspaces();
        final p = RepoWorkspaceProvisioner(
          filesystem: FakeFilesystemPort(),
          isolation: _FakeIsolation(),
          registry: _FakeRegistry(),
          workspaces: thrower,
          githubToken: () async => '',
          branchTemplate: (_) async => '{type}/{ticket-key}-{slug}',
        );

        final dir = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/safe-fallback',
        );

        expect(dir, '/safe-fallback');
      },
    );

    // ── Per-agent overlay ────────────────────────────────────────────────

    test(
      'overlay cwd has a `repos` symlink to the space\'s shared repos',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_overlay_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final isolation = _FakeIsolation();
          final registry = _FakeRegistry();
          final repo = _makeRepo();

          final p = _build(
            registry: registry,
            isolation: isolation,
            repos: [repo],
            filesystem: fs,
          );

          final cwd = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'dev',
            fallbackDir: '/fallback',
          );

          final reposLink = Link(path.join(cwd, 'repos'));
          expect(reposLink.existsSync(), isTrue);
          // Relative link that resolves via the shared mount (identical
          // host/guest paths): cwd nests as convRoot/agents/<slug>, so the shared
          // repos dir is two levels up.
          expect(await reposLink.target(), '../../repos');
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test(
      'does not create a .mcp.json in the overlay (cc_server owns it)',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_no_mcp_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final p = _build(
            registry: _FakeRegistry(),
            isolation: _FakeIsolation(),
            repos: [_makeRepo()],
            filesystem: fs,
          );

          final cwd = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'dev',
            fallbackDir: '/fallback',
          );

          expect(File(path.join(cwd, '.mcp.json')).existsSync(), isFalse);
          // Nor at the space root.
          final convRoot = path.dirname(path.dirname(cwd));
          expect(File(path.join(convRoot, '.mcp.json')).existsSync(), isFalse);
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test(
      'links AGENTS.md + .agents from the agent config dir when provided',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_config_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          // Materialize the agent's global config dir with an AGENTS.md + .agents.
          final agentConfigDir = '${tempDir.path}/w-1/agents/dev';
          await Directory(
            path.join(agentConfigDir, '.agents', 'skills'),
          ).create(recursive: true);
          await File(
            path.join(agentConfigDir, 'AGENTS.md'),
          ).writeAsString('# Dev');

          final p = _build(
            registry: _FakeRegistry(),
            isolation: _FakeIsolation(),
            repos: [_makeRepo()],
            filesystem: fs,
          );

          final cwd = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'dev',
            agentConfigDir: agentConfigDir,
            fallbackDir: '/fallback',
          );

          final mdLink = Link(path.join(cwd, 'AGENTS.md'));
          expect(mdLink.existsSync(), isTrue);
          expect(await mdLink.target(), path.join(agentConfigDir, 'AGENTS.md'));

          final agentsLink = Link(path.join(cwd, '.agents'));
          expect(agentsLink.existsSync(), isTrue);
          expect(
            await agentsLink.target(),
            path.join(agentConfigDir, '.agents'),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test(
      'two agents in one channel share repos but get distinct overlays',
      () async {
        final tempDir = Directory.systemTemp.createTempSync(
          'provisioner_test_two_agents_',
        );
        try {
          final fs = FakeFilesystemPort()..baseDir = tempDir.path;
          final isolation = _FakeIsolation();
          final registry = _FakeRegistry();
          final repo = _makeRepo();

          final p = _build(
            registry: registry,
            isolation: isolation,
            repos: [repo],
            filesystem: fs,
          );

          final cwdA = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'alice',
            fallbackDir: '/fallback',
          );
          final cwdB = await p.ensureSpaceWorkspace(
            workspaceId: 'w-1',
            spaceId: 'ch',
            agentSlug: 'bob',
            fallbackDir: '/fallback',
          );

          // Distinct per-agent overlays.
          expect(cwdA, '${tempDir.path}/w-1/spaces/ch/agents/alice');
          expect(cwdB, '${tempDir.path}/w-1/spaces/ch/agents/bob');

          // Shared repos: every provision targets the SAME shared repos dir
          // (keyed by workspace+space+repo, NOT per-agent) and both overlays'
          // `repos` symlinks resolve to the same shared target.
          final sharedReposDir = '${tempDir.path}/w-1/spaces/ch/repos';
          expect(
            isolation.provisions.every(
              (c) => c.destParentDir == sharedReposDir,
            ),
            isTrue,
          );
          expect(
            await Link(path.join(cwdA, 'repos')).target(),
            await Link(path.join(cwdB, 'repos')).target(),
          );
        } finally {
          tempDir.deleteSync(recursive: true);
        }
      },
    );

    test('overlay build is idempotent across re-dispatches', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_idempotent_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final p = _build(
          registry: _FakeRegistry(),
          isolation: _FakeIsolation(),
          repos: [_makeRepo()],
          filesystem: fs,
        );

        final first = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );
        // Re-dispatch: reuses the same overlay + repos symlink (no throw, same path).
        final second = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        expect(second, first);
        expect(Link(path.join(second, 'repos')).existsSync(), isTrue);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Release paths ────────────────────────────────────────────────────

    test(
      'releaseSpace destroys + deletes every worktree for the space',
      () async {
        final registry = _FakeRegistry()
          ..rows.addAll([
            _row('a', 'w-1', 'ch'),
            _row('b', 'w-1', 'ch'),
            _row('c', 'w-1', 'other'),
          ]);
        final isolation = _FakeIsolation();
        final p = _build(registry: registry, isolation: isolation);

        await p.releaseSpace(workspaceId: 'w-1', spaceId: 'ch');

        expect(isolation.destroyed.toSet(), {'/iso/a', '/iso/b'});
        expect(registry.rows.map((r) => r.id), ['c']);
      },
    );

    test('releaseSpaceAnyWorkspace destroys across all workspaces', () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch'),
          _row('b', 'w-2', 'ch'),
          _row('c', 'w-3', 'other'),
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseSpaceAnyWorkspace(spaceId: 'ch');

      expect(isolation.destroyed.toSet(), {'/iso/a', '/iso/b'});
      expect(registry.rows.map((r) => r.id), ['c']);
    });

    test('releaseTicket destroys worktrees across workspaces', () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch', ticketId: 't-1'),
          _row('b', 'w-2', 'ch2', ticketId: 't-1'),
          _row('c', 'w-1', 'ch3', ticketId: 't-9'),
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseTicket(ticketId: 't-1');

      expect(isolation.destroyed.toSet(), {'/iso/a', '/iso/b'});
      expect(registry.rows.map((r) => r.id), ['c']);
    });

    test('destroyAll continues after per-row destruction failure', () async {
      final rows = [
        _row('a', 'w-1', 'ch'),
        _row('b', 'w-1', 'ch'),
        _row('c', 'w-1', 'ch'),
      ];
      final registry = _FakeRegistry()..rows.addAll(rows);

      // An isolation that throws on destroy for row 'b'
      final faultyIsolation = _ThrowingIsolation(failOnPath: '/iso/b');
      final p = _build(registry: registry, isolation: faultyIsolation);

      await p.releaseSpace(workspaceId: 'w-1', spaceId: 'ch');

      // All rows should still be deleted from registry despite the throw
      expect(registry.rows, isEmpty);
      // Destroys that succeeded
      expect(faultyIsolation.destroyed, contains('/iso/a'));
      expect(faultyIsolation.destroyed, contains('/iso/c'));
    });

    // ── Short space helper ─────────────────────────────────────────────

    test('short space id truncates to first 8 chars', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_short_',
      );
      try {
        final fs = FakeFilesystemPort()..baseDir = tempDir.path;
        final isolation = _FakeIsolation();
        final registry = _FakeRegistry();
        final repo = _makeRepo();

        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [repo],
          filesystem: fs,
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: '12345678901234',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions.first.branch, 'conv/12345678');
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    // ── Workspace-scoped ticket release ──────────────────────────────────

    test(
      'releaseTicketInWorkspace destroys only the matching workspace rows',
      () async {
        final registry = _FakeRegistry()
          ..rows.addAll([
            _row('a', 'w-1', 'ch', ticketId: 't-1'),
            _row('b', 'w-2', 'ch2', ticketId: 't-1'),
          ]);
        final isolation = _FakeIsolation();
        final p = _build(registry: registry, isolation: isolation);

        final n = await p.releaseTicketInWorkspace(
          workspaceId: 'w-1',
          ticketId: 't-1',
        );

        expect(n, 1);
        expect(isolation.destroyed, ['/iso/a']);
        expect(registry.rows.map((r) => r.id), ['b']);
      },
    );

    test(
      'releaseTicketInWorkspace is a no-op for a foreign-workspace ticket',
      () async {
        final registry = _FakeRegistry()
          ..rows.add(_row('a', 'w-2', 'ch', ticketId: 't-1'));
        final isolation = _FakeIsolation();
        final p = _build(registry: registry, isolation: isolation);

        final n = await p.releaseTicketInWorkspace(
          workspaceId: 'w-1',
          ticketId: 't-1',
        );

        expect(n, 0);
        expect(isolation.destroyed, isEmpty);
        expect(registry.rows.map((r) => r.id), ['a']);
      },
    );

    test('releaseTicketInWorkspace returns 0 for empty args', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(
        await p.releaseTicketInWorkspace(workspaceId: '', ticketId: 't'),
        0,
      );
      expect(
        await p.releaseTicketInWorkspace(workspaceId: 'w', ticketId: ''),
        0,
      );
    });

    // ── Stale sweep ──────────────────────────────────────────────────────

    test('sweepStale reaps rows whose on-disk worktree has vanished', () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'provisioner_test_sweep_',
      );
      try {
        final liveDir = Directory('${tempDir.path}/live')..createSync();
        final live = IsolatedRepo(
          id: 'live',
          workspaceId: 'w-1',
          spaceId: 'ch-live',
          repoId: 'r-1',
          path: liveDir.path,
          branch: 'b',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/src',
          createdAt: DateTime(2026),
        );
        final gone = IsolatedRepo(
          id: 'gone',
          workspaceId: 'w-1',
          spaceId: 'ch-gone',
          repoId: 'r-1',
          path: '${tempDir.path}/vanished',
          branch: 'b',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/src',
          createdAt: DateTime(2026),
        );
        final registry = _FakeRegistry()..rows.addAll([live, gone]);
        final isolation = _FakeIsolation();
        final p = _build(registry: registry, isolation: isolation);

        final reaped = await p.sweepStale(workspaceId: 'w-1');

        expect(reaped, 1);
        expect(isolation.destroyed, ['${tempDir.path}/vanished']);
        expect(registry.rows.map((r) => r.id), ['live']);
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('sweepStale only touches the given workspace', () async {
      final registry = _FakeRegistry()
        ..rows.addAll([
          _row('a', 'w-1', 'ch'), // /iso/a — vanished
          _row('b', 'w-2', 'ch'), // other workspace — ignored
        ]);
      final isolation = _FakeIsolation();
      final p = _build(registry: registry, isolation: isolation);

      final reaped = await p.sweepStale(workspaceId: 'w-1');

      expect(reaped, 1);
      expect(isolation.destroyed, ['/iso/a']);
      expect(registry.rows.map((r) => r.id), ['b']);
    });

    test('sweepStale returns 0 for an empty workspaceId', () async {
      final p = _build(registry: _FakeRegistry(), isolation: _FakeIsolation());
      expect(await p.sweepStale(workspaceId: ''), 0);
    });

    // ── Stopping a provision ─────────────────────────────────────────────

    test(
      'cancelling mid-run stops before the next repo is materialized',
      () async {
        // The point of the feature: a stop during the first clone must not be
        // answered by starting the second one.
        final tempDir = Directory.systemTemp.createTempSync('cancel_midrun_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final registry = _FakeRegistry();
        final isolation = _FakeIsolation();
        late final RepoWorkspaceProvisioner p;
        isolation.onProvision = () => p.cancelSpaceProvisioning('w-1', 'ch');
        p = _build(
          registry: registry,
          isolation: isolation,
          repos: [
            _makeRepo(id: 'r-1', remoteName: 'first'),
            _makeRepo(id: 'r-2', remoteName: 'second'),
          ],
          filesystem: FakeFilesystemPort()..baseDir = tempDir.path,
        );

        final dir = await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        expect(isolation.provisions, hasLength(1));
        expect(
          dir,
          '/fallback',
          reason: 'an interrupted provision has no overlay to hand back',
        );
        expect(p.isSpaceProvisioningCancelled('w-1', 'ch'), isTrue);
      },
    );

    test('a stop stands until someone re-provisions deliberately', () async {
      final tempDir = Directory.systemTemp.createTempSync('stop_stands_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final isolation = _FakeIsolation();
      final p = _build(
        registry: _FakeRegistry(),
        isolation: isolation,
        repos: [_makeRepo()],
        filesystem: FakeFilesystemPort()..baseDir = tempDir.path,
      );

      p.cancelSpaceProvisioning('w-1', 'ch');
      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'ch',
        agentSlug: 'dev',
        fallbackDir: '/fallback',
      );
      expect(
        isolation.provisions,
        isEmpty,
        reason: 'a dispatch arriving after the stop must not restart the clone',
      );

      p.clearSpaceProvisioningCancellation('w-1', 'ch');
      await p.ensureSpaceWorkspace(
        workspaceId: 'w-1',
        spaceId: 'ch',
        agentSlug: 'dev',
        fallbackDir: '/fallback',
      );
      expect(isolation.provisions, hasLength(1));
    });

    test(
      'a worktree row outside the space\'s repos dir is re-provisioned',
      () async {
        // Rows written before worktrees moved from `conversations/<id>/` to
        // `spaces/<id>/` name a directory that still EXISTS, so an existence
        // check alone would report "reuse" forever while the agent's overlay
        // symlinked into an empty `spaces/<id>/repos`.
        final tempDir = Directory.systemTemp.createTempSync('displaced_row_');
        addTearDown(() => tempDir.deleteSync(recursive: true));
        final legacy = Directory(
          path.join(
            tempDir.path,
            'w-1',
            'conversations',
            'ch',
            'repos',
            'repo',
          ),
        )..createSync(recursive: true);

        final registry = _FakeRegistry();
        registry.rows.add(
          IsolatedRepo(
            id: 'old',
            workspaceId: 'w-1',
            spaceId: 'ch',
            repoId: 'r-1',
            path: legacy.path,
            branch: 'conv/ch',
            backend: RepoIsolationBackend.rift,
            sourcePath: '/tmp/test-repo',
            createdAt: DateTime(2026),
          ),
        );
        final isolation = _FakeIsolation();
        final p = _build(
          registry: registry,
          isolation: isolation,
          repos: [_makeRepo()],
          filesystem: FakeFilesystemPort()..baseDir = tempDir.path,
        );

        await p.ensureSpaceWorkspace(
          workspaceId: 'w-1',
          spaceId: 'ch',
          agentSlug: 'dev',
          fallbackDir: '/fallback',
        );

        expect(isolation.destroyed, [legacy.path]);
        expect(isolation.provisions, hasLength(1));
        expect(
          isolation.provisions.single.destParentDir,
          path.join(tempDir.path, 'w-1', 'spaces', 'ch', 'repos'),
        );
      },
    );

    test('sweepStale removes the obsolete conversations/ tree', () async {
      final tempDir = Directory.systemTemp.createTempSync('legacy_tree_');
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final legacy = Directory(
        path.join(tempDir.path, 'w-1', 'conversations', 'ch'),
      )..createSync(recursive: true);

      final p = _build(
        registry: _FakeRegistry(),
        isolation: _FakeIsolation(),
        filesystem: FakeFilesystemPort()..baseDir = tempDir.path,
      );

      await p.sweepStale(workspaceId: 'w-1');

      expect(
        legacy.parent.existsSync(),
        isFalse,
        reason: 'checkouts nothing reads any more are pure disk cost',
      );
    });
  });

  group('releaseSpaceReposOutside', () {
    test('destroys only the deselected repos\u2019 worktrees', () async {
      final registry = _FakeRegistry();
      final isolation = _FakeIsolation();
      registry.rows.addAll([
        _row('w-a', 'w-1', 'ch-1').copyWith(repoId: 'r-a'),
        _row('w-b', 'w-1', 'ch-1').copyWith(repoId: 'r-b'),
        _row('w-c', 'w-1', 'ch-1').copyWith(repoId: 'r-c'),
        // Another space's worktree for the SAME repo never leaves.
        _row('w-x', 'w-1', 'ch-2').copyWith(repoId: 'r-b'),
        // Another workspace's row for the SAME (space, repo) never leaves.
        _row('w-y', 'w-2', 'ch-1').copyWith(repoId: 'r-b'),
      ]);
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseSpaceReposOutside(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        keepRepoIds: {'r-a', 'r-c'},
      );

      expect(isolation.destroyed, ['/iso/w-b']);
      expect(
        registry.rows.map((r) => r.id),
        unorderedEquals(['w-a', 'w-c', 'w-x', 'w-y']),
      );
    });

    test('an empty keep-set tears down every worktree of the space', () async {
      final registry = _FakeRegistry();
      final isolation = _FakeIsolation();
      registry.rows.addAll([
        _row('w-a', 'w-1', 'ch-1').copyWith(repoId: 'r-a'),
        _row('w-b', 'w-1', 'ch-1').copyWith(repoId: 'r-b'),
      ]);
      final p = _build(registry: registry, isolation: isolation);

      await p.releaseSpaceReposOutside(
        workspaceId: 'w-1',
        spaceId: 'ch-1',
        keepRepoIds: const {},
      );

      expect(isolation.destroyed, unorderedEquals(['/iso/w-a', '/iso/w-b']));
      expect(registry.rows, isEmpty);
    });

    test(
      'a null keep-set is a no-op (the space is on the all-repos default)',
      () async {
        final registry = _FakeRegistry();
        final isolation = _FakeIsolation();
        registry.rows.add(_row('w-a', 'w-1', 'ch-1').copyWith(repoId: 'r-a'));
        final p = _build(registry: registry, isolation: isolation);

        await p.releaseSpaceReposOutside(
          workspaceId: 'w-1',
          spaceId: 'ch-1',
          keepRepoIds: null,
        );

        expect(isolation.destroyed, isEmpty);
        expect(registry.rows, hasLength(1));
      },
    );
  });
}

// ── Throwing fakes for error-path tests ──────────────────────────────────

class _ThrowingWorkspaces implements WorkspaceRepository {
  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) =>
      throw Exception('BOOM');

  @override
  Stream<List<Workspace>> watchAll() => throw UnimplementedError();
  @override
  Future<List<Workspace>> getAll() => throw UnimplementedError();
  @override
  Future<Workspace?> getById(String id) => throw UnimplementedError();
  @override
  Future<String> upsert(Workspace workspace) => throw UnimplementedError();
  @override
  Future<void> delete(String id) => throw UnimplementedError();
  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      throw UnimplementedError();
  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();
  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      throw UnimplementedError();

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) async {}
}

class _ThrowingIsolation implements RepoIsolationPort {
  _ThrowingIsolation({required this.failOnPath});
  final String failOnPath;
  final List<String> destroyed = [];
  final List<_ProvisionCall> provisions = [];

  @override
  bool get isCowAvailable => false;

  @override
  Future<RepoIsolationResult> provision({
    required String sourcePath,
    bool pristine = false,
    required String destParentDir,
    required String name,
    required String branch,
    String baseRef = '',
    String? authUrl,
    String? headRef,
    CancellationToken? cancel,
  }) async {
    provisions.add(
      _ProvisionCall(
        sourcePath: sourcePath,
        destParentDir: destParentDir,
        name: name,
        branch: branch,
        authUrl: authUrl,
      ),
    );
    return RepoIsolationResult(
      path: '$destParentDir/$name',
      backend: RepoIsolationBackend.rift,
    );
  }

  @override
  Future<void> destroy({
    required String path,
    required String sourcePath,
    required RepoIsolationBackend backend,
    String? branch,
  }) async {
    if (path == failOnPath) {
      throw Exception('destroy failed');
    }
    destroyed.add(path);
  }
}
