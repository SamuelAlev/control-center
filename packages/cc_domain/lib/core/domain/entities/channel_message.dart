import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/message_attachment.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:collection/collection.dart';

/// A resolved mention stored on a message's metadata.
///
/// PRD 16 §15: `@mentions` resolve to **principals** — humans as well as
/// agents. [principalType] distinguishes the two; [agentId] (kept for
/// backward compatibility with every persisted mention written before §15)
/// carries the mentioned principal's id either way — an agent id when
/// [principalType] is [PrincipalType.agent], a user id when it is
/// [PrincipalType.user]. Use [principalId] at call sites that read more
/// naturally that way.
class MessageMention {
  /// Creates a [MessageMention] from a JSON map. Tolerant of frames written
  /// before §15: a missing `principalType` defaults to [PrincipalType.agent],
  /// so every mention persisted so far decodes unchanged.
  factory MessageMention.fromJson(Map<String, dynamic> json) => MessageMention(
    agentId: json['agentId'] as String,
    raw: json['raw'] as String,
    resolvedVia: json['resolvedVia'] as String?,
    principalType:
        PrincipalType.fromWire(json['principalType'] as String?) ??
        PrincipalType.agent,
  );

  /// Creates a const [MessageMention].
  const MessageMention({
    required this.agentId,
    required this.raw,
    this.resolvedVia,
    this.principalType = PrincipalType.agent,
  });

  /// The id of the mentioned principal (an agent id, or — when
  /// [principalType] is [PrincipalType.user] — a human user id).
  final String agentId;

  /// Raw mention text from the message content.
  final String raw;

  /// How the mention was resolved, if recorded.
  final String? resolvedVia;

  /// Which kind of principal [agentId] names. Defaults to
  /// [PrincipalType.agent] so every mention persisted before PRD 16 §15
  /// (human mentions did not exist yet) decodes unchanged.
  final PrincipalType principalType;

  /// Alias for [agentId] that reads correctly at a human-mention call site.
  String get principalId => agentId;

  /// Serializes this mention to a JSON map. `principalType` is omitted when
  /// it is the default `agent` — every mention written before §15 round-trips
  /// byte-for-byte identical.
  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'raw': raw,
    if (resolvedVia != null) 'resolvedVia': resolvedVia,
    if (principalType != PrincipalType.agent)
      'principalType': principalType.wireName,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageMention &&
          agentId == other.agentId &&
          raw == other.raw &&
          resolvedVia == other.resolvedVia &&
          principalType == other.principalType;

  @override
  int get hashCode => Object.hash(agentId, raw, resolvedVia, principalType);
}

/// Rendering type of a channel message.

enum ChannelMessageType {
  /// Plain text message.
  text,

  /// System notification message.
  system,

  /// Ticket card message.
  ticketCard,

  /// A complete agent turn: an ordered transcript of reasoning, tool calls,
  /// and answer text, persisted under `metadata['segments']`.
  agentTurn,

  /// Structured review finding from an agent.
  reviewNode,

  /// Hire proposal awaiting user approval.
  hireProposal,

  /// Editorial summary of a finalized review.
  reviewSummary,

  /// Plan message from agent with action buttons.
  plan,

  /// A question an agent is asking the user, rendered as an interactive form.
  userQuestion,

  /// An orchestration proposal awaiting the user's one upfront approval; the
  /// bubble watches the orchestration row by id and renders its whole
  /// lifecycle (proposed → executing → completed).
  orchestrationProposal,

  /// A published artifact — an ordered list of typed blocks (markdown, table,
  /// chart, mermaid, code, data) stored as a WorkProduct. The bubble watches the
  /// work-product row by id (`metadata['workProductId']` /
  /// `metadata['revisionId']`), so revisions re-render in place instead of
  /// posting a second message.
  artifact,

  /// A first-class compaction summary that stands in for a span of older
  /// messages. Its [ChannelMessage.content] is the anchored summary text; the
  /// messages it replaced are marked `compacted = true` and kept (recoverable),
  /// while this message is what gets injected into future prompts in their
  /// place. See `metadata['tailStartId']`, `metadata['compactedIds']` and
  /// `metadata['compactionReason']`.
  compaction,
}

/// Who sent a channel message.
enum ChannelSenderType {
  /// Human user.
  user,

  /// AI agent.
  agent,
}

/// A lightweight per-response quality signal the user can attach to an agent
/// turn, persisted under `metadata['feedback']`. Feeds friction analytics.
enum MessageFeedback {
  /// The response was helpful (thumbs up).
  helpful,

  /// The response was not helpful (thumbs down).
  notHelpful;

  /// The wire value stored in metadata.
  String get wireName => name;

  /// Parses the stored wire value, or null when absent/unknown.
  static MessageFeedback? fromWire(Object? value) => switch (value) {
    'helpful' => MessageFeedback.helpful,
    'notHelpful' => MessageFeedback.notHelpful,
    _ => null,
  };
}

