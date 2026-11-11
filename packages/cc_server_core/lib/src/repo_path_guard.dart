import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_repo_gate.dart';
import 'package:cc_host/cc_host.dart' show CcHostLog;
import 'package:path/path.dart' as p;

/// Why a repository's local path is refused.
enum RepoPathRefusal {
  /// Nothing exists at the path.
  missing('repo_path.missing'),

  /// The path is the server's data dir, lies inside it (another workspace's
  /// storage included), or contains it.
  dataDir('repo_path.data_dir'),

  /// The path is the workspace's own directory, which holds its database.
  workspaceRoot('repo_path.workspace_root'),

  /// A path outside the workspace's storage that the server owner did not
  /// link.
  hostPath('repo_path.host_path'),

  /// The checkout's `origin` names another repository than the stored one.
  originMismatch('repo_path.origin_mismatch');

  const RepoPathRefusal(this.wire);

  /// The error code a refusal carries.
  final String wire;
}

/// A repository path the server will neither link nor read.
final class RepoPathRefused extends ValidationException {
  /// Creates the refusal.
  RepoPathRefused(this.reason, String message)
    : super(message, code: reason.wire);

  /// Why.
  final RepoPathRefusal reason;
}

/// Where a linked repository's checkout may live.
///
/// The path is canonicalized with symlinks resolved, and must exist. A path
/// under the workspace's own directory is accepted. A path that is, lies in
/// or contains the server's data dir (which holds every workspace's storage,
/// the server's secrets and its databases) is refused. Any other path on the
/// host is accepted only when the server owner linked it: only the host's
/// owner may point the server at the host's files.
///
/// The same check runs when a path is linked ([check], with the person
/// linking it) and whenever a stored repository is read ([admit], with the
/// person recorded as having linked it), so a row stored before the check,
/// imported from another server, or retargeted by a symlink is refused too.
final class RepoPathGuard {
  /// Creates the guard over the server's data dir.
  RepoPathGuard({
    required this._dataDir,
    required this._workspaceDir,
    required this._serverOwnerUserId,
  });

  final String _dataDir;
  final Future<String> Function(String workspaceId) _workspaceDir;
  final String? _serverOwnerUserId;
  final Set<String> _reported = {};

  /// [path], canonical, when [linkedBy] may link it into [workspaceId].
  /// Throws [RepoPathRefused] otherwise.
  Future<String> check(
    String workspaceId,
    String path, {
    required String linkedBy,
  }) async {
    final resolved = _canonical(path);
    if (resolved == null) {
      throw RepoPathRefused(
        RepoPathRefusal.missing,
        'Nothing exists at $path on the server.',
      );
    }
    final own = _canonical(await _workspaceDir(workspaceId));
    if (own != null && p.equals(own, resolved)) {
      throw RepoPathRefused(
        RepoPathRefusal.workspaceRoot,
        "A repository cannot be the workspace's own directory.",
      );
    }
    if (own != null && p.isWithin(own, resolved)) {
      return resolved;
    }
    final data = _canonical(_dataDir) ?? p.normalize(p.absolute(_dataDir));
    if (p.equals(data, resolved) ||
        p.isWithin(data, resolved) ||
        p.isWithin(resolved, data)) {
      throw RepoPathRefused(
        RepoPathRefusal.dataDir,
        "A repository cannot point into the server's data directory.",
      );
    }
    final owner = _serverOwnerUserId;
    if (owner != null && owner.isNotEmpty && linkedBy == owner) {
      return resolved;
    }
    throw RepoPathRefused(
      RepoPathRefusal.hostPath,
      "Only the server's owner can link a checkout outside this workspace's "
      'storage.',
    );
  }

  /// [repo] with its canonical path, when its stored path is still one its
  /// recorded linker may link. Throws [RepoPathRefused] otherwise.
  Future<Repo> admit(String workspaceId, Repo repo) async => repo.copyWith(
    path: await check(workspaceId, repo.path, linkedBy: repo.linkedBy),
  );

  /// Why [repo]'s stored path is not served ([admit]), or null when it is.
  Future<RepoPathRefusal?> refusalOf(String workspaceId, Repo repo) async {
    try {
      await admit(workspaceId, repo);
      return null;
    } on RepoPathRefused catch (e) {
      return e.reason;
    }
  }

  /// The [repos] of [workspaceId] whose stored paths are served
  /// ([admit]), with canonical paths. A refused one is left out and logged
  /// once.
  Future<List<Repo>> served(String workspaceId, List<Repo> repos) async {
    final out = <Repo>[];
    for (final repo in repos) {
      try {
        out.add(await admit(workspaceId, repo));
      } on RepoPathRefused catch (e) {
        if (_reported.add('$workspaceId\u0000${repo.id}\u0000${e.code}')) {
          CcHostLog.warning(
            'repos: not serving ${repo.id} in $workspaceId (${e.code})',
          );
        }
      }
    }
    return out;
  }

