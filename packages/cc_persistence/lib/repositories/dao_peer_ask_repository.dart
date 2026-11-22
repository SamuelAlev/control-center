import 'package:cc_domain/features/dispatch/domain/entities/peer_ask.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/peer_ask_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/peer_ask_values.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/peer_ask_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/peer_ask_mapper.dart';
import 'package:cc_persistence/repositories/refused_rows.dart';
import 'package:drift/drift.dart';

/// Drift-backed [PeerAskRepository].
///
/// Resolves `_dbs.of(workspaceId).peerAskDao` per call; [insertWithinLimits]
/// picks the file from the ask's own workspace. Every change after the insert is one
/// conditional statement on a pending ask. A row the entity refuses is left
/// out and reported through the warning sink; a pending one is settled as
/// `failed` (`invalid_row`) by the read.
class DaoPeerAskRepository implements PeerAskRepository {
  /// Creates a [DaoPeerAskRepository] over the per-workspace databases.
  /// `clock` stamps the `settled_at` of a refused ask a read settles.
  DaoPeerAskRepository(this._dbs, {this._clock = DateTime.now})
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final DateTime Function() _clock;
  final PeerAskMapper _mapper = const PeerAskMapper();

  /// The `error` of a stored ask the entity refused.
  static const String invalidRowError = 'invalid_row';

  PeerAskDao _dao(String workspaceId) => _dbs.of(workspaceId).peerAskDao;

  Future<List<PeerAsk>> _list(
    String workspaceId,
    Iterable<PeerAsksTableData> rows,
  ) => mapSettlingRefused(
    dbs: _dbs,
    workspaceId: workspaceId,
    repository: 'PeerAskRepository',
    table: 'peer_asks',
    rows: rows,
    map: _mapper.tryToDomain,
    isOpen: (row) => row.status == PeerAskDao.pending,
    idOf: (row) => row.id,
    settle: (ids) async {
      var settled = 0;
      for (final id in ids) {
        if (await _dao(workspaceId).settle(
          id,
          PeerAsksTableCompanion(
            status: Value(PeerAskStatus.failed.wire),
            error: const Value(invalidRowError),
            settledAt: Value(_clock()),
          ),
        )) {
          settled++;
        }
      }
      return settled;
    },
    settledAs: 'failed ($invalidRowError)',
  );

  Future<PeerAsk?> _one(String workspaceId, PeerAsksTableData? row) async =>
      row == null ? null : (await _list(workspaceId, [row])).firstOrNull;

  @override
  Future<PeerAskLimitHit?> insertWithinLimits(
    PeerAsk ask, {
    required PeerAskInsertLimits limits,
  }) {
    final ws = ask.workspaceId;
    final db = _dbs.of(ws);
    // One transaction: the checks and the insert see the same rows, so two
    // asks at once cannot both pass a limit. Counted from the mapped rows,
    // so a refused stored ask (settled by the read) never counts.
    return db.transaction(() async {
      final dao = db.peerAskDao;
      final duplicate = await _one(
        ws,
        await dao.findPendingDuplicate(
          askerAgentId: ask.askerAgentId,
          recipientAgentId: ask.recipientAgentId,
          questionHash: ask.questionHash,
          since: limits.duplicateSince,
        ),
      );
      if (duplicate != null) {
        return PeerAskLimitHit(
          PeerAskLimit.duplicate,
          duplicateAskId: duplicate.id,
        );
      }
      final ofAsker = await _list(
        ws,
        await dao.listPending(askerAgentId: ask.askerAgentId),
      );
      if (ofAsker.length >= limits.perAsker) {
        return PeerAskLimitHit(PeerAskLimit.asker);
      }
      final ofRecipient = await _list(
        ws,
        await dao.listPending(recipientAgentId: ask.recipientAgentId),
      );
      if (ofRecipient.length >= limits.perRecipient) {
        return PeerAskLimitHit(PeerAskLimit.recipient);
      }
      await dao.insert(_mapper.toCompanion(ask));
      return null;
    });
  }

  @override
  Future<bool> setDispatched(
    String workspaceId, {
    required String id,
    required String dispatchedRunId,
    String? recipientConversationId,
    String? recipientSpaceId,
    String? questionMessageId,
  }) {
    for (final (value, name) in [
      (dispatchedRunId, 'dispatchedRunId'),
      (recipientConversationId, 'recipientConversationId'),
      (recipientSpaceId, 'recipientSpaceId'),
      (questionMessageId, 'questionMessageId'),
    ]) {
      if (value != null && value.isEmpty) {
        throw ArgumentError.value(value, name, 'must not be empty');
      }
    }
    return _dao(workspaceId).writeWhilePending(
      id,
      (t) => const Constant(true),
      PeerAsksTableCompanion(
        dispatchedRunId: Value(dispatchedRunId),
        recipientConversationId: Value.absentIfNull(recipientConversationId),
        recipientSpaceId: Value.absentIfNull(recipientSpaceId),
        questionMessageId: Value.absentIfNull(questionMessageId),
      ),
    );
  }

