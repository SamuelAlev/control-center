import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';

/// Maps one external chat member to one Control Center user inside one
/// workspace.
///
/// This is the bridge's identity resolution: a chat message is attributed to the
/// linked CC user, so rate limits, git co-author trailers, ticket reporters and
/// audit rows all name a real principal instead of the workspace owner.
///
/// A link is **not** an access grant. The bridge still checks workspace
/// membership on every inbound event — being linked to a user who was later
/// removed from the workspace resolves to a refusal, not access.
class ChatUserLink {
  /// Creates a [ChatUserLink].
  ChatUserLink({
    required this.id,
    required this.workspaceId,
    required this.provider,
    required this.externalTeamId,
    required this.externalUserId,
    required this.userId,
    required this.method,
    required this.linkedAt,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'must not be empty',
      );
    }
    if (externalUserId.isEmpty) {
      throw ArgumentError.value(
        externalUserId,
        'externalUserId',
        'must not be empty',
      );
    }
    if (userId.isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'must not be empty');
    }
  }

  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope.
  final String workspaceId;

  /// Which chat product the external identity lives on.
  final ChatProvider provider;

  /// Provider-side workspace/guild id. May be empty for a provider with no such
  /// concept.
  final String externalTeamId;

  /// Provider-side member id (Slack `U024BE7LH`).
  final String externalUserId;

  /// The Control Center user id.
  final String userId;

  /// How the link was established.
  final ChatLinkMethod method;

  /// When the link was established.
  final DateTime linkedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatUserLink &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          provider == other.provider &&
          externalTeamId == other.externalTeamId &&
          externalUserId == other.externalUserId &&
          userId == other.userId &&
          method == other.method &&
          linkedAt == other.linkedAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    provider,
    externalTeamId,
    externalUserId,
    userId,
    method,
    linkedAt,
  );
}
