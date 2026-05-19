import 'package:drift/drift.dart';

/// Drift table for tickets — a dumb issue-tracking artifact (mirror + a thin
/// Control-Center overlay). One row carries the provider **mirror** (provider /
/// externalKey / url / title / description / priority / labels / status /
/// rawStatus) and the **overlay** (assignee / team / channel link / parent /
/// project). Agent execution no longer hangs off a ticket: pipelines dispatch
/// into hidden conversations and the output contract lives on the agent run.
/// A remote sync rewrites only the mirror columns, preserving the overlay.
@TableIndex(name: 'idx_tickets_workspace_status', columns: {#workspaceId, #status})
@TableIndex(name: 'idx_tickets_assignee_status', columns: {#assignedAgentId, #status})
@TableIndex(name: 'idx_tickets_parent', columns: {#parentTicketId})
@TableIndex(name: 'idx_tickets_project', columns: {#projectId})
class TicketsTable extends Table {
  /// Unique ticket id (UUID v4). For local tickets, also the external key.
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The backend that owns this ticket's canonical data.
  TextColumn get provider => text().withDefault(const Constant('local'))();

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
  TextColumn get labels => text().withDefault(const Constant('[]'))();

  /// Canonical normalized status.
  TextColumn get status => text().withDefault(const Constant('open'))();

  /// Provider's native state name (for lossless display).
  TextColumn get rawStatus => text().nullable()();

  /// Parent ticket (delegation / breakdown tree).
  TextColumn get parentTicketId => text()
      .nullable()
      .references(TicketsTable, #id, onDelete: KeyAction.cascade)();

  // --- overlay (Control-Center only) ---

  /// Owning project (a workspace-scoped grouping). Null when the ticket is not
  /// part of any project. No `.references()` — the FK constraint is declared in
  /// the migration so deleting a project sets this to null (orphaning, not
  /// cascading, its tickets).
  TextColumn get projectId => text().nullable()();

  /// Assigned agent (UUID or `user`), nullable for unassigned remote tickets.
  TextColumn get assignedAgentId => text().nullable()();

  /// Assigned team.
  TextColumn get assignedTeamId => text().nullable()();

  /// Delegating agent (for the delegation tree).
  TextColumn get delegatedByAgentId => text().nullable()();

  /// Linked discussion channel. No FK — cleaned up in application code, like
  /// `channel_participants.agent_id`.
  TextColumn get channelId => text().nullable()();


  /// Error message when failed.
  TextColumn get errorMessage => text().nullable()();

  /// JSON array of linked PR node ids.
  TextColumn get linkedPrIds => text().withDefault(const Constant('[]'))();

  /// Free-form JSON metadata.
  TextColumn get metadata => text().withDefault(const Constant('{}'))();

  // --- optimistic concurrency ---

  /// Version column for optimistic concurrency. Incremented on every mutation.
  IntColumn get version => integer().withDefault(const Constant(0))();

  // --- provenance ---

  /// How this ticket was created (manual, pipeline_step, agent_delegation, etc.).
  TextColumn get originKind => text().withDefault(const Constant('manual'))();


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
