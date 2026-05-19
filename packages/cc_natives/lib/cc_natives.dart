/// Dart FFI surface for Control Center's runtime-loaded native libraries:
/// rift (copy-on-write git worktrees), fff (fast file search), tree-sitter +
/// its grammars (code indexing), cc_watcher (file watching), aec (acoustic echo
/// cancellation), lame (MP3 encoding), pty (pseudo-terminal, for the
/// Flutter-free agent executor in the cc_server binary), and the inference
/// runtimes (onnxruntime, sherpa-onnx).
///
/// Bindings, loaders and path resolution only — this package builds NO native
/// code. The dylibs are produced by `scripts/natives/*.sh`, bundled into the
/// host binary as `DynamicLoadingBundled` code assets (see
/// `apps/cc_server/hook/build.dart`), and loaded at runtime via `dart:ffi`.
///
/// A missing native is a HARD failure — there is no degraded mode. Loaders
/// throw a `NativeLibraryUnavailable` (rift signals it via
/// `RiftException.isUnavailable`), and `cc_server` refuses to boot when its
/// native preflight cannot resolve one. The only fallbacks that remain are
/// environment-driven, never build-driven: a filesystem without copy-on-write
/// support falls back to `git worktree`, and semantic search degrades to
/// FTS-only until the on-device embedding MODEL is downloaded.
///
/// The host app injects its logging sink and on-disk path resolvers (see
/// `NativeLog` / `NativeDirResolver`) so this package stays a leaf with no
/// `package:control_center` dependency.
library;

export 'src/audio/aec/aec_ffi_bindings.dart';
export 'src/audio/aec/aec_processor.dart';
export 'src/audio/lame/lame_ffi_bindings.dart';
export 'src/audio/lame/mp3_encoder.dart';
export 'src/code_index/code_graph_ids.dart';
export 'src/code_index/code_languages.dart';
export 'src/code_index/embedded_queries.dart';
export 'src/code_index/grammar_manager.dart';
export 'src/code_index/repo_state_probe.dart';
export 'src/code_index/source_file_walker.dart';
export 'src/code_index/tree_sitter_bindings.dart';
export 'src/code_index/tree_sitter_loader.dart';
export 'src/code_index/tree_sitter_parser.dart';
export 'src/file_search/dart_file_search.dart';
export 'src/file_search/fff_file_search.dart';
export 'src/file_search/file_search.dart';
export 'src/inference/cc_inference_bindings.dart';
export 'src/inference/embedding/text_embedder.dart';
export 'src/inference/embedding/text_embedder_worker.dart';
export 'src/inference/inference_library.dart';
export 'src/inference/speech/meeting_diarization_service.dart';
export 'src/inference/speech/meeting_offline_vad.dart';
export 'src/inference/speech/sherpa_onnx_transcriber.dart';
export 'src/inference/speech/silero_vad_detector.dart';
export 'src/native_library.dart';
export 'src/native_runtime.dart';
export 'src/native_unavailable.dart';
export 'src/pty/pty.dart';
export 'src/pty/pty_ffi_bindings.dart';
export 'src/rift/rift_client.dart';
export 'src/rift/rift_exception.dart';
export 'src/rift/rift_ffi_bindings.dart';
export 'src/watch/directory_change_watcher.dart';
export 'src/watch/native_directory_watcher.dart';
export 'src/watch/watcher_ffi_bindings.dart';
