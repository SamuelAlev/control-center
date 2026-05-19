import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';

/// Maps one external chat conversation to one Control Center channel.
///
/// The external side is a `(provider, team, channel, thread)` tuple: a bot
/// `@mention` in a public channel anchors on that message's thread, while a DM
/// with the bot anchors on the conversation itself and carries a null
/// [externalThreadId].
///
/// Workspace-scoped. `(workspaceId, provider, externalChannelId,
/// externalThreadId)` is unique — one CC channel per external thread — and
/// [ccChannelId] is the reverse lookup the outbound relay uses to find where an
/// agent turn should stream.
class ChatChannelLink {
  /// Creates a [ChatChannelLink].
  ChatChannelLink({
    required this.id,
    required this.workspaceId,
    required this.provider,
    required this.externalTeamId,
    required this.externalChannelId,
    this.externalThreadId,
    required this.ccChannelId,
    this.createdByUserId,
    required this.createdAt,
    required this.lastActivityAt,
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
    if (externalChannelId.isEmpty) {
      throw ArgumentError.value(
        externalChannelId,
        'externalChannelId',
        'must not be empty',
      );
    }
    if (ccChannelId.isEmpty) {
      throw ArgumentError.value(
        ccChannelId,
        'ccChannelId',
        'must not be empty',
      );
    }
  }

  /// Unique row id (UUID v4).
  final String id;

  /// Workspace scope — the CC workspace that owns both sides of the link.
  final String workspaceId;

  /// Which chat product the external side lives on.
  final ChatProvider provider;

  /// Provider-side workspace/guild id (Slack `T024BE7LD`). May be empty for a
  /// provider with no such concept.
  final String externalTeamId;

  /// Provider-side conversation id (Slack channel `C…`, group `G…` or DM `D…`).
  final String externalChannelId;

  /// Provider-side thread anchor (Slack's thread-parent `ts`), or null when the
  /// whole conversation is the anchor (bot DMs).
  final String? externalThreadId;

  /// The Control Center channel this external thread drives.
  final String ccChannelId;

  /// The CC user whose message created the link, when known.
  final String? createdByUserId;

  /// When the link was created.
  final DateTime createdAt;

  /// Last time a message crossed the bridge in either direction. Drives
  /// retention: a long-idle thread's subscription can be dropped.
  final DateTime lastActivityAt;

  /// Returns a copy with the given fields replaced.
  ChatChannelLink copyWith({DateTime? lastActivityAt}) => ChatChannelLink(
    id: id,
    workspaceId: workspaceId,
    provider: provider,
    externalTeamId: externalTeamId,
    externalChannelId: externalChannelId,
    externalThreadId: externalThreadId,
    ccChannelId: ccChannelId,
    createdByUserId: createdByUserId,
    createdAt: createdAt,
    lastActivityAt: lastActivityAt ?? this.lastActivityAt,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatChannelLink &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          provider == other.provider &&
          externalTeamId == other.externalTeamId &&
          externalChannelId == other.externalChannelId &&
          externalThreadId == other.externalThreadId &&
          ccChannelId == other.ccChannelId &&
          createdByUserId == other.createdByUserId &&
          createdAt == other.createdAt &&
          lastActivityAt == other.lastActivityAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    provider,
    externalTeamId,
    externalChannelId,
    externalThreadId,
    ccChannelId,
    createdByUserId,
    createdAt,
    lastActivityAt,
  );
}
