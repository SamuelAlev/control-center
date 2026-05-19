import 'dart:async';
import 'dart:ffi';
import 'dart:isolate';

import 'package:cc_natives/src/file_search/dart_file_search.dart';
import 'package:cc_natives/src/file_search/file_search.dart';
import 'package:cc_natives/src/native_library.dart';
import 'package:cc_natives/src/native_runtime.dart';
import 'package:cc_natives/src/native_unavailable.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

// ignore_for_file: avoid_positional_boolean_parameters
// ── FFI struct ────────────────────────────────────────────────────────────────

/// Universal return envelope from every `fff_*` function (heap-allocated).
///
/// Matches `FffResult` in `fff.h` (cbindgen layout):
///   offset  0: bool   success  (1 byte, then 7 bytes padding)
///   offset  8: char*  error    (8 bytes; null when success == true)
///   offset 16: void*  handle   (8 bytes; payload pointer, type depends on function)
///   offset 24: int64  intValue (8 bytes; for simple return values)
///
/// `fff_free_result` frees `error` but NOT `handle` — the handle must be
/// freed with the appropriate typed free function before calling `freeResult`.
final class FffResult extends Struct {
  /// Whether the native call succeeded.
  @Bool()
  external bool success;

  /// Error message when `success` is `false`.
  external Pointer<Utf8> error;

  /// Opaque result handle pointing to function-specific payload.
  external Pointer<Void> handle;

  /// Integer return value for simple results.
  @Int64()
  external int intValue;
}

// ── Native function typedefs ──────────────────────────────────────────────────

typedef _CreateInstance =
    Pointer<FffResult> Function(
      Pointer<Utf8> basePath,
      Pointer<Utf8> frecencyDbPath,
      Pointer<Utf8> historyDbPath,
      bool useUnsafeNoLock,
      bool enableMmapCache,
      bool enableContentIndexing,
      bool watch,
      bool aiMode,
    );

typedef _WaitForScan =
    Pointer<FffResult> Function(Pointer<Void> handle, int timeoutMs);

typedef _Search =
    Pointer<FffResult> Function(
      Pointer<Void> handle,
      Pointer<Utf8> query,
      Pointer<Utf8> currentFile,
      int maxThreads,
      int pageIndex,
      int pageSize,
      int comboBoostMultiplier,
      int minComboCount,
    );

typedef _SearchResultGetCount = int Function(Pointer<Void> result);

typedef _SearchResultGetItem =
    Pointer<Void> Function(Pointer<Void> result, int index);

typedef _FileItemGetRelativePath = Pointer<Utf8> Function(Pointer<Void> item);

// FffScore.total is int32_t at offset 0 — read via scorePtr.cast<Int32>().value
typedef _SearchResultGetScore =
    Pointer<Void> Function(Pointer<Void> result, int index);

typedef _FreeSearchResult = void Function(Pointer<Void> result);

typedef _FreeResult = void Function(Pointer<FffResult> result);

typedef _Destroy = void Function(Pointer<Void> handle);

// ── Bindings ──────────────────────────────────────────────────────────────────

