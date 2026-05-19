import 'package:cc_domain/core/domain/entities/channel_message.dart';

/// The default page size for cursor-based history loading.
const int defaultMessagePageSize = 80;

/// One page of conversation history, oldest-first for display, plus a cursor to
/// load the page before it.
class MessagePage {
  /// Creates a [MessagePage].
  const MessagePage({
    required this.messages,
    required this.hasMore,
    this.nextCursor,
  });

  /// The page's messages in ascending (oldest-first) order.
  final List<ChannelMessage> messages;

  /// Whether older messages exist before this page.
  final bool hasMore;

  /// Opaque cursor to pass back as `before` to load the page just before this
  /// one; null when [hasMore] is false.
  final String? nextCursor;

  /// An empty page.
  static const MessagePage empty =
      MessagePage(messages: [], hasMore: false);
}
