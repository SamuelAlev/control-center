import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Default width for the PR file-tree panel (logical pixels).
const double kDefaultPrTreeWidth = 260;

/// Persists the PR file-tree panel width across sessions.
final prTreeWidthProvider = NotifierProvider<PrTreeWidthNotifier, double>(
  PrTreeWidthNotifier.new,
);

/// Notifier that reads/writes the PR tree width to [AppPreferences].
class PrTreeWidthNotifier extends Notifier<double> {
  late AppPreferences _prefs;

  @override
  double build() {
    _prefs = ref.watch(appPreferencesProvider);
    return _prefs.getDouble(prTreeWidthKey) ?? kDefaultPrTreeWidth;
  }

  /// Persists [width] and updates the state.
  void setWidth(double width) {
    _prefs.setDouble(prTreeWidthKey, width);
    state = width;
  }
}
