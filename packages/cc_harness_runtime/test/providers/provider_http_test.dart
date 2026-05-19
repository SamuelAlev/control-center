import 'package:cc_harness_runtime/src/providers/provider_http.dart';
import 'package:test/test.dart';

/// Exercises [parseRetryAfter] — the pure Retry-After header parser with its
/// delta-seconds / HTTP-date / clamp-to-5min logic.
void main() {
  group('parseRetryAfter', () {
    test('null or empty returns null', () {
      expect(parseRetryAfter(null), isNull);
      expect(parseRetryAfter(''), isNull);
    });

    test('parses delta-seconds', () {
      expect(parseRetryAfter('30'), const Duration(seconds: 30));
      expect(parseRetryAfter('  120  '), const Duration(seconds: 120));
    });

    test('clamps negative to zero', () {
      expect(parseRetryAfter('-5'), Duration.zero);
    });

    test('clamps to 5 minutes max', () {
      expect(parseRetryAfter('99999'), const Duration(minutes: 5));
    });

    test('returns null for unparseable input', () {
      expect(parseRetryAfter('not-a-date'), isNull);
    });
  });

  group('ProviderHttpException', () {
    test('stores fields and formats toString', () {
      final e = ProviderHttpException(
        429,
        'rate limited',
        retryAfter: const Duration(seconds: 60),
      );
      expect(e.statusCode, 429);
      expect(e.body, 'rate limited');
      expect(e.retryAfter, const Duration(seconds: 60));
      expect(e.toString(), contains('429'));
      expect(e.toString(), contains('rate limited'));
    });

    test('retryAfter is optional', () {
      final e = ProviderHttpException(401, 'unauthorized');
      expect(e.retryAfter, isNull);
    });
  });
}
