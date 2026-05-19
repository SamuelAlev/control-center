import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';

/// Persistence + fetching contract for the Newsfeed feature.
///
/// The feed list is PER-USER: every operation takes the owning user's id as
/// its first argument (mirroring the user-preferences repository). The server
/// derives it from the session identity — never from a client arg.
abstract interface class NewsfeedRepository {
  /// Watches the user's feeds.
  Stream<List<RssFeed>> watchFeeds(String userId);

  /// Watches articles across the user's enabled feeds.
  Stream<List<RssArticle>> watchArticles(String userId, {int limit = 200});

  /// Watches the user's bookmarked articles only.
  Stream<List<RssArticle>> watchSavedArticles(String userId);

  /// Get one of the user's articles by id.
  Future<RssArticle?> getArticleById(String userId, String id);

  /// Add a feed for the user.
  Future<RssFeed> addFeed(
    String userId, {
    required String name,
    required String url,
    String description,
    String userAgent,
  });

  /// Set one of the user's feeds enabled.
  Future<void> setFeedEnabled(
    String userId,
    String feedId, {
    required bool enabled,
  });

  /// Delete one of the user's feeds.
  Future<void> deleteFeed(String userId, String feedId);

  /// Re-fetches every enabled feed of the user's and persists new articles.
  Future<void> refreshAll(String userId);

  /// Re-fetches a single feed of the user's.
  Future<void> refreshFeed(String userId, String feedId);

  /// Set one of the user's articles saved.
  Future<void> setArticleSaved(
    String userId,
    String articleId, {
    required bool saved,
  });

  /// Set one of the user's articles read.
  Future<void> setArticleRead(
    String userId,
    String articleId, {
    required bool read,
  });

  /// Mark all of the user's articles read.
  Future<void> markAllRead(String userId);

  /// Inserts the bundled default feeds if the user has no feeds yet.
  Future<void> seedDefaultFeedsIfEmpty(String userId);
}
