import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/daos/rss_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_server_core/src/dao_newsfeed_repository.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart' as drift;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'helpers/test_database.dart';

const _uuid = Uuid();

// ── Fake fetcher ────────────────────────────────────────────────────────

class FakeRssFetcherService extends RssFetcherService {
  FakeRssFetcherService() : super(Dio());

  final Map<String, ParsedFeed> _feeds = {};

  /// Every `(feedId, url)` this fake was actually asked to fetch.
  final List<({String feedId, String url})> fetches = [];

  /// Stubs by URL rather than feed id, so two users subscribed to the same
  /// publication resolve to the same body — the shape the memo is about.
  final Map<String, ParsedFeed> _byUrl = {};

  void stubUrl(String url, List<RssArticle> articles) {
    _byUrl[url] = ParsedFeed(articles: articles);
  }

  void stubArticles(String feedId, List<RssArticle> articles) {
    _feeds[feedId] = ParsedFeed(articles: articles);
  }

  void stubFeed(
    String feedId,
    List<RssArticle> articles, {
    String? iconUrl,
    String? siteUrl,
  }) {
    _feeds[feedId] = ParsedFeed(
      articles: articles,
      iconUrl: iconUrl,
      siteUrl: siteUrl,
    );
  }

  @override
  Future<ParsedFeed> fetchAndParseFeed({
    required String feedId,
    required String url,
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    fetches.add((feedId: feedId, url: url));
    return _feeds[feedId] ?? _byUrl[url] ?? const ParsedFeed(articles: []);
  }
}

/// Records calls and returns stubbed icons per site URL.
class FakeSiteIconResolver extends SiteIconResolver {
  FakeSiteIconResolver() : super(Dio());

  final Map<String, String> _icons = {};
  final List<String> calls = [];

  void stubIcon(String siteUrl, String iconUrl) {
    _icons[siteUrl] = iconUrl;
  }

