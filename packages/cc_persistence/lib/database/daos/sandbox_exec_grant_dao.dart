import 'package:cc_persistence/database/tables/sandbox_exec_grants_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'sandbox_exec_grant_dao.g.dart';

/// Data access for sandbox exec grants. Every read filters by `workspaceId`
/// (workspace isolation invariant).
@DriftAccessor(tables: [SandboxExecGrantsTable])
class SandboxExecGrantDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SandboxExecGrantDaoMixin {
  /// Creates a [SandboxExecGrantDao].
  SandboxExecGrantDao(super.db);

  /// Inserts or replaces a grant by id.
  Future<void> upsert(SandboxExecGrantsTableCompanion entry) =>
      into(sandboxExecGrantsTable).insertOnConflictUpdate(entry);

  /// All grants in [workspaceId], newest first.
  Future<List<SandboxExecGrantsTableData>> grants(String workspaceId) =>
      (select(sandboxExecGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  /// [limit] grants in [workspaceId] from [offset] whose path contains
  /// [query], newest first. `id` breaks `createdAt` ties so pages never
  /// overlap or skip a row.
  Future<List<SandboxExecGrantsTableData>> searchGrants(
    String workspaceId, {
    String? query,
    required int limit,
    required int offset,
  }) =>
      (select(sandboxExecGrantsTable)
            ..where((_) => _matching(workspaceId, query))
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(limit, offset: offset))
          .get();

  /// How many grants in [workspaceId] match [query] (see [searchGrants]).
  Future<int> countGrants(String workspaceId, {String? query}) async {
    final count = sandboxExecGrantsTable.id.count();
    final row =
        await (selectOnly(sandboxExecGrantsTable)
              ..addColumns([count])
              ..where(_matching(workspaceId, query)))
            .getSingle();
    return row.read(count) ?? 0;
  }

  /// Workspace filter plus a literal, case-insensitive substring match on the
  /// path. `%` and `_` are escaped rather than stripped: paths routinely carry
  /// underscores (`cc_server`), and stripping them would make the typed text
  /// stop matching.
  Expression<bool> _matching(String workspaceId, String? query) {
    final t = sandboxExecGrantsTable;
    final needle = query?.trim() ?? '';
    final inWorkspace = t.workspaceId.equals(workspaceId);
    if (needle.isEmpty) {
      return inWorkspace;
    }
    final escaped = needle
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
    return inWorkspace & t.path.like('%$escaped%', escapeChar: r'\');
  }

  /// Live grants in [workspaceId] (the Settings surface).
  Stream<List<SandboxExecGrantsTableData>> watchGrants(String workspaceId) =>
      (select(sandboxExecGrantsTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  /// The grant on exactly [path] within [workspaceId], or null.
  Future<SandboxExecGrantsTableData?> byPath(String workspaceId, String path) =>
      (select(sandboxExecGrantsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.path.equals(path),
          ))
          .getSingleOrNull();

  /// Deletes a grant within [workspaceId].
  Future<void> revoke(String workspaceId, String id) => (delete(
    sandboxExecGrantsTable,
  )..where((t) => t.workspaceId.equals(workspaceId) & t.id.equals(id))).go();
}
