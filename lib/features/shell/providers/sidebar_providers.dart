import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Preference key backing [sidebarCollapsedProvider] (non-sensitive UI
/// preference, stored via [AppPreferences] like the theme mode).
const String sidebarCollapsedKey = 'ui.sidebarCollapsed';

/// Whether the global app sidebar is collapsed to its icon-only rail.
///
/// Persisted so the operator's preferred chrome survives a restart; the
/// initial value is read synchronously (the store is backed by synchronous
/// native calls) and every toggle rewrites it.
class SidebarCollapsedNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.read(appPreferencesProvider).getBool(sidebarCollapsedKey) ?? false;

  /// Flips the sidebar between the full-width and icon-only rail modes.
  void toggle() {
    state = !state;
    // Fire-and-forget: the write is synchronous under the hood and a lost
    // write only means the next launch restores the previous mode.
    ref.read(appPreferencesProvider).setBool(sidebarCollapsedKey, value: state);
  }
}

/// The global sidebar's collapsed (icon-only rail) state.
final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedNotifier, bool>(
      SidebarCollapsedNotifier.new,
    );
