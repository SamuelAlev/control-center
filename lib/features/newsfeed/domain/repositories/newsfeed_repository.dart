import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';

/// Persistence + fetching contract for the Newsfeed feature.
abstract interface class NewsfeedRepository {
  /// Watches all feeds.
  Stream<List<RssFeed>> watchFeeds();

  /// Watches articles across all enabled feeds.
  Stream<List<RssArticle>> watchArticles({int limit = 200});

  /// Watches bookmarked articles only.
  Stream<List<RssArticle>> watchSavedArticles();

  /// Get article by id.
  Future<RssArticle?> getArticleById(String id);

  /// Add feed.
  Future<RssFeed> addFeed({
    required String name,
    required String url,
    String description,
    String userAgent,
  });

  /// Set feed enabled.
  Future<void> setFeedEnabled(String feedId, {required bool enabled});

  /// Delete feed.
  Future<void> deleteFeed(String feedId);

  /// Re-fetches every enabled feed and persists new articles.
  Future<void> refreshAll();

  /// Re-fetches a single feed.
  Future<void> refreshFeed(String feedId);

  /// Set article saved.
  Future<void> setArticleSaved(String articleId, {required bool saved});

  /// Set article read.
  Future<void> setArticleRead(String articleId, {required bool read});

  /// Mark all read.
  Future<void> markAllRead();

  /// Inserts the bundled default feeds if no feeds exist yet.
  Future<void> seedDefaultFeedsIfEmpty();
}
