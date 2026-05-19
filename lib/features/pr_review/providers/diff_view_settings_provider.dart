import 'package:cc_domain/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// User preference for how the diff viewer handles lines wider than the
/// viewport ([DiffOverflowMode.wrap] vs [DiffOverflowMode.scroll]). Persisted
/// as a non-sensitive preference in shared_preferences.
final diffOverflowModeProvider =
    NotifierProvider<DiffOverflowModeNotifier, DiffOverflowMode>(
      DiffOverflowModeNotifier.new,
    );

/// Loads and persists the diff overflow mode preference.
class DiffOverflowModeNotifier extends Notifier<DiffOverflowMode> {
  late AppPreferences _prefs;

  @override
  DiffOverflowMode build() {
    _prefs = ref.watch(appPreferencesProvider);
    return DiffOverflowMode.fromName(_prefs.getString(diffOverflowModeKey));
  }

  /// Sets the diff overflow mode and persists it.
  void setMode(DiffOverflowMode mode) {
    _prefs.setString(diffOverflowModeKey, mode.name);
    state = mode;
  }
}
