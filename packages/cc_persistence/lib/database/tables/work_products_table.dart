import 'package:drift/drift.dart';

/// Drift table for work products — durable deliverable artifacts attached to a
/// task (plan, document, diff, report, …). A work product is the stable handle;
/// its content lives in versioned `work_product_revisions` rows, with
/// [currentRevisionId] pointing at the head. Workspace-scoped: every read
/// filters by [workspaceId].
@TableIndex(name: 'idx_work_products_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_work_products_ticket', columns: {#ticketId})
class WorkProductsTable extends Table {
  /// Unique work-product identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Ticket this artifact is a deliverable of, if any.
  TextColumn get ticketId => text().nullable()();

  /// Agent that authored / owns the artifact, if any.
  TextColumn get agentId => text().nullable()();

  /// Short title of the artifact.
  TextColumn get title => text()();

  /// Artifact kind: `plan`, `document`, `diff`, `report`, or `note`.
  TextColumn get artifactType =>
      text().withDefault(const Constant('document'))();

  /// Head revision id, or null before the first revision is written.
  TextColumn get currentRevisionId => text().nullable()();

  /// When the artifact was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the artifact was last updated (new revision / metadata change).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'work_products';

  @override
  Set<Column> get primaryKey => {id};
}
