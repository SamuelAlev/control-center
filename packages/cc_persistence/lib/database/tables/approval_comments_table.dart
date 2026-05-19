import 'package:cc_persistence/database/tables/approvals_table.dart';
import 'package:drift/drift.dart';

/// Drift table for approval comments — the review discussion attached to an
/// [ApprovalsTable] row. Comments are immutable once written and ordered by
/// [createdAt]. They cascade-delete with their parent approval.
@TableIndex(name: 'idx_approval_comments_approval', columns: {#approvalId})
class ApprovalCommentsTable extends Table {
  /// Unique comment identifier.
  TextColumn get id => text()();

  /// Approval this comment belongs to.
  TextColumn get approvalId =>
      text().references(ApprovalsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace (mirrors the parent approval's workspace).
  TextColumn get workspaceId => text()();

  /// Actor type that authored the comment (`user`, `agent`, `system`).
  TextColumn get authorType => text().withDefault(const Constant('user'))();

  /// Identifier of the authoring actor, if known.
  TextColumn get authorId => text().nullable()();

  /// The comment body.
  TextColumn get body => text()();

  /// When the comment was written.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'approval_comments';

  @override
  Set<Column> get primaryKey => {id};
}