/// A message inside a messaging channel.
class ChannelMessage {
  /// Creates a new [ChannelMessage].
  ChannelMessage({
    required this.id,
    required this.channelId,
    required this.conversationId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    this.metadata,
    this.compacted = false,
    this.reverted = false,
    this.revertedAt,
    required this.createdAt,
  }) {
    if (channelId.isEmpty) {
      throw ArgumentError('ChannelMessage channelId must not be empty');
    }
    if (conversationId.isEmpty) {
      throw ArgumentError('ChannelMessage conversationId must not be empty');
    }
  }

  /// Unique identifier.
  final String id;

  /// Parent channel identifier.
  final String channelId;

  /// The conversation (stream) inside the channel this message belongs to.
  /// Every channel has a `main` conversation; users can open additional
  /// parallel conversations ("parentheses") that share the channel's worktree
  /// but keep their own message history and agent sessions.
  final String conversationId;

  /// Sender identifier.
  final String senderId;

  /// Sender type.
  final ChannelSenderType senderType;

  /// Message content.
  final String content;

  /// Message rendering type.
  final ChannelMessageType messageType;

  /// Optional metadata map.
  final Map<String, dynamic>? metadata;

  /// Whether this message has been compacted.
  final bool compacted;

  /// Whether this message has been reverted (rolled back) and is hidden from
  /// the live conversation until an unrevert restores it.
  final bool reverted;

  /// When this message was reverted (epoch ms), or null. Messages reverted in
  /// one operation share a timestamp so unrevert can restore the latest batch.
  final int? revertedAt;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Whether the sender is a human user.
  bool get isUser => senderType == ChannelSenderType.user;

  /// Whether this is a system message.
  bool get isSystem => messageType == ChannelMessageType.system;

  /// Whether this is a ticket card.
  bool get isTicket => messageType == ChannelMessageType.ticketCard;

  /// Whether this is a complete agent turn with a structured transcript.
  bool get isAgentTurn => messageType == ChannelMessageType.agentTurn;

  /// Whether this is a review node.
  bool get isReviewNode => messageType == ChannelMessageType.reviewNode;

  /// Whether this is a hire proposal awaiting approval.
  bool get isHireProposal => messageType == ChannelMessageType.hireProposal;

  /// Whether this is an editorial review summary.
  bool get isReviewSummary => messageType == ChannelMessageType.reviewSummary;

  /// Whether this is a plan message.
  bool get isPlan => messageType == ChannelMessageType.plan;

  /// Whether this is an agent question rendered as an interactive form.
  bool get isUserQuestion => messageType == ChannelMessageType.userQuestion;

  /// Whether this is an orchestration proposal card.
  bool get isOrchestrationProposal =>
      messageType == ChannelMessageType.orchestrationProposal;

  /// Whether this is a published artifact card.
  bool get isArtifact => messageType == ChannelMessageType.artifact;

  /// Whether this is a first-class compaction summary.
  bool get isCompaction => messageType == ChannelMessageType.compaction;

  /// Whether this message stands in for older context — either a first-class
  /// [ChannelMessageType.compaction] message or a legacy compacted system
  /// summary (`system` + `metadata['compacted'] == true`).
  bool get isContextSummary =>
      isCompaction || (isSystem && metadata?['compacted'] == true);

  /// For a compaction message, the id of the first message kept verbatim after
  /// the compacted span (the "tail start"), or null.
  String? get compactionTailStartId => metadata?['tailStartId'] as String?;

  /// For a compaction message, why it was produced: `'auto'` or `'manual'`.
  String get compactionReason =>
      metadata?['compactionReason'] as String? ?? 'auto';

