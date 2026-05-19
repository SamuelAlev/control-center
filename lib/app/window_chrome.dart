import 'dart:async';

import 'package:control_center/app/window_geometry_watcher.dart';
import 'package:control_center/app/window_placement.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/widgets.dart'
    show Color, Offset, Rect, Size, visibleForTesting;
import 'package:nativeapi/nativeapi.dart'
    show DisplayManager, TitleBarStyle, Window, WindowManager;

/// OS window titles. These double as the routing key in [styleWindowOnShow] /
/// [persistWindowSnapshot] — the windowing layer matches on title to apply the
/// right chrome and persist to the right prefs keys. Set via each window's
/// `WindowController(title: ...)`.
const String primaryWindowTitle = 'Control Center';

/// Title of the transient pre-app server-setup window. Intentionally DISTINCT
/// from [primaryWindowTitle] so the window-chrome hooks keyed on title
/// ([styleWindowOnShow] / [persistWindowSnapshot]) do not treat it as the
/// primary window: it must not inherit the hidden-title-bar / transparent
/// chrome (it needs an ordinary movable frame) and — critically — its geometry
/// must never be persisted over the real primary window's saved size/position.
const String serverSetupWindowTitle = 'Control Center setup';

/// Title of the last-resort window shown when the bootstrap itself failed.
///
/// DISTINCT from [primaryWindowTitle] for the same reason
/// [serverSetupWindowTitle] is. It used to be the very same string, which
/// silently routed it down the primary window's branch: it came up with no
/// title bar and `isMovable = false` — unmovable, since it has none of the
/// app's own title-bar chrome to drag by — wearing the main window's saved
/// geometry, and [persistWindowSnapshot] would now write its small frame back
/// as the main window's remembered size.
const String bootFailureWindowTitle = 'Control Center startup error';

/// Title of the floating focus-pill HUD window.
const String focusPillWindowTitle = 'Focus \\\\ Control Center';

/// Title of the meeting-recording toolbar HUD window.
const String meetingToolbarWindowTitle = 'Recording \\\\ Control Center';

/// Title of the floating soundscape mini-player HUD window.
const String soundscapeMiniPlayerWindowTitle = 'Soundscape \\\\ Control Center';

/// Fixed content size of the floating focus pill HUD. Matches the meeting
/// toolbar's height so the two HUDs read as siblings rather than one dwarfing
/// the other.
const Size focusPillSize = Size(420, 52);

/// Fixed content size of the floating meeting-recording toolbar HUD.
const Size meetingToolbarSize = Size(380, 52);

/// Fixed content size of the floating soundscape mini-player HUD.
const Size soundscapeMiniPlayerSize = Size(300, 52);

const String _windowXKey = 'window_x';
const String _windowYKey = 'window_y';
const String _windowWKey = 'window_w';
const String _windowHKey = 'window_h';
const String _windowMaximizedKey = 'window_maximized';
const String _windowFullscreenKey = 'window_fullscreen';
const String _pillXKey = 'focus_mode_pill_x';
const String _pillYKey = 'focus_mode_pill_y';
const String _toolbarXKey = 'meeting_toolbar_x';
const String _toolbarYKey = 'meeting_toolbar_y';
const String _soundscapeXKey = 'soundscape_hud_x';
const String _soundscapeYKey = 'soundscape_hud_y';

/// Windows whose saved geometry has already been applied this session, by
/// native window id.
///
/// [dressKnownWindows] re-styles EVERY known window on EVERY show (it has to —
/// a window cannot be identified on its own first show), and styling is
/// idempotent for chrome but emphatically not for position: without this latch,
/// opening the meeting toolbar would yank a focus pill the operator had just
/// dragged back to wherever it was saved, and re-apply the main window's
/// startup frame on top of a window they had since resized.
///
/// Keyed on `Window.id`, which on macOS is the NSWindow's `windowNumber` — a
/// per-session number that is never reused — so a HUD that is destroyed and
/// re-created (its provider flipped off and on) is a NEW window and correctly
/// restores its position again.
final Set<int> _geometryRestoredWindowIds = <int>{};

/// Forgets which windows have had their geometry restored, so a test can drive
/// [styleWindowOnShow] more than once.
@visibleForTesting
void resetWindowGeometryRestoreLatch() => _geometryRestoredWindowIds.clear();

