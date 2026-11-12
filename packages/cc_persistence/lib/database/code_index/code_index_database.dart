import 'package:cc_persistence/database/daos/code_graph_dao.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/schema/schema_converge.dart';
import 'package:cc_persistence/database/tables/code_edges.dart';
import 'package:cc_persistence/database/tables/code_files.dart';
import 'package:cc_persistence/database/tables/code_index_checkpoints.dart';
import 'package:cc_persistence/database/tables/code_symbol_embeddings.dart';
import 'package:cc_persistence/database/tables/code_symbols.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/src/vector_extension.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';

part 'code_index_database.g.dart';

/// One workspace's code index (`<dataDir>/<workspaceId>/code_index.db`): the
/// symbols, edges, file hashes and checkpoints the tree-sitter indexer derives
/// from the workspace's checkouts.
///
/// A file of its own because everything in it can be derived again. On a
/// large workspace it is most of the bytes, and keeping it out of
/// `workspace.db` keeps it out of every snapshot, export and integrity check
/// of the data people wrote. For the same reason it is treated as disposable:
/// written with `synchronous = OFF`, never copied before an upgrade, and a
/// damaged, foreign or newer file is replaced by an empty one
/// (`WorkspaceDatabaseManager.codeIndexOf`). A partition with no checkpoint
/// is indexed in full on its next run, so an empty file fills itself again.
///
/// Every row belongs to [workspaceId] by construction, so no table carries a
/// workspace column.
@DriftDatabase(
  tables: [
    CodeSymbolsTable,
    CodeSymbolEmbeddingsTable,
    CodeEdgesTable,
    CodeFilesTable,
    CodeIndexCheckpointsTable,
  ],
  daos: [CodeGraphDao],
)
class CodeIndexDatabase extends _$CodeIndexDatabase with ConvergedDatabase {
  /// Creates the code index of [workspaceId] over a host-supplied
  /// [QueryExecutor] (the server passes `openCodeIndexDatabase`).
  CodeIndexDatabase(
    super.e, {
    required this.workspaceId,
    this.onWarn,
    this.skipIntegrityCheck = false,
    this.onIntegrityChecked,
  }) {
    // The extension applies to connections opened after it is registered, and
    // the executor opens on the first statement, so this is early enough.
    ensureVectorExtensionRegistered();
  }

  /// Creates an in-memory code index for testing.
  CodeIndexDatabase.forTesting(super.e, {this.workspaceId = 'test-workspace'})
    : onWarn = null,
      skipIntegrityCheck = false,
      onIntegrityChecked = null {
    ensureVectorExtensionRegistered();
  }

  /// The workspace whose index this file holds.
  final String workspaceId;

  @override
  final void Function(String tag, String message)? onWarn;

  /// Skips the `PRAGMA quick_check` on this open: this process already
  /// checked the file.
  final bool skipIntegrityCheck;

  /// Called when this open's `quick_check` passed, so the manager can skip
  /// the check on later opens of the same file.
  final void Function()? onIntegrityChecked;

  /// Why the last open refused this file, when it did: a damaged file, a
  /// foreign one, or one newer than this build. The manager reads it after a
  /// failed open to decide that the file is replaced rather than the error
  /// surfaced. Recorded here because the exception itself may reach the
  /// manager wrapped by the connection's isolate.
  Object? get refusal => _refusal;
  Object? _refusal;

  /// Forgets [refusal] before the open is tried again on a fresh file.
  void clearRefusal() => _refusal = null;

  /// The current code index schema version. Bump it whenever the declared
  /// schema changes; an existing file converges on its next open.
  static const int currentSchemaVersion = 2;

  /// `PRAGMA application_id` of a code index file: "CCCI".
  static const int fileApplicationId = 0x43434349;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  int get applicationId => fileApplicationId;

  /// Every code index file has carried an application id.
  @override
  int get lastUnidentifiedVersion => 0;

  @override
  String get identityTable => 'code_index_checkpoints';

  @override
  String get databaseLabel => 'code index $workspaceId';

  /// Never copied before an upgrade: the file can be derived again.
  @override
  String? get upgradeSnapshotDirectory => null;

  /// `code_symbol_embeddings` is vector indexed.
  @override
  bool get usesExtensionTables => true;

  static Future<SchemaSnapshot>? _declaredSchema;

  /// The schema a fresh code index file holds, read once per process from an
  /// in-memory instance.
  static Future<SchemaSnapshot> declaredSchema() =>
      _declaredSchema ??= _readDeclaredSchema();

  static Future<SchemaSnapshot> _readDeclaredSchema() async {
    final db = CodeIndexDatabase(
      NativeDatabase.memory(),
      workspaceId: 'declared-schema',
    );
    try {
      return await SchemaSnapshot.read(db);
    } on Object {
      _declaredSchema = null;
      rethrow;
    } finally {
      await db.close();
    }
  }

