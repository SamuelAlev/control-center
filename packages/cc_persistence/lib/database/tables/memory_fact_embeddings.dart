import 'package:cc_persistence/database/tables/memory_facts.dart';
import 'package:drift/drift.dart';

/// The semantic-search vector of a memory fact, one row per embedded fact.
///
/// Kept beside the fact rather than on it: every fact list, recall and
/// counter update reads or rewrites the fact row, and none of them needs a
/// 1.5 KB vector. A fact that is not embedded yet has no row here, which is
/// what the backfill looks for (an anti-join served by the primary key).
///
/// The vector extension scans this table (`vector_init` names it), and a scan
/// yields the rowids of this table, not of `memory_facts`. The search maps a
/// scanned rowid to its row here in the same statement and reaches the fact
/// through the [factId] it stores, so nothing depends on a rowid outliving
/// the statement: a `VACUUM` or a snapshot copy cannot attach a vector to
/// another fact. That is why the key is the fact id and not an
/// `INTEGER PRIMARY KEY` of its own.
class MemoryFactEmbeddingsTable extends Table {
  /// The embedded fact. `ON DELETE CASCADE`: the vector is part of the fact
  /// and describes its text.
  TextColumn get factId =>
      text().references(MemoryFactsTable, #id, onDelete: KeyAction.cascade)();

  /// The vector: FLOAT32 bytes of the embedding of the fact's topic and
  /// content.
  BlobColumn get embedding => blob()();

  @override
  String get tableName => 'memory_fact_embeddings';

  @override
  Set<Column> get primaryKey => {factId};
}
