import 'package:cc_data/src/repositories/remote_newsfeed_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [NewsfeedRepository] backed by the RPC client — the thin-client data path.
///
/// Newsfeed is global (not workspace-scoped) and fetched SERVER-SIDE only: the
/// host owns RSS fetching/parsing and is the single source of truth. A thin
/// client (web / desktop-remote) never fetches RSS itself — it consumes
/// articles over the `newsfeed.*` ops + `newsfeed.watchArticles` subscription
/// (see [RemoteNewsfeedRepository]). Reads + the per-article read/saved toggles
/// are served; feed-management and bulk ops the host owns throw
/// [UnsupportedError].
///
/// The wire [ArticleDto] is lossy relative to [RssArticle] (no guid/imageUrl/
/// createdAt) — those fall back the same way `RpcTicketRepository` handles
/// missing fields (guid←id, link←url, createdAt←publishedAt), which is fine for
/// a read surface where the host holds the authoritative row.
class RpcNewsfeedRepository implements NewsfeedRepository {
  /// Creates an [RpcNewsfeedRepository] over [client].
  RpcNewsfeedRepository(RemoteRpcClient client)
    : _remote = RemoteNewsfeedRepository(client);

  final RemoteNewsfeedRepository _remote;

  /// Rebuilds an [RssFeed] from its wire DTO. The thin client only reads feeds
  /// (it never owns the registry), so the timestamps the UI does not surface
  /// (`createdAt`/`updatedAt`) fall back to the epoch; the fields it DOES render
  /// (enabled, last fetch time, last error, icon) ride the wire.
  static RssFeed _feedFromDto(FeedDto d) => RssFeed(
    id: d.id,
    name: d.name,
    url: d.url,
    description: d.description ?? '',
    iconUrl: d.iconUrl ?? '',
    userAgent: d.userAgent ?? '',
    enabled: d.enabled,
    lastFetchedAt: d.lastFetchedAt,
    lastError: d.lastError,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt: d.lastFetchedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Rebuilds an [RssArticle] from its wire DTO, filling fields the DTO doesn't
  /// carry with read-safe fallbacks.
  static RssArticle _fromDto(ArticleDto d) {
    final published = d.publishedAt;
    return RssArticle(
      id: d.id,
      feedId: d.feedId,
      guid: d.id,
      title: d.title,
      link: d.url ?? '',
      imageUrl: d.imageUrl ?? '',
      summary: d.summary ?? '',
      author: d.author ?? '',
      publishedAt: published,
      saved: d.isSaved,
      read: d.isRead,
      createdAt: published ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  @override
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      _remote.watch().map(
        (dtos) => dtos.map(_fromDto).take(limit).toList(),
      );

  @override
  Stream<List<RssArticle>> watchSavedArticles() => _remote.watch().map(
    (dtos) => dtos.where((d) => d.isSaved).map(_fromDto).toList(),
  );

  @override
  Future<RssArticle?> getArticleById(String id) async {
    for (final d in await _remote.listArticles()) {
      if (d.id == id) {
        return _fromDto(d);
      }
    }
    return null;
  }

  @override
  Future<void> setArticleRead(String articleId, {required bool read}) =>
      _remote.setRead(articleId, read: read);

  @override
  Future<void> setArticleSaved(String articleId, {required bool saved}) =>
      _remote.setSaved(articleId, saved: saved);

  // ---- Feed management + bulk ops. RSS fetching itself runs host-side; these
  // forward over RPC so a thin client can see the feeds, manage them, and ask
  // the host to fetch. The refreshed rows arrive over the watch subscriptions.
  @override
  Stream<List<RssFeed>> watchFeeds() =>
      _remote.watchFeeds().map((dtos) => dtos.map(_feedFromDto).toList());

  @override
  Future<RssFeed> addFeed({
    required String name,
    required String url,
    String description = '',
    String userAgent = '',
  }) async => _feedFromDto(
    await _remote.addFeed(
      name: name,
      url: url,
      description: description,
      userAgent: userAgent,
    ),
  );

  @override
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) =>
      _remote.setFeedEnabled(feedId, enabled: enabled);

  @override
  Future<void> deleteFeed(String feedId) => _remote.deleteFeed(feedId);

  @override
  Future<void> refreshAll() => _remote.refreshAll();

  @override
  Future<void> refreshFeed(String feedId) => _remote.refreshFeed(feedId);

  @override
  Future<void> markAllRead() => _remote.markAllRead();

  @override
  Future<void> seedDefaultFeedsIfEmpty() async {
    // Seeding the default feed set is a host-side concern — the server seeds on
    // startup and owns the registry. A client calling this (e.g. the newsfeed
    // screen's bootstrap) is a harmless no-op rather than an error.
  }
}
