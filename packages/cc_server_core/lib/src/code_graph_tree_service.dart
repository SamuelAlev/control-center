import 'dart:io';

import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/code_graph/domain/ports/code_graph_tree_port.dart';
import 'package:path/path.dart' as p;

/// Filesystem-backed [CodeGraphTreePort]: resolves the tree behind the
/// searched code-graph partition and reports which indexed paths still exist
/// in it.
///
/// The graph is partitioned per checkout: the linked checkout (what
/// `index_code` walks) plus one partition per space/PR worktree (built and kept
/// current by the `CodeGraphWatchService`). A space-scoped call therefore
/// resolves BOTH the searched partition and the audit tree to the space's
/// isolated repo copy; a non-space call uses the linked checkout for both.
///
/// The scope is the SPACE. `isolated_repos` is keyed by `space_id` and every
/// conversation in a space shares that one worktree, so a conversation id here
/// matches nothing: both lookups below miss, both fall back to the linked
/// checkout and an agent on a PR branch is answered from the base checkout
/// with no error anywhere.
///
/// Workspace isolation: the repo must be linked to `workspaceId`
/// ([WorkspaceRepository.isRepoLinkedToWorkspace]) and the worktree lookup is
/// workspace-scoped, so a foreign repo or space simply does not resolve and
/// the audit returns null (serve unfiltered) rather than reaching another
/// workspace's files.
class CodeGraphTreeService implements CodeGraphTreePort {
  /// Creates a [CodeGraphTreeService].
  CodeGraphTreeService({
    required RepoRepository repoRepository,
    required WorkspaceRepository workspaceRepository,
    required IsolatedRepoRepository isolatedRepoRepository,
  }) : _repos = repoRepository,
       _workspaces = workspaceRepository,
       _isolated = isolatedRepoRepository;

  final RepoRepository _repos;
  final WorkspaceRepository _workspaces;
  final IsolatedRepoRepository _isolated;

  @override
  Future<String?> checkoutIdFor({
    required String workspaceId,
    required String repoId,
    String? spaceId,
  }) async {
    if (spaceId == null || spaceId.isEmpty) {
      return null;
    }
    try {
      final worktrees = await _isolated.forSpace(workspaceId, spaceId);
      for (final worktree in worktrees) {
        if (worktree.repoId == repoId) {
          return worktree.id;
        }
      }
    } on Object {
      return null;
    }
    return null;
  }

  @override
  Future<CodeGraphPathAudit?> audit({
    required String workspaceId,
    required String repoId,
    required List<String> paths,
    String? spaceId,
    String? checkoutId,
  }) async {
    if (paths.isEmpty) {
      return const CodeGraphPathAudit(
        presentForCaller: {},
        goneFromIndexedTree: {},
      );
    }
    final linkedRoot = await _linkedCheckout(workspaceId, repoId);
    final callerRoot = await _callerCheckout(
      workspaceId: workspaceId,
      repoId: repoId,
      spaceId: spaceId,
      fallback: linkedRoot,
    );
    // The indexed tree is the tree the SEARCHED partition was built from: the
    // space's worktree when [checkoutId] selects its partition, else the
    // linked checkout.
    final indexedRoot = checkoutId == null ? linkedRoot : callerRoot;
    // Neither tree on disk (unlinked repo, missing checkout, host that owns no
    // worktrees) → no ground truth, so the caller must not filter.
    if (callerRoot == null && indexedRoot == null) {
      return null;
    }
    final presentForCaller = <String>{};
    final goneFromIndexedTree = <String>{};
    for (final path in paths) {
      if (callerRoot == null || _exists(callerRoot, path)) {
        presentForCaller.add(path);
      }
      if (indexedRoot != null && !_exists(indexedRoot, path)) {
        goneFromIndexedTree.add(path);
      }
    }
    return CodeGraphPathAudit(
      presentForCaller: presentForCaller,
      goneFromIndexedTree: goneFromIndexedTree,
    );
  }

  /// The space's isolated copy of [repoId], or [fallback] when the call is not
  /// space-scoped / the space has no copy of this repo.
  Future<String?> _callerCheckout({
    required String workspaceId,
    required String repoId,
    required String? spaceId,
    required String? fallback,
  }) async {
    if (spaceId == null || spaceId.isEmpty) {
      return fallback;
    }
    try {
      final worktrees = await _isolated.forSpace(workspaceId, spaceId);
      for (final worktree in worktrees) {
        if (worktree.repoId == repoId) {
          final root = p.normalize(worktree.path);
          return Directory(root).existsSync() ? root : fallback;
        }
      }
    } on Object {
      return fallback;
    }
    return fallback;
  }

  Future<String?> _linkedCheckout(String workspaceId, String repoId) async {
    try {
      if (!await _workspaces.isRepoLinkedToWorkspace(workspaceId, repoId)) {
        return null;
      }
      final repo = await _repos.getById(workspaceId, repoId);
      if (repo == null) {
        return null;
      }
      final root = p.normalize(repo.path);
      return Directory(root).existsSync() ? root : null;
    } on Object {
      return null;
    }
  }

  /// Whether [relativePath] exists under [root], with the traversal confinement
  /// the rest of the server applies — a path that escapes the root is treated as
  /// absent rather than probed.
  bool _exists(String root, String relativePath) {
    final resolved = p.normalize(p.join(root, relativePath));
    if (resolved == root || !p.isWithin(root, resolved)) {
      return false;
    }
    return File(resolved).existsSync();
  }
}
