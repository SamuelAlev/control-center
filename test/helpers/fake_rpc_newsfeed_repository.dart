import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [RpcNewsfeedRepository] for widget tests: built over a never-connected
/// channel, with every method overridden to serve canned rows or no-op.
///
/// The provider is typed to the concrete RPC adapter (the client surface is
/// session-scoped — no user ids to thread), so tests subclass it rather than
/// implement the server-side `NewsfeedRepository` port.
class FakeRpcNewsfeedRepository extends RpcNewsfeedRepository {
  /// Creates a fake serving `feeds`, `articles` and an optional single
  /// `article` for [getArticleById] deep links.
  FakeRpcNewsfeedRepository({
    this._feeds = const [],
    this._articles = const [],
    this._article,
  }) : super(RemoteRpcClient(_NullRpcChannel()));

  final List<RssFeed> _feeds;
  final List<RssArticle> _articles;
  final RssArticle? _article;

  @override
  Stream<List<RssFeed>> watchFeeds() => Stream.value(_feeds);

  @override
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      Stream.value(_articles.take(limit).toList());

  @override
  Stream<List<RssArticle>> watchSavedArticles() =>
      Stream.value(_articles.where((a) => a.saved).toList());

  @override
  Future<RssArticle?> getArticleById(String id) async =>
      _article ?? _articles.where((a) => a.id == id).firstOrNull;

  @override
  Future<RssFeed> addFeed({
    required String name,
    required String url,
    String description = '',
    String userAgent = '',
  }) => throw UnimplementedError();

  @override
  Future<void> setFeedEnabled(String feedId, {required bool enabled}) async {}

  @override
  Future<void> deleteFeed(String feedId) async {}

  @override
  Future<void> refreshAll() async {}

  @override
  Future<void> refreshFeed(String feedId) async {}

  @override
  Future<void> setArticleSaved(String articleId, {required bool saved}) async {}

  @override
  Future<void> setArticleRead(String articleId, {required bool read}) async {}

  @override
  Future<void> markAllRead() async {}

  @override
  Future<void> seedDefaultFeedsIfEmpty() async {}
}

/// A channel that is never open — enough to construct a [RemoteRpcClient]
/// whose transport is never touched because every method is overridden.
class _NullRpcChannel implements RemoteRpcChannelPort {
  @override
  Stream<Map<String, dynamic>> get incoming => const Stream.empty();

  @override
  Stream<RemoteChannelState> get state => const Stream.empty();

  @override
  bool get isOpen => false;

  @override
  Future<void> send(Map<String, dynamic> frame) async {}

  @override
  Future<void> close() async {}
}
