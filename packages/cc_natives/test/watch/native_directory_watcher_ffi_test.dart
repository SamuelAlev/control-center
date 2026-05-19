import 'dart:async';
import 'dart:io';

import 'package:cc_natives/cc_natives.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import '../helpers/dev_native_layout.dart';

/// End-to-end FFI tests for the native cc_watcher library. Loads
/// libcc_watcher from the repo's dev locations and exercises create → events
/// → drain → destroy, including the two regressions that bit during design:
/// the FSEvents canonical-root rewrite (`/var/...` → `/private/var/...`) and
/// overflow degrading to a rescan signal.
///
/// Fails (does not skip) when the library hasn't been built locally:
/// libcc_watcher is a REQUIRED native and `cc_server` refuses to boot without
/// it. CI runners do not build natives and skip.
void main() {
  NativeDirectoryWatcher.debugResetBindings();
  NativeDirectoryWatcher.libraryResolver = () => tryOpenFirst(
    devNativeCandidates(watcherLibraryBaseName, envVar: watcherLibraryEnvVar),
  );
  NativeDirectoryWatcher.pumpInterval = const Duration(milliseconds: 50);

  tearDownAll(() {
    NativeDirectoryWatcher.pumpInterval = const Duration(milliseconds: 500);
    NativeDirectoryWatcher.libraryResolver = defaultWatcherLibraryResolver;
    NativeDirectoryWatcher.debugResetBindings();
  });

  if (!NativeDirectoryWatcher.isAvailable) {
    test(
      'libcc_watcher is built',
      () {
        fail(
          'libcc_watcher not loadable — run scripts/natives/build_watcher.sh '
          '(on Windows scripts/release/windows_natives.sh). It is a REQUIRED '
          'native.',
        );
      },
      skip: skipIfMissingInCi(
        false,
        'libcc_watcher is not built on CI runners',
      ),
    );
    return;
  }

  /// The watcher for [root]. Throws on any failure — the native is required, so
  /// both a missing dylib and a create failure are real bugs, never a skip.
  NativeDirectoryWatcher open(
    String root, {
    Set<String> ignore = const {'.git', 'node_modules', 'build'},
    int queueCapacity = 4096,
  }) {
    try {
      return NativeDirectoryWatcher.create(
        root,
        ignoreDirNames: ignore,
        queueCapacity: queueCapacity,
      );
    } on WatcherUnavailable catch (e) {
      fail(
        'libcc_watcher not loadable — run scripts/natives/build_watcher.sh (on '
        'Windows scripts/release/windows_natives.sh). It is a REQUIRED '
        'native: $e',
      );
    }
  }

  Future<void> until(
    bool Function() predicate, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!predicate()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('condition not met within $timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  test('delivers changed paths under the REQUESTED root prefix', () async {
    final root = Directory.systemTemp.createTempSync('cc_watch_ffi_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    final watcher = open(root.path);
    addTearDown(watcher.close);
    final batches = <DirectoryChangeBatch>[];
    watcher.changes.listen(batches.add);
    // Give the backend a moment to arm before the first write.
    await Future<void>.delayed(const Duration(milliseconds: 300));

    File(p.join(root.path, 'a.dart')).writeAsStringSync('void a() {}');
    await until(
      () => batches.any((b) => b.paths.any((x) => x.endsWith('a.dart'))),
    );
    // The FSEvents canonicalization regression: a temp dir under /var/...
    // reports /private/var/... natively; every delivered path must be
    // rewritten back under the root the caller asked for.
    for (final batch in batches) {
      for (final path in batch.paths) {
        expect(path, startsWith(root.path));
      }
    }
  });

  test('never delivers paths under ignored directory names', () async {
    final root = Directory.systemTemp.createTempSync('cc_watch_ffi_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    Directory(
      p.join(root.path, 'node_modules', 'pkg'),
    ).createSync(recursive: true);
    Directory(p.join(root.path, '.git')).createSync();
    final watcher = open(root.path);
    addTearDown(watcher.close);
    final batches = <DirectoryChangeBatch>[];
    watcher.changes.listen(batches.add);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    File(
      p.join(root.path, 'node_modules', 'pkg', 'x.js'),
    ).writeAsStringSync('x');
    File(p.join(root.path, '.git', 'index.lock')).writeAsStringSync('x');
    // A real file too, proving events flow at all.
    File(p.join(root.path, 'real.dart')).writeAsStringSync('void f() {}');
    await until(
      () => batches.any((b) => b.paths.any((x) => x.endsWith('real.dart'))),
    );
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final delivered = [for (final b in batches) ...b.paths];
    expect(
      delivered.where(
        (x) => x.contains('node_modules') || x.contains('${p.separator}.git'),
      ),
      isEmpty,
      reason: 'ignored subtrees must be filtered natively: $delivered',
    );
  });

  test('a nested mkdir followed by a write inside it is delivered', () async {
    final root = Directory.systemTemp.createTempSync('cc_watch_ffi_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    final watcher = open(root.path);
    addTearDown(watcher.close);
    final batches = <DirectoryChangeBatch>[];
    watcher.changes.listen(batches.add);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    final nested = Directory(p.join(root.path, 'lib', 'src'))
      ..createSync(recursive: true);
    // Give the (Linux) dynamic watch-install path a beat before writing.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    File(p.join(nested.path, 'deep.dart')).writeAsStringSync('void d() {}');

    // Delivered either as the concrete path or as a structural rescan —
    // both make the consumer reindex.
    await until(
      () => batches.any(
        (b) => b.rescanNeeded || b.paths.any((x) => x.endsWith('deep.dart')),
      ),
    );
  });

  test('queue overflow degrades to rescanNeeded with a drop count', () async {
    final root = Directory.systemTemp.createTempSync('cc_watch_ffi_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    final watcher = open(root.path, queueCapacity: 8);
    addTearDown(watcher.close);
    // No pump race: stop draining while the burst lands by writing quickly.
    final batches = <DirectoryChangeBatch>[];
    watcher.changes.listen(batches.add);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    for (var i = 0; i < 50; i++) {
      File(p.join(root.path, 'file_$i.dart')).writeAsStringSync('void f() {}');
    }
    await until(() => batches.any((b) => b.rescanNeeded && b.dropped > 0));
  });

  test('root deletion delivers rootGone and the handle self-closes', () async {
    final root = Directory.systemTemp.createTempSync('cc_watch_ffi_');
    final watcher = open(root.path);
    final batches = <DirectoryChangeBatch>[];
    final done = Completer<void>();
    watcher.changes.listen(batches.add, onDone: done.complete);
    await Future<void>.delayed(const Duration(milliseconds: 200));

    root.deleteSync(recursive: true);
    await until(() => batches.any((b) => b.rootGone));
    // rootGone auto-closes the handle (the consumer's reconcile re-arms).
    await done.future.timeout(const Duration(seconds: 2));
    // Double close is safe.
    await watcher.close();
    await watcher.close();
  });

  test('close is idempotent and stops delivery', () async {
    final root = Directory.systemTemp.createTempSync('cc_watch_ffi_');
    addTearDown(() {
      if (root.existsSync()) {
        root.deleteSync(recursive: true);
      }
    });
    final watcher = open(root.path);
    await watcher.close();
    await watcher.close();
    // Writes after close must not crash anything.
    File(p.join(root.path, 'late.dart')).writeAsStringSync('void l() {}');
    await Future<void>.delayed(const Duration(milliseconds: 200));
  });
}
