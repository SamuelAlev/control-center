import 'dart:ffi';

/// Base name of the native watcher library (`libcc_watcher.dylib` /
/// `libcc_watcher.so` / `cc_watcher.dll`), built by
/// `scripts/natives/build_watcher.sh` from the in-repo Rust crate
/// `packages/cc_natives/native/watcher/`.
const String watcherLibraryBaseName = 'cc_watcher';

/// Env var overriding the watcher dylib path (highest-priority candidate).
const String watcherLibraryEnvVar = 'CC_WATCHER_DYLIB';

/// The C ABI version this Dart binding speaks. Must equal the native's
/// `cc_watch_abi_version()`; a mismatch refuses to bind — and therefore fails
/// loudly — rather than misreading structs.
const int ccWatcherAbiVersion = 1;

/// `CC_WATCH_FLAG_RESCAN`: something under the root changed, paths unknown.
const int ccWatchFlagRescan = 1;

/// `CC_WATCH_FLAG_ROOT_GONE`: the watched root vanished; the handle is dead.
const int ccWatchFlagRootGone = 2;

/// `CC_WATCH_FLAG_DEGRADED`: watch budget / ENOSPC — coverage is partial.
const int ccWatchFlagDegraded = 4;

/// Mirror of the native `CcWatchDrain` out-struct (see `cc_watcher.h`).
///
/// [buf] is a NUL-separated UTF-8 path list OWNED BY THE HANDLE and reused:
/// it is valid only until the next `cc_watch_drain`/`cc_watch_destroy` on the
/// same handle, so callers must copy (a `utf8.decode` does) before returning.
final class CcWatchDrain extends Struct {
  /// NUL-separated UTF-8 absolute paths.
  external Pointer<Uint8> buf;

  /// Byte length of [buf].
  @UintPtr()
  external int len;

  /// Bitmask of `ccWatchFlag*`.
  @Uint32()
  external int flags;

  /// Paths discarded (queue overflow) since the last drain.
  @Uint32()
  external int dropped;

  /// Live OS watches (Linux: watched dirs; macOS/Windows: 1).
  @Uint32()
  external int watchCount;
}

/// Dart signature of `cc_watch_create`.
typedef CcWatchCreate =
    Pointer<Void> Function(
      Pointer<Uint8> rootUtf8,
      Pointer<Uint8> ignoreDirsUtf8,
      int queueCap,
      int maxWatches,
    );

/// Dart signature of `cc_watch_drain`.
typedef CcWatchDrainFn = int Function(Pointer<Void> w, Pointer<CcWatchDrain> out);

/// Dart signature of `cc_watch_destroy`.
typedef CcWatchDestroy = void Function(Pointer<Void> w);

/// Dart signature of `cc_watch_last_error`.
typedef CcWatchLastError = Pointer<Uint8> Function();

/// Typed bindings over the `cc_watcher` dylib.
class CcWatcherBindings {
  CcWatcherBindings._({
    required this.create,
    required this.drain,
    required this.destroy,
    required this.lastError,
  });

  /// `cc_watch_create` — never blocks; returns NULL on failure (see
  /// [lastError]).
  final CcWatchCreate create;

  /// `cc_watch_drain` — 1 = payload/flags present, 0 = idle. NOT a leaf call:
  /// it takes the native queue mutex.
  final CcWatchDrainFn drain;

  /// `cc_watch_destroy` — joins the watcher thread; NULL-safe.
  final CcWatchDestroy destroy;

  /// `cc_watch_last_error` — thread-local message; NULL pointer when none.
  final CcWatchLastError lastError;

  /// Binds against [lib], or returns null when a symbol is missing or the
  /// native speaks a different ABI version. Null surfaces to the caller as
  /// `WatcherUnavailable` — a broken install, not a degraded mode.
  static CcWatcherBindings? tryFrom(DynamicLibrary lib) {
    try {
      final abiVersion = lib.lookupFunction<Uint32 Function(), int Function()>(
        'cc_watch_abi_version',
      );
      if (abiVersion() != ccWatcherAbiVersion) {
        return null;
      }
      return CcWatcherBindings._(
        create: lib.lookupFunction<Pointer<Void> Function(Pointer<Uint8>, Pointer<Uint8>, Uint32, Uint32), CcWatchCreate>('cc_watch_create'),
        drain: lib.lookupFunction<Int32 Function(Pointer<Void>, Pointer<CcWatchDrain>), CcWatchDrainFn>('cc_watch_drain'),
        destroy: lib.lookupFunction<Void Function(Pointer<Void>), CcWatchDestroy>(
          'cc_watch_destroy',
        ),
        lastError: lib.lookupFunction<Pointer<Uint8> Function(), CcWatchLastError>(
          'cc_watch_last_error',
        ),
      );
    } on ArgumentError {
      // Missing symbol — an unrelated or truncated dylib.
      return null;
    }
  }
}
