import 'dart:io';

import 'package:cc_persistence/database/schema/schema_converge.dart';
import 'package:drift/drift.dart';

/// Pragmas every connection carries, the writer and each pooled reader alike.
///
/// They are per connection and not stored in the file, so they are applied
/// twice on purpose: by the connection's `setup` callback (the only hook a
/// pooled reader runs) and again by `beforeOpen` (the only hook an in-memory
/// test database runs).
///
/// * `busy_timeout`: wait up to 5s for a lock instead of failing a contended
///   write at once with SQLITE_BUSY. Background reconcilers write beside
///   live requests.
/// * `foreign_keys`: enforced on every connection that can write.
/// * `trusted_schema = OFF`: a file's own schema (CHECK constraints, generated
///   columns, expression indexes, triggers) may only call functions SQLite
///   marks innocuous. An imported file is somebody else's bytes.
/// * `synchronous = NORMAL`: with WAL an application crash loses no committed
///   transaction; a power loss can lose the ones not yet checkpointed. That
///   is the setting SQLite recommends for WAL.
/// * `temp_store = MEMORY`: sorts and transient indexes stay off disk.
/// * `mmap_size` / `cache_size`: 8 MB each per connection. N open workspaces
///   mean N caches, so the bound matters. No mapping on Windows: there a file
///   cannot be cut shorter while any handle holds a view of it, and SQLite
///   ignores that refusal (`ERROR_USER_MAPPED_FILE`), so with the pooled
///   readers mapping the file the checkpoint after an incremental vacuum
///   never handed a page back to the disk.
/// * `journal_size_limit`: a long-running server does not accumulate an
///   unbounded `-wal`.
final List<String> connectionPragmas = List.unmodifiable(<String>[
  'PRAGMA busy_timeout = 5000',
  'PRAGMA foreign_keys = ON',
  'PRAGMA trusted_schema = OFF',
  'PRAGMA synchronous = NORMAL',
  'PRAGMA temp_store = MEMORY',
  if (!Platform.isWindows) 'PRAGMA mmap_size = 8388608',
  'PRAGMA cache_size = -8192',
  'PRAGMA journal_size_limit = 67108864',
]);

/// The table the sqlite_vector extension creates in every database a
/// connection opens once the extension is registered. The extension owns it:
/// it is never compared, rebuilt or dropped as part of a declared schema.
const vectorExtensionTable = '_sqliteai_vector';

/// A database file was written by a newer build than the one opening it.
///
/// An older binary would run nothing, write rows without knowing the newer
/// columns and stamp its own version on the file. It refuses instead.
final class DatabaseNewerThanBinaryException implements Exception {
  /// Creates the exception for the file named by [database].
  const DatabaseNewerThanBinaryException({
    required this.database,
    required this.fileVersion,
    required this.binaryVersion,
  });

  /// Which database: `global` or `workspace <id>`.
  final String database;

  /// The schema version stamped on the file.
  final int fileVersion;

  /// The schema version this build declares.
  final int binaryVersion;

  @override
  String toString() =>
      'DatabaseNewerThanBinaryException: $database is at schema '
      'v$fileVersion, this build knows v$binaryVersion. Update the server.';
}

/// A file is an SQLite database but not one this server wrote for this
/// purpose (another application's file, or one kind of database put where
/// another belongs).
final class ForeignDatabaseFileException implements Exception {
  /// Creates the exception for the file named by [database].
  const ForeignDatabaseFileException({
    required this.database,
    required this.applicationId,
    required this.expectedApplicationId,
  });

  /// Which database: `global` or `workspace <id>`.
  final String database;

  /// The `application_id` found in the file.
  final int applicationId;

  /// The `application_id` this kind of database carries.
  final int expectedApplicationId;

  @override
  String toString() =>
      'ForeignDatabaseFileException: $database carries application id '
      '$applicationId, expected $expectedApplicationId. '
      'This is not a file this server wrote for that purpose.';
}

/// SQLite's own check found a database file damaged.
///
/// Thrown where there is nothing to fall back to (the server-global file):
/// serving from it, or writing on top of the damage, would carry the damage
/// into every later snapshot.
final class DatabaseDamagedException implements Exception {
  /// Creates the exception for the file named by [database].
  const DatabaseDamagedException({
    required this.database,
    required this.finding,
  });

  /// Which database: `global` or `workspace <id>`.
  final String database;

  /// What `PRAGMA quick_check` reported.
  final String finding;

  @override
  String toString() =>
      'DatabaseDamagedException: $database failed its integrity check: '
      '$finding. Restore it from a snapshot.';
}

