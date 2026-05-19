import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/user_preferences_table.dart';
import 'package:drift/drift.dart';

part 'user_preference_dao.g.dart';

/// Data access object for [UserPreferencesTable].
///
/// User-scoped: every query filters by `userId`. The session chokepoint
/// guarantees a caller only ever reaches their own rows.
@DriftAccessor(tables: [UserPreferencesTable])
class UserPreferenceDao extends DatabaseAccessor<GlobalDatabase>
    with _$UserPreferenceDaoMixin {
  /// Creates a [UserPreferenceDao] for the given database.
  UserPreferenceDao(super.attachedDatabase);

  /// The value of [key] for [userId], or null.
  Future<String?> getValue(String userId, String key) async {
    final row =
        await (select(userPreferencesTable)
              ..where((t) => t.userId.equals(userId) & t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  /// All preferences of [userId].
  Future<List<UserPreferencesTableData>> getForUser(String userId) => (select(
    userPreferencesTable,
  )..where((t) => t.userId.equals(userId))).get();

  /// Watches all preferences of [userId].
  Stream<List<UserPreferencesTableData>> watchForUser(String userId) => (select(
    userPreferencesTable,
  )..where((t) => t.userId.equals(userId))).watch();

  /// How many distinct keys [userId] holds.
  ///
  /// An indexed `COUNT` rather than `getForUser(userId).length`, so the
  /// per-user key quota does not read every value (one of which may be a
  /// few hundred KB) just to size the set.
  Future<int> countForUser(String userId) async {
    final expr = userPreferencesTable.key.count();
    final row =
        await (selectOnly(userPreferencesTable)
              ..addColumns([expr])
              ..where(userPreferencesTable.userId.equals(userId)))
            .getSingle();
    return row.read(expr) ?? 0;
  }

  /// Sets [key] to [value] for [userId].
  Future<void> setValue(String userId, String key, String value) =>
      into(userPreferencesTable).insertOnConflictUpdate(
        UserPreferencesTableCompanion(
          userId: Value(userId),
          key: Value(key),
          value: Value(value),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes [key] for [userId].
  Future<int> deleteValue(String userId, String key) => (delete(
    userPreferencesTable,
  )..where((t) => t.userId.equals(userId) & t.key.equals(key))).go();
}
