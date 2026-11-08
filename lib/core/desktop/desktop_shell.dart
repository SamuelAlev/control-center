/// The desktop process's shell: its tray (menu bar) icon, the main window's
/// hidden-in-the-tray state and launch at login.
///
/// A port, not an implementation. The native one (`lib/app/tray/`) reaches
/// nativeapi and the runners' app channel, which the web build must never
/// import; features talk to this interface through `desktopShellProvider`,
/// which defaults to [UnsupportedDesktopShell] everywhere the desktop
/// bootstrap does not override it (web, tests, previews).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

/// Which variant of the tray glyph is showing.
enum TrayIconTone {
  /// Connected, nothing waiting on the operator.
  normal,

  /// Something waits on the operator: an agent question or an approval.
  attention,

  /// The connection to the server is down.
  offline,
}

/// What the tray icon shows. Compared by value so an unchanged spec is never
/// pushed to the platform again.
@immutable
class TrayIconSpec {
  /// Creates a [TrayIconSpec].
  const TrayIconSpec({required this.tone, required this.tooltip, this.badge});

  /// The glyph variant.
  final TrayIconTone tone;

  /// Hover text (Windows and Linux hosts; macOS shows it too).
  final String tooltip;

  /// Short text beside the glyph, such as the count of waiting items. Only
  /// macOS draws a title next to a status item; elsewhere this is ignored.
  final String? badge;

  @override
  bool operator ==(Object other) =>
      other is TrayIconSpec &&
      other.tone == tone &&
      other.tooltip == tooltip &&
      other.badge == badge;

  @override
  int get hashCode => Object.hash(tone, tooltip, badge);
}

/// One line of the tray icon's native context menu.
@immutable
sealed class TrayMenuEntry {
  const TrayMenuEntry();
}

/// A selectable line. Selecting it reports [id] on
/// [DesktopShell.trayMenuSelections].
final class TrayMenuAction extends TrayMenuEntry {
  /// Creates a [TrayMenuAction].
  const TrayMenuAction({required this.id, required this.label});

  /// Stable identifier reported when the line is selected.
  final String id;

  /// The visible label.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is TrayMenuAction && other.id == id && other.label == label;

  @override
  int get hashCode => Object.hash(id, label);
}

/// A disabled, informational line (a status summary).
final class TrayMenuCaption extends TrayMenuEntry {
  /// Creates a [TrayMenuCaption].
  const TrayMenuCaption(this.label);

  /// The visible text.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is TrayMenuCaption && other.label == label;

  @override
  int get hashCode => label.hashCode;
}

/// A divider between groups of lines.
final class TrayMenuSeparator extends TrayMenuEntry {
  /// Creates a [TrayMenuSeparator].
  const TrayMenuSeparator();

  @override
  bool operator ==(Object other) => other is TrayMenuSeparator;

  @override
  int get hashCode => (TrayMenuSeparator).hashCode;
}

/// A pointer gesture on the tray icon itself (not on its menu).
enum TrayPointerEvent {
  /// A primary click.
  primary,

  /// A secondary click on a host that does not show the menu by itself.
  secondary,

  /// A double click (Windows; Linux hosts that report one).
  double,
}

/// Whether a tray icon can be seen at all on this desktop.
enum TrayHostState {
  /// An icon placed in the tray will be visible.
  available,

  /// The platform has trays, but this session shows none: a Linux desktop
  /// without a StatusNotifierItem host (stock GNOME without the AppIndicator
  /// extension). An icon placed now would be invisible.
  missing,

  /// This build has no tray at all (web, tests).
  unsupported,
}

/// What the operating system says about launching the app at login.
enum LaunchAtLoginState {
  /// Registered and allowed to run.
  enabled,

  /// Not registered, or disabled from the system's own settings.
  disabled,

  /// This platform or build cannot register the app.
  unsupported,
}

/// The desktop shell features drive. See the library comment.
abstract interface class DesktopShell {
  /// Whether this process has a tray to put an icon in.
  bool get traySupported;

  /// Whether an icon placed in the tray would be visible. Linux settles this
  /// asynchronously, so it starts [TrayHostState.available] and may change.
  ValueListenable<TrayHostState> get trayHost;

  /// Shows (or updates) the tray icon and its native context menu. Calls with
  /// an unchanged [spec] or [menu] do not reach the platform.
  void setTrayIcon(TrayIconSpec spec, List<TrayMenuEntry> menu);

  /// Removes the tray icon.
  void removeTrayIcon();

  /// Pointer gestures on the tray icon.
  Stream<TrayPointerEvent> get trayEvents;

  /// The [TrayMenuAction.id] of each selected context-menu line.
  Stream<String> get trayMenuSelections;

  /// Whether the main window is currently hidden in the tray.
  ValueListenable<bool> get mainWindowHidden;

  /// Hides the main window. The app keeps running; [revealMainWindow] or a
  /// relaunch brings it back.
  void hideMainWindow();

  /// Shows the main window again, restored and focused.
  void revealMainWindow();

  /// Decides what closing the main window does: returns true when it took
  /// care of the close (hid the window, or is asking), false to quit as
  /// before. Null restores quitting on close.
  set closeInterceptor(bool Function()? interceptor);

  /// Quits the app the same way the window's close used to.
  void quit();

  /// Whether this process was started by the login launch.
  bool get launchedAtLogin;

  /// Reads the login-launch registration from the operating system. The
  /// user can change it outside the app, so it is read rather than cached.
  LaunchAtLoginState readLaunchAtLogin();

  /// Registers or unregisters the login launch. Returns whether the system
  /// now reports the requested state.
  bool setLaunchAtLogin({required bool enabled});
}

/// The shell of a build with no desktop integration: web, tests, previews.
///
/// Every query answers "not here" and every command does nothing, so a
/// feature built on [DesktopShell] needs no platform checks of its own.
class UnsupportedDesktopShell implements DesktopShell {
  /// Creates an [UnsupportedDesktopShell].
  UnsupportedDesktopShell();

  final ValueNotifier<TrayHostState> _trayHost = ValueNotifier(
    TrayHostState.unsupported,
  );
  final ValueNotifier<bool> _hidden = ValueNotifier(false);

  @override
  bool get traySupported => false;

  @override
  ValueListenable<TrayHostState> get trayHost => _trayHost;

  @override
  void setTrayIcon(TrayIconSpec spec, List<TrayMenuEntry> menu) {}

  @override
  void removeTrayIcon() {}

  @override
  Stream<TrayPointerEvent> get trayEvents => const Stream.empty();

  @override
  Stream<String> get trayMenuSelections => const Stream.empty();

  @override
  ValueListenable<bool> get mainWindowHidden => _hidden;

  @override
  void hideMainWindow() {}

  @override
  void revealMainWindow() {}

  @override
  set closeInterceptor(bool Function()? interceptor) {}

  @override
  void quit() {}

  @override
  bool get launchedAtLogin => false;

  @override
  LaunchAtLoginState readLaunchAtLogin() => LaunchAtLoginState.unsupported;

  @override
  bool setLaunchAtLogin({required bool enabled}) => false;
}
