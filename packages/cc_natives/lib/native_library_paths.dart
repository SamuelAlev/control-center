/// Standalone, FFI-free re-export of the on-disk path policy.
///
/// `package:cc_natives/cc_natives.dart` is the FFI barrel (it re-exports the
/// tree-sitter / rift / pty / aec bindings that import `dart:ffi`), so importing
/// it from web-reachable code breaks `flutter build web`. This library exposes
/// ONLY `native_library_paths.dart` — which deliberately imports no `dart:ffi`
/// — so consumers that need just the path layout (e.g. cc_infra's path resolver)
/// can depend on a stable public entry point without dragging the FFI subtree.
library;

export 'src/native_library_paths.dart';
