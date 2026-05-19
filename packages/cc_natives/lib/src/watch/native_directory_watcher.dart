import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/native_runtime.dart' show NativeLog;
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:cc_natives/src/watch/directory_change_watcher.dart';
import 'package:cc_natives/src/watch/watcher_ffi_bindings.dart';
import 'package:ffi/ffi.dart';

/// Resolves the `cc_watcher` dynamic library; null when unavailable.
typedef WatcherLibraryResolver = DynamicLibrary? Function();

/// Thrown when the `libcc_watcher` dylib itself cannot be used: absent, wrong
/// arch, or ABI-mismatched.
///
/// Strictly a BROKEN INSTALL. A *per-root* create failure (the native refused
/// one directory — it vanished mid-arm, inotify limits, ENOSPC) is a
/// [StateError] instead, so a consumer arming many checkouts can catch and retry
/// the one bad root while still letting a broken install propagate.
///
/// There is NO degraded mode. `package:watcher`'s alternative scans the whole
/// tree per checkout and cannot skip `node_modules`/`build` — measured, that
/// froze the server isolate for 65 seconds across 4 repos + 72 worktrees, so a
/// silent fallback to it is worse than a loud failure. The dylib ships inside
/// the host bundle and `cc_server` refuses to boot without it (the native
/// preflight), so hitting this means a broken install. See
/// [NativeLibraryUnavailable].
class WatcherUnavailable implements NativeLibraryUnavailable {
  /// Creates a [WatcherUnavailable].
  const WatcherUnavailable(this.message);

  /// What failed, including the native's own error when it supplied one.
  @override
  final String message;

  @override
  String toString() =>
      'WatcherUnavailable: $message (build it with '
      'scripts/natives/build_watcher.sh, or set \$$watcherLibraryEnvVar)';
}

/// Default `libcc_watcher` resolution: env override → bundle candidates. The
/// host installs a richer resolver (with its app-support root) via
/// [NativeDirectoryWatcher.libraryResolver] — same shape as `Pty`.
DynamicLibrary? defaultWatcherLibraryResolver() => tryOpenFirst(
  nativeLibraryCandidates(watcherLibraryBaseName, envVar: watcherLibraryEnvVar),
);

/// [DirectoryChangeWatcher] over the native `cc_watcher` library — recursive
/// FSEvents (macOS) / ReadDirectoryChangesW (Windows) / ignore-aware inotify
/// (Linux) watching with NO full-tree scan on any Dart isolate.
///
/// `package:watcher`'s `DirectoryWatcher` performs a full recursive scan of
/// the tree on construction and cannot skip `node_modules`/`build`; arming a
/// realistic worktree fleet with it froze the server isolate for a measured
/// 65 seconds. The native watches kernel-recursively (or installs its Linux
/// per-dir watches on its own thread) and applies the ignore list at the
/// source, so [create] is O(1) for the caller.
///
/// Event delivery is a POLLING DRAIN: one process-wide timer
/// ([pumpInterval], default 500 ms) drains every live handle. The consumer
/// debounces changes for 2 s anyway, a drain is inherently coalescing, and
/// polling avoids vendoring `dart_api_dl` into the Rust crate for a latency
/// nobody consumes.
class NativeDirectoryWatcher implements DirectoryChangeWatcher {
  NativeDirectoryWatcher._(this._bindings, this._handle, this.root, this._log);

  /// Host-overridable resolver, set once at startup (the `Pty` pattern).
  static WatcherLibraryResolver libraryResolver = defaultWatcherLibraryResolver;

  /// How often the shared pump drains live handles. Configurable for tests.
  static Duration pumpInterval = const Duration(milliseconds: 500);

  static CcWatcherBindings? _cachedBindings;
  static bool _probed = false;

  static CcWatcherBindings? _ensureBindings() {
    if (_probed) {
      return _cachedBindings;
    }
    _probed = true;
    final lib = libraryResolver();
    if (lib == null) {
      return null;
    }
    return _cachedBindings = CcWatcherBindings.tryFrom(lib);
  }

  /// Resets the cached bindings so a changed [libraryResolver] is re-probed
  /// (tests only).
  static void debugResetBindings() {
    _cachedBindings = null;
    _probed = false;
  }

  /// Whether the native watcher can be used in this process (cheap; caches
  /// the bindings). False means a broken install — `cc_server`'s native
  /// preflight refuses to boot on it.
  static bool get isAvailable => _ensureBindings() != null;

