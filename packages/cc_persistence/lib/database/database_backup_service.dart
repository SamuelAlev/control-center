import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cc_domain/cc_domain.dart' show NotFoundException;
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_domain/core/domain/events/workspace_events.dart';
import 'package:cc_domain/core/domain/ports/database_backup_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/database/backup/snapshot_manifest.dart';
import 'package:cc_persistence/database/backup/workspace_import.dart';
import 'package:cc_persistence/database/daos/imported_authority_hold_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/schema/converged_database.dart';
import 'package:cc_persistence/database/tables/workspace_routes_table.dart';
import 'package:cc_persistence/database/utils/durable_files.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/src/server_database.dart';
import 'package:drift/drift.dart';

/// [DatabaseBackupPort] over SQLite `VACUUM INTO`, each copy taken on a
/// connection of its own.
///
/// Whole-install snapshots are timestamped directories under `backupsDir`
/// holding `<workspaceId>/workspace.db` per live workspace, `global.db` and,
/// written last, `manifest.json` ([SnapshotManifest]): per file its size,
/// SHA-256, `quick_check` result, schema version and application id, each
/// measured on the copy. Scoped backups live at
/// `workspace-backups/<workspaceId>/<timestamp>/` with the same manifest and
/// no global or other workspace data. A restore first leaves the replaced
/// file there as `<timestamp>-pre-restore`. The code index is never copied:
/// it is rebuilt from the data.
class AppDatabaseBackupService implements DatabaseBackupPort {
  /// Creates a backup service writing into [backupsDir].
  ///
  /// [exportsDir] receives single-workspace exports (defaults to a sibling of
  /// [backupsDir]). [_webhookSecrets] turns an imported trigger's token
  /// reference into its route key; [_eventBus] carries [WorkspaceRestored]
  /// and the membership changes a restore makes. [_now] is a test seam.
  AppDatabaseBackupService({
    required this._global,
    required this._workspaces,
    required String backupsDir,
    required this._webhookSecrets,
    required this._eventBus,
    String? exportsDir,
    this._now = DateTime.now,
    this._onWarn,
  }) : _backupsDir = backupsDir,
       _exportsDir =
           exportsDir ?? '$backupsDir${Platform.pathSeparator}exports';

  final GlobalDatabase _global;
  final WorkspaceDatabaseManager _workspaces;
  final WebhookSecretVault _webhookSecrets;
  final DomainEventBus _eventBus;
  final String _backupsDir;
  final String _exportsDir;
  final DateTime Function() _now;
  final void Function(String message)? _onWarn;

  /// Filename of the manifest inside a snapshot directory.
  static const manifestFileName = snapshotManifestFileName;

  /// Name suffix of the copy a restore takes of the file it replaces.
  static const preRestoreSuffix = '-pre-restore';

  /// Suffix of the staged copy of an incoming file, beside `workspace.db`.
  static const importingSuffix = '.importing';

  /// Filename of a workspace's code index, which is rebuilt rather than
  /// restored.
  static const codeIndexFileName = 'code_index.db';

  /// A snapshot directory younger than this with no manifest may still be
  /// being written, so pruning leaves it alone.
  static const inProgressGrace = Duration(hours: 1);

  /// Matches what [_timestamp] writes, with an optional [preRestoreSuffix].
  /// `toIso8601String` emits microseconds (six fractional digits) whenever
  /// the sub-millisecond part is non-zero, i.e. almost always on a real
  /// clock, and milliseconds only otherwise.
  static final _snapshotNamePattern = RegExp(
    r'^(\d{4}-\d{2}-\d{2})T(\d{2})-(\d{2})-(\d{2})-(\d{3}(?:\d{3})?)Z'
    '(?:$preRestoreSuffix)?\$',
  );

  /// Imports in flight per workspace. A second import of the same workspace
  /// waits for the first: both would stage into the same file.
  final Map<String, Future<void>> _importLocks = {};

  Directory get _workspaceBackups =>
      Directory('$_backupsDir${Platform.pathSeparator}workspace-backups');

  DateTime? _snapshotDate(String name) {
    final match = _snapshotNamePattern.firstMatch(name);
    if (match == null) {
      return null;
    }
    return DateTime.tryParse(
      '${match[1]}T${match[2]}:${match[3]}:${match[4]}.${match[5]}Z',
    );
  }

  /// Do not let an externally substituted backups root or scope redirect I/O.
  void _requireRealDirectory(Directory dir) {
    final type = FileSystemEntity.typeSync(dir.path, followLinks: false);
    if (type == FileSystemEntityType.link ||
        (type != FileSystemEntityType.notFound &&
            type != FileSystemEntityType.directory)) {
      throw StateError('backup directory is not a real directory: ${dir.path}');
    }
  }

