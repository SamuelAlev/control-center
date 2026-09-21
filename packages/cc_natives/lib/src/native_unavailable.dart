/// Marker: a required native library could not be loaded.
///
/// No degraded mode — missing dylib means broken install / unbuilt tree.
/// `cc_server` preflight refuses to boot. Not used for environment fallbacks:
/// embedding model not downloaded → FTS-only; Windows rift backend is
/// `git worktree` (CoW is sole elsewhere). Implementors: Fff/Pty/TreeSitter/
/// Watcher/Aec/LameUnavailable; rift via `RiftException.isUnavailable`.
library;

/// See the library doc: a required native library could not be loaded.
abstract interface class NativeLibraryUnavailable implements Exception {
  /// Human-readable detail, including the remediation (which build script to
  /// run, or that the host bundle needs rebuilding).
  String get message;
}
