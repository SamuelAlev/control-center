import 'package:control_center/app/main_window_nudger.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// A window whose resize can run arbitrary code while it is "in progress",
/// the way macOS's `ResizeSynchronizer.beginResize` runs Dart timers while it
/// blocks waiting for a frame at the new size.
class _FakeWindow implements NudgeWindow {
  _FakeWindow(this._size);

  Size _size;
  @override
  bool isOpen = true;

  final List<Size> writes = [];
  int _depth = 0;
  int maxDepth = 0;

  /// Runs inside the next resize, before it returns.
  void Function()? duringNextResize;

  @override
  Size get contentSize => _size;

  @override
  set contentSize(Size value) {
    _depth++;
    if (_depth > maxDepth) {
      maxDepth = _depth;
    }
    try {
      writes.add(value);
      _size = value;
      final during = duringNextResize;
      duringNextResize = null;
      during?.call();
    } finally {
      _depth--;
    }
  }
}

void main() {
  test('grows by 1px, then restores after the hold', () {
    fakeAsync((async) {
      final window = _FakeWindow(const Size(800, 600));
      final nudger = MainWindowNudger(
        findTarget: () => window,
        canResize: () => true,
      );

      expect(nudger.nudge(), isTrue);
      expect(window.writes, [const Size(801, 600)]);

      async.elapse(MainWindowNudger.holdDuration);
      expect(window.writes, [const Size(801, 600), const Size(800, 600)]);
      expect(window.contentSize, const Size(800, 600));
    });
  });

  test('never resizes while a frame is in progress', () {
    // The setup → primary handoff destroys the setup window from a post-frame
    // callback, and the will-show hook's nudge runs inside that destroy. A
    // resize there blocks for a full second, waiting for a frame that cannot
    // start until the current one returns.
    fakeAsync((async) {
      final window = _FakeWindow(const Size(800, 600));
      var idle = false;
      final nudger = MainWindowNudger(
        findTarget: () => window,
        canResize: () => idle,
      );

      expect(nudger.nudge(), isTrue);
      async.elapse(const Duration(milliseconds: 500));
      expect(window.writes, isEmpty);

      idle = true;
      async.elapse(MainWindowNudger.retryDelay);
      expect(window.writes, [const Size(801, 600)]);
      async.elapse(MainWindowNudger.holdDuration + MainWindowNudger.retryDelay);
      expect(window.contentSize, const Size(800, 600));
    });
  });

  test('nothing resizes again while the grow is still blocked', () {
    // The reported hang: a nudge's resize blocked in `beginResize`, the engine
    // ran Dart timers inside that wait, and one of them (an overlapping
    // nudge's restore) resized again, blocking for another second.
    fakeAsync((async) {
      final window = _FakeWindow(const Size(800, 600));
      final nudger = MainWindowNudger(
        findTarget: () => window,
        canResize: () => true,
      );
      window.duringNextResize = () {
        // The guard's staged repairs keep firing while the grow is on the
        // stack, and each asks for another nudge.
        async.elapse(const Duration(milliseconds: 300));
        expect(nudger.nudge(), isTrue);
        expect(window.writes, [const Size(801, 600)]);
      };

      nudger.nudge();
      async.elapse(MainWindowNudger.holdDuration);

      expect(window.writes, [const Size(801, 600), const Size(800, 600)]);
      expect(window.maxDepth, 1);
    });
  });

  test('one nudge in flight at a time, through the restore', () {
    // Two stacked nudges would capture different baselines and leave the
    // window permanently 1px wider.
    fakeAsync((async) {
      final window = _FakeWindow(const Size(800, 600));
      final nudger = MainWindowNudger(
        findTarget: () => window,
        canResize: () => true,
      );

      nudger.nudge();
      async.elapse(const Duration(milliseconds: 60));
      expect(nudger.nudge(), isTrue);
      async.elapse(const Duration(seconds: 1));

      expect(window.writes, [const Size(801, 600), const Size(800, 600)]);

      // Once restored, the next nudge is a real one again.
      nudger.nudge();
      expect(window.writes.last, const Size(801, 600));
    });
  });

  test('reports no window, and does nothing, when there is none', () {
    fakeAsync((async) {
      final nudger = MainWindowNudger(
        findTarget: () => null,
        canResize: () => true,
      );
      expect(nudger.nudge(), isFalse);
      async.elapse(const Duration(seconds: 1));
    });
  });

  test('skips the restore when the window closed during the hold', () {
    fakeAsync((async) {
      var window = _FakeWindow(const Size(800, 600));
      final nudger = MainWindowNudger(
        findTarget: () => window,
        canResize: () => true,
      );

      nudger.nudge();
      window.isOpen = false;
      async.elapse(const Duration(seconds: 1));
      expect(window.writes, [const Size(801, 600)]);

      // And the closed window does not wedge the nudger.
      window = _FakeWindow(const Size(400, 300));
      nudger.nudge();
      expect(window.writes, [const Size(401, 300)]);
    });
  });
}
