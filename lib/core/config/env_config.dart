import 'dart:io';

/// Env config.
class EnvConfig {
  EnvConfig._();

  static String? _envValue(String key) {
    final env = Platform.environment[key];
    if (env != null && env.isNotEmpty) {
      return env;
    }

    try {
      final file = File('.env');
      if (file.existsSync()) {
        for (final line in file.readAsLinesSync()) {
          if (line.startsWith('$key=')) {
            return line.substring(key.length + 1).trim();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String? _cachedKlipyAppKey;

  /// The Klipy app key loaded from environment or `.env` file.
  static String get klipyAppKey {
    if (_cachedKlipyAppKey != null) {
      return _cachedKlipyAppKey!;
    }

    _cachedKlipyAppKey = _envValue('KLIPY_APP_KEY') ?? '';
    return _cachedKlipyAppKey!;
  }

  /// Clears the cached Klipy app key so it is re-read on next access.
  static void clearCache() {
    _cachedKlipyAppKey = null;
  }
}
