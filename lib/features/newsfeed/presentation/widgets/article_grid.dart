import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_domain/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_card.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_list_row.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/auto_scroll/auto_scroll.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Tracks which article currently holds (or should hold) keyboard focus.
class FocusedArticleIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Marks the article with [id] as focused (or clears when null).
  void set(String? id) => state = id;
}

/// The id of the article that currently holds (or should hold) keyboard
/// focus. Drives j/k navigation and the native focus ring; `null` = none.
final focusedArticleIdProvider =
    NotifierProvider<FocusedArticleIdNotifier, String?>(
      FocusedArticleIdNotifier.new,
    );

/// Side-effecting article actions: mark read, toggle saved, open in reader.
class ArticleActionsNotifier extends Notifier<void> {
  @override
  void build() {}

  /// Marks the article with [articleId] as read.
  Future<void> markRead(String articleId) async {
    await ref
        .read(newsfeedRepositoryProvider)
        .setArticleRead(articleId, read: true);
  }

  /// Sets the bookmarked state of the article with [articleId].
  Future<void> toggleSaved(String articleId, {required bool saved}) async {
    await ref
        .read(newsfeedRepositoryProvider)
        .setArticleSaved(articleId, saved: saved);
  }

  /// Marks [article] read and opens it in the in-app reader or the external
  /// browser, depending on the user's [articleOpenModeProvider] preference.
  Future<void> openArticle(BuildContext context, RssArticle article) async {
    // Capture the workspace id before awaiting: the in-app navigation below
    // runs after async gaps where the route context may have changed.
    final workspaceId = context.currentWorkspaceId!;
    await markRead(article.id);
    final mode = ref.read(articleOpenModeProvider);
    if (!context.mounted) {
      return;
    }
    final cleanLink = stripTrackingParams(
      article.link,
      knownParams: defaultRemoveParams(),
    );
    if (mode == ArticleOpenMode.externalBrowser) {
      openExternalUrl(cleanLink);
      return;
    }
    if (!context.mounted) {
      return;
    }
    context.go(newsfeedArticleRoute(workspaceId, article.id));
  }
}

/// Exposes [ArticleActionsNotifier] for opening/saving/marking articles.
final articleActionsProvider = NotifierProvider<ArticleActionsNotifier, void>(
  ArticleActionsNotifier.new,
);

/// Responsive grid of article tiles with an optional featured lead story.
class ArticleGrid extends ConsumerStatefulWidget {
  /// Creates a new [ArticleGrid].
  const ArticleGrid({
    super.key,
    required this.articles,
    required this.emptyTitle,
    required this.emptyBody,
    this.emptyIcon = AppIcons.newspaper,
  });

  /// Articles to render.
  final List<RssArticle> articles;

  /// Title shown when the list is empty.
  final String emptyTitle;

  /// Body text shown when the list is empty.
  final String emptyBody;

  /// Icon shown in the empty state.
  final IconData emptyIcon;

  @override
  ConsumerState<ArticleGrid> createState() => _ArticleGridState();
}

class _ArticleGridState extends ConsumerState<ArticleGrid> {
  /// Drives the grid's vertical scroll. Owned here so [AutoScroll] can
  /// share the same [ScrollPosition] for middle-click auto-scroll.
  final ScrollController _scrollController = ScrollController();

  /// Per-article focus nodes. The focused node renders the native focus ring;
  /// j/k navigation requests focus on the next/prev node instead of painting a
  /// separate selection highlight (which would double up with the ring).
  final Map<String, FocusNode> _focusNodes = {};

  @override
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  FocusNode _nodeFor(String articleId) {
    return _focusNodes.putIfAbsent(articleId, () {
      final node = FocusNode(debugLabel: 'article:$articleId');
      // Native focus is the source of truth: when a row gains focus (via
      // click, Tab, or j/k) keep the provider in sync so navigation continues
      // from the actually-focused row.
      node.addListener(() {
        if (node.hasFocus) {
          ref.read(focusedArticleIdProvider.notifier).set(articleId);
        }
      });
      return node;
    });
  }

  /// Requests native focus on [id]'s row and scrolls it into view. Runs after
  /// the current frame so lazily-built rows have a chance to attach first.
  void _focusArticle(String? id) {
    if (id == null) {
      return;
    }
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final node = _focusNodes[id];
      if (node == null) {
        return;
      }
      node.requestFocus();
      final ctx = node.context;
      if (ctx == null || !ctx.mounted) {
        return;
      }
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.3,
        duration: Duration(milliseconds: reduceMotion ? 0 : 220),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _open(BuildContext context, RssArticle article) {
    ref.read(focusedArticleIdProvider.notifier).set(article.id);
    ref.read(articleActionsProvider.notifier).openArticle(context, article);
  }

  void _toggleSaved(RssArticle article) {
    ref
        .read(articleActionsProvider.notifier)
        .toggleSaved(article.id, saved: !article.saved);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.articles.isEmpty) {
      return _EmptyState(
        title: widget.emptyTitle,
        body: widget.emptyBody,
        icon: widget.emptyIcon,
      );
    }

    final feeds = ref.watch(feedsProvider).value ?? const <RssFeed>[];
    final feedsById = {for (final f in feeds) f.id: f};
    final layout = ref.watch(newsfeedLayoutProvider);
    final articles = widget.articles;

    // j/k (and click/Tab) move the focused article; mirror that onto native
    // focus so the focus ring is the single selection indicator.
    ref.listen<String?>(
      focusedArticleIdProvider,
      (_, next) => _focusArticle(next),
    );

    return ReadyAutoScroll(
      controller: _scrollController,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          if (layout == NewsfeedLayout.grid)
            _gridSliver(context, articles, feedsById)
          else
            _listSliver(context, articles, feedsById),
        ],
      ),
    );
  }

  Widget _gridSliver(
    BuildContext context,
    List<RssArticle> articles,
    Map<String, RssFeed> feedsById,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.xs,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 340,
          mainAxisSpacing: AppSpacing.lg,
          crossAxisSpacing: AppSpacing.lg,
          childAspectRatio: 0.9,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = articles[index];
          return ArticleCard(
            key: ValueKey(article.id),
            focusNode: _nodeFor(article.id),
            article: article,
            feed: feedsById[article.feedId],
            onTap: () => _open(context, article),
            onToggleSaved: () => _toggleSaved(article),
          );
        }, childCount: articles.length),
      ),
    );
  }

  Widget _listSliver(
    BuildContext context,
    List<RssArticle> articles,
    Map<String, RssFeed> feedsById,
  ) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final article = articles[index];
          return ArticleListRow(
            key: ValueKey(article.id),
            focusNode: _nodeFor(article.id),
            article: article,
            feed: feedsById[article.feedId],
            onTap: () => _open(context, article),
            onToggleSaved: () => _toggleSaved(article),
          );
        }, childCount: articles.length),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.body,
    required this.icon,
  });
  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.designSystem;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: tokens?.bgSecondary ?? colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 32,
              color: tokens?.fgTertiary ?? colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: tokens?.textPrimary ?? colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens?.textTertiary ?? colors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
