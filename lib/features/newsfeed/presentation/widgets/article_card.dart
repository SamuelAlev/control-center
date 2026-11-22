import 'package:cc_domain/features/newsfeed/domain/entities/rss_article.dart';
import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/article_thumbnail.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/newsfeed_format.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/save_toggle_button.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:material_ui/material_ui.dart';

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

  static const double _padTop = 11;
  static const double _padBottom = AppSpacing.sm + 2;
  static const double _titleLineHeight = 1.3;
  static const double _metaGap = AppSpacing.sm;

  /// The bookmark glyph plus [SaveToggleButton]'s padding on both sides.
  static const double _metaButtonHeight = 16 + 2 * AppSpacing.xs;

  /// Width of the card's border on each edge.
  static const double borderWidth = 1;

  /// Height of everything below the thumbnail, border included: two title
  /// lines and the meta row, at [scaler]. The grid sizes
  /// its tiles from this, so a card is never taller than its content.
  static double bodyHeight(TextScaler scaler) {
    final title =
        2 * scaler.scale(CcTypography.body.fontSize!) * _titleLineHeight;
    final metaText =
        scaler.scale(CcTypography.caption.fontSize!) *
        CcTypography.caption.height!;
    final meta = metaText > _metaButtonHeight ? metaText : _metaButtonHeight;
    return (2 * borderWidth + _padTop + title + _metaGap + meta + _padBottom)
        .ceilToDouble();
  }

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
            border: Border.all(color: border, width: borderWidth),
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
                  child: ArticleThumbnail(imageUrl: image, feed: feed),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    _padTop,
                    AppSpacing.md,
                    _padBottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!read) ...[
                            Padding(
                              padding: const EdgeInsetsDirectional.only(
                                top: 6,
                                end: 7,
                              ),
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
                              style: CcTypography.body.copyWith(
                                fontWeight: read
                                    ? FontWeight.w500
                                    : FontWeight.w600,
                                height: _titleLineHeight,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: _metaGap),
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
    final muted = tokens?.textTertiary ?? theme.colorScheme.onSurfaceVariant;
    final time = article.publishedAt == null
        ? null
        : relativeTimeShort(article.publishedAt!);

    final rtl = Directionality.of(context) == TextDirection.rtl;

    return Row(
      children: [
        // The source group takes all the slack so the bookmark always sits
        // flush with the trailing edge. A loose Flexible beside a Spacer
        // splits the free width between them and strands the bookmark short
        // of the edge.
        Expanded(
          child: Row(
            children: [
              if (feed != null) ...[
                FeedFavicon(feed: feed!, size: 14),
                const SizedBox(width: AppSpacing.xs + 2),
                Flexible(
                  child: Text(
                    feed!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.caption.copyWith(color: muted),
                  ),
                ),
              ],
              if (feed != null && time != null)
                Text(
                  '  ·  ',
                  style: CcTypography.caption.copyWith(color: muted),
                ),
              if (time != null)
                AppTimestamp(
                  dateTime: article.publishedAt!,
                  child: Text(
                    time,
                    style: CcTypography.caption.copyWith(color: muted),
                  ),
                ),
            ],
          ),
        ),
        // Shift by the button's own padding so the glyph lines up with the
        // card's content edge while keeping the full hit target.
        Transform.translate(
          offset: Offset(rtl ? -AppSpacing.xs : AppSpacing.xs, 0),
          child: SaveToggleButton(
            saved: article.saved,
            onToggle: onToggleSaved,
          ),
        ),
      ],
    );
  }
}
