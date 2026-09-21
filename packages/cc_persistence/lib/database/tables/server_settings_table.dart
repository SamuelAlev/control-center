import 'package:drift/drift.dart';

/// Install-wide host bounds (sandbox, adapter argv/env) — not workspace config.
///
/// CROSS-WORKSPACE BY DESIGN. Lives in `global.db`: one host serves every
/// workspace; a workspace may tighten a bound but never loosen one. Separate
/// from `server_meta` (install identity is not user-writable). Env/CLI
/// (`CcServerConfig`) take precedence over rows here.
class ServerSettingsTable extends Table {
  /// Setting key.
  TextColumn get key => text()();

  /// Opaque setting value.
  TextColumn get value => text()();

  /// When the value was last written.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'server_settings';

  @override
  Set<Column> get primaryKey => {key};
}
