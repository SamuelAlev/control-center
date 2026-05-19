import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/pr_review/domain/value_objects/diff_overflow_mode.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preference for how the diff viewer handles lines wider than the
/// viewport ([DiffOverflowMode.wrap] vs [DiffOverflowMode.scroll]). Persisted
/// as a non-sensitive preference in shared_preferences.
final diffOverflowModeProvider =
    NotifierProvider<DiffOverflowModeNotifier, DiffOverflowMode>(
  DiffOverflowModeNotifier.new,
);

/// Loads and persists the diff overflow mode preference.
class DiffOverflowModeNotifier extends Notifier<DiffOverflowMode> {
  late SharedPreferences _prefs;

  @override
  DiffOverflowMode build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return DiffOverflowMode.fromName(_prefs.getString(diffOverflowModeKey));
  }

  /// Sets the diff overflow mode and persists it.
  void setMode(DiffOverflowMode mode) {
    _prefs.setString(diffOverflowModeKey, mode.name);
    state = mode;
  }
}
