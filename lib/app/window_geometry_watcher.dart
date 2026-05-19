import 'dart:async';
import 'dart:ui' show Rect;

import 'package:nativeapi/nativeapi.dart' show WindowManager;

/// One window's geometry and window-state at a point in time.
///
/// Value type: two snapshots of a window that has not moved compare equal,
/// which is what lets [WindowGeometryWatcher] tell "settled" from "still being
/// dragged" and skip writes that would change nothing.
class WindowGeometrySnapshot {
  /// Captures the state of a window titled [title].
  const WindowGeometrySnapshot({
    required this.title,
    required this.bounds,
    required this.isMaximized,
    required this.isFullScreen,
    required this.isMinimized,
  });

  /// The window's title, which is how this app identifies its windows.
  final String title;

  /// The window's frame, in the global top-left coordinate space shared with
  /// display work areas.
  final Rect bounds;

  /// Whether the window is zoomed (macOS green-button "fill", not full screen).
  /// Note that a full-screen window reports this as true as well.
  final bool isMaximized;

  /// Whether the window occupies a full-screen Space.
  final bool isFullScreen;

  /// Whether the window is minimized to the Dock.
  final bool isMinimized;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WindowGeometrySnapshot &&
          other.title == title &&
          other.bounds == bounds &&
          other.isMaximized == isMaximized &&
          other.isFullScreen == isFullScreen &&
          other.isMinimized == isMinimized;

  @override
  int get hashCode =>
      Object.hash(title, bounds, isMaximized, isFullScreen, isMinimized);

  @override
  String toString() =>
      'WindowGeometrySnapshot($title, $bounds, maximized: $isMaximized, '
      'fullScreen: $isFullScreen, minimized: $isMinimized)';
}

/// Reads the current geometry of every window [manager] knows about.
///
/// Windows with no title yet are skipped: a window's title lands just after
/// its first show, and an untitled snapshot matches nothing downstream anyway.
List<WindowGeometrySnapshot> captureWindowGeometry(WindowManager manager) {
  final snapshots = <WindowGeometrySnapshot>[];
  for (final window in manager.getAll()) {
    final title = window.title;
    if (title == null || title.isEmpty) {
      continue;
    }
    snapshots.add(
      WindowGeometrySnapshot(
        title: title,
        bounds: window.bounds,
        isMaximized: window.isMaximized,
        isFullScreen: window.isFullScreen,
        isMinimized: window.isMinimized,
      ),
    );
  }
  return snapshots;
}

/// Persists window geometry by polling for it, writing only once a window has
/// stopped moving.
///
/// **Why polling and not window events.** nativeapi exposes
/// `WindowMovedEvent` / `WindowResizedEvent` and friends, and this app used to
/// persist from them — but on macOS they never arrive. In `cnativeapi`'s
/// window-manager delegate every notification handler's body is commented out
/// upstream (`window_manager_macos.mm`: `windowDidMove:`, `windowDidResize:`,
/// … all have their `OnWindowEvent(...)` call disabled), so nothing is ever
/// dispatched to Dart and the listener that looked like the save side of this
/// feature had in fact never written a single byte. There is also no zoom or
/// full-screen notification registered at all, in any version — those states
/// have to be read, never inferred from an event.
///
/// **Why settle-then-write.** Writing on every observed change would mean a
/// preference write per frame of a window drag. Persisting only a snapshot
/// that is identical to the previous tick's costs one extra [interval] of
/// latency and collapses a whole drag into a single write. It also removes a
/// class of bug the event-driven version would have had: entering or leaving
/// full screen sweeps the window through a sequence of intermediate frames,
/// and any one of them written to disk becomes the size the app opens at
/// forever after. An intermediate frame is never equal to the one before it,
/// so it is never persisted.
class WindowGeometryWatcher {
  /// Watches the windows returned by [capture], handing settled snapshots to
  /// [persist]. Both are injected so the polling logic can be tested without a
  /// window server.
  WindowGeometryWatcher({
    required this.capture,
    required this.persist,
    this.interval = const Duration(seconds: 1),
  });

  /// Reads the current state of every window worth persisting.
  final List<WindowGeometrySnapshot> Function() capture;

  /// Writes one settled snapshot to wherever it belongs.
  final void Function(WindowGeometrySnapshot snapshot) persist;

  /// How often window geometry is sampled.
  final Duration interval;

  /// Last tick's snapshot per window title — the "has it stopped moving?"
  /// comparison.
  final Map<String, WindowGeometrySnapshot> _lastSeen = {};

  /// What has already been handed to [persist], so an idle app does no work.
  /// Keyed by title rather than window id on purpose: it stays valid across a
  /// HUD being closed and re-opened, since the preference it guards is the
  /// same one.
  final Map<String, WindowGeometrySnapshot> _lastPersisted = {};

  Timer? _timer;

  /// Begins sampling. Safe to call more than once; the previous timer is
  /// replaced.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void _tick() {
    final snapshots = capture();
    final seen = <String, WindowGeometrySnapshot>{};
    for (final snapshot in snapshots) {
      seen[snapshot.title] = snapshot;
      if (_lastSeen[snapshot.title] != snapshot) {
        // Still in motion (or newly appeared) — wait for it to hold still.
        continue;
      }
      _persistIfChanged(snapshot);
    }
    _lastSeen
      ..clear()
      ..addAll(seen);
  }

  /// Persists whatever the windows look like right now, without waiting for
  /// them to settle.
  ///
  /// This is the quit path: the app is about to exit, so a move made in the
  /// last [interval] has no later tick to catch it. The state guards in the
  /// persist callback still apply, so quitting while minimized or full screen
  /// does not overwrite the saved normal frame.
  void flushNow() {
    for (final snapshot in capture()) {
      _lastSeen[snapshot.title] = snapshot;
      _persistIfChanged(snapshot);
    }
  }

  void _persistIfChanged(WindowGeometrySnapshot snapshot) {
    if (_lastPersisted[snapshot.title] == snapshot) {
      return;
    }
    persist(snapshot);
    _lastPersisted[snapshot.title] = snapshot;
  }

  /// Stops sampling. The watcher can be restarted with [start].
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
