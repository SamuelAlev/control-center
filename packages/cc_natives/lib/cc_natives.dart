/// Dart FFI surface for Control Center's runtime-loaded native libraries:
/// rift (copy-on-write git worktrees), fff (fast file search), tree-sitter
/// (code indexing), aec (acoustic echo cancellation) and pty (pseudo-terminal,
/// for the Flutter-free agent executor in the cc_server binary).
///
/// Bindings, loaders and path resolution only — this package builds NO native
/// code. The dylibs are produced by `scripts/natives/*.sh` and loaded at
/// runtime via `dart:ffi`, with graceful degradation when absent.
///
/// The host app injects its logging sink and on-disk path resolvers (see
/// `NativeLog` / `NativeDirResolver`) so this package stays a leaf with no
/// `package:control_center` dependency.
library;

export 'src/audio/aec/aec_ffi_bindings.dart';
export 'src/audio/aec/aec_processor.dart';
export 'src/code_index/code_graph_ids.dart';
export 'src/code_index/code_languages.dart';
export 'src/code_index/grammar_manager.dart';
export 'src/code_index/source_file_walker.dart';
export 'src/code_index/tree_sitter_bindings.dart';
export 'src/code_index/tree_sitter_loader.dart';
export 'src/code_index/tree_sitter_parser.dart';
export 'src/file_search/dart_file_search.dart';
export 'src/file_search/fff_file_search.dart';
export 'src/file_search/file_search.dart';
export 'src/inference/embedding/onnx_runtime_loader.dart';
export 'src/inference/embedding/text_embedder.dart';
export 'src/inference/speech/meeting_diarization_service.dart';
export 'src/inference/speech/meeting_offline_vad.dart';
export 'src/inference/speech/sherpa_bindings.dart';
export 'src/inference/speech/sherpa_onnx_transcriber.dart';
export 'src/inference/speech/silero_vad_detector.dart';
export 'src/native_library.dart';
export 'src/native_runtime.dart';
export 'src/pty/pty.dart';
export 'src/pty/pty_ffi_bindings.dart';
export 'src/rift/rift_client.dart';
export 'src/rift/rift_exception.dart';
export 'src/rift/rift_ffi_bindings.dart';
