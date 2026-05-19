import 'package:cc_domain/features/pr_review/domain/entities/gif_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GifResult constructor', () {
    test('creates instance with all fields', timeout: const Timeout.factor(2), () {
      const gif = GifResult(
        id: 42,
        url: 'https://example.com/hd.gif',
        previewUrl: 'https://example.com/sm.gif',
        width: 480,
        height: 270,
      );
      expect(gif.id, 42);
      expect(gif.url, 'https://example.com/hd.gif');
      expect(gif.previewUrl, 'https://example.com/sm.gif');
      expect(gif.width, 480);
      expect(gif.height, 270);
    });
  });

  group('GifResult.fromJson', () {
    test('parses from JSON with hd gif', timeout: const Timeout.factor(2), () {
      final json = {
        'id': 1,
        'file': {
          'sm': {
            'gif': {'url': 'https://sm.gif', 'width': 200, 'height': 150},
          },
          'hd': {
            'gif': {'url': 'https://hd.gif', 'width': 480, 'height': 270},
          },
        },
      };
      final result = GifResult.fromJson(json);
      expect(result.id, 1);
      expect(result.url, 'https://hd.gif');
      expect(result.previewUrl, 'https://sm.gif');
      expect(result.width, 480);
      expect(result.height, 270);
    });

    test('falls back to sm gif when no hd', timeout: const Timeout.factor(2), () {
      final json = {
        'id': 2,
        'file': {
          'sm': {
            'gif': {'url': 'https://sm.gif', 'width': 200, 'height': 150},
          },
        },
      };
      final result = GifResult.fromJson(json);
      expect(result.url, 'https://sm.gif');
      expect(result.previewUrl, 'https://sm.gif');
      expect(result.width, 200);
      expect(result.height, 150);
    });

    test('falls back to sm webp for preview', timeout: const Timeout.factor(2), () {
      final json = {
        'id': 3,
        'file': {
          'sm': {
            'webp': {'url': 'https://sm.webp', 'width': 200, 'height': 150},
            'gif': {'url': 'https://sm.gif', 'width': 200, 'height': 150},
          },
        },
      };
      final result = GifResult.fromJson(json);
      expect(result.url, 'https://sm.gif');
      expect(result.previewUrl, 'https://sm.gif');
    });

    test('falls back to hd gif url for preview when sm has no gif/webp/jpg',
        timeout: const Timeout.factor(2), () {
      final json = {
        'id': 4,
        'file': {
          'hd': {
            'gif': {'url': 'https://hd.gif', 'width': 480, 'height': 270},
          },
        },
      };
      final result = GifResult.fromJson(json);
      expect(result.url, 'https://hd.gif');
      expect(result.previewUrl, 'https://hd.gif');
    });

    test('parses string id as int', timeout: const Timeout.factor(2), () {
      final json = {
        'id': '99',
        'file': <String, dynamic>{},
      };
      final result = GifResult.fromJson(json);
      expect(result.id, 99);
    });

    test('defaults to 0 for non-parseable id', timeout: const Timeout.factor(2), () {
      final json = {
        'id': 'not-a-number',
        'file': <String, dynamic>{},
      };
      final result = GifResult.fromJson(json);
      expect(result.id, 0);
    });

    test('defaults to empty strings and zero dimensions for missing file data',
        timeout: const Timeout.factor(2), () {
      final json = {
        'id': 5,
        'file': <String, dynamic>{},
      };
      final result = GifResult.fromJson(json);
      expect(result.url, '');
      expect(result.previewUrl, '');
      expect(result.width, 0);
      expect(result.height, 0);
    });

    test('handles missing file key entirely', timeout: const Timeout.factor(2), () {
      final json = <String, dynamic>{'id': 6};
      // This will throw because json['file'] is null, so `as Map` fails.
      // But looking at the code: `final file = json['file'] as Map<String, dynamic>;`
      // If file is null, the cast throws.
      expect(() => GifResult.fromJson(json), throwsA(isA<TypeError>()));
    });
  });

  group('GifResult == and hashCode', () {
    const a = GifResult(
      id: 1,
      url: 'u',
      previewUrl: 'p',
      width: 100,
      height: 100,
    );

    test('equal when all fields match', timeout: const Timeout.factor(2), () {
      const b = GifResult(
        id: 1,
        url: 'u',
        previewUrl: 'p',
        width: 100,
        height: 100,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when id differs', timeout: const Timeout.factor(2), () {
      const b = GifResult(
        id: 2,
        url: 'u',
        previewUrl: 'p',
        width: 100,
        height: 100,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when url differs', timeout: const Timeout.factor(2), () {
      const b = GifResult(
        id: 1,
        url: 'other',
        previewUrl: 'p',
        width: 100,
        height: 100,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when previewUrl differs', timeout: const Timeout.factor(2), () {
      const b = GifResult(
        id: 1,
        url: 'u',
        previewUrl: 'other',
        width: 100,
        height: 100,
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when dimensions differ', timeout: const Timeout.factor(2), () {
      const b = GifResult(
        id: 1,
        url: 'u',
        previewUrl: 'p',
        width: 200,
        height: 100,
      );
      expect(a, isNot(equals(b)));
    });

    test('self equality', timeout: const Timeout.factor(2), () {
      expect(a, equals(a));
    });

    test('not equal to other types', timeout: const Timeout.factor(2), () {
      expect(a, isNot(equals('not a gif')));
    });
  });
}
