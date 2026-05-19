import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';

/// A conversation (message stream) inside a space.
///
/// A space owns the worktree, participants, autonomy, takeover and
/// provisioning; a [Conversation] owns a stream of messages and the agent run
/// sessions bound to it. Conversations in a space are flat equals — there is
/// no primary stream. A conversation whose [anchorMessageId] is set is a
/// **thread**: it is anchored to one message of a sibling conversation in the
/// same space, starts with a fresh agent context seeded by that message, and
/// threads never nest ([isThread]).
class Conversation {
  /// Creates a [Conversation].
  Conversation({
    required this.id,
    required this.workspaceId,
    required this.spaceId,
    required this.title,
    this.status = ConversationStatus.active,
    this.anchorMessageId,
    this.createdByPrincipalId,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError('Conversation id must not be empty');
    }
    if (spaceId.isEmpty) {
      throw ArgumentError('Conversation spaceId must not be empty');
    }
  }

  /// Unique identifier. Always its own uuid — there is no main-conversation
  /// aliasing to the space id.
  final String id;

  /// Owning workspace (isolation scope). Nullable to mirror the space — some
  /// system/legacy spaces carry a null workspace.
  final String? workspaceId;

  /// The space this conversation lives inside.
  final String spaceId;

  /// Human-readable title. Sentence case.
  final String title;

  /// Lifecycle status (active / archived).
  final ConversationStatus status;

  /// Id of the message this conversation is anchored to, when it is a thread.
  /// Non-null ⇒ [isThread]; the anchor lives in a sibling conversation of the
  /// same space and seeds the thread's fresh agent context.
  final String? anchorMessageId;

  /// Principal that opened this conversation, when known.
  final String? createdByPrincipalId;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Whether this conversation is a thread anchored to a sibling message.
  /// One level deep: threads never anchor to threads.
  bool get isThread => anchorMessageId != null;

  /// Whether the conversation is archived (closed).
  bool get isArchived => status.isArchived;

  /// Returns a copy with optional overrides.
  Conversation copyWith({
    String? id,
    String? workspaceId,
    String? spaceId,
    String? title,
    ConversationStatus? status,
    String? anchorMessageId,
    bool removeAnchorMessageId = false,
    String? createdByPrincipalId,
    bool removeCreatedByPrincipalId = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Conversation(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      spaceId: spaceId ?? this.spaceId,
      title: title ?? this.title,
      status: status ?? this.status,
      anchorMessageId: removeAnchorMessageId
          ? null
          : (anchorMessageId ?? this.anchorMessageId),
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
          spaceId == other.spaceId &&
          title == other.title &&
          status == other.status &&
          anchorMessageId == other.anchorMessageId &&
          createdByPrincipalId == other.createdByPrincipalId &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    spaceId,
    title,
    status,
    anchorMessageId,
    createdByPrincipalId,
    createdAt,
    updatedAt,
  );
}
