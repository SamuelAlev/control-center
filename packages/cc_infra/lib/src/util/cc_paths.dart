import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;

/// Pure-Dart resolver for everything Control Center persists on disk, rooted at
/// an [appSupportRoot] the composition root supplies.
///
/// The desktop passes the `path_provider` app-support directory (resolved in
/// lib via `FontCachePathProvider`); a headless `cc_server` passes its own data
/// dir. Keeping the layout logic here — Flutter-free, parameterized by the root
/// — is the foundational unblocker for moving the dispatch / sandbox / relay /
/// repo cluster off lib, and lets the same on-disk layout serve both hosts.
///
/// Layout under [appSupportRoot]:
/// ```
/// <root>/
///   control_center.db    # drift database
///   mcp.json             # MCP client config
///   rift.sqlite          # rift CoW registry
///   models/              # on-device models (Whisper, embeddings)
///   grammars/            # tree-sitter runtime + grammar libs
///   pipelines/<runId>/   # per-pipeline-run working dir
///   meetings/<id>/       # retained per-channel audio
/// ```
class CcPaths {
  /// Creates a resolver rooted at [appSupportRoot] (an already app-scoped dir).
  const CcPaths(this.appSupportRoot);

  /// The app-scoped storage root (OS app-support dir on desktop; the server's
  /// data dir headless).
  final String appSupportRoot;

  Future<Directory> _ensure(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// The single root for everything Control Center persists.
  Future<Directory> root() => _ensure(appSupportRoot);

  /// Root for installable on-device models (Whisper, embedding models, etc.).
  Future<Directory> modelsRoot() => _ensure(p.join(appSupportRoot, 'models'));

  /// Root for installed tree-sitter native libraries used by the code indexer.
  Future<Directory> grammarsRoot() =>
      _ensure(p.join(appSupportRoot, 'grammars'));

  /// Per-pipeline-run working directory: `<root>/pipelines/<pipelineRunId>/`.
  Future<Directory> pipelineRunDir(String pipelineRunId) =>
      _ensure(p.join(appSupportRoot, 'pipelines', pipelineRunId));

  /// Per-meeting working directory: `<root>/meetings/<meetingId>/`.
  Future<Directory> meetingAudioDir(String meetingId) =>
      _ensure(p.join(appSupportRoot, 'meetings', meetingId));

  /// Path to the SQLite database file used by drift.
  Future<File> databaseFile() async {
    await root();
    return File(p.join(appSupportRoot, 'control_center.db'));
  }

  /// Path to the MCP client config file at the app data root.
  Future<File> mcpConfigFile() async {
    await root();
    return File(p.join(appSupportRoot, 'mcp.json'));
  }

  /// Path to the rift copy-on-write registry database shared by all worktrees.
  String riftRegistryPath() => p.join(appSupportRoot, 'rift.sqlite');

  /// Candidate absolute paths for the bundled rift FFI shared library.
  List<String> riftDylibCandidatePaths() => nativeLibraryCandidates(
        'rift_ffi',
        appSupportRoot: appSupportRoot,
        envVar: 'RIFT_FFI_DYLIB',
      );

  /// Candidate absolute paths for the bundled echo-cancellation FFI library.
  List<String> aecFfiDylibCandidatePaths() => nativeLibraryCandidates(
        'aec_ffi',
        appSupportRoot: appSupportRoot,
        envVar: 'AEC_FFI_DYLIB',
      );
}
