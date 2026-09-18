import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_grid.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_skeleton.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_toolbar.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Newsfeed home — every article across enabled feeds, with All / Unread /
/// Saved views, source filtering and search all on a single page.
class NewsfeedScreen extends ConsumerStatefulWidget {
  /// Creates a new [NewsfeedScreen].
  const NewsfeedScreen({super.key});

  @override
  ConsumerState<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends ConsumerState<NewsfeedScreen> {
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    if (_seeded) {
      return;
    }
    _seeded = true;
    final repo = ref.read(newsfeedRepositoryProvider);
    await repo.seedDefaultFeedsIfEmpty();
    await ref.read(newsfeedRefreshControllerProvider.notifier).refreshAll();
  }

  void _cycle(int delta, List<RssArticle> articles) {
    if (articles.isEmpty) {
      return;
    }
    final current = ref.read(focusedArticleIdProvider);
    final currentIdx = current == null
        ? -1
        : articles.indexWhere((a) => a.id == current);
    final base = currentIdx < 0 ? (delta > 0 ? -1 : 0) : currentIdx;
    final raw = (base + delta) % articles.length;
    final nextIdx = raw < 0 ? raw + articles.length : raw;
    ref.read(focusedArticleIdProvider.notifier).set(articles[nextIdx].id);
  }

  void _openSelected(List<RssArticle> articles) {
    final id = ref.read(focusedArticleIdProvider);
    if (id == null) {
      return;
    }
    final article = articles.where((a) => a.id == id).firstOrNull;
    if (article == null) {
      return;
    }
    ref.read(articleActionsProvider.notifier).openArticle(context, article);
  }

  Future<void> _toggleSelectedSaved(List<RssArticle> articles) async {
    final id = ref.read(focusedArticleIdProvider);
    if (id == null) {
      return;
    }
    final article = articles.where((a) => a.id == id).firstOrNull;
    if (article == null) {
      return;
    }
    await ref
        .read(articleActionsProvider.notifier)
        .toggleSaved(article.id, saved: !article.saved);
  }

  @override
  Widget build(BuildContext context) {
    final articlesAsync = ref.watch(filteredArticlesProvider);
    final refreshing = ref.watch(newsfeedRefreshControllerProvider);
    final articles = articlesAsync.value ?? const <RssArticle>[];
    final unreadCounts = ref.watch(feedUnreadCountsProvider);
    final totalUnread = unreadCounts.values.fold<int>(0, (a, b) => a + b);
    final view = ref.watch(newsfeedViewProvider);
    final layout = ref.watch(newsfeedLayoutProvider);
    final sources = ref.watch(newsfeedFilterProvider);
    final query = ref.watch(newsfeedSearchProvider).trim();
    final filtering = query.isNotEmpty || sources.isNotEmpty;
    final l10n = AppLocalizations.of(context);

    // "Last checked" derives from the real per-feed fetch times — the most
    // recent fetch across all feeds.
    final feeds = ref.watch(feedsProvider).value ?? const [];
    DateTime? lastChecked;
    for (final feed in feeds) {
      final fetchedAt = feed.lastFetchedAt;
      if (fetchedAt != null &&
          (lastChecked == null || fetchedAt.isAfter(lastChecked))) {
        lastChecked = fetchedAt;
      }
    }

    final underlyingHasAny = view == NewsfeedView.saved
        ? (ref.watch(savedArticlesProvider).value ?? const <RssArticle>[])
              .isNotEmpty
        : (ref.watch(articlesProvider).value ?? const <RssArticle>[])
              .isNotEmpty;

    return ScopedShortcuts(
      scope: '/newsfeed',
      bindings: {
        'newsfeed.refresh': () =>
            ref.read(newsfeedRefreshControllerProvider.notifier).refreshAll(),
        if (articles.isNotEmpty) ...{
          'newsfeed.next': () => _cycle(1, articles),
          'newsfeed.prev': () => _cycle(-1, articles),
          'newsfeed.open': () => _openSelected(articles),
          'newsfeed.save': () => _toggleSelectedSaved(articles),
        },
      },
      child: PageWrapper(
        title: l10n.newsfeedLabel,
        subtitle: l10n.articlesSubscribed,
        actions: [
          if (totalUnread > 0)
            CcTooltip(
              message: l10n.markAllRead,
              child: CcIconButton(
                icon: AppIcons.checkCheck,
                semanticLabel: l10n.markAllRead,
                onPressed: () => ref
                    .read(markAllReadControllerProvider.notifier)
                    .markAllRead(),
              ),
            ),
          RefreshControl(
            variant: CcButtonVariant.ghost,
            lastChecked: lastChecked,
            isLoading: refreshing,
            tooltip: l10n.refreshAllFeeds,
            onRefresh: () => ref
                .read(newsfeedRefreshControllerProvider.notifier)
                .refreshAll(),
          ),
          CcTooltip(
            message: l10n.newsfeedSettingsTitle,
            child: CcIconButton(
              icon: AppIcons.settings,
              semanticLabel: l10n.newsfeedSettingsTitle,
              // Settings → You → Newsfeed: the feed registry is per-user, so
              // it lives in the settings' You scope, not on this page.
              onPressed: () => context.go(
                settingsNewsfeedRoute(context.currentWorkspaceId!),
              ),
            ),
          ),
        ],
        child: Column(
          children: [
            const NewsfeedToolbar(),
            Expanded(
              child: articlesAsync.when(
                data: (articles) {
                  final empty = _emptyStateFor(
                    l10n: l10n,
                    view: view,
                    filtering: filtering,
                    underlyingHasAny: underlyingHasAny,
                  );
                  return ArticleGrid(
                    articles: articles,
                    emptyIcon: empty.icon,
                    emptyTitle: empty.title,
                    emptyBody: empty.body,
                  );
                },
                loading: () => NewsfeedSkeleton(layout: layout),
                error: (e, _) =>
                    Center(child: Text(l10n.failedWithError('$e'))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String title, String body, IconData icon}) _emptyStateFor({
    required AppLocalizations l10n,
    required NewsfeedView view,
    required bool filtering,
    required bool underlyingHasAny,
  }) {
    if (filtering && underlyingHasAny) {
      return (
        title: l10n.noMatchingArticles,
        body: l10n.noMatchingArticlesBody,
        icon: AppIcons.searchX,
      );
    }
    return switch (view) {
      NewsfeedView.saved => (
        title: l10n.noSavedArticles,
        body: l10n.noSavedArticlesBody,
        icon: AppIcons.bookmark,
      ),
      NewsfeedView.unread => (
        title: l10n.allCaughtUp,
        body: l10n.allCaughtUpBody,
        icon: AppIcons.checkCheck,
      ),
      NewsfeedView.all => (
        title: l10n.noArticlesYet,
        body: l10n.noArticlesYetBody,
        icon: AppIcons.newspaper,
      ),
    };
  }
}
