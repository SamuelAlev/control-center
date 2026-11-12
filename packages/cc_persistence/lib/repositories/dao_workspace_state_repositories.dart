import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/editor_layout_repository.dart';
import 'package:cc_domain/core/domain/value_objects/editor_layout_cache_kinds.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_escalation_repository.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_divergence_repository.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:drift/drift.dart';

/// Drift-backed [EditorLayoutRepository] over each workspace's
/// `editor_layouts` table.
class DaoEditorLayoutRepository implements EditorLayoutRepository {
  /// Creates the repository over the per-workspace databases.
  DaoEditorLayoutRepository(this._dbs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _dbs;
  final DateTime Function() _now;

  @override
  Future<String?> read(
    String workspaceId, {
    required String userId,
    required EditorLayoutSurface surface,
    required String target,
  }) async {
    final db = _dbs.of(workspaceId);
    final row =
        await (db.select(db.editorLayoutsTable)..where(
              (t) =>
                  t.userId.equals(userId) &
                  t.surface.equals(surface.wire) &
                  t.target.equals(target),
            ))
            .getSingleOrNull();
    return row?.layout;
  }

  @override
  Future<void> write(
    String workspaceId, {
    required String userId,
    required EditorLayoutSurface surface,
    required String target,
    required String layout,
  }) async {
    final db = _dbs.of(workspaceId);
    await db
        .into(db.editorLayoutsTable)
        .insertOnConflictUpdate(
          EditorLayoutsTableCompanion.insert(
            userId: userId,
            surface: surface.wire,
            target: target,
            layout: layout,
            updatedAt: _now(),
          ),
        );
  }
}

/// Drift-backed [ApprovalEscalationRepository] over each workspace's
/// `approval_escalations` table.
class DaoApprovalEscalationRepository implements ApprovalEscalationRepository {
  /// Creates the repository over the per-workspace databases.
  DaoApprovalEscalationRepository(this._dbs, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final WorkspaceDatabaseManager _dbs;
  final DateTime Function() _now;

  @override
  Future<int> tierOf(String workspaceId, String approvalId) async {
    final db = _dbs.of(workspaceId);
    final row = await (db.select(
      db.approvalEscalationsTable,
    )..where((t) => t.approvalId.equals(approvalId))).getSingleOrNull();
    return row?.tier ?? 0;
  }

  @override
  Future<void> recordTier(
    String workspaceId,
    String approvalId,
    int tier,
  ) async {
    final db = _dbs.of(workspaceId);
    await db
        .into(db.approvalEscalationsTable)
        .insertOnConflictUpdate(
          ApprovalEscalationsTableCompanion.insert(
            approvalId: approvalId,
            tier: tier,
            escalatedAt: _now(),
          ),
        );
  }
}

/// Drift-backed [PlanDivergenceRepository] over each workspace's
/// `plan_divergences` table.
class DaoPlanDivergenceRepository implements PlanDivergenceRepository {
  /// Creates the repository over the per-workspace databases.
  DaoPlanDivergenceRepository(this._dbs);

  final WorkspaceDatabaseManager _dbs;

  @override
  Future<Map<String, PlanDivergence>> forOrchestration(
    String workspaceId,
    String orchestrationId,
  ) async {
    final db = _dbs.of(workspaceId);
    return {
      for (final row in await (db.select(
        db.planDivergencesTable,
      )..where((t) => t.orchestrationId.equals(orchestrationId))).get())
        row.nodeKey: PlanDivergence(
          nodeKey: row.nodeKey,
          reasons: [
            for (final reason in jsonDecode(row.reasons) as List)
              if (reason is String) reason,
          ],
          at: row.recordedAt,
          held: row.held,
        ),
    };
  }

  @override
  Future<void> record(
    String workspaceId,
    String orchestrationId,
    PlanDivergence divergence,
  ) async {
    final db = _dbs.of(workspaceId);
    await db
        .into(db.planDivergencesTable)
        .insertOnConflictUpdate(
          PlanDivergencesTableCompanion.insert(
            orchestrationId: orchestrationId,
            nodeKey: divergence.nodeKey,
            reasons: jsonEncode(divergence.reasons),
            held: divergence.held,
            recordedAt: divergence.at,
          ),
        );
  }

  @override
  Future<void> markResumed(
    String workspaceId,
    String orchestrationId,
    String nodeKey,
  ) async {
    final db = _dbs.of(workspaceId);
    await (db.update(db.planDivergencesTable)..where(
          (t) =>
              t.orchestrationId.equals(orchestrationId) &
              t.nodeKey.equals(nodeKey),
        ))
        .write(const PlanDivergencesTableCompanion(held: Value(false)));
  }
}
