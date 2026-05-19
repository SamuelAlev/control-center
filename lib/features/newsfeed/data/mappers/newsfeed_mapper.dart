import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/domain/social_media_url_transformer.dart';
import 'package:control_center/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:control_center/shared/utils/string_utils.dart'
    show decodeHtmlEntities;

/// Drift row ↔ domain entity mapping for the newsfeed feature.
class NewsfeedMapper {
  /// Creates a new [NewsfeedMapper].
  const NewsfeedMapper();

  /// Feed to domain.
  RssFeed feedToDomain(RssFeedsTableData row) => RssFeed(
    id: row.id,
    name: decodeHtmlEntities(row.name),
    url: row.url,
    description: decodeHtmlEntities(row.description),
    iconUrl: row.iconUrl,
    userAgent: row.userAgent,
    enabled: row.enabled,
    lastFetchedAt: row.lastFetchedAt,
    lastError: row.lastError,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  /// Feeds to domain.
  List<RssFeed> feedsToDomain(List<RssFeedsTableData> rows) =>
      rows.map(feedToDomain).toList();

  /// Article to domain.
  RssArticle articleToDomain(RssArticlesTableData row) => RssArticle(
    id: row.id,
    feedId: row.feedId,
    guid: row.guid,
    title: decodeHtmlEntities(row.title),
    link: stripTrackingParams(
      transformSocialMediaUrl(row.link),
      knownParams: defaultRemoveParams(),
    ),
    summary: decodeHtmlEntities(row.summary),
    imageUrl: row.imageUrl,
    author: decodeHtmlEntities(row.author),
    publishedAt: row.publishedAt,
    saved: row.saved,
    read: row.read,
    createdAt: row.createdAt,
  );

  /// Articles to domain.
  List<RssArticle> articlesToDomain(List<RssArticlesTableData> rows) =>
      rows.map(articleToDomain).toList();
}
