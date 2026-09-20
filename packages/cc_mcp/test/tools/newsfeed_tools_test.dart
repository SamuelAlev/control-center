import 'dart:convert';

import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_mcp/src/tools/newsfeed_tools.dart';
import 'package:test/test.dart';

void main() {
  late _FakeNewsfeed repo;

  setUp(() {
    repo = _FakeNewsfeed();
  });

  test('list_feeds returns the owner feeds and honors enabled_only', () async {
    final tool = ListFeedsTool(repository: repo, userId: 'user-1');
    final all = await tool.run(const {});
    expect(all.isError, isFalse);
    final allBody = jsonDecode(all.content.first.text) as Map<String, dynamic>;
    expect(allBody['count'], 2);

    final enabled = await tool.run({'enabled_only': true});
    final enabledBody =
        jsonDecode(enabled.content.first.text) as Map<String, dynamic>;
    expect(enabledBody['count'], 1);
    expect((enabledBody['feeds'] as List).single, isA<Map>());
    expect(((enabledBody['feeds'] as List).single as Map)['name'], 'Active');
  });

  test(
    'get_article refuses a missing id and returns a known article',
    () async {
      final tool = GetArticleTool(repository: repo, userId: 'user-1');
      final missing = await tool.run(const {});
      expect(missing.isError, isTrue);
      expect(missing.content.first.text, contains('article_id'));

      final found = await tool.run({'article_id': 'a1'});
      expect(found.isError, isFalse);
      final body = jsonDecode(found.content.first.text) as Map<String, dynamic>;
      expect(body['title'], 'Hello');
    },
  );

  test('set_article_read marks the owner article', () async {
    final tool = SetArticleReadTool(repository: repo, userId: 'user-1');
    final result = await tool.run({'article_id': 'a1', 'read': true});
    expect(result.isError, isFalse);
    expect(repo.readMarked, 'a1');
  });
}

class _FakeNewsfeed implements NewsfeedRepository {
  String? readMarked;

  @override
  Stream<List<RssFeed>> watchFeeds(String userId) => Stream.value([
    RssFeed(
      id: 'f1',
      name: 'Active',
      url: 'https://example.com/a.xml',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    RssFeed(
      id: 'f2',
      name: 'Off',
      url: 'https://example.com/b.xml',
      enabled: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ]);

  @override
  Future<RssArticle?> getArticleById(String userId, String id) async {
    if (id != 'a1') {
      return null;
    }
    return RssArticle(
      id: 'a1',
      feedId: 'f1',
      guid: 'g1',
      title: 'Hello',
      link: 'https://example.com/hello',
      createdAt: DateTime(2026),
    );
  }

  @override
  Future<void> setArticleRead(
    String userId,
    String articleId, {
    required bool read,
  }) async {
    readMarked = articleId;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