class _FffBindings {
  _FffBindings(DynamicLibrary lib)
    : createInstance = lib
          .lookupFunction<
            Pointer<FffResult> Function(
              Pointer<Utf8>,
              Pointer<Utf8>,
              Pointer<Utf8>,
              Bool,
              Bool,
              Bool,
              Bool,
              Bool,
            ),
            _CreateInstance
          >('fff_create_instance'),
      waitForScan = lib
          .lookupFunction<
            Pointer<FffResult> Function(Pointer<Void>, Uint64),
            _WaitForScan
          >('fff_wait_for_scan'),
      search = lib
          .lookupFunction<
            Pointer<FffResult> Function(
              Pointer<Void>,
              Pointer<Utf8>,
              Pointer<Utf8>,
              Uint32,
              Uint32,
              Uint32,
              Int32,
              Uint32,
            ),
            _Search
          >('fff_search'),
      searchResultGetCount = lib
          .lookupFunction<
            Uint32 Function(Pointer<Void>),
            _SearchResultGetCount
          >('fff_search_result_get_count'),
      searchResultGetItem = lib
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>, Uint32),
            _SearchResultGetItem
          >('fff_search_result_get_item'),
      fileItemGetRelativePath = lib
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Void>),
            _FileItemGetRelativePath
          >('fff_file_item_get_relative_path'),
      searchResultGetScore = lib
          .lookupFunction<
            Pointer<Void> Function(Pointer<Void>, Uint32),
            _SearchResultGetScore
          >('fff_search_result_get_score'),
      freeSearchResult = lib
          .lookupFunction<Void Function(Pointer<Void>), _FreeSearchResult>(
            'fff_free_search_result',
          ),
      freeResult = lib
          .lookupFunction<Void Function(Pointer<FffResult>), _FreeResult>(
            'fff_free_result',
          ),
      destroy = lib.lookupFunction<Void Function(Pointer<Void>), _Destroy>(
        'fff_destroy',
      );

  final _CreateInstance createInstance;
  final _WaitForScan waitForScan;
  final _Search search;
  final _SearchResultGetCount searchResultGetCount;
  final _SearchResultGetItem searchResultGetItem;
  final _FileItemGetRelativePath fileItemGetRelativePath;
  final _SearchResultGetScore searchResultGetScore;
  final _FreeSearchResult freeSearchResult;
  final _FreeResult freeResult;
  final _Destroy destroy;
}

// ── FffFileSearch ─────────────────────────────────────────────────────────────

/// Thrown when the `libfff_c` native cannot be loaded. There is no degraded
/// mode: the native ships inside the host bundle (the cc_server build hook /
/// the desktop release packaging), so its absence is a broken install.
/// See [NativeLibraryUnavailable].
class FffUnavailable implements NativeLibraryUnavailable {
  /// Creates the marker exception.
  const FffUnavailable();

  @override
  String get message =>
      'libfff_c could not be loaded (build it with '
      'scripts/natives/build_fff.sh, or rebuild the server bundle with the '
      'natives staged)';

  @override
  String toString() => 'FffUnavailable: $message.';
}

// ── Worker protocol ───────────────────────────────────────────────────────────

/// A command sent to the fff worker isolate.
///
/// Plain data by construction: the isolate owns the `DynamicLibrary`, the
/// bindings and every `Pointer`, none of which can cross an isolate boundary.
/// The host resolves the app-support path BEFORE spawning and sends the
/// resolved string, because `NativeDirResolver` is a closure.
sealed class _FffCommand {
  const _FffCommand(this.id);

  final int id;
}

class _WarmUpCommand extends _FffCommand {
  const _WarmUpCommand(super.id, this.roots);

  final List<String> roots;
}

class _SearchCommand extends _FffCommand {
  const _SearchCommand(
    super.id,
    this.roots,
    this.query,
    this.offset,
    this.limit,
  );

  final List<String> roots;
  final String query;
  final int offset;
  final int limit;
}

class _InvalidateCommand extends _FffCommand {
  const _InvalidateCommand(super.id, this.roots);

  final List<String> roots;
}

class _ShutdownCommand extends _FffCommand {
  const _ShutdownCommand(super.id);
}

/// A reply from the worker.
class _FffReply {
  const _FffReply(this.id, {this.hits, this.error});

  final int id;
  final List<FileSearchHit>? hits;
  final String? error;
}

