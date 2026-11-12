import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:drift/drift.dart';

/// Grants an imported workspace file carried, held out of their live tables
/// until the server owner accepts or discards each one.
///
/// A held row is MOVED here (or, for a role or grant level, its live row is
/// demoted to the floor), never flagged in place: a flag is something every
/// resolver would have to remember to check, and one that forgot would
/// grant it. Nothing reads this table to decide anything; accepting a hold
/// writes its row back into the table it came from.
class ImportedAuthorityHoldsTable extends Table {
  @override
  String get tableName => 'imported_authority_holds';

  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// What the row grants: an `ImportHoldKind` wire name, which also decides
  /// the one table accepting it writes to.
  // Drift reads the column's own getter inside its CHECK to name the column;
  // the generator never evaluates it as a getter call.
  TextColumn get kind => text().check(
    // ignore: recursive_getters
    kind.isIn(const [
      'action_policy',
      'sandbox_exec_grant',
      'repo_grant',
      'membership_role',
      'invite',
    ]),
  )();

  /// The held row as the file had it, as a JSON object of column name to
  /// value.
  // ignore: recursive_getters
  TextColumn get payloadJson => text().check(isJsonObject(payloadJson))();

  /// When the import that held it ran.
  DateTimeColumn get importedAt => dateTime()();

  /// The install the imported file names in its `workspace_meta` row.
  TextColumn get sourceInstallId => text()();

  @override
  Set<Column> get primaryKey => {id};
}
