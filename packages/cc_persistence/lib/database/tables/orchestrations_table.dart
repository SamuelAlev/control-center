import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/pipeline_runs_table.dart';
import 'package:cc_persistence/database/tables/pipeline_templates_table.dart';
import 'package:cc_persistence/database/tables/projects_table.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:cc_persistence/database/tables/teams_table.dart';
import 'package:cc_persistence/database/tables/tickets_table.dart';
import 'package:drift/drift.dart';

/// Drift table for autonomous multi-agent orchestrations.
///
/// One row per "big ask" the user asked the system to orchestrate. Holds the
/// agent-proposed plan (`proposalJson`), its lifecycle status and references
/// to everything the deterministic materializer creates on approval (team,
/// project, generated pipeline template + run, hired agents).
///
/// Every reference is `SET NULL`: an orchestration is the record of what was
/// asked and approved, and outlives the things it created or pointed at.
@TableIndex(
  name: 'idx_orchestrations_parentTicket',
  columns: {#parentTicketId, #createdAt},
)
@TableIndex(name: 'idx_orchestrations_pipelineRun', columns: {#pipelineRunId})
@TableIndex(name: 'idx_orchestrations_status', columns: {#status})
@TableIndex(name: 'idx_orchestrations_created', columns: {#createdAt})
@TableIndex(name: 'idx_orchestrations_space', columns: {#spaceId})
@TableIndex(
  name: 'idx_orchestrations_orchestrator',
  columns: {#orchestratorAgentId},
)
@TableIndex(name: 'idx_orchestrations_template', columns: {#pipelineTemplateId})
@TableIndex(name: 'idx_orchestrations_team', columns: {#teamId})
@TableIndex(name: 'idx_orchestrations_project', columns: {#projectId})
class OrchestrationsTable extends Table {
  /// Unique orchestration id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The anchor ticket the orchestration was opened against. `SET NULL` when
  /// the ticket is deleted (the orchestration record survives for audit).
  TextColumn get parentTicketId => text().nullable().references(
    TicketsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Shared discussion space for the orchestration. `SET NULL`.
  TextColumn get spaceId => text().nullable().references(
    SpacesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Agent that produced (and revises) the proposal (the orchestrator).
  /// `SET NULL`.
  TextColumn get orchestratorAgentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Lifecycle status: an `OrchestrationStatus` storage string.
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(AgentsStoredValues.orchestrationStatus))
      .withDefault(const Constant('proposed'))();

  /// JSON-serialized `OrchestrationProposal`.
  TextColumn get proposalJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(proposalJson))();

  /// Monotonic proposal revision (>= 1), bumped on each refine/edit.
  IntColumn get revision => integer().withDefault(const Constant(1))();

  /// The revision the user approved, if any.
  IntColumn get approvedRevision => integer().nullable()();

  /// Generated pipeline template id, set on approval. `SET NULL`.
  TextColumn get pipelineTemplateId => text().nullable().references(
    PipelineTemplatesTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Pipeline run id, set when execution starts. `SET NULL`.
  TextColumn get pipelineRunId => text().nullable().references(
    PipelineRunsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Team created for the orchestration. `SET NULL`.
  TextColumn get teamId => text().nullable().references(
    TeamsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Project created for the orchestration. `SET NULL`.
  TextColumn get projectId => text().nullable().references(
    ProjectsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Estimated total cost in micro-dollars (from the proposal budget).
  IntColumn get estimatedCostMicros => integer().nullable()();

  /// Hard spending limit in micro-dollars; the budget guard cancels the run
  /// when rolled-up cost exceeds it.
  IntColumn get maxCostMicros => integer().nullable()();

  /// JSON array of agent ids hired specifically for this orchestration.
  /// No foreign key: an array cannot hold one.
  TextColumn get hiredAgentIdsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(hiredAgentIdsJson))
      .withDefault(const Constant('[]'))();

  /// JSON array of approved sub-ticket keys (PRD 17 §4 partial approval).
  /// Null = every node approved (the whole-plan approve path).
  TextColumn get approvedNodeKeysJson =>
      text().nullable()
      // ignore: recursive_getters
      .check(isJsonArray(approvedNodeKeysJson))();

  /// Error message when the orchestration failed.
  TextColumn get errorMessage => text().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// When the orchestration reached a terminal state.
  DateTimeColumn get completedAt => dateTime().nullable()();

  @override
  String get tableName => 'orchestrations';

  @override
  Set<Column> get primaryKey => {id};
}