/// The open and upgrade sequence the server's databases share.
///
/// A database class mixes this in and builds its `MigrationStrategy` from
/// [createFresh], [upgradeByConverging] and [applyConnectionPragmas]. There
/// are no migration steps: bump `schemaVersion` whenever the declared schema
/// changes and an existing file is converged to it on its next open (see
/// [SchemaConverger]).
mixin ConvergedDatabase on GeneratedDatabase {
  /// The `PRAGMA application_id` of this kind of file.
  int get applicationId;

  /// The last schema version whose files were written before application ids
  /// existed. A file at or below it may carry id 0; converging stamps it.
  int get lastUnidentifiedVersion;

  /// A table every file of this kind already had before application ids
  /// existed. It is how a file with id 0 is told apart from an arbitrary
  /// SQLite file that happens to sit at this path: without it, converging
  /// would empty somebody else's database.
  String get identityTable;

  /// Names this database in messages: `global`, `workspace <id>`.
  String get databaseLabel;

  /// Tables an SQLite extension may create in this file. They are never
  /// part of a schema comparison.
  ///
  /// The vector extension is registered process-wide once any workspace
  /// opens, and from then on creates its table in every file a connection
  /// touches, the global one included.
  static const extensionTables = <String>{vectorExtensionTable};

  /// Whether this database uses what the extensions keep in
  /// [extensionTables]. One that does not drops them when it converges.
  bool get usesExtensionTables => true;

  /// Values for `NOT NULL` columns old rows cannot supply, by column name.
  Map<String, Object> get convergeFills => const {};

  /// Where a copy of the file is written before it is upgraded. Null (tests,
  /// in-memory databases) skips the copy.
  String? get upgradeSnapshotDirectory;

  /// Warning sink, host-injected.
  void Function(String tag, String message)? get onWarn;

  /// The schema this class declares: what a fresh file holds.
  Future<SchemaSnapshot> loadDeclaredSchema();

  /// How many pre-upgrade copies are kept per database.
  static const keptUpgradeSnapshots = 2;

  /// What the last convergence on this instance changed, if one ran.
  SchemaConvergeReport? get lastConvergeReport => _lastConvergeReport;
  SchemaConvergeReport? _lastConvergeReport;

  /// Whether the upgrade on this open rewrote the whole file (`VACUUM`).
  /// Rowids of tables without an integer primary key are not guaranteed to
  /// survive that, so indexes that address rows by rowid are rebuilt after.
  bool get fileWasRewritten => _fileWasRewritten;
  bool _fileWasRewritten = false;

  bool _opened = false;

  /// Builds a fresh file inside one transaction and stamps its identity.
  ///
  /// A crash halfway leaves an empty file (version 0), which the next open
  /// builds again from the start.
  Future<void> createFresh(Future<void> Function() build) async {
    await transaction(() async {
      await build();
      await customStatement('PRAGMA application_id = $applicationId');
    });
  }

  /// The `onUpgrade` body: refuses a newer or foreign file, copies the file
  /// aside, then converges it to the declared schema.
  Future<void> upgradeByConverging(int from, int to) async {
    // Identity before version: another kind of file has a version of its
    // own, and "update the server" would be the wrong thing to say about it.
    await verifyIdentity(fileVersion: from);
    if (from > to) {
      throw DatabaseNewerThanBinaryException(
        database: databaseLabel,
        fileVersion: from,
        binaryVersion: to,
      );
    }
    await _snapshotBeforeUpgrade(from);
    final report = await convergeSchema();
    onWarn?.call(
      'SchemaConverge',
      '$databaseLabel v$from -> v$to: ${report.describe()}',
    );
    await _adoptIncrementalVacuum();
  }

  /// Forces this file to the declared schema, whatever version it claims.
  ///
  /// The upgrade path calls it when versions differ. Import calls it on every
  /// adopted file: after it returns, the file holds exactly the declared
  /// tables, indexes and constraints and nothing else, so a constraint,
  /// generated column, trigger or view somebody added to the file is gone.
  /// Must not run inside a transaction.
  Future<SchemaConvergeReport> convergeSchema() async {
    final report = await SchemaConverger(
      db: this,
      declared: (await loadDeclaredSchema()).without(extensionTables),
      version: schemaVersion,
      applicationId: applicationId,
      fills: convergeFills,
      preserve: usesExtensionTables ? extensionTables : const {},
    ).converge();
    _lastConvergeReport = report;
    return report;
  }

  /// How this file's schema differs from the declared one. Empty when equal.
  Future<List<String>> schemaDifferences() async {
    final current = await SchemaSnapshot.read(this);
    return current.differencesFrom(
      await loadDeclaredSchema(),
      ignore: extensionTables,
    );
  }

  /// Throws [ForeignDatabaseFileException] unless the file carries this
  /// database's application id.
  ///
  /// With [fileVersion] at or below [lastUnidentifiedVersion] an id of 0 is
  /// accepted when the file holds [identityTable]: it predates ids and is
  /// about to be stamped.
  Future<void> verifyIdentity({int? fileVersion}) async {
    final row = await customSelect('PRAGMA application_id').getSingle();
    final id = row.read<int>('application_id');
    if (id == applicationId) {
      return;
    }
    if (id == 0 &&
        fileVersion != null &&
        fileVersion <= lastUnidentifiedVersion) {
      final marker = await customSelect(
        "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = ?",
        variables: [Variable.withString(identityTable)],
      ).get();
      if (marker.isNotEmpty) {
        return;
      }
    }
    throw ForeignDatabaseFileException(
      database: databaseLabel,
      applicationId: id,
      expectedApplicationId: applicationId,
    );
  }

  /// Applies [connectionPragmas] to the connection `beforeOpen` runs on and
  /// marks this instance opened.
  Future<void> applyConnectionPragmas() async {
    await customStatement('PRAGMA journal_mode = WAL');
    for (final pragma in connectionPragmas) {
      await customStatement(pragma);
    }
    _opened = true;
  }

  /// Refreshes the planner's statistics where they are missing or stale.
  ///
  /// `0x10002` on open also analyses tables that never had statistics; the
  /// plain form afterwards only touches tables whose row counts moved. Both
  /// are bounded by `analysis_limit`, so neither scans a large table whole.
  Future<void> optimize({bool onOpen = false}) async {
    await customStatement('PRAGMA analysis_limit = 400');
    await customStatement(
      onOpen ? 'PRAGMA optimize = 0x10002' : 'PRAGMA optimize',
    );
  }

  /// Hands pages freed by deletes back to the file system, [maxPages] at
  /// most per call so one sweep never holds the write lock for long.
  ///
  /// Works on a file in `auto_vacuum = INCREMENTAL` (every file this server
  /// creates or has upgraded); on any other file it does nothing.
  Future<void> reclaimFreePages({int maxPages = 8192}) =>
      customStatement('PRAGMA incremental_vacuum($maxPages)');

  /// Moves the write-ahead log into the file and truncates it.
  Future<void> checkpoint() =>
      customStatement('PRAGMA wal_checkpoint(TRUNCATE)');

  /// Runs `PRAGMA optimize` before the connection goes away, so the next open
  /// plans with what this session learned. A database that never opened is
  /// closed without touching the file.
  @override
  Future<void> close() async {
    if (_opened) {
      _opened = false;
      try {
        await optimize();
      } on Object {
        // Statistics are an optimisation; a failure here must not keep the
        // file open.
      }
    }
    await super.close();
  }

  /// Writes `VACUUM INTO` of the file as it is to
  /// `<upgradeSnapshotDirectory>/v<from>.<utc timestamp>.db` and keeps the
  /// newest [keptUpgradeSnapshots].
  ///
  /// A failure aborts the upgrade: converging a file there is no copy of is
  /// the one thing this exists to prevent.
  Future<void> _snapshotBeforeUpgrade(int from) async {
    final directory = upgradeSnapshotDirectory;
    if (directory == null) {
      return;
    }
    final dir = Directory(directory)..createSync(recursive: true);
    final stamp = DateTime.now()
        .toUtc()
        .toIso8601String()
        .replaceAll(RegExp('[-:]'), '')
        .split('.')
        .first;
    final separator = Platform.pathSeparator;
    var target = File('${dir.path}${separator}v$from.${stamp}Z.db');
    for (var n = 1; target.existsSync(); n++) {
      target = File('${dir.path}${separator}v$from.${stamp}Z.$n.db');
    }
    await customStatement('VACUUM INTO ?', [target.path]);
    final copies =
        dir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.db'))
            .toList()
          ..sort(
            (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
          );
    for (final stale in copies.skip(keptUpgradeSnapshots)) {
      try {
        stale.deleteSync();
      } on FileSystemException {
        // An undeletable old copy costs disk, not correctness.
      }
    }
  }

  /// Switches an existing file to `auto_vacuum = INCREMENTAL`.
  ///
  /// The mode is fixed when a file's first table is created, so a file made
  /// before the server asked for it can only change through one `VACUUM`.
  /// New files get the mode from the connection's `setup` callback.
  Future<void> _adoptIncrementalVacuum() async {
    final file = await customSelect('PRAGMA database_list').get();
    final path = file
        .where((row) => row.read<String>('name') == 'main')
        .map((row) => row.readNullable<String>('file') ?? '')
        .firstOrNull;
    if (path == null || path.isEmpty) {
      return;
    }
    final mode = await customSelect('PRAGMA auto_vacuum').getSingle();
    if (mode.read<int>('auto_vacuum') == 2) {
      return;
    }
    await customStatement('PRAGMA auto_vacuum = 2');
    await customStatement('VACUUM');
    _fileWasRewritten = true;
  }
}
