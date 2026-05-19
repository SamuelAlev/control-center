import 'package:control_center/core/constants/app_constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Storage key constants', () {
    test('githubTokenKey is correct', () {
      expect(githubTokenKey, 'github_token');
    });

    test('ticketingApiKeyKey is correct', () {
      expect(ticketingApiKeyKey, 'ticketing_api_key');
    });

    test('themeModeKey is correct', () {
      expect(themeModeKey, 'theme_mode');
    });
  });

  group('Font family preference keys', () {
    test('appFontFamilyKey is correct', () {
      expect(appFontFamilyKey, 'app_font_family');
    });

    test('appFontSourceKey is correct', () {
      expect(appFontSourceKey, 'app_font_source');
    });

    test('appFontPathKey is correct', () {
      expect(appFontPathKey, 'app_font_path');
    });

    test('codeFontFamilyKey is correct', () {
      expect(codeFontFamilyKey, 'code_font_family');
    });

    test('codeFontSourceKey is correct', () {
      expect(codeFontSourceKey, 'code_font_source');
    });

    test('codeFontPathKey is correct', () {
      expect(codeFontPathKey, 'code_font_path');
    });
  });

  group('Default status constants', () {
    test('defaultConversationStatus is active', () {
      expect(defaultConversationStatus, 'active');
    });
  });

  group('API constants', () {
    test('githubApiBaseUrl is correct', () {
      expect(githubApiBaseUrl, 'https://api.github.com');
    });

    test('githubApiBaseUrl uses HTTPS', () {
      expect(githubApiBaseUrl, startsWith('https://'));
    });

    test('defaultMcpHost is localhost', () {
      expect(defaultMcpHost, '127.0.0.1');
    });
  });

  group('Constants are compile-time', () {
    test('all constants are non-null and non-empty strings', () {
      expect(githubTokenKey, isNotEmpty);
      expect(ticketingApiKeyKey, isNotEmpty);
      expect(themeModeKey, isNotEmpty);
      expect(appFontFamilyKey, isNotEmpty);
      expect(appFontSourceKey, isNotEmpty);
      expect(appFontPathKey, isNotEmpty);
      expect(codeFontFamilyKey, isNotEmpty);
      expect(codeFontSourceKey, isNotEmpty);
      expect(codeFontPathKey, isNotEmpty);
      expect(defaultConversationStatus, isNotEmpty);
      expect(githubApiBaseUrl, isNotEmpty);
      expect(defaultMcpHost, isNotEmpty);
    });

    test('storage keys are snake_case', () {
      expect(githubTokenKey, contains('_'));
      expect(ticketingApiKeyKey, contains('_'));
      expect(themeModeKey, contains('_'));
    });

    test('route-related constants do not start with /', () {
      // Verify constants are just values, not routes
      expect(githubApiBaseUrl, startsWith('https://'));
      expect(defaultMcpHost, isNot(startsWith('/')));
    });

    test('font keys are distinct', () {
      final fontKeys = [
        appFontFamilyKey,
        appFontSourceKey,
        appFontPathKey,
        codeFontFamilyKey,
        codeFontSourceKey,
        codeFontPathKey,
      ];
      expect(fontKeys.toSet().length, fontKeys.length);
    });
  });
}