/// Runs inside the worker isolate: owns the bindings and the per-root handles,
/// and processes one command at a time.
Future<void> _fffWorkerMain((SendPort, String?) args) async {
  final (host, appSupportRoot) = args;
  final commands = ReceivePort();
  host.send(commands.sendPort);

  _FffBindings? bindings;
  var loadFailed = false;
  final handles = <String, Pointer<Void>>{};

  _FffBindings? ensureBindings() {
    if (bindings != null || loadFailed) {
      return bindings;
    }
    final lib = tryOpenFirst(
      nativeLibraryCandidates('fff_c', appSupportRoot: appSupportRoot),
    );
    if (lib == null) {
      loadFailed = true;
      return null;
    }
    try {
      return bindings = _FffBindings(lib);
    } on Object {
      loadFailed = true;
      return null;
    }
  }

  void createHandle(_FffBindings b, String root) {
    final rootPtr = root.toNativeUtf8();
    final nullStr = nullptr.cast<Utf8>();
    try {
      final result = b.createInstance(
        rootPtr,
        nullStr,
        nullStr,
        false,
        true,
        false,
        true,
        false,
      );
      if (result.address == 0) {
        return;
      }
      final ok = result.ref.success;
      final handle = result.ref.handle;
      b.freeResult(result);
      if (!ok || handle.address == 0) {
        return;
      }
      handles[root] = handle;
      // Wait for the initial file scan so the first query returns results.
      // This blocks for up to 5 s — which is exactly why the whole engine
      // lives on this isolate and not on the caller's.
      final waitResult = b.waitForScan(handle, 5000);
      if (waitResult.address != 0) {
        b.freeResult(waitResult);
      }
    } finally {
      malloc.free(rootPtr);
    }
  }

  List<FileSearchHit> runSearch(
    _FffBindings b,
    List<String> roots,
    String query,
    int offset,
    int limit,
  ) {
    final hits = <FileSearchHit>[];
    final queryPtr = query.toNativeUtf8();
    final nullStr = nullptr.cast<Utf8>();
    // Multi-root paging must MERGE, not cut: fff ranks per root, so the global
    // page [offset, offset+limit) can only be computed by fetching each root's
    // top (offset+limit) results, sorting the union and slicing. Cutting the
    // accumulation at `limit` mid-loop (the single-page behaviour) would let
    // the first root fill every page and the later roots' entries would never
    // surface on ANY page. fff pages natively by pageIndex/pageSize; asking
    // for one bigger page keeps the wire payload at `limit` either way.
    final fetch = offset + limit;
    try {
      for (final root in roots) {
        if (!handles.containsKey(root)) {
          createHandle(b, root);
        }
        final handle = handles[root];
        if (handle == null) {
          continue;
        }

        final result = b.search(handle, queryPtr, nullStr, 0, 0, fetch, 0, 0);
        if (result.address == 0) {
          continue;
        }
        final ok = result.ref.success;
        final searchResultPtr = result.ref.handle;
        b.freeResult(result);
        if (!ok || searchResultPtr.address == 0) {
          continue;
        }

        try {
          final count = b.searchResultGetCount(searchResultPtr);
          for (var i = 0; i < count; i++) {
            final item = b.searchResultGetItem(searchResultPtr, i);
            if (item.address == 0) {
              continue;
            }
            final relPathPtr = b.fileItemGetRelativePath(item);
            if (relPathPtr.address == 0) {
              continue;
            }
            final relPath = relPathPtr.toDartString();
            // FffScore.total (int32_t) is the first field at offset 0.
            final scorePtr = b.searchResultGetScore(searchResultPtr, i);
            final score = scorePtr.address != 0
                ? scorePtr.cast<Int32>().value.toDouble()
                : 0.0;
            hits.add(
              FileSearchHit(
                absolutePath: p.join(root, relPath),
                relativePath: relPath,
                rootPath: root,
                isDirectory: false,
                score: score,
              ),
            );
          }
        } finally {
          b.freeSearchResult(searchResultPtr);
        }
      }
    } finally {
      malloc.free(queryPtr);
    }
    hits.sort((a, b) => b.score.compareTo(a.score));
    return hits.skip(offset).take(limit).toList(growable: false);
  }

  await for (final message in commands) {
    if (message is! _FffCommand) {
      continue;
    }
    switch (message) {
      case _ShutdownCommand():
        final b = bindings;
        if (b != null) {
          for (final handle in handles.values) {
            b.destroy(handle);
          }
        }
        handles.clear();
        host.send(_FffReply(message.id));
        commands.close();
        return;

      case _InvalidateCommand(:final roots):
        final b = bindings;
        for (final root in roots) {
          final handle = handles.remove(root);
          if (handle != null && b != null) {
            b.destroy(handle);
          }
        }
        host.send(_FffReply(message.id));

      case _WarmUpCommand(:final roots):
        final b = ensureBindings();
        if (b == null) {
          host.send(_FffReply(message.id, error: 'unavailable'));
          break;
        }
        try {
          for (final root in roots) {
            if (!handles.containsKey(root)) {
              createHandle(b, root);
            }
          }
          host.send(_FffReply(message.id));
        } on Object catch (e) {
          host.send(_FffReply(message.id, error: '$e'));
        }

      case _SearchCommand(:final roots, :final query, :final offset, :final limit):
        final b = ensureBindings();
        if (b == null) {
          host.send(_FffReply(message.id, error: 'unavailable'));
          break;
        }
        try {
          host.send(
            _FffReply(
              message.id,
              hits: runSearch(b, roots, query, offset, limit),
            ),
          );
        } on Object catch (e) {
          host.send(_FffReply(message.id, error: '$e'));
        }
    }
  }
}

