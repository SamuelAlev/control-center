import 'package:cc_persistence/database/tables/orchestrations_table.dart';
import 'package:drift/drift.dart';

/// Drift table for orchestration proposal revision history (PRD 17 §5).
///
/// One row per revision of an orchestration's proposal — the append-only
/// version timeline behind plan diff and rewind. The live row in
/// `OrchestrationsTable` always mirrors the highest revision; this table is
/// what makes "what changed since I approved?" answerable.
@TableIndex(
  name: 'idx_orchestration_revisions_orchestration',
  columns: {#orchestrationId},
)
@TableIndex(
  name: 'idx_orchestration_revisions_workspace',
  columns: {#workspaceId},
)
class OrchestrationRevisionsTable extends Table {
  /// Unique revision row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The orchestration this revision belongs to.
  TextColumn get orchestrationId => text().references(
    OrchestrationsTable,
    #id,
    onDelete: KeyAction.cascade,
  )();

  /// The monotonic revision number this row snapshots (>= 1).
  IntColumn get revision => integer()();

  /// Full JSON-serialized `OrchestrationProposal` at this revision.
  TextColumn get proposalJson => text()();

  /// Who authored the revision: a user id or an agent id.
  TextColumn get authoredBy => text()();

  /// Whether [authoredBy] is a `user` or an `agent`.
  TextColumn get authorKind => text().withDefault(const Constant('user'))();

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
@TableIndex(name: 'idx_plan_documents_workspace', columns: {#workspaceId})
@TableIndex(name: 'idx_plan_documents_conversation', columns: {#conversationId})
class PlanDocumentsTable extends Table {
  /// Unique plan document id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope.
  TextColumn get workspaceId => text()();

  /// The conversation (space) the plan was authored in.
  TextColumn get conversationId => text()();

  /// The agent that authored the plan.
  TextColumn get agentId => text()();

  /// JSON-serialized `PlanDocument`.
  TextColumn get planJson => text()();

  /// Lifecycle status (see `PlanDocumentStatus`): draft → proposed →
  /// approved / rejected / superseded.
  TextColumn get status => text().withDefault(const Constant('proposed'))();

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
@TableIndex(name: 'idx_playbooks_workspace', columns: {#workspaceId})
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
  TextColumn get paramsSchemaJson => text().withDefault(const Constant('[]'))();

  /// JSON-serialized source `OrchestrationProposal` with `{{param}}`
  /// placeholders.
  TextColumn get sourceProposalJson => text()();

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

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, name},
  ];
}
