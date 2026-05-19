import 'package:drift/drift.dart';

@TableIndex(name: 'idx_agents_workspaceId', columns: {#workspaceId})
@TableIndex(
  name: 'idx_agents_workspace_name',
  columns: {#workspaceId, #name},
  unique: true,
)
/// Drift table definition for agents.
class AgentsTable extends Table {
  /// Unique agent identifier.
  TextColumn get id => text()();

  /// Short agent name. Unique per workspace (enforced by
  /// `idx_agents_workspace_name` unique index).
  TextColumn get name => text()();

  /// Human-readable title.
  TextColumn get title => text()();

  /// Path to the agent's markdown file.
  TextColumn get agentMdPath => text()();

  /// Id of the workspace this agent belongs to.
  TextColumn get workspaceId => text()();

  /// Id of the agent this one reports to, if any.
  TextColumn get reportsTo => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Comma-separated list of skills.
  TextColumn get skills => text()();

  /// Optional persona description.
  TextColumn get persona => text().nullable()();

  /// System prompt override for the agent.
  TextColumn get systemPrompt => text().nullable()();

  /// Selected adapter identifier.
  TextColumn get adapterId => text().nullable()();

  /// Selected model identifier.
  TextColumn get modelId => text().nullable()();

  /// Whether strict identity checking is enabled.
  BoolColumn get strictMode => boolean().withDefault(const Constant(false))();

  /// Reasoning effort level: low, medium, or high.
  TextColumn get effort => text().nullable()();

  /// Context window size in tokens.
  IntColumn get contextSize => integer().nullable()();

  /// JSON-encoded sandbox `AgentCapabilities` snapshot for this agent.
  /// Empty string falls back to the user-level default at dispatch time.
  TextColumn get sandboxCapabilitiesJson =>
      text().withDefault(const Constant(''))();

  /// Agent role (e.g. 'ceo', 'coder', 'reviewer'). Null for legacy agents.
  TextColumn get role => text().nullable()();

  /// Monthly budget in US cents for this agent.
  IntColumn get monthlyBudgetCents =>
      integer().withDefault(const Constant(0))();

  /// Per-agent silence-timeout override in minutes. Null falls back to the
  /// per-mode default at dispatch time.
  IntColumn get silenceTimeoutMinutes => integer().nullable()();

  /// Creation timestamp.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
