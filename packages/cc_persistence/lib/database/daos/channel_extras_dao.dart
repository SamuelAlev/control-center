import 'package:cc_persistence/database/tables/channel_autonomy_table.dart';
import 'package:cc_persistence/database/tables/channel_notes_table.dart';
import 'package:cc_persistence/database/tables/message_reactions_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'channel_extras_dao.g.dart';

/// Data access for the collaboration extras on channels (PRD 16): the shared
/// Notes doc (§11), the per-channel agent autonomy dial (§12) and message
/// reactions (§15).
///
/// Every read is workspace-scoped (isolation invariant): an id-only lookup is
/// not a scoping boundary, so each query filters on `workspaceId` — a foreign
/// row is simply not found.
@DriftAccessor(
  tables: [ChannelNotesTable, ChannelAutonomyTable, MessageReactionsTable],
)
class ChannelExtrasDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$ChannelExtrasDaoMixin {
  /// Creates a [ChannelExtrasDao] for the given database.
  ChannelExtrasDao(super.attachedDatabase);

  // ── Channel notes ──

  /// The channel's Notes doc, or null when none exists yet.
  Future<ChannelNotesTableData?> noteForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(channelNotesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId),
          ))
          .getSingleOrNull();

  /// Watches the channel's Notes doc.
  Stream<ChannelNotesTableData?> watchNoteForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(channelNotesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId),
          ))
          .watchSingleOrNull();

  /// Upserts the channel's Notes doc, bumping [ChannelNotesTable.version].
  /// Last writer wins in server receipt order — the caller does NOT pass an
  /// expected version (PRD 16's per-field LWW; the whole doc is one column).
  Future<ChannelNotesTableData> upsertNote({
    required String id,
    required String workspaceId,
    required String channelId,
    required String contentMarkdown,
    required String updatedByPrincipal,
  }) async {
    final existing = await noteForChannel(workspaceId, channelId);
    if (existing == null) {
      final row = ChannelNotesTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        channelId: channelId,
        contentMarkdown: Value(contentMarkdown),
        updatedByPrincipal: updatedByPrincipal,
      );
      await into(channelNotesTable).insert(row);
      return (await noteForChannel(workspaceId, channelId))!;
    }
    await (update(channelNotesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.id.equals(existing.id),
        ))
        .write(
          ChannelNotesTableCompanion(
            contentMarkdown: Value(contentMarkdown),
            updatedByPrincipal: Value(updatedByPrincipal),
            updatedAt: Value(DateTime.now()),
            version: Value(existing.version + 1),
          ),
        );
    return (await noteForChannel(workspaceId, channelId))!;
  }

  // ── Per-channel agent autonomy ──

  /// Every autonomy dial set in [channelId].
  Future<List<ChannelAutonomyTableData>> autonomyForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(channelAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId),
          ))
          .get();

  /// Watches the autonomy dials of [channelId].
  Stream<List<ChannelAutonomyTableData>> watchAutonomyForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(channelAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId),
          ))
          .watch();

  /// One agent's dial in one channel, or null (callers fall back to the
  /// default autonomy).
  Future<ChannelAutonomyTableData?> autonomyFor(
    String workspaceId,
    String channelId,
    String agentId,
  ) =>
      (select(channelAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId) &
                t.agentId.equals(agentId),
          ))
          .getSingleOrNull();

  /// Sets (or clears, with null) an agent's autonomy in a channel.
  Future<void> setAutonomy({
    required String id,
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String? autonomyLevel,
  }) async {
    if (autonomyLevel == null) {
      await (delete(channelAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId) &
                t.agentId.equals(agentId),
          ))
          .go();
      return;
    }
    await into(channelAutonomyTable).insert(
      ChannelAutonomyTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        channelId: channelId,
        agentId: agentId,
        autonomyLevel: autonomyLevel,
      ),
      onConflict: DoUpdate(
        (old) => ChannelAutonomyTableCompanion(
          autonomyLevel: Value(autonomyLevel),
          updatedAt: Value(DateTime.now()),
        ),
        target: [
          channelAutonomyTable.workspaceId,
          channelAutonomyTable.channelId,
          channelAutonomyTable.agentId,
        ],
      ),
    );
  }

  // ── Message reactions ──

  /// Watches every reaction in [channelId].
  Stream<List<MessageReactionsTableData>> watchReactionsForChannel(
    String workspaceId,
    String channelId,
  ) =>
      (select(messageReactionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.channelId.equals(channelId),
          ))
          .watch();

  /// Toggles a principal's [emoji] reaction on a message. Returns true when
  /// the reaction now exists, false when the toggle removed it.
  Future<bool> toggleReaction({
    required String id,
    required String workspaceId,
    required String channelId,
    required String messageId,
    required String principalId,
    required String principalType,
    required String emoji,
  }) async {
    final removed =
        await (delete(messageReactionsTable)..where(
              (t) =>
                  t.workspaceId.equals(workspaceId) &
                  t.messageId.equals(messageId) &
                  t.principalId.equals(principalId) &
                  t.emoji.equals(emoji),
            ))
            .go();
    if (removed > 0) {
      return false;
    }
    await into(messageReactionsTable).insert(
      MessageReactionsTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        channelId: channelId,
        messageId: messageId,
        principalId: principalId,
        principalType: principalType,
        emoji: emoji,
      ),
    );
    return true;
  }
}
