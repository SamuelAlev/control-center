import 'package:control_center/core/providers/storage_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Mixin that sets up SharedPreferences for widget tests.
///
/// Use in setUp:
/// ```dart
/// setUp(() async {
///   await setUpSharedPrefs(overrides);
/// });
/// ```
///
/// The mixin provides:
/// - [prefs] — the SharedPreferences instance
/// - [sharedPrefsOverride] — the Riverpod override for sharedPreferencesProvider
mixin SharedPrefsMixin {
  late final SharedPreferences prefs;
  late final dynamic sharedPrefsOverride;

  /// Must be called in setUp before using [prefs] or [sharedPrefsOverride].
  Future<void> setUpSharedPrefs([Map<String, Object> initialValues = const {}]) async {
    SharedPreferences.setMockInitialValues(initialValues);
    prefs = await SharedPreferences.getInstance();
    sharedPrefsOverride = sharedPreferencesProvider.overrideWithValue(prefs);
  }
}
