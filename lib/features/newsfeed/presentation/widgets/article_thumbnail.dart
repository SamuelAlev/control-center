import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/newsfeed/presentation/widgets/feed_favicon.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/proxied_image.dart';
import 'package:flutter/widgets.dart';

/// An article card's thumbnail: the article's image, or the source-favicon
/// placeholder when it has none (or it fails to load).
class ArticleThumbnail extends StatelessWidget {
  /// Creates an [ArticleThumbnail].
  const ArticleThumbnail({
    required this.imageUrl,
    required this.feed,
    super.key,
  });

  /// The article's image URL; empty when it has none.
  final String imageUrl;

  /// The article's feed, if known.
  final RssFeed? feed;

  @override
  Widget build(BuildContext context) => imageUrl.isNotEmpty
      ? _NetworkThumbnail(url: imageUrl, feed: feed)
      : _PlaceholderThumbnail(feed: feed);
}

class _NetworkThumbnail extends StatelessWidget {
  const _NetworkThumbnail({required this.url, required this.feed});
  final String url;
  final RssFeed? feed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    // The card grid caps each tile at maxCrossAxisExtent 340; size the proxy
    // resize / decode to that width (cover crops, so width-only keeps aspect).
    final targetWidth = (340 * MediaQuery.devicePixelRatioOf(context)).ceil();
    return ProxiedImage(
      url: url,
      maxWidth: targetWidth,
      fit: BoxFit.cover,
      placeholder: ColoredBox(color: tokens.bgSecondary),
      // The error widget fades in over prior content, so a failed load settles
      // onto the source-favicon fallback instead of flashing.
      errorBuilder: (_, _) => _PlaceholderThumbnail(feed: feed),
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
    final tokens = context.ds;
    final feed = this.feed;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [tokens.bgSecondary, tokens.bgTertiary],
        ),
      ),
      child: Center(
        child: feed != null
            ? Opacity(opacity: 0.85, child: FeedFavicon(feed: feed, size: 36))
            : Icon(AppIcons.newspaper, size: 28, color: tokens.fgQuaternary),
      ),
    );
  }
}
