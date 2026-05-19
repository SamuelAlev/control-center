import 'package:cc_persistence/database/tables/message_reactions_table.dart';
import 'package:cc_persistence/database/tables/space_autonomy_table.dart';
import 'package:cc_persistence/database/tables/space_notes_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'space_extras_dao.g.dart';

/// Data access for the collaboration extras on spaces (PRD 16): the shared
/// Notes doc (§11), the per-space agent autonomy dial (§12) and message
/// reactions (§15).
///
/// Every read is workspace-scoped (isolation invariant): an id-only lookup is
/// not a scoping boundary, so each query filters on `workspaceId` — a foreign
/// row is simply not found.
@DriftAccessor(
  tables: [SpaceNotesTable, SpaceAutonomyTable, MessageReactionsTable],
)
class SpaceExtrasDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$SpaceExtrasDaoMixin {
  /// Creates a [SpaceExtrasDao] for the given database.
  SpaceExtrasDao(super.attachedDatabase);

  // ── Space notes ──

  /// The space's Notes doc, or null when none exists yet.
  Future<SpaceNotesTableData?> noteForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(spaceNotesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .getSingleOrNull();

  /// Watches the space's Notes doc.
  Stream<SpaceNotesTableData?> watchNoteForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(spaceNotesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .watchSingleOrNull();

  /// Upserts the space's Notes doc, bumping [SpaceNotesTable.version].
  /// Last writer wins in server receipt order — the caller does NOT pass an
  /// expected version (PRD 16's per-field LWW; the whole doc is one column).
  Future<SpaceNotesTableData> upsertNote({
    required String id,
    required String workspaceId,
    required String spaceId,
    required String contentMarkdown,
    required String updatedByPrincipal,
  }) async {
    final existing = await noteForSpace(workspaceId, spaceId);
    if (existing == null) {
      final row = SpaceNotesTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        spaceId: spaceId,
        contentMarkdown: Value(contentMarkdown),
        updatedByPrincipal: updatedByPrincipal,
      );
      await into(spaceNotesTable).insert(row);
      return (await noteForSpace(workspaceId, spaceId))!;
    }
    await (update(spaceNotesTable)..where(
          (t) => t.workspaceId.equals(workspaceId) & t.id.equals(existing.id),
        ))
        .write(
          SpaceNotesTableCompanion(
            contentMarkdown: Value(contentMarkdown),
            updatedByPrincipal: Value(updatedByPrincipal),
            updatedAt: Value(DateTime.now()),
            version: Value(existing.version + 1),
          ),
        );
    return (await noteForSpace(workspaceId, spaceId))!;
  }

  // ── Per-space agent autonomy ──

  /// Every autonomy dial set in [spaceId].
  Future<List<SpaceAutonomyTableData>> autonomyForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(spaceAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .get();

  /// Watches the autonomy dials of [spaceId].
  Stream<List<SpaceAutonomyTableData>> watchAutonomyForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(spaceAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .watch();

  /// One agent's dial in one space, or null (callers fall back to the
  /// default autonomy).
  Future<SpaceAutonomyTableData?> autonomyFor(
    String workspaceId,
    String spaceId,
    String agentId,
  ) =>
      (select(spaceAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.agentId.equals(agentId),
          ))
          .getSingleOrNull();

  /// Sets (or clears, with null) an agent's autonomy in a space.
  Future<void> setAutonomy({
    required String id,
    required String workspaceId,
    required String spaceId,
    required String agentId,
    required String? autonomyLevel,
  }) async {
    if (autonomyLevel == null) {
      await (delete(spaceAutonomyTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId) &
                t.agentId.equals(agentId),
          ))
          .go();
      return;
    }
    await into(spaceAutonomyTable).insert(
      SpaceAutonomyTableCompanion.insert(
        id: id,
        workspaceId: workspaceId,
        spaceId: spaceId,
        agentId: agentId,
        autonomyLevel: autonomyLevel,
      ),
      onConflict: DoUpdate(
        (old) => SpaceAutonomyTableCompanion(
          autonomyLevel: Value(autonomyLevel),
          updatedAt: Value(DateTime.now()),
        ),
        target: [
          spaceAutonomyTable.workspaceId,
          spaceAutonomyTable.spaceId,
          spaceAutonomyTable.agentId,
        ],
      ),
    );
  }

  // ── Message reactions ──

  /// Watches every reaction in [spaceId].
  Stream<List<MessageReactionsTableData>> watchReactionsForSpace(
    String workspaceId,
    String spaceId,
  ) =>
      (select(messageReactionsTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.spaceId.equals(spaceId),
          ))
          .watch();

  /// Toggles a principal's [emoji] reaction on a message. Returns true when
  /// the reaction now exists, false when the toggle removed it.
  Future<bool> toggleReaction({
    required String id,
    required String workspaceId,
    required String spaceId,
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
        spaceId: spaceId,
        messageId: messageId,
        principalId: principalId,
        principalType: principalType,
        emoji: emoji,
      ),
    );
    return true;
  }
}
