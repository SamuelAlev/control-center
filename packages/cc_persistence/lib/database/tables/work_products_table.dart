import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:cc_persistence/database/tables/work_product_revisions_table.dart';
import 'package:drift/drift.dart';

/// Drift table for work products — durable deliverable artifacts attached to a
/// task (plan, document, diff, report, …). A work product is the stable handle;
/// its content lives in versioned `work_product_revisions` rows, with
/// [currentRevisionId] pointing at the head. Workspace-scoped: every read
/// filters by [workspaceId].
///
/// A deliverable outlives the ticket and the agent it came from: both
/// references are `SET NULL`.
@TableIndex(name: 'idx_work_products_updated', columns: {#updatedAt})
@TableIndex(name: 'idx_work_products_ticket', columns: {#ticketId, #updatedAt})
@TableIndex(name: 'idx_work_products_agent', columns: {#agentId})
@TableIndex(
  name: 'idx_work_products_current_revision',
  columns: {#currentRevisionId},
)
class WorkProductsTable extends Table {
  /// Unique work-product identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Ticket this artifact is a deliverable of, if any.
  TextColumn get ticketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Agent that authored / owns the artifact, if any.
  TextColumn get agentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Short title of the artifact.
  TextColumn get title => text()();

  /// Artifact kind: a `WorkProductType` name.
  TextColumn get artifactType => text()
      // ignore: recursive_getters
      .check(artifactType.isIn(AgentsStoredValues.workProductType))
      .withDefault(const Constant('document'))();

  /// Head revision id, or null before the first revision is written.
  /// `SET NULL`: the head pointer falls away with the revision it named.
  TextColumn get currentRevisionId => text().nullable().references(
    WorkProductRevisionsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// When the artifact was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the artifact was last updated (new revision / metadata change).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'work_products';

  @override
  Set<Column> get primaryKey => {id};
}
