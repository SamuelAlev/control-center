import 'dart:async';
import 'dart:convert';

import 'package:cc_host/cc_host.dart'
    show
        LedgerClaimed,
        LedgerInProgress,
        LedgerReplay,
        WriteLedgerClaim,
        WriteLedgerPort;
import 'package:cc_persistence/cc_persistence.dart';

/// Drift-backed [WriteLedgerPort] (PRD 19 §3): the universal idempotency ledger
/// consulted by the `RepoOpDispatcher` before a mutating handler runs. Stores
/// the returned result `data` as JSON so a retry replays it byte-identically.
///
/// The ledger lives in each workspace's own database file, so an idempotency key
/// is only ever replayed against the workspace that recorded it.
///
/// A claim is a row with no result yet. Claims are only ever completed by the
/// process that made them, so the first claim this instance makes in a
/// workspace is preceded by [dropUnfinishedClaims]: anything unfinished in that
/// file was left by a previous server process and would otherwise refuse its
/// key as in progress forever. One instance serves the whole server process.
class DaoWriteLedger implements WriteLedgerPort {
  /// Creates a [DaoWriteLedger] over the per-workspace databases. [now] is
  /// injectable for tests.
  DaoWriteLedger(this._dbs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _dbs;
  final DateTime Function() _now;

  /// One sweep per workspace per process, shared by concurrent first claims.
  final Map<String, Future<int>> _swept = {};

  WriteLedgerDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).writeLedgerDao;

  /// Drops the unfinished claims in [workspaceId]: those a previous server
  /// process made and can never complete. Returns how many were dropped.
  ///
  /// Called once per workspace before this process's first claim there; it
  /// must not run while this process holds a claim in [workspaceId].
  Future<int> dropUnfinishedClaims(String workspaceId) =>
      _dao(workspaceId).dropUnfinished(workspaceId);

  @override
  Future<WriteLedgerClaim> claim({
    required String workspaceId,
    required String key,
    required String opName,
  }) async {
    final sweep = _swept.putIfAbsent(
      workspaceId,
      () => dropUnfinishedClaims(workspaceId),
    );
    try {
      await sweep;
    } catch (_) {
      // Let the next claim try the sweep again rather than skip it. The
      // failed future was awaited above; dropping it leaves nothing pending.
      unawaited(_swept.remove(workspaceId));
      rethrow;
    }
    final dao = _dao(workspaceId);
    final claimed = await dao.claim(
      WriteLedgerTableCompanion(
        workspaceId: Value(workspaceId),
        idempotencyKey: Value(key),
        opName: Value(opName),
        resultJson: const Value(null),
        createdAt: Value(_now()),
      ),
    );
    if (claimed) {
      return const LedgerClaimed();
    }
    final row = await dao.find(workspaceId, key);
    final result = row?.resultJson;
    if (row == null) {
      // The holder released between the insert and the read: the key is free
      // again, so this call may still take it.
      return claim(workspaceId: workspaceId, key: key, opName: opName);
    }
    if (result == null) {
      return const LedgerInProgress();
    }
    final decoded = jsonDecode(result);
    return LedgerReplay(
      decoded is Map ? decoded.cast<String, dynamic>() : <String, dynamic>{},
    );
  }

  @override
  Future<bool> complete({
    required String workspaceId,
    required String key,
    required Map<String, dynamic> data,
  }) => _dao(workspaceId).complete(workspaceId, key, jsonEncode(data), _now());

  @override
  Future<void> release({
    required String workspaceId,
    required String key,
  }) async {
    await _dao(workspaceId).release(workspaceId, key);
  }
}
