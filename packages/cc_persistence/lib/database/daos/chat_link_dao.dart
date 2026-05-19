import 'package:cc_persistence/database/tables/chat_links_tables.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'chat_link_dao.g.dart';

/// Data access for the chat bridge's two link tables: external conversation ↔ CC
/// channel, and external member ↔ CC user.
///
/// Every read is workspace-scoped *and* provider-scoped: the workspace picks the
/// database file, the provider keeps two bridged products from resolving each
/// other's rows.
@DriftAccessor(tables: [ChatChannelLinksTable, ChatUserLinksTable])
class ChatLinkDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ChatLinkDaoMixin {
  /// Creates a [ChatLinkDao].
  ChatLinkDao(super.db);

  // ── channel links ──

  /// Inserts or updates a channel link, keyed on the external thread it bridges.
  ///
  /// The row is unique on `(workspace_id, provider, external_channel_id,
  /// external_thread_id)` as well as on its id, so writing a *new* id for a
  /// thread that is already bridged would violate the index rather than re-point
  /// it. Retargeting the thread is the intended outcome (its Control Center
  /// channel was deleted, or a fresh one is being opened), so the stale row for
  /// that thread goes first.
  Future<void> upsertChannelLink(ChatChannelLinksTableCompanion link) {
    final threadId = link.externalThreadId.present
        ? link.externalThreadId.value
        : null;
    return transaction(() async {
      await (delete(chatChannelLinksTable)..where(
            (t) =>
                t.workspaceId.equals(link.workspaceId.value) &
                t.provider.equals(link.provider.value) &
                t.externalChannelId.equals(link.externalChannelId.value) &
                (threadId == null
                    ? t.externalThreadId.isNull()
                    : t.externalThreadId.equals(threadId)) &
                t.id.equals(link.id.value).not(),
          ))
          .go();
      await into(chatChannelLinksTable).insertOnConflictUpdate(link);
    });
  }

  /// The link anchored on `(provider, externalChannelId, externalThreadId)`, or
  /// null.
  Future<ChatChannelLinksTableData?> channelLinkForThread(
    String workspaceId, {
    required String provider,
    required String externalChannelId,
    String? externalThreadId,
  }) {
    final query = select(chatChannelLinksTable)
      ..where(
        (t) =>
            t.workspaceId.equals(workspaceId) &
            t.provider.equals(provider) &
            t.externalChannelId.equals(externalChannelId) &
            (externalThreadId == null
                ? t.externalThreadId.isNull()
                : t.externalThreadId.equals(externalThreadId)),
      )
      ..limit(1);
    return query.getSingleOrNull();
  }

  /// The link whose CC channel is [ccChannelId], or null.
  ///
  /// Deliberately not provider-scoped: a CC channel is bridged to at most one
  /// external thread, and the caller's job is to notice which provider answered.
  Future<ChatChannelLinksTableData?> channelLinkForCcChannel(
    String workspaceId,
    String ccChannelId,
  ) =>
      (select(chatChannelLinksTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.ccChannelId.equals(ccChannelId),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Every channel link in the workspace, optionally narrowed to one provider.
  Future<List<ChatChannelLinksTableData>> channelLinksForWorkspace(
    String workspaceId, {
    String? provider,
  }) =>
      (select(chatChannelLinksTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                (provider == null
                    ? const Constant(true)
                    : t.provider.equals(provider)),
          ))
          .get();

  /// Deletes a channel link scoped to [workspaceId]. Returns rows deleted.
  Future<int> deleteChannelLink(String id, String workspaceId) =>
      (delete(chatChannelLinksTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();

  // ── user links ──

  /// Inserts or updates a user link, keyed on both sides of the mapping.
  ///
  /// Attribution has to stay single-valued in both directions *within a
  /// provider*: one Control Center user per external member, and one external
  /// member per Control Center user. Both are unique indexes, so re-linking
  /// either side (a corrected link, somebody moving to a new account) drops the
  /// row it supersedes instead of failing the write. A link on another provider
  /// is untouched.
  Future<void> upsertUserLink(ChatUserLinksTableCompanion link) =>
      transaction(() async {
        await (delete(chatUserLinksTable)..where(
              (t) =>
                  t.workspaceId.equals(link.workspaceId.value) &
                  t.provider.equals(link.provider.value) &
                  (t.userId.equals(link.userId.value) |
                      (t.externalTeamId.equals(link.externalTeamId.value) &
                          t.externalUserId.equals(link.externalUserId.value))) &
                  t.id.equals(link.id.value).not(),
            ))
            .go();
        await into(chatUserLinksTable).insertOnConflictUpdate(link);
      });

  /// The link for an external member, or null.
  Future<ChatUserLinksTableData?> userLinkForExternalUser(
    String workspaceId, {
    required String provider,
    required String externalTeamId,
    required String externalUserId,
  }) =>
      (select(chatUserLinksTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.provider.equals(provider) &
                  t.externalTeamId.equals(externalTeamId) &
                  t.externalUserId.equals(externalUserId),
            )
            ..limit(1))
          .getSingleOrNull();

  /// The link for a CC user on [provider], or null.
  Future<ChatUserLinksTableData?> userLinkForUser(
    String workspaceId,
    String userId, {
    required String provider,
  }) =>
      (select(chatUserLinksTable)
            ..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.provider.equals(provider) &
                  t.userId.equals(userId),
            )
            ..limit(1))
          .getSingleOrNull();

  /// Every user link in the workspace (oldest first), optionally narrowed to one
  /// provider.
  Future<List<ChatUserLinksTableData>> userLinksForWorkspace(
    String workspaceId, {
    String? provider,
  }) => _userLinksQuery(workspaceId, provider).get();

  /// Watches every user link in the workspace, optionally narrowed to one
  /// provider.
  Stream<List<ChatUserLinksTableData>> watchUserLinksForWorkspace(
    String workspaceId, {
    String? provider,
  }) => _userLinksQuery(workspaceId, provider).watch();

  /// Removes a CC user's link on [provider]. Returns rows deleted.
  Future<int> deleteUserLinkForUser(
    String workspaceId,
    String userId, {
    required String provider,
  }) =>
      (delete(chatUserLinksTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.provider.equals(provider) &
                t.userId.equals(userId),
          ))
          .go();

  SimpleSelectStatement<$ChatUserLinksTableTable, ChatUserLinksTableData>
  _userLinksQuery(String workspaceId, String? provider) =>
      select(chatUserLinksTable)
        ..where(
          (t) =>
              t.workspaceId.equals(workspaceId) &
              (provider == null
                  ? const Constant(true)
                  : t.provider.equals(provider)),
        )
        ..orderBy([(t) => OrderingTerm.asc(t.linkedAt)]);
}
