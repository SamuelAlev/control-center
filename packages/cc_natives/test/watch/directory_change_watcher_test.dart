import 'dart:async';

import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

/// The FFI-free port contract every backend (the production native cc_watcher
/// and test fakes — there is deliberately no `package:watcher` fallback) must
/// satisfy, plus the hard-failure shape of [NativeDirectoryWatcher.create].
void main() {
  group('DirectoryChangeBatch', () {
    test('defaults are inert', () {
      const batch = DirectoryChangeBatch();
      expect(batch.paths, isEmpty);
      expect(batch.rescanNeeded, isFalse);
      expect(batch.rootGone, isFalse);
      expect(batch.dropped, 0);
    });

    test('flags and paths are independent', () {
      const batch = DirectoryChangeBatch(
        paths: ['/root/a.dart'],
        rescanNeeded: true,
        dropped: 3,
      );
      expect(batch.paths, ['/root/a.dart']);
      expect(batch.rescanNeeded, isTrue);
      expect(batch.rootGone, isFalse);
      expect(batch.dropped, 3);
    });
  });

  group('port contract (via a fake)', () {
    test('batches arrive in order and close terminates the stream', () async {
      final fake = _FakeDirectoryChangeWatcher();
      final received = <DirectoryChangeBatch>[];
      var done = false;
      fake.changes.listen(received.add, onDone: () => done = true);

      fake.emit(const DirectoryChangeBatch(paths: ['/r/1.dart']));
      fake.emit(const DirectoryChangeBatch(rescanNeeded: true));
      await fake.close();
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(2));
      expect(received.first.paths, ['/r/1.dart']);
      expect(received.last.rescanNeeded, isTrue);
      expect(done, isTrue);
    });

    test('close is idempotent', () async {
      final fake = _FakeDirectoryChangeWatcher();
      await fake.close();
      await fake.close();
    });
  });

  group('NativeDirectoryWatcher.create', () {
    setUp(NativeDirectoryWatcher.debugResetBindings);
    tearDown(() {
      NativeDirectoryWatcher.libraryResolver = defaultWatcherLibraryResolver;
      NativeDirectoryWatcher.debugResetBindings();
    });

    test('throws WatcherUnavailable when the dylib cannot load', () {
      // There is no fallback watcher: an unloadable dylib is a broken install
      // and must fail loudly rather than silently degrade to a full-tree scan.
      NativeDirectoryWatcher.libraryResolver = () => null;
      expect(NativeDirectoryWatcher.isAvailable, isFalse);
      expect(
        () => NativeDirectoryWatcher.create(
          '/nowhere',
          ignoreDirNames: const {'.git'},
        ),
        throwsA(isA<WatcherUnavailable>()),
      );
    });
  });
}

class _FakeDirectoryChangeWatcher implements DirectoryChangeWatcher {
  final _controller = StreamController<DirectoryChangeBatch>();

  void emit(DirectoryChangeBatch batch) {
    if (!_controller.isClosed) {
      _controller.add(batch);
    }
  }

  @override
  Stream<DirectoryChangeBatch> get changes => _controller.stream;

  @override
  Future<void> close() async {
    if (!_controller.isClosed) {
      final done = _controller.close();
      if (_controller.hasListener) {
        await done;
      }
    }
  }
}
