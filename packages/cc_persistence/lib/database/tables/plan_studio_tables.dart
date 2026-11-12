import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:drift/drift.dart';

/// Drift table for orchestration proposal revision history (PRD 17 §5).
///
/// One row per revision of an orchestration's proposal — the append-only
/// version timeline behind plan diff and rewind. The live row in
/// `OrchestrationsTable` always mirrors the highest revision; this table is
/// what makes "what changed since I approved?" answerable.
///
/// The unique `(orchestration_id, revision)` key is also the index the
/// timeline reads and the cascade from the orchestration use.
class OrchestrationRevisionsTable extends Table {
  /// Unique revision row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The orchestration this revision belongs to. `CASCADE`: a revision is
  /// part of its orchestration's timeline.
  TextColumn get orchestrationId => text().references(
    OrchestrationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The monotonic revision number this row snapshots (>= 1).
  IntColumn get revision => integer()();

  /// Full JSON-serialized `OrchestrationProposal` at this revision.
  TextColumn get proposalJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(proposalJson))();

  /// Who authored the revision: a user id or an agent id. No foreign key: it
  /// names an agent here or a user in `global.db`, per [authorKind].
  TextColumn get authoredBy => text()();

  /// Whether [authoredBy] is a user or an agent: an `ActorKind` wire name.
  TextColumn get authorKind => text()
      // ignore: recursive_getters
      .check(authorKind.isIn(AgentsStoredValues.actorKind))
      .withDefault(const Constant('user'))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'orchestration_revisions';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {orchestrationId, revision},
  ];
}

/// Drift table for single-agent plan-mode artifacts (PRD 17 §8).
///
/// One row per plan a harness plan-mode run produced for a conversation. The
/// plan body is a JSON-serialized `PlanDocument` (which embeds the shared
/// `PlanGraph`). Revisions are in-place: the row keeps only the latest
/// `planJson` and bumps [revision]; plan-mode documents are working drafts,
/// not an audit surface (orchestrations are the audited path).
@TableIndex(
  name: 'idx_plan_documents_conversation',
  columns: {#conversationId, #updatedAt},
)
@TableIndex(name: 'idx_plan_documents_updated', columns: {#updatedAt})
@TableIndex(name: 'idx_plan_documents_agent', columns: {#agentId})
class PlanDocumentsTable extends Table {
  /// Unique plan document id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The conversation the plan was authored in. `CASCADE`: a plan-mode
  /// document is a working draft of that conversation.
  TextColumn get conversationId =>
      text().references(ConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// The agent that authored the plan. `CASCADE`: a draft has no meaning
  /// without the agent that would execute it.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// JSON-serialized `PlanDocument`.
  TextColumn get planJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(planJson))();

  /// Lifecycle status: a `PlanDocumentStatus` name (draft → proposed →
  /// approved / rejected / superseded).
  TextColumn get status => text()
      // ignore: recursive_getters
      .check(status.isIn(AgentsStoredValues.planDocumentStatus))
      .withDefault(const Constant('proposed'))();

  /// Monotonic revision (>= 1), bumped on each replan/edit.
  IntColumn get revision => integer().withDefault(const Constant(1))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'plan_documents';

  @override
  Set<Column> get primaryKey => {id};
}

/// Drift table for playbooks — parameterized, versioned, reusable plans
/// (PRD 17 §10).
///
/// A playbook layers a typed parameter schema over a stored proposal: the
/// source proposal JSON carries explicit `{{param}}` placeholders which
/// instantiation substitutes before re-validation. No expression language —
/// a playbook that needs logic is a pipeline.
class PlaybooksTable extends Table {
  /// Unique playbook id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// Display name (unique per workspace).
  TextColumn get name => text()();

  /// What the playbook does / when to use it.
  TextColumn get description => text().withDefault(const Constant(''))();

  /// JSON-serialized `List<PlaybookParam>` — the typed parameter schema.
  TextColumn get paramsSchemaJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(paramsSchemaJson))
      .withDefault(const Constant('[]'))();

  /// JSON-serialized source `OrchestrationProposal` with `{{param}}`
  /// placeholders.
  TextColumn get sourceProposalJson =>
      // ignore: recursive_getters
      text().check(isJsonObject(sourceProposalJson))();

  /// Monotonic version, bumped on each save-over.
  IntColumn get version => integer().withDefault(const Constant(1))();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last mutation time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'playbooks';

  @override
  Set<Column> get primaryKey => {id};

  /// The name is unique in the file; the list reads order by it.
  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}
