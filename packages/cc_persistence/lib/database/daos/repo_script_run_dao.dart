import 'package:cc_persistence/database/tables/repo_script_runs.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'repo_script_run_dao.g.dart';

/// Data access object for the [RepoScriptRunsTable] — the recorded lifecycle
/// script runs of ONE workspace.
///
/// Like `RepoDao`, every method is implicitly scoped by hanging off a
/// [WorkspaceDatabase]; the redundant `workspaceId` column is still written on
/// every row so a file stays self-describing.
@DriftAccessor(tables: [RepoScriptRunsTable])
class RepoScriptRunDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$RepoScriptRunDaoMixin {
  /// Creates a [RepoScriptRunDao] bound to one workspace's database.
  RepoScriptRunDao(super.attachedDatabase);

  /// How many runs are kept per `(workspace, repo)`, newest first. Pruned
  /// after every insert so the table stays bounded without a sweeper.
  static const int retentionPerRepo = 25;

  /// Watches this workspace's runs, newest first, optionally filtered to one
  /// repo. This is the query behind the `repos.watchScriptRuns` subscription.
  Stream<List<RepoScriptRunsTableData>> watchRuns({
    String? repoId,
    int limit = 100,
  }) {
    final query =
        select(repoScriptRunsTable)..orderBy([
              (t) => OrderingTerm.desc(t.startedAt),
              (t) => OrderingTerm.desc(t.id),
            ]);
    if (repoId != null) {
      query.where((t) => t.repoId.equals(repoId));
    }
    query.limit(limit);
    return query.watch();
  }

  /// Inserts a run row and prunes this repo's history past [retentionPerRepo].
  ///
  /// The prune keeps the N newest `started_at` rows per repo (plus every row
  /// still `running`, so an in-flight run is never deleted out from under its
  /// own finish write).
  Future<void> insertRun(RepoScriptRunsTableCompanion entry) async {
    await transaction(() async {
      await into(repoScriptRunsTable).insert(entry);
      final repoId = entry.repoId.value;
      final keep = repoScriptRunsTable.id;
      final cutoff = (
        selectOnly(repoScriptRunsTable)
          ..addColumns([repoScriptRunsTable.id])
          ..where(
            repoScriptRunsTable.repoId.equals(repoId) &
                repoScriptRunsTable.status.equals('running').not(),
          )
          ..orderBy([
            OrderingTerm.desc(repoScriptRunsTable.startedAt),
            OrderingTerm.desc(repoScriptRunsTable.id),
          ])
          ..limit(retentionPerRepo)
      ).get();
      final kept =
          (await cutoff)
              .map((row) => row.read(keep))
              .whereType<String>()
              .toSet();
      await (
        delete(repoScriptRunsTable)..where(
          (t) =>
              t.repoId.equals(repoId) &
              t.status.equals('running').not() &
              t.id.isNotIn(kept),
        )
      ).go();
    });
  }

  /// Appends a progress write (bounded output tail) while a run is live.
  Future<void> updateOutput(String runId, String output) =>
      (update(repoScriptRunsTable)..where((t) => t.id.equals(runId))).write(
        RepoScriptRunsTableCompanion(outputText: Value(output)),
      );

  /// Closes a run with its outcome.
  Future<void> finishRun(
    String runId, {
    required String status,
    int? exitCode,
    String? error,
    String? output,
  }) => (update(repoScriptRunsTable)..where((t) => t.id.equals(runId))).write(
    RepoScriptRunsTableCompanion(
      status: Value(status),
      completedAt: Value(DateTime.now()),
      exitCode: Value(exitCode),
      error: Value(error),
      outputText: Value(output),
    ),
  );
}
