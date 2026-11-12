import 'package:drift/drift.dart'
    show CouldNotRollBackException, DriftWrappedException;
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:sqlite3/common.dart' show SqlError, SqliteException;

/// What kind of storage failure an error is, for callers that answer it
/// differently (a busy database can be retried, a full disk cannot).
enum StorageFailure {
  /// The database stayed locked by another writer past the busy timeout
  /// (`SQLITE_BUSY` / `SQLITE_LOCKED`).
  busy,

  /// The disk or the database's size limit is full (`SQLITE_FULL`).
  full,

  /// SQLite found the file's own structure broken (`SQLITE_CORRUPT`,
  /// `SQLITE_NOTADB`).
  damaged,

  /// A write reached a database that takes none (`SQLITE_READONLY`): a
  /// workspace whose file failed its integrity check is opened that way.
  readOnly,

  /// Any other SQLite failure.
  other,
}

/// The SQLite error behind [error], unwrapping drift's wrappers (a failed
/// statement, a failed rollback, a query answered from the database's
/// background isolate), or null when [error] is not a storage failure.
SqliteException? sqliteCauseOf(Object? error) {
  for (var depth = 0; depth < 8 && error != null; depth++) {
    switch (error) {
      case SqliteException():
        return error;
      case DriftWrappedException(:final cause):
        error = cause;
      case CouldNotRollBackException(:final exception):
        error = exception;
      case DriftRemoteException(:final remoteCause):
        error = remoteCause;
      default:
        return null;
    }
  }
  return null;
}

/// The [StorageFailure] [error] is, or null when it is not a storage failure.
StorageFailure? storageFailureOf(Object error) {
  final sqlite = sqliteCauseOf(error);
  if (sqlite == null) {
    return null;
  }
  return switch (sqlite.resultCode) {
    SqlError.SQLITE_BUSY || SqlError.SQLITE_LOCKED => StorageFailure.busy,
    SqlError.SQLITE_FULL => StorageFailure.full,
    SqlError.SQLITE_CORRUPT || SqlError.SQLITE_NOTADB => StorageFailure.damaged,
    SqlError.SQLITE_READONLY => StorageFailure.readOnly,
    _ => StorageFailure.other,
  };
}

/// A log-safe one-line description of a storage failure: result code,
/// message and statement, never the bound parameter values that
/// `SqliteException.toString` appends (message bodies, tokens). Null when
/// [error] is not a storage failure.
String? describeStorageError(Object error) {
  final sqlite = sqliteCauseOf(error);
  if (sqlite == null) {
    return null;
  }
  final explanation = sqlite.explanation;
  final operation = sqlite.operation;
  final statement = sqlite.causingStatement;
  return 'SqliteException(${sqlite.extendedResultCode}): ${sqlite.message}'
      '${explanation == null ? '' : ' ($explanation)'}'
      '${operation == null ? '' : ' while $operation'}'
      '${statement == null ? '' : ' — statement: $statement'}';
}
