import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Newsfeed tab: live articles (`newsfeed.watchArticles`) filterable by feed
/// (`newsfeed.watchFeeds`) and unread and pushes a reader route. Newsfeed is
/// global — not workspace-scoped.
class NewsfeedScreen extends ConsumerStatefulWidget {
  /// Creates a [NewsfeedScreen].
  const NewsfeedScreen({super.key});

  @override
  ConsumerState<NewsfeedScreen> createState() => _NewsfeedScreenState();
}

class _NewsfeedScreenState extends ConsumerState<NewsfeedScreen> {
  String? _feedFilter;
  bool _unreadOnly = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final feeds = ref.watch(newsfeedFeedsProvider).value ?? const [];
    final async = ref.watch(newsfeedArticlesProvider);
    final articles = (async.value ?? const <ArticleDto>[])
        .where((a) => _feedFilter == null || a.feedId == _feedFilter)
        .where((a) => !_unreadOnly || !a.isRead)
        .toList();

    return ColoredBox(
      color: t.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _filterBar(t, feeds),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CcSpinner(size: 24)),
              error: (e, _) => CcEmptyState(
                icon: AppIcons.triangleAlert,
                message: AppLocalizations.of(context).articlesLoadFailed,
                description: e.toString(),
              ),
              data: (_) {
                if (articles.isEmpty) {
                  return CcEmptyState(
                    icon: AppIcons.newspaper,
                    message: AppLocalizations.of(context).noArticles,
                    description: AppLocalizations.of(
                      context,
                    ).articlesEmptyDescription,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _articleCard(t, articles[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _articleCard(DesignSystemTokens t, ArticleDto article) {
    return CcCard(
      interactive: true,
      semanticLabel: article.title,
      onPressed: () => context.push('/article/${article.id}'),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!article.isRead)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: t.accent,
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(width: 8, height: 8),
              ),
            )
          else
            const SizedBox(width: 8),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: article.isRead
                        ? FontWeight.w400
                        : FontWeight.w600,
                    color: t.textPrimary,
                  ),
                ),
                if (article.summary?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    article.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: t.textTertiary),
                  ),
                ],
              ],
            ),
          ),
          if (article.isSaved)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 8),
              child: Icon(AppIcons.bookmark, size: 16, color: t.accent),
            ),
        ],
      ),
    );
  }

  Widget _filterBar(DesignSystemTokens t, List<FeedDto> feeds) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, top: 8),
            child: CcChip(
              label: l10n.unread,
              selected: _unreadOnly,
              onPressed: () => setState(() => _unreadOnly = !_unreadOnly),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8, top: 8),
            child: CcChip(
              label: l10n.allFeeds,
              selected: _feedFilter == null,
              onPressed: () => setState(() => _feedFilter = null),
            ),
          ),
          for (final feed in feeds)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8, top: 8),
              child: CcChip(
                label: feed.name,
                selected: _feedFilter == feed.id,
                onPressed: () => setState(() => _feedFilter = feed.id),
              ),
            ),
        ],
      ),
    );
  }
}
