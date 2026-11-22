import 'package:cc_domain/core/domain/value_objects/feed_position.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_read_repository.dart';

/// A no-host [ConversationReadRepository]: emits [reads] for every workspace
/// watch and records each mark, calling [onMark] when given.
///
/// The real provider is RPC-backed and would reach for a connection, leaving
/// a pending reconnect timer after the widget tree is torn down.
class FakeConversationReadRepository implements ConversationReadRepository {
  /// Creates a [FakeConversationReadRepository].
  FakeConversationReadRepository({this.reads = const {}, this.onMark});

  /// The cursors every watch emits, keyed by conversation id.
  final Map<String, FeedPosition> reads;

  /// Called after each mark is recorded.
  final Future<void> Function(String workspaceId, String conversationId)?
  onMark;

  /// Every `(workspaceId, conversationId)` marked read, in order.
  final List<({String workspaceId, String conversationId})> marked = [];

  /// Every workspace a watch was opened for, in order.
  final List<String> watched = [];

  @override
  Future<void> markConversationRead(
    String workspaceId,
    String conversationId,
    String userId,
  ) async {
    marked.add((workspaceId: workspaceId, conversationId: conversationId));
    await onMark?.call(workspaceId, conversationId);
  }

  @override
  Stream<Map<String, FeedPosition>> watchUserConversationReads(
    String workspaceId,
    String userId,
  ) {
    watched.add(workspaceId);
    return Stream.value(reads);
  }
}
