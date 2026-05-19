import 'package:control_center/core/storage/key_value_backend.dart';
import 'package:nativeapi/nativeapi.dart' show Preferences, Storage;

/// Desktop [KeyValueBackend] backed by nativeapi's native [Storage]
/// (NSUserDefaults / Windows Registry / GSettings).
///
/// Imports nativeapi (`dart:ffi`), so it only ever compiles on the VM — the
/// desktop composition root constructs it; the web build uses an
/// `InMemoryStorage` / localStorage backend instead.
class NativeKeyValueBackend implements KeyValueBackend {
  /// Wraps [store], defaulting to a fresh nativeapi [Preferences] backing.
  NativeKeyValueBackend([Storage? store]) : _store = store ?? Preferences();

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
