import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates the signed-in user's newsfeed over the RPC client.
///
/// Newsfeed is PER-USER on global tables (a declared workspace-isolation
/// exemption), so these calls carry no workspace — and no user id either: the
/// server scopes every `newsfeed.*` op + `newsfeed.watch*` subscription by
/// the SESSION's user. Mirrors the `newsfeed.*` ops.
class RemoteNewsfeedRepository {
  /// Creates a [RemoteNewsfeedRepository] over [_client].
  RemoteNewsfeedRepository(this._client);

  final RemoteRpcClient _client;

  /// All articles across subscribed feeds.
  Future<List<ArticleDto>> listArticles() async {
    final data = await _client.call('newsfeed.listArticles', const {});
    return _articles(data);
  }

  /// One article by id, or null when the signed-in user has no such article.
  ///
  /// A scoped read rather than a scan of [listArticles]: the server resolves it
  /// with an indexed join through the user's feeds, so this carries one row
  /// instead of the whole subscribed corpus.
  Future<ArticleDto?> getArticle(String articleId) async {
    try {
      final data = await _client.call('newsfeed.getArticle', {
        'article_id': articleId,
      });
      final raw = data['article'];
      return raw is Map
          ? ArticleDto.fromJson(raw.cast<String, dynamic>())
          : null;
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  /// Marks [articleId] read or unread.
  Future<void> setRead(String articleId, {required bool read}) => _client.call(
    'newsfeed.setArticleRead',
    {'article_id': articleId, 'read': read},
  );

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

  /// Re-fetches every enabled feed host-side. Fetching N feeds + their
  /// og:image fallbacks far exceeds the default 30s request timeout.
  Future<void> refreshAll() => _client.call(
    'newsfeed.refreshAll',
    const {},
    timeout: const Duration(minutes: 3),
  );

  /// Re-fetches a single feed host-side (see [refreshAll] for the timeout).
  Future<void> refreshFeed(String feedId) => _client.call(
    'newsfeed.refreshFeed',
    {'feed_id': feedId},
    timeout: const Duration(minutes: 3),
  );

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
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) => _client
      .call('newsfeed.setFeedEnabled', {'feed_id': feedId, 'enabled': enabled});

  /// Deletes a feed host-side.
  Future<void> deleteFeed(String feedId) =>
      _client.call('newsfeed.deleteFeed', {'feed_id': feedId});

  /// Marks every article read host-side.
  Future<void> markAllRead() => _client.call('newsfeed.markAllRead', const {});

  /// Seeds the session user's default feed set if they have no feeds yet.
  Future<void> seedDefaultFeedsIfEmpty() =>
      _client.call('newsfeed.seedDefaultFeedsIfEmpty', const {});

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
