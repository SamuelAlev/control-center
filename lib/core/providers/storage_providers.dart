import 'dart:convert';

import 'package:cc_domain/core/domain/ports/key_value_store.dart';
import 'package:control_center/core/storage/key_value_backend.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Typed key-value facade over the [KeyValueBackend] interface.
///
/// The backend stores **String values only**, so the typed accessors encode
/// bool/int/double/`List<String>` to text and decode on read. Getters return
/// `null` when the key is absent (mirroring the nullable accessors the app's
/// preference wrappers were written against); setters stay `Future`-shaped so
/// existing `await prefs.setX(...)` call sites are untouched even though the
/// underlying native calls are synchronous.
class AppPreferences implements KeyValueStore {
  const AppPreferences(this._store);

  /// An in-memory instance seeded from typed [initial] values (encoded the same
  /// way the typed setters write them). Handy for tests and previews — replaces
  /// the old `SharedPreferences.setMockInitialValues(initial)` + `getInstance()`
  /// dance: `AppPreferences.inMemory({themeModeKey: 'dark'})`.
  factory AppPreferences.inMemory([
    Map<String, Object> initial = const {},
  ]) {
    final store = InMemoryStorage();
    initial.forEach((key, value) {
      store.set(key, switch (value) {
        final bool b => b ? 'true' : 'false',
        final int i => i.toString(),
        final double d => d.toString(),
        final List<String> l => jsonEncode(l),
        _ => value.toString(),
      });
    });
    return AppPreferences(store);
  }

  final KeyValueBackend _store;

  @override
  String? getString(String key) => _store.contains(key) ? _store.get(key) : null;

  @override
  Future<bool> setString(String key, String value) async =>
      _store.set(key, value);

  bool? getBool(String key) =>
      _store.contains(key) ? _store.get(key) == 'true' : null;

  Future<bool> setBool(String key, bool value) async =>
      _store.set(key, value ? 'true' : 'false');

  @override
  int? getInt(String key) =>
      _store.contains(key) ? int.tryParse(_store.get(key)) : null;

  @override
  Future<bool> setInt(String key, int value) async =>
      _store.set(key, value.toString());

  double? getDouble(String key) =>
      _store.contains(key) ? double.tryParse(_store.get(key)) : null;

  Future<bool> setDouble(String key, double value) async =>
      _store.set(key, value.toString());

  List<String>? getStringList(String key) {
    if (!_store.contains(key)) {
      return null;
    }
    final decoded = jsonDecode(_store.get(key));
    return (decoded as List).cast<String>();
  }

  Future<bool> setStringList(String key, List<String> value) async =>
      _store.set(key, jsonEncode(value));

  bool containsKey(String key) => _store.contains(key);

  Future<bool> remove(String key) async => _store.remove(key);

  Set<String> getKeys() => _store.keys.toSet();
}

/// Secure (keychain/DPAPI/libsecret) key-value facade.
///
/// Mirrors the small `read`/`write`/`delete` surface the
/// credential repositories use, keeping their call sites unchanged.
///
/// nativeapi owns the platform keychain backing. On macOS this uses Keychain
/// Services; a properly signed app (team-prefixed `keychain-access-groups`
/// entitlement in `macos/Runner/*.entitlements`) reads its own secrets without
/// a prompt. An ad-hoc build with no Apple team cannot satisfy the entitlement
/// and secure storage is unavailable. The App Sandbox stays off (sandbox-exec
/// agent feature).
class SecureStore {
  /// Wraps a synchronous [KeyValueBackend] — used by tests/previews (via
  /// [InMemoryStorage]) and [SecureStore.inMemory].
  const SecureStore(this._store) : _keychain = null;

  /// An in-memory instance seeded from [initial] secrets — for tests/previews,
  /// replacing a mocked keychain.
  factory SecureStore.inMemory([Map<String, String> initial = const {}]) {
    final store = InMemoryStorage();
    initial.forEach(store.set);
    return SecureStore(store);
  }

  /// The real OS-keychain-backed instance used in `main`: macOS/iOS Keychain,
  /// Windows Credential Manager, Linux libsecret — via flutter_secure_storage.
  ///
  /// nativeapi 0.1.x ships an unimplemented `SecureStorage` (every platform is
  /// a stub whose `set` returns false and `get` returns the default), so it
  /// cannot back secrets. flutter_secure_storage is a battle-tested keychain
  /// plugin that works for any locally-signed build — including open-source
  /// contributors with no specific Apple team — while nativeapi keeps backing
  /// the non-secret [AppPreferences].
  SecureStore.keychain([FlutterSecureStorage? keychain])
    : _store = null,
      _keychain = keychain ?? const FlutterSecureStorage();

  final KeyValueBackend? _store;
  final FlutterSecureStorage? _keychain;

  Future<String?> read({required String key}) async {
    final keychain = _keychain;
    if (keychain != null) {
      return keychain.read(key: key);
    }
    final store = _store!;
    return store.contains(key) ? store.get(key) : null;
  }

  /// Persists [value] under [key]. Returns whether the write succeeded so
  /// callers can detect (and surface) a secret that failed to persist.
  /// flutter_secure_storage throws on failure rather than returning a flag, so
  /// a normal return is treated as success.
  Future<bool> write({required String key, required String value}) async {
    final keychain = _keychain;
    if (keychain != null) {
      await keychain.write(key: key, value: value);
      return true;
    }
    return _store!.set(key, value);
  }

  Future<void> delete({required String key}) async {
    final keychain = _keychain;
    if (keychain != null) {
      await keychain.delete(key: key);
      return;
    }
    _store!.remove(key);
  }
}

/// In-memory [KeyValueBackend] used as the default provider value and in tests,
/// so the providers never reach native FFI unless explicitly overridden in the
/// composition root with the real disk-backed instances.
class InMemoryStorage implements KeyValueBackend {
  final Map<String, String> _cache = {};

  @override
  bool set(String key, String value) {
    _cache[key] = value;
    return true;
  }

  @override
  String get(String key, [String defaultValue = '']) =>
      _cache[key] ?? defaultValue;

  @override
  bool remove(String key) => _cache.remove(key) != null;

  @override
  bool clear() {
    _cache.clear();
    return true;
  }

  @override
  bool contains(String key) => _cache.containsKey(key);

  @override
  List<String> get keys => _cache.keys.toList();

  @override
  int get size => _cache.length;

  @override
  Map<String, String> getAll() => Map<String, String>.from(_cache);

  @override
  void dispose() {}
}

/// App preferences (non-sensitive). Returns an in-memory fake unless overridden
/// in `main` with `AppPreferences(Preferences())` (the real NSUserDefaults /
/// Registry / GSettings backing).
final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return AppPreferences(InMemoryStorage());
});

/// Platform secure storage (Keychain, Credential Manager, libsecret). Returns
/// an in-memory fake unless overridden in `main` with
/// `SecureStore.keychain()` (the real flutter_secure_storage backing).
final secureStoreProvider = Provider<SecureStore>((ref) {
  return SecureStore(InMemoryStorage());
});
