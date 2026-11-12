import 'dart:io';

import 'package:cc_infra/cc_paths.dart'
    show PrivateDirectoryException, ensurePrivateDirectory, tightenToOwnerOnly;
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:drift/drift.dart' show DriftWrappedException;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:path/path.dart' as p;

/// A reason the server refuses to start that the operator has to resolve.
///
/// Not a crash: the server binaries print [message] and exit with status 78
/// (`EX_CONFIG`), the same way an exported provider secret ends the boot.
abstract base class ServerBootRefusal implements Exception {
  /// Creates a refusal.
  const ServerBootRefusal();

  /// What is wrong and what to do about it, for the operator's terminal.
  String get message;

  @override
  String toString() => message;
}

/// The data directory is readable by accounts other than the server's own and
/// could not be restricted.
final class DataDirNotPrivate extends ServerBootRefusal {
  /// Creates the refusal for the [cause] reported by the mode check.
  const DataDirNotPrivate(this.cause);

  /// The directory and the mode it still has.
  final PrivateDirectoryException cause;

  @override
  String get message =>
      'cc_server: cannot start — the data directory ${cause.path} is mode '
      '${cause.octalMode} and could not be restricted to its owner (0700). It '
      'holds the server identity, the secrets file and every database, so '
      'other accounts on this host must not be able to read it. Make the '
      'account that runs cc_server its owner (chown) and run '
      '`chmod 700 ${cause.path}`, or pass a different --data-dir.';
}

/// Secures [dataDir] before anything in it is opened.
///
/// Creates it `0700`, or tightens an existing one to `0700`, and throws
/// [DataDirNotPrivate] when it still is not owner-only. Then tightens to `0600`
/// the secret-bearing files that sit directly in it (`global.db` with its WAL
/// and shared-memory files, `server_identity.json`, `secrets.json`) and to
/// `0700` each workspace directory (a subdirectory holding a `workspace.db`).
/// Files are created under the umask by SQLite, so this pass is what keeps
/// an install made before the directory was private from staying readable.
///
/// POSIX only: on Windows the directory is created and secrecy rests on the
/// ACL it inherits, as there are no mode bits to check.
void secureDataDirectory(String dataDir) {
  try {
    ensurePrivateDirectory(dataDir);
  } on PrivateDirectoryException catch (e) {
    throw DataDirNotPrivate(e);
  }
  if (Platform.isWindows) {
    return;
  }
  for (final name in secretFileNames) {
    tightenToOwnerOnly(p.join(dataDir, name));
  }
  for (final entry in Directory(dataDir).listSync(followLinks: false)) {
    if (entry is Directory &&
        File(p.join(entry.path, 'workspace.db')).existsSync()) {
      tightenToOwnerOnly(entry.path);
    }
  }
}

/// The secret-bearing files kept directly in the data directory.
const List<String> secretFileNames = [
  'global.db',
  'global.db-wal',
  'global.db-shm',
  'server_identity.json',
  'secrets.json',
];

/// The server-global database (`global.db`) cannot be served.
///
/// Everything the server does starts from this file (the workspace
/// registry, paired devices, the owner, the pre-auth routes), and unlike a
/// workspace it has no read-only mode: a server that ran on top of it would
/// spread the damage into every later snapshot, or rewrite a newer build's
/// file with an older schema. So the boot stops and tells the operator which
/// of the three it is.
sealed class GlobalDatabaseUnusable extends ServerBootRefusal {
  /// Creates the refusal for the file at [path].
  const GlobalDatabaseUnusable(this.path);

  /// The `global.db` the server tried to open.
  final String path;
}

/// `global.db` failed SQLite's integrity check, or is not readable as a
/// database at all.
final class GlobalDatabaseDamaged extends GlobalDatabaseUnusable {
  /// Creates the refusal with SQLite's [finding].
  const GlobalDatabaseDamaged(super.path, this.finding);

  /// What SQLite reported.
  final String finding;

  @override
  String get message =>
      'cc_server: cannot start — $path is damaged ($finding). Stop every '
      'process using this data directory and restore global.db from a '
      'snapshot (the newest copy in its backups directory, or a pre_upgrade/ '
      'copy beside it), then start the server again.';
}

/// `global.db` was written by a newer server build than this one.
final class GlobalDatabaseNewer extends GlobalDatabaseUnusable {
  /// Creates the refusal for the two schema versions.
  const GlobalDatabaseNewer(super.path, this.fileVersion, this.binaryVersion);

  /// The schema version stamped on the file.
  final int fileVersion;

  /// The schema version this build declares.
  final int binaryVersion;

  @override
  String get message =>
      'cc_server: cannot start — $path is at schema v$fileVersion and this '
      'build knows only v$binaryVersion. Run the newer server build that '
      'wrote it; this one will not downgrade the file.';
}

/// `global.db` is an SQLite file this server did not write as its global
/// database.
final class GlobalDatabaseForeign extends GlobalDatabaseUnusable {
  /// Creates the refusal for the [applicationId] found in the file.
  const GlobalDatabaseForeign(super.path, this.applicationId);

  /// The `application_id` the file carries.
  final int applicationId;

  @override
  String get message =>
      'cc_server: cannot start — $path is not a Control Center global '
      'database (application id $applicationId). Move it aside, or pass the '
      '--data-dir that holds this install.';
}

/// Opens [db] (the global database at [path]) now, so a file the server
/// cannot serve stops the boot with a [GlobalDatabaseUnusable] instead of
/// failing the first request that reaches it.
Future<void> openGlobalDatabaseOrRefuse(GlobalDatabase db, String path) async {
  try {
    await db.customSelect('SELECT 1').get();
  } on Object catch (e) {
    // The file opens in drift's background isolate, which hands the open
    // failure back wrapped, sometimes more than once.
    var cause = e;
    for (var depth = 0; depth < 8; depth++) {
      cause = switch (cause) {
        DriftRemoteException(:final remoteCause) => remoteCause,
        DriftWrappedException(:final Object cause) => cause,
        _ => cause,
      };
    }
    throw switch (cause) {
      DatabaseDamagedException() => GlobalDatabaseDamaged(path, cause.finding),
      DatabaseNewerThanBinaryException() => GlobalDatabaseNewer(
        path,
        cause.fileVersion,
        cause.binaryVersion,
      ),
      ForeignDatabaseFileException() => GlobalDatabaseForeign(
        path,
        cause.applicationId,
      ),
      _ when storageFailureOf(cause) == StorageFailure.damaged =>
        GlobalDatabaseDamaged(path, describeStorageError(cause) ?? '$cause'),
      _ => e,
    };
  }
}
