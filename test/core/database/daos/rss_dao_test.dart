import 'package:control_center/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull, Column;
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('RssDao - Feeds', () {
    test('watchFeeds returns empty when no feeds', () async {
      final feeds = await db.rssDao.watchFeeds().first;
      expect(feeds, isEmpty);
    });

    test('upsertFeed inserts a new feed', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Tech Blog',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      final feeds = await db.rssDao.watchFeeds().first;
      expect(feeds.length, 1);
      expect(feeds.first.name, 'Tech Blog');
      expect(feeds.first.url, 'https://example.com/rss');
      expect(feeds.first.enabled, isTrue);
    });

    test('upsertFeed updates existing feed', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Original',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Updated',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      final feeds = await db.rssDao.watchFeeds().first;
      expect(feeds.length, 1);
      expect(feeds.first.name, 'Updated');
    });

    test('getEnabledFeeds returns only enabled feeds', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Enabled',
          url: 'https://example.com/rss1',
          enabled: const Value(true),
        ),
      );
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-2',
          name: 'Disabled',
          url: 'https://example.com/rss2',
          enabled: const Value(false),
        ),
      );

      final enabled = await db.rssDao.getEnabledFeeds();
      expect(enabled.length, 1);
      expect(enabled.first.name, 'Enabled');
    });

    test('getFeedByUrl finds matching feed', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'My Feed',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      final found = await db.rssDao.getFeedByUrl('https://example.com/rss');
      expect(found, isNotNull);
      expect(found!.name, 'My Feed');
    });

    test('getFeedByUrl returns null for unknown URL', () async {
      final found = await db.rssDao.getFeedByUrl('https://unknown.com/rss');
      expect(found, isNull);
    });

    test('updateFeedFetchResult updates lastFetchedAt', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Feed',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      final now = DateTime(2026, 5, 18);
      await db.rssDao.updateFeedFetchResult(
        feedId: 'feed-1',
        fetchedAt: now,
      );

      final feed = await db.rssDao.getFeedByUrl('https://example.com/rss');
      expect(feed!.lastFetchedAt, now);
    });

    test('updateFeedFetchResult stores error', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Feed',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      await db.rssDao.updateFeedFetchResult(
        feedId: 'feed-1',
        fetchedAt: DateTime(2026, 5, 18),
        error: 'Connection timeout',
      );

      final feed = await db.rssDao.getFeedByUrl('https://example.com/rss');
      expect(feed!.lastError, 'Connection timeout');
    });

    test('setFeedEnabled toggles enabled state', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Feed',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      await db.rssDao.setFeedEnabled('feed-1', enabled: false);
      final feed = await db.rssDao.getFeedByUrl('https://example.com/rss');
      expect(feed!.enabled, isFalse);

      await db.rssDao.setFeedEnabled('feed-1', enabled: true);
      final enabled = await db.rssDao.getEnabledFeeds();
      expect(enabled.length, 1);
    });

    test('deleteFeed removes feed', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'To Delete',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      await db.rssDao.deleteFeed('feed-1');

      final feeds = await db.rssDao.watchFeeds().first;
      expect(feeds, isEmpty);
    });

    test('deleteFeed returns affected row count', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'feed-1',
          name: 'Feed',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );

      final count = await db.rssDao.deleteFeed('feed-1');
      expect(count, greaterThanOrEqualTo(1));
    });
  });

  group('RssDao - Articles', () {
    const feedId = 'feed-1';

    setUp(() async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: feedId,
          name: 'Test Feed',
          url: 'https://example.com/rss',
          enabled: const Value(true),
        ),
      );
    });

    test('watchAllArticles returns empty when no articles', () async {
      final articles = await db.rssDao.watchAllArticles().first;
      expect(articles, isEmpty);
    });

    test('watchSavedArticles returns empty when no saved', () async {
      final saved = await db.rssDao.watchSavedArticles().first;
      expect(saved, isEmpty);
    });

    test('upsertArticleFromFeed inserts new article', () async {
      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-1',
          feedId: feedId,
          title: 'Breaking News',
          guid: 'guid-1',
          link: 'https://example.com/article/1',
          saved: const Value(false),
          read: const Value(false),
        ),
      );

      final articles = await db.rssDao.watchAllArticles().first;
      expect(articles.length, 1);
      expect(articles.first.title, 'Breaking News');
    });

    test('upsertArticleFromFeed does not duplicate by guid', () async {
      final entry = RssArticlesTableCompanion.insert(
        id: 'art-1',
        feedId: feedId,
        title: 'Original',
        guid: 'guid-1',
        link: 'https://example.com/article/1',
        saved: const Value(false),
        read: const Value(false),
      );
      await db.rssDao.upsertArticleFromFeed(entry);
      // A later fetch assigns a fresh id but reuses the guid.
      await db.rssDao.upsertArticleFromFeed(
        entry.copyWith(id: const Value('art-2'), title: const Value('Updated')),
      );

      final articles = await db.rssDao.watchAllArticles().first;
      expect(articles.length, 1);
      // The original row survives; only its content is revalidated.
      expect(articles.first.id, 'art-1');
      expect(articles.first.title, 'Updated');
    });

    test('upsertArticleFromFeed refreshes content but keeps saved/read',
        () async {
      final entry = RssArticlesTableCompanion.insert(
        id: 'art-1',
        feedId: feedId,
        title: 'Original',
        guid: 'guid-1',
        link: 'https://example.com/article/1',
        summary: const Value('Old summary'),
        imageUrl: const Value('https://example.com/old.png'),
        saved: const Value(false),
        read: const Value(false),
      );
      await db.rssDao.upsertArticleFromFeed(entry);
      // The user bookmarks and reads it.
      await db.rssDao.setArticleSaved('art-1', saved: true);
      await db.rssDao.setArticleRead('art-1', read: true);

      // The source edits the story (new id + new content, same guid).
      await db.rssDao.upsertArticleFromFeed(
        entry.copyWith(
          id: const Value('art-2'),
          title: const Value('Updated'),
          summary: const Value('New summary'),
          imageUrl: const Value('https://example.com/new.png'),
        ),
      );

      final article = await db.rssDao.getArticleById('art-1');
      expect(article, isNotNull);
      expect(article!.title, 'Updated');
      expect(article.summary, 'New summary');
      expect(article.imageUrl, 'https://example.com/new.png');
      // User-owned flags must survive the revalidation.
      expect(article.saved, isTrue);
      expect(article.read, isTrue);
    });

    test('getArticleById returns article', () async {
      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-1',
          feedId: feedId,
          title: 'Found Article',
          guid: 'guid-1',
          link: 'https://example.com/article/1',
          saved: const Value(false),
          read: const Value(false),
        ),
      );

      final article = await db.rssDao.getArticleById('art-1');
      expect(article, isNotNull);
      expect(article!.title, 'Found Article');
    });

    test('getArticleById returns null for unknown id', () async {
      final article = await db.rssDao.getArticleById('nonexistent');
      expect(article, isNull);
    });

    test('setArticleSaved toggles saved state', () async {
      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-1',
          feedId: feedId,
          title: 'Article',
          guid: 'guid-1',
          link: 'https://example.com/article/1',
          saved: const Value(false),
          read: const Value(false),
        ),
      );

      await db.rssDao.setArticleSaved('art-1', saved: true);
      final savedArticles = await db.rssDao.watchSavedArticles().first;
      expect(savedArticles.length, 1);

      await db.rssDao.setArticleSaved('art-1', saved: false);
      final noSaved = await db.rssDao.watchSavedArticles().first;
      expect(noSaved, isEmpty);
    });

    test('setArticleRead toggles read state', () async {
      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-1',
          feedId: feedId,
          title: 'Article',
          guid: 'guid-1',
          link: 'https://example.com/article/1',
          saved: const Value(false),
          read: const Value(false),
        ),
      );

      await db.rssDao.setArticleRead('art-1', read: true);
      final article = await db.rssDao.getArticleById('art-1');
      expect(article!.read, isTrue);
    });

    test('markAllRead marks all articles as read', () async {
      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-1', feedId: feedId, title: 'A1', guid: 'g1',
          link: 'https://example.com/1',
          saved: const Value(false), read: const Value(false),
        ),
      );
      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-2', feedId: feedId, title: 'A2', guid: 'g2',
          link: 'https://example.com/2',
          saved: const Value(false), read: const Value(false),
        ),
      );

      await db.rssDao.markAllRead();

      final articles = await db.rssDao.watchAllArticles().first;
      for (final a in articles) {
        expect(a.read, isTrue);
      }
    });

    test('watchAllArticles only shows from enabled feeds', () async {
      await db.rssDao.upsertFeed(
        RssFeedsTableCompanion.insert(
          id: 'disabled-feed',
          name: 'Disabled',
          url: 'https://example.com/disabled',
          enabled: const Value(false),
        ),
      );

      await db.rssDao.upsertArticleFromFeed(
        RssArticlesTableCompanion.insert(
          id: 'art-disabled',
          feedId: 'disabled-feed',
          title: 'Hidden',
          guid: 'g-hidden',
          link: 'https://example.com/hidden',
          saved: const Value(false), read: const Value(false),
        ),
      );

      final articles = await db.rssDao.watchAllArticles().first;
      expect(articles.length, 0);
    });
  });
}
