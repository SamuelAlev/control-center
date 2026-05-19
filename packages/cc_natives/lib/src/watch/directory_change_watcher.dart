/// The directory-watching PORT the code-graph watch service consumes.
///
/// Deliberately FFI-free (no `dart:ffi` import) so the contract can be faked
/// in tests without loading a dylib. The only production implementation is
/// the native `cc_watcher` (`NativeDirectoryWatcher`) — there is no
/// `package:watcher` fallback, by design (see [DirectoryChangeWatcher]'s
/// implementation for why).
library;

/// One coalesced batch of filesystem changes under a watched root.
///
/// A batch is a SET of changed paths (duplicates collapsed at the source),
/// possibly with out-of-band flags: [rescanNeeded] means "something under the
/// root changed but the paths are unknown" (event-queue overflow, kernel
/// rescan hints, structural directory changes on Linux) — the consumer treats
/// it exactly like a relevant change. [rootGone] means the watched root
/// itself vanished and the watch is dead.
class DirectoryChangeBatch {
  /// Creates a [DirectoryChangeBatch].
  const DirectoryChangeBatch({
    this.paths = const [],
    this.rescanNeeded = false,
    this.rootGone = false,
    this.dropped = 0,
  });

  /// Absolute changed paths, all under the requested root.
  final List<String> paths;

  /// Something changed but the paths are unknown — treat as "changed".
  final bool rescanNeeded;

  /// The watched root itself vanished; this watcher delivers nothing more.
  final bool rootGone;

  /// Paths discarded (queue overflow) since the previous batch.
  final int dropped;
}

/// A live watch on one directory tree.
abstract interface class DirectoryChangeWatcher {
  /// Coalesced change batches. A broadcast-like single-subscription stream;
  /// errors are non-fatal diagnostics.
  Stream<DirectoryChangeBatch> get changes;

  /// Stops watching and releases any native resources. Idempotent.
  Future<void> close();
}

/// Creates a [DirectoryChangeWatcher] for [path]. [ignoreDirNames] are
/// directory NAMES (not paths) whose subtrees are never watched or reported —
/// fed from `SourceFileWalker.watchIgnoredDirs` so the walker and the watcher
/// agree on what matters.
typedef DirectoryChangeWatcherFactory =
    DirectoryChangeWatcher Function(String path, {Set<String> ignoreDirNames});
