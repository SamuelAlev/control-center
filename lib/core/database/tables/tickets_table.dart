import 'package:control_center/core/database/tables/pipeline_runs_table.dart';
import 'package:drift/drift.dart';

/// Drift table for tickets — the unified work-item model (absorbs the old
/// `tasks` table). One row carries both the provider **mirror** (provider /
/// externalKey / url / title / description / priority / labels / status /
/// rawStatus) and the Control-Center **overlay** (assignee / team / channel /
/// conversation mode / pipeline coupling). A remote sync rewrites only the
/// mirror columns, preserving the overlay.
@TableIndex(name: 'idx_tickets_workspace_status', columns: {#workspaceId, #status})
@TableIndex(name: 'idx_tickets_assignee_status', columns: {#assignedAgentId, #status})
@TableIndex(name: 'idx_tickets_pipelineStep', columns: {#pipelineRunId, #pipelineStepId})
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

  /// Conversation mode used when dispatching agents on this ticket.
  TextColumn get mode => text().withDefault(const Constant('chat'))();

  /// Owning pipeline run (when pipeline-tracked).
  TextColumn get pipelineRunId => text()
      .nullable()
      .references(PipelineRunsTable, #id, onDelete: KeyAction.setNull)();

  /// Pipeline step that created this ticket (resume-listener key).
  TextColumn get pipelineStepId => text().nullable()();

  /// JSON schema the output should conform to.
  TextColumn get expectedOutputSchema => text().nullable()();

  /// How strictly output is validated against [expectedOutputSchema] at the
  /// `complete_ticket` boundary (`strict` | `permissive`).
  TextColumn get outputContractMode =>
      text().withDefault(const Constant('strict'))();

  /// JSON output produced by the agent.
  TextColumn get outputJson => text().nullable()();

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

  // --- execution lock ---

  /// Heartbeat run that currently owns this ticket, if locked.
  TextColumn get checkoutRunId => text().nullable()();

  /// When the execution lock was acquired.
  DateTimeColumn get executionLockedAt => dateTime().nullable()();

  /// Agent that checked out (redundant, useful for queries).
  TextColumn get checkoutAgentId => text().nullable()();

  // --- execution policy ---

  /// JSON execution policy (list of stages with participants and rules).
  TextColumn get executionPolicyJson => text().nullable()();

  /// JSON execution state (current stage, decisions, completed stages).
  TextColumn get executionStateJson => text().nullable()();

  // --- recovery ---

  /// JSON recovery actions log.
  TextColumn get recoveryActionsJson => text().nullable()();

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
