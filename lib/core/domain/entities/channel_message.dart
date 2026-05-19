import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/message_attachment.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';

/// A resolved mention stored on a message's metadata.
class MessageMention {

  /// Creates a [MessageMention] from a JSON map.
  factory MessageMention.fromJson(Map<String, dynamic> json) => MessageMention(
    agentId: json['agentId'] as String,
    raw: json['raw'] as String,
    resolvedVia: json['resolvedVia'] as String?,
  );
  /// Creates a const [MessageMention].
  const MessageMention({
    required this.agentId,
    required this.raw,
    this.resolvedVia,
  });

  /// The id of the mentioned agent.
  final String agentId;
  /// Raw mention text from the message content.
  final String raw;
  /// How the mention was resolved, if recorded.
  final String? resolvedVia;

  /// Serializes this mention to a JSON map.
  Map<String, dynamic> toJson() => {
    'agentId': agentId,
    'raw': raw,
    if (resolvedVia != null) 'resolvedVia': resolvedVia,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MessageMention &&
          agentId == other.agentId &&
          raw == other.raw &&
          resolvedVia == other.resolvedVia;

  @override
  int get hashCode => Object.hash(agentId, raw, resolvedVia);
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
}

/// Who sent a channel message.
enum ChannelSenderType {
  /// Human user.
  user,
  /// AI agent.
  agent,
}

/// A message inside a messaging channel.
class ChannelMessage {
  /// Creates a new [ChannelMessage].
  ChannelMessage({
    required this.id,
    required this.channelId,
    required this.senderId,
    required this.senderType,
    required this.content,
    required this.messageType,
    this.metadata,
    this.parentMessageId,
    this.compacted = false,
    required this.createdAt,
  }) : assert(
         channelId.isNotEmpty,
         'ChannelMessage channelId must not be empty',
       );

  /// Unique identifier.
  final String id;
  /// Parent channel identifier.
  final String channelId;
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
  /// Parent message id when this is a thread reply.
  final String? parentMessageId;
  /// Whether this message has been compacted.
  final bool compacted;
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
  /// Whether this question has already been answered by the user.
  bool get isQuestionAnswered => metadata?['answered'] == true;
  /// Plan lifecycle status: 'pending', 'approved', or 'refining'.
  String get planStatus => metadata?['planStatus'] as String? ?? 'pending';
  /// Whether this message is a thread reply.
  bool get isThreadReply => parentMessageId != null;
  /// Whether the streaming is complete.
  bool get isStreamingComplete => metadata?['streamComplete'] == true;

  /// Ordered transcript segments decoded from `metadata['segments']`.
  ///
  /// Returns an empty list when the message carries no transcript. Used by the
  /// transcript UI to render reasoning, tool calls, and text in chronological
  /// order.
  List<TranscriptSegment> get transcript => decodeTranscript(metadata?['segments']);

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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          channelId == other.channelId &&
          senderId == other.senderId &&
          senderType == other.senderType &&
          content == other.content &&
          messageType == other.messageType &&
          const DeepCollectionEquality().equals(metadata, other.metadata) &&
          parentMessageId == other.parentMessageId &&
          compacted == other.compacted &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    channelId,
    senderId,
    senderType,
    content,
    messageType,
    const DeepCollectionEquality().hash(metadata),
    parentMessageId,
    compacted,
    createdAt,
  );

  /// Returns a copy with optional overrides.
  ChannelMessage copyWith({
    String? id,
    String? channelId,
    String? senderId,
    ChannelSenderType? senderType,
    String? content,
    ChannelMessageType? messageType,
    Map<String, dynamic>? metadata,
    bool removeMetadata = false,
    String? parentMessageId,
    bool removeParentMessageId = false,
    bool? compacted,
    DateTime? createdAt,
  }) {
    return ChannelMessage(
      id: id ?? this.id,
      channelId: channelId ?? this.channelId,
      senderId: senderId ?? this.senderId,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: removeMetadata ? null : (metadata ?? this.metadata),
      parentMessageId: removeParentMessageId
          ? null
          : (parentMessageId ?? this.parentMessageId),
      compacted: compacted ?? this.compacted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