  /// Creates a native watch on [root].
  ///
  /// Throws [WatcherUnavailable] when the dylib cannot be loaded (a broken
  /// install — callers must let it propagate), or a [StateError] when the native
  /// refuses this particular [root] (vanished mid-arm, watch-descriptor limits):
  /// that one is per-root and operational, so a caller arming many checkouts
  /// should catch it and retry that root later.
  ///
  /// Synchronous by design: the arm path in the watch service is synchronous,
  /// and the native `cc_watch_create` never blocks (the Linux watch-install
  /// walk runs on the native thread).
  ///
  /// [ignoreDirNames] are directory NAMES whose subtrees are never watched
  /// or reported (feed `SourceFileWalker.watchIgnoredDirs`). [queueCapacity]
  /// bounds distinct pending paths before the native degrades to a
  /// rescan-needed signal; [maxWatches] bounds Linux inotify watches
  /// (0 = unlimited).
  static NativeDirectoryWatcher create(
    String root, {
    required Set<String> ignoreDirNames,
    int queueCapacity = 4096,
    int maxWatches = 20000,
    NativeLog? onLog,
  }) {
    final bindings = _ensureBindings();
    if (bindings == null) {
      throw const WatcherUnavailable('libcc_watcher could not be loaded');
    }
    final rootPtr = root.toNativeUtf8();
    final ignorePtr = ignoreDirNames.join('\n').toNativeUtf8();
    Pointer<Void> handle;
    try {
      handle = bindings.create(
        rootPtr.cast<Uint8>(),
        ignorePtr.cast<Uint8>(),
        queueCapacity,
        maxWatches,
      );
    } finally {
      malloc.free(rootPtr);
      malloc.free(ignorePtr);
    }
    if (handle == nullptr) {
      final err = bindings.lastError();
      // Per-root refusal, NOT a dylib problem — the library loaded fine. Kept a
      // StateError so consumers can retry this root without also swallowing the
      // broken-install signal above.
      throw StateError(
        'cc_watch_create failed for $root: '
        '${err == nullptr ? 'unknown error' : err.cast<Utf8>().toDartString()}',
      );
    }
    final watcher = NativeDirectoryWatcher._(bindings, handle, root, onLog);
    _WatchPump.instance.register(watcher);
    return watcher;
  }

  final CcWatcherBindings _bindings;
  final Pointer<Void> _handle;
  final NativeLog? _log;

  /// The watched root, as requested (native paths are rewritten back to this
  /// prefix — FSEvents canonicalizes `/var/...` to `/private/var/...`).
  final String root;

  final StreamController<DirectoryChangeBatch> _controller =
      StreamController<DirectoryChangeBatch>();
  bool _closed = false;
  bool _warnedDegraded = false;

  static final String _nul = String.fromCharCode(0);

  @override
  Stream<DirectoryChangeBatch> get changes => _controller.stream;

  /// Called by the pump with its shared scratch struct.
  void _drain(Pointer<CcWatchDrain> scratch) {
    if (_closed) {
      return;
    }
    final rc = _bindings.drain(_handle, scratch);
    if (rc <= 0) {
      return;
    }
    final out = scratch.ref;
    var paths = const <String>[];
    if (out.len > 0) {
      // utf8.decode copies — required, the native buffer is reused by the
      // next drain on this handle.
      paths = utf8
          .decode(out.buf.asTypedList(out.len), allowMalformed: true)
          .split(_nul)
          .where((path) => path.isNotEmpty)
          .toList();
    }
    final flags = out.flags;
    final degraded = flags & ccWatchFlagDegraded != 0;
    if (degraded && !_warnedDegraded) {
      _warnedDegraded = true;
      _log?.call(
        'NativeDirectoryWatcher',
        'watch coverage for $root is partial (watch budget/ENOSPC; '
            '${out.watchCount} live watches) — changes may arrive as '
            'rescan signals',
      );
    }
    final batch = DirectoryChangeBatch(
      paths: paths,
      rescanNeeded: flags & ccWatchFlagRescan != 0,
      rootGone: flags & ccWatchFlagRootGone != 0,
      dropped: out.dropped,
    );
    _controller.add(batch);
    if (batch.rootGone) {
      // The handle is dead; release it so the consumer's reconcile can re-arm
      // a re-provisioned checkout at the same path.
      unawaited(close());
    }
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _WatchPump.instance.unregister(this);
    _bindings.destroy(_handle);
    if (!_controller.isClosed) {
      // Await only when someone is listening: a single-subscription
      // controller's close() future completes when the done event is
      // DELIVERED, which never happens without a listener — awaiting it
      // unconditionally hangs a close-before-listen.
      final done = _controller.close();
      if (_controller.hasListener) {
        await done;
      }
    }
  }
}

/// Process-wide drain pump: one periodic timer and one shared scratch struct
/// serving every live [NativeDirectoryWatcher]. Stops (and frees the scratch)
/// when the last handle closes.
class _WatchPump {
  _WatchPump._();

  static final _WatchPump instance = _WatchPump._();

  final Set<NativeDirectoryWatcher> _live = {};
  Timer? _timer;
  Pointer<CcWatchDrain>? _scratch;

  void register(NativeDirectoryWatcher watcher) {
    _live.add(watcher);
    _scratch ??= calloc<CcWatchDrain>();
    _timer ??= Timer.periodic(NativeDirectoryWatcher.pumpInterval, _tick);
  }

  void unregister(NativeDirectoryWatcher watcher) {
    _live.remove(watcher);
    if (_live.isEmpty) {
      _timer?.cancel();
      _timer = null;
      final scratch = _scratch;
      _scratch = null;
      if (scratch != null) {
        calloc.free(scratch);
      }
    }
  }

  void _tick(Timer _) {
    final scratch = _scratch;
    if (scratch == null) {
      return;
    }
    // Snapshot: a rootGone drain closes (and unregisters) mid-iteration.
    for (final watcher in _live.toList()) {
      watcher._drain(scratch);
    }
  }
}
