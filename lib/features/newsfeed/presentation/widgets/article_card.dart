import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_format.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/save_toggle_button.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';

/// Card representation of an article in the newsfeed grid.
class ArticleCard extends StatelessWidget {
  /// Creates a new [ArticleCard].
  const ArticleCard({
    super.key,
    required this.article,
    required this.feed,
    required this.onTap,
    required this.onToggleSaved,
    this.focusNode,
  });

  /// Article data to display.
  final RssArticle article;

  /// Parent feed, if known.
  final RssFeed? feed;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  /// Called when the bookmark icon is toggled.
  final VoidCallback onToggleSaved;

  /// Focus node driving the native focus ring. j/k navigation requests focus
  /// on this node rather than painting a separate selection highlight.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tokens = context.designSystem;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final article = this.article;
    final feed = this.feed;
    final image = article.imageUrl;
    final read = article.read;

    final border = tokens?.borderSecondary ?? colors.outlineVariant;
    final titleColor = read
        ? (tokens?.textTertiary ?? colors.onSurfaceVariant)
        : (tokens?.textPrimary ?? colors.onSurface);
    final brand = tokens?.fgBrandPrimary ?? colors.primary;

    return CcTappable(
      focusNode: focusNode,
      onPressed: onTap,
      borderRadius: AppRadii.brLg,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final bg = hovered
            ? (tokens?.bgPrimaryHover ?? colors.surfaceContainerHighest)
            : (tokens?.bgPrimary ?? colors.surface);
        return AnimatedContainer(
          duration: Duration(milliseconds: reduceMotion ? 0 : 120),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: border),
            boxShadow: hovered ? AppShadows.soft : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Opacity(
                  opacity: read ? 0.55 : 1,
                  child: image.isNotEmpty
                      ? _NetworkThumbnail(url: image, feed: feed)
                      : _PlaceholderThumbnail(feed: feed),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    11,
                    AppSpacing.md,
                    AppSpacing.sm + 2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!read) ...[
                            Padding(
                              padding: const EdgeInsets.only(top: 6, right: 7),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: brand,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                          Expanded(
                            child: Text(
                              article.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: read
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                height: 1.3,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (article.summary.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs + 2),
                        Text(
                          article.summary,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.4,
                            color:
                                tokens?.textTertiary ?? colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                      const Spacer(),
                      const SizedBox(height: AppSpacing.sm),
                      _MetaRow(
                        feed: feed,
                        article: article,
                        onToggleSaved: onToggleSaved,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Footer row: source favicon + name · relative time, with the bookmark
/// toggle aligned to the trailing edge.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.feed,
    required this.article,
    required this.onToggleSaved,
  });

  final RssFeed? feed;
  final RssArticle article;
  final VoidCallback onToggleSaved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final muted =
        tokens?.textTertiary ?? theme.colorScheme.onSurfaceVariant;
    final time = article.publishedAt == null
        ? null
        : relativeTimeShort(article.publishedAt!);

    return Row(
      children: [
        if (feed != null) ...[
          FeedFavicon(feed: feed, size: 14),
          const SizedBox(width: AppSpacing.xs + 2),
        ],
        if (feed != null)
          Flexible(
            child: Text(
              feed!.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(color: muted),
            ),
          ),
        if (feed != null && time != null)
          Text(
            '  ·  ',
            style: theme.textTheme.labelSmall?.copyWith(color: muted),
          ),
        if (time != null)
          Text(time, style: theme.textTheme.labelSmall?.copyWith(color: muted)),
        const Spacer(),
        SaveToggleButton(saved: article.saved, onToggle: onToggleSaved),
      ],
    );
  }
}

class _NetworkThumbnail extends StatelessWidget {
  const _NetworkThumbnail({required this.url, required this.feed});
  final String url;
  final RssFeed? feed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    // The card grid caps each tile at maxCrossAxisExtent 340; size the proxy
    // resize / decode to that width (cover crops, so width-only keeps aspect).
    final targetWidth = (340 * MediaQuery.devicePixelRatioOf(context)).ceil();
    return Stack(
      fit: StackFit.expand,
      children: [
        // First-load backdrop sits BEHIND the image. We do NOT use a
        // loadingBuilder that paints over the image: on web a network image
        // re-resolves on every rebuild, and overpainting it with a solid colour
        // makes it flicker. gaplessPlayback keeps the last frame on top of this
        // backdrop instead.
        ColoredBox(
          color:
              tokens?.bgSecondary ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        Image.network(
          MediaProxyScope.urlOf(context, url, maxWidth: targetWidth),
          fit: BoxFit.cover,
          cacheWidth: targetWidth,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => _PlaceholderThumbnail(feed: feed),
        ),
      ],
    );
  }
}

/// Neutral fallback shown when an article has no image (or it fails to load).
///
/// Replaces the former random hash-to-hue gradient — which painted a
/// full-spectrum rainbow that reported nothing and broke the one-signal-colour
/// rule. The tile is a quiet graphite surface; the centred [FeedFavicon] makes
/// the placeholder *report its source* (ownership) instead of decorating with
/// meaningless colour. With no feed it falls back to a neutral newspaper glyph.
class _PlaceholderThumbnail extends StatelessWidget {
  const _PlaceholderThumbnail({required this.feed});
  final RssFeed? feed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.designSystem;
    final feed = this.feed;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tokens?.bgSecondary ?? colors.surfaceContainerHighest,
            tokens?.bgTertiary ?? colors.surfaceContainerHighest,
          ],
        ),
      ),
      child: Center(
        child: feed != null
            ? Opacity(opacity: 0.85, child: FeedFavicon(feed: feed, size: 36))
            : Icon(
                AppIcons.newspaper,
                size: 28,
                color: tokens?.fgQuaternary ?? colors.onSurfaceVariant,
              ),
      ),
    );
  }
}
