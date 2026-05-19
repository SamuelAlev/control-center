import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_article.dart';
import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_format.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/save_toggle_button.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Dense, scannable row representation of an article — the digest layout's
/// unit, and the default newsfeed view.
///
/// One line of title plus a muted source/time line, a compact leading
/// thumbnail, and the trailing bookmark toggle. Read/unread is carried by the
/// leading dot, the title weight, and the title colour together (never colour
/// alone); hover tints the whole row, and keyboard focus is shown by the
/// native focus ring.
class ArticleListRow extends StatefulWidget {
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
  State<ArticleListRow> createState() => _ArticleListRowState();
}

class _ArticleListRowState extends State<ArticleListRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fColors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final article = widget.article;
    final feed = widget.feed;
    final read = article.read;

    final hoverColor = tokens?.bgPrimaryHover ?? fColors.muted;
    // Resting state fades the hover color's alpha to zero rather than using
    // Colors.transparent (transparent black). Lerping to transparent black
    // makes Color.lerp cross through dark tones, flashing on mouse-out.
    final bg = _hovered ? hoverColor : hoverColor.withAlpha(0);
    final muted = tokens?.textTertiary ?? fColors.mutedForeground;
    final titleColor = read
        ? (tokens?.textTertiary ?? fColors.mutedForeground)
        : (tokens?.textPrimary ?? fColors.foreground);
    final brand = tokens?.fgBrandPrimary ?? fColors.primary;
    final time = article.publishedAt == null
        ? null
        : relativeTimeShort(article.publishedAt!);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: FTappable.static(
        focusNode: widget.focusNode,
        onPress: widget.onTap,
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        child: AnimatedContainer(
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
                onToggle: widget.onToggleSaved,
              ),
            ],
          ),
        ),
      ),
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
    final fColors = FTheme.of(context).colors;
    final tokens = context.designSystem;
    final fallback = DecoratedBox(
      decoration: BoxDecoration(color: tokens?.bgSecondary ?? fColors.muted),
      child: Center(
        child: feed != null
            ? FeedFavicon(feed: feed, size: 18)
            : Icon(
                LucideIcons.newspaper,
                size: 16,
                color: tokens?.fgQuaternary ?? fColors.mutedForeground,
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
            : Image.network(
                image,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => fallback,
                loadingBuilder: (context, child, progress) =>
                    progress == null ? child : fallback,
              ),
      ),
    );
  }
}
