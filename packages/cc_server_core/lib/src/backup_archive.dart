import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

/// Packs a backup snapshot directory into a single zip for download.
///
/// A snapshot is a set of files — `manifest.json`, `global.db` and one
/// `<workspaceId>/workspace.db` per workspace — and an HTTP response carries
/// one body. Without this, "download the backup" would mean downloading its
/// pieces one at a time and reassembling the layout by hand, which is the part
/// a restore depends on being exactly right.
///
/// Zip rather than tar because the destination is a person's Downloads folder:
/// macOS, Windows and every Linux desktop open a zip on double-click, and the
/// entry paths are relative to the snapshot directory so unpacking reproduces
/// the layout the data directory expects.
///
/// Written to a FILE rather than built in memory. A snapshot is the whole
/// install; buffering one would put every workspace's database in the server's
/// heap at once, which is the same mistake the embedding pass made before it
/// moved off the main isolate. The caller owns the returned file and is
/// expected to delete it once it has been streamed.
class BackupSnapshotArchiveBuilder {
  /// Creates a builder writing archives into [stagingDir].
  const BackupSnapshotArchiveBuilder({required this.stagingDir});

  /// Where the transient archive is written. It is the caller's job to delete
  /// what lands here; nothing else sweeps it.
  final String stagingDir;

  /// Zips [snapshot] and returns the archive, or null when [snapshot] is not a
  /// directory (a snapshot that was removed between listing and download).
  ///
  /// [name] names the archive and is assumed to be a snapshot directory name —
  /// a timestamp. The caller resolves it against the backup listing rather than
  /// letting it reach a path: this method never joins a caller-supplied string
  /// onto a root, so there is nothing here to traverse out of.
  Future<File?> build({required Directory snapshot, required String name}) async {
    if (!snapshot.existsSync()) {
      return null;
    }
    final dir = Directory(stagingDir);
    await dir.create(recursive: true);
    final target = File(p.join(dir.path, '$name.zip'));
    // A previous run that died mid-stream could have left one; ZipFileEncoder
    // would happily append to it and produce an archive with every file twice.
    if (target.existsSync()) {
      target.deleteSync();
    }

    final encoder = ZipFileEncoder();
    encoder.create(target.path);
    try {
      // Entries are relative to the snapshot directory, so unpacking yields
      // `manifest.json` + `global.db` + `<id>/workspace.db` — the same shape as
      // the live data directory, which is what makes a restore a copy back.
      for (final entity in snapshot.listSync(followLinks: false)..sort(_byPath)) {
        if (entity is File) {
          await encoder.addFile(entity, p.basename(entity.path));
        } else if (entity is Directory) {
          await encoder.addDirectory(entity);
        }
      }
    } on Object {
      await encoder.close();
      if (target.existsSync()) {
        target.deleteSync();
      }
      rethrow;
    }
    await encoder.close();
    return target;
  }

  /// Stable entry order, so two archives of the same snapshot are the same
  /// archive. `listSync` order is filesystem order, which is not.
  static int _byPath(FileSystemEntity a, FileSystemEntity b) =>
      a.path.compareTo(b.path);
}
