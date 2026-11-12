import 'dart:convert';

import 'package:cc_domain/features/pr_review/domain/repositories/agent_pull_request_requester_repository.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_state_repositories.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [AgentPullRequestRequesterRepository] over the global
/// database's `agent_pull_request_requesters` table.
class DaoAgentPullRequestRequesterRepository
    implements AgentPullRequestRequesterRepository {
  /// Creates the repository over the global database.
  DaoAgentPullRequestRequesterRepository(this._db, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final GlobalDatabase _db;
  final DateTime Function() _now;

  @override
  Future<void> add(
    AgentPullRequestRecordState state,
    String key,
    Set<String> userIds,
  ) async {
    final at = _now();
    await _db.batch((batch) {
      for (final userId in userIds) {
        batch.insert(
          _db.agentPullRequestRequestersTable,
          AgentPullRequestRequestersTableCompanion.insert(
            state: state.wire,
            prKey: key,
            userId: userId,
            recordedAt: at,
          ),
          onConflict: DoUpdate(
            (_) =>
                AgentPullRequestRequestersTableCompanion(recordedAt: Value(at)),
          ),
        );
      }
    });
  }

  @override
  Future<Set<String>> requesters({
    String? openedKey,
    String? pendingKey,
  }) async {
    final opened = openedKey != null && openedKey.isNotEmpty;
    final pending = pendingKey != null && pendingKey.isNotEmpty;
    if (!opened && !pending) {
      return const {};
    }
    final t = _db.agentPullRequestRequestersTable;
    Expression<bool> record(AgentPullRequestRecordState state, String key) =>
        t.state.equals(state.wire) & t.prKey.equals(key);
    final query = _db.selectOnly(t)
      ..addColumns([t.userId])
      ..where(
        opened && pending
            ? record(AgentPullRequestRecordState.opened, openedKey) |
                  record(AgentPullRequestRecordState.pending, pendingKey)
            : opened
            ? record(AgentPullRequestRecordState.opened, openedKey)
            : record(AgentPullRequestRecordState.pending, pendingKey!),
      );
    return {for (final row in await query.get()) row.read(t.userId)!};
  }

  @override
  Future<List<({String key, Set<String> userIds, DateTime recordedAt})>>
  pendingWithPrefix(String keyPrefix) async {
    final rows =
        await (_db.select(_db.agentPullRequestRequestersTable)..where(
              (t) =>
                  t.state.equals(AgentPullRequestRecordState.pending.wire) &
                  t.prKey.like('${_escapeLike(keyPrefix)}%', escapeChar: r'\'),
            ))
            .get();
    final byKey = <String, ({Set<String> userIds, DateTime recordedAt})>{};
    for (final row in rows) {
      final seen = byKey[row.prKey];
      byKey[row.prKey] = (
        userIds: {...?seen?.userIds, row.userId},
        recordedAt: seen == null || row.recordedAt.isAfter(seen.recordedAt)
            ? row.recordedAt
            : seen.recordedAt,
      );
    }
    return [
      for (final entry in byKey.entries)
        (
          key: entry.key,
          userIds: entry.value.userIds,
          recordedAt: entry.value.recordedAt,
        ),
    ];
  }

  @override
  Future<void> remove(AgentPullRequestRecordState state, String key) =>
      (_db.delete(
        _db.agentPullRequestRequestersTable,
      )..where((t) => t.state.equals(state.wire) & t.prKey.equals(key))).go();

  @override
  Future<void> promote(String pendingKey, String openedKey) =>
      _db.transaction(() async {
        final owners = await requesters(pendingKey: pendingKey);
        if (owners.isEmpty) {
          return;
        }
        await add(AgentPullRequestRecordState.opened, openedKey, owners);
        await remove(AgentPullRequestRecordState.pending, pendingKey);
      });

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

/// Drift-backed [PrCodeOwnerRepository] over each workspace's
/// `pr_code_owner_reviewers` table.
class DaoPrCodeOwnerRepository implements PrCodeOwnerRepository {
  /// Creates the repository over the per-workspace databases.
  DaoPrCodeOwnerRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<Set<String>> addAndList(
    String workspaceId, {
    required String repoKey,
    required int prNumber,
    required Set<String> identities,
  }) async {
    final db = _dbs.of(workspaceId);
    if (identities.isNotEmpty) {
      await db.batch((batch) {
        for (final identity in identities) {
          batch.insert(
            db.prCodeOwnerReviewersTable,
            PrCodeOwnerReviewersTableCompanion.insert(
              repoKey: repoKey,
              prNumber: prNumber,
              identity: identity,
            ),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
    }
    return {
      for (final row
          in await (db.select(db.prCodeOwnerReviewersTable)..where(
                (t) => t.repoKey.equals(repoKey) & t.prNumber.equals(prNumber),
              ))
              .get())
        row.identity,
    };
  }
}

/// Drift-backed [PendingPrReplyRepository] over each workspace's
/// `pending_pr_replies` table.
class DaoPendingPrReplyRepository implements PendingPrReplyRepository {
  /// Creates the repository over the per-workspace databases.
  DaoPendingPrReplyRepository(this._dbs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _dbs;
  final DateTime Function() _now;

  @override
  Future<void> save(
    String workspaceId,
    String runLogId,
    Map<String, dynamic> reply,
  ) async {
    final db = _dbs.of(workspaceId);
    await db
        .into(db.pendingPrRepliesTable)
        .insertOnConflictUpdate(
          PendingPrRepliesTableCompanion.insert(
            runLogId: runLogId,
            replyJson: jsonEncode(reply),
            createdAt: _now(),
          ),
        );
  }

  @override
  Future<Map<String, dynamic>?> take(
    String workspaceId,
    String runLogId,
  ) async {
    final db = _dbs.of(workspaceId);
    // `DELETE … RETURNING`: reading and consuming are one statement, so a
    // reply fires once however many completions race for it.
    final rows = await (db.delete(
      db.pendingPrRepliesTable,
    )..where((t) => t.runLogId.equals(runLogId))).goAndReturn();
    if (rows.isEmpty) {
      return null;
    }
    return jsonDecode(rows.first.replyJson) as Map<String, dynamic>;
  }
}
