import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Notices for the server owner, kept until they are resolved.
///
/// CROSS-WORKSPACE BY DESIGN — lives in `global.db`: a notice that a
/// workspace's database is damaged cannot be stored in that database. Only
/// the server owner reads it (`server.notices`); a notice names a workspace by
/// id and carries SQLite's finding, never workspace content.
class ServerNoticesTable extends Table {
  @override
  String get tableName => 'server_notices';

  /// What it is about: a `ServerNoticeKind` wire name.
  TextColumn get kind => text().check(
    // ignore: recursive_getters
    kind.isIn(PlatformStoredValues.serverNoticeKind),
  )();

  /// The thing it names (a workspace id). No foreign key: a notice is kept
  /// until it is resolved, whatever happened to what it names.
  TextColumn get subject => text()();

  /// The operator-facing finding.
  TextColumn get detail => text()();

  /// When it was first raised.
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {kind, subject};
}