  /// For a compaction message, the ids of the messages it replaced.
  List<String> get compactedIds {
    final raw = metadata?['compactedIds'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final e in raw)
        if (e is String) e,
    ];
  }

  /// Whether this question has already been answered by the user.
  bool get isQuestionAnswered => metadata?['answered'] == true;

  /// Plan lifecycle status: 'pending', 'approved', or 'refining'.
  String get planStatus => metadata?['planStatus'] as String? ?? 'pending';

  /// Whether this message has been reverted (rolled back) and is hidden from
  /// the live conversation until an unrevert restores it.
  bool get isReverted => reverted;

  /// Whether the streaming is complete.
  bool get isStreamingComplete => metadata?['streamComplete'] == true;

  /// Whether this message has been edited by the user (`metadata['editedAt']`).
  bool get isEdited => metadata?['editedAt'] != null;

  /// Whether this message has been soft-deleted (`metadata['deletedAt']`). A
  /// deleted message is kept (for audit/undo) but rendered as a placeholder.
  bool get isDeleted => metadata?['deletedAt'] != null;

  /// Returns this message's metadata with an `editedAt` stamp applied, leaving
  /// every other entry intact (copy-on-write, like [metadataWithFeedback]).
  Map<String, dynamic> metadataWithEdited({required int atEpochMs}) =>
      <String, dynamic>{...?metadata, 'editedAt': atEpochMs};

  /// Returns this message's metadata with a `deletedAt` stamp applied (marks a
  /// soft delete), leaving every other entry intact.
  Map<String, dynamic> metadataWithDeleted({required int atEpochMs}) =>
      <String, dynamic>{...?metadata, 'deletedAt': atEpochMs};

  /// The user's per-response feedback for this turn, or null when none.
  MessageFeedback? get feedback {
    final raw = metadata?['feedback'];
    if (raw is! Map) {
      return null;
    }
    return MessageFeedback.fromWire(raw['value']);
  }

  /// Returns this message's metadata with [feedback] applied — set under the
  /// `feedback` key, or removed when null — leaving every other entry intact.
  /// Pass the result to a metadata-replacing update so feedback never clobbers
  /// the transcript, snapshot, or turn metrics.
  Map<String, dynamic> metadataWithFeedback(
    MessageFeedback? feedback, {
    required int atEpochMs,
  }) {
    final next = <String, dynamic>{...?metadata};
    if (feedback == null) {
      next.remove('feedback');
    } else {
      next['feedback'] = {'value': feedback.wireName, 'at': atEpochMs};
    }
    return next;
  }

  /// Ordered transcript segments decoded from `metadata['segments']`.
  ///
  /// Returns an empty list when the message carries no transcript. Used by the
  /// transcript UI to render reasoning, tool calls and text in chronological
  /// order.
  ///
  /// Lazily decoded ONCE per entity instance (`late final`): the UI reads this
  /// on every rebuild and re-decoding a large transcript's JSON per frame was
  /// a measured hot path. Relies on `metadata` never being mutated in place
  /// after construction (the repo convention is copy-on-write — see
  /// [metadataWithFeedback]).
  late final List<TranscriptSegment> transcript = decodeTranscript(
    metadata?['segments'],
  );

  /// How the agent turn ended (`metadata['outcome']`); null while streaming.
  TurnOutcome? get turnOutcome =>
      turnOutcomeFromString(metadata?['outcome'] as String?);

  /// Wall-clock duration of the turn in milliseconds (`metadata['turn']['durationMs']`).
  int? get turnDurationMs => (_turnMeta?['durationMs'] as num?)?.toInt();

  /// Total tokens consumed by the turn (`metadata['turn']['totalTokens']`).
  int? get turnTotalTokens => (_turnMeta?['totalTokens'] as num?)?.toInt();

  /// Estimated cost of the turn in cents (`metadata['turn']['costCents']`).
  int? get turnCostCents => (_turnMeta?['costCents'] as num?)?.toInt();

  Map<String, dynamic>? get _turnMeta {
    final raw = metadata?['turn'];
    return raw is Map ? raw.cast<String, dynamic>() : null;
  }

  /// Mentions decoded from `metadata['mentions']`.
  List<MessageMention> get mentions {
    final raw = metadata?['mentions'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final m in raw)
        if (m is Map<String, dynamic>) MessageMention.fromJson(m),
    ];
  }

  /// Attachments decoded from `metadata['attachments']`.
  List<MessageAttachment> get attachments {
    final raw = metadata?['attachments'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final a in raw)
        if (a is Map<String, dynamic>) MessageAttachment.fromJson(a),
    ];
  }

  /// Entity references (`#ticket` / `#pr` / `#meeting`) decoded from
  /// `metadata['entityRefs']`. Rendered as live-resolving chips on the message.
  List<EntityRef> get entityRefs {
    final raw = metadata?['entityRefs'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final e in raw)
        if (e is Map<String, dynamic>) ?EntityRef.tryFromJson(e),
    ];
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          channelId == other.channelId &&
          conversationId == other.conversationId &&
          senderId == other.senderId &&
          senderType == other.senderType &&
          content == other.content &&
          messageType == other.messageType &&
          const DeepCollectionEquality().equals(metadata, other.metadata) &&
          compacted == other.compacted &&
          reverted == other.reverted &&
          revertedAt == other.revertedAt &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    conversationId,
    senderId,
    senderType,
    content,
    messageType,
    const DeepCollectionEquality().hash(metadata),
    compacted,
    reverted,
    revertedAt,
    createdAt,
  );

  /// Returns a copy with optional overrides.
  ChannelMessage copyWith({
    String? id,
    String? channelId,
    String? conversationId,
    String? senderId,
    ChannelSenderType? senderType,
    String? content,
    ChannelMessageType? messageType,
    Map<String, dynamic>? metadata,
    bool removeMetadata = false,
    bool? compacted,
    bool? reverted,
    int? revertedAt,
    bool removeRevertedAt = false,
    DateTime? createdAt,
  }) {
    return ChannelMessage(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: removeMetadata ? null : (metadata ?? this.metadata),
      compacted: compacted ?? this.compacted,
      reverted: reverted ?? this.reverted,
      revertedAt: removeRevertedAt ? null : (revertedAt ?? this.revertedAt),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
