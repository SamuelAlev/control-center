import 'dart:async';

import 'package:control_center/app/window_chrome.dart' show isMainWindowTitle;
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:nativeapi_flutter/nativeapi_flutter.dart'
    show SizeToNative, WindowManager;

/// The one window a nudge resizes, re-resolved on every access.
abstract interface class NudgeWindow {
  /// Whether the window still exists.
  bool get isOpen;

  /// The window's content size, in logical pixels.
  Size get contentSize;

  /// Resizes the content. A no-op once the window is gone.
  set contentSize(Size value);
}

/// Performs the real 1px out-and-back resize the visibility guard relies on.
///
/// Dart `resumed` cannot clear the engine's AppKit occlusion latch; a resize
/// does, and `handleMetricsChanged` forces a frame past `framesEnabled`.
///
/// Every resize waits for a safe moment, because on macOS setting the content
/// size is not a plain setter: `FlutterView setFrameSize:` blocks the main
/// thread in `ResizeSynchronizer.beginResize` for up to a second, until a frame
/// AT THE NEW SIZE is committed, and keeps running Dart timers while it waits.
/// Two shapes turned that into a 2-second "App Hanging" report:
///
/// * Resizing mid-frame. The setup → primary handoff destroys the setup window
///   from a post-frame callback; the destroy spins the run loop, which runs the
///   will-show hook's microtask and its nudge. No new frame can start while the
///   current one is still on the stack, so the wait always hits its timeout.
/// * Resizing inside another resize. The restore timer fired inside that
///   one-second wait and resized again, starting a second wait that also could
///   not finish.
///
/// So a resize runs only while the scheduler is idle and no other resize of
/// ours is on the stack; otherwise it retries a moment later. One nudge is in
/// flight at a time, from the grow through the restore, so two nudges can never
/// capture different baselines and leave the window permanently 1px wider.
class MainWindowNudger {
  /// Creates a nudger.
  ///
  /// `findTarget` returns the main window to nudge, or null when none is
  /// visible, restored and windowed. [canResize] answers whether a resize may
  /// run right now; it defaults to "the scheduler is idle".
  MainWindowNudger({
    required this._findTarget,
    bool Function()? canResize,
  }) : _canResize = canResize ?? _schedulerIdle;

  final NudgeWindow? Function() _findTarget;
  final bool Function() _canResize;

  bool _inFlight = false;
  bool _resizing = false;

  /// How long a nudge holds its +1px size before restoring it.
  ///
  /// An out-and-back issued within a single Dart turn can be a complete no-op:
  /// the engine may coalesce the two metric updates into "nothing changed",
  /// and the window server may never flush the intermediate size. Holding the
  /// new size for a beat makes the resize real (metrics delivered, occlusion
  /// recomputed) before the restore, at a duration the eye cannot see. It also
  /// cannot be persisted by the geometry watcher, which only writes a frame
  /// two of its one-second polls agree on.
  static const Duration holdDuration = Duration(milliseconds: 120);

  /// How long a resize that could not run safely waits before trying again.
  static const Duration retryDelay = Duration(milliseconds: 16);

  /// Starts a nudge and returns whether a window was found to nudge.
  ///
  /// Returns true without starting another while a nudge is already in flight:
  /// `dressKnownWindows` reports every main window on every show, so one hook
  /// can reach here several times in a row.
  bool nudge() {
    if (_inFlight) {
      return true;
    }
    final target = _findTarget();
    if (target == null) {
      return false;
    }
    _inFlight = true;
    _whenSafe(() {
      if (!target.isOpen) {
        _inFlight = false;
        return;
      }
      final baseline = target.contentSize;
      _resize(target, Size(baseline.width + 1, baseline.height));
      Timer(holdDuration, () {
        _whenSafe(() {
          try {
            if (target.isOpen) {
              _resize(target, baseline);
            }
          } finally {
            _inFlight = false;
          }
        });
      });
    });
    return true;
  }

  void _whenSafe(void Function() action) {
    if (_resizing || !_canResize()) {
      Timer(retryDelay, () => _whenSafe(action));
      return;
    }
    action();
  }

  void _resize(NudgeWindow target, Size size) {
    _resizing = true;
    try {
      target.contentSize = size;
    } finally {
      _resizing = false;
    }
  }

  static bool _schedulerIdle() =>
      SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle;
}

/// The process-wide nudger over the app's real main windows.
final MainWindowNudger mainWindowNudger = MainWindowNudger(
  findTarget: _findNativeMainWindow,
);

/// The first main window that is visible, not minimized and not full screen.
NudgeWindow? _findNativeMainWindow() {
  for (final window in WindowManager.instance.getAll()) {
    if (!isMainWindowTitle(window.title)) {
      continue;
    }
    if (!window.isVisible || window.isMinimized || window.isFullScreen) {
      continue;
    }
    return _NativeNudgeWindow(window.id);
  }
  return null;
}

class _NativeNudgeWindow implements NudgeWindow {
  _NativeNudgeWindow(this._id);

  final int _id;

  @override
  bool get isOpen => WindowManager.instance.get(_id) != null;

  @override
  Size get contentSize {
    final size = WindowManager.instance.get(_id)?.contentSize;
    return size == null ? Size.zero : Size(size.width, size.height);
  }

  @override
  set contentSize(Size value) {
    WindowManager.instance.get(_id)?.contentSize = value.toNative();
  }
}
