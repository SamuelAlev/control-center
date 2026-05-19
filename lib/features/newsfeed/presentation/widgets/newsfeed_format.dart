/// Compact relative timestamp used on article cards, e.g. `now`, `30m`, `3h`,
/// `3d`, `2w`. Always returns a short, locale-neutral token.
String relativeTimeShort(DateTime when) {
  final diff = DateTime.now().difference(when);
  if (diff.inMinutes < 1) {
    return 'now';
  }
  if (diff.inMinutes < 60) {
    return '${diff.inMinutes}m';
  }
  if (diff.inHours < 24) {
    return '${diff.inHours}h';
  }
  if (diff.inDays < 7) {
    return '${diff.inDays}d';
  }
  return '${(diff.inDays / 7).floor()}w';
}
