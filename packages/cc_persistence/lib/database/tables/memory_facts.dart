import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_facts_supersededBy', columns: {#supersededBy})
@TableIndex(name: 'idx_memory_facts_topic', columns: {#topic})
@TableIndex(name: 'idx_memory_facts_author', columns: {#authoredByAgentId})
/// Drift table for memory facts (the durable / episodic tier).
///
/// Addressed by its implicit `rowid` as well as by [id]: the full-text index
/// maps rows by rowid (and reads [workspaceId]), so the table keeps its text
/// primary key and is never `WITHOUT ROWID`.
///
/// The fact's vector is not here: it is a row of `memory_fact_embeddings`.
class MemoryFactsTable extends Table {
  /// Unique fact identifier.
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId => text()();

  /// Domain this fact belongs to. No foreign key: a domain slug, which a
  /// fact may name before the domain row exists.
  TextColumn get domain => text()();

  /// Topic this fact is about.
  TextColumn get topic => text()();

  /// Fact content text.
  TextColumn get content => text()();

  /// JSON array of source observation ids.
  TextColumn get sourceObservationIds => text()
      .check(
        // ignore: recursive_getters
        isJsonArray(sourceObservationIds),
      )
      .withDefault(const Constant('[]'))();

  /// Confidence score (0.0–1.0).
  RealColumn get confidence => real().withDefault(const Constant(1.0))();

  /// Id of the fact that supersedes this one. No foreign key: a harvest
  /// marks a fact superseded with the sentinel `system:harvest`, which names
  /// no fact.
  TextColumn get supersededBy => text().nullable()();

  /// Id of the agent that authored this fact. `ON DELETE SET NULL`: what an
  /// agent learned outlives the agent.
  TextColumn get authoredByAgentId => text().nullable().references(
    AgentsTable,
    #id,
    onDelete: KeyAction.setNull,
  )();

  /// Role that authored this fact (`AgentRole.name`).
  TextColumn get authoredByRole => text().nullable().check(
    // ignore: recursive_getters
    authoredByRole.isIn(SpacesStoredValues.agentRole),
  )();

  /// Typed classification (drives Weibull decay + surfacing). Default `fact`
  /// (`MemoryType.wireName`).
  TextColumn get memoryType => text()
      .check(
        // ignore: recursive_getters
        memoryType.isIn(SpacesStoredValues.memoryType),
      )
      .withDefault(const Constant('fact'))();

  /// Provenance (drives Bayesian confidence weighting). Default `stated`
  /// (`MemoryVeracity.wireName`).
  TextColumn get veracity => text()
      .check(
        // ignore: recursive_getters
        veracity.isIn(SpacesStoredValues.memoryVeracity),
      )
      .withDefault(const Constant('stated'))();

  /// Explicit expiry: the fact is treated as superseded past this time.
  DateTimeColumn get validUntil => dateTime().nullable()();

  /// How many times recall has returned this fact.
  IntColumn get recallCount => integer().withDefault(const Constant(0))();

  /// When recall last returned this fact.
  DateTimeColumn get lastRecalledAt => dateTime().nullable()();

  /// JSON array of temporal tags extracted from the content.
  TextColumn get temporalTags => text().nullable().check(
    // ignore: recursive_getters
    isJsonArray(temporalTags),
  )();

  /// How many times this fact has been (re-)asserted (Bayesian updates).
  IntColumn get mentionCount => integer().withDefault(const Constant(1))();

  /// When this fact was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When this fact was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'memory_facts';

  @override
  Set<Column> get primaryKey => {id};
}
