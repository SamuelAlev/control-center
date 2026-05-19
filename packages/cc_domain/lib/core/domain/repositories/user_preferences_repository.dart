/// Persistence port for per-user preferences (theme, fonts, keybindings,
/// notification prefs).
///
/// Preferences are user-scoped, not workspace- or device-scoped: a user's
/// setup follows them across desktop, web, and phone. Values are opaque
/// strings (JSON where structured); the client owns the schema of each key.
abstract class UserPreferencesRepository {
  /// The value of [key] for [userId], or null when unset.
  Future<String?> get(String userId, String key);

  /// All preferences of [userId].
  Future<Map<String, String>> getAll(String userId);

  /// Live stream of all preferences of [userId].
  Stream<Map<String, String>> watchAll(String userId);

  /// Sets [key] to [value] for [userId]; null deletes the key.
  Future<void> set(String userId, String key, String? value);
}
