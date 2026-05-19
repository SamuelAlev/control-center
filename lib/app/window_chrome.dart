import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/widgets.dart' show Color, Offset, Size;
import 'package:nativeapi/nativeapi.dart' show TitleBarStyle, Window, WindowManager;

/// OS window titles. These double as the routing key in [styleWindowOnShow] /
/// [persistWindowGeometry] — the windowing layer matches on title to apply the
/// right chrome and persist to the right prefs keys. Set via each window's
/// `RegularWindowController(title: ...)`.
const String primaryWindowTitle = 'Control Center';
const String focusPillWindowTitle = 'Control Center · Focus';
const String meetingToolbarWindowTitle = 'Control Center · Recording';

/// Fixed content size of the floating focus pill HUD. Matches the meeting
/// toolbar's height so the two HUDs read as siblings rather than one dwarfing
/// the other.
const Size focusPillSize = Size(420, 52);

/// Fixed content size of the floating meeting-recording toolbar HUD.
const Size meetingToolbarSize = Size(380, 52);

const String _windowXKey = 'window_x';
const String _windowYKey = 'window_y';
const String _windowWKey = 'window_w';
const String _windowHKey = 'window_h';
const String _pillXKey = 'focus_mode_pill_x';
const String _pillYKey = 'focus_mode_pill_y';
const String _toolbarXKey = 'meeting_toolbar_x';
const String _toolbarYKey = 'meeting_toolbar_y';

const Offset _defaultPillPosition = Offset(700, 30);
const Offset _defaultToolbarPosition = Offset(640, 72);
const Color _transparent = Color(0x00000000);

/// Applies a window's chrome the moment it is about to show (called from
/// `WindowManager.setWillShowHook`). The primary window restores its persisted
/// geometry and hides its title bar (the app draws its own); the two HUDs become
/// fixed-size, frameless, transparent, always-on-top bars at their saved spot.
void styleWindowOnShow(Window window, AppPreferences prefs) {
  switch (window.title) {
    case primaryWindowTitle:
      window.titleBarStyle = TitleBarStyle.hidden;
      window.backgroundColor = _transparent;
      final w = prefs.getDouble(_windowWKey);
      final h = prefs.getDouble(_windowHKey);
      if (w != null && h != null) {
        window.setSize(w, h);
      }
      final x = prefs.getDouble(_windowXKey);
      final y = prefs.getDouble(_windowYKey);
      if (x != null && y != null) {
        window.setPosition(x, y);
      } else {
        window.center();
      }
    case focusPillWindowTitle:
      _styleHud(
        window,
        focusPillSize,
        _readPosition(prefs, _pillXKey, _pillYKey, _defaultPillPosition),
      );
    case meetingToolbarWindowTitle:
      _styleHud(
        window,
        meetingToolbarSize,
        _readPosition(prefs, _toolbarXKey, _toolbarYKey, _defaultToolbarPosition),
      );
  }
}

void _styleHud(Window window, Size size, Offset position) {
  window.setSize(size.width, size.height);
  // Lock the size: min == max plus non-resizable, since min==max alone still
  // leaves macOS resize handles that stick once dragged.
  window.setMinimumSize(size.width, size.height);
  window.setMaximumSize(size.width, size.height);
  window.isResizable = false;
  window.titleBarStyle = TitleBarStyle.hidden;
  window.windowControlButtonsVisible = false;
  window.isAlwaysOnTop = true;
  window.backgroundColor = _transparent;
  // The HUDs are mouse-only (drag + buttons / hold-to-stop). Mark them
  // non-focusable so they never become the key window — otherwise, sharing one
  // engine with the main window, the HUD steals keyboard focus on show and text
  // input in the main app dies (macOS beeps, since the HUD has no text field).
  window.isFocusable = false;
  window.setPosition(position.dx, position.dy);
}

Offset _readPosition(
  AppPreferences prefs,
  String xKey,
  String yKey,
  Offset fallback,
) {
  final x = prefs.getDouble(xKey);
  final y = prefs.getDouble(yKey);
  return (x != null && y != null) ? Offset(x, y) : fallback;
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

/// Persists the geometry of the window identified by [windowId] (resolved via
/// [wm]) on move/resize, keyed by its title. Wired to `WindowMovedEvent` /
/// `WindowResizedEvent`. Replaces the old per-HUD position IPC and the main
/// window's `WindowListener`.
void persistWindowGeometry(WindowManager wm, AppPreferences prefs, int windowId) {
  final window = wm.getById(windowId);
  if (window == null) {
    return;
  }
  final pos = window.position;
  switch (window.title) {
    case primaryWindowTitle:
      final size = window.size;
      prefs.setDouble(_windowXKey, pos.dx);
      prefs.setDouble(_windowYKey, pos.dy);
      prefs.setDouble(_windowWKey, size.width);
      prefs.setDouble(_windowHKey, size.height);
    case focusPillWindowTitle:
      prefs.setDouble(_pillXKey, pos.dx);
      prefs.setDouble(_pillYKey, pos.dy);
    case meetingToolbarWindowTitle:
      prefs.setDouble(_toolbarXKey, pos.dx);
      prefs.setDouble(_toolbarYKey, pos.dy);
  }
}
