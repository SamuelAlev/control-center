import 'package:cc_persistence/database/tables/agent_goal_runs_table.dart';
import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:drift/drift.dart';

/// Changes the learning review proposes after a goal passed verification
/// (`ImprovementProposal`). Nothing changes until a person accepts one.
///
/// A proposal goes with its agent (`CASCADE`): it would change that agent's
/// knowledge. It outlives the conversation and the goal it came from (`SET
/// NULL`): a pending decision is still the person's to make, and an accepted
/// one is the record of what was written.
@TableIndex(
  name: 'idx_improvement_proposals_status_created',
  columns: {#status, #createdAt},
)
@TableIndex(name: 'idx_improvement_proposals_goal', columns: {#goalId})
@TableIndex(
  name: 'idx_improvement_proposals_conversation',
  columns: {#conversationId},
)
@TableIndex(
  name: 'idx_improvement_proposals_agent_status',
  columns: {#agentId, #status},
)
class ImprovementProposalsTable extends Table {
  /// Unique proposal id.
  TextColumn get id => text()();

  /// Owning workspace (this file's workspace).
  TextColumn get workspaceId => text()();

  /// The agent whose work was reviewed. `CASCADE`.
  TextColumn get agentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The space the work happened in. A value.
  TextColumn get spaceId => text().nullable()();

  /// The conversation the work happened in. `SET NULL`.
  TextColumn get conversationId => text().nullable().references(
    ConversationsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The goal that passed verification. `SET NULL`.
  TextColumn get goalId => text().nullable().references(
    AgentGoalRunsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// The review run that proposed it. A value.
  TextColumn get reviewRunId => text().nullable()();

  /// What it would change: an `ImprovementKind` wire name.
  TextColumn get kind => text().check(
    // ignore: recursive_getters
    kind.isIn(AgentsStoredValues.improvementKind),
  )();

  /// Where it applies: an `ImprovementScope` wire name.
  TextColumn get scope => text().check(
    // ignore: recursive_getters
    scope.isIn(AgentsStoredValues.improvementScope),
  )();

  /// The repository id for a repository scope. A value.
  TextColumn get scopeRefId => text().nullable()();

  /// `add`, `replace` or `remove`: an `ImprovementOperation` wire name.
  TextColumn get operation => text().check(
    // ignore: recursive_getters
    operation.isIn(AgentsStoredValues.improvementOperation),
  )();

  /// The id or name of what a replace or remove changes.
  TextColumn get targetRef => text().nullable()();

  /// The one change (at most 600 characters, checked by the entity).
  TextColumn get change => text()();

  /// `ImprovementEvidence` as a JSON object (`runIds`, `messageIds`,
  /// `checkResults`).
  TextColumn get evidence => text()
      // ignore: recursive_getters
      .check(isJsonObject(evidence))
      .withDefault(const Constant('{}'))();

  /// What should be different next time.
  TextColumn get expected => text()();

  /// Where it is: an `ImprovementStatus` wire name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.improvementStatus),
      )
      .withDefault(const Constant('proposed'))();

  /// The text before acceptance.
  TextColumn get beforeText => text().nullable()();

  /// The text acceptance wrote.
  TextColumn get afterText => text().nullable()();

  /// The id of what acceptance wrote. A value.
  TextColumn get appliedRef => text().nullable()();

  /// The candidate skill revision of a skill change. A value.
  TextColumn get candidateRevisionId => text().nullable()();

  /// The evaluation campaign that gates a skill change. A value.
  TextColumn get campaignId => text().nullable()();

  /// Where that campaign is: an `ImprovementCampaignState` wire name.
  TextColumn get campaignState => text()
      .check(
        // ignore: recursive_getters
        campaignState.isIn(AgentsStoredValues.improvementCampaignState),
      )
      .withDefault(const Constant('none'))();

  /// The person who decided. No key: users live in `global.db`.
  TextColumn get decidedByUserId => text().nullable()();

  /// When they decided.
  DateTimeColumn get decidedAt => dateTime().nullable()();

  /// When it was proposed.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When it expires if nobody decides.
  DateTimeColumn get expiresAt => dateTime()();

  // The entity's limits that cost nothing to keep here as well. Times are
  // whole seconds here, so the ordering allows equality.
  @override
  List<String> get customConstraints => [
    'CHECK (length(change) BETWEEN 1 AND 600)',
    'CHECK (length(expected) BETWEEN 1 AND 600)',
    'CHECK (expires_at >= created_at)',
  ];

  @override
  String get tableName => 'improvement_proposals';

  @override
  Set<Column> get primaryKey => {id};
}
