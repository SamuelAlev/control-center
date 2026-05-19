import 'dart:io';

import 'package:cc_infra/src/util/cc_paths.dart';
import 'package:control_center/core/storage/font_cache_path_provider.dart';

/// Single root for everything Control Center persists on disk.
///
/// The on-disk layout logic now lives in cc_infra's [CcPaths] (Flutter-free, so
/// the headless server reuses it with its own root). lib supplies the
/// device-resolved app-support base via [FontCachePathProvider] and re-exposes
/// the legacy free-function API below so existing call sites are unchanged.
///
/// Layout under the root (see [CcPaths]): `control_center.db`, `mcp.json`,
/// `rift.sqlite`, `models/`, `grammars/`, `pipelines/<runId>/`,
/// `meetings/<id>/`, plus per-workspace agent/skill dirs.
CcPaths get _paths => CcPaths(FontCachePathProvider.realAppSupportDir.path);

/// The app's [CcPaths] resolver, rooted at the device app-support dir. Inject
/// this into Flutter-free services (e.g. `WorkspaceFilesystemService`) so they
/// reuse the same on-disk layout without reaching for `path_provider`.
CcPaths get appCcPaths => _paths;

/// The app-scoped storage root.
Future<Directory> controlCenterRootDir() => _paths.root();

/// Root for installable on-device models (Whisper, embedding models, etc.).
Future<Directory> modelsRootDir() => _paths.modelsRoot();

/// Root for installed tree-sitter native libraries used by the code indexer.
Future<Directory> grammarsRootDir() => _paths.grammarsRoot();

/// Per-pipeline-run working directory: `<root>/pipelines/<pipelineRunId>/`.
Future<Directory> pipelineRunDir(String pipelineRunId) =>
    _paths.pipelineRunDir(pipelineRunId);

/// Per-meeting working directory: `<root>/meetings/<meetingId>/`.
Future<Directory> meetingAudioDir(String meetingId) =>
    _paths.meetingAudioDir(meetingId);

/// Deprecated: use [modelsRootDir] instead.
@Deprecated('Use modelsRootDir()')
Future<Directory> voiceModelsRootDir() => modelsRootDir();

/// Path to the SQLite database file used by drift.
Future<File> controlCenterDatabaseFile() => _paths.databaseFile();

/// Path to the rift copy-on-write registry database shared by managed worktrees.
String riftRegistryPath() => _paths.riftRegistryPath();

/// Candidate absolute paths for the bundled rift FFI shared library.
List<String> riftDylibCandidatePaths() => _paths.riftDylibCandidatePaths();

/// Candidate absolute paths for the bundled echo-cancellation FFI library.
List<String> aecFfiDylibCandidatePaths() => _paths.aecFfiDylibCandidatePaths();

/// Path to the MCP client config file at the app data root.
Future<File> mcpConfigFile() => _paths.mcpConfigFile();
