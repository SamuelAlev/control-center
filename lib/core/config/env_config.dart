import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;

/// Env config.
class EnvConfig {
  EnvConfig._();

  /// Reads [key] from the OS environment, then a repo-root `.env` file.
  ///
  /// On the web there is no process environment and no filesystem —
  /// `Platform.environment` and `File` both throw `UnsupportedError` — so this
  /// returns null there and callers fall back to a compile-time
  /// `--dart-define` value (see the getters below).
  static String? _envValue(String key) {
    if (kIsWeb) {
      return null;
    }
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

  /// The Klipy app key loaded from the environment, the repo-root `.env`, or a
  /// compile-time `--dart-define=KLIPY_APP_KEY=...` (the only source available
  /// on web). Empty when unset — the GIF picker shows a "no key" card.
  static String get klipyAppKey {
    return _cachedKlipyAppKey ??=
        _envValue('KLIPY_APP_KEY') ??
        const String.fromEnvironment('KLIPY_APP_KEY');
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
    return _cachedGoogleClientId ??=
        _envValue('GOOGLE_OAUTH_CLIENT_ID') ??
        const String.fromEnvironment('GOOGLE_OAUTH_CLIENT_ID');
  }

  /// Clears the cached env values so they are re-read on next access.
  static void clearCache() {
    _cachedKlipyAppKey = null;
    _cachedGoogleClientId = null;
  }
}
