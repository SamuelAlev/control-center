import 'package:flutter/foundation.dart';
import 'package:nativeapi_flutter/nativeapi_flutter.dart'
    as nativeapi
    show Window;

/// The primary window's hidden-in-the-tray state, and the only way in and
/// out of it.
///
/// Closing the main window with "keep running" set orders it out instead of
/// destroying it: the engine, the server connection and the notifications
/// stay alive, and the window comes back exactly as it was. Process-wide like
/// the window itself, which survives every server switch.
///
/// The window is reached through its own controller's native handle
/// ([attach]), not by enumerating windows: Windows only lists visible ones,
/// and a hidden window is precisely the one this has to find again.
class MainWindowVisibility {
  MainWindowVisibility._();

  /// The process-wide instance.
  static final MainWindowVisibility instance = MainWindowVisibility._();

  nativeapi.Window? Function()? _resolve;
  final ValueNotifier<bool> _hidden = ValueNotifier(false);
  bool _startingHidden = false;

  /// Decides what a close request does; see `DesktopShell.closeInterceptor`.
  bool Function()? closeInterceptor;

  /// Whether the main window is hidden in the tray.
  ValueListenable<bool> get hidden => _hidden;

  /// Whether the app is still starting hidden: a login launch the operator
  /// asked to stay in the tray. The will-show hook refuses to show the main
  /// window until [reveal] ends this.
  bool get startingHidden => _startingHidden;

  /// Whether a primary window is registered.
  bool get attached => _resolve != null;

  /// Registers how to reach the primary window. [resolve] wraps the window
  /// controller's native handle in a fresh `nativeapi.Window` the caller
  /// disposes; it returns null once that window is gone.
  ///
  /// A new primary window (after the setup window replaced the app) starts
  /// visible unless the launch is still starting hidden.
  void attach(nativeapi.Window? Function() resolve) {
    _resolve = resolve;
    _hidden.value = _startingHidden;
  }

  /// Forgets the primary window (it is being destroyed).
  void detach(nativeapi.Window? Function() resolve) {
    // Tear-offs of one method on one object compare equal, not identical.
    if (_resolve == resolve) {
      _resolve = null;
    }
  }

  /// Asks the close interceptor; true when it handled the close.
  bool interceptClose() => closeInterceptor?.call() ?? false;

  /// Starts the app with its main window hidden. Call before the window is
  /// first shown.
  void startHidden() {
    _startingHidden = true;
    _hidden.value = true;
  }

  /// Records that the main window was shown by something other than
  /// [reveal] (the engine's first frame, the window menu), so the state never
  /// claims a visible window is hidden.
  void noteShown() {
    if (!_startingHidden) {
      _hidden.value = false;
    }
  }

  /// Orders the main window out.
  void hide() {
    _withWindow((window) => window.hide());
    _hidden.value = true;
  }

  /// Shows the main window again: restored if minimized, in front, focused.
  void reveal() {
    _startingHidden = false;
    _withWindow((window) {
      if (window.isMinimized) {
        window.restore();
      }
      window
        ..show()
        ..focus();
    });
    _hidden.value = false;
  }

  void _withWindow(void Function(nativeapi.Window window) action) {
    final window = _resolve?.call();
    if (window == null) {
      return;
    }
    try {
      action(window);
    } finally {
      window.dispose();
    }
  }
}
