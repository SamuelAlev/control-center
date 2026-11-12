/// The server's secrets store, seen as plain named slots.
///
/// Secrets that must not sit in a database row (and so in every snapshot and
/// admin export of it) live here instead; the row keeps only the slot's name.
/// The server binds it to its owner-only secrets file.
abstract interface class SecretStorePort {
  /// The secret stored under [key], or null when there is none.
  Future<String?> read(String key);

  /// Stores [value] under [key], replacing any previous value.
  Future<void> write(String key, String value);

  /// Removes [key]; removing an absent key is not an error.
  Future<void> delete(String key);

  /// Removes every key for which [matches] is true and returns how many went.
  Future<int> deleteMatching(bool Function(String key) matches);
}

/// A [SecretStorePort] held in memory, for tests and tools that run without
/// the server's secrets file. Nothing written here outlives the process.
class InMemorySecretStore implements SecretStorePort {
  /// The stored secrets, by key; exposed so a test can see what was kept.
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<int> deleteMatching(bool Function(String key) matches) async {
    final keys = values.keys.where(matches).toList();
    keys.forEach(values.remove);
    return keys.length;
  }
}