/// Host-side handle to the worker isolate.
class _FffWorker {
  _FffWorker._(this._isolate, this._toWorker, this._fromWorker);

  final Isolate _isolate;
  final SendPort _toWorker;
  final ReceivePort _fromWorker;
  final Map<int, Completer<List<FileSearchHit>?>> _pending = {};
  var _nextId = 0;
  var _closed = false;

  static Future<_FffWorker> spawn(String? appSupportRoot) async {
    final fromWorker = ReceivePort();
    final replies = fromWorker.asBroadcastStream();
    final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _fffWorkerMain,
        (fromWorker.sendPort, appSupportRoot),
        debugName: 'fff-file-search',
        errorsAreFatal: false,
      );
    } on Object {
      fromWorker.close();
      rethrow;
    }
    // The worker's first message is its command port.
    final toWorker = await replies.firstWhere((m) => m is SendPort) as SendPort;
    final worker = _FffWorker._(isolate, toWorker, fromWorker);
    worker._subscription = replies.listen((message) {
      if (message is _FffReply) {
        worker._complete(message);
      }
    });
    return worker;
  }

  // Cancelled in [shutdown]; the analyzer cannot see across the assignment.
  // ignore: cancel_subscriptions
  StreamSubscription<dynamic>? _subscription;

  void _complete(_FffReply reply) {
    final completer = _pending.remove(reply.id);
    if (completer == null || completer.isCompleted) {
      return;
    }
    final error = reply.error;
    if (error != null) {
      completer.completeError(
        error == 'unavailable' ? const FffUnavailable() : StateError(error),
      );
      return;
    }
    completer.complete(reply.hits);
  }

  Future<List<FileSearchHit>?> _send(
    _FffCommand Function(int id) build,
  ) {
    if (_closed) {
      throw StateError('fff worker is closed');
    }
    final id = _nextId++;
    final completer = Completer<List<FileSearchHit>?>();
    _pending[id] = completer;
    _toWorker.send(build(id));
    return completer.future;
  }

  Future<void> warmUp(List<String> roots) =>
      _send((id) => _WarmUpCommand(id, roots));

  Future<List<FileSearchHit>> search(
    List<String> roots,
    String query,
    int offset,
    int limit,
  ) async =>
      await _send(
        (id) => _SearchCommand(id, roots, query, offset, limit),
      ) ??
      const [];

  Future<void> invalidate(List<String> roots) =>
      _send((id) => _InvalidateCommand(id, roots));

  Future<void> shutdown() async {
    if (_closed) {
      return;
    }
    _closed = true;
    try {
      await _send(_ShutdownCommand.new).timeout(const Duration(seconds: 5));
    } on Object {
      // The worker is wedged or already gone — kill it below either way.
    }
    await _subscription?.cancel();
    _fromWorker.close();
    _isolate.kill(priority: Isolate.immediate);
    for (final completer in _pending.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('fff worker closed'));
      }
    }
    _pending.clear();
  }
}

