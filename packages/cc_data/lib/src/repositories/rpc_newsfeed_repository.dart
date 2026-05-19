import 'package:cc_data/src/repositories/remote_newsfeed_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The thin client's newsfeed data path over the RPC client.
///
/// The newsfeed is PER-USER (global tables, not workspace-scoped) and fetched
/// SERVER-SIDE only: the host owns RSS fetching/parsing and is the single
/// source of truth. A thin client (web / desktop-remote) never fetches RSS
/// itself — it consumes articles over the `newsfeed.*` ops +
/// `newsfeed.watchArticles` subscription (see [RemoteNewsfeedRepository]).
/// The session's user is resolved server-side, which is why this surface
/// carries no user id and does not implement the server-side
/// `NewsfeedRepository` port (whose every method takes the owning user).
///
/// The wire [ArticleDto] is lossy relative to [RssArticle] (no guid/imageUrl/
/// createdAt) — those fall back the same way `RpcTicketRepository` handles
/// missing fields (guid←id, link←url, createdAt←publishedAt), which is fine for
/// a read surface where the host holds the authoritative row.
class RpcNewsfeedRepository {
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
  ///
  /// Returns null for an article with no `url`: `RssArticle` requires a
  /// non-empty `link` (an article you cannot open is not an article), and this
  /// runs inside a stream `map`, where a throw would blank the whole feed
  /// instead of dropping one item.
  static RssArticle? _fromDto(ArticleDto d) {
    final link = d.url ?? '';
    if (link.isEmpty) {
      return null;
    }
    final published = d.publishedAt;
    return RssArticle(
      id: d.id,
      feedId: d.feedId,
      guid: d.id,
      title: d.title,
      link: link,
      imageUrl: d.imageUrl ?? '',
      summary: d.summary ?? '',
      author: d.author ?? '',
      publishedAt: published,
      saved: d.isSaved,
      read: d.isRead,
      createdAt: published ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Live articles across the user's enabled feeds.
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      _remote.watch().map(
        (dtos) =>
            dtos.map(_fromDto).whereType<RssArticle>().take(limit).toList(),
      );

  /// Live bookmarked articles only.
  Stream<List<RssArticle>> watchSavedArticles() => _remote.watch().map(
    (dtos) => dtos
        .where((d) => d.isSaved)
        .map(_fromDto)
        .whereType<RssArticle>()
        .toList(),
  );

  /// One article by id.
  Future<RssArticle?> getArticleById(String id) async {
    final dto = await _remote.getArticle(id);
    return dto == null ? null : _fromDto(dto);
  }

  /// Marks [articleId] read or unread.
  Future<void> setArticleRead(String articleId, {required bool read}) =>
      _remote.setRead(articleId, read: read);

  /// Saves or unsaves [articleId].
  Future<void> setArticleSaved(String articleId, {required bool saved}) =>
      _remote.setSaved(articleId, saved: saved);

  // ---- Feed management + bulk ops. RSS fetching itself runs host-side; these
  // forward over RPC so a thin client can see the user's feeds, manage them
  // and ask the host to fetch. The refreshed rows arrive over the watch
  // subscriptions.
  /// Live feeds — the signed-in user's registry.
  Stream<List<RssFeed>> watchFeeds() =>
      _remote.watchFeeds().map((dtos) => dtos.map(_feedFromDto).toList());

  /// Adds a feed to the user's registry host-side.
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

  /// Enables or disables one of the user's feeds host-side.
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) =>
      _remote.setFeedEnabled(feedId, enabled: enabled);

  /// Deletes one of the user's feeds host-side.
  Future<void> deleteFeed(String feedId) => _remote.deleteFeed(feedId);

  /// Re-fetches every enabled feed of the user's host-side.
  Future<void> refreshAll() => _remote.refreshAll();

  /// Re-fetches a single feed host-side.
  Future<void> refreshFeed(String feedId) => _remote.refreshFeed(feedId);

  /// Marks every one of the user's articles read host-side.
  Future<void> markAllRead() => _remote.markAllRead();

  /// Seeds the session user's default feed set host-side if they have none
  /// yet. Real over RPC (unlike the old install-global no-op): a user
  /// created after the server's boot sweep gets the bundled defaults the
  /// moment they first open the newsfeed.
  Future<void> seedDefaultFeedsIfEmpty() => _remote.seedDefaultFeedsIfEmpty();
}
