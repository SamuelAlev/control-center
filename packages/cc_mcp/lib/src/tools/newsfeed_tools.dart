import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';

Map<String, dynamic> _feedJson(RssFeed f) => {
  'id': f.id,
  'name': f.name,
  'url': f.url,
  if (f.description.isNotEmpty) 'description': f.description,
  'enabled': f.enabled,
};

Map<String, dynamic> _articleJson(RssArticle a) => {
  'id': a.id,
  'feed_id': a.feedId,
  'title': a.title,
  'url': a.link,
  if (a.summary.isNotEmpty) 'summary': a.summary,
  if (a.author.isNotEmpty) 'author': a.author,
  if (a.publishedAt != null) 'published_at': a.publishedAt!.toIso8601String(),
  'is_read': a.read,
  'is_saved': a.saved,
};

/// MCP tool to list all RSS feeds. Newsfeed is global, so this takes no
/// `workspace_id`.
class ListFeedsTool extends McpTool {
  ListFeedsTool({required NewsfeedRepository repository})
    : _repository = repository;

  final NewsfeedRepository _repository;

  @override
  String get name => 'list_feeds';

  @override
  String get description => 'Lists all registered RSS/Atom feeds.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'enabled_only': {
        'type': 'boolean',
        'description': 'When true, only return feeds enabled for fetching.',
        'default': false,
      },
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final enabledOnly = arguments['enabled_only'] == true;
    final feeds = await _repository.watchFeeds().first;
    final list = (enabledOnly ? feeds.where((f) => f.enabled) : feeds)
        .map(_feedJson)
        .toList();
    return CallResult.success(
      jsonEncode({'feeds': list, 'count': list.length}),
    );
  }
}

/// MCP tool to list articles, optionally filtered by feed / unread / saved.
class ListArticlesTool extends McpTool {
  ListArticlesTool({required NewsfeedRepository repository})
    : _repository = repository;

  final NewsfeedRepository _repository;

  @override
  String get name => 'list_articles';

  @override
  String get description =>
      'Lists newsfeed articles, optionally filtered by feed, unread, or saved.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'feed_id': {
        'type': 'string',
        'description': 'Restrict to a single feed by id.',
      },
      'unread_only': {
        'type': 'boolean',
        'description': 'When true, only return unread articles.',
        'default': false,
      },
      'saved_only': {
        'type': 'boolean',
        'description':
            'When true, only return bookmarked articles (overrides unread_only).',
        'default': false,
      },
      'limit': {
        'type': 'integer',
        'description': 'Maximum number of articles to return (default 50).',
        'default': 50,
      },
    },
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final feedId = arguments['feed_id'];
    final unreadOnly = arguments['unread_only'] == true;
    final savedOnly = arguments['saved_only'] == true;
    final rawLimit = arguments['limit'];
    final limit = rawLimit is int ? rawLimit : 50;

    List<RssArticle> articles;
    if (savedOnly) {
      articles = await _repository.watchSavedArticles().first;
    } else {
      // Fetch a wider window so post-filters (feed/unread) still have room.
      articles = await _repository.watchArticles(limit: 200).first;
      if (unreadOnly) {
        articles = articles.where((a) => !a.read).toList();
      }
    }
    if (feedId is String && feedId.isNotEmpty) {
      articles = articles.where((a) => a.feedId == feedId).toList();
    }
    final list = articles.take(limit).map(_articleJson).toList();
    return CallResult.success(
      jsonEncode({'articles': list, 'count': list.length}),
    );
  }
}

/// MCP tool to fetch a single article by id.
class GetArticleTool extends McpTool {
  GetArticleTool({required NewsfeedRepository repository})
    : _repository = repository;

  final NewsfeedRepository _repository;

  @override
  String get name => 'get_article';

  @override
  String get description => 'Fetches a single newsfeed article by id.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'article_id': {'type': 'string', 'description': 'The article id.'},
    },
    'required': ['article_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawId = arguments['article_id'];
    if (rawId is! String) {
      return CallResult.error(
        'Missing or invalid argument: article_id (expected string)',
      );
    }
    final article = await _repository.getArticleById(rawId);
    if (article == null) {
      return CallResult.error('Article not found: $rawId');
    }
    return CallResult.success(jsonEncode(_articleJson(article)));
  }
}

/// MCP tool to mark an article read or unread.
class SetArticleReadTool extends McpTool {
  SetArticleReadTool({required NewsfeedRepository repository})
    : _repository = repository;

  final NewsfeedRepository _repository;

  @override
  String get name => 'set_article_read';

  @override
  String get description => 'Marks a newsfeed article as read or unread.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'article_id': {'type': 'string', 'description': 'The article id.'},
      'read': {
        'type': 'boolean',
        'description': 'True to mark read, false to mark unread.',
        'default': true,
      },
    },
    'required': ['article_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawId = arguments['article_id'];
    if (rawId is! String) {
      return CallResult.error(
        'Missing or invalid argument: article_id (expected string)',
      );
    }
    final read = arguments['read'] != false;
    await _repository.setArticleRead(rawId, read: read);
    return CallResult.success(
      jsonEncode({'article_id': rawId, 'is_read': read}),
    );
  }
}

/// MCP tool to bookmark or unbookmark an article.
class SetArticleSavedTool extends McpTool {
  SetArticleSavedTool({required NewsfeedRepository repository})
    : _repository = repository;

  final NewsfeedRepository _repository;

  @override
  String get name => 'set_article_saved';

  @override
  String get description => 'Bookmarks (saves) or unsaves a newsfeed article.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'article_id': {'type': 'string', 'description': 'The article id.'},
      'saved': {
        'type': 'boolean',
        'description': 'True to save, false to unsave.',
        'default': true,
      },
    },
    'required': ['article_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawId = arguments['article_id'];
    if (rawId is! String) {
      return CallResult.error(
        'Missing or invalid argument: article_id (expected string)',
      );
    }
    final saved = arguments['saved'] != false;
    await _repository.setArticleSaved(rawId, saved: saved);
    return CallResult.success(
      jsonEncode({'article_id': rawId, 'is_saved': saved}),
    );
  }
}

/// MCP tool to re-fetch every enabled feed.
class RefreshFeedsTool extends McpTool {
  RefreshFeedsTool({required NewsfeedRepository repository})
    : _repository = repository;

  final NewsfeedRepository _repository;

  @override
  String get name => 'refresh_feeds';

  @override
  String get description => 'Re-fetches every enabled RSS/Atom feed now.';

  @override
  Map<String, dynamic> get inputSchema => {'type': 'object', 'properties': {}};

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    await _repository.refreshAll();
    return CallResult.success(jsonEncode({'status': 'refreshed'}));
  }
}