  Future<Directory> _newSnapshot(Directory parent, {String suffix = ''}) async {
    _requireRealDirectory(Directory(_backupsDir));
    _requireRealDirectory(parent);
    await parent.create(recursive: true);
    final dir = Directory(
      '${parent.path}${Platform.pathSeparator}${_timestamp()}$suffix',
    );
    if (FileSystemEntity.typeSync(dir.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      throw StateError('snapshot already exists: ${dir.path}');
    }
    await dir.create();
    return dir;
  }

  /// Traversal is explicit: `followLinks: false` includes links as links,
  /// which are unlinked rather than traversed into their external targets.
  Future<void> _removeSnapshot(Directory dir) async {
    if (FileSystemEntity.typeSync(dir.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      throw StateError('snapshot is not a real directory: ${dir.path}');
    }
    await for (final child in dir.list(followLinks: false)) {
      if (child is Directory) {
        await _removeSnapshot(child);
      } else {
        await child.delete();
      }
    }
    await dir.delete();
  }

  /// Opens [workspaceId]'s file if it is not open yet, which is when this
  /// process checks it. After this, [WorkspaceDatabaseManager.integrityFailure]
  /// answers for it.
  Future<void> _open(String workspaceId) =>
      _workspaces.of(workspaceId).customSelect('SELECT 1').get();

  /// Copies [workspaceId] to [relative] under [dir] on a connection of its
  /// own and measures the copy. Null when the live file is damaged: such a
  /// file is not copied over good ones. Throws when the copy itself fails
  /// its check (and removes it).
  Future<SnapshotFileRecord?> _copyWorkspace(
    String workspaceId,
    Directory dir,
    String relative,
  ) async {
    await _open(workspaceId);
    if (_workspaces.integrityFailure(workspaceId) != null) {
      return null;
    }
    final path = _under(dir, relative);
    await File(path).parent.create(recursive: true);
    await _workspaces.snapshotTo(workspaceId, path);
    final record = await inspectSnapshotFile(path, relative);
    if (!record.verified) {
      await File(path).delete();
      throw DatabaseDamagedException(
        database: 'copy of workspace $workspaceId',
        finding: record.quickCheck,
      );
    }
    return record;
  }

  /// Copies `global.db` into [dir] and measures the copy.
  ///
  /// `VACUUM INTO` on the global connection itself, which reads one
  /// consistent state. Not [snapshotDatabaseFile]: its read-only connection
  /// loads the vector extension, which creates its own table on open, and
  /// `global.db` (opened before the extension is registered) has none, so
  /// that open is refused.
  Future<SnapshotFileRecord> _copyGlobal(Directory dir) async {
    const relative = globalDatabaseFileName;
    final path = _under(dir, relative);
    await _global.backupTo(path);
    final record = await inspectSnapshotFile(path, relative);
    if (!record.verified) {
      throw DatabaseDamagedException(
        database: 'copy of global',
        finding: record.quickCheck,
      );
    }
    return record;
  }

  static String _under(Directory dir, String relative) =>
      '${dir.path}${Platform.pathSeparator}'
      '${relative.replaceAll('/', Platform.pathSeparator)}';

  @override
  Future<String> backupNow() async {
    final dir = await _newSnapshot(Directory(_backupsDir));
    final entries = <SnapshotWorkspaceEntry>[];
    final skipped = <SnapshotSkip>[];
    // CROSS-WORKSPACE BY DESIGN: a backup is the snapshot of an INSTALL, so it
    // covers every live workspace by definition. Enumerated directly rather
    // than via CrossWorkspaceQueries because the unit of work here is a FILE
    // (one copy per database), not a query to fan out.
    for (final id in await _workspaces.liveWorkspaceIds()) {
      if (!_workspaces.existsOnDisk(id)) {
        // Registered and never written to: there is no file. Recorded so the
        // manifest says what was and wasn't captured.
        skipped.add((workspaceId: id, reason: SnapshotSkipReason.noFile));
        continue;
      }
      try {
        final record = await _copyWorkspace(
          id,
          dir,
          '$id/$workspaceDatabaseFileName',
        );
        if (record == null) {
          skipped.add((workspaceId: id, reason: SnapshotSkipReason.damaged));
        } else {
          entries.add((workspaceId: id, record: record));
        }
      } on Object catch (e) {
        skipped.add((workspaceId: id, reason: SnapshotSkipReason.failed));
        _onWarn?.call('backup of workspace $id failed: $e');
      }
    }
    if (skipped.isNotEmpty) {
      _onWarn?.call(
        'backup skipped ${skipped.length} workspace(s): '
        '${skipped.map((s) => '${s.workspaceId} (${s.reason.wire})').join(', ')}',
      );
    }
    // Last: routes in the global file are rebuilt from the workspaces anyway,
    // but the registry must never be older than a workspace file it lists.
    final global = await _copyGlobal(dir);
    await SnapshotManifest(
      createdAt: _now(),
      global: global,
      workspaces: entries,
      skipped: skipped,
    ).writeTo(dir);
    return dir.path;
  }

  @override
  Future<String> backupWorkspace(String workspaceId) async {
    final dir = await _scopedBackup(workspaceId);
    return _under(dir, workspaceDatabaseFileName);
  }

  /// Writes a verified scoped backup of [workspaceId] and returns its
  /// directory. Refuses a damaged workspace ([DatabaseDamagedException]):
  /// its copy would be pruned in place of the good ones.
  Future<Directory> _scopedBackup(
    String workspaceId, {
    String suffix = '',
  }) async {
    final scope = _workspaceBackupScope(workspaceId);
    if (!_workspaces.existsOnDisk(workspaceId)) {
      throw StateError(
        'workspace $workspaceId has no database file to back up',
      );
    }
    await _open(workspaceId);
    final damage = _workspaces.integrityFailure(workspaceId);
    if (damage != null) {
      throw DatabaseDamagedException(
        database: 'workspace $workspaceId',
        finding: damage,
      );
    }
    final dir = await _newSnapshot(scope, suffix: suffix);
    try {
      final record = await _copyWorkspace(
        workspaceId,
        dir,
        workspaceDatabaseFileName,
      );
      if (record == null) {
        throw DatabaseDamagedException(
          database: 'workspace $workspaceId',
          finding: _workspaces.integrityFailure(workspaceId) ?? 'damaged',
        );
      }
      await SnapshotManifest(
        createdAt: _now(),
        workspaces: [(workspaceId: workspaceId, record: record)],
      ).writeTo(dir);
      return dir;
    } on Object {
      await _removeSnapshot(dir);
      rethrow;
    }
  }

  /// Keeps the file a restore is about to replace, so the restore can be
  /// undone: a verified scoped backup named `…-pre-restore`, or, when the
  /// live file is damaged (the usual reason to restore), its bytes as they
  /// are, with its log, and a manifest recording the failed check.
  Future<void> _preRestoreCopy(String workspaceId) async {
    var damaged = false;
    try {
      await _open(workspaceId);
      damaged = _workspaces.integrityFailure(workspaceId) != null;
    } on Object {
      // Too damaged even to open.
      damaged = true;
    }
    if (!damaged) {
      await _scopedBackup(workspaceId, suffix: preRestoreSuffix);
      return;
    }
    final scope = _workspaceBackupScope(workspaceId);
    final dir = await _newSnapshot(scope, suffix: preRestoreSuffix);
    final live = _workspaces.pathFor(workspaceId);
    final copy = _under(dir, workspaceDatabaseFileName);
    await File(live).copy(copy);
    if (File('$live-wal').existsSync()) {
      await File('$live-wal').copy('$copy-wal');
    }
    await SnapshotManifest(
      createdAt: _now(),
      workspaces: [
        (
          workspaceId: workspaceId,
          record: await inspectSnapshotFile(copy, workspaceDatabaseFileName),
        ),
      ],
    ).writeTo(dir);
  }

  @override
  Future<void> deleteBackup(String name) async {
    if (_snapshotDate(name) == null) {
      throw ArgumentError.value(name, 'name', 'invalid snapshot name');
    }
    final root = Directory(_backupsDir);
    _requireRealDirectory(root);
    final dir = Directory('${root.path}${Platform.pathSeparator}$name');
    await _removeSnapshot(dir);
  }

  @override
  Future<int> deleteBackupsOlderThan({
    required Duration age,
    String? workspaceId,
  }) async {
    if (age.isNegative) {
      throw ArgumentError.value(age, 'age', 'must not be negative');
    }
    final root = Directory(_backupsDir);
    _requireRealDirectory(root);
    Directory scope = root;
    if (workspaceId != null) {
      scope = _workspaceBackupScope(workspaceId);
    }
    if (!scope.existsSync()) {
      return 0;
    }
    final now = _now().toUtc();
    final cutoff = now.subtract(age);
    final unfinishedCutoff = now.subtract(inProgressGrace);
    final pinned = _pinned(_datedSnapshots(scope));
    var deleted = 0;
    for (final (date, dir, name) in _datedSnapshots(scope)) {
      if (pinned.containsKey(name)) {
        continue;
      }
      // A directory with no manifest never finished, because the manifest
      // is written last: it goes first, whatever its age, unless it may
      // still be being written. A manifest this build cannot read (a
      // snapshot taken before the format changed) is a finished backup that
      // lists as incomplete; it stays until it ages out or its owner
      // deletes it.
      final unfinished =
          !SnapshotManifest.existsIn(dir) && date.isBefore(unfinishedCutoff);
      if (date.isBefore(cutoff) || unfinished) {
        await _removeSnapshot(dir);
        deleted++;
      }
    }
    return deleted;
  }

  /// The timestamp-named snapshot directories directly under [scope], newest
  /// first. Ordered by the timestamp, not the name: the fractional part is
  /// three or six digits wide, so names are not fixed-width.
  List<(DateTime, Directory, String)> _datedSnapshots(Directory scope) {
    if (!scope.existsSync()) {
      return const [];
    }
    final snapshots = <(DateTime, Directory, String)>[];
    for (final entity in scope.listSync(followLinks: false)) {
      if (entity is! Directory) {
        continue;
      }
      final name = entity.path.split(Platform.pathSeparator).last;
      final date = _snapshotDate(name);
      if (date != null) {
        snapshots.add((date, entity, name));
      }
    }
    snapshots.sort((a, b) => b.$1.compareTo(a.$1));
    return snapshots;
  }

  /// The snapshots pruning must keep whatever their age, by name: for each
  /// workspace whose live file is damaged, the newest snapshot among
  /// [snapshots] (newest first) holding a verified copy of it.
  Map<String, String> _pinned(List<(DateTime, Directory, String)> snapshots) {
    final damaged = _workspaces.integrityFailures.keys.toSet();
    if (damaged.isEmpty) {
      return const {};
    }
    final pinned = <String, String>{};
    final unresolved = {...damaged};
    for (final (_, dir, name) in snapshots) {
      if (unresolved.isEmpty) {
        break;
      }
      final manifest = SnapshotManifest.read(dir);
      if (manifest == null) {
        continue;
      }
      for (final id in unresolved.toList()) {
        if (manifest.holdsVerifiedCopyOf(dir, id)) {
          pinned[name] = BackupSnapshot.lastGoodCopyPin;
          unresolved.remove(id);
        }
      }
    }
    return pinned;
  }

  @override
  Future<List<BackupSnapshot>> listBackups() async {
    final root = Directory(_backupsDir);
    _requireRealDirectory(root);
    // Only timestamp-named install snapshots belong in this list. Exports and
    // scoped workspace backups have their own lanes.
    final snapshots = _datedSnapshots(root);
    final pinned = _pinned(snapshots);
    return [
      for (final (_, dir, name) in snapshots)
        _readSnapshot(dir, name, pinnedReason: pinned[name]),
    ];
  }

  /// The directory holding [workspaceId]'s scoped backups, which may not exist.
  Directory _workspaceBackupScope(String workspaceId) {
    if (!WorkspaceDatabaseManager.isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'invalid');
    }
    _requireRealDirectory(Directory(_backupsDir));
    _requireRealDirectory(_workspaceBackups);
    final scope = Directory(
      '${_workspaceBackups.path}${Platform.pathSeparator}$workspaceId',
    );
    _requireRealDirectory(scope);
    return scope;
  }

  /// Resolves backup [name] strictly under its workspace's own directory.
  Directory _workspaceBackupDir(String workspaceId, String name) {
    if (_snapshotDate(name) == null) {
      throw ArgumentError.value(name, 'name', 'invalid backup name');
    }
    final scope = _workspaceBackupScope(workspaceId);
    return Directory('${scope.path}${Platform.pathSeparator}$name');
  }

  @override
  Future<List<BackupSnapshot>> listWorkspaceBackups(String workspaceId) async {
    final scope = _workspaceBackupScope(workspaceId);
    final backups = _datedSnapshots(scope);
    final pinned = _pinned(backups);
    return [
      for (final (date, dir, name) in backups)
        _readWorkspaceBackup(
          dir,
          name,
          date,
          workspaceId,
          pinnedReason: pinned[name],
        ),
    ];
  }

  @override
  Future<String?> workspaceBackupFile(String workspaceId, String name) async {
    final dir = _workspaceBackupDir(workspaceId, name);
    if (FileSystemEntity.typeSync(dir.path, followLinks: false) !=
        FileSystemEntityType.directory) {
      return null;
    }
    final path = _under(dir, workspaceDatabaseFileName);
    return FileSystemEntity.typeSync(path, followLinks: false) ==
            FileSystemEntityType.file
        ? path
        : null;
  }

  @override
  Future<void> deleteWorkspaceBackup(String workspaceId, String name) =>
      _removeSnapshot(_workspaceBackupDir(workspaceId, name));

  @override
  Future<List<OrphanedWorkspaceBackups>> listOrphanedWorkspaceBackups() async {
    _requireRealDirectory(Directory(_backupsDir));
    _requireRealDirectory(_workspaceBackups);
    if (!_workspaceBackups.existsSync()) {
      return const [];
    }
    // CROSS-WORKSPACE BY DESIGN: this is the install owner's view of leftovers,
    // and it reads directory names only. No workspace database is opened.
    final live = (await _workspaces.liveWorkspaceIds()).toSet();
    final names = await _global.workspaceRegistryDao.namesIncludingDeleted();
    final orphans = <OrphanedWorkspaceBackups>[];
    for (final entity in _workspaceBackups.listSync(followLinks: false)) {
      final id = entity.path.split(Platform.pathSeparator).last;
      if (entity is! Directory ||
          !WorkspaceDatabaseManager.isValidWorkspaceId(id) ||
          live.contains(id)) {
        continue;
      }
      final backups = await listWorkspaceBackups(id);
      if (backups.isNotEmpty) {
        orphans.add(
          OrphanedWorkspaceBackups(
            workspaceId: id,
            workspaceName: names[id],
            backups: backups,
          ),
        );
      }
    }
    return orphans;
  }

  @override
  Future<void> deleteOrphanedWorkspaceBackup(
    String workspaceId,
    String name,
  ) async {
    if ((await _workspaces.liveWorkspaceIds()).contains(workspaceId)) {
      throw StateError('workspace $workspaceId is live');
    }
    await deleteWorkspaceBackup(workspaceId, name);
  }

  /// Reads one scoped backup. Its directory name gives the time; its
  /// manifest decides whether it is whole.
  BackupSnapshot _readWorkspaceBackup(
    Directory dir,
    String name,
    DateTime date,
    String workspaceId, {
    String? pinnedReason,
  }) {
    final path = _under(dir, workspaceDatabaseFileName);
    final file = File(path);
    // A link is not a backup this service wrote, and a restore would read
    // through it, so it is reported as missing rather than offered.
    final restorable =
        FileSystemEntity.typeSync(path, followLinks: false) ==
            FileSystemEntityType.file &&
        file.lengthSync() > 0;
    final manifest = SnapshotManifest.read(dir);
    return BackupSnapshot(
      path: dir.path,
      name: name,
      createdAt: date,
      bytes: _directoryBytes(dir),
      workspaces: [
        if (restorable)
          BackupSnapshotWorkspace(
            workspaceId: workspaceId,
            path: path,
            bytes: file.lengthSync(),
          ),
      ],
      complete:
          restorable &&
          manifest != null &&
          manifest.workspaces.length == 1 &&
          manifest.holdsVerifiedCopyOf(dir, workspaceId),
      pinnedReason: pinnedReason,
    );
  }

  /// Reads one snapshot directory, tolerating every way it can be broken.
  ///
  /// Nothing here throws: an unreadable snapshot is reported as incomplete,
  /// because the operator's question is "what do I have?" and a listing that
  /// fails on the first damaged entry answers it for nobody.
  BackupSnapshot _readSnapshot(
    Directory dir,
    String name, {
    String? pinnedReason,
  }) {
    final manifest = SnapshotManifest.read(dir);
    final workspaces = <BackupSnapshotWorkspace>[];
    if (manifest != null) {
      for (final entry in manifest.workspaces) {
        final path = _under(dir, entry.record.file);
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.file) {
          // Missing entry: exclude it from the individually restorable set.
          continue;
        }
        workspaces.add(
          BackupSnapshotWorkspace(
            workspaceId: entry.workspaceId,
            path: path,
            bytes: File(path).lengthSync(),
          ),
        );
      }
    } else {
      // No manifest this build can read. The per-workspace files are still
      // adoptable one by one (an import checks each anyway), so recover what
      // the layout itself says rather than reporting an empty snapshot.
      for (final child in dir.listSync(followLinks: false)) {
        if (child is! Directory) {
          continue;
        }
        final path = _under(child, workspaceDatabaseFileName);
        if (FileSystemEntity.typeSync(path, followLinks: false) !=
            FileSystemEntityType.file) {
          continue;
        }
        workspaces.add(
          BackupSnapshotWorkspace(
            workspaceId: child.path.split(Platform.pathSeparator).last,
            path: path,
            bytes: File(path).lengthSync(),
          ),
        );
      }
    }
    return BackupSnapshot(
      path: dir.path,
      name: name,
      createdAt: manifest?.createdAt,
      bytes: _directoryBytes(dir),
      workspaces: workspaces,
      skippedWorkspaceIds: [
        for (final skip in manifest?.skipped ?? const <SnapshotSkip>[])
          skip.workspaceId,
      ],
      complete:
          manifest != null &&
          manifest.global != null &&
          manifest.skipped.isEmpty &&
          manifest.isIntactIn(dir),
      pinnedReason: pinnedReason,
    );
  }

