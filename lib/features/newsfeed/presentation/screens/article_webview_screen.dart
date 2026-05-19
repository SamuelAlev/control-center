import 'dart:async';
import 'dart:io' show Platform;

import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/tracking_param_stripper.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/adblocker_webview.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/adblocker_webview_controller.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/features/newsfeed/providers/site_allowlist_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

bool get _isLinux => !kIsWeb && Platform.isLinux;

/// In-app reader for an article URL.
class ArticleWebviewScreen extends ConsumerStatefulWidget {
  /// Creates a new [ArticleWebviewScreen].
  const ArticleWebviewScreen({super.key, required this.articleId});

  /// ID of the article to display.
  final String articleId;

  @override
  ConsumerState<ArticleWebviewScreen> createState() =>
      _ArticleWebviewScreenState();
}

class _ArticleWebviewScreenState extends ConsumerState<ArticleWebviewScreen> {
  late final AdBlockerWebViewController _webController;
  RssArticle? _article;
  Uri? _initialUrl;
  String _currentUrl = '';
  Timer? _loadTimeoutTimer;
  bool _loadTimedOut = false;

  @override
  void initState() {
    super.initState();
    _webController = AdBlockerWebViewController();
    _webController.isLoading.addListener(_onWebStateChanged);
    _webController.navState.addListener(_onWebStateChanged);
    _webController.currentUrl.addListener(_onWebStateChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolveAndBootstrap());
  }

  @override
  void dispose() {
    _loadTimeoutTimer?.cancel();
    _webController.isLoading.removeListener(_onWebStateChanged);
    _webController.navState.removeListener(_onWebStateChanged);
    _webController.currentUrl.removeListener(_onWebStateChanged);
    _webController.dispose();
    super.dispose();
  }

  void _onWebStateChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _resolveAndBootstrap() async {
    AppLog.d(
      'ArticleWebviewScreen',
      'resolve start articleId=${widget.articleId}',
    );
    try {
      final article = await ref
          .read(newsfeedRepositoryProvider)
          .getArticleById(widget.articleId);
      if (article == null) {
        AppLog.w(
          'ArticleWebviewScreen',
          'article not found id=${widget.articleId}',
        );
        if (mounted) {
          context.go(newsfeedRoute);
        }
        return;
      }

      final cleanLink = stripTrackingParams(
        article.link,
        knownParams: defaultRemoveParams(),
      );
      AppLog.d(
        'ArticleWebviewScreen',
        'resolved articleId=${widget.articleId} '
            'original=${article.link} stripped=$cleanLink',
      );

      if (_isLinux) {
        await launchUrl(
          Uri.parse(cleanLink),
          mode: LaunchMode.externalApplication,
        );
        if (mounted) {
          context.go(newsfeedRoute);
        }
        return;
      }

      if (!mounted) {
        return;
      }
      setState(() {
        _article = article;
        _initialUrl = Uri.parse(cleanLink);
        _currentUrl = cleanLink;
      });
    } on Object catch (e, st) {
      AppLog.e('ArticleWebviewScreen', 'resolve failed', e, st);
      if (mounted) {
        context.go(newsfeedRoute);
      }
    }
  }