/// [FileSearch] backed by fff (Rust) via its C ABI.
///
/// The native library is REQUIRED: [warmUp] and [search] throw
/// [FffUnavailable] when `libfff_c` cannot be loaded (no silent pure-Dart
/// degrade). Only [listEntries] uses the pure-Dart walk, because fff has no
/// list-all surface — a functional gap, not an availability fallback.
///
/// One fff instance (opaque handle) is kept alive per root directory.
/// Construct once and share via the `fileSearchProvider`.
///
/// fff-backed [FileSearch], with every native call on a worker isolate.
///
/// The engine has to live off the caller's isolate, not merely be `async`:
/// `fff_wait_for_scan` blocks for up to 5 SECONDS on a cold root, and both
/// `search` and `warmUp` reach it. This object is constructed on cc_server's
/// main isolate and backs both the Explorer RPC and the harness `read` /
/// `file_search` agent tools, so an agent searching a cold root used to freeze
/// every concurrent RPC for the duration.
///
/// One long-lived isolate rather than `Isolate.run` per call: fff instance
/// handles are per-root native pointers that must be created once, reused, and
/// destroyed by whoever created them — they cannot cross an isolate boundary,
/// so the isolate that owns them owns the whole engine. Same shape as the
/// embedder and transcriber workers.
class FffFileSearch implements FileSearch {
  /// Creates an [FffFileSearch].
  ///
  /// [appSupportRoot] resolves the directory where `scripts/natives/build_fff.sh`
  /// installs `libfff_c` at dev time (the app-support root, next to
  /// `control_center.db`). When omitted, only the bundle-relative release paths
  /// are tried. [onLog] receives error diagnostics; defaults to silent.
  FffFileSearch({NativeDirResolver? appSupportRoot, NativeLog? onLog})
    : _appSupportRoot = appSupportRoot,
      _log = onLog;

  final NativeDirResolver? _appSupportRoot;
  final NativeLog? _log;

  /// Pure-Dart walker for [listEntries] only (fff has no list-all API).
  final _fallback = DartFileSearch();

  Future<_FffWorker>? _workerFuture;
  var _disposed = false;

  Future<_FffWorker> _ensureWorker() {
    final inFlight = _workerFuture;
    if (inFlight != null) {
      return inFlight;
    }
    final future = _spawnWorker();
    _workerFuture = future;
    return future.catchError((Object e) {
      // Allow a retry on the next call (e.g. the dylib installed later).
      _workerFuture = null;
      throw e;
    });
  }

  Future<_FffWorker> _spawnWorker() async {
    // Resolve the host-injected app-support root HERE: the resolver is a
    // closure and cannot be sent to the worker.
    String? appSupportRoot;
    final rootResolver = _appSupportRoot;
    if (rootResolver != null) {
      try {
        appSupportRoot = (await rootResolver()).path;
      } on Object {
        // Fall back to the bundle-relative release paths.
      }
    }
    return _FffWorker.spawn(appSupportRoot);
  }

  @override
  Future<void> warmUp(List<String> roots) async {
    if (_disposed) {
      return;
    }
    try {
      await (await _ensureWorker()).warmUp(roots);
    } on FffUnavailable {
      _log?.call('FffFileSearch', 'libfff_c not found');
      rethrow;
    }
  }

  @override
  void invalidate(List<String> roots) {
    final worker = _workerFuture;
    if (worker != null) {
      unawaited(
        worker.then((w) => w.invalidate(roots)).catchError((Object _) {}),
      );
    }
    _fallback.invalidate(roots);
  }

  @override
  Stream<List<FileSearchHit>> search({
    required List<String> roots,
    required String query,
    int limit = 25,
    int offset = 0,
  }) {
    final ctrl = StreamController<List<FileSearchHit>>();
    unawaited(
      _doSearch(ctrl, roots: roots, query: query, limit: limit, offset: offset),
    );
    return ctrl.stream;
  }

  @override
  Stream<List<FileSearchHit>> listEntries({
    required List<String> roots,
    int limit = 50000,
  }) {
    // fff is search-oriented (no "list every entry" surface); the unfiltered
    // explorer tree delegates to the cached Dart walk, which mirrors the
    // working directory incl. untracked files.
    return _fallback.listEntries(roots: roots, limit: limit);
  }

  Future<void> _doSearch(
    StreamController<List<FileSearchHit>> ctrl, {
    required List<String> roots,
    required String query,
    required int limit,
    required int offset,
  }) async {
    try {
      final worker = await _ensureWorker();
      ctrl.add(await worker.search(roots, query, offset, limit));
    } catch (e, st) {
      _log?.call('FffFileSearch', 'search error', e, st);
      ctrl.addError(e, st);
    } finally {
      await ctrl.close();
    }
  }

  /// Destroys all fff instance handles and stops the worker. Called by the DI
  /// provider on dispose.
  Future<void> dispose() async {
    _disposed = true;
    final worker = _workerFuture;
    _workerFuture = null;
    if (worker == null) {
      return;
    }
    try {
      await (await worker).shutdown();
    } on Object {
      // Never let teardown throw.
    }
  }
}
