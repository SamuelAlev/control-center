import 'package:control_center/core/storage/key_value_backend.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:nativeapi/nativeapi.dart' show Preferences, Storage;

/// The nativeapi preferences scope this install reads and writes.
///
/// nativeapi's no-arg `Preferences()` uses the scope `default`, which lands in
/// a MACHINE-GLOBAL store shared by every app on the box that uses the package
/// (macOS: the `com.nativeapi.preferences.default` NSUserDefaults suite) — the
/// root cause of dev-build state leaking into the production install. Scoping
/// gives this app its own store (macOS: `com.nativeapi.preferences.<scope>`;
/// Windows: `HKCU\Software\NativeAPI\Preferences\<scope>`; Linux:
/// `~/.config/nativeapi/preferences_<scope>.conf`), and debug builds get a
/// `.dev`-suffixed scope so a dev run never shares — or pollutes — the
/// production install's preferences.
///
/// There is deliberately NO migration from the old `default` scope: values
/// there are simply orphaned, and device-local preferences (theme, layout,
/// onboarding flag) reset once. Credentials are unaffected (they live in the
/// OS keychain, not here).
const String appPreferencesScope = kDebugMode
    ? 'com.alev.control-center.dev'
    : 'com.alev.control-center';

/// Desktop [KeyValueBackend] backed by nativeapi's native [Storage]
/// (NSUserDefaults / Windows Registry / GSettings), scoped to
/// [appPreferencesScope].
///
/// Imports nativeapi (`dart:ffi`), so it only ever compiles on the VM — the
/// desktop composition root constructs it; the web build uses an
/// `InMemoryStorage` / localStorage backend instead.
class NativeKeyValueBackend implements KeyValueBackend {
  /// Wraps [store], defaulting to the app-scoped nativeapi [Preferences]
  /// backing.
  NativeKeyValueBackend([Storage? store])
    : _store = store ?? Preferences.withScope(appPreferencesScope);

  final Storage _store;

  @override
  bool set(String key, String value) => _store.set(key, value);

  @override
  String get(String key, [String defaultValue = '']) =>
      _store.get(key, defaultValue);

  @override
  bool remove(String key) => _store.remove(key);

  @override
  bool clear() => _store.clear();

  @override
  bool contains(String key) => _store.contains(key);

  @override
  List<String> get keys => _store.keys;

  @override
  int get size => _store.size;

  @override
  Map<String, String> getAll() => _store.getAll();

  @override
  void dispose() => _store.dispose();
}
