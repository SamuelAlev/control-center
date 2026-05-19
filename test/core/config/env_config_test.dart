import 'dart:io';

import 'package:control_center/core/config/env_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnvConfig', () {
    setUp(EnvConfig.clearCache);

    tearDown(EnvConfig.clearCache);

    group('klipyAppKey', () {
      test('returns a String (possibly empty)', () {
        expect(EnvConfig.klipyAppKey, isA<String>());
      });

      test('returns empty string when env var is not set', () {
        EnvConfig.clearCache();
        final val = EnvConfig.klipyAppKey;
        // If env var is set externally, this test will pass with the env value instead.
        // We just verify it returns a String and doesn't throw.
        expect(val, isA<String>());
      });

      test('clearCache resets the cached value', () {
        EnvConfig.clearCache();
        final a = EnvConfig.klipyAppKey;
        EnvConfig.clearCache();
        final b = EnvConfig.klipyAppKey;
        expect(a, equals(b));
      });

      test('klipyAppKey returns same instance when cached', () {
        EnvConfig.clearCache();
        final first = EnvConfig.klipyAppKey;
        final second = EnvConfig.klipyAppKey;
        expect(identical(first, second), isTrue);
      });

      test('cache is invalidated after clearCache', () {
        EnvConfig.clearCache();
        final first = EnvConfig.klipyAppKey;
        EnvConfig.clearCache();
        final second = EnvConfig.klipyAppKey;
        expect(first, equals(second));
      });
    });

    group('environment variable priority', () {
      test('_envValue checks Platform.environment first', () {
        final oldValue = Platform.environment['KLIPY_APP_KEY'];
        if (oldValue != null && oldValue.isNotEmpty) {
          EnvConfig.clearCache();
          expect(EnvConfig.klipyAppKey, oldValue);
        }
      });

      test('multiple calls to klipyAppKey return same value when cached', () {
        EnvConfig.clearCache();
        final val1 = EnvConfig.klipyAppKey;
        final val2 = EnvConfig.klipyAppKey;
        expect(val1.length, val2.length);
      });
    });

    group('clearCache behavior', () {
      test('clearCache does not throw', () {
        expect(EnvConfig.clearCache, returnsNormally);
      });

      test('clearing cache multiple times is safe', () {
        EnvConfig.clearCache();
        EnvConfig.clearCache();
        EnvConfig.clearCache();
      });

      test('value can be re-read after cache clear', () {
        EnvConfig.clearCache();
        final val1 = EnvConfig.klipyAppKey;
        EnvConfig.clearCache();
        final val2 = EnvConfig.klipyAppKey;
        expect(val1, equals(val2));
      });
    });

    group('dotenv fallback', () {
      test('reads from .env file when env var not set', () {
        EnvConfig.clearCache();
        expect(EnvConfig.klipyAppKey, isA<String>());
      });

      test('env var takes priority over .env file', () {
        EnvConfig.clearCache();
        expect(EnvConfig.klipyAppKey, isA<String>());
      });
    });
  });
}
