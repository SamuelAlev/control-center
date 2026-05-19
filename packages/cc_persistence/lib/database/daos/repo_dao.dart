import 'package:cc_persistence/cc_persistence.dart' show CodeGraphDao;
import 'package:cc_persistence/database/daos/code_graph_dao.dart' show CodeGraphDao;
import 'package:cc_persistence/database/daos/daos.dart' show CodeGraphDao;
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'repo_dao.g.dart';

/// Data access object for the [ReposTable] — the repos of ONE workspace.
///
/// Every method is implicitly scoped: this DAO hangs off a
/// [WorkspaceDatabase], which is one workspace's own file. That is why the
/// signatures carry no `workspaceId` — there is no other workspace's repo to
/// accidentally read. The old server-global `repos` table plus its
/// `workspace_repos` join collapsed into this one table, so the link/unlink/
/// reorder methods that used to live on `WorkspaceDao` are here now.
@DriftAccessor(tables: [ReposTable])
class RepoDao extends DatabaseAccessor<WorkspaceDatabase> with _$RepoDaoMixin {
  /// Creates a [RepoDao] bound to one workspace's database.
  RepoDao(super.attachedDatabase);

  /// Watches this workspace's repos in the operator's manual drag-to-reorder
  /// [ReposTable.position] order ([ReposTable.linkedAt] as a stable tiebreak).
  ///
  /// This is the single query every repo list in the app flows through, so this
  /// ORDER BY is the app-wide repo order.
  Stream<List<ReposTableData>> watchAll() =>
      (select(reposTable)..orderBy([
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.linkedAt),
          ]))
          .watch();

  /// Returns this workspace's repos in the same order as [watchAll], for the
  /// one-shot readers.
  Future<List<ReposTableData>> getAll() =>
      (select(reposTable)..orderBy([
            (t) => OrderingTerm.asc(t.position),
            (t) => OrderingTerm.asc(t.linkedAt),
          ]))
          .get();

  /// Returns a single repo by [id], or `null` when this workspace has no such
  /// repo. A repo id from another workspace simply does not resolve — the
  /// isolation boundary is the database file.
  Future<ReposTableData?> getById(String id) =>
      (select(reposTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns the repo registered at [path], or `null`.
  ///
  /// Repo identity ACROSS workspaces is by path, never by id (each workspace
  /// mints its own id for a checkout), so this is the lookup that answers "is
  /// this checkout already in this workspace?".
  Future<ReposTableData?> getByPath(String path) =>
      (select(reposTable)..where((t) => t.path.equals(path))).getSingleOrNull();

  /// Whether [repoId] belongs to this workspace. The replacement for the old
  /// `isRepoLinkedToWorkspace` link probe, used to gate repo-scoped operations
  /// (e.g. the code-graph tools) before exposing a repo's data.
  Future<bool> exists(String repoId) async {
    final row =
        await (select(reposTable)
              ..where((t) => t.id.equals(repoId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Inserts or updates a repo row.
  ///
  /// A row being INSERTED with no explicit [ReposTable.position] is appended to
  /// the end of the manual order rather than landing on the default `0` (which
  /// would silently jump every new repo to the top of every repo list). An
  /// UPDATE never touches the stored position unless the caller passes one, so
  /// a rename can't reshuffle the list.
  Future<void> upsertRepo(ReposTableCompanion entry) async {
    var toWrite = entry;
    if (!entry.position.present && entry.id.present) {
      final present = await exists(entry.id.value);
      if (!present) {
        toWrite = entry.copyWith(position: Value(await _nextPosition()));
      }
    }
    await into(reposTable).insertOnConflictUpdate(toWrite);
  }

  /// The next free [ReposTable.position] (max + 1, or 0 when the workspace has
  /// no repos yet), so a newly added repo appends to the end of the manual
  /// order.
  Future<int> _nextPosition() async {
    final maxPos = reposTable.position.max();
    final row = await (selectOnly(
      reposTable,
    )..addColumns([maxPos])).getSingleOrNull();
    return (row?.read(maxPos) ?? -1) + 1;
  }

  /// Removes [repoId] from this workspace and drops its code-index rows
  /// (symbols/edges/files/checkpoints).
  ///
  /// The index rows carry an `ON DELETE CASCADE` FK to `repos`, so SQLite
  /// removes them for us — but the index CHECKPOINT is deleted explicitly
  /// anyway: a surviving checkpoint would make a re-add's first run
  /// short-circuit as "unchanged" and serve an empty graph (see
  /// [CodeGraphDao.deleteByRepo]). Both happen in one transaction so an
  /// interrupted delete can't leave a stale index behind.
  Future<int> deleteRepo(String repoId) async {
    var deleted = 0;
    await transaction(() async {
      await attachedDatabase.codeGraphDao.deleteByRepo(
        attachedDatabase.workspaceId,
        repoId,
      );
      deleted = await (delete(
        reposTable,
      )..where((t) => t.id.equals(repoId))).go();
    });
    return deleted;
  }

  /// Re-sequences this workspace's repos so each named row's
  /// [ReposTable.position] is its index in [repoIds].
  ///
  /// This is the drag-to-reorder write path; callers pass the full displayed
  /// list. Ids not present in this workspace are ignored (a repo cannot be
  /// created from an id alone — repos are registered from a path) and repos
  /// not named keep their stored position. Runs in one transaction so a partial
  /// write can never leave two repos claiming one slot.
  Future<void> reorderRepos(List<String> repoIds) async {
    await transaction(() async {
      for (var i = 0; i < repoIds.length; i++) {
        await (update(reposTable)..where((t) => t.id.equals(repoIds[i]))).write(
          ReposTableCompanion(position: Value(i)),
        );
      }
    });
  }

  /// The lifecycle scripts configured for [repoId]. The two columns are read
  /// as a pair; blank values normalize to null so callers never see a
  /// whitespace-only "configured" script.
  Future<({String? setup, String? archive})> getScripts(String repoId) async {
    final row = await getById(repoId);
    if (row == null) {
      return (setup: null, archive: null);
    }
    return (
      setup: _blankToNull(row.setupScript),
      archive: _blankToNull(row.archiveScript),
    );
  }

  /// Replaces the lifecycle scripts for [repoId]. A no-op when the repo does
  /// not exist in this workspace (an id from another workspace does not
  /// resolve — the isolation boundary is the database file).
  Future<void> setScripts(
    String repoId, {
    required String? setup,
    required String? archive,
  }) async {
    await (update(reposTable)..where((t) => t.id.equals(repoId))).write(
      ReposTableCompanion(
        setupScript: Value(_blankToNull(setup)),
        archiveScript: Value(_blankToNull(archive)),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
