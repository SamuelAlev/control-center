import 'package:cc_persistence/database/tables/approvals_table.dart';
import 'package:drift/drift.dart';

/// How far a pending approval has escalated (requesting user, then admins,
/// then the owner). The next sweep comments only when the tier rises, so the
/// row is state and goes with its approval.
class ApprovalEscalationsTable extends Table {
  @override
  String get tableName => 'approval_escalations';

  /// The approval.
  TextColumn get approvalId =>
      text().references(ApprovalsTable, #id, onDelete: KeyAction.cascade)();

  /// The highest tier reached.
  // ignore: recursive_getters
  IntColumn get tier => integer().check(tier.isBiggerOrEqualValue(1))();

  /// When it reached it.
  DateTimeColumn get escalatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {approvalId};
}
