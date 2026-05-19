// Web article reader: the browser IS the reader.
//
// The desktop reader embeds an ad-blocking webview (flutter_inappwebview + the
// locally-cached filter lists) — inherently desktop-only. On web the browser
// already renders pages, so this screen resolves the article over RPC and opens
// it in a new tab, then offers to open it again. (The newsfeed list also opens
// externally on web, so this route is mainly a deep-link fallback.)
library;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web article reader — opens the article URL in the browser.
class ArticleWebviewScreen extends ConsumerStatefulWidget {
  /// Creates an [ArticleWebviewScreen] for [articleId].
  const ArticleWebviewScreen({super.key, required this.articleId});

  /// ID of the article to open.
  final String articleId;

  @override
  ConsumerState<ArticleWebviewScreen> createState() =>
      _ArticleWebviewScreenState();
}

class _ArticleWebviewScreenState extends ConsumerState<ArticleWebviewScreen> {
  bool _opened = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final article = ref.watch(articleByIdProvider(widget.articleId)).value;
    final url = article?.link ?? '';

    // Open the article in a new tab once, as soon as it resolves.
    if (!_opened && url.isNotEmpty) {
      _opened = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => openExternalUrl(url));
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              article?.title ?? 'Article',
              style: TextStyle(
                color: tokens?.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Opened in your browser.',
              style: TextStyle(color: tokens?.textTertiary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            CcButton(
              onPressed: url.isEmpty ? null : () => openExternalUrl(url),
              child: const Text('Open in browser'),
            ),
          ],
        ),
      ),
    );
  }
}