  void _startLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (mounted && _webController.isLoading.value) {
        setState(() => _loadTimedOut = true);
      }
    });
  }

  Future<void> _toggleSiteAllowlist() async {
    final url = _currentUrl;
    if (url.isEmpty) {
      return;
    }
    final repo = ref.read(siteAllowlistRepositoryProvider);
    final host = repo.hostOf(url);
    if (host.isEmpty) {
      return;
    }
    final normalised = repo.normalizeDomain(host);
    if (normalised.isEmpty) {
      return;
    }
    final allowed = await repo.read();
    if (repo.isAllowedUrl(url, allowed)) {
      // Find the matching entry to remove (could be the exact host or a
      // parent suffix entry).
      String? toRemove;
      for (final entry in allowed) {
        if (normalised == entry || normalised.endsWith('.$entry')) {
          toRemove = entry;
          break;
        }
      }
      if (toRemove != null) {
        await repo.remove(toRemove);
      }
    } else {
      await repo.add(normalised);
    }
    // The AdBlockerWebView listens for allowlist changes and reloads.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final article = _article;
    final initialUrl = _initialUrl;
    final ready = article != null && initialUrl != null;
    final blockingOnForCurrent = _currentUrl.isEmpty
        ? true
        : ref.watch(siteBlockingEnabledProvider(_currentUrl));
    final nav = _webController.navState.value;
    final loading = _webController.isLoading.value;

    return Scaffold(
      body: Column(
        children: [
          _ReaderToolbar(
            url: _currentUrl,
            loading: loading,
            loadTimedOut: _loadTimedOut,
            canGoBack: nav.canGoBack,
            canGoForward: nav.canGoForward,
            saved: article?.saved ?? false,
            blockingEnabled: blockingOnForCurrent,
            onClose: () => context.go(newsfeedRoute),
            onBack: () => _webController.goBack(),
            onForward: () => _webController.goForward(),
            onReload: () => _webController.reload(),
            onToggleBlocking: _toggleSiteAllowlist,
            onOpenExternal: () async {
              final link = article?.link;
              if (link != null) {
                final cleanLink = stripTrackingParams(
                  link,
                  knownParams: defaultRemoveParams(),
                );
                await launchUrl(
                  Uri.parse(cleanLink),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            onToggleSaved: article == null
                ? null
                : () => ref
                      .read(newsfeedRepositoryProvider)
                      .setArticleSaved(article.id, saved: !article.saved),
            l10n: l10n,
          ),
          const FDivider(),
          Expanded(
            child: !ready
                ? const Center(child: FCircularProgress())
                : AdBlockerWebView(
                    initialUrl: initialUrl,
                    controller: _webController,
                    onLoadStart: (url) {
                      _startLoadTimeout();
                      if (mounted) {
                        setState(() => _loadTimedOut = false);
                      }
                    },
                    onLoadStop: (_) => _loadTimeoutTimer?.cancel(),
                    onLoadError: (_, _) {
                      _loadTimeoutTimer?.cancel();
                      if (mounted) {
                        setState(() => _loadTimedOut = true);
                      }
                    },
                    onUrlChanged: (url) {
                      if (url != null && mounted) {
                        setState(() => _currentUrl = url.toString());
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ReaderToolbar extends StatelessWidget {
  const _ReaderToolbar({
    required this.url,
    required this.loading,
    required this.loadTimedOut,
    required this.canGoBack,
    required this.canGoForward,
    required this.saved,
    required this.blockingEnabled,
    required this.onClose,
    required this.onBack,
    required this.onForward,
    required this.onReload,
    required this.onToggleBlocking,
    required this.onOpenExternal,
    required this.onToggleSaved,
    required this.l10n,
  });

  final String url;
  final bool loading;
  final bool loadTimedOut;
  final bool canGoBack;
  final bool canGoForward;
  final bool saved;
  final bool blockingEnabled;
  final VoidCallback onClose;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onReload;
  final VoidCallback onToggleBlocking;
  final VoidCallback onOpenExternal;
  final VoidCallback? onToggleSaved;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          FTooltip(
            tipAnchor: Alignment.topLeft,
            childAnchor: Alignment.bottomLeft,
            tipBuilder: (_, _) => Text(l10n.closeReader),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: onClose,
              child: const Icon(LucideIcons.x, size: 16),
            ),
          ),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(l10n.backLabel),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: canGoBack ? onBack : null,
              child: const Icon(LucideIcons.arrowLeft, size: 16),
            ),
          ),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(l10n.forward),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: canGoForward ? onForward : null,
              child: const Icon(LucideIcons.arrowRight, size: 16),
            ),
          ),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(l10n.reload),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: loading ? null : onReload,
              child: loading
                  ? const FCircularProgress(
                      style: FCircularProgressStyleDelta.delta(
                        iconStyle: IconThemeDataDelta.delta(size: 16),
                      ),
                    )
                  : const Icon(LucideIcons.refreshCw, size: 16),
            ),
          ),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(
              blockingEnabled
                  ? l10n.disableBlockingForThisSite
                  : l10n.enableBlockingForThisSite,
            ),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: url.isEmpty ? null : onToggleBlocking,
              child: Icon(
                blockingEnabled ? LucideIcons.shield : LucideIcons.shieldOff,
                size: 16,
                color: blockingEnabled ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          if (loadTimedOut)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: tokens?.bgWarningSecondary ?? Colors.amber.withAlpha(30),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.alertTriangle,
                      size: 14,
                      color: tokens?.fgWarningPrimary ?? Colors.amber.shade700,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        l10n.pageLoadTimedOut,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens?.textWarningPrimary ??
                              Colors.amber.shade800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  url,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          const SizedBox(width: 8),
          if (onToggleSaved != null)
            FTooltip(
              tipAnchor: Alignment.topRight,
              childAnchor: Alignment.bottomRight,
              tipBuilder: (_, _) =>
                  Text(saved ? l10n.removeBookmark : l10n.bookmarkLabel),
              child: FButton.icon(
                variant: FButtonVariant.ghost,
                onPress: onToggleSaved,
                child: Icon(
                  LucideIcons.bookmark,
                  size: 16,
                  color: saved ? theme.colorScheme.primary : null,
                ),
              ),
            ),
          FTooltip(
            tipAnchor: Alignment.topRight,
            childAnchor: Alignment.bottomRight,
            tipBuilder: (_, _) => Text(l10n.openInBrowser),
            child: FButton.icon(
              variant: FButtonVariant.ghost,
              onPress: onOpenExternal,
              child: const Icon(LucideIcons.externalLink, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
