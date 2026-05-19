import 'package:control_center/features/newsfeed/domain/entities/rss_feed.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

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
    final fallback = FAvatar.raw(
      size: size,
      child: Text(
        initial,
        style: TextStyle(fontSize: size * 0.5, fontWeight: FontWeight.w600),
      ),
    );
    if (url.isEmpty) {
      return fallback;
    }
    return FAvatar(image: NetworkImage(url), size: size, fallback: fallback);
  }
}
