import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_memory_facts_supersededBy', columns: {#supersededBy})
@TableIndex(name: 'idx_memory_facts_workspaceId', columns: {#workspaceId})
@TableIndex(name: 'idx_memory_facts_topic', columns: {#topic})
@TableIndex(name: 'idx_memory_facts_domain', columns: {#domain})
/// Drift table for memory facts (the durable / episodic tier).
class MemoryFactsTable extends Table {
  /// Unique fact identifier.
  TextColumn get id => text()();
  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();
  /// Domain this fact belongs to.
  TextColumn get domain => text()();
  /// Topic this fact is about.
  TextColumn get topic => text()();
  /// Fact content text.
  TextColumn get content => text()();
  /// JSON array of source observation ids.
  TextColumn get sourceObservationIds => text().withDefault(const Constant('[]'))();
  /// Confidence score (0.0–1.0).
  RealColumn get confidence => real().withDefault(const Constant(1.0))();
  /// Id of the fact that supersedes this one.
  TextColumn get supersededBy => text().nullable()();
  /// Id of the agent that authored this fact.
  TextColumn get authoredByAgentId => text().nullable()();
  /// Role that authored this fact.
  TextColumn get authoredByRole => text().nullable()();
  /// Typed classification (drives Weibull decay + surfacing). Default `fact`.
  TextColumn get memoryType => text().withDefault(const Constant('fact'))();
  /// Provenance (drives Bayesian confidence weighting). Default `stated`.
  TextColumn get veracity => text().withDefault(const Constant('stated'))();
  /// Explicit expiry: the fact is treated as superseded past this time.
  DateTimeColumn get validUntil => dateTime().nullable()();
  /// How many times recall has returned this fact.
  IntColumn get recallCount => integer().withDefault(const Constant(0))();
  /// When recall last returned this fact.
  DateTimeColumn get lastRecalledAt => dateTime().nullable()();
  /// JSON array of temporal tags extracted from the content.
  TextColumn get temporalTags => text().nullable()();
  /// How many times this fact has been (re-)asserted (Bayesian updates).
  IntColumn get mentionCount => integer().withDefault(const Constant(1))();
  /// Float32 vector embedding for semantic search.
  BlobColumn get embedding => blob().nullable()();
  /// Sign-bit-packed binary embedding for Hamming/quantized search.
  BlobColumn get binaryEmbedding => blob().nullable()();
  /// When this fact was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// When this fact was last updated.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}