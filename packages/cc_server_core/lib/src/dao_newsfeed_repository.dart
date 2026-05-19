import 'package:cc_domain/features/newsfeed/domain/default_feeds.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_infra/cc_infra.dart';
import 'package:cc_persistence/database/daos/rss_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/mappers/newsfeed_mapper.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift-backed [NewsfeedRepository] implementation.
///
/// Every operation is scoped to the owning user — feeds, their articles and
/// the saved/read flags riding them are per-user, never shared.
class DaoNewsfeedRepository implements NewsfeedRepository {
  /// Creates a new [Dao newsfeed repository].
  ///
  /// [siteIcons] resolves a site's favicon from its HTML when a feed
  /// advertises no space image of its own; when null that fallback is
  /// skipped (tests).
  DaoNewsfeedRepository(this._dao, this._fetcher, {SiteIconResolver? siteIcons})
    : _siteIcons = siteIcons;

  final RssDao _dao;
  final RssFetcherService _fetcher;
  final SiteIconResolver? _siteIcons;
  final NewsfeedMapper _mapper = const NewsfeedMapper();
  final _uuid = const Uuid();

  /// Recently fetched feed bodies, keyed by URL.
  ///
  /// Feeds are per-user rows, so the same publication subscribed by N people
  /// is N rows — and the sweep refreshed each one, hitting the publisher N
  /// times for a body that is byte-identical. On a team that is rude; on a
  /// PUBLIC demo host, where every anonymous visitor is seeded with the whole
  /// default list, it is linear in visitors and earns exactly what it sounds
  /// like (TLDR started answering 429 during testing).
  ///
  /// So a fetch is memoized by URL for [_fetchMemoTtl] and re-keyed per
  /// subscribing feed row on the way to the database. Articles dedup on
  /// `(feed_id, guid)`, so replaying one parse under another feed's id is the
  /// same write the network would have produced.
  final Map<String, ({DateTime at, ParsedFeed parsed})> _fetchMemo = {};

  /// Comfortably under the 30-minute sweep, so the sweep itself always fetches
  /// and only the traffic BETWEEN sweeps (a new user, a manual refresh) is
  /// served from the memo.
  static const Duration _fetchMemoTtl = Duration(minutes: 10);

  /// Bound on [_fetchMemo]. A server with more distinct feeds than this keeps
  /// the most recent — the memo is an optimization, never a correctness
  /// requirement, so evicting is always safe.
  static const int _fetchMemoMaxEntries = 256;

  ParsedFeed? _memoized(String url) {
    final hit = _fetchMemo[url];
    if (hit == null) {
      return null;
    }
    if (DateTime.now().difference(hit.at) > _fetchMemoTtl) {
      _fetchMemo.remove(url);
      return null;
    }
    return hit.parsed;
  }

  void _memoize(String url, ParsedFeed parsed) {
    if (_fetchMemo.length >= _fetchMemoMaxEntries) {
      final oldest = _fetchMemo.entries.reduce(
        (a, b) => a.value.at.isBefore(b.value.at) ? a : b,
      );
      _fetchMemo.remove(oldest.key);
    }
    _fetchMemo[url] = (at: DateTime.now(), parsed: parsed);
  }

  @override
  Stream<List<RssFeed>> watchFeeds(String userId) =>
      _dao.watchFeeds(userId).map(_mapper.feedsToDomain);

  @override
  Stream<List<RssArticle>> watchArticles(String userId, {int limit = 200}) =>
      _dao.watchAllArticles(userId, limit: limit).map(_mapper.articlesToDomain);

  @override
  Stream<List<RssArticle>> watchSavedArticles(String userId) =>
      _dao.watchSavedArticles(userId).map(_mapper.articlesToDomain);

  @override
  Future<RssArticle?> getArticleById(String userId, String id) async {
    final row = await _dao.getArticleById(userId, id);
    return row == null ? null : _mapper.articleToDomain(row);
  }

