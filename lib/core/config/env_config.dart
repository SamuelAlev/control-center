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

  static String? _cachedGoogleClientId;

  /// The Google OAuth client id, loaded from environment or the repo-root
  /// `.env` file (`GOOGLE_OAUTH_CLIENT_ID`).
  ///
  /// This must be a *public iOS-type* OAuth client id — a genuinely public
  /// client with **no secret**. The PKCE flow needs none, so nothing
  /// confidential ships in the binary. The OS-registered redirect scheme
  /// (`com.googleusercontent.apps.<client>`) is derived from this id, so it must
  /// match the reversed-client-id scheme registered for each platform (macOS
  /// `CFBundleURLSchemes` via `GOOGLE_REVERSED_CLIENT_ID`, Linux
  /// `x-scheme-handler`). Empty when unset; the calendar connect flow surfaces a
  /// "configure Google client id" error rather than crashing in that case.
  static String get googleOAuthClientId {
    _cachedGoogleClientId ??= _envValue('GOOGLE_OAUTH_CLIENT_ID') ?? '';
    return _cachedGoogleClientId!;
  }

  /// Clears the cached env values so they are re-read on next access.
  static void clearCache() {
    _cachedKlipyAppKey = null;
    _cachedGoogleClientId = null;
  }
}
