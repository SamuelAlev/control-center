import 'package:control_center/core/storage/key_value_backend.dart';
import 'package:web/web.dart' as web;

/// A [KeyValueBackend] over the browser's `window.localStorage`, so web
/// preferences (theme, the server connection, …) survive a page reload — the
/// web counterpart to the desktop's NSUserDefaults / Registry / GSettings
/// backing (`NativeKeyValueBackend`).
///
/// `localStorage` is synchronous and string-only, so it maps 1:1 onto the
/// [KeyValueBackend] surface with no FFI. Imported only from the web bootstrap
/// (the desktop never references this file), so the `package:web` dependency
/// stays out of the VM build.
class WebLocalStorageBackend implements KeyValueBackend {
  /// Creates a backend over the window's localStorage.
  WebLocalStorageBackend();

  web.Storage get _ls => web.window.localStorage;

  @override
  bool set(String key, String value) {
    _ls.setItem(key, value);
    return true;
  }

  @override
  String get(String key, [String defaultValue = '']) =>
      _ls.getItem(key) ?? defaultValue;

  @override
  bool remove(String key) {
    final had = _ls.getItem(key) != null;
    _ls.removeItem(key);
    return had;
  }

  @override
  bool clear() {
    _ls.clear();
    return true;
  }

  @override
  bool contains(String key) => _ls.getItem(key) != null;

  @override
  List<String> get keys => [
    for (var i = 0; i < _ls.length; i++)
      if (_ls.key(i) case final String k) k,
  ];

  @override
  int get size => _ls.length;

  @override
  Map<String, String> getAll() => {
    for (final k in keys) k: _ls.getItem(k) ?? '',
  };

  @override
  void dispose() {}
}