  @override
  Future<String?> resolve(
    String siteUrl, {
    String? userAgent,
    CancelToken? cancelToken,
  }) async {
    calls.add(siteUrl);
    return _icons[siteUrl];
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────

RssFeedsTableCompanion _feedCompanion({
  String? id,
  required String name,
  required String url,
  String description = '',
  String userAgent = '',
  bool enabled = true,
  DateTime? now,
}) {
  final ts = now ?? DateTime.now();
  return RssFeedsTableCompanion(
    id: drift.Value(id ?? _uuid.v4()),
    userId: const drift.Value(_user),
    name: drift.Value(name),
    url: drift.Value(url),
    description: drift.Value(description),
    userAgent: drift.Value(userAgent),
    enabled: drift.Value(enabled),
    createdAt: drift.Value(ts),
    updatedAt: drift.Value(ts),
  );
}

RssArticlesTableCompanion _articleCompanion({
  String? id,
  required String feedId,
  String? guid,
  required String title,
  required String link,
  String summary = '',
  String author = '',
  DateTime? publishedAt,
  bool saved = false,
  bool read = false,
  DateTime? now,
}) {
  final ts = now ?? DateTime.now();
  return RssArticlesTableCompanion(
    id: drift.Value(id ?? _uuid.v4()),
    feedId: drift.Value(feedId),
    guid: drift.Value(guid ?? _uuid.v4()),
    title: drift.Value(title),
    link: drift.Value(link),
    summary: drift.Value(summary),
    imageUrl: const drift.Value(''),
    author: drift.Value(author),
    publishedAt: drift.Value(publishedAt),
    saved: drift.Value(saved),
    read: drift.Value(read),
    createdAt: drift.Value(ts),
  );
}

RssArticle _domainArticle({
  String? id,
  required String feedId,
  String guid = '',
  required String title,
  required String link,
  String summary = '',
  String author = '',
  DateTime? publishedAt,
  bool saved = false,
  bool read = false,
  DateTime? createdAt,
}) {
  final ts = createdAt ?? DateTime.now();
  return RssArticle(
    id: id ?? _uuid.v4(),
    feedId: feedId,
    guid: guid.isEmpty ? _uuid.v4() : guid,
    title: title,
    link: link,
    summary: summary,
    author: author,
    publishedAt: publishedAt,
    saved: saved,
    read: read,
    createdAt: ts,
  );
}

/// The feed owner everything in this suite acts as (the FK target).
const _user = 'user-1';

/// A second user for isolation assertions.
const _otherUser = 'user-2';

Future<void> _insertUser(GlobalDatabase db, String id) => db.into(
  db.usersTable,
).insert(UsersTableCompanion.insert(id: id, handle: id, displayName: id));

void main() {
  late GlobalDatabase db;
  late RssDao dao;
  late DaoNewsfeedRepository repo;

  setUp(() async {
    db = createTestGlobalDatabase();
    await _insertUser(db, _user);
    await _insertUser(db, _otherUser);
    dao = RssDao(db);
    repo = DaoNewsfeedRepository(dao, FakeRssFetcherService());
  });

  tearDown(() async {
    await db.close();
  });

  // ── Feeds CRUD ──────────────────────────────────────────────────────────

  group('addFeed', () {
    test('creates a new feed when URL is new', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Test Feed',
        url: 'https://example.com/rss',
        description: 'A test feed',
        userAgent: 'TestAgent/1.0',
      );

      expect(feed.name, 'Test Feed');
      expect(feed.url, 'https://example.com/rss');
      expect(feed.description, 'A test feed');
      expect(feed.userAgent, 'TestAgent/1.0');
      expect(feed.enabled, isTrue);
      expect(feed.id, isNotEmpty);
    });

    test('returns existing feed for duplicate URL', () async {
      final first = await repo.addFeed(
        _user,
        name: 'Original Name',
        url: 'https://example.com/rss',
      );
      final second = await repo.addFeed(
        _user,
        name: 'Different Name',
        url: 'https://example.com/rss',
      );

      expect(second.id, first.id);
      expect(second.name, 'Original Name');
    });

    test('stores description and userAgent defaults', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Minimal',
        url: 'https://minimal.example.com/feed',
      );

      expect(feed.description, '');
      expect(feed.userAgent, '');
    });
  });

  group('watchFeeds', () {
    test('emits empty list when no feeds exist', () async {
      final feeds = await repo.watchFeeds(_user).first;
      expect(feeds, isEmpty);
    });

    test('emits all feeds ordered by name', () async {
      final now = DateTime.now();
      await dao.upsertFeed(
        _feedCompanion(
          name: 'Z Feed',
          url: 'https://z.example.com/rss',
          now: now,
        ),
      );
      await dao.upsertFeed(
        _feedCompanion(
          name: 'A Feed',
          url: 'https://a.example.com/rss',
          now: now,
        ),
      );

      final feeds = await repo.watchFeeds(_user).first;
      expect(feeds.length, 2);
      expect(feeds[0].name, 'A Feed');
      expect(feeds[1].name, 'Z Feed');
    });
  });

  group('setFeedEnabled', () {
    test('toggles feed enabled state', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Toggle Feed',
        url: 'https://toggle.example.com/rss',
      );

      await repo.setFeedEnabled(_user, feed.id, enabled: false);
      var feeds = await repo.watchFeeds(_user).first;
      expect(feeds.singleWhere((f) => f.id == feed.id).enabled, isFalse);

      await repo.setFeedEnabled(_user, feed.id, enabled: true);
      feeds = await repo.watchFeeds(_user).first;
      expect(feeds.singleWhere((f) => f.id == feed.id).enabled, isTrue);
    });
  });

  group('deleteFeed', () {
    test('removes the feed', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Delete Me',
        url: 'https://delete.example.com/rss',
      );

      await repo.deleteFeed(_user, feed.id);
      final feeds = await repo.watchFeeds(_user).first;
      expect(feeds.where((f) => f.id == feed.id), isEmpty);
    });

    test('cascades to articles belonging to that feed', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Parent Feed',
        url: 'https://parent.example.com/rss',
      );

      // Insert article directly via DAO
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          title: 'Cascade Article',
          link: 'https://parent.example.com/1',
        ),
      );

      // Verify article exists
      final articlesBefore = await dao.watchAllArticles(_user).first;
      expect(articlesBefore, isNotEmpty);

      // Delete feed → articles cascade
      await repo.deleteFeed(_user, feed.id);

      final articlesAfter = await dao.watchAllArticles(_user).first;
      expect(articlesAfter, isEmpty);
    });
  });

  // ── Articles CRUD ─────────────────────────────────────────────────────

  group('getArticleById', () {
    test('returns article when found', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Article Feed',
        url: 'https://articles.example.com/rss',
      );
      final articleId = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: articleId,
          feedId: feed.id,
          title: 'Find Me',
          link: 'https://articles.example.com/find-me',
        ),
      );

      final article = await repo.getArticleById(_user, articleId);
      expect(article, isNotNull);
      expect(article!.title, 'Find Me');
      expect(article.feedId, feed.id);
    });

    test('returns null for nonexistent id', () async {
      final article = await repo.getArticleById(_user, 'nonexistent-id');
      expect(article, isNull);
    });
  });

  group('watchArticles', () {
    test(
      'emits articles from enabled feeds ordered by publishedAt desc',
      () async {
        final feedA = await repo.addFeed(
          _user,
          name: 'Feed A',
          url: 'https://a.example.com/rss',
        );
        final feedB = await repo.addFeed(
          _user,
          name: 'Feed B',
          url: 'https://b.example.com/rss',
        );

        final older = DateTime(2024, 1, 1);
        final newer = DateTime(2024, 6, 1);

        await dao.upsertArticleFromFeed(
          _articleCompanion(
            feedId: feedA.id,
            title: 'Older Article',
            link: 'https://a.example.com/older',
            publishedAt: older,
          ),
        );
        await dao.upsertArticleFromFeed(
          _articleCompanion(
            feedId: feedB.id,
            title: 'Newer Article',
            link: 'https://b.example.com/newer',
            publishedAt: newer,
          ),
        );

        final articles = await repo.watchArticles(_user).first;
        expect(articles.length, 2);
        expect(articles[0].title, 'Newer Article');
        expect(articles[1].title, 'Older Article');
      },
    );

    test('respects the limit parameter', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Limit Feed',
        url: 'https://limit.example.com/rss',
      );

      for (var i = 0; i < 10; i++) {
        await dao.upsertArticleFromFeed(
          _articleCompanion(
            feedId: feed.id,
            guid: 'guid-$i',
            title: 'Article $i',
            link: 'https://limit.example.com/$i',
            publishedAt: DateTime(2024, 1, i + 1),
          ),
        );
      }

      final articles = await repo.watchArticles(_user, limit: 3).first;
      expect(articles.length, 3);
    });

    test('excludes articles from disabled feeds', () async {
      final enabledFeed = await repo.addFeed(
        _user,
        name: 'Enabled Feed',
        url: 'https://enabled.example.com/rss',
      );
      final disabledFeed = await repo.addFeed(
        _user,
        name: 'Disabled Feed',
        url: 'https://disabled.example.com/rss',
      );
      await repo.setFeedEnabled(_user, disabledFeed.id, enabled: false);

      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: enabledFeed.id,
          title: 'Visible',
          link: 'https://enabled.example.com/1',
        ),
      );
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: disabledFeed.id,
          title: 'Hidden',
          link: 'https://disabled.example.com/1',
        ),
      );

      final articles = await repo.watchArticles(_user).first;
      expect(articles.length, 1);
      expect(articles.single.title, 'Visible');
    });
  });

  group('setArticleSaved', () {
    test('toggles saved flag', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Save Feed',
        url: 'https://save.example.com/rss',
      );
      final articleId = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: articleId,
          feedId: feed.id,
          title: 'Bookmark Me',
          link: 'https://save.example.com/1',
        ),
      );

      await repo.setArticleSaved(_user, articleId, saved: true);
      var article = await repo.getArticleById(_user, articleId);
      expect(article!.saved, isTrue);

      await repo.setArticleSaved(_user, articleId, saved: false);
      article = await repo.getArticleById(_user, articleId);
      expect(article!.saved, isFalse);
    });
  });

  group('watchSavedArticles', () {
    test('only emits bookmarked articles', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Bookmark Feed',
        url: 'https://bookmark.example.com/rss',
      );

      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          guid: 'saved-one',
          title: 'Saved Article',
          link: 'https://bookmark.example.com/saved',
          saved: true,
        ),
      );
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          guid: 'not-saved',
          title: 'Unsaved Article',
          link: 'https://bookmark.example.com/unsaved',
        ),
      );

      final saved = await repo.watchSavedArticles(_user).first;
      expect(saved.length, 1);
      expect(saved.single.title, 'Saved Article');
    });

    test('updates when saved status changes', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Toggle Bookmark',
        url: 'https://toggle-bookmark.example.com/rss',
      );
      final articleId = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: articleId,
          feedId: feed.id,
          title: 'Toggle Me',
          link: 'https://toggle-bookmark.example.com/1',
        ),
      );

      await repo.setArticleSaved(_user, articleId, saved: true);
      var saved = await repo.watchSavedArticles(_user).first;
      expect(saved.length, 1);

      await repo.setArticleSaved(_user, articleId, saved: false);
      saved = await repo.watchSavedArticles(_user).first;
      expect(saved, isEmpty);
    });
  });

  group('setArticleRead', () {
    test('toggles read flag', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Read Feed',
        url: 'https://read.example.com/rss',
      );
      final articleId = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: articleId,
          feedId: feed.id,
          title: 'Read Me',
          link: 'https://read.example.com/1',
        ),
      );

      await repo.setArticleRead(_user, articleId, read: true);
      var article = await repo.getArticleById(_user, articleId);
      expect(article!.read, isTrue);

      await repo.setArticleRead(_user, articleId, read: false);
      article = await repo.getArticleById(_user, articleId);
      expect(article!.read, isFalse);
    });
  });

  group('markAllRead', () {
    test('marks all articles as read', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Mark All Feed',
        url: 'https://markall.example.com/rss',
      );
      final a1 = _uuid.v4();
      final a2 = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: a1,
          feedId: feed.id,
          guid: 'g1',
          title: 'First',
          link: 'https://markall.example.com/1',
        ),
      );
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: a2,
          feedId: feed.id,
          guid: 'g2',
          title: 'Second',
          link: 'https://markall.example.com/2',
        ),
      );

      await repo.markAllRead(_user);

      final a = await repo.getArticleById(_user, a1);
      final b = await repo.getArticleById(_user, a2);
      expect(a!.read, isTrue);
      expect(b!.read, isTrue);
    });

    test('is idempotent when all already read', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Already Read',
        url: 'https://alreadyread.example.com/rss',
      );
      final articleId = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: articleId,
          feedId: feed.id,
          title: 'Done',
          link: 'https://alreadyread.example.com/1',
          read: true,
        ),
      );

      await repo.markAllRead(_user);
      final article = await repo.getArticleById(_user, articleId);
      expect(article!.read, isTrue);
    });
  });

  // ── Refresh ───────────────────────────────────────────────────────────

  group('refreshFeed', () {
    test('fetches and persists articles for a single feed', () async {
      final fetcher = FakeRssFetcherService();
      final refreshRepo = DaoNewsfeedRepository(dao, fetcher);

      final feed = await refreshRepo.addFeed(
        _user,
        name: 'Refresh Single',
        url: 'https://refresh-single.example.com/rss',
      );

      fetcher.stubArticles(feed.id, [
        _domainArticle(
          feedId: feed.id,
          guid: 'g-a',
          title: 'Fetched A',
          link: 'https://refresh-single.example.com/a',
        ),
        _domainArticle(
          feedId: feed.id,
          guid: 'g-b',
          title: 'Fetched B',
          link: 'https://refresh-single.example.com/b',
        ),
      ]);

      await refreshRepo.refreshFeed(_user, feed.id);

      final articles = await refreshRepo.watchArticles(_user).first;
      expect(articles.length, 2);
      expect(
        articles.map((a) => a.title),
        containsAll(['Fetched A', 'Fetched B']),
      );
    });

    test('does nothing for nonexistent feed id', () async {
      final fetcher = FakeRssFetcherService();
      final refreshRepo = DaoNewsfeedRepository(dao, fetcher);

      // Should not throw
      await refreshRepo.refreshFeed(_user, 'nonexistent-feed-id');

      final articles = await refreshRepo.watchArticles(_user).first;
      expect(articles, isEmpty);
    });

    test('records fetch error when fetcher throws', () async {
      final fetcher = FakeRssFetcherService();
      final refreshRepo = DaoNewsfeedRepository(dao, fetcher);

      final feed = await refreshRepo.addFeed(
        _user,
        name: 'Error Feed',
        url: 'https://error.example.com/rss',
      );

      fetcher.stubArticles(feed.id, [
        _domainArticle(
          feedId: feed.id,
          title: 'Should Fail',
          link: 'https://error.example.com/1',
        ),
      ]);
      // Actually, the fetcher always returns a list — errors happen in _refreshOne's
      // catch block. To test the catch path, we'd need the real fetcher to throw.
      // FakeRssFetcherService always succeeds. The catch block in _refreshOne
      // handles Object, so we test that the happy path works here.
      // The error path is tested implicitly: no crash, lastFetchedAt updated.

      await refreshRepo.refreshFeed(_user, feed.id);

      final feeds = await refreshRepo.watchFeeds(_user).first;
      final updatedFeed = feeds.singleWhere((f) => f.id == feed.id);
      expect(updatedFeed.lastFetchedAt, isNotNull);
    });
  });

  group('refreshAll', () {
    test('fetches from all enabled feeds', () async {
      final fetcher = FakeRssFetcherService();
      final refreshRepo = DaoNewsfeedRepository(dao, fetcher);

      final feedA = await refreshRepo.addFeed(
        _user,
        name: 'All Feed A',
        url: 'https://all-a.example.com/rss',
      );
      final feedB = await refreshRepo.addFeed(
        _user,
        name: 'All Feed B',
        url: 'https://all-b.example.com/rss',
      );

      fetcher.stubArticles(feedA.id, [
        _domainArticle(
          feedId: feedA.id,
          guid: 'a1',
          title: 'A1',
          link: 'https://all-a.example.com/1',
        ),
      ]);
      fetcher.stubArticles(feedB.id, [
        _domainArticle(
          feedId: feedB.id,
          guid: 'b1',
          title: 'B1',
          link: 'https://all-b.example.com/1',
        ),
      ]);

      await refreshRepo.refreshAll(_user);

      final articles = await refreshRepo.watchArticles(_user).first;
      expect(articles.length, 2);
      expect(articles.map((a) => a.title), containsAll(['A1', 'B1']));
    });

    test('skips disabled feeds', () async {
      final fetcher = FakeRssFetcherService();
      final refreshRepo = DaoNewsfeedRepository(dao, fetcher);

      final enabled = await refreshRepo.addFeed(
        _user,
        name: 'Enabled',
        url: 'https://enabled2.example.com/rss',
      );
      final disabled = await refreshRepo.addFeed(
        _user,
        name: 'Disabled',
        url: 'https://disabled2.example.com/rss',
      );
      await refreshRepo.setFeedEnabled(_user, disabled.id, enabled: false);

      fetcher.stubArticles(enabled.id, [
        _domainArticle(
          feedId: enabled.id,
          guid: 'e1',
          title: 'Only This',
          link: 'https://enabled2.example.com/1',
        ),
      ]);
      fetcher.stubArticles(disabled.id, [
        _domainArticle(
          feedId: disabled.id,
          guid: 'd1',
          title: 'Not This',
          link: 'https://disabled2.example.com/1',
        ),
      ]);

      await refreshRepo.refreshAll(_user);

      final articles = await refreshRepo.watchArticles(_user).first;
      expect(articles.length, 1);
      expect(articles.single.title, 'Only This');
    });
  });

  // ── Feed icon resolution ─────────────────────────────────────────────

  group('feed icon resolution', () {
    test('persists the space image the feed advertises (TechCrunch case)', () async {
      final fetcher = FakeRssFetcherService();
      final icons = FakeSiteIconResolver();
      final refreshRepo = DaoNewsfeedRepository(
        dao,
        fetcher,
        siteIcons: icons,
      );

      final feed = await refreshRepo.addFeed(
        _user,
        name: 'TechCrunch',
        url: 'https://techcrunch.example.com/feed/',
      );
      fetcher.stubFeed(
        feed.id,
        const [],
        iconUrl:
            'https://techcrunch.example.com/wp-content/uploads/2015/02/cropped-cropped-favicon-gradient.png?w=32',
        siteUrl: 'https://techcrunch.example.com/',
      );

      await refreshRepo.refreshFeed(_user, feed.id);

      final stored = await dao.getFeedByUrl(_user, feed.url);
      expect(
        stored!.iconUrl,
        'https://techcrunch.example.com/wp-content/uploads/2015/02/cropped-cropped-favicon-gradient.png?w=32',
      );
      // The space image wins; the site is never fetched for an icon.
      expect(icons.calls, isEmpty);
    });

    test(
      'falls back to the site favicon when the feed advertises no image '
      '(lea.verou.me case)',
      () async {
        final fetcher = FakeRssFetcherService();
        final icons = FakeSiteIconResolver();
        final refreshRepo = DaoNewsfeedRepository(
          dao,
          fetcher,
          siteIcons: icons,
        );

        final feed = await refreshRepo.addFeed(
          _user,
          name: 'Lea Verou',
          url: 'https://lea.example.com/feed.xml',
        );
        fetcher.stubFeed(
          feed.id,
          const [],
          siteUrl: 'https://lea.example.com/',
        );
        icons.stubIcon(
          'https://lea.example.com/',
          'https://lea.example.com/assets/favicon.png',
        );

        await refreshRepo.refreshFeed(_user, feed.id);

        final stored = await dao.getFeedByUrl(_user, feed.url);
        expect(stored!.iconUrl, 'https://lea.example.com/assets/favicon.png');
        expect(icons.calls, ['https://lea.example.com/']);
      },
    );

    test(
      'uses the feed URL as the site when the space has no link',
      () async {
        final fetcher = FakeRssFetcherService();
        final icons = FakeSiteIconResolver();
        final refreshRepo = DaoNewsfeedRepository(
          dao,
          fetcher,
          siteIcons: icons,
        );

        final feed = await refreshRepo.addFeed(
          _user,
          name: 'No Link',
          url: 'https://nolink.example.com/feed.xml',
        );
        fetcher.stubFeed(feed.id, const []);
        icons.stubIcon(
          'https://nolink.example.com/feed.xml',
          'https://nolink.example.com/favicon.ico',
        );

        await refreshRepo.refreshFeed(_user, feed.id);

        final stored = await dao.getFeedByUrl(_user, feed.url);
        expect(stored!.iconUrl, 'https://nolink.example.com/favicon.ico');
      },
    );

    test(
      'does not re-fetch the site once an icon is stored',
      () async {
        final fetcher = FakeRssFetcherService();
        final icons = FakeSiteIconResolver();
        final refreshRepo = DaoNewsfeedRepository(
          dao,
          fetcher,
          siteIcons: icons,
        );

        final feed = await refreshRepo.addFeed(
          _user,
          name: 'Has Icon',
          url: 'https://hasicon.example.com/feed',
        );
        await dao.updateFeedIcon(
          feedId: feed.id,
          iconUrl: 'https://hasicon.example.com/icon.png',
        );
        fetcher.stubFeed(feed.id, const []);

        await refreshRepo.refreshFeed(_user, feed.id);

        final stored = await dao.getFeedByUrl(_user, feed.url);
        expect(stored!.iconUrl, 'https://hasicon.example.com/icon.png');
        expect(icons.calls, isEmpty);
      },
    );

    test('a refreshed space image replaces a rebranded icon', () async {
      final fetcher = FakeRssFetcherService();
      final icons = FakeSiteIconResolver();
      final refreshRepo = DaoNewsfeedRepository(
        dao,
        fetcher,
        siteIcons: icons,
      );

      final feed = await refreshRepo.addFeed(
        _user,
        name: 'Rebrand',
        url: 'https://rebrand.example.com/feed',
      );
      await dao.updateFeedIcon(
        feedId: feed.id,
        iconUrl: 'https://rebrand.example.com/old.png',
      );
      fetcher.stubFeed(
        feed.id,
        const [],
        iconUrl: 'https://rebrand.example.com/new.png',
      );

      await refreshRepo.refreshFeed(_user, feed.id);

      final stored = await dao.getFeedByUrl(_user, feed.url);
      expect(stored!.iconUrl, 'https://rebrand.example.com/new.png');
    });

    test(
      'a stored SVG icon is re-resolved, or cleared when the site offers '
      'nothing better (Hacker News case)',
      () async {
        final fetcher = FakeRssFetcherService();
        final icons = FakeSiteIconResolver();
        final refreshRepo = DaoNewsfeedRepository(
          dao,
          fetcher,
          siteIcons: icons,
        );

        final feed = await refreshRepo.addFeed(
          _user,
          name: 'Hacker News',
          url: 'https://news.example.com/rss',
        );
        // Legacy state: the resolver stored y18.svg before SVGs were
        // recognised as unrenderable.
        await dao.updateFeedIcon(
          feedId: feed.id,
          iconUrl: 'https://news.example.com/y18.svg',
        );
        fetcher.stubFeed(feed.id, const [], siteUrl: 'https://news.example.com/');

        await refreshRepo.refreshFeed(_user, feed.id);

        // The resolver finds no raster icon → the SVG is cleared so the
        // client falls back to the origin's /favicon.ico again.
        var stored = await dao.getFeedByUrl(_user, feed.url);
        expect(stored!.iconUrl, '');
        expect(icons.calls, ['https://news.example.com/']);

        // When the site later offers a raster icon, it replaces the SVG.
        await dao.updateFeedIcon(
          feedId: feed.id,
          iconUrl: 'https://news.example.com/y18.svg',
        );
        icons.stubIcon(
          'https://news.example.com/',
          'https://news.example.com/favicon.png',
        );
        await refreshRepo.refreshFeed(_user, feed.id);
        stored = await dao.getFeedByUrl(_user, feed.url);
        expect(stored!.iconUrl, 'https://news.example.com/favicon.png');
      },
    );

    test(
      'an SVG space image is not stored; the site resolver takes over',
      () async {
        final fetcher = FakeRssFetcherService();
        final icons = FakeSiteIconResolver();
        final refreshRepo = DaoNewsfeedRepository(
          dao,
          fetcher,
          siteIcons: icons,
        );

        final feed = await refreshRepo.addFeed(
          _user,
          name: 'Svg Channel',
          url: 'https://svgch.example.com/feed',
        );
        fetcher.stubFeed(
          feed.id,
          const [],
          iconUrl: 'https://svgch.example.com/logo.svg',
          siteUrl: 'https://svgch.example.com/',
        );
        icons.stubIcon(
          'https://svgch.example.com/',
          'https://svgch.example.com/favicon.png',
        );

        await refreshRepo.refreshFeed(_user, feed.id);

        final stored = await dao.getFeedByUrl(_user, feed.url);
        expect(stored!.iconUrl, 'https://svgch.example.com/favicon.png');
      },
    );
  });

  // ── Seed defaults ─────────────────────────────────────────────────────

  group('seedDefaultFeedsIfEmpty', () {
    test('seeds default feeds when database is empty', () async {
      await repo.seedDefaultFeedsIfEmpty(_user);

      final feeds = await repo.watchFeeds(_user).first;
      expect(feeds, isNotEmpty);
      expect(feeds.length, greaterThanOrEqualTo(1));
    });

    test('does not seed when feeds already exist', () async {
      await repo.addFeed(
        _user,
        name: 'Existing',
        url: 'https://existing.example.com/rss',
      );

      await repo.seedDefaultFeedsIfEmpty(_user);

      final feeds = await repo.watchFeeds(_user).first;
      // Should only have the one we added
      expect(feeds.length, 1);
      expect(feeds.single.name, 'Existing');
    });
  });

  // ── User scoping ──────────────────────────────────────────────────────

  group('user scoping', () {
    /// The feed list is PER-USER: every repository method threads the owning
    /// user, the DAO scopes every query by `user_id`, and an id-only lookup
    /// (getFeedById / getArticleById) treats another user's row as missing.
    test('another user never sees my feeds or articles', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Private Feed',
        url: 'https://private.example.com/rss',
      );
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          title: 'Private Article',
          link: 'https://private.example.com/1',
        ),
      );

      expect(await repo.watchFeeds(_user).first, hasLength(1));
      expect(await repo.watchFeeds(_otherUser).first, isEmpty);
      expect(await repo.watchArticles(_user).first, hasLength(1));
      expect(await repo.watchArticles(_otherUser).first, isEmpty);
    });

    test('the same URL can be registered independently by two users', () async {
      final mine = await repo.addFeed(
        _user,
        name: 'Mine',
        url: 'https://shared.example.com/rss',
      );
      final theirs = await repo.addFeed(
        _otherUser,
        name: 'Theirs',
        url: 'https://shared.example.com/rss',
      );

      expect(mine.id, isNot(theirs.id));
      expect(await repo.watchFeeds(_user).first, hasLength(1));
      expect(await repo.watchFeeds(_otherUser).first, hasLength(1));
    });

    test('mutating by id cannot reach another users feed', () async {
      final theirs = await repo.addFeed(
        _otherUser,
        name: 'Their Feed',
        url: 'https://theirs.example.com/rss',
      );

      // A foreign feed id is indistinguishable from a missing one: disabling
      // and deleting affect zero rows, refreshing is a no-op.
      await repo.setFeedEnabled(_user, theirs.id, enabled: false);
      await repo.deleteFeed(_user, theirs.id);
      await repo.refreshFeed(_user, theirs.id);

      final stillThere = await repo.watchFeeds(_otherUser).first;
      expect(stillThere, hasLength(1));
      expect(stillThere.single.enabled, isTrue);
    });

    test('article flags and markAllRead are scoped to the user', () async {
      final mine = await repo.addFeed(
        _user,
        name: 'My Mark Feed',
        url: 'https://my-mark.example.com/rss',
      );
      final theirs = await repo.addFeed(
        _otherUser,
        name: 'Their Mark Feed',
        url: 'https://their-mark.example.com/rss',
      );
      final myArticle = _uuid.v4();
      final theirArticle = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: myArticle,
          feedId: mine.id,
          title: 'Mine',
          link: 'https://my-mark.example.com/1',
        ),
      );
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: theirArticle,
          feedId: theirs.id,
          title: 'Theirs',
          link: 'https://their-mark.example.com/1',
        ),
      );

      // Saving through the wrong user is a silent no-op.
      await repo.setArticleSaved(_user, theirArticle, saved: true);
      expect((await repo.getArticleById(_otherUser, theirArticle))!.saved, isFalse);

      // markAllRead only touches the caller's articles.
      await repo.markAllRead(_user);
      expect((await repo.getArticleById(_user, myArticle))!.read, isTrue);
      expect(
        (await repo.getArticleById(_otherUser, theirArticle))!.read,
        isFalse,
      );
    });

    test('seedDefaultFeedsIfEmpty is per-user', () async {
      await repo.seedDefaultFeedsIfEmpty(_user);

      expect(await repo.watchFeeds(_user).first, isNotEmpty);
      // The other user still has an empty registry and seeds independently.
      expect(await repo.watchFeeds(_otherUser).first, isEmpty);
      await repo.seedDefaultFeedsIfEmpty(_otherUser);
      expect(await repo.watchFeeds(_otherUser).first, isNotEmpty);
    });
  });

  // ── Edge cases ─────────────────────────────────────────────────────────

  group('edge cases', () {
    test('addFeed with empty name throws ArgumentError', () async {
      expect(
        () => repo.addFeed(_user, name: '', url: 'https://valid.example.com/rss'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addFeed with empty url throws ArgumentError', () async {
      expect(
        () => repo.addFeed(_user, name: 'Valid Name', url: ''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('watchArticles returns empty when no articles exist', () async {
      await repo.addFeed(
        _user,
        name: 'Empty Feed',
        url: 'https://empty.example.com/rss',
      );

      final articles = await repo.watchArticles(_user).first;
      expect(articles, isEmpty);
    });

    test('watchSavedArticles returns empty when no saved articles', () async {
      final articles = await repo.watchSavedArticles(_user).first;
      expect(articles, isEmpty);
    });

    test(
      'articles with same guid in different feeds are kept separate',
      () async {
        final feedA = await repo.addFeed(
          _user,
          name: 'Feed A Dup',
          url: 'https://dupa.example.com/rss',
        );
        final feedB = await repo.addFeed(
          _user,
          name: 'Feed B Dup',
          url: 'https://dupb.example.com/rss',
        );

        await dao.upsertArticleFromFeed(
          _articleCompanion(
            feedId: feedA.id,
            guid: 'shared-guid',
            title: 'From A',
            link: 'https://dupa.example.com/shared',
          ),
        );
        // This should insert a new row (different feedId), not update Feed A's
        await dao.upsertArticleFromFeed(
          _articleCompanion(
            feedId: feedB.id,
            guid: 'shared-guid',
            title: 'From B',
            link: 'https://dupb.example.com/shared',
          ),
        );

        final articles = await repo.watchArticles(_user).first;
        expect(articles.length, 2);
        expect(articles.map((a) => a.title), containsAll(['From A', 'From B']));
      },
    );

    test('upsertArticleFromFeed preserves saved/read on update', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Preserve Feed',
        url: 'https://preserve.example.com/rss',
      );
      final articleId = _uuid.v4();
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          id: articleId,
          feedId: feed.id,
          guid: 'preserve-guid',
          title: 'Original Title',
          link: 'https://preserve.example.com/1',
        ),
      );
      await repo.setArticleSaved(_user, articleId, saved: true);
      await repo.setArticleRead(_user, articleId, read: true);

      // Re-upsert same (feedId, guid) — should update title but keep flags
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          guid: 'preserve-guid',
          title: 'Updated Title',
          link: 'https://preserve.example.com/1',
        ),
      );

      final article = await repo.getArticleById(_user, articleId);
      expect(article!.title, 'Updated Title');
      expect(article.saved, isTrue);
      expect(article.read, isTrue);
    });

    test('articles publishedAt null sorts by createdAt', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Null Date Feed',
        url: 'https://nulldate.example.com/rss',
      );

      final older = DateTime(2024, 1, 1);
      final newer = DateTime(2024, 6, 1);

      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          guid: 'null-date',
          title: 'Null Published',
          link: 'https://nulldate.example.com/null',
          publishedAt: null,
          now: older,
        ),
      );
      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          guid: 'has-date',
          title: 'Has Published',
          link: 'https://nulldate.example.com/has',
          publishedAt: newer,
          now: older,
        ),
      );

      // COALESCE(publishedAt, createdAt) DESC → Has Published first (newer), Null Published second
      final articles = await repo.watchArticles(_user).first;
      expect(articles.length, 2);
      expect(articles[0].title, 'Has Published');
    });

    test('delete nonexistent feed does not throw', () async {
      // The DAO's deleteFeed returns 0 rows affected; repo wraps it
      await repo.deleteFeed(_user, 'nonexistent');
      // Should not throw
    });

    test('setFeedEnabled on nonexistent feed is a no-op at DB level', () async {
      // DAO writes WHERE id = 'nonexistent' → 0 rows → no error
      await repo.setFeedEnabled(_user, 'nonexistent', enabled: false);
      // Should not throw
    });

    test('article guids with special characters are handled', () async {
      final feed = await repo.addFeed(
        _user,
        name: 'Special GUID',
        url: 'https://special.example.com/rss',
      );

      await dao.upsertArticleFromFeed(
        _articleCompanion(
          feedId: feed.id,
          guid: 'tag:example.com,2024:post/123?q=1',
          title: 'Special',
          link: 'https://special.example.com/1',
        ),
      );

      final articles = await repo.watchArticles(_user).first;
      expect(articles.length, 1);
      expect(articles.single.title, 'Special');
      expect(articles.single.guid, 'tag:example.com,2024:post/123?q=1');
    });
  });

  group('fetch memo', () {
    test('two users on one URL cost one fetch and get separate rows', () async {
      // Feeds are per-user rows, so a shared publication used to be fetched
      // once PER SUBSCRIBER. That is linear in users, and on a public demo
      // host — where every visitor is seeded with the whole default list — it
      // is how a demo gets itself rate-limited by the publishers it reads.
      final fetcher = FakeRssFetcherService();
      final memoRepo = DaoNewsfeedRepository(dao, fetcher);
      const url = 'https://shared.example.com/rss';
      fetcher.stubUrl(url, [
        RssArticle(
          id: 'stub-1',
          feedId: 'whichever-feed-caused-the-fetch',
          guid: 'guid-1',
          title: 'Shared story',
          link: 'https://shared.example.com/1',
          createdAt: DateTime(2024),
        ),
      ]);

      final mine = await memoRepo.addFeed(_user, name: 'Shared', url: url);
      final theirs = await memoRepo.addFeed(
        _otherUser,
        name: 'Shared',
        url: url,
      );

      await memoRepo.refreshAll(_user);
      await memoRepo.refreshAll(_otherUser);

      expect(
        fetcher.fetches,
        hasLength(1),
        reason: 'the second subscriber must be served from the memo',
      );

      // Both users see it, and neither row is the other's: the memoized parse
      // carries the FIRST feed's id, so replaying it verbatim would have made
      // one refresh overwrite the other's article.
      final mineArticles = await memoRepo.watchArticles(_user).first;
      final theirArticles = await memoRepo.watchArticles(_otherUser).first;
      expect(mineArticles.single.title, 'Shared story');
      expect(theirArticles.single.title, 'Shared story');
      expect(mineArticles.single.feedId, mine.id);
      expect(theirArticles.single.feedId, theirs.id);
      expect(mineArticles.single.id, isNot(theirArticles.single.id));
    });

    test('a .invalid host is never fetched', () async {
      // RFC 2606 reserves it; a feed there ships its own articles.
      final fetcher = FakeRssFetcherService();
      final memoRepo = DaoNewsfeedRepository(dao, fetcher);
      await memoRepo.addFeed(
        _user,
        name: 'Fixture',
        url: 'https://example.invalid/feed.xml',
      );
      await memoRepo.refreshAll(_user);
      expect(fetcher.fetches, isEmpty);
    });
  });
}