/// Whether [title] names a window that IS the app, as opposed to a floating
/// HUD: the primary window, the transient pre-app setup window, or the
/// boot-failure window.
///
/// The HUDs are deliberately excluded — they are always-on-top, non-focusable
/// bars designed to stay up while the operator works inside ANOTHER app, so
/// one being on screen says nothing about whether this app is.
///
/// The boot-failure window belongs here even though it is not the app proper:
/// it is subject to the same launch-time black-window problem the visibility
/// guard exists to repair, and it is the one surface where an unpainted frame
/// costs the operator the error message itself.
bool isMainWindowTitle(String? title) =>
    title == primaryWindowTitle ||
    title == serverSetupWindowTitle ||
    title == bootFailureWindowTitle;

const Offset _defaultPillPosition = Offset(700, 30);
const Offset _defaultToolbarPosition = Offset(640, 72);
const Offset _defaultSoundscapePosition = Offset(700, 114);
const Color _transparent = Color(0x00000000);

/// How long after a window is shown its saved full-screen state is re-entered.
///
/// `toggleFullScreen:` on a window the window server has only just put up
/// (we are inside the microtask that follows its very first show) is ignored
/// often enough to matter, and a swallowed toggle would leave the operator in
/// a normal window with no clue why. A short beat lets launch activation
/// settle first; the cost is seeing the window at its normal size for a moment
/// before it animates out, which is what macOS's own state restoration looks
/// like.
const Duration _fullScreenRestoreDelay = Duration(milliseconds: 300);

/// Applies a window's chrome the moment it is about to show (called from
/// `WindowManager.setWillShowHook`). The primary window restores its persisted
/// geometry and hides its title bar (the app draws its own); the two HUDs become
/// fixed-size, frameless, transparent, always-on-top bars at their saved spot.
void styleWindowOnShow(Window window, AppPreferences prefs) {
  switch (window.title) {
    case primaryWindowTitle:
      window.titleBarStyle = TitleBarStyle.hidden;
      window.backgroundColor = _transparent;
      // macOS drags the window ITSELF from the titlebar region — the strip our
      // own title bar draws into, once the style above puts the content under
      // a transparent titlebar. That is why pressing the sidebar toggle,
      // back/forward, a breadcrumb or a popover trigger and moving a few
      // pixels walked the whole window: AppKit starts that drag before Dart
      // sees the event, so no `WindowDragArea` guard can refuse it, and it is
      // not the view's `mouseDownCanMoveWindow` either (overriding that on
      // FlutterView changed nothing).
      //
      // `setMovable:NO` is the switch that reaches it: it "will disable
      // server-side dragging of the window via titlebar or background"
      // (NSWindow.h). It takes the app's own deliberate drag with it —
      // `performWindowDragWithEvent:` is server-side too — so the title bar
      // moves the window itself (`WindowDragArea.moveWindowManually`). The
      // window can still be resized and moved programmatically, which is what
      // restoring geometry and double-click-to-zoom need.
      window.isMovable = false;
      if (_geometryRestoredWindowIds.add(window.id)) {
        _restoreMainWindowGeometry(window, prefs);
      }
    case bootFailureWindowTitle:
      // Keeps its ordinary movable frame (it draws no title bar of its own),
      // but put it where the operator is looking rather than wherever macOS
      // cascades a new window.
      if (_geometryRestoredWindowIds.add(window.id)) {
        window.center();
      }
    case focusPillWindowTitle:
      _styleHud(
        window,
        focusPillSize,
        () => _hudPosition(
          prefs,
          _pillXKey,
          _pillYKey,
          _defaultPillPosition,
          focusPillSize,
        ),
      );
    case meetingToolbarWindowTitle:
      _styleHud(
        window,
        meetingToolbarSize,
        () => _hudPosition(
          prefs,
          _toolbarXKey,
          _toolbarYKey,
          _defaultToolbarPosition,
          meetingToolbarSize,
        ),
      );
    case soundscapeMiniPlayerWindowTitle:
      _styleHud(
        window,
        soundscapeMiniPlayerSize,
        () => _hudPosition(
          prefs,
          _soundscapeXKey,
          _soundscapeYKey,
          _defaultSoundscapePosition,
          soundscapeMiniPlayerSize,
        ),
      );
  }
}

