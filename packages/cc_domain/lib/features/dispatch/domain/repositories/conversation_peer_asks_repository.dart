import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';

/// An ask an agent made from a conversation, as a person sees it there
/// (`peerAsks.*` ops): who asked whom, what kind and mode, where it stands,
/// and when. The question and the reply are messages, named by id.
class PeerAskView {
  /// Creates a view. Throws [ArgumentError] for an empty id or party.
  PeerAskView({
    required this.id,
    required this.workspaceId,
    required this.kind,
    required this.mode,
    required this.status,
    required this.askerAgentId,
    required this.askerConversationId,
    required this.recipientAgentId,
    required DateTime createdAt,
    required DateTime expiresAt,
    this.recipientConversationId,
    this.questionMessageId,
    this.replyMessageId,
    this.replyInline = false,
    this.error,
    DateTime? settledAt,
    DateTime? promisedAt,
    DateTime? blockedNoticedAt,
  }) : createdAt = createdAt.toUtc(),
       expiresAt = expiresAt.toUtc(),
       settledAt = settledAt?.toUtc(),
       promisedAt = promisedAt?.toUtc(),
       blockedNoticedAt = blockedNoticedAt?.toUtc() {
    for (final (name, value) in [
      ('id', id),
      ('workspaceId', workspaceId),
      ('askerAgentId', askerAgentId),
      ('askerConversationId', askerConversationId),
      ('recipientAgentId', recipientAgentId),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
  }

  /// The ask's id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// An ask, a consult or a review request.
  final PeerAskKind kind;

  /// Whether the asker blocked on it or went on.
  final PeerAskMode mode;

  /// Where it stands.
  final PeerAskStatus status;

  /// The agent that asked.
  final String askerAgentId;

  /// The conversation it asked from (where its answer wakes it).
  final String askerConversationId;

  /// The agent asked.
  final String recipientAgentId;

  /// The conversation the recipient answers in, once it has one.
  final String? recipientConversationId;

  /// The question's message.
  final String? questionMessageId;

  /// The answer's message, once answered.
  final String? replyMessageId;

  /// Whether the answer was returned inside the asker's blocking call.
  final bool replyInline;

  /// Why it failed, when it did.
  final String? error;

  /// When it was asked.
  final DateTime createdAt;

  /// When it expires unanswered.
  final DateTime expiresAt;

  /// When it settled.
  final DateTime? settledAt;

  /// When the recipient said it would answer later.
  final DateTime? promisedAt;

  /// When the recipient was seen waiting on a person.
  final DateTime? blockedNoticedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerAskView &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          kind == other.kind &&
          mode == other.mode &&
          status == other.status &&
          askerAgentId == other.askerAgentId &&
          askerConversationId == other.askerConversationId &&
          recipientAgentId == other.recipientAgentId &&
          recipientConversationId == other.recipientConversationId &&
          questionMessageId == other.questionMessageId &&
          replyMessageId == other.replyMessageId &&
          replyInline == other.replyInline &&
          error == other.error &&
          _sameInstant(createdAt, other.createdAt) &&
          _sameInstant(expiresAt, other.expiresAt) &&
          _sameInstant(settledAt, other.settledAt) &&
          _sameInstant(promisedAt, other.promisedAt) &&
          _sameInstant(blockedNoticedAt, other.blockedNoticedAt);

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    kind,
    mode,
    status,
    askerAgentId,
    askerConversationId,
    recipientAgentId,
    recipientConversationId,
    questionMessageId,
    replyMessageId,
    replyInline,
    error,
    createdAt.microsecondsSinceEpoch,
    expiresAt.microsecondsSinceEpoch,
    settledAt?.microsecondsSinceEpoch,
    promisedAt?.microsecondsSinceEpoch,
    blockedNoticedAt?.microsecondsSinceEpoch,
  );
}

bool _sameInstant(DateTime? a, DateTime? b) =>
    a == null ? b == null : b != null && a.isAtSameMomentAs(b);

/// A client's view of the asks agents made from a conversation and a
/// person's one control over them. Every call names its workspace; an ask or
/// conversation outside it is refused by the server.
abstract interface class ConversationPeerAsksRepository {
  /// The asks made from [conversationId], newest first.
  Stream<List<PeerAskView>> watchForConversation(
    String workspaceId,
    String conversationId,
  );

  /// Cancels a pending ask: the asker is not woken and the recipient's run
  /// goes on. False when it already settled.
  Future<bool> cancel(String workspaceId, String askId);
}
