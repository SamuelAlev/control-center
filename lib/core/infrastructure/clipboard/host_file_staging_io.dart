import 'dart:io';
import 'dart:typed_data';

import 'package:control_center/core/utils/app_log.dart';
import 'package:path/path.dart' as p;

/// Whether files fetched out of a guest can be staged on this host.
const bool hostFileStagingAvailable = true;

/// The scratch directory every staged file lands in.
///
/// One fixed directory rather than a fresh temp dir per transfer, so
/// [sweepStagedFiles] has somewhere to sweep. Under the system temp root,
/// because the OS already clears that and these files are copies — the
/// original is still in the machine they came out of.
Directory _stagingRoot() =>
    Directory(p.join(Directory.systemTemp.path, 'cc-rig-out'));

/// Writes [files] into the host's scratch directory and returns their URIs,
/// plus the directory holding them.
///
/// The URIs are what actually crosses to Finder/Explorer: an OS drag or a file
/// paste carries paths, never bytes, so a file coming out of a guest has to
/// exist on this side first.
///
/// The DIRECTORY is returned as well because a native drag carries exactly one
/// item, and dragging a folder is how several files leave a machine in one
/// gesture without the caller having to pick one and drop the rest.
///
/// Names collide (two `screenshot.png` out of the same machine), so each
/// transfer gets its own subdirectory. That keeps the LEAF name intact —
/// which is what the user sees after the drop — instead of renaming the file
/// to `screenshot-2.png` on the way out.
Future<({Uri? directory, List<Uri> files})> stageFilesOnHost(
  List<({String name, Uint8List bytes})> files,
) async {
  if (files.isEmpty) {
    return (directory: null, files: const <Uri>[]);
  }
  final uris = <Uri>[];
  Uri? directory;
  try {
    final root = _stagingRoot();
    await root.create(recursive: true);
    final dir = await root.createTemp('drop-');
    directory = dir.uri;
    for (final file in files) {
      // Re-sanitized here even though the server already did: this name is
      // about to become a path on the USER's machine, and a `../` in it would
      // write outside the scratch directory. Cheap, and the alternative is
      // trusting a name that came out of a VM.
      final leaf = p.basename(file.name.replaceAll(r'\', '/'));
      final safe = leaf.isEmpty || leaf == '.' || leaf == '..'
          ? 'file-from-machine'
          : leaf;
      final target = File(p.join(dir.path, safe));
      await target.writeAsBytes(file.bytes, flush: true);
      uris.add(target.uri);
    }
  } on Object catch (e) {
    AppLog.d('rig-transfer', 'staging files on the host failed: $e');
    // Partial results are still usable — a two-file drag that staged one file
    // carries one file rather than nothing.
  }
  return (directory: directory, files: uris);
}

/// Deletes staged copies older than an hour.
///
/// Best-effort housekeeping, not a guarantee: a drag hands the OS a path and
/// there is no completion callback that says the receiver has finished
/// reading it, so a staged file cannot be deleted when the drag ends. An hour
/// is far longer than any drop takes and far shorter than a session.
Future<void> sweepStagedFiles() async {
  try {
    final root = _stagingRoot();
    if (!root.existsSync()) {
      return;
    }
    final cutoff = DateTime.now().subtract(const Duration(hours: 1));
    for (final entry in root.listSync(followLinks: false)) {
      // statSync, not stat: `avoid_slow_async_io` is right here — the async
      // form spawns work on the IO pool for a metadata read that resolves off
      // the page cache, and this loop runs over a handful of directories.
      if (entry.statSync().modified.isBefore(cutoff)) {
        entry.deleteSync(recursive: true);
      }
    }
  } on Object catch (e) {
    AppLog.d('rig-transfer', 'sweeping staged files failed: $e');
  }
}
