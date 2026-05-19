import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates newsfeed articles over the RPC client.
///
/// Newsfeed is global (not workspace-scoped) on the host — a declared
/// workspace-isolation exemption — so these calls carry no workspace. Mirrors
/// the `newsfeed.*` ops + `newsfeed.watchArticles` query.
class RemoteNewsfeedRepository {
  /// Creates a [RemoteNewsfeedRepository] over [_client].
  RemoteNewsfeedRepository(this._client);

  final RemoteRpcClient _client;

  /// All articles across subscribed feeds.
  Future<List<ArticleDto>> listArticles() async {
    final data = await _client.call('newsfeed.listArticles', const {});
    return _articles(data);
  }

  /// Marks [articleId] read or unread.
  Future<void> setRead(String articleId, {required bool read}) =>
      _client.call('newsfeed.setArticleRead', {
        'article_id': articleId,
        'read': read,
      });

  /// Saves or unsaves [articleId].
  Future<void> setSaved(String articleId, {required bool saved}) =>
      _client.call('newsfeed.setArticleSaved', {
        'article_id': articleId,
        'saved': saved,
      });

  /// Live articles — a fresh snapshot on every change.
  Stream<List<ArticleDto>> watch() =>
      _client.subscribe('newsfeed.watchArticles', const {}).map(_articles);

  /// Live feeds — a fresh snapshot on every change.
  Stream<List<FeedDto>> watchFeeds() =>
      _client.subscribe('newsfeed.watchFeeds', const {}).map(_feeds);

  /// Re-fetches every enabled feed host-side.
  Future<void> refreshAll() => _client.call('newsfeed.refreshAll', const {});

  /// Re-fetches a single feed host-side.
  Future<void> refreshFeed(String feedId) =>
      _client.call('newsfeed.refreshFeed', {'feed_id': feedId});

  /// Adds a feed host-side and returns the created row.
  Future<FeedDto> addFeed({
    required String name,
    required String url,
    String description = '',
    String userAgent = '',
  }) async {
    final data = await _client.call('newsfeed.addFeed', {
      'name': name,
      'url': url,
      if (description.isNotEmpty) 'description': description,
      if (userAgent.isNotEmpty) 'user_agent': userAgent,
    });
    return FeedDto.fromJson((data['feed'] as Map).cast<String, dynamic>());
  }

  /// Enables or disables a feed host-side.
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) =>
      _client.call('newsfeed.setFeedEnabled', {
        'feed_id': feedId,
        'enabled': enabled,
      });

  /// Deletes a feed host-side.
  Future<void> deleteFeed(String feedId) =>
      _client.call('newsfeed.deleteFeed', {'feed_id': feedId});

  /// Marks every article read host-side.
  Future<void> markAllRead() => _client.call('newsfeed.markAllRead', const {});

  List<ArticleDto> _articles(Map<String, dynamic> data) =>
      ((data['articles'] as List?) ?? const [])
          .whereType<Map>()
          .map((a) => ArticleDto.fromJson(a.cast<String, dynamic>()))
          .toList();

  List<FeedDto> _feeds(Map<String, dynamic> data) =>
      ((data['feeds'] as List?) ?? const [])
          .whereType<Map>()
          .map((f) => FeedDto.fromJson(f.cast<String, dynamic>()))
          .toList();
}