  @override
  Future<RssFeed> addFeed(
    String userId, {
    required String name,
    required String url,
    String description = '',
    String userAgent = '',
  }) async {
    final existing = await _dao.getFeedByUrl(userId, url);
    if (existing != null) {
      return _mapper.feedToDomain(existing);
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    await _dao.upsertFeed(
      RssFeedsTableCompanion(
        id: drift.Value(id),
        userId: drift.Value(userId),
        name: drift.Value(name),
        url: drift.Value(url),
        description: drift.Value(description),
        userAgent: drift.Value(userAgent),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );
    final row = await _dao.getFeedByUrl(userId, url);
    return _mapper.feedToDomain(row!);
  }

  @override
  Future<void> setFeedEnabled(
    String userId,
    String feedId, {
    required bool enabled,
  }) => _dao.setFeedEnabled(userId, feedId, enabled: enabled);

  @override
  Future<void> deleteFeed(String userId, String feedId) =>
      _dao.deleteFeed(userId, feedId);

  @override
  Future<void> refreshAll(String userId) async {
    final feeds = await _dao.getEnabledFeeds(userId);
    // Bounded fan-out: sequential refreshes multiply the per-feed fetch
    // (+ og:image fallback) latency by the feed count and overrun the
    // caller's patience; four workers keep the upstream load sane.
    var next = 0;
    const concurrency = 4;
    await Future.wait(
      List.generate(concurrency < feeds.length ? concurrency : feeds.length, (
        _,
      ) async {
        while (next < feeds.length) {
          await _refreshOne(feeds[next++]);
        }
      }),
    );
  }

  @override
  Future<void> refreshFeed(String userId, String feedId) async {
    // Scoped lookup: a foreign feed id is indistinguishable from a missing
    // one, so refreshing someone else's feed is a silent no-op.
    final feed = await _dao.getFeedById(userId, feedId);
    if (feed == null || !feed.enabled) {
      return;
    }
    await _refreshOne(feed);
  }

  Future<void> _refreshOne(RssFeedsTableData feed) async {
    // `.invalid` is reserved by RFC 2606 and guaranteed never to resolve, so a
    // feed on one is a fixture that ships its own articles — the demo's
    // in-house blog, for instance, which must render without egress. Fetching
    // it can only spend a DNS lookup to log a `SocketException`, once per feed
    // per sweep, and per visitor on a demo host. Treat it as already fresh.
    if (Uri.tryParse(feed.url)?.host.endsWith('.invalid') ?? false) {
      return;
    }
    try {
      final cached = _memoized(feed.url);
      final parsed =
          cached ??
          await _fetcher.fetchAndParseFeed(
            feedId: feed.id,
            url: feed.url,
            userAgent: feed.userAgent,
          );
      if (cached == null) {
        _memoize(feed.url, parsed);
      }
      final articles = parsed.articles;
      // Persist the whole feed in a single transaction. Each individual upsert
      // would otherwise fire its own `watchAllArticles` stream emission and a
      // feed with N articles would rebuild the newsfeed list N times during one
      // refresh. Batching to one transaction collapses those into a single
      // emission per feed.
      await _dao.upsertArticlesFromFeed(
        articles.map(
          (article) => RssArticlesTableCompanion(
            // Fresh id + THIS feed's id: a memoized parse carries the id of
            // whichever feed row caused the fetch. Reusing either would make
            // one subscriber's refresh overwrite another's row.
            id: drift.Value(
              article.feedId == feed.id ? article.id : _uuid.v4(),
            ),
            feedId: drift.Value(feed.id),
            guid: drift.Value(article.guid),
            title: drift.Value(article.title),
            link: drift.Value(article.link),
            summary: drift.Value(article.summary),
            imageUrl: drift.Value(article.imageUrl),
            author: drift.Value(article.author),
            publishedAt: drift.Value(article.publishedAt),
            createdAt: drift.Value(article.createdAt),
          ),
        ),
      );
      await _dao.updateFeedFetchResult(
        feedId: feed.id,
        fetchedAt: DateTime.now(),
      );
      await _updateFeedIcon(feed, parsed);
    } on Object catch (e) {
      await _dao.updateFeedFetchResult(
        feedId: feed.id,
        fetchedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  /// Keeps the stored feed icon in sync with what the feed — or its site —
  /// advertises. The feed's own space image always wins and is re-applied
  /// every refresh (sites rebrand). When the feed advertises none and we
  /// have never resolved one, fall back to the site HTML's
  /// `<link rel="icon">` — attempted only while the stored icon is empty, so
  /// a refresh doesn't re-fetch the homepage every cycle. Best-effort: a
  /// failure never fails the refresh.
  ///
  /// SVG icons are never stored: the client's raster pipeline cannot decode
  /// them, so an SVG renders as nothing — worse than no icon, which falls
  /// back to the origin's `/favicon.ico`. A previously stored SVG (resolved
  /// before this rule existed, e.g. news.ycombinator.com's `y18.svg`) is
  /// treated as unresolved: re-resolved, or cleared when nothing better is
  /// found so the fallback returns.
  Future<void> _updateFeedIcon(
    RssFeedsTableData feed,
    ParsedFeed parsed,
  ) async {
    final advertised = parsed.iconUrl;
    if (advertised != null &&
        advertised.isNotEmpty &&
        !isSvgIconUrl(advertised)) {
      if (advertised != feed.iconUrl) {
        await _dao.updateFeedIcon(feedId: feed.id, iconUrl: advertised);
      }
      return;
    }
    final storedIsSvg = feed.iconUrl.isNotEmpty && isSvgIconUrl(feed.iconUrl);
    if ((feed.iconUrl.isNotEmpty && !storedIsSvg) || _siteIcons == null) {
      return;
    }
    final siteUrl = (parsed.siteUrl != null && parsed.siteUrl!.isNotEmpty)
        ? parsed.siteUrl!
        : feed.url;
    final resolved = await _siteIcons.resolve(
      siteUrl,
      userAgent: feed.userAgent.isNotEmpty ? feed.userAgent : null,
    );
    if (resolved != null && resolved.isNotEmpty) {
      await _dao.updateFeedIcon(feedId: feed.id, iconUrl: resolved);
    } else if (storedIsSvg) {
      // Clear the unrenderable icon so the client falls back to the
      // origin's /favicon.ico.
      await _dao.updateFeedIcon(feedId: feed.id, iconUrl: '');
    }
  }

  @override
  Future<void> setArticleSaved(
    String userId,
    String articleId, {
    required bool saved,
  }) => _dao.setArticleSaved(userId, articleId, saved: saved);

  @override
  Future<void> setArticleRead(
    String userId,
    String articleId, {
    required bool read,
  }) => _dao.setArticleRead(userId, articleId, read: read);

  @override
  Future<void> markAllRead(String userId) => _dao.markAllRead(userId);

  @override
  Future<void> seedDefaultFeedsIfEmpty(String userId) async {
    final existing = await _dao.watchFeeds(userId).first;
    if (existing.isNotEmpty) {
      return;
    }
    final now = DateTime.now();
    for (final def in kDefaultFeeds) {
      await _dao.upsertFeed(
        RssFeedsTableCompanion(
          id: drift.Value(_uuid.v4()),
          userId: drift.Value(userId),
          name: drift.Value(def.name),
          url: drift.Value(def.url),
          description: drift.Value(def.description),
          userAgent: const drift.Value(''),
          createdAt: drift.Value(now),
          updatedAt: drift.Value(now),
        ),
      );
    }
  }
}
