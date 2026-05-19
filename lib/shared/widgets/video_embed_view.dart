import 'dart:io' show Platform;

import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// Inline player for third-party video embeds (Loom, …) recognised by a
/// `VideoEmbedAdapter`. Renders the provider's embed page inside an in-app
/// webview on platforms that support `flutter_inappwebview`
/// (macOS / Windows / iOS / Android); elsewhere — or when the embed fails to
/// load — it degrades to a card that opens the original link in the system
/// browser.
class VideoEmbedView extends StatefulWidget {
  /// Creates a [VideoEmbedView].
  const VideoEmbedView({
    super.key,
    required this.embedUrl,
    required this.sourceUrl,
    required this.providerName,
    this.aspectRatio = 16 / 9,
  });

  /// The provider's embeddable URL (e.g. Loom's `/embed/<id>` form) loaded in
  /// the webview.
  final Uri embedUrl;

  /// The original link the author wrote — opened externally by the fallback.
  final Uri sourceUrl;

  /// Provider name shown on the fallback card (proper noun, not translated).
  final String providerName;

  /// Aspect ratio (width / height) reserved for the player.
  final double aspectRatio;

  @override
  State<VideoEmbedView> createState() => _VideoEmbedViewState();
}

class _VideoEmbedViewState extends State<VideoEmbedView> {
  bool _loaded = false;
  bool _failed = false;

  // `flutter_inappwebview` ships native webviews on these platforms only.
  // Linux has no backend, so we degrade to an "open externally" card.
  bool get _webviewSupported =>
      Platform.isMacOS ||
      Platform.isWindows ||
      Platform.isIOS ||
      Platform.isAndroid;

  @override
  Widget build(BuildContext context) {
    if (!_webviewSupported || _failed) {
      return _VideoEmbedFallbackCard(
        sourceUrl: widget.sourceUrl,
        providerName: widget.providerName,
      );
    }

    final theme = Theme.of(context);
    final aspectRatio = widget.aspectRatio <= 0 ? 16 / 9 : widget.aspectRatio;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : double.infinity;
            final cappedWidth =
                maxWidth.isFinite ? maxWidth.clamp(0.0, 800.0) : 800.0;
            return ConstrainedBox(
              constraints: BoxConstraints(maxWidth: cappedWidth, maxHeight: 600),
              child: AspectRatio(
                aspectRatio: aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    InAppWebView(
                      // Re-create the platform view when the URL changes (e.g.
                      // a body edit swaps the link) rather than navigating.
                      key: ValueKey(widget.embedUrl),
                      initialUrlRequest:
                          URLRequest(url: WebUri.uri(widget.embedUrl)),
                      initialSettings: InAppWebViewSettings(
                        transparentBackground: true,
                        javaScriptEnabled: true,
                        isInspectable: kDebugMode,
                        // Non-persistent data store — embeds are throwaway, and
                        // this keeps WebKit from persisting a per-bundle
                        // "WebCrypto master key" to the macOS keychain (which
                        // otherwise prompts for the keychain password on access
                        // under our ad-hoc/self-signed builds).
                        incognito: true,
                        supportZoom: false,
                        // Let the surrounding markdown scroll instead of the
                        // embed swallowing the gesture.
                        disableVerticalScroll: true,
                        disableHorizontalScroll: true,
                        allowsInlineMediaPlayback: true,
                        mediaPlaybackRequiresUserGesture: true,
                      ),
                      onLoadStop: (controller, url) {
                        if (mounted) {
                          setState(() => _loaded = true);
                        }
                      },
                      onReceivedError: (controller, request, error) {
                        if ((request.isForMainFrame ?? false) && mounted) {
                          setState(() => _failed = true);
                        }
                      },
                    ),
                    if (!_loaded)
                      ColoredBox(
                        color: theme.dividerColor.withValues(alpha: 0.12),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator.adaptive(
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Shown when the webview is unavailable (Linux) or the embed failed to load.
/// Opens the original link in the system browser.
class _VideoEmbedFallbackCard extends StatelessWidget {
  const _VideoEmbedFallbackCard({
    required this.sourceUrl,
    required this.providerName,
  });

  final Uri sourceUrl;
  final String providerName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.hintColor;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: () => launchUrl(sourceUrl, mode: LaunchMode.externalApplication),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.dividerColor.withValues(alpha: 0.12),
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circlePlay, size: 28, color: hint),
              const SizedBox(height: 8),
              Text(
                l10n.watchVideoOn(providerName),
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.externalLink, size: 12, color: hint),
                  const SizedBox(width: 4),
                  Text(
                    l10n.openInBrowser,
                    style: theme.textTheme.labelSmall?.copyWith(color: hint),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
