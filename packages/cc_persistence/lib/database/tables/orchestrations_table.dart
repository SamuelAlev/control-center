import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

/// Drift table for autonomous multi-agent orchestrations.
///
/// One row per "big ask" the user asked the system to orchestrate. Holds the
/// agent-proposed plan (`proposalJson`), its lifecycle status, and references
/// to everything the deterministic materializer creates on approval (team,
/// project, generated pipeline template + run, hired agents).
@TableIndex(name: 'idx_orchestrations_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_orchestrations_parentTicket', columns: {#parentTicketId})
@TableIndex(name: 'idx_orchestrations_pipelineRun', columns: {#pipelineRunId})
@TableIndex(name: 'idx_orchestrations_status', columns: {#status})
class OrchestrationsTable extends Table {
  /// Unique orchestration id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text().references(
        WorkspacesTable,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// The anchor ticket the orchestration was opened against. Cascades to null
  /// if the ticket is deleted (the orchestration record survives for audit).
  TextColumn get parentTicketId => text().nullable()();

  /// Shared discussion channel for the orchestration.
  TextColumn get channelId => text().nullable()();

  /// Agent that produced (and revises) the proposal (the orchestrator).
  TextColumn get orchestratorAgentId => text().nullable()();

  /// Lifecycle status (see `OrchestrationStatus`).
  TextColumn get status =>
      text().withDefault(const Constant('proposed'))();

  /// JSON-serialized `OrchestrationProposal`.
  TextColumn get proposalJson => text()();

  /// Monotonic proposal revision (>= 1), bumped on each refine/edit.
  IntColumn get revision => integer().withDefault(const Constant(1))();

  /// The revision the user approved, if any.
  IntColumn get approvedRevision => integer().nullable()();

  /// Generated pipeline template id, set on approval.
  TextColumn get pipelineTemplateId => text().nullable()();

  /// Pipeline run id, set when execution starts.
  TextColumn get pipelineRunId => text().nullable()();

  /// Team created for the orchestration.
  TextColumn get teamId => text().nullable()();

  /// Project created for the orchestration.
  TextColumn get projectId => text().nullable()();

  /// Estimated total cost in US cents (from the proposal budget).
  IntColumn get estimatedCostCents => integer().nullable()();

  /// Hard spending limit in US cents; the budget guard cancels the run when
  /// rolled-up cost exceeds it.
  IntColumn get maxCostCents => integer().nullable()();

  /// JSON array of agent ids hired specifically for this orchestration.
  TextColumn get hiredAgentIdsJson =>
      text().withDefault(const Constant('[]'))();

  /// Error message when the orchestration failed.
  TextColumn get errorMessage => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the orchestration reached a terminal state.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
