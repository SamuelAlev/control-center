import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/external_link.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    } catch (_) {}
  }

  Future<void> _toggleSaved(ArticleDto article) async {
    final repo = _repo();
    if (repo == null) {
      return;
    }
    try {
      await repo.setSaved(article.id, saved: !article.isSaved);
    } catch (_) {}
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
            PhoneIconButton(
              icon: AppIcons.arrowLeft,
              semanticLabel: AppLocalizations.of(context).back,
              onPressed: () => context.pop(),
              color: t.fgSecondary,
            ),
            const Spacer(),
            PhoneIconButton(
              icon: article?.isSaved == true
                  ? AppIcons.bookmarkCheck
                  : AppIcons.bookmark,
              semanticLabel: article?.isSaved == true
                  ? AppLocalizations.of(context).unsave
                  : AppLocalizations.of(context).save,
              onPressed: article == null ? null : () => _toggleSaved(article),
              color: t.fgSecondary,
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
                shortDate(context, article.publishedAt!),
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
            onPressed: () => openExternal(article.url),
            child: Text(AppLocalizations.of(context).readFullArticle),
          ),
        ],
      ],
    );
  }
}
