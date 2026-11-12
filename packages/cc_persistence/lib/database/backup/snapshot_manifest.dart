import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_persistence/database/utils/durable_files.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Filename of the manifest inside a snapshot directory.
const snapshotManifestFileName = 'manifest.json';

/// The manifest format this build writes and reads. A manifest of any other
/// format describes files this build cannot verify, so the snapshot lists as
/// incomplete.
const snapshotManifestFormat = 2;

/// Why a workspace is not in a snapshot.
enum SnapshotSkipReason {
  /// Registered, never written to: there is no file.
  noFile('no_file'),

  /// Its file failed the integrity check. A damaged copy is not taken over
  /// the good ones.
  damaged('damaged'),

  /// The copy or its check failed.
  failed('failed');

  const SnapshotSkipReason(this.wire);

  /// Manifest spelling.
  final String wire;
}

/// What the manifest records about one copied database file, measured on the
/// copy after it was written.
final class SnapshotFileRecord {
  /// Creates a record.
  const SnapshotFileRecord({
    required this.file,
    required this.bytes,
    required this.sha256,
    required this.quickCheck,
    required this.userVersion,
    required this.applicationId,
  });

  /// Path relative to the snapshot directory, `/`-separated.
  final String file;

  /// Size of the copy.
  final int bytes;

  /// Lowercase hex SHA-256 of the copy.
  final String sha256;

  /// `PRAGMA quick_check` of the copy: `ok`, or SQLite's finding.
  final String quickCheck;

  /// `PRAGMA user_version` (the schema version) of the copy.
  final int userVersion;

  /// `PRAGMA application_id` of the copy.
  final int applicationId;

  /// Whether the copy passed its check when it was written.
  bool get verified => quickCheck == 'ok';

  /// Manifest form.
  Map<String, Object?> toJson() => {
    'file': file,
    'bytes': bytes,
    'sha256': sha256,
    'quick_check': quickCheck,
    'user_version': userVersion,
    'application_id': applicationId,
  };

  /// Reads a manifest entry; null when any field is missing or mistyped.
  static SnapshotFileRecord? tryParse(Object? json) {
    if (json is! Map) {
      return null;
    }
    final file = json['file'];
    final bytes = json['bytes'];
    final sha = json['sha256'];
    final check = json['quick_check'];
    final version = json['user_version'];
    final appId = json['application_id'];
    if (file is! String ||
        bytes is! int ||
        sha is! String ||
        check is! String ||
        version is! int ||
        appId is! int) {
      return null;
    }
    return SnapshotFileRecord(
      file: file,
      bytes: bytes,
      sha256: sha,
      quickCheck: check,
      userVersion: version,
      applicationId: appId,
    );
  }
}

/// One workspace's file in a snapshot.
typedef SnapshotWorkspaceEntry = ({
  String workspaceId,
  SnapshotFileRecord record,
});

/// One workspace a snapshot left out, and why.
typedef SnapshotSkip = ({String workspaceId, SnapshotSkipReason reason});

/// The manifest of a snapshot directory: what it holds, measured after the
/// copies were written. Written last, so a directory without one is a
/// snapshot that did not finish.
final class SnapshotManifest {
  /// Creates a manifest.
  const SnapshotManifest({
    required this.createdAt,
    required this.workspaces,
    this.global,
    this.skipped = const [],
  });

  /// When the snapshot was taken.
  final DateTime createdAt;

  /// The server-global file; null in a single-workspace backup.
  final SnapshotFileRecord? global;

  /// The workspace files.
  final List<SnapshotWorkspaceEntry> workspaces;

  /// Workspaces left out.
  final List<SnapshotSkip> skipped;

  /// Every file the manifest names.
  Iterable<SnapshotFileRecord> get files => [
    ?global,
    for (final entry in workspaces) entry.record,
  ];

  /// Manifest form.
  Map<String, Object?> toJson() => {
    'format': snapshotManifestFormat,
    'created_at': createdAt.toUtc().toIso8601String(),
    if (global != null) 'global': global!.toJson(),
    'workspaces': [
      for (final entry in workspaces)
        {'workspace_id': entry.workspaceId, ...entry.record.toJson()},
    ],
    'skipped_workspaces': [
      for (final skip in skipped)
        {'workspace_id': skip.workspaceId, 'reason': skip.reason.wire},
    ],
  };

  /// Whether [dir] holds a manifest file at all, readable or not.
  ///
  /// The manifest is written last, so a directory without one never
  /// finished. One that this build cannot [read] (another format) did
  /// finish: its files cannot be verified, which is not a reason to delete
  /// somebody's backup.
  static bool existsIn(Directory dir) =>
      FileSystemEntity.typeSync(
        '${dir.path}${Platform.pathSeparator}$snapshotManifestFileName',
        followLinks: false,
      ) ==
      FileSystemEntityType.file;

