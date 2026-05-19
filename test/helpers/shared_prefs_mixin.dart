import 'package:control_center/core/providers/storage_providers.dart';

/// Mixin that sets up app preferences for widget tests.
///
/// Use in setUp:
/// ```dart
/// setUp(() async {
///   await setUpSharedPrefs(overrides);
/// });
/// ```
///
/// The mixin provides:
/// - [prefs] — the in-memory [AppPreferences] instance
/// - [sharedPrefsOverride] — the Riverpod override for `appPreferencesProvider`
mixin SharedPrefsMixin {
  late final AppPreferences prefs;
  late final dynamic sharedPrefsOverride;

  /// Must be called in setUp before using [prefs] or [sharedPrefsOverride].
  Future<void> setUpSharedPrefs([
    Map<String, Object> initialValues = const {},
  ]) async {
    prefs = AppPreferences.inMemory(initialValues);
    sharedPrefsOverride = appPreferencesProvider.overrideWithValue(prefs);
  }
}
