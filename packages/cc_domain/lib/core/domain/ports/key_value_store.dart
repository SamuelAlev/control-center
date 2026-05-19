/// Minimal typed key-value persistence port for non-sensitive app preferences.
///
/// Flutter-free services (e.g. the newsfeed `FilterListService`) depend on this
/// instead of a concrete preferences class so they stay linkable into the
/// headless server. The desktop binds it to its `nativeapi`-backed
/// `AppPreferences`; the server binds its own store. Only the accessors actual
/// consumers need are declared — widen deliberately, not by reflex.
abstract class KeyValueStore {
  /// Reads the string at [key], or `null` when absent.
  String? getString(String key);

  /// Writes [value] at [key]; resolves `true` on success.
  Future<bool> setString(String key, String value);

  /// Reads the int at [key], or `null` when absent.
  int? getInt(String key);

  /// Writes [value] at [key]; resolves `true` on success.
  Future<bool> setInt(String key, int value);
}
