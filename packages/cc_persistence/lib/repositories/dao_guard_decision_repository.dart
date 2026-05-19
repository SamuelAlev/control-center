import 'dart:convert';

import 'package:cc_domain/features/guardrails/domain/entities/guard_decision.dart';
import 'package:cc_domain/features/guardrails/domain/repositories/guard_decision_repository.dart';
import 'package:cc_domain/features/guardrails/domain/value_objects/action_decision.dart';
import 'package:cc_persistence/database/daos/guard_decision_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Drift-backed [GuardDecisionRepository] — the hash-chained audit spine.
///
/// Holds the [WorkspaceDatabaseManager] and resolves the DAO per call: a
/// chain belongs to one workspace's file, so the workspace id picks the file
/// before any SQL runs (never a cached DAO — that is the one way to
/// reintroduce a cross-workspace leak).
class DaoGuardDecisionRepository implements GuardDecisionRepository {
  /// Creates a [DaoGuardDecisionRepository] over the per-workspace databases.
  DaoGuardDecisionRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;
  static const _uuid = Uuid();

  GuardDecisionDao _dao(String workspaceId) =>
      _dbs.of(workspaceId).guardDecisionDao;

  @override
  Future<void> append(GuardDecision decision) =>
      _dao(decision.workspaceId).append(decision.workspaceId, (seq, prevHash) {
        final chained = decision.chained(seq: seq, prevHash: prevHash);
        return _toCompanion(chained);
      });

