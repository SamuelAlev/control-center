import 'package:drift/drift.dart';

/// Server-wide key/value metadata, in `global.db`.
///
/// Deliberately tiny and schema-free: it holds facts about the *install*, not
/// about any workspace. Its one required key is `install_id`, a uuid minted on
/// first boot and stamped into every workspace database file
/// (`workspace_meta.install_id`) so an exported workspace can be recognised as
/// foreign on import.
///
/// This is NOT a settings store. Operator-facing configuration lives in CLI
/// args / env (`CcServerConfig`), per-user rows (`user_preferences`), or
/// workspace-scoped policy tables.
class ServerMetaTable extends Table {
  /// Metadata key.
  TextColumn get key => text()();

  /// Metadata value.
  TextColumn get value => text()();

  @override
  String get tableName => 'server_meta';

  @override
  Set<Column> get primaryKey => {key};
}