  /// Refuses a forge [repo] whose checkout at [path] has an `origin` naming
  /// another forge repository than the one stored.
  static Future<void> requireOrigin(
    GitRepoInspectorPort inspector,
    String path,
    Repo repo,
  ) async {
    final info = await inspector.inspect(path);
    if (info.forge != repo.forge ||
        info.owner.toLowerCase() != repo.remoteOwner.toLowerCase() ||
        info.repoName.toLowerCase() != repo.remoteName.toLowerCase()) {
      throw RepoPathRefused(
        RepoPathRefusal.originMismatch,
        "The checkout's origin is ${info.owner}/${info.repoName} on "
        '${info.forge.displayName}, not ${repo.fullName}.',
      );
    }
  }

  static String? _canonical(String path) {
    try {
      final type = FileSystemEntity.typeSync(path);
      if (type == FileSystemEntityType.notFound) {
        return null;
      }
      return p.normalize(
        type == FileSystemEntityType.directory
            ? Directory(path).resolveSymbolicLinksSync()
            : File(path).resolveSymbolicLinksSync(),
      );
    } on FileSystemException {
      return null;
    }
  }
}

/// The server's repositories as readers see them: a repository whose stored
/// path [RepoPathGuard] refuses is left out of every listing and refused
/// (with [RepoPathRefused]) when asked for by id or path, and a served one
/// carries its canonical path. Writes pass through; the ops that link a
/// path check it first.
final class GuardedRepoRepository implements RepoRepository {
  /// Wraps [_inner].
  GuardedRepoRepository(this._inner, this._guard);

  final RepoRepository _inner;
  final RepoPathGuard _guard;

  @override
  Stream<List<Repo>> watchAll(String workspaceId) => _inner
      .watchAll(workspaceId)
      .asyncMap((repos) => _guard.served(workspaceId, repos));

  @override
  Future<List<Repo>> getAll(String workspaceId) async =>
      _guard.served(workspaceId, await _inner.getAll(workspaceId));

  @override
  Future<Repo?> getById(String workspaceId, String repoId) async {
    final repo = await _inner.getById(workspaceId, repoId);
    return repo == null ? null : _guard.admit(workspaceId, repo);
  }

  @override
  Future<Repo?> findByPath(String workspaceId, String path) async {
    final repo = await _inner.findByPath(workspaceId, path);
    return repo == null ? null : _guard.admit(workspaceId, repo);
  }

  @override
  Future<bool> exists(String workspaceId, String repoId) =>
      _inner.exists(workspaceId, repoId);

  @override
  Future<String> upsert(String workspaceId, Repo repo) =>
      _inner.upsert(workspaceId, repo);

  @override
  Future<void> delete(String workspaceId, String repoId) =>
      _inner.delete(workspaceId, repoId);

  @override
  Future<void> reorder(String workspaceId, List<String> orderedIds) =>
      _inner.reorder(workspaceId, orderedIds);
}

/// [WorkspaceRepository] whose repository listing is [RepoPathGuard]'s
/// ([RepoPathGuard.served]), for readers that list a workspace's repos to
/// reach their checkouts (the space provisioner, the IDE). Everything else
/// passes through.
final class ServedWorkspaceRepository implements WorkspaceRepository {
  /// Wraps [_inner].
  ServedWorkspaceRepository(this._inner, this._guard);

  final WorkspaceRepository _inner;
  final RepoPathGuard _guard;

  @override
  Stream<List<Repo>> watchReposForWorkspace(String workspaceId) => _inner
      .watchReposForWorkspace(workspaceId)
      .asyncMap((repos) => _guard.served(workspaceId, repos));

  @override
  Stream<List<Workspace>> watchAll() => _inner.watchAll();

  @override
  Future<List<Workspace>> getAll() => _inner.getAll();

  @override
  Future<Workspace?> getById(String id) => _inner.getById(id);

  @override
  Future<String> upsert(Workspace workspace) => _inner.upsert(workspace);

  @override
  Future<void> delete(String id) => _inner.delete(id);

  @override
  Future<void> reorderWorkspaces(List<String> orderedIds) =>
      _inner.reorderWorkspaces(orderedIds);

  @override
  Future<void> setReposForWorkspace(String workspaceId, List<String> repoIds) =>
      _inner.setReposForWorkspace(workspaceId, repoIds);

  @override
  Future<bool> isRepoLinkedToWorkspace(String workspaceId, String repoId) =>
      _inner.isRepoLinkedToWorkspace(workspaceId, repoId);

  @override
  Future<void> unlinkRepoFromWorkspace(String workspaceId, String repoId) =>
      _inner.unlinkRepoFromWorkspace(workspaceId, repoId);
}

/// The code graph's repository check: the repository is linked to the
/// workspace ([workspaces]) and its stored row ([repos], unguarded) passes
/// [guard]. A
/// repository whose path is refused keeps its index but is neither searched
/// nor listed until it is linked again.
CodeGraphRepoGate servedCodeGraphRepos({
  required WorkspaceRepository workspaces,
  required RepoRepository repos,
  required RepoPathGuard guard,
}) => (workspaceId, repoId) async {
  if (!await workspaces.isRepoLinkedToWorkspace(workspaceId, repoId)) {
    return false;
  }
  final repo = await repos.getById(workspaceId, repoId);
  return repo != null && await guard.refusalOf(workspaceId, repo) == null;
};
