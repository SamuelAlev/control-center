import 'dart:convert';
import 'dart:ui';

import 'package:control_center/shared/widgets/markdown/markdown_media_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

/// The memo that turns "every attachment resizes the page when it loads" into
/// "once, ever".
///
/// The bug it exists for: a PR description with two screenshots painted four
/// different heights per image — a 20px spinner, a 140px failure card, another
/// spinner, then the real height — because a raw `user-attachments` URL cannot
/// be fetched, and the `body_html` refresh that fixes it mints a DIFFERENT URL
/// for the same bytes. Keyed on the URL, that refresh is a cache miss and the
/// settled image is torn back down mid-read.
void main() {
  setUp(MarkdownMediaMetrics.reset);

  group('markdownMediaKey', () {
    // The two forms of the same attachment. The raw one is what the markdown
    // body carries; the pre-signed one is what the body_html splice rewrites it
    // to. Same bytes, same shape, and the whole point of the memo is that the
    // rewrite is invisible.
    final raw = Uri.parse(
      'https://github.com/user-attachments/assets/'
      '3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
    );
    final signed = Uri.parse(
      'https://private-user-images.githubusercontent.com/47146443/'
      '1234567-3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d.png?jwt=abc.def.ghi',
    );

    test('the raw and pre-signed forms of one attachment share a key', () {
      expect(markdownMediaKey(raw), markdownMediaKey(signed));
    });

    test('a refreshed JWT does not change the key', () {
      final refreshed = Uri.parse(
        signed.toString().replaceFirst('jwt=abc.def.ghi', 'jwt=xyz.uvw.rst'),
      );
      expect(markdownMediaKey(refreshed), markdownMediaKey(signed));
    });

    test('two different attachments do not collide', () {
      final other = Uri.parse(
        'https://github.com/user-attachments/assets/'
        'aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee',
      );
      expect(markdownMediaKey(other), isNot(markdownMediaKey(raw)));
    });

    test('a non-GitHub URL keeps its query as part of its identity', () {
      // For most hosts the query IS the image. Two shields.io badges live at
      // one path and differ only in their parameters; collapsing them served
      // whichever loaded first for both — and, once the disk cache keyed on
      // this, kept doing so across restarts.
      final build = Uri.parse(
        'https://img.shields.io/static/v1?label=build&message=passing',
      );
      final coverage = Uri.parse(
        'https://img.shields.io/static/v1?label=coverage&message=92%25',
      );
      expect(markdownMediaKey(build), isNot(markdownMediaKey(coverage)));
      expect(markdownMediaKey(build), markdownMediaKey(Uri.parse('$build')));
    });

    test('a UUID in an unrelated host is not read as an attachment id', () {
      // The UUID scan is gated on the GitHub attachment hosts precisely so an
      // arbitrary CDN path containing one keeps its own identity.
      final one = Uri.parse(
        'https://cdn.example.test/3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d/a.png',
      );
      final two = Uri.parse(
        'https://cdn.example.test/3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d/b.png',
      );
      expect(markdownMediaKey(one), isNot(markdownMediaKey(two)));
    });
  });

  group('isGitHubAttachmentMedia', () {
    test('covers both attachment forms', () {
      expect(
        isGitHubAttachmentMedia(
          Uri.parse('https://github.com/user-attachments/assets/x'),
        ),
        isTrue,
      );
      expect(
        isGitHubAttachmentMedia(
          Uri.parse(
            'https://private-user-images.githubusercontent.com/1/a.png',
          ),
        ),
        isTrue,
      );
    });

    test('a badge host is not attachment media', () {
      // The distinction that keeps a 20px shields.io check from holding a
      // column-wide hole open until its bytes land.
      expect(
        isGitHubAttachmentMedia(Uri.parse('https://img.shields.io/badge/a-b')),
        isFalse,
      );
      expect(
        isGitHubAttachmentMedia(Uri.parse('https://github.com/owner/repo')),
        isFalse,
      );
    });
  });

  group('isUnsplicedUserAttachment', () {
    test('only the raw form, which is the unfetchable one', () {
      expect(
        isUnsplicedUserAttachment(
          Uri.parse('https://github.com/user-attachments/assets/x'),
        ),
        isTrue,
      );
      expect(
        isUnsplicedUserAttachment(
          Uri.parse(
            'https://private-user-images.githubusercontent.com/1/a.png',
          ),
        ),
        isFalse,
      );
    });
  });

  group('MarkdownMediaMetrics', () {
    final uri = Uri.parse(
      'https://github.com/user-attachments/assets/'
      '3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
    );

    test('a measured size is readable back through either URL form', () {
      MarkdownMediaMetrics.record(uri, const Size(1600, 900));
      final signed = Uri.parse(
        'https://private-user-images.githubusercontent.com/47146443/'
        '1-3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d.png?jwt=zzz',
      );
      expect(MarkdownMediaMetrics.sizeOf(signed), const Size(1600, 900));
    });

    test('a degenerate size is refused, never memoized', () {
      // A zero-height reserve would collapse the box and reintroduce the jump
      // it exists to prevent, so a failed probe must not be able to write one.
      MarkdownMediaMetrics.record(uri, Size.zero);
      MarkdownMediaMetrics.record(uri, const Size(100, double.nan));
      MarkdownMediaMetrics.record(uri, const Size(-4, 10));
      expect(MarkdownMediaMetrics.sizeOf(uri), isNull);
    });
  });

  group('reservedMediaIntrinsic', () {
    final attachment = Uri.parse(
      'https://github.com/user-attachments/assets/'
      '3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d',
    );

    test('a measured size outranks the default guess', () {
      MarkdownMediaMetrics.record(attachment, const Size(1000, 250));
      expect(
        reservedMediaIntrinsic(uri: attachment, columnWidth: 700),
        const Size(1000, 250),
      );
    });

    test('an unmeasured attachment reserves the default aspect', () {
      final reserved = reservedMediaIntrinsic(
        uri: attachment,
        columnWidth: 700,
      );
      expect(reserved, isNotNull);
      // At least column-wide, or the resolver would read it as "render at
      // natural size" and reserve a box narrower than the screenshot fills.
      expect(reserved!.width, greaterThanOrEqualTo(700));
      expect(reserved.height / reserved.width, closeTo(9 / 16, 0.0001));
    });

    test('an un-hinted non-attachment reserves nothing', () {
      // Badges and inline icons keep the small placeholder: nothing here knows
      // whether the next byte is a 16px check or a screenshot.
      expect(
        reservedMediaIntrinsic(
          uri: Uri.parse('https://img.shields.io/badge/a-b'),
          columnWidth: 700,
        ),
        isNull,
      );
    });

    test('a declared width/height pair is left to the resolver', () {
      // Measured beats declared, so a synthetic intrinsic must not be handed
      // back to outrank the author's own attributes.
      expect(
        reservedMediaIntrinsic(
          uri: attachment,
          columnWidth: 700,
          hasDimensionHint: true,
        ),
        isNull,
      );
    });

    test('a measured size still wins over a declared pair', () {
      MarkdownMediaMetrics.record(attachment, const Size(800, 200));
      expect(
        reservedMediaIntrinsic(
          uri: attachment,
          columnWidth: 700,
          hasDimensionHint: true,
        ),
        const Size(800, 200),
      );
    });
  });

  group('hasExpiredAttachmentJwt', () {
    // A pre-signed attachment URL is only good for about five minutes, so a
    // cached PR row older than that splices in URLs that are already dead. The
    // renderer used to learn this by requesting one and reading the 403; the
    // token says so for free, before any socket is opened.
    String urlWithJwt(Map<String, Object?> payload) {
      String seg(Object? v) =>
          base64Url.encode(utf8.encode(jsonEncode(v))).replaceAll('=', '');
      final jwt = '${seg({'alg': 'HS256'})}.${seg(payload)}.sig';
      return 'https://private-user-images.githubusercontent.com/1/'
          'a-3f2b1c4d-5e6f-4a7b-8c9d-0e1f2a3b4c5d.png?jwt=$jwt';
    }

    final now = DateTime.utc(2026, 8, 30, 12);
    int epoch(DateTime t) => t.millisecondsSinceEpoch ~/ 1000;

    test('an expired token is refused before the fetch', () {
      final uri = Uri.parse(
        urlWithJwt({'exp': epoch(now.subtract(const Duration(minutes: 10)))}),
      );
      expect(hasExpiredAttachmentJwt(uri, now: now), isTrue);
      expect(needsAttachmentCredentials(uri, now: now), isTrue);
    });

    test('a malformed percent-escape anywhere in the query cannot throw', () {
      // `Uri.queryParameters` percent-decodes the WHOLE query eagerly and
      // throws on a truncated multibyte escape. Reading it outside the guard
      // turned any such URL in any document into an exception out of
      // `initState`, taking the widget subtree with it.
      final uri = Uri.parse(
        'https://private-user-images.githubusercontent.com/1/a.png'
        '?jwt=abc.def.ghi&x=%E0%A4%A',
      );
      expect(() => hasExpiredAttachmentJwt(uri, now: now), returnsNormally);
      expect(hasExpiredAttachmentJwt(uri, now: now), isFalse);
    });

    test('a non-GitHub host carrying a jwt param is never judged', () {
      // We decode one vendor's token shape. Off a PR body there is no
      // body_html refresh lane, so a wrong "expired" verdict is an image that
      // never loads and never recovers.
      final expired = urlWithJwt({
        'exp': epoch(now.subtract(const Duration(days: 1))),
      });
      final elsewhere = Uri.parse(
        expired.replaceFirst(
          'private-user-images.githubusercontent.com',
          'cdn.example.test',
        ),
      );
      expect(hasExpiredAttachmentJwt(elsewhere, now: now), isFalse);
    });

    test(
      'a clock ahead by less than the skew allowance defers to the server',
      () {
        // A machine running fast would otherwise call every freshly-minted token
        // dead and lock private attachments out permanently.
        final uri = Uri.parse(
          urlWithJwt({'exp': epoch(now.subtract(const Duration(seconds: 90)))}),
        );
        expect(hasExpiredAttachmentJwt(uri, now: now), isFalse);
      },
    );

    test('a live token is fetched normally', () {
      final uri = Uri.parse(
        urlWithJwt({'exp': epoch(now.add(const Duration(minutes: 4)))}),
      );
      expect(hasExpiredAttachmentJwt(uri, now: now), isFalse);
      expect(needsAttachmentCredentials(uri, now: now), isFalse);
    });

    test('a long-dead token is refused', () {
      // Past any plausible clock skew, so the reading is trustworthy.
      final uri = Uri.parse(
        urlWithJwt({'exp': epoch(now.subtract(const Duration(hours: 1)))}),
      );
      expect(hasExpiredAttachmentJwt(uri, now: now), isTrue);
    });

    test('anything unparseable fails OPEN', () {
      // This is a "do not bother asking" decision, never an authorization one,
      // so a shape it does not understand must still get its fetch rather than
      // silently never loading.
      for (final raw in <String>[
        'https://private-user-images.githubusercontent.com/1/a.png?jwt=notajwt',
        'https://private-user-images.githubusercontent.com/1/a.png?jwt=a.b.c',
        'https://private-user-images.githubusercontent.com/1/a.png',
        'https://cdn.example.test/a.png',
      ]) {
        expect(
          hasExpiredAttachmentJwt(Uri.parse(raw), now: now),
          isFalse,
          reason: raw,
        );
      }
    });

    test('a token with no exp claim is left alone', () {
      final uri = Uri.parse(urlWithJwt({'iss': 'github'}));
      expect(hasExpiredAttachmentJwt(uri, now: now), isFalse);
    });
  });
}
