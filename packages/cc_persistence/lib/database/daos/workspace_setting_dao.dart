import 'package:cc_persistence/database/tables/workspace_settings_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'workspace_setting_dao.g.dart';

/// Data access object for [WorkspaceSettingsTable].
///
/// Workspace-scoped: the database file already is one workspace and every
/// query additionally filters by `workspaceId` so a signature can never lose
/// the scope it is operating in.
@DriftAccessor(tables: [WorkspaceSettingsTable])
class WorkspaceSettingDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$WorkspaceSettingDaoMixin {
  /// Creates a [WorkspaceSettingDao] for the given database.
  WorkspaceSettingDao(super.attachedDatabase);

  /// The value of [key] for [workspaceId], or null.
  Future<String?> getValue(String workspaceId, String key) async {
    final row =
        await (select(workspaceSettingsTable)..where(
              (t) => t.workspaceId.equals(workspaceId) & t.key.equals(key),
            ))
            .getSingleOrNull();
    return row?.value;
  }

  /// All settings of [workspaceId].
  Future<List<WorkspaceSettingsTableData>> getForWorkspace(
    String workspaceId,
  ) => (select(
    workspaceSettingsTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).get();

  /// Watches all settings of [workspaceId].
  Stream<List<WorkspaceSettingsTableData>> watchForWorkspace(
    String workspaceId,
  ) => (select(
    workspaceSettingsTable,
  )..where((t) => t.workspaceId.equals(workspaceId))).watch();

  /// How many distinct keys [workspaceId] holds.
  ///
  /// An indexed `COUNT` rather than reading every row, so the key quota does
  /// not drag along every value just to size the set.
  Future<int> countForWorkspace(String workspaceId) async {
    final expr = workspaceSettingsTable.key.count();
    final row =
        await (selectOnly(workspaceSettingsTable)
              ..addColumns([expr])
              ..where(workspaceSettingsTable.workspaceId.equals(workspaceId)))
            .getSingle();
    return row.read(expr) ?? 0;
  }

  /// Sets [key] to [value] for [workspaceId].
  Future<void> setValue(String workspaceId, String key, String value) =>
      into(workspaceSettingsTable).insertOnConflictUpdate(
        WorkspaceSettingsTableCompanion(
          workspaceId: Value(workspaceId),
          key: Value(key),
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes [key] for [workspaceId].
  Future<int> deleteValue(String workspaceId, String key) =>
      (delete(workspaceSettingsTable)..where(
            (t) => t.workspaceId.equals(workspaceId) & t.key.equals(key),
          ))
          .go();
}
