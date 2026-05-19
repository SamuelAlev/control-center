import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Newsfeed tab: live articles (`newsfeed.watchArticles`) filterable by feed
/// (`newsfeed.watchFeeds`) and unread, and pushes a reader route. Newsfeed is
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
                message: "Couldn't load articles",
                description: e.toString(),
              ),
              data: (_) {
                if (articles.isEmpty) {
                  return const CcEmptyState(
                    icon: AppIcons.newspaper,
                    message: 'No articles',
                    description: 'New articles appear here as feeds update.',
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: articles.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) =>
                      _articleCard(t, articles[i]),
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
                    fontWeight:
                        article.isRead ? FontWeight.w400 : FontWeight.w600,
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
              padding: const EdgeInsets.only(left: 8),
              child: Icon(AppIcons.bookmark, size: 16, color: t.accent),
            ),
        ],
      ),
    );
  }

  Widget _filterBar(DesignSystemTokens t, List<FeedDto> feeds) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: CcChip(
              label: 'Unread',
              selected: _unreadOnly,
              onTap: () => setState(() => _unreadOnly = !_unreadOnly),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 8),
            child: CcChip(
              label: 'All feeds',
              selected: _feedFilter == null,
              onTap: () => setState(() => _feedFilter = null),
            ),
          ),
          for (final feed in feeds)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 8),
              child: CcChip(
                label: feed.name,
                selected: _feedFilter == feed.id,
                onTap: () => setState(() => _feedFilter = feed.id),
              ),
            ),
        ],
      ),
    );
  }
}

/// `/article/:articleId` — reader. Marks the article read on open; toggles save.
/// The article is resolved from the live article list (there is no per-article
/// repo/call op), so it updates in place as the host refreshes feeds.
class ArticleReaderScreen extends ConsumerStatefulWidget {
  /// Creates an [ArticleReaderScreen].
  const ArticleReaderScreen({required this.articleId, super.key});

  /// The article id from the route.
  final String articleId;

  @override
  ConsumerState<ArticleReaderScreen> createState() =>
      _ArticleReaderScreenState();
}

class _ArticleReaderScreenState extends ConsumerState<ArticleReaderScreen> {
  bool _markedRead = false;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final article = ref
        .watch(newsfeedArticlesProvider)
        .value
        ?.where((a) => a.id == widget.articleId)
        .firstOrNull;

    // Mark read once the article resolves.
    if (article != null && !article.isRead && !_markedRead) {
      _markedRead = true;
      _markRead();
    }

    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _readerHeader(t, article),
            if (article == null)
              const Expanded(child: Center(child: CcSpinner(size: 24)))
            else
              Expanded(child: _body(t, article)),
          ],
        ),
      ),
    );
  }

  RemoteNewsfeedRepository? _repo() {
    final client = ref.read(rpcClientProvider).value;
    return client == null ? null : RemoteNewsfeedRepository(client);
  }

  Future<void> _markRead() async {
    try {
      await _repo()?.setRead(widget.articleId, read: true);
    } catch (_) {
      // Marking read is best-effort.
    }
  }

  Future<void> _toggleSaved(ArticleDto article) async {
    final repo = _repo();
    if (repo == null) {
      return;
    }
    try {
      await repo.setSaved(article.id, saved: !article.isSaved);
    } catch (_) {
      // The live subscription re-syncs the real state on failure.
    }
  }

  Widget _readerHeader(DesignSystemTokens t, ArticleDto? article) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.topbar,
        border: Border(bottom: BorderSide(color: t.borderSoft)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            CcTappable(
              onPressed: () => context.pop(),
              semanticLabel: 'Back',
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(AppIcons.arrowLeft, color: t.fgSecondary),
              ),
            ),
            const Spacer(),
            CcTappable(
              onPressed: article == null ? null : () => _toggleSaved(article),
              semanticLabel: 'Save',
              builder: (context, _) => Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  article?.isSaved == true
                      ? AppIcons.bookmarkCheck
                      : AppIcons.bookmark,
                  color: t.fgSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(DesignSystemTokens t, ArticleDto article) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          article.title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: t.textPrimary,
          ),
        ),
        if (article.author != null || article.publishedAt != null) ...[
          const SizedBox(height: 8),
          Text(
            [
              if (article.author != null) article.author!,
              if (article.publishedAt != null)
                _formatDate(article.publishedAt!),
            ].join(' · '),
            style: TextStyle(fontSize: 13, color: t.textTertiary),
          ),
        ],
        const SizedBox(height: 20),
        if (article.summary?.isNotEmpty == true)
          Text(
            article.summary!,
            style: TextStyle(fontSize: 15, height: 1.6, color: t.textSecondary),
          ),
        if (article.url != null) ...[
          const SizedBox(height: 24),
          CcButton(
            fullWidth: true,
            variant: CcButtonVariant.secondary,
            icon: AppIcons.externalLink,
            onPressed: () => {},
            child: const Text('Read full article'),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime d) {
    final local = d.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}';
  }
}
