import 'package:cc_persistence/database/tables/space_repos.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'space_repo_dao.g.dart';

/// Data access object for the [SpaceReposTable] — the per-space repo
/// selection recorded at space creation.
@DriftAccessor(tables: [SpaceReposTable])
class SpaceRepoDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SpaceRepoDaoMixin {
  /// Creates a [SpaceRepoDao] bound to the given database.
  SpaceRepoDao(super.attachedDatabase);

  /// The repo ids selected for [spaceId] in [workspaceId], in link order.
  /// Empty means "no explicit selection" — callers treat that as all workspace
  /// repos.
  Future<List<String>> repoIdsForSpace(
    String workspaceId,
    String spaceId,
  ) async {
    final rows =
        await (select(spaceReposTable)
              ..where(
                (t) =>
                    t.workspaceId.equals(workspaceId) &
                    t.spaceId.equals(spaceId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();
    return rows.map((r) => r.repoId).toList(growable: false);
  }

  /// The base branch each selected repo's worktree is cut from, for the repos
  /// that pin one. A repo absent from the map takes its own default branch.
  Future<Map<String, String>> repoBranchesForSpace(
    String workspaceId,
    String spaceId,
  ) async {
    final rows = await (select(spaceReposTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
        ))
        .get();
    return {
      for (final r in rows)
        if (r.branch != null && r.branch!.isNotEmpty) r.repoId: r.branch!,
    };
  }

  /// Records [repoIds] as the selection for [spaceId], optionally pinning each
  /// one to the base branch its worktree is cut from ([branches], keyed by repo
  /// id). Idempotent per `(spaceId, repoId)`. A no-op when [repoIds] is empty
  /// (leaves the space on the "all workspace repos" default).
  Future<void> setReposForSpace({
    required String workspaceId,
    required String spaceId,
    required List<String> repoIds,
    Map<String, String> branches = const {},
  }) async {
    if (repoIds.isEmpty) {
      return;
    }
    await batch((b) {
      b.insertAll(spaceReposTable, [
        for (final repoId in repoIds)
          SpaceReposTableCompanion.insert(
            workspaceId: workspaceId,
            spaceId: spaceId,
            repoId: repoId,
            branch: Value(branches[repoId]),
          ),
      ], mode: InsertMode.insertOrIgnore);
    });
  }

  /// Removes every selection row for [spaceId]. With the space's `no_repos`
  /// flag false this restores the "all workspace repos" default; with it
  /// true the space explicitly checks out nothing. Used by the selection
  /// replace, which re-inserts the surviving ids in the same transaction.
  Future<void> clearReposForSpace(String workspaceId, String spaceId) =>
      (delete(spaceReposTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) & t.spaceId.equals(spaceId),
          ))
          .go();
}
