import 'package:cc_domain/features/chat_bridge/domain/entities/chat_space_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_link_method.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between the chat bridge's link entities and their Drift rows.
/// Stateless (`const`), like the other repo mappers.
///
/// A row whose `provider` this build does not know maps to null rather than
/// throwing: a database written by a newer version must degrade to "that link is
/// not mine to serve", not to a crash on every read.
class ChatLinkMapper {
  /// Creates a [ChatLinkMapper].
  const ChatLinkMapper();

  /// Domain space link → companion.
  ChatSpaceLinksTableCompanion spaceLinkToCompanion(ChatSpaceLink link) =>
      ChatSpaceLinksTableCompanion(
        id: Value(link.id),
        workspaceId: Value(link.workspaceId),
        provider: Value(link.provider.wire),
        externalTeamId: Value(link.externalTeamId),
        externalChannelId: Value(link.externalChannelId),
        externalThreadId: Value(link.externalThreadId),
        ccSpaceId: Value(link.ccSpaceId),
        createdByUserId: Value(link.createdByUserId),
        createdAt: Value(link.createdAt),
        lastActivityAt: Value(link.lastActivityAt),
      );

  /// Row → domain space link, or null when the row's provider is unknown.
  ChatSpaceLink? spaceLinkFromRow(ChatSpaceLinksTableData row) {
    final provider = ChatProvider.tryFromWire(row.provider);
    if (provider == null) {
      return null;
    }
    return ChatSpaceLink(
      id: row.id,
      workspaceId: row.workspaceId,
      provider: provider,
      externalTeamId: row.externalTeamId,
      externalChannelId: row.externalChannelId,
      externalThreadId: row.externalThreadId,
      ccSpaceId: row.ccSpaceId,
      createdByUserId: row.createdByUserId,
      createdAt: row.createdAt,
      lastActivityAt: row.lastActivityAt,
    );
  }

  /// Domain user link → companion.
  ChatUserLinksTableCompanion userLinkToCompanion(ChatUserLink link) =>
      ChatUserLinksTableCompanion(
        id: Value(link.id),
        workspaceId: Value(link.workspaceId),
        provider: Value(link.provider.wire),
        externalTeamId: Value(link.externalTeamId),
        externalUserId: Value(link.externalUserId),
        userId: Value(link.userId),
        method: Value(link.method.wire),
        linkedAt: Value(link.linkedAt),
      );

  /// Row → domain user link, or null when the row's provider is unknown.
  ChatUserLink? userLinkFromRow(ChatUserLinksTableData row) {
    final provider = ChatProvider.tryFromWire(row.provider);
    if (provider == null) {
      return null;
    }
    return ChatUserLink(
      id: row.id,
      workspaceId: row.workspaceId,
      provider: provider,
      externalTeamId: row.externalTeamId,
      externalUserId: row.externalUserId,
      userId: row.userId,
      method: ChatLinkMethod.fromWire(row.method),
      linkedAt: row.linkedAt,
    );
  }
}
