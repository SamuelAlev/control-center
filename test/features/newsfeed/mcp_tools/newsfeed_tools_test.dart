import 'dart:convert';

import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_mcp/src/tools/newsfeed_tools.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal in-memory [NewsfeedRepository] for tool tests.
class _FakeNewsfeedRepository implements NewsfeedRepository {
  _FakeNewsfeedRepository({this.feeds = const [], this.articles = const []});

  List<RssFeed> feeds;
  List<RssArticle> articles;
  int refreshCalls = 0;
  final Map<String, bool> readOverrides = {};
  final Map<String, bool> savedOverrides = {};
  @override
  Stream<List<RssFeed>> watchFeeds() => Stream.value(feeds);

  @override
  Stream<List<RssArticle>> watchArticles({int limit = 200}) =>
      Stream.value(articles.take(limit).toList());

  @override
  Stream<List<RssArticle>> watchSavedArticles() =>
      Stream.value(articles.where((a) => savedOverrides[a.id] ?? a.saved).toList());

  @override
  Future<RssArticle?> getArticleById(String id) async {
    if (!articles.any((a) => a.id == id)) return null;
    return _resolve(articles.firstWhere((a) => a.id == id));
  }

  RssArticle _resolve(RssArticle a) {
    final read = readOverrides[a.id] ?? a.read;
    final saved = savedOverrides[a.id] ?? a.saved;
    return RssArticle(
      id: a.id,
      feedId: a.feedId,
      guid: a.guid,
      title: a.title,
      link: a.link,
      summary: a.summary,
      imageUrl: a.imageUrl,
      author: a.author,
      publishedAt: a.publishedAt,
      saved: saved,
      read: read,
      createdAt: a.createdAt,
    );
  }

  @override
  Future<void> setArticleSaved(String articleId, {required bool saved}) async {
    savedOverrides[articleId] = saved;
  }

  @override
  Future<void> setArticleRead(String articleId, {required bool read}) async {
    readOverrides[articleId] = read;
  }

  @override
  Future<void> refreshAll() async {
    refreshCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Not used in newsfeed tool tests: ${invocation.memberName}');
}

RssFeed _feed(String id, {bool enabled = true}) => RssFeed(
      id: id,
      name: 'Feed $id',
      url: 'https://example.com/$id.xml',
      description: 'desc',
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

RssArticle _article(String id, String feedId, {bool read = false, bool saved = false}) =>
    RssArticle(
      id: id,
      feedId: feedId,
      guid: 'guid-$id',
      title: 'Article $id',
      link: 'https://example.com/a/$id',
      summary: 'summary $id',
      author: 'Author',
      publishedAt: DateTime(2026, 1, 2),
      saved: saved,
      read: read,
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('ListFeedsTool', () {
    test('lists all feeds', () async {
      final repo = _FakeNewsfeedRepository(feeds: [_feed('a'), _feed('b', enabled: false)]);
      final tool = ListFeedsTool(repository: repo);
      final res = await tool.run({});
      expect(res.isError, isFalse);
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['count'], 2);
      expect((body['feeds'] as List).length, 2);
    });

    test('enabled_only filters disabled feeds', () async {
      final repo = _FakeNewsfeedRepository(feeds: [_feed('a'), _feed('b', enabled: false)]);
      final tool = ListFeedsTool(repository: repo);
      final res = await tool.run({'enabled_only': true});
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['count'], 1);
    });
  });

  group('ListArticlesTool', () {
    test('filters by feed_id', () async {
      final repo = _FakeNewsfeedRepository(articles: [
        _article('1', 'f1'),
        _article('2', 'f2'),
        _article('3', 'f1'),
      ]);
      final tool = ListArticlesTool(repository: repo);
      final res = await tool.run({'feed_id': 'f1'});
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['count'], 2);
    });

    test('unread_only returns only unread', () async {
      final repo = _FakeNewsfeedRepository(articles: [
        _article('1', 'f1', read: true),
        _article('2', 'f1'),
      ]);
      final tool = ListArticlesTool(repository: repo);
      final res = await tool.run({'unread_only': true});
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['count'], 1);
      expect(
        ((body['articles'] as List).first as Map)['id'],
        '2',
      );
    });

    test('saved_only overrides unread_only', () async {
      final repo = _FakeNewsfeedRepository(articles: [
        _article('1', 'f1', saved: true, read: true),
      ]);
      final tool = ListArticlesTool(repository: repo);
      final res = await tool.run({'saved_only': true, 'unread_only': true});
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['count'], 1);
    });

    test('respects limit', () async {
      final repo = _FakeNewsfeedRepository(
        articles: [for (var i = 0; i < 10; i++) _article('$i', 'f1')],
      );
      final tool = ListArticlesTool(repository: repo);
      final res = await tool.run({'limit': 3});
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['count'], 3);
    });
  });

  group('GetArticleTool', () {
    test('returns article json', () async {
      final repo = _FakeNewsfeedRepository(articles: [_article('1', 'f1')]);
      final tool = GetArticleTool(repository: repo);
      final res = await tool.run({'article_id': '1'});
      expect(res.isError, isFalse);
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['id'], '1');
      expect(body['url'], 'https://example.com/a/1');
    });

    test('errors on missing article_id', () async {
      final tool = GetArticleTool(repository: _FakeNewsfeedRepository());
      final res = await tool.run({});
      expect(res.isError, isTrue);
    });

    test('errors when not found', () async {
      final tool = GetArticleTool(repository: _FakeNewsfeedRepository());
      final res = await tool.run({'article_id': 'nope'});
      expect(res.isError, isTrue);
    });
  });

  group('SetArticleReadTool', () {
    test('marks read by default', () async {
      final repo = _FakeNewsfeedRepository();
      final tool = SetArticleReadTool(repository: repo);
      final res = await tool.run({'article_id': '1'});
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['is_read'], true);
      expect(repo.readOverrides['1'], true);
    });

    test('marks unread when read=false', () async {
      final repo = _FakeNewsfeedRepository();
      final tool = SetArticleReadTool(repository: repo);
      await tool.run({'article_id': '1', 'read': false});
      expect(repo.readOverrides['1'], false);
    });
  });

  group('SetArticleSavedTool', () {
    test('saves by default', () async {
      final repo = _FakeNewsfeedRepository();
      final tool = SetArticleSavedTool(repository: repo);
      await tool.run({'article_id': '1'});
      expect(repo.savedOverrides['1'], true);
    });
  });

  group('RefreshFeedsTool', () {
    test('calls refreshAll', () async {
      final repo = _FakeNewsfeedRepository();
      final tool = RefreshFeedsTool(repository: repo);
      final res = await tool.run({});
      expect(repo.refreshCalls, 1);
      final body = jsonDecode(res.content.first.text) as Map<String, dynamic>;
      expect(body['status'], 'refreshed');
    });
  });
}
