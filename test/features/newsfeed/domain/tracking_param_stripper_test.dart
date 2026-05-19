import 'package:cc_domain/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final knownParams = <String>{'utm_source', 'utm_medium', 'fbclid', 'gclid'};

  group('stripTrackingParams', () {
    test('returns original URL when no tracking params present', () {
      const url = 'https://example.com/article';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, url);
    });

    test('returns original URL when URI parsing fails', () {
      const url = 'not-a-valid-url';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, url);
    });

    test('strips single tracking param', () {
      const url = 'https://example.com/article?utm_source=newsletter';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/article');
    });

    test('strips multiple tracking params', () {
      const url =
          'https://example.com/article?utm_source=newsletter&fbclid=123&gclid=456';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/article');
    });

    test('strips only known params and leaves others intact', () {
      const url =
          'https://example.com/article?id=42&utm_source=newsletter&page=3';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/article?id=42&page=3');
    });

    test('is case-insensitive for param names', () {
      const url = 'https://example.com/article?UTM_SOURCE=newsletter';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/article');
    });

    test('removes all query params when every param is tracked', () {
      const url = 'https://example.com/article?utm_source=a&fbclid=b';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/article');
    });

    test('preserves fragment when stripping params', () {
      const url = 'https://example.com/article?utm_source=newsletter#section-2';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/article#section-2');
    });

    test('preserves path segments when stripping params', () {
      const url = 'https://example.com/blog/2024/01/post?utm_source=newsletter';
      final result = stripTrackingParams(url, knownParams: knownParams);
      expect(result, 'https://example.com/blog/2024/01/post');
    });
  });

  group('defaultRemoveParams', () {
    test('contains expected well-known params', () {
      final params = defaultRemoveParams();
      expect(params, contains('utm_source'));
      expect(params, contains('utm_medium'));
      expect(params, contains('fbclid'));
      expect(params, contains('gclid'));
      expect(params, contains('igshid'));
      expect(params, isNot(contains('ref')));
      expect(params, isNot(contains('id')));
    });

    test('returns a non-empty set', () {
      final params = defaultRemoveParams();
      expect(params, isNotEmpty);
    });
  });
}
