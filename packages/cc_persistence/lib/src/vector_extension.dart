import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:sqlite_vector/sqlite_vector.dart';

/// Tables of a workspace database that carry a vector index on `embedding`.
///
/// Side tables, one row per embedded parent: a scan yields their rowids and
/// each search joins back to the parent by the id the side row stores.
const workspaceVectorTables = <String>['memory_fact_embeddings'];

/// Tables of a code index database that carry a vector index on `embedding`.
const codeIndexVectorTables = <String>['code_symbol_embeddings'];

/// The statement that builds the per-connection vector context for [table].
///
/// FLOAT32, 384 dimensions: the embedding model's output.
String vectorInitStatement(String table) =>
    "SELECT vector_init('$table', 'embedding', 'type=FLOAT32,dimension=384')";

bool _registered = false;

/// Registers the vector-search extension as a process-wide SQLite
/// auto-extension, so every connection opened afterwards has
/// `vector_init`/`vector_full_scan_stream`.
///
/// Idempotent. Throws when the native library cannot be loaded: a missing
/// native is a failure, never a reason to serve keyword-only search as if
/// nothing were wrong.
void ensureVectorExtensionRegistered() {
  if (_registered) {
    return;
  }
  sqlite3.sqlite3.loadSqliteVectorExtension();
  _registered = true;
}
