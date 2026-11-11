import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/newsfeed/domain/repositories/newsfeed_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/src/catalog/catalog_wire.dart';

/// Builds the `newsfeed.*` ops the catalog spreads.
///
/// The newsfeed is per user, not per workspace: every op is unscoped and
/// keyed by the session user, so one person never reads another's feeds.
List<RepoOp> buildNewsfeedOps(NewsfeedRepository newsfeedRepository) => [
  RepoOp(
    name: 'newsfeed.listArticles',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    handler: (ctx) async {
      final articles = await newsfeedRepository.watchArticles(ctx.userId).first;
      return {'articles': articles.map(articleToWire).toList()};
    },
  ),
  // Scoped point lookup. The client used to `listArticles()` and scan for the
  // id, which pulls every article across every subscribed feed to answer a
  // primary-key question. The DAO query joins through `rss_feeds` so the
  // article is found only if it belongs to THIS user's feeds — an id alone
  // never proves ownership.
  RepoOp(
    name: 'newsfeed.getArticle',
    kind: RepoOpKind.read,
    workspaceScoped: false,
    requiredArgs: ['article_id'],
    handler: (ctx) async {
      final article = await newsfeedRepository.getArticleById(
        ctx.userId,
        ctx.args['article_id'] as String,
      );
      if (article == null) {
        throw const NotFoundException('Article not found');
      }
      return {'article': articleToWire(article)};
    },
  ),
  RepoOp(
    name: 'newsfeed.setArticleRead',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['article_id', 'read'],
    handler: (ctx) async {
      await newsfeedRepository.setArticleRead(
        ctx.userId,
        ctx.args['article_id'] as String,
        read: ctx.args['read'] as bool,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'newsfeed.setArticleSaved',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['article_id', 'saved'],
    handler: (ctx) async {
      await newsfeedRepository.setArticleSaved(
        ctx.userId,
        ctx.args['article_id'] as String,
        saved: ctx.args['saved'] as bool,
      );
      return {'ok': true};
    },
  ),
  // Feed management + refresh (per-user). RSS fetching runs server-side;
  // these let a thin client SEE the user's feeds, manage them and trigger
  // a host-side fetch. The refreshed rows stream back over
  // `newsfeed.watchArticles` / `newsfeed.watchFeeds`.
  RepoOp(
    name: 'newsfeed.refreshAll',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    // Fetches every enabled feed + og:image fallbacks host-side; the
    // first-party client gives the call 3 minutes, so the server budget
    // must outlive it (the deadline exists to free the session slot, not
    // to cut a healthy sweep short).
    timeout: const Duration(minutes: 4),
    handler: (ctx) async {
      await newsfeedRepository.refreshAll(ctx.userId);
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'newsfeed.refreshFeed',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['feed_id'],
    // See `newsfeed.refreshAll` for the budget.
    timeout: const Duration(minutes: 4),
    handler: (ctx) async {
      await newsfeedRepository.refreshFeed(
        ctx.userId,
        ctx.args['feed_id'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'newsfeed.addFeed',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['name', 'url'],
    handler: (ctx) async {
      final feed = await newsfeedRepository.addFeed(
        ctx.userId,
        name: ctx.args['name'] as String,
        url: ctx.args['url'] as String,
        description: ctx.args['description'] as String? ?? '',
        userAgent: ctx.args['user_agent'] as String? ?? '',
      );
      return {'feed': feedToWire(feed)};
    },
  ),
  RepoOp(
    name: 'newsfeed.setFeedEnabled',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['feed_id', 'enabled'],
    handler: (ctx) async {
      await newsfeedRepository.setFeedEnabled(
        ctx.userId,
        ctx.args['feed_id'] as String,
        enabled: ctx.args['enabled'] as bool,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'newsfeed.deleteFeed',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    requiredArgs: ['feed_id'],
    handler: (ctx) async {
      await newsfeedRepository.deleteFeed(
        ctx.userId,
        ctx.args['feed_id'] as String,
      );
      return {'ok': true};
    },
  ),
  RepoOp(
    name: 'newsfeed.markAllRead',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    handler: (ctx) async {
      await newsfeedRepository.markAllRead(ctx.userId);
      return {'ok': true};
    },
  ),
  // Seeds the session user's default feed set on first use, so a user
  // created after boot still gets the bundled defaults the moment they
  // open the newsfeed (the boot-time sweep only covers users that
  // existed at startup).
  RepoOp(
    name: 'newsfeed.seedDefaultFeedsIfEmpty',
    kind: RepoOpKind.mutate,
    workspaceScoped: false,
    handler: (ctx) async {
      await newsfeedRepository.seedDefaultFeedsIfEmpty(ctx.userId);
      return {'ok': true};
    },
  ),
];
