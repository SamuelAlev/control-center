part of 'messaging_dao.dart';

/// Space rows and their participants: provisioning state, naming,
/// archiving, deletion and each person's read cursor.
mixin _SpaceRows
    on
        DatabaseAccessor<WorkspaceDatabase>,
        _$MessagingDaoMixin,
        _ConversationActivity {
  /// Updates the updatedAt timestamp for a space.
  Future<void> updateSpaceUpdatedAt(String spaceId, DateTime updatedAt) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(updatedAt: Value(updatedAt)),
      );

  /// Updates the [Mode]-serialized value for a space.
  Future<void> updateSpaceMode(String spaceId, String mode) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(mode: Value(mode)),
      );

  /// Updates the provisioning status for a space. Leaving `provisioning`
  /// also clears the granular step in the same write, so a non-null
  /// `provisioning_step` can never accompany a `ready`/`failed` row.
  Future<void> updateSpaceProvisioningStatus(String spaceId, String status) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(
          provisioningStatus: Value(status),
          provisioningStep: status == 'provisioning'
              ? const Value.absent()
              : const Value(null),
        ),
      );

  /// Updates the granular in-flight provisioning step for a space
  /// (`SpaceProvisioningStep.toDbValue()` JSON, or null to clear).
  Future<void> updateSpaceProvisioningStep(String spaceId, String? step) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(provisioningStep: Value(step)),
      );

  /// This workspace's spaces whose provisioning status equals [status].
  ///
  /// Used by the boot reconciler to re-kick spaces a previous session
  /// stranded in `provisioning` (the flip to ready/failed only ever comes from
  /// the in-flight provisioning future, so a restart mid-provision would leave
  /// them stuck forever). The reconciler visits every workspace's database in
  /// turn, so it reaches all of them without this query spanning any.
  Future<List<SpacesTableData>> spacesByProvisioningStatus(String status) =>
      (select(
        spacesTable,
      )..where((t) => t.provisioningStatus.equals(status))).get();

  /// Returns the space row by id, or null.
  Future<SpacesTableData?> getSpaceById(String spaceId) => (select(
    spacesTable,
  )..where((t) => t.id.equals(spaceId))).getSingleOrNull();

  /// Returns all participants for a space (for dedup checks).
  Future<List<SpaceParticipantsTableData>> getParticipants(String spaceId) =>
      (select(
        spaceParticipantsTable,
      )..where((t) => t.spaceId.equals(spaceId))).get();

  /// Deletes a space and all its messages and participants.
  ///
  /// The SPACE row goes first and FK `ON DELETE CASCADE` takes the children
  /// with it.
  Future<void> deleteSpaceCascade(String spaceId) => transaction(() async {
    await (delete(spacesTable)..where((t) => t.id.equals(spaceId))).go();
    // Belt and braces for a row whose FK did not cascade (`foreign_keys`
    // off on this connection).
    await (delete(
      conversationMessagesTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
    await (delete(
      spaceParticipantsTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
    await _deleteSpaceActivity(spaceId);
  });

  Future<void> _deleteSpaceActivity(String spaceId) => (delete(
    conversationActivityTable,
  )..where((t) => t.spaceId.equals(spaceId))).go();

  /// Updates the space name.
  Future<void> updateSpaceName(String spaceId, String name) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(name: Value(name)),
      );

  /// Stamps (or clears, when [archivedAt] is null) a space's archive time.
  /// `updatedAt` is deliberately untouched: archiving is a hide, not an
  /// activity, so a restored space keeps its recency position in the list.
  Future<void> setSpaceArchived(String spaceId, DateTime? archivedAt) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(archivedAt: Value(archivedAt)),
      );

  /// Sets the space's `no_repos` flag — the only way "explicitly no repos"
  /// is expressible, since zero `space_repos` rows already means "all repos".
  Future<void> updateSpaceNoRepos(String spaceId, bool noRepos) =>
      (update(spacesTable)..where((t) => t.id.equals(spaceId))).write(
        SpacesTableCompanion(noRepos: Value(noRepos)),
      );

  /// Deletes all messages in a space, the threads anchored on them, and the
  /// space's activity rows.
  ///
  /// Deleting a message leaves a thread anchored on it in place (the anchor
  /// is `ON DELETE SET NULL`). Clearing the space is the caller that means
  /// the threads too: every reply in them is one of the messages cleared,
  /// so what would remain is an empty conversation hanging off nothing.
  Future<void> clearSpaceMessages(String spaceId) => transaction(() async {
    await (delete(conversationsTable)..where(
          (t) => t.spaceId.equals(spaceId) & t.anchorMessageId.isNotNull(),
        ))
        .go();
    await (delete(
      conversationMessagesTable,
    )..where((t) => t.spaceId.equals(spaceId))).go();
    await _deleteSpaceActivity(spaceId);
  });

  /// Removes a single participant (agent or user) from a space.
  Future<void> removeParticipant(String spaceId, String principalId) =>
      (delete(spaceParticipantsTable)
            ..where((t) => t.spaceId.equals(spaceId))
            ..where((t) => t.principalId.equals(principalId)))
          .go();

  /// Moves [userId]'s read cursor in [conversationId] to the newest live
  /// message in the conversation, as the position `(created_at, rowid)`.
  ///
  /// A cursor holding only the time would treat a message landing later in
  /// the same second as already read, because `created_at` has whole-second
  /// resolution. A conversation without messages gets the current time and
  /// sequence 0, which every later message follows.
  ///
  /// Idempotent and cheap: one index probe and an upsert of that user's row.
  Future<void> markConversationRead(String conversationId, String userId) =>
      transaction(() async {
        final newest = await customSelect(
          'SELECT created_at, rowid AS seq FROM conversation_messages '
          'WHERE conversation_id = ? AND reverted = 0 '
          'ORDER BY created_at DESC, rowid DESC LIMIT 1',
          variables: [Variable.withString(conversationId)],
          readsFrom: {conversationMessagesTable},
        ).getSingleOrNull();
        final at = newest == null
            ? DateTime.now()
            : _fromSeconds(newest.read<int>('created_at'));
        final seq = newest?.read<int>('seq') ?? 0;
        await into(conversationReadsTable).insertOnConflictUpdate(
          ConversationReadsTableCompanion.insert(
            conversationId: conversationId,
            userId: userId,
            lastReadAt: at,
            lastReadSeq: seq,
          ),
        );
      });

  /// Watches [userId]'s read cursors across this workspace's conversations,
  /// keyed by conversation id. A conversation missing from the map has never
  /// been read by that user.
  Stream<Map<String, FeedPosition>> watchUserConversationReads(
    String workspaceId,
    String userId,
  ) {
    final query =
        select(conversationReadsTable).join([
          innerJoin(
            conversationsTable,
            conversationsTable.id.equalsExp(
              conversationReadsTable.conversationId,
            ),
          ),
        ])..where(
          conversationsTable.workspaceId.equals(workspaceId) &
              conversationReadsTable.userId.equals(userId),
        );
    return query.watch().map(
      (rows) => {
        for (final row in rows)
          row.readTable(conversationReadsTable).conversationId: FeedPosition(
            at: row.readTable(conversationReadsTable).lastReadAt,
            seq: row.readTable(conversationReadsTable).lastReadSeq,
          ),
      },
    );
  }
}
