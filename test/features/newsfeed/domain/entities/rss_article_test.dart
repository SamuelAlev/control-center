import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final testCreatedAt = DateTime(2024, 6, 1);

  RssArticle createArticle({
    String id = 'art-1',
    String feedId = 'feed-1',
    String guid = 'guid-1',
    String title = 'Test Article',
    String link = 'https://example.com/article',
    String summary = 'A test summary',
    String imageUrl = 'https://example.com/img.png',
    String author = 'Author',
    DateTime? publishedAt,
    bool saved = false,
    bool read = false,
    DateTime? createdAt,
  }) {
    return RssArticle(
      id: id,
      feedId: feedId,
      guid: guid,
      title: title,
      link: link,
      summary: summary,
      imageUrl: imageUrl,
      author: author,
      publishedAt: publishedAt,
      saved: saved,
      read: read,
      createdAt: createdAt ?? testCreatedAt,
    );
  }

  group('RssArticle', () {
    group('constructor', () {
      test('creates article with all fields', timeout: const Timeout.factor(2), () {
        final a = createArticle();
        expect(a.id, 'art-1');
        expect(a.feedId, 'feed-1');
        expect(a.guid, 'guid-1');
        expect(a.title, 'Test Article');
        expect(a.link, 'https://example.com/article');
        expect(a.summary, 'A test summary');
        expect(a.imageUrl, 'https://example.com/img.png');
        expect(a.author, 'Author');
        expect(a.publishedAt, isNull);
        expect(a.saved, isFalse);
        expect(a.read, isFalse);
        expect(a.createdAt, testCreatedAt);
      });

      test('creates article with publishedAt', timeout: const Timeout.factor(2), () {
        final pubDate = DateTime(2024, 5, 15);
        final a = createArticle(publishedAt: pubDate);
        expect(a.publishedAt, pubDate);
      });

      test('defaults summary, imageUrl, and author to empty strings', timeout: const Timeout.factor(2), () {
        final a = RssArticle(
          id: 'a',
          feedId: 'f',
          guid: 'g',
          title: 't',
          link: 'l',
          createdAt: testCreatedAt,
        );
        expect(a.summary, '');
        expect(a.imageUrl, '');
        expect(a.author, '');
      });

      test('asserts id is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssArticle(
            id: '',
            feedId: 'f',
            guid: 'g',
            title: 't',
            link: 'l',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts feedId is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssArticle(
            id: 'a',
            feedId: '',
            guid: 'g',
            title: 't',
            link: 'l',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts title is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssArticle(
            id: 'a',
            feedId: 'f',
            guid: 'g',
            title: '',
            link: 'l',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });

      test('asserts link is not empty', timeout: const Timeout.factor(2), () {
        expect(
          () => RssArticle(
            id: 'a',
            feedId: 'f',
            guid: 'g',
            title: 't',
            link: '',
            createdAt: testCreatedAt,
          ),
          throwsA(isA<AssertionError>()),
        );
      });
    });

    group('effectivePublishedAt', () {
      test('returns publishedAt when set', timeout: const Timeout.factor(2), () {
        final pubDate = DateTime(2024, 5, 15);
        final a = createArticle(publishedAt: pubDate);
        expect(a.effectivePublishedAt, pubDate);
      });

      test('returns createdAt when publishedAt is null', timeout: const Timeout.factor(2), () {
        final a = createArticle();
        expect(a.effectivePublishedAt, testCreatedAt);
      });
    });

    group('== and hashCode', () {
      test('== returns true for same id', timeout: const Timeout.factor(2), () {
        final a1 = createArticle();
        final a2 = createArticle(title: 'Different Title');
        expect(a1, equals(a2));
      });

      test('== returns false for different id', timeout: const Timeout.factor(2), () {
        final a1 = createArticle(id: 'art-1');
        final a2 = createArticle(id: 'art-2');
        expect(a1, isNot(equals(a2)));
      });

      test('== returns true for same reference', timeout: const Timeout.factor(2), () {
        final a = createArticle();
        expect(a, equals(a));
      });

      test('== returns false for different runtime type', timeout: const Timeout.factor(2), () {
        final a = createArticle();
        expect(a, isNot(equals('not an article')));
      });

      test('hashCode matches for equal articles', timeout: const Timeout.factor(2), () {
        final a1 = createArticle();
        final a2 = createArticle();
        expect(a1.hashCode, equals(a2.hashCode));
      });

      test('hashCode differs for different articles', timeout: const Timeout.factor(2), () {
        final a1 = createArticle(id: 'art-1');
        final a2 = createArticle(id: 'art-2');
        expect(a1.hashCode, isNot(equals(a2.hashCode)));
      });
    });
  });
}
