import 'dart:ui' show Rect;

import 'package:control_center/app/window_chrome.dart';
import 'package:control_center/app/window_geometry_watcher.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/synced_preferences.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

const Rect _normal = Rect.fromLTWH(100, 80, 1280, 800);
const Rect _moved = Rect.fromLTWH(140, 80, 1280, 800);
const Rect _fullScreen = Rect.fromLTWH(0, 0, 1512, 982);

WindowGeometrySnapshot _snapshot({
  String title = primaryWindowTitle,
  Rect bounds = _normal,
  bool isMaximized = false,
  bool isFullScreen = false,
  bool isMinimized = false,
}) => WindowGeometrySnapshot(
  title: title,
  bounds: bounds,
  isMaximized: isMaximized,
  isFullScreen: isFullScreen,
  isMinimized: isMinimized,
);

void main() {
  group('WindowGeometryWatcher', () {
    /// Runs [frames] one per tick and returns everything that was persisted.
    ///
    /// Each frame is what [WindowGeometryWatcher.capture] answers on that
    /// tick, so a list of DIFFERENT frames models a window in motion and a
    /// repeated frame models one that has come to rest.
    List<WindowGeometrySnapshot> persistedOver(
      List<List<WindowGeometrySnapshot>> frames, {
      bool flushAtEnd = false,
    }) {
      final persisted = <WindowGeometrySnapshot>[];
      fakeAsync((async) {
        var index = 0;
        final watcher = WindowGeometryWatcher(
          capture: () =>
              frames[index < frames.length ? index : frames.length - 1],
          persist: persisted.add,
        )..start();
        for (; index < frames.length; index++) {
          async.elapse(watcher.interval);
        }
        index = frames.length - 1;
        if (flushAtEnd) {
          watcher.flushNow();
        }
        watcher.dispose();
        // Nothing may fire after disposal.
        async.elapse(const Duration(seconds: 10));
      });
      return persisted;
    }

    test('writes nothing while a window is still moving', () {
      final persisted = persistedOver([
        [_snapshot()],
        [_snapshot(bounds: _moved)],
        [_snapshot(bounds: const Rect.fromLTWH(180, 80, 1280, 800))],
      ]);
      expect(persisted, isEmpty);
    });

    test('writes once the window has held still for a tick', () {
      final persisted = persistedOver([
        [_snapshot()],
        [_snapshot(bounds: _moved)],
        [_snapshot(bounds: _moved)],
      ]);
      expect(persisted, [_snapshot(bounds: _moved)]);
    });

    test('does not rewrite an unchanged window', () {
      final persisted = persistedOver([
        [_snapshot()],
        [_snapshot()],
        [_snapshot()],
        [_snapshot()],
      ]);
      expect(persisted, hasLength(1));
    });

    test('never persists a frame from mid-transition', () {
      // Entering full screen sweeps the window through intermediate frames.
      // Any one of them written to disk would become the size the app opens
      // at from then on.
      final persisted = persistedOver([
        [_snapshot()],
        [_snapshot()],
        [_snapshot(bounds: const Rect.fromLTWH(50, 40, 1400, 880))],
        [_snapshot(bounds: const Rect.fromLTWH(10, 10, 1490, 950))],
        [_snapshot(bounds: _fullScreen, isFullScreen: true, isMaximized: true)],
        [_snapshot(bounds: _fullScreen, isFullScreen: true, isMaximized: true)],
      ]);
      expect(persisted, [
        _snapshot(),
        _snapshot(bounds: _fullScreen, isFullScreen: true, isMaximized: true),
      ]);
    });

    test('tracks each window separately', () {
      final persisted = persistedOver([
        [_snapshot(), _snapshot(title: focusPillWindowTitle)],
        // The main window settles while the pill is being dragged.
        [
          _snapshot(),
          _snapshot(title: focusPillWindowTitle, bounds: _moved),
        ],
      ]);
      expect(persisted, [_snapshot()]);
    });

    test('flushNow persists a move the next tick would have caught', () {
      final persisted = persistedOver([
        [_snapshot()],
        [_snapshot(bounds: _moved)],
      ], flushAtEnd: true);
      // The move never settled, but quitting is the last chance to record it.
      expect(persisted, [_snapshot(bounds: _moved)]);
    });

    test('flushNow does not rewrite what is already saved', () {
      final persisted = persistedOver([
        [_snapshot()],
        [_snapshot()],
      ], flushAtEnd: true);
      expect(persisted, hasLength(1));
    });

    test('stops sampling once disposed', () {
      var captures = 0;
      fakeAsync((async) {
        final watcher = WindowGeometryWatcher(
          capture: () {
            captures++;
            return [_snapshot()];
          },
          persist: (_) {},
        )..start();
        async.elapse(const Duration(seconds: 3));
        final before = captures;
        watcher.dispose();
        async.elapse(const Duration(seconds: 10));
        expect(captures, before);
      });
      expect(captures, greaterThan(0));
    });
  });

  group('persistWindowSnapshot', () {
    test('records a normal frame and clears both state flags', () {
      final prefs = AppPreferences.inMemory();
      persistWindowSnapshot(prefs, _snapshot());
      expect(prefs.getDouble('window_x'), 100);
      expect(prefs.getDouble('window_y'), 80);
      expect(prefs.getDouble('window_w'), 1280);
      expect(prefs.getDouble('window_h'), 800);
      expect(prefs.getBool('window_maximized'), isFalse);
      expect(prefs.getBool('window_fullscreen'), isFalse);
    });

    test('a full-screen window records the flag, never the frame', () {
      // The saved frame must keep describing the window the operator sized by
      // hand, so that leaving full screen after a relaunch returns to it
      // instead of to a window the size of the display.
      final prefs = AppPreferences.inMemory({
        'window_x': 100.0,
        'window_y': 80.0,
        'window_w': 1280.0,
        'window_h': 800.0,
      });
      persistWindowSnapshot(
        prefs,
        // `isZoomed` reports true for a full-screen window too, which is why
        // full screen has to be tested first.
        _snapshot(bounds: _fullScreen, isFullScreen: true, isMaximized: true),
      );
      expect(prefs.getBool('window_fullscreen'), isTrue);
      expect(prefs.getDouble('window_w'), 1280);
      expect(prefs.getDouble('window_h'), 800);
    });

    test('a maximized window records the flag, never the frame', () {
      final prefs = AppPreferences.inMemory({
        'window_x': 100.0,
        'window_y': 80.0,
        'window_w': 1280.0,
        'window_h': 800.0,
      });
      persistWindowSnapshot(
        prefs,
        _snapshot(bounds: _fullScreen, isMaximized: true),
      );
      expect(prefs.getBool('window_maximized'), isTrue);
      expect(prefs.getBool('window_fullscreen'), isFalse);
      expect(prefs.getDouble('window_x'), 100);
      expect(prefs.getDouble('window_w'), 1280);
    });

    test('a minimized window records nothing at all', () {
      final prefs = AppPreferences.inMemory();
      persistWindowSnapshot(
        prefs,
        _snapshot(bounds: const Rect.fromLTWH(-3000, 0, 1, 1), isMinimized: true),
      );
      expect(prefs.getKeys(), isEmpty);
    });

    test('HUD windows record only their position', () {
      final prefs = AppPreferences.inMemory();
      persistWindowSnapshot(
        prefs,
        _snapshot(title: focusPillWindowTitle, bounds: _moved),
      );
      expect(prefs.getDouble('focus_mode_pill_x'), 140);
      expect(prefs.getDouble('focus_mode_pill_y'), 80);
      expect(prefs.getKeys(), hasLength(2));
    });

    test('the pre-app setup window never touches the main window keys', () {
      // It is a different window with a different job; letting its small frame
      // land in `window_w`/`window_h` would resize the app on the next launch.
      final prefs = AppPreferences.inMemory();
      persistWindowSnapshot(
        prefs,
        _snapshot(
          title: serverSetupWindowTitle,
          bounds: const Rect.fromLTWH(0, 0, 600, 720),
        ),
      );
      expect(prefs.getKeys(), isEmpty);
    });

    test('the boot-failure window never touches the main window keys', () {
      final prefs = AppPreferences.inMemory();
      persistWindowSnapshot(
        prefs,
        _snapshot(
          title: bootFailureWindowTitle,
          bounds: const Rect.fromLTWH(0, 0, 620, 420),
        ),
      );
      expect(prefs.getKeys(), isEmpty);
    });

    test('every window key stays out of the per-user preference sync', () {
      // Window geometry describes ONE machine's displays. A frame that fits a
      // 27" monitor is off the edge of a laptop, and "I work full screen on
      // the desktop" is not a claim about the laptop — so these keys are
      // device-local, which in this codebase means simply not being in the
      // sync registry. Pinned here because the failure is silent: a synced
      // window position moves someone else's window, it does not throw.
      final synced = buildSyncedPreferences().map((p) => p.key).toSet();
      const windowKeys = [
        'window_x',
        'window_y',
        'window_w',
        'window_h',
        'window_maximized',
        'window_fullscreen',
        'focus_mode_pill_x',
        'focus_mode_pill_y',
        'meeting_toolbar_x',
        'meeting_toolbar_y',
        'soundscape_hud_x',
        'soundscape_hud_y',
      ];
      for (final key in windowKeys) {
        expect(
          synced,
          isNot(contains(key)),
          reason: '$key is window geometry and must never leave this machine',
        );
      }
    });
  });
}