  @override
  Future<PeerAsk?> getById(String workspaceId, String id) async =>
      _one(workspaceId, await _dao(workspaceId).getById(id));

  @override
  Future<PeerAsk?> getByDispatchedRun(String workspaceId, String runId) async =>
      _one(workspaceId, await _dao(workspaceId).getByDispatchedRun(runId));

  @override
  Future<List<PeerAsk>> listPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
    String? askerConversationId,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listPending(
      askerAgentId: askerAgentId,
      recipientAgentId: recipientAgentId,
      askerConversationId: askerConversationId,
    ),
  );

  @override
  Future<int> countPending(
    String workspaceId, {
    String? askerAgentId,
    String? recipientAgentId,
  }) async {
    // Counted from the mapped rows, so a refused ask (settled by this read)
    // never counts against a limit.
    final asks = await _list(
      workspaceId,
      await _dao(workspaceId).listPending(
        askerAgentId: askerAgentId,
        recipientAgentId: recipientAgentId,
      ),
    );
    return asks.length;
  }

  @override
  Future<PeerAsk?> findPendingDuplicate(
    String workspaceId, {
    required String askerAgentId,
    required String recipientAgentId,
    required String questionHash,
    required DateTime since,
  }) async => _one(
    workspaceId,
    await _dao(workspaceId).findPendingDuplicate(
      askerAgentId: askerAgentId,
      recipientAgentId: recipientAgentId,
      questionHash: questionHash,
      since: since,
    ),
  );

  @override
  Future<bool> settle(
    String workspaceId, {
    required String id,
    required PeerAskStatus status,
    String? replyMessageId,
    String? error,
    bool? replyInline,
    required DateTime now,
  }) {
    if (status == PeerAskStatus.pending) {
      throw ArgumentError.value(status, 'status', 'must be a settled status');
    }
    if (error != null && error.length > PeerAsk.maxErrorLength) {
      throw ArgumentError.value(
        error.length,
        'error',
        'must be at most ${PeerAsk.maxErrorLength} characters',
      );
    }
    return _dao(workspaceId).settle(
      id,
      PeerAsksTableCompanion(
        status: Value(status.wire),
        replyMessageId: Value.absentIfNull(replyMessageId),
        error: Value.absentIfNull(error),
        replyInline: Value.absentIfNull(replyInline),
        settledAt: Value(now),
      ),
    );
  }

  @override
  Future<bool> markPromised(
    String workspaceId, {
    required String id,
    required DateTime now,
  }) => _dao(workspaceId).writeWhilePending(
    id,
    (t) => t.promisedAt.isNull(),
    PeerAsksTableCompanion(promisedAt: Value(now)),
  );

  @override
  Future<bool> markBlockedNoticed(
    String workspaceId, {
    required String id,
    required DateTime now,
  }) => _dao(workspaceId).writeWhilePending(
    id,
    (t) => t.blockedNoticedAt.isNull(),
    PeerAsksTableCompanion(blockedNoticedAt: Value(now)),
  );

  @override
  Future<bool> markStallNoticed(
    String workspaceId, {
    required String id,
    required String runId,
  }) {
    if (runId.isEmpty) {
      throw ArgumentError.value(runId, 'runId', 'must not be empty');
    }
    return _dao(workspaceId).writeWhilePending(
      id,
      (t) => t.stallNoticedRunId.isNull(),
      PeerAsksTableCompanion(stallNoticedRunId: Value(runId)),
    );
  }

  @override
  Future<List<PeerAsk>> listPendingForRecipientConversation(
    String workspaceId, {
    required String recipientAgentId,
    required String recipientConversationId,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listPendingForRecipientConversation(
      recipientAgentId: recipientAgentId,
      recipientConversationId: recipientConversationId,
    ),
  );

  @override
  Future<List<PeerAsk>> listExpired(
    String workspaceId, {
    required DateTime now,
  }) async => _list(workspaceId, await _dao(workspaceId).listExpired(now));

  @override
  Stream<List<PeerAsk>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _dao(workspaceId)
      .watchForAskerConversation(conversationId)
      .asyncMap((rows) => _list(workspaceId, rows));

  @override
  Future<int> deleteSettledBefore(
    String workspaceId, {
    required DateTime cutoff,
  }) => _dao(workspaceId).deleteSettledBefore(cutoff);

  /// CROSS-WORKSPACE BY DESIGN: the ask sweep (at boot and periodically)
  /// finds the workspaces that hold a pending ask; everything it then reads
  /// or writes is workspace-scoped. Read-only workspaces are skipped (the
  /// sweep would fail every write there).
  @override
  Future<List<String>> workspacesWithPendingAsks() async {
    final ids = await _cross.fanOut(
      (db) async => await db.peerAskDao.hasPendingAsks() ? db.workspaceId : null,
      backgroundWriter: 'peer ask sweep',
    );
    return [for (final id in ids) ?id];
  }
}
