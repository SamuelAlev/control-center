import 'package:collection/collection.dart';
import 'package:control_center/core/domain/value_objects/message_attachment.dart';
import 'package:control_center/core/domain/value_objects/thinking_event.dart';

/// A resolved mention stored on a message's metadata.
class MessageMention {

  factory MessageMention.fromJson(Map<String, dynamic> json) => MessageMention(
    agentId: json['agentId'] as String,
    raw: json['raw'] as String,
    resolvedVia: json['resolvedVia'] as String?,
  );
  const MessageMention({
    required this.agentId,
    required this.raw,
    this.resolvedVia,
  });

  final String agentId;
  final String raw;
  final String? resolvedVia;

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
  /// Agent thinking message.
  thinking,
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
  /// Whether this is a thinking message.
  bool get isThinking => messageType == ChannelMessageType.thinking;
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
  /// Whether this question has already been answered by the user.
  bool get isQuestionAnswered => metadata?['answered'] == true;
  /// Plan lifecycle status: 'pending', 'approved', or 'refining'.
  String get planStatus => metadata?['planStatus'] as String? ?? 'pending';
  /// Whether this message is a thread reply.
  bool get isThreadReply => parentMessageId != null;
  /// Whether the streaming is complete.
  bool get isStreamingComplete => metadata?['streamComplete'] == true;

  /// Structured thinking transcript decoded from `metadata['events']`.
  ///
  /// Returns an empty list when the message has no events. Used by
  /// `ThinkingTimeline` to render reasoning and tool calls as discrete rows.
  List<ThinkingEvent> get thinkingEvents {
    final raw = metadata?['events'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final e in raw)
        if (e is Map) ThinkingEvent.fromJson(e.cast<String, dynamic>()),
    ];
  }

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
