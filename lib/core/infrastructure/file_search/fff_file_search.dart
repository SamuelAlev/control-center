import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:control_center/core/infrastructure/file_search/dart_file_search.dart';
import 'package:control_center/core/infrastructure/file_search/file_search.dart';
import 'package:control_center/core/storage/control_center_paths.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;

// ── FFI struct ────────────────────────────────────────────────────────────────

/// Universal return envelope from every `fff_*` function (heap-allocated).
///
/// Matches `FffResult` in `fff.h` (cbindgen layout):
///   offset  0: bool   success  (1 byte, then 7 bytes padding)
///   offset  8: char*  error    (8 bytes; null when success == true)
///   offset 16: void*  handle   (8 bytes; payload pointer, type depends on function)
///   offset 24: int64  intValue (8 bytes; for simple return values)
///
/// `fff_free_result` frees [error] but NOT [handle] — the handle must be
/// freed with the appropriate typed free function before calling [freeResult].
final class FffResult extends Struct {
  @Bool()
  external bool success;
  external Pointer<Utf8> error;
  external Pointer<Void> handle;
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
          .lookupFunction<Pointer<FffResult> Function(Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Bool, Bool, Bool, Bool, Bool), _CreateInstance>(
            'fff_create_instance',
          ),
      waitForScan = lib.lookupFunction<Pointer<FffResult> Function(Pointer<Void>, Uint64), _WaitForScan>(
        'fff_wait_for_scan',
      ),
      search = lib.lookupFunction<Pointer<FffResult> Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Uint32, Uint32, Uint32, Int32, Uint32), _Search>('fff_search'),
      searchResultGetCount = lib
          .lookupFunction<Uint32 Function(Pointer<Void>), _SearchResultGetCount>(
            'fff_search_result_get_count',
          ),
      searchResultGetItem = lib
          .lookupFunction<Pointer<Void> Function(Pointer<Void>, Uint32), _SearchResultGetItem>(
            'fff_search_result_get_item',
          ),
      fileItemGetRelativePath = lib
          .lookupFunction<
            Pointer<Utf8> Function(Pointer<Void>),
            _FileItemGetRelativePath
          >('fff_file_item_get_relative_path'),
      searchResultGetScore = lib
          .lookupFunction<Pointer<Void> Function(Pointer<Void>, Uint32), _SearchResultGetScore>(
            'fff_search_result_get_score',
          ),
      freeSearchResult = lib
          .lookupFunction<Void Function(Pointer<Void>), _FreeSearchResult>(
            'fff_free_search_result',
          ),
      freeResult = lib.lookupFunction<Void Function(Pointer<FffResult>), _FreeResult>(
        'fff_free_result',
      ),
      destroy = lib.lookupFunction<Void Function(Pointer<Void>), _Destroy>('fff_destroy');

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

/// [FileSearch] backed by fff (Rust) via its C ABI.
///
/// Degrades transparently to [DartFileSearch] when the native library is
/// absent — call sites are unaffected. Build and install `libfff_c` with
/// `scripts/build_fff.sh`, then restart the app.
///
/// One fff instance (opaque handle) is kept alive per root directory.
/// Construct once and share via the `fileSearchProvider`.
class FffFileSearch implements FileSearch {
  FffFileSearch({this.forceDartFallback = false});

  /// Skip native loading entirely. Used in tests and before the dylib is built.
  final bool forceDartFallback;

  final _fallback = DartFileSearch();

  // Per-root instance handles from fff_create_instance.
  final Map<String, Pointer<Void>> _handles = {};

  // Lazily resolved native bindings (null when library unavailable).
  _FffBindings? _bindings;
  Completer<_FffBindings?>? _bindingsCompleter;

  Future<_FffBindings?> _ensureBindings() {
    _bindingsCompleter ??= Completer()..complete(_loadBindings());
    return _bindingsCompleter!.future;
  }

  Future<_FffBindings?> _loadBindings() async {
    if (forceDartFallback) return null;
    final lib = await _openLib();
    if (lib == null) return null;
    try {
      _bindings = _FffBindings(lib);
      return _bindings;
    } catch (e) {
      AppLog.e('FffFileSearch', 'failed to resolve symbols', e);
      return null;
    }
  }