  /// Bytes on disk under [dir], which is what an operator deciding whether to
  /// keep a snapshot is actually asking about — not the manifest's own sum,
  /// which describes the files it MEANT to write.
  int _directoryBytes(Directory dir) {
    var total = 0;
    for (final entity in dir.listSync(recursive: true, followLinks: false)) {
      if (entity is File) {
        try {
          total += entity.lengthSync();
        } on Object {
          // A file that vanished mid-walk contributes nothing; a size is not
          // worth failing a listing over.
        }
      }
    }
    return total;
  }

  @override
  Future<String> exportWorkspace(String workspaceId) async {
    if (!WorkspaceDatabaseManager.isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'invalid');
    }
    if (!_workspaces.existsOnDisk(workspaceId)) {
      throw StateError(
        'workspace $workspaceId has no database file to export '
        '(it has never been written to)',
      );
    }
    final dir = Directory(_exportsDir);
    await dir.create(recursive: true);
    final relative = '$workspaceId-${_timestamp()}.db';
    final record = await _copyWorkspace(workspaceId, dir, relative);
    if (record == null) {
      throw DatabaseDamagedException(
        database: 'workspace $workspaceId',
        finding: _workspaces.integrityFailure(workspaceId) ?? 'damaged',
      );
    }
    return _under(dir, relative);
  }

  /// Removes the staged copy a crashed import left beside each live
  /// workspace's file. The server's boot calls it once, before it serves.
  /// Returns how many it removed.
  Future<int> removeStaleImportFiles() async {
    var removed = 0;
    // CROSS-WORKSPACE BY DESIGN: a boot sweep over files on disk; it opens no
    // database.
    for (final id in await _workspaces.liveWorkspaceIds()) {
      if (_removeStaged(_stagedPath(id))) {
        removed++;
      }
    }
    return removed;
  }

  String _stagedPath(String workspaceId) =>
      '${_workspaces.pathFor(workspaceId)}$importingSuffix';

  /// Deletes the staged file at [path] and its SQLite sidecars. Returns
  /// whether there was one.
  static bool _removeStaged(String path) {
    var found = false;
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (FileSystemEntity.typeSync(file.path, followLinks: false) !=
          FileSystemEntityType.notFound) {
        file.deleteSync();
        found = true;
      }
    }
    return found;
  }

  /// Stages [sourcePath] beside the live file, validates and strips the
  /// staged copy ([prepareStagedWorkspace]), keeps a copy of the file it
  /// replaces, then renames it into place. A refusal or failure before the
  /// rename leaves the workspace exactly as it was and no staged file.
  ///
  /// Adopting this server's own snapshot gets no exemption: the bytes on
  /// disk are whatever is there now, not what this server wrote then.
  @override
  Future<String> importWorkspace({
    required String workspaceId,
    required String sourcePath,
    required String importedBy,
  }) async {
    if (!WorkspaceDatabaseManager.isValidWorkspaceId(workspaceId)) {
      throw ArgumentError.value(workspaceId, 'workspaceId', 'invalid');
    }
    if (_workspaces.isDeleted(workspaceId)) {
      throw DeletedWorkspaceException(workspaceId);
    }
    final previous = _importLocks[workspaceId];
    final done = Completer<void>();
    final mine = done.future;
    _importLocks[workspaceId] = mine;
    try {
      await previous;
      await _import(workspaceId, sourcePath, importedBy);
      return workspaceId;
    } finally {
      done.complete();
      if (identical(_importLocks[workspaceId], mine)) {
        unawaited(_importLocks.remove(workspaceId));
      }
    }
  }

  Future<void> _import(
    String workspaceId,
    String sourcePath,
    String importedBy,
  ) async {
    if (FileSystemEntity.typeSync(sourcePath) != FileSystemEntityType.file) {
      throw const WorkspaceImportRefusedException(
        WorkspaceImportRefusal.missingSource,
        'There is no file to restore from',
      );
    }
    await _verifyAgainstManifest(sourcePath);

    final staged = _stagedPath(workspaceId);
    await Directory(_workspaces.dirFor(workspaceId)).create(recursive: true);
    // A crash during an earlier import leaves its copy behind.
    _removeStaged(staged);
    final StagedWorkspace prepared;
    try {
      await File(sourcePath).copy(staged);
      // A source still in WAL mode keeps committed rows in its log; without
      // it they would be lost.
      final sourceLog = '$sourcePath-wal';
      if (FileSystemEntity.typeSync(sourceLog, followLinks: false) ==
          FileSystemEntityType.file) {
        await File(sourceLog).copy('$staged-wal');
      }
      prepared = await prepareStagedWorkspace(
        stagedPath: staged,
        workspaceId: workspaceId,
        importedBy: importedBy,
        webhookSecrets: _webhookSecrets,
        now: _now(),
      );
      for (final route in prepared.routes) {
        final owner = await _global.workspaceRouteDao.resolve(
          route.kind,
          route.key,
        );
        if (owner != null && owner != workspaceId) {
          throw const WorkspaceImportRefusedException(
            WorkspaceImportRefusal.routeConflict,
            'A key in this file already belongs to another workspace',
          );
        }
      }
      syncFile(staged);
      if (_workspaces.existsOnDisk(workspaceId)) {
        await _preRestoreCopy(workspaceId);
      }
    } on Object {
      _removeStaged(staged);
      rethrow;
    }
    _report(workspaceId, prepared);

    final before = _workspaces.existsOnDisk(workspaceId)
        ? await _membershipsOf(workspaceId)
        : const <String, WorkspaceRole>{};
    await _swap(workspaceId, staged);
    await _global.transaction(() async {
      await _global.workspaceRouteDao.removeAllForWorkspace(workspaceId);
      for (final route in prepared.routes) {
        await _global.workspaceRouteDao.put(route.kind, route.key, workspaceId);
      }
    });
    _removeCodeIndex(workspaceId);
    await _open(workspaceId);
    _publishRestored(workspaceId, before, await _membershipsOf(workspaceId));
    // Subscribers run on the next turn; the caller's next request must not
    // be answered from a cache that has not heard yet.
    await Future<void>.delayed(Duration.zero);
  }

  void _report(String workspaceId, StagedWorkspace prepared) {
    if (prepared.recordedWorkspaceId != workspaceId) {
      _onWarn?.call(
        'importing workspace database that records workspace '
        '${prepared.recordedWorkspaceId} as workspace $workspaceId',
      );
    }
    if (prepared.heldCount > 0) {
      _onWarn?.call(
        'import of workspace $workspaceId held ${prepared.heldCount} '
        'grant(s) for the server owner to review',
      );
    }
  }

  /// Checks [sourcePath] against the SHA-256 the manifest beside it recorded
  /// (a snapshot's or a scoped backup's), when there is one. A truncated or
  /// altered copy is refused before anything is staged.
  Future<void> _verifyAgainstManifest(String sourcePath) async {
    final file = File(sourcePath).absolute;
    for (final dir in [file.parent, file.parent.parent]) {
      final record = SnapshotManifest.read(dir)?.recordFor(dir, file.path);
      if (record == null) {
        continue;
      }
      final path = file.path;
      final digest = await Isolate.run(
        () => backupFileDigest(File(path).openRead()),
      );
      if (digest != record.sha256) {
        throw const WorkspaceImportRefusedException(
          WorkspaceImportRefusal.checksumMismatch,
          'The file differs from the one the snapshot recorded',
        );
      }
      return;
    }
  }

  /// Puts the staged file in place of [workspaceId]'s live one.
  ///
  /// The live connection is closed through the manager, the old log
  /// removed, the staged file renamed over `workspace.db` and the directory
  /// synced, with nothing awaited between the removal and the sync. Nothing
  /// else in the directory is touched.
  Future<void> _swap(String workspaceId, String staged) async {
    await _workspaces.close(workspaceId);
    final live = _workspaces.pathFor(workspaceId);
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('$live$suffix');
      if (sidecar.existsSync()) {
        sidecar.deleteSync();
      }
    }
    File(staged).renameSync(live);
    syncDirectory(_workspaces.dirFor(workspaceId));
    // A request that reopened the workspace between the close and the rename
    // holds the replaced file; closing again (a no-op otherwise) makes it
    // reopen on the new one.
    await _workspaces.close(workspaceId);
  }

  /// Deletes the workspace's code index so it is rebuilt against the
  /// restored rows rather than describing the replaced ones.
  void _removeCodeIndex(String workspaceId) {
    final index =
        '${_workspaces.dirFor(workspaceId)}${Platform.pathSeparator}'
        '$codeIndexFileName';
    for (final suffix in const ['', '-wal', '-shm', '-journal']) {
      final file = File('$index$suffix');
      if (file.existsSync()) {
        file.deleteSync();
      }
    }
  }

  /// Every member of [workspaceId] and the preset their role resolves to, or
  /// null when the file cannot be read (or there is none).
  Future<Map<String, WorkspaceRole>?> _membershipsOf(String workspaceId) async {
    if (!_workspaces.existsOnDisk(workspaceId)) {
      return null;
    }
    try {
      final rows = await _workspaces
          .of(workspaceId)
          .customSelect(
            'SELECT m.user_id, m.role, r.base_preset FROM workspace_members m '
            "LEFT JOIN workspace_roles r ON m.role = 'custom:' || r.id",
          )
          .get();
      return {
        for (final row in rows)
          row.read<String>('user_id'):
              WorkspaceRole.fromWire(
                row.readNullable<String>('base_preset') ??
                    row.read<String>('role'),
              ) ??
              WorkspaceRole.guest,
      };
    } on Object {
      return null;
    }
  }

  /// Publishes [WorkspaceRestored], then the membership changes the restore
  /// made, so every listener that reacts to one (live subscriptions of a
  /// removed member, tokens minted for them, caches of their role) does.
  /// With [before] unknown every member counts as changed.
  void _publishRestored(
    String workspaceId,
    Map<String, WorkspaceRole>? before,
    Map<String, WorkspaceRole>? after,
  ) {
    final at = _now();
    _eventBus.publish(
      WorkspaceRestored(workspaceId: workspaceId, occurredAt: at),
    );
    final now = after ?? const <String, WorkspaceRole>{};
    for (final userId in before?.keys ?? const <String>[]) {
      if (!now.containsKey(userId)) {
        _eventBus.publish(
          WorkspaceMemberRemoved(
            workspaceId: workspaceId,
            userId: userId,
            occurredAt: at,
          ),
        );
      }
    }
    for (final MapEntry(key: userId, value: role) in now.entries) {
      final previous = before?[userId];
      if (before != null && !before.containsKey(userId)) {
        _eventBus.publish(
          WorkspaceMemberAdded(
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            occurredAt: at,
          ),
        );
      } else if (previous != role) {
        _eventBus.publish(
          WorkspaceMemberRoleChanged(
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            occurredAt: at,
          ),
        );
      }
    }
  }

  @override
  Future<List<ImportedAuthorityHold>> listImportHolds(
    String workspaceId,
  ) async {
    final rows = await ImportedAuthorityHoldDao(
      _workspaces.of(workspaceId),
    ).all();
    return [
      for (final row in rows)
        if (ImportHoldKind.fromWire(row.kind) case final kind?)
          ImportedAuthorityHold(
            id: row.id,
            kind: kind,
            payload: _decodePayload(row.payloadJson)..remove('code_hash'),
            importedAt: row.importedAt,
            sourceInstallId: row.sourceInstallId,
          ),
    ];
  }

  @override
  Future<bool> resolveImportHold({
    required String workspaceId,
    required String holdId,
    required bool accept,
  }) async {
    final db = _workspaces.of(workspaceId);
    final holds = ImportedAuthorityHoldDao(db);
    final hold = await holds.byId(holdId);
    final kind = hold == null ? null : ImportHoldKind.fromWire(hold.kind);
    if (hold == null || kind == null) {
      throw const NotFoundException('No such import hold');
    }
    if (!accept) {
      await holds.remove(holdId);
      return false;
    }
    final payload = _decodePayload(hold.payloadJson);
    if (kind == ImportHoldKind.invite) {
      final codeHash = payload['code_hash'];
      final owner = codeHash is String
          ? await _global.workspaceRouteDao.resolve(
              WorkspaceRouteKind.inviteCode,
              codeHash,
            )
          : null;
      if (codeHash is! String || (owner != null && owner != workspaceId)) {
        // Its code now belongs to another workspace: putting the route back
        // would take that workspace's invite.
        await holds.remove(holdId);
        return false;
      }
    }
    final applied = await db.transaction(() async {
      final applied = await _applyHold(db, workspaceId, kind, payload);
      await holds.remove(holdId);
      return applied;
    });
    if (!applied) {
      return false;
    }
    if (kind == ImportHoldKind.invite) {
      await _global.workspaceRouteDao.put(
        WorkspaceRouteKind.inviteCode,
        payload['code_hash']! as String,
        workspaceId,
      );
    }
    final at = _now();
    _eventBus.publish(
      ImportedAuthorityAccepted(
        workspaceId: workspaceId,
        kind: kind.wire,
        occurredAt: at,
      ),
    );
    if (kind == ImportHoldKind.membershipRole) {
      final userId = payload['user_id'];
      final role = (await _membershipsOf(workspaceId))?[userId];
      if (userId is String && role != null) {
        _eventBus.publish(
          WorkspaceMemberRoleChanged(
            workspaceId: workspaceId,
            userId: userId,
            role: role,
            occurredAt: at,
          ),
        );
      }
    }
    await Future<void>.delayed(Duration.zero);
    return true;
  }

  /// Writes an accepted hold back to its table. A role or grant level goes
  /// back onto the row it was taken from, which must still exist; a removed
  /// row is inserted again with the columns its table has today.
  static Future<bool> _applyHold(
    WorkspaceDatabase db,
    String workspaceId,
    ImportHoldKind kind,
    Map<String, Object?> payload,
  ) async {
    final table = holdTable(kind);
    final info = db.allTables.firstWhere((t) => t.actualTableName == table);
    switch (kind) {
      case ImportHoldKind.membershipRole:
      case ImportHoldKind.repoGrant:
        final column = kind == ImportHoldKind.membershipRole ? 'role' : 'level';
        final value = payload[column];
        final id = payload['id'];
        if (value is! String || id is! String) {
          return false;
        }
        return await db.customUpdate(
              'UPDATE $table SET $column = ? WHERE id = ?',
              variables: [Variable.withString(value), Variable.withString(id)],
              updates: {info},
            ) >
            0;
      case ImportHoldKind.actionPolicy:
      case ImportHoldKind.sandboxExecGrant:
      case ImportHoldKind.invite:
        final columns = {
          for (final row
              in await db.customSelect('PRAGMA table_info($table)').get())
            row.read<String>('name'),
        };
        final row = <String, Object?>{
          for (final entry in payload.entries)
            if (columns.contains(entry.key)) entry.key: entry.value,
          if (columns.contains('workspace_id')) 'workspace_id': workspaceId,
        };
        await db.customStatement(
          'INSERT OR REPLACE INTO $table '
          '(${row.keys.map((c) => '"$c"').join(', ')}) '
          'VALUES (${List.filled(row.length, '?').join(', ')})',
          row.values.toList(),
        );
        db.notifyUpdates({TableUpdate.onTable(info)});
        return true;
    }
  }

  static Map<String, Object?> _decodePayload(String json) {
    final decoded = jsonDecode(json);
    return decoded is Map<String, Object?> ? {...decoded} : {};
  }

  /// Filesystem-safe UTC timestamp (no ':' or '.' — invalid on Windows).
  String _timestamp() => _now()
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '-')
      .replaceAll('.', '-');
}
