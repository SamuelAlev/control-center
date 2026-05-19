import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/storage/font_cache_path_provider.dart';
import 'package:path/path.dart' as p;

/// Single root for everything Control Center persists on disk.
///
/// Resolves to the OS-recommended per-app storage directory:
/// - macOS:   `~/Library/Application Support/<bundle-id>/`
/// - Linux:   `$XDG_DATA_HOME/control_center/` (typically `~/.local/share/control_center/`)
/// - Windows: `%APPDATA%\control_center\`
/// - iOS/Android: the platform's app-private application-support directory.
///
/// The returned directory is already app-scoped, so we don't wrap it in an
/// extra `control_center/` folder.
///
/// Layout under this root:
/// ```
/// <root>/
///   control_center.db         # drift database (see core/database/app_database.dart)
///   mcp.json                  # MCP client config for connecting back to the control center
///   fonts/                    # google_fonts cache (see core/storage/font_cache_path_provider.dart)
///     manrope_<hash>.ttf
///     jetbrainsmono_<hash>.ttf
///   <workspace-id-1>/
///     agents/<slug>/
///       AGENTS.md
///       .mcp.json             # symlink → ../../../mcp.json
///     skills/<slug>/SKILL.md
///   <workspace-id-2>/...
///   models/
///     sherpa-onnx-whisper-base.en/
///       base.en-encoder.int8.onnx
///       base.en-decoder.int8.onnx
///       base.en-tokens.txt
///     arctic-embed-xs/
///       model.onnx
///       vocab.txt
/// ```
///
/// Reads from [FontCachePathProvider.realAppSupportDir] — we don't call
/// `getApplicationSupportDirectory()` directly because that's been
/// redirected to `<root>/fonts/` to keep google_fonts' cache out of the
/// root directory listing.
Future<Directory> controlCenterRootDir() async {
  final dir = FontCachePathProvider.realAppSupportDir;
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Root for installable on-device models (Whisper, embedding models, etc.).
Future<Directory> modelsRootDir() async {
  final root = await controlCenterRootDir();
  final dir = Directory(p.join(root.path, 'models'));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Root for installed tree-sitter native libraries (the `libtree-sitter`
/// runtime + per-language grammar libs) used by the code indexer. Mirrors
/// [modelsRootDir]; the build script (`scripts/natives/build_tree_sitter.sh`) or
/// `GrammarManager` populates `<root>/grammars/`.
Future<Directory> grammarsRootDir() async {
  final root = await controlCenterRootDir();
  final dir = Directory(p.join(root.path, 'grammars'));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Per-pipeline-run working directory: `<root>/pipelines/<pipelineRunId>/`.
///
/// All agentless bash steps in a run share this directory as their cwd, and the
/// `pipeline.condition` body resolves relative file-existence checks against it
/// (or against a `repoLocalPath` clone underneath it). Created on first access.
Future<Directory> pipelineRunDir(String pipelineRunId) async {
  final root = await controlCenterRootDir();
  final dir = Directory(p.join(root.path, 'pipelines', pipelineRunId));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Per-meeting working directory: `<root>/meetings/<meetingId>/`. Holds the
/// retained per-channel audio (`me.wav`, `them.wav`) used by the offline
/// diarization step. Created on first access.
Future<Directory> meetingAudioDir(String meetingId) async {
  final root = await controlCenterRootDir();
  final dir = Directory(p.join(root.path, 'meetings', meetingId));
  if (!dir.existsSync()) {
    await dir.create(recursive: true);
  }
  return dir;
}

/// Deprecated: use [modelsRootDir] instead.
@Deprecated('Use modelsRootDir()')
Future<Directory> voiceModelsRootDir() => modelsRootDir();

/// Path to the SQLite database file used by drift.
Future<File> controlCenterDatabaseFile() async {
  final root = await controlCenterRootDir();
  return File(p.join(root.path, 'control_center.db'));
}

/// Path to the rift copy-on-write registry database, shared by all managed
/// worktrees (separate from rift's CLI default location).
String riftRegistryPath() =>
    p.join(FontCachePathProvider.realAppSupportDir.path, 'rift.sqlite');

/// Candidate absolute paths for the bundled rift FFI shared library. Injects
/// this app's app-support root and the `RIFT_FFI_DYLIB` env override into the
/// shared resolution policy (`nativeLibraryCandidates` in package:cc_natives),
/// which appends the release-bundle defaults. The app degrades to a plain
/// `git worktree` when none resolve.
List<String> riftDylibCandidatePaths() => nativeLibraryCandidates(
      'rift_ffi',
      appSupportRoot: FontCachePathProvider.realAppSupportDir.path,
      envVar: 'RIFT_FFI_DYLIB',
    );

/// Candidate absolute paths for the bundled acoustic-echo-cancellation FFI
/// shared library (`libaec_ffi`). Injects this app's app-support root and the
/// `AEC_FFI_DYLIB` env override into the shared resolution policy
/// (`nativeLibraryCandidates` in package:cc_natives), which appends the
/// release-bundle defaults. The app degrades to the text echo filter when none
/// resolve.
List<String> aecFfiDylibCandidatePaths() => nativeLibraryCandidates(
      'aec_ffi',
      appSupportRoot: FontCachePathProvider.realAppSupportDir.path,
      envVar: 'AEC_FFI_DYLIB',
    );

/// Path to the MCP client config file at the app data root.
///
/// This file tells MCP clients (e.g., Claude Code running in an agent worktree)
/// how to connect back to the Control Center's MCP server.
Future<File> mcpConfigFile() async {
  final root = await controlCenterRootDir();
  return File(p.join(root.path, 'mcp.json'));
}
