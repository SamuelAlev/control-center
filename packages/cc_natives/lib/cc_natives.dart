/// @docImport 'src/native_runtime.dart';
/// @docImport 'src/native_unavailable.dart';
/// Dart FFI surface for runtime-loaded natives: rift, fff, tree-sitter,
/// cc_watcher, aec, lame, pty, cc_inference, cc_saml.
///
/// Bindings/loaders only — dylibs from `scripts/natives/*.sh`, bundled as
/// `DynamicLoadingBundled` assets. Missing native = hard failure
/// ([NativeLibraryUnavailable]); no degraded mode. Environment-only
/// fallbacks: embedding model not downloaded → FTS-only; Windows still uses
/// `git worktree` as the rift backend (CoW is sole elsewhere). Host injects
/// [NativeLog] / [NativeDirResolver].
library;

export 'src/audio/aec/aec_ffi_bindings.dart';
export 'src/audio/aec/aec_processor.dart';
export 'src/audio/lame/lame_ffi_bindings.dart';
export 'src/audio/lame/mp3_encoder.dart';
export 'src/code_index/ast_node.dart';
export 'src/code_index/ast_pattern.dart';
export 'src/code_index/ast_pattern_compiler.dart';
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
export 'src/saml/saml_ffi_bindings.dart';
export 'src/saml/saml_library.dart';
export 'src/watch/directory_change_watcher.dart';
export 'src/watch/native_directory_watcher.dart';
export 'src/watch/watcher_ffi_bindings.dart';
