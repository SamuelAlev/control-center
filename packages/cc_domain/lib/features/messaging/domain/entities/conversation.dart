import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';

/// A conversation (stream) inside a messaging channel.
///
/// A channel owns the worktree, participants, autonomy, takeover and
/// provisioning; a [Conversation] owns a stream of messages and the agent run
/// sessions bound to it. Every channel has exactly one [ConversationKind.main]
/// conversation; users open additional [ConversationKind.parenthesis]
/// conversations to run parallel work against the same worktree without mixing
/// histories (an agent run in a parenthesis only ever sees that parenthesis's
/// messages).
class Conversation {
  /// Creates a [Conversation].
  Conversation({
    required this.id,
    required this.workspaceId,
    required this.channelId,
    required this.title,
    this.kind = ConversationKind.main,
    this.status = ConversationStatus.active,
    this.createdByPrincipalId,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('Conversation id must not be empty');
    }
    if (channelId.isEmpty) {
      throw ArgumentError('Conversation channelId must not be empty');
    }
  }

  /// Unique identifier. For the `main` conversation this equals the channel id.
  final String id;

  /// Owning workspace (isolation scope). Nullable to mirror the channel — some
  /// system/legacy channels carry a null workspace.
  final String? workspaceId;

  /// The channel this conversation lives inside.
  final String channelId;

  /// Human-readable title (e.g. "Main", or a parenthesis label). Sentence case.
  final String title;

  /// Whether this is the channel's [ConversationKind.main] stream or a
  /// [ConversationKind.parenthesis].
  final ConversationKind kind;

  /// Lifecycle status (active / archived).
  final ConversationStatus status;

  /// Principal that opened this conversation, when known.
  final String? createdByPrincipalId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Whether this is the channel's primary conversation.
  bool get isMain => kind.isMain;

  /// Whether this is a parenthesis (side conversation).
  bool get isParenthesis => kind.isParenthesis;

  /// Whether the conversation is archived (closed).
  bool get isArchived => status.isArchived;

  /// Returns a copy with optional overrides.
  Conversation copyWith({
    String? id,
    String? workspaceId,
    String? channelId,
    String? title,
    ConversationKind? kind,
    ConversationStatus? status,
    String? createdByPrincipalId,
    bool removeCreatedByPrincipalId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      channelId: channelId ?? this.channelId,
      title: title ?? this.title,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      createdByPrincipalId: removeCreatedByPrincipalId
          ? null
          : (createdByPrincipalId ?? this.createdByPrincipalId),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Conversation &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          channelId == other.channelId &&
          title == other.title &&
          kind == other.kind &&
          status == other.status &&
          createdByPrincipalId == other.createdByPrincipalId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    channelId,
    title,
    kind,
    status,
    createdByPrincipalId,
    createdAt,
    updatedAt,
  );
}
