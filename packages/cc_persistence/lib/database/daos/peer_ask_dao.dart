import 'package:cc_persistence/database/tables/peer_asks_table.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

part 'peer_ask_dao.g.dart';

/// Data access for peer asks (`peer_asks`) in ONE workspace.
///
/// Scoped by hanging off a [WorkspaceDatabase]: the isolation boundary is the
/// database file.
@DriftAccessor(tables: [PeerAsksTable])
class PeerAskDao extends DatabaseAccessor<WorkspaceDatabase>
    with _$PeerAskDaoMixin {
  /// Creates a [PeerAskDao] bound to one workspace's database.
  PeerAskDao(super.attachedDatabase);

  /// The `status` of an ask that waits for its recipient.
  static const String pending = 'pending';

  /// Inserts a new ask; throws when its id exists.
  Future<void> insert(PeerAsksTableCompanion ask) =>
      into(peerAsksTable).insert(ask);

  /// Writes [values] on the ask [id] while it is pending and [condition]
  /// holds, as one statement. True only for the caller that changed it.
  Future<bool> writeWhilePending(
    String id,
    Expression<bool> Function($PeerAsksTableTable t) condition,
    PeerAsksTableCompanion values,
  ) async =>
      await (update(peerAsksTable)..where(
            (t) => t.id.equals(id) & t.status.equals(pending) & condition(t),
          ))
          .write(values) ==
      1;

  /// The ask [id], or null.
  Future<PeerAsksTableData?> getById(String id) =>
      (select(peerAsksTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// The newest ask whose recipient run is [runId], or null.
  Future<PeerAsksTableData?> getByDispatchedRun(String runId) =>
      (select(peerAsksTable)
            ..where((t) => t.dispatchedRunId.equals(runId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ])
            ..limit(1))
          .getSingleOrNull();

  Expression<bool> _pendingWhere(
    $PeerAsksTableTable t, {
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  }) {
    Expression<bool> where = t.status.equals(pending);
    if (askerAgentId != null) {
      where &= t.askerAgentId.equals(askerAgentId);
    }
    if (recipientAgentId != null) {
      where &= t.recipientAgentId.equals(recipientAgentId);
    }
    if (askerConversationId != null) {
      where &= t.askerConversationId.equals(askerConversationId);
    }
    return where;
  }

  /// Pending asks, oldest first, narrowed by every given filter.
  Future<List<PeerAsksTableData>> listPending({
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  }) =>
      (select(peerAsksTable)
            ..where(
              (t) => _pendingWhere(
                t,
                askerAgentId: askerAgentId,
                recipientAgentId: recipientAgentId,
                askerConversationId: askerConversationId,
              ),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// The newest pending ask from [askerAgentId] to [recipientAgentId] with
  /// [questionHash] created at or after [since], or null.
  Future<PeerAsksTableData?> findPendingDuplicate({
    required String askerAgentId,
    required String recipientAgentId,
    required String questionHash,
    required DateTime since,
  }) =>
      (select(peerAsksTable)
            ..where(
              (t) =>
                  _pendingWhere(
                    t,
                    askerAgentId: askerAgentId,
                    recipientAgentId: recipientAgentId,
                  ) &
                  t.questionHash.equals(questionHash) &
                  t.createdAt.isBiggerOrEqualValue(since),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Settles the ask [id] from pending with [values]. True only for the
  /// caller that moved it.
  Future<bool> settle(String id, PeerAsksTableCompanion values) async =>
      await (update(peerAsksTable)
            ..where((t) => t.id.equals(id) & t.status.equals(pending)))
          .write(values) ==
      1;

  /// Pending asks to [recipientAgentId] in [recipientConversationId], oldest
  /// first.
  Future<List<PeerAsksTableData>> listPendingForRecipientConversation({
    required String recipientAgentId,
    required String recipientConversationId,
  }) =>
      (select(peerAsksTable)
            ..where(
              (t) =>
                  _pendingWhere(t, recipientAgentId: recipientAgentId) &
                  t.recipientConversationId.equals(recipientConversationId),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.createdAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// Pending asks whose `expires_at` is at or before [now], oldest first.
  Future<List<PeerAsksTableData>> listExpired(DateTime now) =>
      (select(peerAsksTable)
            ..where(
              (t) =>
                  t.status.equals(pending) &
                  t.expiresAt.isSmallerOrEqualValue(now),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.expiresAt),
              (t) => OrderingTerm.asc(t.id),
            ]))
          .get();

  /// Watches the asks made from [conversationId], newest first.
  Stream<List<PeerAsksTableData>> watchForAskerConversation(
    String conversationId,
  ) =>
      (select(peerAsksTable)
            ..where((t) => t.askerConversationId.equals(conversationId))
            ..orderBy([
              (t) => OrderingTerm.desc(t.createdAt),
              (t) => OrderingTerm.desc(t.id),
            ]))
          .watch();

  /// Deletes settled asks that settled before [cutoff]. Returns how many.
  Future<int> deleteSettledBefore(DateTime cutoff) =>
      (delete(peerAsksTable)..where(
            (t) =>
                t.status.equals(pending).not() &
                t.settledAt.isSmallerThanValue(cutoff),
          ))
          .go();

  /// True when this workspace has a pending ask.
  Future<bool> hasPendingAsks() async =>
      await (selectOnly(peerAsksTable)
            ..addColumns([peerAsksTable.id])
            ..where(peerAsksTable.status.equals(pending))
            ..limit(1))
          .getSingleOrNull() !=
      null;
}
