import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:drift/drift.dart';

/// The semantic-search vector of a code symbol, one row per embedded symbol.
///
/// Kept beside the symbol rather than on it: graph traversal, name lookups
/// and every re-index read symbol rows by the thousand, and none of them
/// needs a 1.5 KB vector. A symbol that is not embedded yet (indexed while
/// the model was missing) has no row here, which is what the backfill looks
/// for (an anti-join served by the primary key).
///
/// The vector extension scans this table (`vector_init` names it), and a scan
/// yields the rowids of this table, not of `code_symbols`. The search maps a
/// scanned rowid to its row here in the same statement and reaches the
/// symbol through the [symbolId] it stores, so nothing depends on a rowid
/// outliving the statement. That is why the key is the symbol id and not an
/// `INTEGER PRIMARY KEY` of its own.
class CodeSymbolEmbeddingsTable extends Table {
  /// The embedded symbol. `ON DELETE CASCADE`: the vector describes the
  /// symbol's text, and every delete of a file, a partition or a repo takes
  /// its vectors with it.
  TextColumn get symbolId =>
      text().references(CodeSymbolsTable, #id, onDelete: KeyAction.cascade)();

  /// The vector: FLOAT32 bytes of the embedding of the symbol's qualified
  /// name, signature and doc comment.
  BlobColumn get embedding => blob()();

  @override
  String get tableName => 'code_symbol_embeddings';

  @override
  Set<Column> get primaryKey => {symbolId};
}
