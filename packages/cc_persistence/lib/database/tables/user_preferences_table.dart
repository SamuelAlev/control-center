import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:drift/drift.dart';

/// Drift table for per-user preferences (theme, fonts, keybindings,
/// notification prefs).
///
/// User-scoped, not workspace-scoped: a user's setup follows them across
/// desktop, web and phone. Values are opaque strings (JSON where
/// structured); the client owns each key's schema. Access is validated at
/// the session chokepoint (a session may only read/write its own user's
/// rows).
class UserPreferencesTable extends Table {
  /// The owning user.
  TextColumn get userId =>
      text().references(UsersTable, #id, onDelete: KeyAction.cascade)();

  /// Preference key (client-defined namespace, e.g. `theme_mode`).
  TextColumn get key => text()();

  /// Opaque preference value.
  TextColumn get value => text()();

  /// When the value was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'user_preferences';

  @override
  Set<Column> get primaryKey => {userId, key};
}