/// Applies [styleWindowOnShow] to every window this app recognises, and calls
/// [onMainWindow] for each main (non-HUD) one.
///
/// This exists because a window's title is not set when it is first shown.
/// Flutter's `WindowControllerMacOS` calls `createWindow` — which creates the
/// `NSWindow` AND calls `makeKeyAndOrderFront:` on it, the very call that
/// invokes the will-show hook — and only applies `setTitle` after that returns
/// (see `_window_macos.dart`). So the hook's own pass runs against an untitled
/// window, [styleWindowOnShow]'s title switch matches nothing, and the window
/// arrives wearing the stock macOS title bar instead of the app's own chrome.
///
/// Running this from a microtask scheduled inside the hook is what fixes it:
/// the title is applied in the same synchronous turn that created the window,
/// so by the time the microtask runs every window can be identified. Styling
/// is idempotent, so re-dressing an already-correct window costs nothing.
void dressKnownWindows(
  WindowManager manager,
  AppPreferences prefs, {
  void Function(Window window)? onMainWindow,
}) {
  final windows = manager.getAll();
  // Drop closed windows from the restore latch so it cannot grow for the life
  // of the process as HUDs are toggled on and off.
  _geometryRestoredWindowIds.retainAll(<int>{
    for (final window in windows) window.id,
  });
  for (final window in windows) {
    styleWindowOnShow(window, prefs);
    if (isMainWindowTitle(window.title)) {
      onMainWindow?.call(window);
    }
  }
}

/// Places the main window where the operator left it — on a display that still
/// exists, at a size that fits it.
///
/// The saved frame describes a display arrangement that may be gone: restoring
/// `(3200, 400, 2560x1440)` verbatim after the external monitor was unplugged
/// puts the window somewhere unreachable, with no title bar on screen to drag
/// it back by. [resolveMainWindowBounds] answers with a frame that is always
/// on a live display; see there for the rules.
void _restoreMainWindowGeometry(Window window, AppPreferences prefs) {
  final saved = _readSavedBounds(prefs);
  final layout = _readDisplayLayout();
  final primaryWorkArea = layout.primary;
  if (primaryWorkArea == null) {
    // No display we can measure (a work area of 0x0 is what nativeapi returns
    // for a screen it could not resolve). Restoring blind is still better than
    // dropping the window at the OS default, but there is nothing to clamp to.
    if (saved != null) {
      window.setSize(saved.size, false);
      window.position = saved.topLeft;
    } else {
      window.center();
    }
    return;
  }
  // One `setFrame:` rather than a size call followed by a position call: on
  // macOS setting the position converts the top-left origin using the window's
  // CURRENT height, so the pair has to run in that order and briefly puts the
  // window somewhere neither value asked for.
  window.bounds = resolveMainWindowBounds(
    saved: saved,
    workAreas: layout.workAreas,
    primaryWorkArea: primaryWorkArea,
  );
  // Full screen is restored INSTEAD of maximized, never both: `isZoomed`
  // reports true for a full-screen window, so a session that ended full screen
  // has both flags' worth of truth in it and the more specific one wins.
  if (prefs.getBool(_windowFullscreenKey) ?? false) {
    _restoreFullScreenLater(window.id);
    return;
  }
  if (prefs.getBool(_windowMaximizedKey) ?? false) {
    // Bounds first, then zoom: AppKit remembers the pre-zoom frame, so leaving
    // full-window mode later lands on the frame we just restored rather than
    // on whatever macOS would have guessed.
    window.maximize();
  }
}

void _restoreFullScreenLater(int windowId) {
  Timer(_fullScreenRestoreDelay, () {
    // Re-resolve rather than capturing the Window: the app may have quit, or
    // the operator may have got there first.
    final window = WindowManager.instance.get(windowId);
    if (window == null || !window.isVisible || window.isFullScreen) {
      return;
    }
    window.isFullScreen = true;
  });
}

/// The current displays' usable areas (menu bar and Dock excluded), and which
/// of them is the primary one.
///
/// Every rect shares one global top-left coordinate space with window frames —
/// nativeapi converts both through the same primary-screen-height flip — so
/// displays left of or above the primary have negative coordinates and can be
/// compared with a window's bounds directly.
({List<Rect> workAreas, Rect? primary}) _readDisplayLayout() {
  final workAreas = <Rect>[];
  Rect? primary;
  for (final display in DisplayManager.instance.getAll()) {
    final workArea = display.workArea;
    if (workArea.isEmpty) {
      continue;
    }
    workAreas.add(workArea);
    if (primary == null && display.isPrimary) {
      primary = workArea;
    }
  }
  return (
    workAreas: workAreas,
    primary: primary ?? (workAreas.isEmpty ? null : workAreas.first),
  );
}

Rect? _readSavedBounds(AppPreferences prefs) {
  final x = prefs.getDouble(_windowXKey);
  final y = prefs.getDouble(_windowYKey);
  final w = prefs.getDouble(_windowWKey);
  final h = prefs.getDouble(_windowHKey);
  if (x == null || y == null || w == null || h == null) {
    return null;
  }
  return Rect.fromLTWH(x, y, w, h);
}