  /// Reads [dir]'s manifest. Null when there is none, or it is not this
  /// format, or any entry is malformed: all three mean nothing in the
  /// directory can be verified against it.
  static SnapshotManifest? read(Directory dir) {
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      '$snapshotManifestFileName',
    );
    if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      return null;
    }
    try {
      final json = jsonDecode(file.readAsStringSync());
      if (json is! Map || json['format'] != snapshotManifestFormat) {
        return null;
      }
      final createdAt = DateTime.tryParse('${json['created_at']}');
      final rawWorkspaces = json['workspaces'];
      final rawSkipped = json['skipped_workspaces'];
      if (createdAt == null || rawWorkspaces is! List || rawSkipped is! List) {
        return null;
      }
      SnapshotFileRecord? global;
      if (json.containsKey('global')) {
        global = SnapshotFileRecord.tryParse(json['global']);
        if (global == null) {
          return null;
        }
      }
      final workspaces = <SnapshotWorkspaceEntry>[];
      for (final raw in rawWorkspaces) {
        final record = SnapshotFileRecord.tryParse(raw);
        final id = raw is Map ? raw['workspace_id'] : null;
        if (record == null || id is! String) {
          return null;
        }
        workspaces.add((workspaceId: id, record: record));
      }
      final skipped = <SnapshotSkip>[];
      for (final raw in rawSkipped) {
        final id = raw is Map ? raw['workspace_id'] : null;
        final reason = raw is Map
            ? SnapshotSkipReason.values
                  .where((r) => r.wire == raw['reason'])
                  .firstOrNull
            : null;
        if (id is! String || reason == null) {
          return null;
        }
        skipped.add((workspaceId: id, reason: reason));
      }
      return SnapshotManifest(
        createdAt: createdAt,
        global: global,
        workspaces: workspaces,
        skipped: skipped,
      );
    } on Object {
      return null;
    }
  }

  /// Writes this manifest into [dir] through a temp file, a flush and a
  /// rename: a reader finds either no manifest or the whole of it.
  Future<void> writeTo(Directory dir) => writeFileAtomically(
    '${dir.path}${Platform.pathSeparator}$snapshotManifestFileName',
    const JsonEncoder.withIndent('  ').convert(toJson()),
  );

  /// The record of the file at [path] inside [dir], or null when the
  /// manifest names no such file.
  SnapshotFileRecord? recordFor(Directory dir, String path) {
    final wanted = File(path).absolute.path;
    for (final record in files) {
      final candidate = File(
        '${dir.path}${Platform.pathSeparator}'
        '${record.file.replaceAll('/', Platform.pathSeparator)}',
      ).absolute.path;
      if (candidate == wanted) {
        return record;
      }
    }
    return null;
  }

  /// Whether every named file is in [dir] at its recorded size and passed
  /// its check when written. Hashes are not recomputed: that is a read of
  /// every byte, paid when a file is restored, not on every listing.
  bool isIntactIn(Directory dir) =>
      files.every((record) => record.verified && _sizeMatches(dir, record));

  /// Whether [record]'s file in [dir] is a regular file of its recorded size.
  static bool _sizeMatches(Directory dir, SnapshotFileRecord record) {
    final path =
        '${dir.path}${Platform.pathSeparator}'
        '${record.file.replaceAll('/', Platform.pathSeparator)}';
    return FileSystemEntity.typeSync(path, followLinks: false) ==
            FileSystemEntityType.file &&
        File(path).lengthSync() == record.bytes;
  }

  /// Whether the copy of [workspaceId] in [dir] is verified and whole.
  bool holdsVerifiedCopyOf(Directory dir, String workspaceId) => workspaces.any(
    (entry) =>
        entry.workspaceId == workspaceId &&
        entry.record.verified &&
        _sizeMatches(dir, entry.record),
  );
}

/// Measures the copy at [path] (recorded as [relative]) on an isolate of its
/// own: the hash reads every byte and `quick_check` every page, which would
/// otherwise stall every request on this one.
///
/// The copy is checked on a read-write connection: every connection loads
/// the vector extension, which creates its own table in a file that lacks
/// it (`global.db` does), and a read-only open of such a file is refused.
/// The size and hash are taken after that connection closes, so they
/// describe the bytes as they stay. A copy that cannot be opened at all is
/// recorded with SQLite's reason as its check result.
Future<SnapshotFileRecord> inspectSnapshotFile(String path, String relative) =>
    Isolate.run(() async {
      var check = 'no result';
      var userVersion = 0;
      var applicationId = 0;
      try {
        final db = sqlite.sqlite3.open(path);
        try {
          db.execute('PRAGMA trusted_schema = OFF');
          int pragma(String name) =>
              db.select('PRAGMA $name').single.values.single! as int;
          userVersion = pragma('user_version');
          applicationId = pragma('application_id');
          check =
              db.select('PRAGMA quick_check').first.values.first?.toString() ??
              check;
        } on sqlite.SqliteException catch (e) {
          check = e.message;
        } finally {
          db.close();
        }
      } on sqlite.SqliteException catch (e) {
        check = e.message;
      }
      return SnapshotFileRecord(
        file: relative,
        bytes: File(path).lengthSync(),
        sha256: await backupFileDigest(File(path).openRead()),
        quickCheck: check,
        userVersion: userVersion,
        applicationId: applicationId,
      );
    });
