import 'package:cc_domain/features/chat_bridge/domain/entities/chat_space_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/entities/chat_user_link.dart';
import 'package:cc_domain/features/chat_bridge/domain/repositories/chat_link_repositories.dart';
import 'package:cc_domain/features/chat_bridge/domain/value_objects/chat_provider.dart';
import 'package:cc_persistence/database/daos/chat_link_dao.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/chat_link_mappers.dart';

const _mapper = ChatLinkMapper();

/// Drift-backed [ChatSpaceLinkRepository].
///
/// Links are workspace-scoped rows in the workspace's own database file; the
/// `workspaceId` on each method (or on the entity being written) picks the file.
/// The manager is held rather than a resolved DAO — a cached DAO would pin the
/// first workspace it saw.
class DaoChatSpaceLinkRepository implements ChatSpaceLinkRepository {
  /// Creates a [DaoChatSpaceLinkRepository] over the per-workspace databases.
  DaoChatSpaceLinkRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ChatLinkDao _dao(String workspaceId) => _dbs.of(workspaceId).chatLinkDao;

  @override
  Future<void> upsert(ChatSpaceLink link) => _dao(
    link.workspaceId,
  ).upsertSpaceLink(_mapper.spaceLinkToCompanion(link));

  @override
  Future<ChatSpaceLink?> forExternalThread(
    String workspaceId, {
    required ChatProvider provider,
    required String externalChannelId,
    String? externalThreadId,
  }) async {
    final row = await _dao(workspaceId).spaceLinkForThread(
      workspaceId,
      provider: provider.wire,
      externalChannelId: externalChannelId,
      externalThreadId: externalThreadId,
    );
    return row == null ? null : _mapper.spaceLinkFromRow(row);
  }

  @override
  Future<ChatSpaceLink?> forCcSpace(
    String workspaceId,
    String ccSpaceId,
  ) async {
    final row = await _dao(
      workspaceId,
    ).spaceLinkForCcSpace(workspaceId, ccSpaceId);
    return row == null ? null : _mapper.spaceLinkFromRow(row);
  }

  @override
  Future<List<ChatSpaceLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).spaceLinksForWorkspace(workspaceId, provider: provider?.wire);
    return rows
        .map(_mapper.spaceLinkFromRow)
        .whereType<ChatSpaceLink>()
        .toList();
  }

  @override
  Future<int> delete(String id, {required String workspaceId}) =>
      _dao(workspaceId).deleteSpaceLink(id, workspaceId);
}

/// Drift-backed [ChatUserLinkRepository].
class DaoChatUserLinkRepository implements ChatUserLinkRepository {
  /// Creates a [DaoChatUserLinkRepository] over the per-workspace databases.
  DaoChatUserLinkRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  ChatLinkDao _dao(String workspaceId) => _dbs.of(workspaceId).chatLinkDao;

  @override
  Future<void> upsert(ChatUserLink link) =>
      _dao(link.workspaceId).upsertUserLink(_mapper.userLinkToCompanion(link));

  @override
  Future<ChatUserLink?> forExternalUser(
    String workspaceId, {
    required ChatProvider provider,
    required String externalTeamId,
    required String externalUserId,
  }) async {
    final row = await _dao(workspaceId).userLinkForExternalUser(
      workspaceId,
      provider: provider.wire,
      externalTeamId: externalTeamId,
      externalUserId: externalUserId,
    );
    return row == null ? null : _mapper.userLinkFromRow(row);
  }

  @override
  Future<ChatUserLink?> forUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) async {
    final row = await _dao(
      workspaceId,
    ).userLinkForUser(workspaceId, userId, provider: provider.wire);
    return row == null ? null : _mapper.userLinkFromRow(row);
  }

  @override
  Future<List<ChatUserLink>> forWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).userLinksForWorkspace(workspaceId, provider: provider?.wire);
    return rows.map(_mapper.userLinkFromRow).whereType<ChatUserLink>().toList();
  }

  @override
  Stream<List<ChatUserLink>> watchForWorkspace(
    String workspaceId, {
    ChatProvider? provider,
  }) => _dao(workspaceId)
      .watchUserLinksForWorkspace(workspaceId, provider: provider?.wire)
      .map(
        (rows) =>
            rows.map(_mapper.userLinkFromRow).whereType<ChatUserLink>().toList(),
      );

  @override
  Future<int> deleteForUser(
    String workspaceId,
    String userId, {
    required ChatProvider provider,
  }) => _dao(
    workspaceId,
  ).deleteUserLinkForUser(workspaceId, userId, provider: provider.wire);
}
