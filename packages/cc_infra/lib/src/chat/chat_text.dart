/// Text helpers the chat bridge needs for every provider.
///
/// Provider-specific markup lives in the adapter (Slack's mrkdwn codec, for
/// instance); what is left here is genuinely product-independent, so a second
/// provider inherits it rather than re-deriving it.
// Pure text transforms with no state to inject: a namespace, not a service.
// ignore_for_file: avoid_classes_with_only_static_members
library;

/// Provider-independent text shaping for the chat bridge.
abstract final class ChatText {
  /// A space title derived from the first line of [text], capped at
  /// [maxLength]. Empty input yields [fallback].
  ///
  /// Cut on a word boundary when there is one past the halfway mark: a name
  /// truncated mid-word reads like a bug in the sidebar.
  static String titleFrom(
    String text, {
    required String fallback,
    int maxLength = 60,
  }) {
    final firstLine = text
        .split('\n')
        .map((l) => l.trim())
        .firstWhere((l) => l.isNotEmpty, orElse: () => '');
    if (firstLine.isEmpty) {
      return fallback;
    }
    if (firstLine.length <= maxLength) {
      return firstLine;
    }
    final cut = firstLine.substring(0, maxLength);
    final lastSpace = cut.lastIndexOf(' ');
    return '${lastSpace > 20 ? cut.substring(0, lastSpace) : cut}…';
  }
}
