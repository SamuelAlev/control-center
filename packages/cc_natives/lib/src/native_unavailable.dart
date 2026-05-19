/// Marker for "a required native library could not be loaded".
///
/// There is no degraded mode. Every native ships INSIDE the host bundle
/// (`apps/cc_server/hook/build.dart` emits them as `DynamicLoadingBundled` code
/// assets; the desktop packagers copy them into `Frameworks`/`lib`), so a load
/// failure means a broken install or an unbuilt dev tree — never a runtime
/// condition a user can hit on a healthy machine. Callers must let these
/// propagate; `cc_server` additionally refuses to boot when its preflight
/// (`native_preflight.dart`) cannot resolve one.
///
/// Deliberately NOT thrown for environment-driven conditions, which keep their
/// documented fallbacks:
///   * a filesystem without copy-on-write support (`RiftException.isCowUnavailable`
///     → plain `git worktree`),
///   * an on-device model that has not been downloaded yet
///     (`EmbeddingService.isReady` → FTS-only search).
///
/// Implementors: `FffUnavailable`, `PtyUnavailable`, `TreeSitterUnavailable`,
/// `WatcherUnavailable`, `AecUnavailable`, `LameUnavailable`. rift signals the
/// same condition through `RiftException.isUnavailable` (its FFI surface is
/// already error-code based).
library;

/// See the library doc: a required native library could not be loaded.
abstract interface class NativeLibraryUnavailable implements Exception {
  /// Human-readable detail, including the remediation (which build script to
  /// run, or that the host bundle needs rebuilding).
  String get message;
}
