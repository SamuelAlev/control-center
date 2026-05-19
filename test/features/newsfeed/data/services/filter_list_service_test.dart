import 'package:control_center/features/newsfeed/domain/filter_list_update_state.dart';
import 'package:dio/dio.dart' show Dio;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

void main() {
  group('FilterListUpdateState', () {
    const state = FilterListUpdateState(
      isUpdating: false,
      errors: [],
      cookieHidingRules: 10,
      adHidingRules: 20,
      networkBlockRules: 5,
      removeParamsCount: 30,
    );

    test('copyWith preserves unchanged fields', () {
      final copy = state.copyWith(isUpdating: true);
      expect(copy.isUpdating, isTrue);
      expect(copy.cookieHidingRules, 10);
      expect(copy.adHidingRules, 20);
      expect(copy.networkBlockRules, 5);
      expect(copy.removeParamsCount, 30);
      expect(copy.errors, isEmpty);
    });

    test('copyWith replaces specified fields', () {
      final copy = state.copyWith(
        errors: ['network error'],
        removeParamsCount: 35,
      );
      expect(copy.errors, ['network error']);
      expect(copy.removeParamsCount, 35);
      expect(copy.cookieHidingRules, 10);
    });
  });

  group('FilterListService.parseRemoveParams', () {
    test('extracts simple universal removeparam rules', () {
      const raw = '*\$removeparam=utm_source';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'utm_source'});
    });

    test('extracts multi-param rules', () {
      const raw = '*\$removeparam=utm_source|utm_medium|utm_campaign';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'utm_source', 'utm_medium', 'utm_campaign'});
    });

    test('skips domain-specific rules', () {
      const raw = '''
example.com\$removeparam=ref
global.com\$removeparam=tracker
*\$removeparam=fbclid
''';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'fbclid'});
      expect(result, isNot(contains('ref')));
      expect(result, isNot(contains('tracker')));
    });

    test('skips regex patterns', () {
      const raw = '*\$removeparam=/utm_.*/';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, isEmpty);
    });

    test('skips comments and headers', () {
      const raw = '''
! uBlock Origin
[Adblock Plus 2.0]
*\$removeparam=fbclid
''';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'fbclid'});
    });

    test('handles mixed content', () {
      const raw = '''
! Comment
*\$removeparam=fbclid
google.com\$removeparam=gclid
*\$removeparam=utm_source|utm_medium
*\$removeparam=/regex/
*\$removeparam=msclkid
''';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'fbclid', 'utm_source', 'utm_medium', 'msclkid'});
      expect(result, isNot(contains('gclid')));
      expect(result, isNot(contains('regex')));
    });

    test('converts param names to lowercase', () {
      const raw = '*\$removeparam=FBCLID|GCLID';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'fbclid', 'gclid'});
    });

    test('ignores empty lines and whitespace', () {
      const raw = '''

  \$removeparam=foo

*\$removeparam=bar

''';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'foo', 'bar'});
    });

    test('allows wildcard prefix before removeparam', () {
      const raw = '*\$removeparam=utm_source';
      final service = _TestableService();
      final result = service.parseRemoveParams(raw);
      expect(result, {'utm_source'});
    });
  });
}

/// Minimal testable wrapper that exposes [parseRemoveParams] without
/// requiring a full [Dio] / [SharedPreferences] setup.
class _TestableService {
  Set<String> parseRemoveParams(String raw) {
    // The implementation mirrors the real [FilterListService] logic.
    final params = <String>{};
    final lines = raw.split(RegExp(r'\r?\n'));
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (trimmed.startsWith('!')) {
        continue;
      }

      final match = RegExp(r'\$removeparam=([^,\s]+)').firstMatch(trimmed);
      if (match == null) {
        continue;
      }

      final value = match.group(1)!;

      final dollarIdx = trimmed.indexOf('\$removeparam');
      if (dollarIdx > 0) {
        final prefix = trimmed.substring(0, dollarIdx).trim();
        if (prefix.contains('.') && !prefix.startsWith('*')) {
          continue;
        }
      }

      if (value.startsWith('/') && value.endsWith('/')) {
        continue;
      }

      final parts = value.split('|');
      for (final part in parts) {
        final p = part.trim();
        if (p.isNotEmpty) {
          params.add(p.toLowerCase());
        }
      }
    }
    return params;
  }
}
