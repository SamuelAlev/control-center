import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_grid.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_skeleton.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/source_filter_menu.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/refresh_control.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
                icon: LucideIcons.checkCheck,
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
              icon: LucideIcons.settings,
              onPressed: () => context.go(newsfeedSettingsRoute),
            ),
          ),
        ],
        child: Column(
          children: [
            const _NewsfeedToolbar(),
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
        icon: LucideIcons.searchX,
      );
    }
    return switch (view) {
      NewsfeedView.saved => (
        title: l10n.noSavedArticles,
        body: l10n.noSavedArticlesBody,
        icon: LucideIcons.bookmark,
      ),
      NewsfeedView.unread => (
        title: l10n.allCaughtUp,
        body: l10n.allCaughtUpBody,
        icon: LucideIcons.checkCheck,
      ),
      NewsfeedView.all => (
        title: l10n.noArticlesYet,
        body: l10n.noArticlesYetBody,
        icon: LucideIcons.newspaper,
      ),
    };
  }
}

/// Search field + source multi-select + All/Unread/Saved view segments.
class _NewsfeedToolbar extends ConsumerWidget {
  const _NewsfeedToolbar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final view = ref.watch(newsfeedViewProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320, minWidth: 200),
              child: const _ArticleSearchField(),
            ),
            const SizedBox(width: 8),
            SourceFilterMenu(provider: newsfeedFilterProvider),
            const Spacer(),
            _ViewSegments(
              view: view,
              onChanged: (v) =>
                  ref.read(newsfeedViewProvider.notifier).set(v),
              labels: (
                all: l10n.filterAll,
                unread: l10n.filterUnread,
                saved: l10n.filterSaved,
              ),
            ),
            const SizedBox(width: 8),
            const _LayoutToggle(),
          ],
        ),
      ),
    );
  }
}

/// Icon toggle that flips the article list between the dense digest list and
/// the magazine card grid.
class _LayoutToggle extends ConsumerWidget {
  const _LayoutToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final layout = ref.watch(newsfeedLayoutProvider);
    final colors = Theme.of(context).colorScheme;
    final tokens = context.designSystem;

    Widget segment({
      required NewsfeedLayout target,
      required bool active,
      required IconData icon,
      required String tooltip,
    }) {
      final fg = active
          ? (tokens?.textPrimary ?? colors.onSurface)
          : (tokens?.textTertiary ?? colors.onSurfaceVariant);
      return Semantics(
        button: true,
        selected: active,
        label: tooltip,
        child: CcTooltip(
          message: tooltip,
          child: CcTappable(
            onPressed: () =>
                ref.read(newsfeedLayoutProvider.notifier).set(target),
            borderRadius: AppRadii.brSm,
            builder: (context, states) => Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: active
                    ? (tokens?.bgPrimary ?? colors.surface)
                    : Colors.transparent,
                borderRadius: AppRadii.brSm,
                border: Border.all(
                  color: active
                      ? (tokens?.borderSecondary ?? colors.outlineVariant)
                      : Colors.transparent,
                ),
              ),
              child: Icon(icon, size: 15, color: fg),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: tokens?.bgSecondary ?? colors.surfaceContainerHighest,
        borderRadius: AppRadii.brMd,
        border: Border.all(
          color: tokens?.borderSecondary ?? colors.outlineVariant,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          segment(
            target: NewsfeedLayout.list,
            active: layout == NewsfeedLayout.list,
            icon: LucideIcons.list,
            tooltip: l10n.viewAsList,
          ),
          segment(
            target: NewsfeedLayout.grid,
            active: layout == NewsfeedLayout.grid,
            icon: LucideIcons.layoutGrid,
            tooltip: l10n.viewAsGrid,
          ),
        ],
      ),
    );
  }
}

/// Segmented All / Unread / Saved selector.
class _ViewSegments extends StatelessWidget {
  const _ViewSegments({
    required this.view,
    required this.onChanged,
    required this.labels,
  });

  final NewsfeedView view;
  final ValueChanged<NewsfeedView> onChanged;
  final ({String all, String unread, String saved}) labels;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.designSystem;

    Widget segment(NewsfeedView value, String label) {
      final active = view == value;
      final fg = active
          ? (tokens?.textPrimary ?? colors.onSurface)
          : (tokens?.textTertiary ?? colors.onSurfaceVariant);
      return Expanded(
        child: CcTappable(
          onPressed: () => onChanged(value),
          borderRadius: AppRadii.brSm,
          builder: (context, states) => Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: active
                  ? (tokens?.bgPrimary ?? colors.surface)
                  : Colors.transparent,
              borderRadius: AppRadii.brSm,
              border: Border.all(
                color: active
                    ? (tokens?.borderSecondary ?? colors.outlineVariant)
                    : Colors.transparent,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: fg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }

    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: tokens?.bgSecondary ?? colors.surfaceContainerHighest,
          borderRadius: AppRadii.brMd,
          border: Border.all(
            color: tokens?.borderSecondary ?? colors.outlineVariant,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            segment(NewsfeedView.all, labels.all),
            segment(NewsfeedView.unread, labels.unread),
            segment(NewsfeedView.saved, labels.saved),
          ],
        ),
      ),
    );
  }
}

/// Search input bound to [newsfeedSearchProvider], with an inline clear
/// affordance.
class _ArticleSearchField extends ConsumerStatefulWidget {
  const _ArticleSearchField();

  @override
  ConsumerState<_ArticleSearchField> createState() =>
      _ArticleSearchFieldState();
}

class _ArticleSearchFieldState extends ConsumerState<_ArticleSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(newsfeedSearchProvider));
    _controller.addListener(_onChanged);
  }

  void _onChanged() {
    ref.read(newsfeedSearchProvider.notifier).set(_controller.text);
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasText = _controller.text.isNotEmpty;
    return CcTextField(
      hintText: l10n.searchArticles,
      controller: _controller,
      prefix: const Icon(LucideIcons.search, size: 16),
      suffix: hasText
          ? Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CcIconButton(
                icon: LucideIcons.x,
                size: CcButtonSize.sm,
                onPressed: () => _controller.clear(),
              ),
            )
          : null,
    );
  }
}
