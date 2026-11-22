import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:drift/drift.dart';

/// Drift table for tickets — a dumb issue-tracking artifact (mirror + a thin
/// Control-Center overlay). One row carries the provider **mirror** (provider /
/// externalKey / url / title / description / priority / labels / status /
/// rawStatus) and the **overlay** (assignee / team / space link / parent /
/// project). Agent execution no longer hangs off a ticket: pipelines dispatch
/// into hidden conversations and the output contract lives on the agent run.
/// A remote sync rewrites only the mirror columns, preserving the overlay.
///
/// Deleting a ticket deletes that ticket: its children become roots (the
/// parent key is `SET NULL`), and `DaoTicketRepository.deleteWithSubtree` is
/// the one call that removes a whole delegation tree.
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_tickets_provider_externalKey '
  'ON tickets (provider, external_key) WHERE external_key IS NOT NULL',
)
@TableIndex(name: 'idx_tickets_status_updated', columns: {#status, #updatedAt})
@TableIndex(
  name: 'idx_tickets_assignee_status',
  columns: {#assignedAgentId, #status},
)
@TableIndex(name: 'idx_tickets_parent', columns: {#parentTicketId})
@TableIndex(name: 'idx_tickets_project', columns: {#projectId})
@TableIndex(name: 'idx_tickets_team', columns: {#assignedTeamId})
@TableIndex(name: 'idx_tickets_delegated_by', columns: {#delegatedByAgentId})
@TableIndex(
  name: 'idx_tickets_delegation_root',
  columns: {#delegationRootTicketId},
)
@TableIndex(name: 'idx_tickets_space', columns: {#spaceId})
class TicketsTable extends Table {
  /// Unique ticket id (UUID v4). For local tickets, also the external key.
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The backend that owns this ticket's canonical data: a `TicketProvider`
  /// name.
  TextColumn get provider => text()
      .check(
        // ignore: recursive_getters
        provider.isIn(AgentsStoredValues.ticketProvider),
      )
      .withDefault(const Constant('local'))();

  /// Provider-native key (e.g. `LIN-123`). Null for unsynced local tickets.
  TextColumn get externalKey => text().nullable()();

  /// Web URL of the ticket on the remote provider.
  TextColumn get url => text().nullable()();

  /// Short title.
  TextColumn get title => text()();

  /// Body / description.
  TextColumn get description => text().nullable()();

  /// Priority (Linear's 0..4 scale; 0 = none).
  IntColumn get priority => integer().withDefault(const Constant(0))();

  /// JSON array of labels.
  TextColumn get labels => text()
      // ignore: recursive_getters
      .check(isJsonArray(labels))
      .withDefault(const Constant('[]'))();

  /// Canonical normalized status: a `TicketStatus` name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.ticketStatus),
      )
      .withDefault(const Constant('open'))();

  /// Provider's native state name (for lossless display). Open set: the
  /// provider's own workflow states.
  TextColumn get rawStatus => text().nullable()();

  /// When this ticket was last synced to/from any external vendor (multi-vendor
  /// sync). Null until the first sync. The per-vendor mapping lives in
  /// `ticket_sync_links`.
  DateTimeColumn get externalSyncedAt => dateTime().nullable()();

  /// Parent ticket (delegation / breakdown tree).
  ///
  /// `SET NULL`: deleting a ticket leaves its children as roots instead of
  /// deleting the subtree behind the caller's back.
  TextColumn get parentTicketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  // --- overlay (Control-Center only) ---

  /// Owning project (a workspace-scoped grouping). Null when the ticket is not
  /// part of any project. `SET NULL`: deleting a project orphans its tickets
  /// rather than removing them.
  TextColumn get projectId => text().nullable().references(
    ProjectsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Assigned principal id (agent id or user id, per [assigneeType]),
  /// nullable for unassigned remote tickets. No foreign key: the id names an
  /// agent here or a user in `global.db`, per [assigneeType].
  TextColumn get assignedAgentId => text().nullable()();

  /// Which kind of principal [assignedAgentId] names: a `PrincipalType` wire
  /// name.
  TextColumn get assigneeType => text()
      .check(
        // ignore: recursive_getters
        assigneeType.isIn(AgentsStoredValues.principalType),
      )
      .withDefault(const Constant('agent'))();

  /// The principal who created the ticket: a `PrincipalType` wire name, or
  /// `system` when no principal did.
  TextColumn get createdByType => text()
      .check(
        // ignore: recursive_getters
        createdByType.isIn(AgentsStoredValues.ticketCreatedByType),
      )
      .withDefault(const Constant('system'))();

  /// Id of the creating principal (agent id or user id), when known. No
  /// foreign key: it may name a user in `global.db`.
  TextColumn get createdById => text().nullable()();

  /// Assigned team. `SET NULL`: deleting a team unassigns its tickets.
  TextColumn get assignedTeamId => text().nullable().references(
    TeamsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Delegating agent (for the delegation tree). `SET NULL`: the delegated
  /// ticket outlives the agent that handed it on.
  TextColumn get delegatedByAgentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Delegation-chain depth (PRD 22 §3). 0 for a root/manual ticket, +1 per
  /// delegation hop. Materialized so the depth-cap guard is O(1) and never
  /// walks the parent graph. Existing rows default to 0.
  IntColumn get delegationDepth => integer().withDefault(const Constant(0))();

  /// The root ticket id of this delegation chain (PRD 22 §3). Equals the row's
  /// own id for a root; inherited by every delegated descendant. Lets the
  /// cycle detector and budget-envelope inheritance identify a chain without a
  /// graph walk. Null is treated as its own root, which is what `SET NULL`
  /// leaves on every descendant when the root ticket is deleted.
  TextColumn get delegationRootTicketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The conversation the delegating agent delegated from: where the
  /// completion wake goes when the ticket settles. A value, not a key: a
  /// wake to a deleted conversation is dropped by the wake queue.
  TextColumn get delegatedFromConversationId => text().nullable()();

  /// Linked discussion space. `SET NULL`: the ticket outlives the space.
  TextColumn get spaceId => text().nullable().references(
    SpacesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Error message when failed.
  TextColumn get errorMessage => text().nullable()();

  /// JSON array of linked PR node ids.
  TextColumn get linkedPrIds => text()
      // ignore: recursive_getters
      .check(isJsonArray(linkedPrIds))
      .withDefault(const Constant('[]'))();

  /// Free-form JSON metadata (an object).
  TextColumn get metadata => text()
      // ignore: recursive_getters
      .check(isJsonObject(metadata))
      .withDefault(const Constant('{}'))();

  // --- optimistic concurrency ---

  /// Version column for optimistic concurrency. Incremented on every mutation.
  IntColumn get version => integer().withDefault(const Constant(0))();

  // --- provenance ---

  /// How this ticket was created: a `TicketOriginKind` name.
  TextColumn get originKind => text()
      .check(
        // ignore: recursive_getters
        originKind.isIn(AgentsStoredValues.ticketOriginKind),
      )
      .withDefault(const Constant('manual'))();

  // --- timestamps ---

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When work started.
  DateTimeColumn get startedAt => dateTime().nullable()();

  /// When the ticket was blocked.
  DateTimeColumn get blockedAt => dateTime().nullable()();

  /// When the ticket was cancelled.
  DateTimeColumn get cancelledAt => dateTime().nullable()();

  /// When the ticket was completed successfully.
  DateTimeColumn get completedAt => dateTime().nullable()();

  /// When it reached a terminal state.
  DateTimeColumn get finishedAt => dateTime().nullable()();

  /// Last mutation timestamp.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'tickets';

  @override
  Set<Column> get primaryKey => {id};
}