  @override
  Future<List<GuardDecision>> recent(
    String workspaceId, {
    int limit = 100,
    int? beforeSeq,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).recent(workspaceId, limit: limit, beforeSeq: beforeSeq);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Stream<List<GuardDecision>> watchRecent(
    String workspaceId, {
    int limit = 100,
  }) => _dao(
    workspaceId,
  ).watchRecent(workspaceId, limit: limit).map((rows) => rows.map(_fromRow).toList(growable: false));

  @override
  Future<List<GuardDecision>> pageFrom(
    String workspaceId,
    int fromSeq, {
    int limit = 500,
  }) async {
    final rows = await _dao(
      workspaceId,
    ).pageFrom(workspaceId, fromSeq, limit: limit);
    return rows.map(_fromRow).toList(growable: false);
  }

  @override
  Future<ChainVerification> verifyChain(
    String workspaceId, {
    int fromSeq = 1,
  }) async {
    var checked = 0;
    var checkpoints = 0;
    var cursor = fromSeq;
    String? expectedPrev;
    var previousSeq = fromSeq - 1;
    while (true) {
      final page = await pageFrom(workspaceId, cursor, limit: 500);
      if (page.isEmpty) {
        break;
      }
      for (final row in page) {
        // A gap means rows were deleted from the middle — the chain's whole
        // purpose is to make that visible, so it is a failure, not a skip.
        // The one sanctioned removal (`truncateWithCheckpoint`) leaves a
        // checkpoint row occupying the boundary sequence.
        if (previousSeq >= fromSeq && row.seq != previousSeq + 1) {
          return ChainVerification(
            rowsChecked: checked,
            intact: false,
            brokenAtSeq: row.seq,
            reason:
                'sequence gap: expected ${previousSeq + 1}, found ${row.seq}',
          );
        }
        // A checkpoint deliberately restarts the chain from the terminal hash
        // of the segment it replaced, so its own prevHash is not the previous
        // row's entryHash.
        final isCheckpoint = row.kind == 'checkpoint';
        if (expectedPrev != null &&
            !isCheckpoint &&
            row.prevHash != expectedPrev) {
          return ChainVerification(
            rowsChecked: checked,
            intact: false,
            brokenAtSeq: row.seq,
            reason: 'prev-hash mismatch at seq ${row.seq}',
          );
        }
        // EVERY row's own hash is re-derived, checkpoints included. Skipping
        // them made a checkpoint an unauthenticated row: anyone able to write
        // the database could delete a stretch of history, drop in a
        // hand-written `kind='checkpoint'` naming whatever hash the surviving
        // tail expects, and the chain would verify clean.
        if (row.computeEntryHash(row.prevHash) != row.entryHash) {
          return ChainVerification(
            rowsChecked: checked,
            intact: false,
            brokenAtSeq: row.seq,
            reason: isCheckpoint
                ? 'the truncation checkpoint at seq ${row.seq} does not hash '
                      'to its own contents'
                : 'row ${row.seq} was modified after it was written',
          );
        }
        if (isCheckpoint) {
          checkpoints++;
        }
        // A checkpoint STANDS IN FOR the segment it replaced: it asserts
        // "the rows I removed ended with this hash", so the first surviving
        // row still links to that terminal hash, not to the checkpoint's own.
        expectedPrev = isCheckpoint ? row.prevHash : row.entryHash;
        previousSeq = row.seq;
        checked++;
      }
      cursor = page.last.seq + 1;
    }
    return ChainVerification(
      rowsChecked: checked,
      intact: true,
      checkpoints: checkpoints,
    );
  }

  @override
  Future<void> truncateWithCheckpoint(
    String workspaceId, {
    required int uptoSeq,
    required DateTime at,
  }) async {
    final tail = await _dao(workspaceId).recent(
      workspaceId,
      limit: 1,
      beforeSeq: uptoSeq + 1,
    );
    if (tail.isEmpty) {
      return;
    }
    final terminalHash = tail.first.entryHash;
    final checkpointId = _uuid.v4();
    final checkpoint = GuardDecision(
      id: checkpointId,
      workspaceId: workspaceId,
      seq: uptoSeq,
      occurredAt: at,
      actorType: 'system',
      actorId: 'retention',
      surface: GuardSurface.audit,
      actionName: 'audit.truncate',
      decision: ActionDecision.allow,
      prevHash: terminalHash,
      kind: 'checkpoint',
    );
    await _dao(workspaceId).truncateWithCheckpoint(
      workspaceId,
      uptoSeq: uptoSeq,
      terminalHash: terminalHash,
      checkpointId: checkpointId,
      checkpointEntryHash: checkpoint.computeEntryHash(terminalHash),
      at: at,
    );
  }

  GuardDecisionsTableCompanion _toCompanion(GuardDecision d) =>
      GuardDecisionsTableCompanion.insert(
        id: d.id,
        workspaceId: d.workspaceId,
        seq: d.seq,
        occurredAt: d.occurredAt,
        actorType: d.actorType,
        actorId: d.actorId,
        onBehalfOfUserId: Value(d.onBehalfOfUserId),
        delegationChainId: Value(d.delegationChainId),
        delegationDepth: Value(d.delegationDepth),
        spaceId: Value(d.spaceId),
        runId: Value(d.runId),
        deviceId: Value(d.deviceId),
        ip: Value(d.ip),
        surface: d.surface.wire,
        actionName: d.actionName,
        actionClasses: Value(jsonEncode(d.actionClasses)),
        permission: Value(d.permission),
        argsDigest: Value(d.argsDigest),
        constraintSummary: Value(d.constraintSummary),
        decision: d.decision.wire,
        enforcement: Value(d.enforcement?.wire),
        sourceScope: Value(d.sourceScope),
        ruleId: Value(d.ruleId),
        prompted: Value(d.prompted),
        responderUserId: Value(d.responderUserId),
        overrideReason: Value(d.overrideReason),
        correlationId: Value(d.correlationId),
        prevHash: d.prevHash,
        entryHash: d.entryHash,
        kind: Value(d.kind),
      );

  GuardDecision _fromRow(GuardDecisionsTableData r) => GuardDecision(
    id: r.id,
    workspaceId: r.workspaceId,
    seq: r.seq,
    occurredAt: r.occurredAt,
    actorType: r.actorType,
    actorId: r.actorId,
    onBehalfOfUserId: r.onBehalfOfUserId,
    delegationChainId: r.delegationChainId,
    delegationDepth: r.delegationDepth,
    spaceId: r.spaceId,
    runId: r.runId,
    deviceId: r.deviceId,
    ip: r.ip,
    surface: GuardSurface.fromWire(r.surface),
    actionName: r.actionName,
    actionClasses: _decodeClasses(r.actionClasses),
    permission: r.permission,
    argsDigest: r.argsDigest,
    constraintSummary: r.constraintSummary,
    decision: ActionDecision.fromWire(r.decision),
    enforcement: r.enforcement == null
        ? null
        : EnforcementLevel.fromWire(r.enforcement),
    sourceScope: r.sourceScope,
    ruleId: r.ruleId,
    prompted: r.prompted,
    responderUserId: r.responderUserId,
    overrideReason: r.overrideReason,
    correlationId: r.correlationId,
    prevHash: r.prevHash,
    entryHash: r.entryHash,
    kind: r.kind,
  );

  static List<String> _decodeClasses(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? [for (final e in decoded) e.toString()]
          : const [];
    } catch (_) {
      return const [];
    }
  }
}