void _styleHud(Window window, Size size, Offset Function() resolvePosition) {
  window.setSize(size, false);
  // Lock the size: min == max plus non-resizable, since min==max alone still
  // leaves macOS resize handles that stick once dragged.
  window.minimumSize = size;
  window.maximumSize = size;
  window.isResizable = false;
  window.titleBarStyle = TitleBarStyle.hidden;
  window.isWindowControlButtonsVisible = false;
  window.isAlwaysOnTop = true;
  window.backgroundColor = _transparent;
  // The HUDs are mouse-only (drag + buttons / hold-to-stop). Mark them
  // non-focusable so they never become the key window — otherwise, sharing one
  // engine with the main window, the HUD steals keyboard focus on show and text
  // input in the main app dies (macOS beeps, since the HUD has no text field).
  window.isFocusable = false;
  // Position is restored once per window, not on every re-dress — see
  // [_geometryRestoredWindowIds]. Resolving it is deferred behind the latch so
  // a re-dress does not read preferences and enumerate displays for an answer
  // it would throw away.
  if (_geometryRestoredWindowIds.add(window.id)) {
    window.position = resolvePosition();
  }
}

Offset _hudPosition(
  AppPreferences prefs,
  String xKey,
  String yKey,
  Offset fallback,
  Size hudSize,
) {
  final x = prefs.getDouble(xKey);
  final y = prefs.getDouble(yKey);
  final saved = (x != null && y != null) ? Offset(x, y) : null;
  final layout = _readDisplayLayout();
  final primaryWorkArea = layout.primary;
  if (primaryWorkArea == null) {
    return saved ?? fallback;
  }
  return resolveHudPosition(
    saved: saved,
    fallback: fallback,
    hudSize: hudSize,
    workAreas: layout.workAreas,
    primaryWorkArea: primaryWorkArea,
  );
}

/// Brings the primary application window to the front (show + focus). Used when
/// returning from a HUD (e.g. expanding the focus pill, stopping a recording).
void focusPrimaryWindow() {
  for (final window in WindowManager.instance.getAll()) {
    if (window.title == primaryWindowTitle) {
      window
        ..show()
        ..focus();
      return;
    }
  }
}

/// Writes [snapshot] to the preference keys its window owns, keyed by title.
/// Driven by [WindowGeometryWatcher]; a title this app does not persist (the
/// pre-app setup window, anything else) falls through and writes nothing.
///
/// The main window's `window_x/y/w/h` always hold its NORMAL frame. A
/// maximized or full-screen frame is recorded as a flag instead, never as
/// bounds: writing the zoomed size would mean un-zooming after a relaunch
/// restores a window the size of the display, and the operator would have lost
/// the frame they actually chose. Order matters — a full-screen window reports
/// `isZoomed` as true as well, so full screen is tested first.
void persistWindowSnapshot(
  AppPreferences prefs,
  WindowGeometrySnapshot snapshot,
) {
  final position = snapshot.bounds.topLeft;
  switch (snapshot.title) {
    case primaryWindowTitle:
      if (snapshot.isMinimized) {
        // A minimized window's frame is not where the operator put it.
        return;
      }
      if (snapshot.isFullScreen) {
        prefs.setBool(_windowFullscreenKey, value: true);
        return;
      }
      if (snapshot.isMaximized) {
        prefs.setBool(_windowMaximizedKey, value: true);
        prefs.setBool(_windowFullscreenKey, value: false);
        return;
      }
      prefs.setDouble(_windowXKey, position.dx);
      prefs.setDouble(_windowYKey, position.dy);
      prefs.setDouble(_windowWKey, snapshot.bounds.width);
      prefs.setDouble(_windowHKey, snapshot.bounds.height);
      prefs.setBool(_windowMaximizedKey, value: false);
      prefs.setBool(_windowFullscreenKey, value: false);
    case focusPillWindowTitle:
      _persistHudPosition(prefs, snapshot, _pillXKey, _pillYKey);
    case meetingToolbarWindowTitle:
      _persistHudPosition(prefs, snapshot, _toolbarXKey, _toolbarYKey);
    case soundscapeMiniPlayerWindowTitle:
      _persistHudPosition(prefs, snapshot, _soundscapeXKey, _soundscapeYKey);
  }
}

void _persistHudPosition(
  AppPreferences prefs,
  WindowGeometrySnapshot snapshot,
  String xKey,
  String yKey,
) {
  if (snapshot.isMinimized) {
    return;
  }
  prefs.setDouble(xKey, snapshot.bounds.left);
  prefs.setDouble(yKey, snapshot.bounds.top);
}
