import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/repos.dart';
import 'package:drift/drift.dart';

part 'repo_dao.g.dart';

/// Data access object for the [ReposTable].
@DriftAccessor(tables: [ReposTable])
class RepoDao extends DatabaseAccessor<AppDatabase> with _$RepoDaoMixin {
  /// Creates a [RepoDao] bound to the given database.
  RepoDao(super.attachedDatabase);

  /// Watches all repos ordered by most recently updated.
  Stream<List<ReposTableData>> watchAll() => (select(
    reposTable,
  )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).watch();

  /// Returns a single repo by [id], or `null`.
  Future<ReposTableData?> getById(String id) =>
      (select(reposTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Inserts or updates a repo row.
  Future<void> upsertRepo(ReposTableCompanion entry) =>
      into(reposTable).insertOnConflictUpdate(entry);

  /// Deletes a repo by [id]. Linked workspace_repos rows cascade.
  Future<int> deleteRepo(String id) =>
      (delete(reposTable)..where((t) => t.id.equals(id))).go();
}