  @override
  Future<SchemaSnapshot> loadDeclaredSchema() => declaredSchema();

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => createFresh(() async {
      await m.createAll();
      await _createPartialIndexes();
    }),
    onUpgrade: (Migrator m, int from, int to) =>
        _refusing(() => upgradeByConverging(from, to)),
    beforeOpen: (_) => _refusing(() async {
      await applyConnectionPragmas();
      // After the shared pragmas, which ask for NORMAL: a power loss may cost
      // this file, and the index is derived again.
      await customStatement('PRAGMA synchronous = OFF');
      await verifyIdentity();
      await _checkIntegrity();
      // Per-connection, in-memory context: built on every open (a pooled
      // reader gets it from its connection setup).
      for (final table in codeIndexVectorTables) {
        await customStatement(vectorInitStatement(table));
      }
      final created = !await _hasSchemaObject(_ftsIndex);
      await _createFts();
      if (created ||
          fileWasRewritten ||
          (lastConvergeReport?.rebuiltTables.contains('code_symbols') ??
              false)) {
        // External content addressed by rowid: stale when just created over
        // existing rows, or when the rows were copied or the file rewritten.
        await customStatement(
          "INSERT INTO $_ftsIndex($_ftsIndex) VALUES('rebuild')",
        );
      }
      await optimize(onOpen: true);
    }),
  );

  /// Runs [body], recording in [refusal] the failures that mean this file
  /// should be replaced rather than served.
  Future<void> _refusing(Future<void> Function() body) async {
    try {
      await body();
    } on Object catch (error) {
      if (error is DatabaseNewerThanBinaryException ||
          error is ForeignDatabaseFileException ||
          error is CodeIndexDamagedException ||
          storageFailureOf(error) == StorageFailure.damaged) {
        _refusal = error;
      }
      rethrow;
    }
  }

  /// `PRAGMA quick_check`, once per file per process. A finding throws
  /// [CodeIndexDamagedException]: a damaged index is replaced, not repaired.
  Future<void> _checkIntegrity() async {
    if (skipIntegrityCheck) {
      return;
    }
    final result = await customSelect('PRAGMA quick_check').get();
    final finding = result.first.read<String>('quick_check');
    if (finding != 'ok') {
      throw CodeIndexDamagedException(
        workspaceId: workspaceId,
        finding: finding,
      );
    }
    onIntegrityChecked?.call();
  }

  static const _ftsIndex = 'code_symbols_fts';

  Future<bool> _hasSchemaObject(String name) async => (await customSelect(
    'SELECT 1 FROM sqlite_master WHERE name = ?',
    variables: [Variable.withString(name)],
  ).get()).isNotEmpty;

  /// The FTS5 index over symbol names, signatures and doc comments and its
  /// sync triggers. Idempotent and installed on every open: a trigger lost
  /// for any reason (a convergence drops them all) is otherwise never rebuilt
  /// and search silently returns less and less.
  Future<void> _createFts() async {
    await customStatement('''
      CREATE VIRTUAL TABLE IF NOT EXISTS code_symbols_fts
      USING fts5(name, qualified_name, signature, docstring, content=code_symbols, content_rowid=rowid)
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_ai AFTER INSERT ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
        VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_ad AFTER DELETE ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
        VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS code_symbols_au AFTER UPDATE ON code_symbols BEGIN
        INSERT INTO code_symbols_fts(code_symbols_fts, rowid, name, qualified_name, signature, docstring)
        VALUES ('delete', old.rowid, old.name, old.qualified_name, old.signature, old.docstring);
        INSERT INTO code_symbols_fts(rowid, name, qualified_name, signature, docstring)
        VALUES (new.rowid, new.name, new.qualified_name, new.signature, new.docstring);
      END
    ''');
  }

  /// Indexes a table class cannot declare because they carry a `WHERE`.
  ///
  /// `idx_code_edges_unresolved`: the indexer asks "any pending references
  /// in this partition?" before loading anything (`countUnresolvedEdges`),
  /// then reads and deletes them. Partial on the unresolved rows, it keeps
  /// all three O(unresolved) instead of a scan of the partition's edges.
  Future<void> _createPartialIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_code_edges_unresolved '
      'ON code_edges (repo_id, checkout_id) '
      'WHERE target_symbol_id IS NULL',
    );
  }
}

/// `PRAGMA quick_check` found a code index file damaged.
///
/// Never surfaced to a caller: the manager replaces the file with an empty
/// one and the indexer fills it again.
final class CodeIndexDamagedException implements Exception {
  /// Creates the exception for [workspaceId]'s code index.
  const CodeIndexDamagedException({
    required this.workspaceId,
    required this.finding,
  });

  /// The workspace whose code index is damaged.
  final String workspaceId;

  /// What `quick_check` reported.
  final String finding;

  @override
  String toString() =>
      'CodeIndexDamagedException: code index of workspace $workspaceId '
      'failed its integrity check: $finding';
}
