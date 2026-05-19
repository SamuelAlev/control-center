import 'package:drift/drift.dart';

/// Drift table for INSTALL-WIDE settings — configuration that bounds what any
/// process on this host may do, regardless of which workspace asked.
///
/// **CROSS-WORKSPACE BY DESIGN.** Lives in `global.db` because one host serves
/// every workspace: if workspace A could waive sandboxing, unsandboxed
/// processes would run on the same machine as workspace B. The operator of the
/// install owns these, not a workspace admin. A workspace may later *tighten*
/// a bound (require sandboxing) but never loosen one.
///
/// What belongs here: `sandbox_enabled`, `sandbox_backend` (a host capability),
/// and per-adapter launch argv/env — argv is handed to a process on this
/// machine, and env overrides are host credentials.
///
/// Deliberately separate from `server_meta`, whose doc comment states it is NOT
/// a settings store: install identity must never be user-writable, and mixing
/// it with operator config that must be would make that untrue.
///
/// Environment and CLI flags (`CcServerConfig`) take PRECEDENCE over rows here,
/// so an operator can pin a value that no admin UI can flip.
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
