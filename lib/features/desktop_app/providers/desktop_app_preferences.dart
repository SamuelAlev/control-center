import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the tray (menu bar) icon is shown. Device-local, like every key
/// here: never registered for per-user sync, because how one laptop's window
/// behaves says nothing about another's.
const String trayIconVisibleKey = 'tray_icon_visible';

/// What closing the main window does: `true` keeps the app running in the
/// background, `false` quits. Absent until the operator picks (the default
/// keeps running).
const String closeToTrayKey = 'tray_close_to_tray';

/// Whether a login launch starts with the main window hidden. Read by the
/// desktop bootstrap before any session exists, hence a plain key.
const String startHiddenAtLoginKey = 'login_start_hidden';

/// What closing the main window does.
enum CloseAction {
  /// Hide the window; the app keeps running in the menu bar or tray.
  keepRunning,

  /// Quit the app, as closing the last window did before.
  quit,
}

/// Whether closing the main window asks once before it first hides it.
///
/// On macOS closing a window never meant quitting: the app stays in the Dock,
/// as Slack, Discord and Mail do. Windows and Linux users expect the X to
/// quit, so there the first close explains that the app keeps running in the
/// tray and lets them pick, instead of silently leaving a process behind.
bool asksBeforeFirstHide(TargetPlatform platform) =>
    platform != TargetPlatform.macOS;

/// Whether the tray icon is shown. Defaults to shown.
final trayIconVisibleProvider = NotifierProvider<TrayIconVisibleNotifier, bool>(
  TrayIconVisibleNotifier.new,
);

/// Notifier for [trayIconVisibleProvider].
class TrayIconVisibleNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getBool(trayIconVisibleKey) ?? true;

  /// Persists [value] and applies it.
  Future<void> set({required bool value}) async {
    await ref
        .read(appPreferencesProvider)
        .setBool(trayIconVisibleKey, value: value);
    state = value;
  }
}

/// What closing the main window does. Defaults to keeping the app running:
/// notifications only arrive while it does.
final closeActionProvider = NotifierProvider<CloseActionNotifier, CloseAction>(
  CloseActionNotifier.new,
);

/// Notifier for [closeActionProvider].
class CloseActionNotifier extends Notifier<CloseAction> {
  @override
  CloseAction build() {
    final stored = ref.watch(appPreferencesProvider).getBool(closeToTrayKey);
    return (stored ?? true) ? CloseAction.keepRunning : CloseAction.quit;
  }

  /// Whether the operator has picked a close action (in Settings or the
  /// first-close prompt), as opposed to running on the default. Read live:
  /// picking the default changes no state, so nothing would notify.
  bool get chosen =>
      ref.read(appPreferencesProvider).getBool(closeToTrayKey) != null;

  /// Persists [action] as the operator's choice and applies it.
  Future<void> set(CloseAction action) async {
    await ref
        .read(appPreferencesProvider)
        .setBool(closeToTrayKey, value: action == CloseAction.keepRunning);
    state = action;
  }
}

/// Whether a login launch starts hidden in the tray. Defaults to opening the
/// window, as Slack and Discord do.
final startHiddenAtLoginProvider =
    NotifierProvider<StartHiddenAtLoginNotifier, bool>(
      StartHiddenAtLoginNotifier.new,
    );

/// Notifier for [startHiddenAtLoginProvider].
class StartHiddenAtLoginNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(appPreferencesProvider).getBool(startHiddenAtLoginKey) ?? false;

  /// Persists [value] and applies it.
  Future<void> set({required bool value}) async {
    await ref
        .read(appPreferencesProvider)
        .setBool(startHiddenAtLoginKey, value: value);
    state = value;
  }
}
