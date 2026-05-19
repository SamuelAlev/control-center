import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists whether the PR diff file-tree panel is shown. Defaults to visible.
final prTreeVisibleProvider = NotifierProvider<PrTreeVisibleNotifier, bool>(
  PrTreeVisibleNotifier.new,
);

/// Notifier that reads/writes the PR tree visibility to [AppPreferences].
class PrTreeVisibleNotifier extends Notifier<bool> {
  late AppPreferences _prefs;

  @override
  bool build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getBool(prTreeVisibleKey) ?? true;
  }

  /// Persists [visible] and updates the state.
  void setVisible({required bool visible}) {
    _prefs.setBool(prTreeVisibleKey, value: visible);
    state = visible;
  }

  /// Flips the current visibility.
  void toggle() => setVisible(visible: !state);
}

/// Persists whether the PR diff renders split (side-by-side) instead of
/// unified. Defaults to unified.
final prDiffSplitViewProvider = NotifierProvider<PrDiffSplitViewNotifier, bool>(
  PrDiffSplitViewNotifier.new,
);

/// Notifier that reads/writes the PR diff view mode to [AppPreferences].
class PrDiffSplitViewNotifier extends Notifier<bool> {
  late AppPreferences _prefs;

  @override
  bool build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getBool(prDiffSplitViewKey) ?? false;
  }

  /// Persists [split] and updates the state.
  void setSplit({required bool split}) {
    _prefs.setBool(prDiffSplitViewKey, value: split);
    state = split;
  }
}
