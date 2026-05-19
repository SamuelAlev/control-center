import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory fallback for [SharedPreferences] used when the provider is not
/// overridden (e.g. in widget tests that forget to inject a mock).
///
/// Overridden in `main` with the real disk-backed instance.
class _FakeSharedPreferences implements SharedPreferences {
  final Map<String, Object> _cache = {};

  @override
  Set<String> getKeys() => Set<String>.from(_cache.keys);

  @override
  Object? get(String key) => _cache[key];

  @override
  bool? getBool(String key) => _cache[key] as bool?;

  @override
  int? getInt(String key) => _cache[key] as int?;

  @override
  double? getDouble(String key) => _cache[key] as double?;

  @override
  String? getString(String key) => _cache[key] as String?;

  @override
  bool containsKey(String key) => _cache.containsKey(key);

  @override
  List<String>? getStringList(String key) {
    final list = _cache[key] as List<dynamic>?;
    return list?.cast<String>().toList();
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _cache[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    _cache.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _cache.clear();
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}
}

/// Returns a fake in-memory instance when not overridden.
/// Overridden in `main` with the real `SharedPreferences` instance.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  return _FakeSharedPreferences();
});

/// Provides the platform secure storage instance (Keychain, Credential Manager, etc.).
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );
});
