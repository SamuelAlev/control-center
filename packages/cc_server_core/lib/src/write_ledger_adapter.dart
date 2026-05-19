import 'dart:convert';

import 'package:cc_host/cc_host.dart' show WriteLedgerPort;
import 'package:cc_persistence/cc_persistence.dart';

/// Drift-backed [WriteLedgerPort] (PRD 19 §3): the universal idempotency ledger
/// consulted by the `RepoOpDispatcher` before a mutating handler runs. Stores
/// the returned result `data` as JSON so a retry replays it byte-identically.
///
/// The ledger lives in each workspace's own database file, so an idempotency key
/// is only ever replayed against the workspace that recorded it.
class DaoWriteLedger implements WriteLedgerPort {
  /// Creates a [DaoWriteLedger] over the per-workspace databases. [now] is
  /// injectable for tests.
  DaoWriteLedger(this._dbs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _dbs;
  final DateTime Function() _now;

  WriteLedgerDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).writeLedgerDao;

  @override
  Future<Map<String, dynamic>?> find(String workspaceId, String key) async {
    final row = await _dao(workspaceId).find(workspaceId, key);
    if (row == null) {
      return null;
    }
    final decoded = jsonDecode(row.resultJson);
    return decoded is Map
        ? decoded.cast<String, dynamic>()
        : <String, dynamic>{};
  }

  @override
  Future<void> record({
    required String workspaceId,
    required String key,
    required String opName,
    required Map<String, dynamic> data,
  }) => _dao(workspaceId).record(
    WriteLedgerTableCompanion(
      workspaceId: Value(workspaceId),
      idempotencyKey: Value(key),
      opName: Value(opName),
      resultJson: Value(jsonEncode(data)),
      createdAt: Value(_now()),
    ),
  );
}
