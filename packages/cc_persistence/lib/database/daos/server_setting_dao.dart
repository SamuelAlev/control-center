import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/server_settings_table.dart';
import 'package:drift/drift.dart';

part 'server_setting_dao.g.dart';

/// Data access object for [ServerSettingsTable].
///
/// Install-wide: there is no workspace dimension here by design. See the table
/// for why these settings are not workspace-scoped.
@DriftAccessor(tables: [ServerSettingsTable])
class ServerSettingDao extends DatabaseAccessor<GlobalDatabase>
    with _$ServerSettingDaoMixin {
  /// Creates a [ServerSettingDao] for the given database.
  ServerSettingDao(super.attachedDatabase);

  /// The value of [key], or null.
  Future<String?> getValue(String key) async {
    final row = await (select(
      serverSettingsTable,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  /// Every server setting.
  Future<List<ServerSettingsTableData>> getAll() =>
      select(serverSettingsTable).get();

  /// Watches every server setting.
  Stream<List<ServerSettingsTableData>> watchAll() =>
      select(serverSettingsTable).watch();

  /// Sets [key] to [value].
  Future<void> setValue(String key, String value) =>
      into(serverSettingsTable).insertOnConflictUpdate(
        ServerSettingsTableCompanion(
          key: Value(key),
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes [key].
  Future<int> deleteValue(String key) =>
      (delete(serverSettingsTable)..where((t) => t.key.equals(key))).go();
}
