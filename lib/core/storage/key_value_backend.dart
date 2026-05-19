/// A synchronous string key-value store — the web-safe interface that
/// `AppPreferences` and `SecureStore` are written against.
///
/// Mirrors the shape of nativeapi's `Storage` so a thin desktop adapter
/// (`NativeKeyValueBackend`) can wrap the native NSUserDefaults / Registry /
/// GSettings backing, while the default `InMemoryStorage` and a web
/// localStorage backend need no FFI. Decoupling this from nativeapi keeps the
/// storage providers (read by virtually every screen) out of the
/// `dart:ffi`-laden nativeapi import, so the full UI compiles for web.
abstract interface class KeyValueBackend {
  /// Stores [value] under [key]. Returns whether the write succeeded.
  bool set(String key, String value);

  /// Reads the value at [key], or [defaultValue] when absent.
  String get(String key, [String defaultValue = '']);

  /// Removes [key]. Returns whether a value was present.
  bool remove(String key);

  /// Clears every entry. Returns whether the store changed.
  bool clear();

  /// Whether [key] has a stored value.
  bool contains(String key);

  /// Every stored key.
  List<String> get keys;

  /// The number of stored entries.
  int get size;

  /// A snapshot copy of all entries.
  Map<String, String> getAll();

  /// Releases any native resources held by the backing store.
  void dispose();
}
