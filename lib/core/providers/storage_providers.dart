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

const _iosOptions = IOSOptions(
  accessibility: KeychainAccessibility.unlocked_this_device,
);

/// macOS secrets live in the iOS-style **data-protection keychain**. Items use
/// the app's **default** access group — the team-prefixed `keychain-access-groups`
/// entitlement in `macos/Runner/*.entitlements` — so we deliberately do NOT
/// hard-code a `groupId` here. That keeps this file team-agnostic: a contributor
/// signs with their own Apple team (the debug entitlement uses
/// `$(DEVELOPMENT_TEAM)`) and never has to touch Dart — see CONTRIBUTING.md.
///
/// Access via the entitlement (not a per-signature ACL) means a properly signed
/// app reads its own secrets with **no keychain prompt**, unlike the legacy login
/// keychain. Requires an Apple Developer team (free works for local dev) + the
/// entitlement; an ad-hoc build with no team can't satisfy it (-34018) and secure
/// storage is unavailable. The App Sandbox stays off (sandbox-exec agent feature).
const _macOsOptions = MacOsOptions(
  accessibility: KeychainAccessibility.unlocked_this_device,
  usesDataProtectionKeychain: true,
);

/// Provides the platform secure storage instance (Keychain, Credential Manager, etc.).
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    iOptions: _iosOptions,
    mOptions: _macOsOptions,
  );
});
