import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/tables/pull_requests.dart';
import 'package:drift/drift.dart';

part 'pull_request_dao.g.dart';

/// Data access object for the [PullRequestsTable].
@DriftAccessor(tables: [PullRequestsTable])
class PullRequestDao extends DatabaseAccessor<AppDatabase>
    with _$PullRequestDaoMixin {
  /// Creates a [PullRequestDao] for the given database.
  PullRequestDao(super.attachedDatabase);

  /// Watches pull requests for a workspace ordered by creation time.
  Stream<List<PullRequestsTableData>> watchByWorkspace(String workspaceId) =>
      (select(pullRequestsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// Returns a PR by [id] or null.
  Future<PullRequestsTableData?> getById(String id) => (select(
    pullRequestsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts a new PR.
  Future<void> insert(PullRequestsTableCompanion entry) =>
      into(pullRequestsTable).insert(entry);

  /// Updates a PR by [id].
  Future<int> updatePr(String id, PullRequestsTableCompanion entry) =>
      (update(pullRequestsTable)..where((t) => t.id.equals(id))).write(entry);

  /// Deletes a PR by [id].
  Future<int> deleteById(String id) =>
      (delete(pullRequestsTable)..where((t) => t.id.equals(id))).go();
}
