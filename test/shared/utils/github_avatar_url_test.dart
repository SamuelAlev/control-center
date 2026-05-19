import 'package:control_center/shared/utils/github_avatar_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sizedGitHubAvatarUrl', () {
    test('appends s= sized to logicalSize * dpr for the avatars CDN', () {
      expect(
        sizedGitHubAvatarUrl(
          'https://avatars.githubusercontent.com/u/1',
          24,
          2,
        ),
        'https://avatars.githubusercontent.com/u/1?s=48',
      );
    });

    test(
      'uses & when the URL already has a query, preserving existing params',
      () {
        expect(
          sizedGitHubAvatarUrl(
            'https://avatars.githubusercontent.com/u/1?v=4',
            24,
            2,
          ),
          'https://avatars.githubusercontent.com/u/1?v=4&s=48',
        );
      },
    );

    test('does not corrupt an opaque existing token query', () {
      // The `u=` token can contain characters a queryParameters round-trip would
      // re-encode; raw append must leave it byte-for-byte.
      const url = 'https://avatars.githubusercontent.com/u/1?u=ab_cd-EF&v=4';
      expect(sizedGitHubAvatarUrl(url, 16, 1), '$url&s=32');
    });

    test('handles the github.com/<owner>.png redirect shorthand', () {
      expect(
        sizedGitHubAvatarUrl('https://github.com/octocat.png', 32, 2),
        'https://github.com/octocat.png?s=64',
      );
    });

    test('clamps s= to GitHub\'s 460px source cap', () {
      expect(
        sizedGitHubAvatarUrl(
          'https://avatars.githubusercontent.com/u/1',
          400,
          3,
        ),
        'https://avatars.githubusercontent.com/u/1?s=460',
      );
    });

    test('buckets up to the width ladder so nearby sizes share one fetch', () {
      // 17 * 1.5 = 25.5 -> 26 -> bucketed up to the 32px rung: a 14px row and
      // a 17px header then mint ONE URL and hit the same cache entry.
      expect(
        sizedGitHubAvatarUrl(
          'https://avatars.githubusercontent.com/u/1',
          17,
          1.5,
        ),
        'https://avatars.githubusercontent.com/u/1?s=32',
      );
      // Already on a rung: unchanged.
      expect(
        sizedGitHubAvatarUrl(
          'https://avatars.githubusercontent.com/u/1',
          24,
          2,
        ),
        'https://avatars.githubusercontent.com/u/1?s=48',
      );
    });

    test('returns non-GitHub hosts unchanged (favicons, banners)', () {
      const favicon = 'https://example.com/favicon.ico';
      expect(sizedGitHubAvatarUrl(favicon, 16, 2), favicon);
      const banner = 'https://cdn.example.com/og.jpg?w=1200';
      expect(sizedGitHubAvatarUrl(banner, 56, 2), banner);
      // github.com non-avatar paths must not be sized.
      const page = 'https://github.com/octocat';
      expect(sizedGitHubAvatarUrl(page, 32, 2), page);
    });

    test(
      'returns empty / non-positive-size / unparseable inputs unchanged',
      () {
        expect(sizedGitHubAvatarUrl('', 24, 2), '');
        expect(
          sizedGitHubAvatarUrl(
            'https://avatars.githubusercontent.com/u/1',
            0,
            2,
          ),
          'https://avatars.githubusercontent.com/u/1',
        );
      },
    );
  });
}
