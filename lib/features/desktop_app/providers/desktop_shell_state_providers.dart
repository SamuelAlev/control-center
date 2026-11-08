import 'package:control_center/core/desktop/desktop_shell.dart';
import 'package:control_center/core/providers/desktop_shell_provider.dart';
import 'package:control_center/features/desktop_app/providers/desktop_app_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether an icon placed in the tray would be visible. Follows the shell's
/// live answer (Linux settles it after launch).
final trayHostStateProvider = Provider<TrayHostState>((ref) {
  final listenable = ref.watch(desktopShellProvider).trayHost;
  void onChange() => ref.invalidateSelf();
  listenable.addListener(onChange);
  ref.onDispose(() => listenable.removeListener(onChange));
  return listenable.value;
});

/// Whether the tray icon is on screen: wanted and possible.
final trayIconShownProvider = Provider<bool>(
  (ref) =>
      ref.watch(trayHostStateProvider) == TrayHostState.available &&
      ref.watch(trayIconVisibleProvider),
);

/// Whether the main window can be hidden at all without stranding the
/// operator: something must remain to bring it back.
///
/// macOS always has the Dock icon. Windows and Linux hide a hidden window's
/// taskbar entry too, so there it takes the tray icon.
final canKeepRunningProvider = Provider<bool>((ref) {
  if (!ref.watch(desktopShellProvider).traySupported) {
    return false;
  }
  if (defaultTargetPlatform == TargetPlatform.macOS) {
    return true;
  }
  return ref.watch(trayIconShownProvider);
});

/// Whether the main window is hidden in the tray right now.
final mainWindowHiddenProvider = Provider<bool>((ref) {
  final listenable = ref.watch(desktopShellProvider).mainWindowHidden;
  void onChange() => ref.invalidateSelf();
  listenable.addListener(onChange);
  ref.onDispose(() => listenable.removeListener(onChange));
  return listenable.value;
});

/// Launch at login, as the operating system reports it, plus whether the
/// last attempt to change it was refused.
@immutable
class LaunchAtLoginStatus {
  /// Creates a [LaunchAtLoginStatus].
  const LaunchAtLoginStatus({required this.state, this.refused = false});

  /// What the system reports.
  final LaunchAtLoginState state;

  /// The last change did not take: macOS waiting for approval in System
  /// Settings, a policy-managed machine, an unwritable autostart folder.
  final bool refused;

  /// Whether the app opens at login.
  bool get enabled => state == LaunchAtLoginState.enabled;

  @override
  bool operator ==(Object other) =>
      other is LaunchAtLoginStatus &&
      other.state == state &&
      other.refused == refused;

  @override
  int get hashCode => Object.hash(state, refused);
}

/// Launch at login. Re-read with [LaunchAtLoginNotifier.refresh] whenever the
/// app comes back to the front: System Settings or Task Manager may have
/// changed it meanwhile.
final launchAtLoginProvider =
    NotifierProvider<LaunchAtLoginNotifier, LaunchAtLoginStatus>(
      LaunchAtLoginNotifier.new,
    );

/// Notifier for [launchAtLoginProvider].
class LaunchAtLoginNotifier extends Notifier<LaunchAtLoginStatus> {
  @override
  LaunchAtLoginStatus build() => LaunchAtLoginStatus(
    state: ref.watch(desktopShellProvider).readLaunchAtLogin(),
  );

  /// Registers or removes the login launch.
  void set({required bool enabled}) {
    final shell = ref.read(desktopShellProvider);
    final took = shell.setLaunchAtLogin(enabled: enabled);
    state = LaunchAtLoginStatus(
      state: shell.readLaunchAtLogin(),
      refused: !took,
    );
  }

  /// Re-reads the system's registration, keeping a refusal on screen only
  /// while the system still disagrees with what was asked.
  void refresh() {
    final next = ref.read(desktopShellProvider).readLaunchAtLogin();
    state = LaunchAtLoginStatus(
      state: next,
      refused: state.refused && next == state.state,
    );
  }
}
