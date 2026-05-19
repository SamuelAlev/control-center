import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/rss_dao.dart';
import 'package:control_center/features/newsfeed/data/mappers/newsfeed_mapper.dart';
import 'package:control_center/features/newsfeed/data/services/rss_fetcher_service.dart';
import 'package:control_center/features/newsfeed/domain/default_feeds.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:drift/drift.dart' as drift;
import 'package:uuid/uuid.dart';

/// Drift-backed [NewsfeedRepository] implementation.
class DaoNewsfeedRepository implements NewsfeedRepository {
  /// Creates a new [Dao newsfeed repository].
  DaoNewsfeedRepository(this._dao, this._fetcher);

  final RssDao _dao;
  final RssFetcherService _fetcher;
  final NewsfeedMapper _mapper = const NewsfeedMapper();
  final _uuid = const Uuid();

  @override
  Stream<List<RssFeed>> watchFeeds() =>
      _dao.watchFeeds().map(_mapper.feedsToDomain);

  @override
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      _dao.watchAllArticles(limit: limit).map(_mapper.articlesToDomain);

  @override
  Stream<List<RssArticle>> watchSavedArticles() =>
      _dao.watchSavedArticles().map(_mapper.articlesToDomain);

  @override
  Future<RssArticle?> getArticleById(String id) async {
    final row = await _dao.getArticleById(id);
    return row == null ? null : _mapper.articleToDomain(row);
  }

  @override
  Future<RssFeed> addFeed({
    required String name,
    required String url,
    String description = '',
    String userAgent = '',
  }) async {
    final existing = await _dao.getFeedByUrl(url);
    if (existing != null) {
      return _mapper.feedToDomain(existing);
    }
    final id = _uuid.v4();
    final now = DateTime.now();
    await _dao.upsertFeed(
      RssFeedsTableCompanion(
        id: drift.Value(id),
        name: drift.Value(name),
        url: drift.Value(url),
        description: drift.Value(description),
        userAgent: drift.Value(userAgent),
        createdAt: drift.Value(now),
        updatedAt: drift.Value(now),
      ),
    );
    final row = await _dao.getFeedByUrl(url);
    return _mapper.feedToDomain(row!);
  }

  @override
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) =>
      _dao.setFeedEnabled(feedId, enabled: enabled);

  @override
  Future<void> deleteFeed(String feedId) => _dao.deleteFeed(feedId);

  @override
  Future<void> refreshAll() async {
    final feeds = await _dao.getEnabledFeeds();
    for (final feed in feeds) {
      await _refreshOne(feed);
    }
  }

  @override
  Future<void> refreshFeed(String feedId) async {
    final feeds = await _dao.getEnabledFeeds();
    final feed = feeds.where((f) => f.id == feedId).firstOrNull;
    if (feed == null) {
      return;
    }
    await _refreshOne(feed);
  }

  Future<void> _refreshOne(RssFeedsTableData feed) async {
    try {
      final articles = await _fetcher.fetchAndParse(
        feedId: feed.id,
        url: feed.url,
        userAgent: feed.userAgent,
      );
      for (final article in articles) {
        await _dao.upsertArticleFromFeed(
          RssArticlesTableCompanion(
            id: drift.Value(article.id),
            feedId: drift.Value(article.feedId),
            guid: drift.Value(article.guid),
            title: drift.Value(article.title),
            link: drift.Value(article.link),
            summary: drift.Value(article.summary),
            imageUrl: drift.Value(article.imageUrl),
            author: drift.Value(article.author),
            publishedAt: drift.Value(article.publishedAt),
            createdAt: drift.Value(article.createdAt),
          ),
        );
      }
      await _dao.updateFeedFetchResult(
        feedId: feed.id,
        fetchedAt: DateTime.now(),
      );
    } on Object catch (e) {
      await _dao.updateFeedFetchResult(
        feedId: feed.id,
        fetchedAt: DateTime.now(),
        error: e.toString(),
      );
    }
  }

  @override
  Future<void> setArticleSaved(String articleId, {required bool saved}) =>
      _dao.setArticleSaved(articleId, saved: saved);

  @override
  Future<void> setArticleRead(String articleId, {required bool read}) =>
      _dao.setArticleRead(articleId, read: read);

  @override
  Future<void> markAllRead() => _dao.markAllRead();

  @override
  Future<void> seedDefaultFeedsIfEmpty() async {
    final existing = await _dao.watchFeeds().first;
    if (existing.isNotEmpty) {
      return;
    }
    final now = DateTime.now();
    for (final def in kDefaultFeeds) {
      await _dao.upsertFeed(
        RssFeedsTableCompanion(
          id: drift.Value(_uuid.v4()),
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
