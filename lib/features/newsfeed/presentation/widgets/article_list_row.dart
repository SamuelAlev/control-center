import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_format.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/save_toggle_button.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';

/// Dense, scannable row representation of an article — the digest layout's
/// unit, and the default newsfeed view.
///
/// One line of title plus a muted source/time line, a compact leading
/// thumbnail, and the trailing bookmark toggle. Read/unread is carried by the
/// leading dot, the title weight, and the title colour together (never colour
/// alone); hover tints the whole row, and keyboard focus is shown by the
/// native focus ring.
class ArticleListRow extends StatelessWidget {
  /// Creates an [ArticleListRow].
  const ArticleListRow({
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

  /// Called when the row is tapped.
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
    final read = article.read;

    final hoverColor = tokens?.bgPrimaryHover ?? colors.surfaceContainerHighest;
    final muted = tokens?.textTertiary ?? colors.onSurfaceVariant;
    final titleColor = read
        ? (tokens?.textTertiary ?? colors.onSurfaceVariant)
        : (tokens?.textPrimary ?? colors.onSurface);
    final brand = tokens?.fgBrandPrimary ?? colors.primary;
    final time = article.publishedAt == null
        ? null
        : relativeTimeShort(article.publishedAt!);

    return CcTappable(
      focusNode: focusNode,
      onPressed: onTap,
      borderRadius: AppRadii.brMd,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        // Resting state fades the hover color's alpha to zero rather than
        // using Colors.transparent (transparent black). Lerping to transparent
        // black makes Color.lerp cross through dark tones, flashing on
        // mouse-out.
        final bg = hovered ? hoverColor : hoverColor.withAlpha(0);
        return AnimatedContainer(
          duration: Duration(milliseconds: reduceMotion ? 0 : 120),
          decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brMd),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Opacity(
                opacity: read ? 0.55 : 1,
                child: _RowThumb(image: article.imageUrl, feed: feed),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!read) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 5, right: 7),
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
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: read
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              color: titleColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        if (feed != null) ...[
                          FeedFavicon(feed: feed, size: 13),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Flexible(
                            child: Text(
                              feed.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                        if (feed != null && time != null)
                          Text(
                            '  ·  ',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        if (time != null)
                          Text(
                            time,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SaveToggleButton(
                saved: article.saved,
                onToggle: onToggleSaved,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Compact 56×40 leading tile: the article image when present, otherwise the
/// same neutral source-favicon fallback the cards use (no hash-derived colour).
class _RowThumb extends StatelessWidget {
  const _RowThumb({required this.image, required this.feed});
  final String image;
  final RssFeed? feed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tokens = context.designSystem;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        color: tokens?.bgSecondary ?? colors.surfaceContainerHighest,
      ),
      child: Center(
        child: feed != null
            ? FeedFavicon(feed: feed, size: 18)
            : Icon(
                AppIcons.newspaper,
                size: 16,
                color: tokens?.fgQuaternary ?? colors.onSurfaceVariant,
              ),
      ),
    );
    return ClipRRect(
      borderRadius: AppRadii.brSm,
      child: SizedBox(
        width: 56,
        height: 40,
        child: image.isEmpty
            ? fallback
            // Fallback sits BEHIND the image (no overpainting loadingBuilder):
            // on web a network image re-resolves on rebuild, so painting the
            // fallback over it would flicker. gaplessPlayback holds the frame.
            : Stack(
                fit: StackFit.expand,
                children: [
                  fallback,
                  Image.network(
                    MediaProxyScope.urlOf(
                      context,
                      image,
                      maxWidth: (56 * dpr).ceil(),
                    ),
                    fit: BoxFit.cover,
                    cacheWidth: (56 * dpr).round(),
                    cacheHeight: (40 * dpr).round(),
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => fallback,
                  ),
                ],
              ),
      ),
    );
  }
}
