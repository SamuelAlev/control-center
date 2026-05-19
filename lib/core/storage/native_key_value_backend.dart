import 'package:control_center/core/storage/key_value_backend.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:nativeapi/nativeapi.dart' show Preferences;

/// The nativeapi preferences scope this install reads and writes.
///
/// nativeapi's no-arg `Preferences()` uses the scope `default`, which lands in
/// a MACHINE-GLOBAL store shared by every app on the box that uses the package
/// (macOS: the `com.nativeapi.preferences.default` NSUserDefaults suite) — the
/// root cause of dev-build state leaking into the production install. Scoping
/// gives this app its own store (macOS: `com.nativeapi.preferences.<scope>`;
/// Windows: `HKCU\Software\NativeAPI\Preferences\<scope>`; Linux:
/// `~/.config/nativeapi/preferences_<scope>.conf`) and debug builds get a
/// `.dev`-suffixed scope so a dev run never shares — or pollutes — the
/// production install's preferences.
///
/// There is deliberately NO migration from the old `default` scope: values
/// there are simply orphaned and device-local preferences (theme, layout,
/// onboarding flag) reset once. Credentials are unaffected (they live in the
/// OS keychain, not here).
const String appPreferencesScope = kDebugMode
    ? 'com.alev.control-center.dev'
    : 'com.alev.control-center';

/// Desktop [KeyValueBackend] backed by nativeapi's native [Preferences] store
/// (NSUserDefaults / Windows Registry / GSettings), scoped to
/// [appPreferencesScope].
///
/// Imports nativeapi (`dart:ffi`), so it only ever compiles on the VM — the
/// desktop composition root constructs it; the web build uses an
/// `InMemoryStorage` / localStorage backend instead.
class NativeKeyValueBackend implements KeyValueBackend {
  /// Wraps [store], defaulting to the app-scoped nativeapi [Preferences]
  /// backing.
  NativeKeyValueBackend([Preferences? store])
    : _store = store ?? _openScopedStore();

  /// Opens the app's own preferences scope, or fails loudly.
  ///
  /// A null handle means the platform store could not be opened at all, which
  /// is a broken install rather than a runtime condition: every device-local
  /// preference (theme, layout, window geometry, the server choice) reads
  /// through here, and silently falling back to an in-memory map would look
  /// like a first run on every launch.
  static Preferences _openScopedStore() {
    final store = Preferences.createWithScope(appPreferencesScope);
    if (store == null) {
      throw StateError(
        'nativeapi could not open the "$appPreferencesScope" preferences scope',
      );
    }
    return store;
  }

  final Preferences _store;

  @override
  bool set(String key, String value) => _store.set(key, value);

  @override
  String get(String key, [String defaultValue = '']) =>
      _store.get(key, defaultValue) ?? defaultValue;

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
  Map<String, String> getAll() => _store.all;

  @override
  void dispose() => _store.dispose();
}
