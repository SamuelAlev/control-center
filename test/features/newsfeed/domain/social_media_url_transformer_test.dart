import 'package:control_center/features/newsfeed/domain/social_media_url_transformer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('transformSocialMediaUrl', () {
    group('twitter.com', () {
      test('replaces twitter.com with xcancel.com', () {
        final result = transformSocialMediaUrl(
          'https://twitter.com/OpenAI/status/123',
        );
        expect(result, 'https://xcancel.com/OpenAI/status/123');
      });

      test('replaces www.twitter.com with xcancel.com', () {
        final result = transformSocialMediaUrl(
          'https://www.twitter.com/OpenAI/status/123',
        );
        expect(result, 'https://xcancel.com/OpenAI/status/123');
      });

      test('preserves path and query params', () {
        final result = transformSocialMediaUrl(
          'https://twitter.com/user/status/123?ref=share',
        );
        expect(result, 'https://xcancel.com/user/status/123?ref=share');
      });
    });

    group('x.com', () {
      test('replaces x.com with xcancel.com', () {
        final result = transformSocialMediaUrl(
          'https://x.com/Alibaba_Qwen/status/2056403591464984753',
        );
        expect(
          result,
          'https://xcancel.com/Alibaba_Qwen/status/2056403591464984753',
        );
      });

      test('replaces www.x.com with xcancel.com', () {
        final result = transformSocialMediaUrl(
          'https://www.x.com/username/status/456',
        );
        expect(result, 'https://xcancel.com/username/status/456');
      });
    });

    group('tiktok.com', () {
      test('replaces tiktok.com with vxtiktok.com', () {
        final result = transformSocialMediaUrl(
          'https://tiktok.com/@user/video/123',
        );
        expect(result, 'https://vxtiktok.com/@user/video/123');
      });

      test('replaces www.tiktok.com with vxtiktok.com', () {
        final result = transformSocialMediaUrl(
          'https://www.tiktok.com/@user/video/123',
        );
        expect(result, 'https://vxtiktok.com/@user/video/123');
      });
    });

    group('no match', () {
      test('returns url unchanged for non-social domains', () {
        final result = transformSocialMediaUrl(
          'https://example.com/article',
        );
        expect(result, 'https://example.com/article');
      });

      test('returns url unchanged for subdomains that are not social media', () {
        final result = transformSocialMediaUrl(
          'https://blog.twitter.com/engineering',
        );
        expect(result, 'https://blog.twitter.com/engineering');
      });
    });

    group('edge cases', () {
      test('returns empty string unchanged', () {
        expect(transformSocialMediaUrl(''), '');
      });

      test('handles http scheme', () {
        final result = transformSocialMediaUrl(
          'http://x.com/user/status/789',
        );
        expect(result, 'http://xcancel.com/user/status/789');
      });

      test('is case-insensitive for domain', () {
        final result = transformSocialMediaUrl(
          'https://X.COM/user/status',
        );
        expect(result, 'https://xcancel.com/user/status');
      });

      test('preserves fragment', () {
        final result = transformSocialMediaUrl(
          'https://x.com/user/status#section',
        );
        expect(result, 'https://xcancel.com/user/status#section');
      });

      test('handles invalid url gracefully', () {
        const invalid = 'not a url';
        expect(transformSocialMediaUrl(invalid), invalid);
      });
    });
  });
}
