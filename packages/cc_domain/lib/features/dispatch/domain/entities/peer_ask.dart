import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';

/// One agent asking another for an answer, a consultation or a review
/// (`peer_asks`), written before the recipient is dispatched.
///
/// The row is what makes a background ask safe: depth and cycles are checked
/// against the [chain]s of pending asks, a repeat of the same question
/// ([questionHash]) to the same recipient is refused, and the answer comes
/// back to the asker as a wake exactly once (`PeerAskRepository.settle` is a
/// conditional update from pending), never when the blocking call already
/// returned it ([replyInline]).
class PeerAsk {
  /// Creates an ask, with every time in UTC. Throws [ArgumentError] for an
  /// empty id, agent, conversation, space or question hash, an over-long
  /// [error] or [chain], an asker that is its own recipient, or an
  /// [expiresAt] not after [createdAt].
  PeerAsk({
    required this.id,
    required this.workspaceId,
    this.kind = PeerAskKind.ask,
    this.mode = PeerAskMode.wait,
    required this.askerAgentId,
    this.askerRunId,
    required this.askerConversationId,
    required this.askerSpaceId,
    required this.recipientAgentId,
    this.recipientConversationId,
    this.recipientSpaceId,
    this.questionMessageId,
    required this.questionHash,
    this.dispatchedRunId,
    List<String> chain = const [],
    this.status = PeerAskStatus.pending,
    this.replyMessageId,
    this.replyInline = false,
    this.error,
    this.requestedByUserId,
    required DateTime createdAt,
    required DateTime expiresAt,
    DateTime? settledAt,
    DateTime? promisedAt,
    DateTime? blockedNoticedAt,
    this.stallNoticedRunId,
  }) : chain = List.unmodifiable(chain),
       // Every time is UTC, whatever the caller (or the database, which
       // reads back local times) handed in.
       createdAt = createdAt.toUtc(),
       expiresAt = expiresAt.toUtc(),
       settledAt = settledAt?.toUtc(),
       promisedAt = promisedAt?.toUtc(),
       blockedNoticedAt = blockedNoticedAt?.toUtc() {
    for (final (value, name) in [
      (id, 'id'),
      (workspaceId, 'workspaceId'),
      (askerAgentId, 'askerAgentId'),
      (askerConversationId, 'askerConversationId'),
      (askerSpaceId, 'askerSpaceId'),
      (recipientAgentId, 'recipientAgentId'),
      (questionHash, 'questionHash'),
    ]) {
      if (value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
    if (askerAgentId == recipientAgentId) {
      throw ArgumentError.value(
        recipientAgentId,
        'recipientAgentId',
        'an agent does not ask itself',
      );
    }
    final failure = error;
    if (failure != null && failure.length > maxErrorLength) {
      throw ArgumentError.value(
        failure.length,
        'error',
        'must be at most $maxErrorLength characters',
      );
    }
    if (chain.length > maxChainLength || chain.any((a) => a.isEmpty)) {
      throw ArgumentError.value(
        chain,
        'chain',
        'at most $maxChainLength non-empty agent ids',
      );
    }
    if (stallNoticedRunId != null && stallNoticedRunId!.isEmpty) {
      throw ArgumentError.value(
        stallNoticedRunId,
        'stallNoticedRunId',
        'must not be empty',
      );
    }
    if (!expiresAt.isAfter(createdAt)) {
      throw ArgumentError.value(
        expiresAt,
        'expiresAt',
        'must be after createdAt',
      );
    }
  }

  /// The longest [error], in characters.
  static const int maxErrorLength = 2000;

  /// The most agent ids a [chain] holds (depth itself is the service's rule).
  static const int maxChainLength = 16;

  /// Unique ask id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// What was asked for.
  final PeerAskKind kind;

  /// Whether the asking call waited.
  final PeerAskMode mode;

  /// The asking agent.
  final String askerAgentId;

  /// The asking agent's run.
  final String? askerRunId;

  /// The conversation the asker asked from; the reply wake goes here.
  final String askerConversationId;

  /// That conversation's space.
  final String askerSpaceId;

  /// The agent asked.
  final String recipientAgentId;

  /// The conversation the recipient answers in, once known.
  final String? recipientConversationId;

  /// That conversation's space, once known.
  final String? recipientSpaceId;

  /// The question's message id.
  final String? questionMessageId;

  /// A hash of the question text: the same question from the same sender to
  /// the same recipient within 10 minutes is refused.
  final String questionHash;

  /// The recipient's run that answers.
  final String? dispatchedRunId;

  /// The agents that led to this ask, oldest first, the asker last.
  final List<String> chain;

  /// Where it is.
  final PeerAskStatus status;

  /// The recipient's final message (the answer).
  final String? replyMessageId;

  /// Whether the blocking call already returned the reply, so no wake is
  /// owed.
  final bool replyInline;

  /// Why it failed.
  final String? error;

  /// The accountable person, or null for the bot.
  final String? requestedByUserId;

  /// When it was written.
  final DateTime createdAt;

  /// When it expires if nothing came back (24 hours after [createdAt]).
  final DateTime expiresAt;

  /// When it settled.
  final DateTime? settledAt;

  /// When the recipient ended a run without the answer but with a wake set
  /// to come back to it (the asker was told an answer is promised). Set at
  /// most once per ask.
  final DateTime? promisedAt;

  /// When the asker was told that the recipient waits on a person. Set at
  /// most once per ask.
  final DateTime? blockedNoticedAt;

  /// The recipient's run that was reminded, before it stopped, that somebody
  /// waits for its answer. Set at most once per ask.
  final String? stallNoticedRunId;

  /// Whether it still waits for the recipient.
  bool get isPending => status == PeerAskStatus.pending;

  /// Whether it is past its expiry at [now].
  bool expiredAt(DateTime now) => !now.isBefore(expiresAt);

  /// A copy with the given fields replaced.
  PeerAsk copyWith({
    String? id,
    String? workspaceId,
    PeerAskKind? kind,
    PeerAskMode? mode,
    String? askerAgentId,
    String? askerRunId,
    String? askerConversationId,
    String? askerSpaceId,
    String? recipientAgentId,
    String? recipientConversationId,
    String? recipientSpaceId,
    String? questionMessageId,
    String? questionHash,
    String? dispatchedRunId,
    List<String>? chain,
    PeerAskStatus? status,
    String? replyMessageId,
    bool removeReplyMessageId = false,
    bool? replyInline,
    String? error,
    bool removeError = false,
    String? requestedByUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? settledAt,
    bool removeSettledAt = false,
    DateTime? promisedAt,
    bool removePromisedAt = false,
    DateTime? blockedNoticedAt,
    bool removeBlockedNoticedAt = false,
    String? stallNoticedRunId,
    bool removeStallNoticedRunId = false,
  }) => PeerAsk(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    kind: kind ?? this.kind,
    mode: mode ?? this.mode,
    askerAgentId: askerAgentId ?? this.askerAgentId,
    askerRunId: askerRunId ?? this.askerRunId,
    askerConversationId: askerConversationId ?? this.askerConversationId,
    askerSpaceId: askerSpaceId ?? this.askerSpaceId,
    recipientAgentId: recipientAgentId ?? this.recipientAgentId,
    recipientConversationId:
        recipientConversationId ?? this.recipientConversationId,
    recipientSpaceId: recipientSpaceId ?? this.recipientSpaceId,
    questionMessageId: questionMessageId ?? this.questionMessageId,
    questionHash: questionHash ?? this.questionHash,
    dispatchedRunId: dispatchedRunId ?? this.dispatchedRunId,
    chain: chain ?? this.chain,
    status: status ?? this.status,
    replyMessageId: removeReplyMessageId
        ? null
        : (replyMessageId ?? this.replyMessageId),
    replyInline: replyInline ?? this.replyInline,
    error: removeError ? null : (error ?? this.error),
    requestedByUserId: requestedByUserId ?? this.requestedByUserId,
    createdAt: createdAt ?? this.createdAt,
    expiresAt: expiresAt ?? this.expiresAt,
    settledAt: removeSettledAt ? null : (settledAt ?? this.settledAt),
    promisedAt: removePromisedAt ? null : (promisedAt ?? this.promisedAt),
    blockedNoticedAt: removeBlockedNoticedAt
        ? null
        : (blockedNoticedAt ?? this.blockedNoticedAt),
    stallNoticedRunId: removeStallNoticedRunId
        ? null
        : (stallNoticedRunId ?? this.stallNoticedRunId),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PeerAsk &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          kind == other.kind &&
          mode == other.mode &&
          askerAgentId == other.askerAgentId &&
          askerRunId == other.askerRunId &&
          askerConversationId == other.askerConversationId &&
          askerSpaceId == other.askerSpaceId &&
          recipientAgentId == other.recipientAgentId &&
          recipientConversationId == other.recipientConversationId &&
          recipientSpaceId == other.recipientSpaceId &&
          questionMessageId == other.questionMessageId &&
          questionHash == other.questionHash &&
          dispatchedRunId == other.dispatchedRunId &&
          _sameList(chain, other.chain) &&
          status == other.status &&
          replyMessageId == other.replyMessageId &&
          replyInline == other.replyInline &&
          error == other.error &&
          requestedByUserId == other.requestedByUserId &&
          _sameInstant(createdAt, other.createdAt) &&
          _sameInstant(expiresAt, other.expiresAt) &&
          _sameInstant(settledAt, other.settledAt) &&
          _sameInstant(promisedAt, other.promisedAt) &&
          _sameInstant(blockedNoticedAt, other.blockedNoticedAt) &&
          stallNoticedRunId == other.stallNoticedRunId;

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    kind,
    mode,
    askerAgentId,
    askerRunId,
    askerConversationId,
    askerSpaceId,
    recipientAgentId,
    recipientConversationId,
    recipientSpaceId,
    questionMessageId,
    questionHash,
    dispatchedRunId,
    Object.hashAll(chain),
    status,
    replyMessageId,
    replyInline,
    error,
    requestedByUserId,
    createdAt.microsecondsSinceEpoch,
    expiresAt.microsecondsSinceEpoch,
    settledAt?.microsecondsSinceEpoch,
    promisedAt?.microsecondsSinceEpoch,
    blockedNoticedAt?.microsecondsSinceEpoch,
    stallNoticedRunId,
  ]);

  @override
  String toString() =>
      'PeerAsk($id, ${kind.wire} $askerAgentId -> $recipientAgentId, '
      '${status.wire})';
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

bool _sameInstant(DateTime? a, DateTime? b) =>
    a == null ? b == null : b != null && a.isAtSameMomentAs(b);
