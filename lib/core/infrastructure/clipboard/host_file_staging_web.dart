import 'dart:typed_data';

/// Whether files fetched out of a guest can be staged on this host.
///
/// False on web, and the callers say so rather than failing silently: a
/// browser tab has no filesystem, so there is nowhere to put a file for the
/// OS to pick up. Text and images still cross — those travel as VALUES on the
/// clipboard, which the web clipboard can carry.
const bool hostFileStagingAvailable = false;

/// Always empty on web. See [hostFileStagingAvailable].
Future<({Uri? directory, List<Uri> files})> stageFilesOnHost(
  List<({String name, Uint8List bytes})> files,
) async => (directory: null, files: const <Uri>[]);

/// Nothing to sweep on web.
Future<void> sweepStagedFiles() async {}
