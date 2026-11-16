import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/message_lifecycle_states.dart';

/// One message of a conversation as its outline states it: what a feed
/// needs to place and size the row before it has the message.
///
/// The outline covers the whole conversation, so a scrollbar can span all of
/// it while only a window of messages is loaded. Every field is a stored
/// value; none is read from the message's content, metadata or transcript.
class ConversationOutlineEntry {
  /// Creates a [ConversationOutlineEntry].
  ///
  /// Throws an [ArgumentError] for an empty [id], or a negative
  /// [contentChars], [segmentCount] or [revision].
  ConversationOutlineEntry({
    required this.id,
    required this.createdAt,
    required this.senderId,
    required this.senderType,
    required this.messageType,
    required this.contentChars,
    this.segmentCount,
    this.steerState,
    this.answered = false,
    this.revision = 0,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (contentChars < 0) {
      throw ArgumentError.value(
        contentChars,
        'contentChars',
        'must not be negative',
      );
    }
    final count = segmentCount;
    if (count != null && count < 0) {
      throw ArgumentError.value(count, 'segmentCount', 'must not be negative');
    }
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must not be negative');
    }
  }

  /// The message id.
  final String id;

  /// When the message was written (second resolution, as stored).
  final DateTime createdAt;

  /// Who sent it.
  final String senderId;

  /// What kind of sender that is.
  final SenderType senderType;

  /// How the message renders.
  final MessageType messageType;

  /// Unicode code points in the message's content.
  final int contentChars;

  /// The number of transcript segments of a turn that finished, or null
  /// while the turn streams and for a message with no transcript.
  final int? segmentCount;

  /// A steering message's queue state, or null for every other message.
  final SteeringState? steerState;

  /// Whether a question has been answered or expired.
  final bool answered;

  /// The message row's change counter ([Message.revision]).
  final int revision;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConversationOutlineEntry &&
          id == other.id &&
          createdAt == other.createdAt &&
          senderId == other.senderId &&
          senderType == other.senderType &&
          messageType == other.messageType &&
          contentChars == other.contentChars &&
          segmentCount == other.segmentCount &&
          steerState == other.steerState &&
          answered == other.answered &&
          revision == other.revision;

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    senderId,
    senderType,
    messageType,
    contentChars,
    segmentCount,
    steerState,
    answered,
    revision,
  );

  @override
  String toString() =>
      'ConversationOutlineEntry($id, ${messageType.name}, r$revision)';
}
