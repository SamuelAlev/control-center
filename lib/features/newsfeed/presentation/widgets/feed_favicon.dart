import 'package:cc_domain/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/media_proxy_scope.dart';
import 'package:flutter/material.dart';

/// Resolves the best favicon URL for [feed].
///
/// Prefers the icon the feed advertises, then falls back to the feed's own
/// origin (`https://host/favicon.ico`). We deliberately do NOT route through a
/// third-party favicon service (e.g. Google's `s2/favicons`): this feature
/// blocks trackers, so it must not leak the user's subscription list to an
/// unrelated host. The feed's origin is already contacted to fetch the RSS, so
/// requesting its favicon adds no new party.
String feedFaviconUrl(RssFeed feed) {
  if (feed.iconUrl.isNotEmpty) {
    return feed.iconUrl;
  }
  final uri = Uri.tryParse(feed.url);
  if (uri != null && uri.host.isNotEmpty && uri.scheme.startsWith('http')) {
    return '${uri.scheme}://${uri.host}/favicon.ico';
  }
  return '';
}

/// Small rounded source icon for a feed. Shows the favicon when available and
/// falls back to the feed's initial. When [feed] is null a neutral globe
/// placeholder is rendered.
class FeedFavicon extends StatelessWidget {
  /// Creates a new [FeedFavicon].
  const FeedFavicon({super.key, required this.feed, this.size = 16});

  /// The feed whose icon should be shown.
  final RssFeed? feed;

  /// Diameter of the avatar.
  final double size;

  @override
  Widget build(BuildContext context) {
    final feed = this.feed;
    final initial = (feed != null && feed.name.isNotEmpty)
        ? feed.name.substring(0, 1).toUpperCase()
        : '?';
    final url = feed == null ? '' : feedFaviconUrl(feed);
    final fallback = CcAvatar(size: size, initials: initial);
    if (url.isEmpty) {
      return fallback;
    }
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return CcAvatar(
      image: NetworkImage(
        MediaProxyScope.urlOf(context, url, maxWidth: (size * dpr).ceil()),
      ),
      size: size,
      initials: initial,
    );
  }
}