  Future<DynamicLibrary?> _openLib() async {
    // 1. Absolute path installed by scripts/build_fff.sh (app support root,
    //    same directory as control_center.db).
    try {
      final root = await controlCenterRootDir();
      final ext = Platform.isMacOS ? 'dylib' : 'so';
      final devPath = p.join(root.path, 'libfff_c.$ext');
      if (File(devPath).existsSync()) {
        return DynamicLibrary.open(devPath);
      }
    } catch (_) {}

    // 2. Bundle-relative paths for release builds.
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      if (Platform.isMacOS) ...[
        '@executable_path/../Frameworks/libfff_c.dylib',
        'libfff_c.dylib',
      ],
      if (Platform.isLinux) ...[
        // Bundled next to the Linux executable (AppImage / tar bundle). The
        // app's RPATH is $ORIGIN/lib, but dlopen-by-soname doesn't honour a
        // RUNPATH, so resolve the bundled path explicitly first.
        p.join(exeDir, 'lib', 'libfff_c.so'),
        'libfff_c.so',
      ],
      if (Platform.isWindows) 'fff_c.dll',
    ];
    for (final c in candidates) {
      try {
        return DynamicLibrary.open(c);
      } on ArgumentError {
        continue;
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  /// Creates and stores a fff instance for [root], then waits up to 5 s for
  /// the initial scan to complete.
  Future<void> _createHandle(_FffBindings b, String root) async {
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
      if (result.address == 0) return;
      final ok = result.ref.success;
      final handle = result.ref.handle;
      b.freeResult(result);
      if (!ok || handle.address == 0) return;
      _handles[root] = handle;
      // Wait for the initial file scan so the first query returns results.
      final waitResult = b.waitForScan(handle, 5000);
      if (waitResult.address != 0) b.freeResult(waitResult);
    } finally {
      malloc.free(rootPtr);
    }
  }

  @override
  Future<void> warmUp(List<String> roots) async {
    final b = await _ensureBindings();
    if (b == null) return _fallback.warmUp(roots);
    for (final root in roots) {
      if (!_handles.containsKey(root)) {
        await _createHandle(b, root);
      }
    }
  }

  @override
  void invalidate(List<String> roots) {
    final b = _bindings;
    for (final root in roots) {
      final handle = _handles.remove(root);
      if (handle != null && b != null) {
        b.destroy(handle);
      }
    }
    _fallback.invalidate(roots);
  }

  @override
  Stream<List<FileSearchHit>> search({
    required List<String> roots,
    required String query,
    int limit = 25,
  }) {
    final ctrl = StreamController<List<FileSearchHit>>();
    _doSearch(ctrl, roots: roots, query: query, limit: limit);
    return ctrl.stream;
  }

  Future<void> _doSearch(
    StreamController<List<FileSearchHit>> ctrl, {
    required List<String> roots,
    required String query,
    required int limit,
  }) async {
    try {
      final b = await _ensureBindings();
      if (b == null) {
        await _fallback
            .search(roots: roots, query: query, limit: limit)
            .forEach(ctrl.add);
        return;
      }

      final hits = <FileSearchHit>[];
      final queryPtr = query.toNativeUtf8();
      final nullStr = nullptr.cast<Utf8>();
      try {
        for (final root in roots) {
          if (!_handles.containsKey(root)) {
            await _createHandle(b, root);
          }
          final handle = _handles[root];
          if (handle == null) continue;

          final result = b.search(handle, queryPtr, nullStr, 0, 0, limit, 0, 0);
          if (result.address == 0) continue;
          final ok = result.ref.success;
          final searchResultPtr = result.ref.handle;
          b.freeResult(result);
          if (!ok || searchResultPtr.address == 0) continue;

          try {
            final count = b.searchResultGetCount(searchResultPtr);
            for (var i = 0; i < count && hits.length < limit; i++) {
              final item = b.searchResultGetItem(searchResultPtr, i);
              if (item.address == 0) continue;
              final relPathPtr = b.fileItemGetRelativePath(item);
              if (relPathPtr.address == 0) continue;
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
      ctrl.add(hits.take(limit).toList(growable: false));
    } catch (e, st) {
      AppLog.e('FffFileSearch', 'search error', e, st);
      ctrl.addError(e, st);
    } finally {
      await ctrl.close();
    }
  }

  /// Destroys all fff instance handles. Called by the DI provider on dispose.
  void dispose() {
    final b = _bindings;
    if (b != null) {
      for (final handle in _handles.values) {
        b.destroy(handle);
      }
    }
    _handles.clear();
  }
}
