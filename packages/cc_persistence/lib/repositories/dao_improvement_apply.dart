import 'package:cc_domain/core/domain/entities/agent_working_memory.dart';
import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/features/dispatch/domain/ports/improvement_apply_port.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/improvement_values.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/repositories/dao_agent_working_memory_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_fact_repository.dart';
import 'package:cc_persistence/repositories/dao_memory_policy_repository.dart';
import 'package:drift/drift.dart';

/// Drift-backed [ImprovementApplyPort].
///
/// One transaction of the proposal's workspace database: the conditional
/// status write comes first (so this connection holds the writer), then the
/// target is read again and compared with the row the plan read, then the
/// write. A mismatch rolls the claim back. A fact is stored without a vector
/// inside the transaction (inference must not hold the writer) and embedded
/// right after it commits, through [_facts]' embedder.
class DaoImprovementApply implements ImprovementApplyPort {
  /// Creates the port over the workspaces' databases; `facts` is the fact
  /// repository with the server's embedder.
  DaoImprovementApply(this._dbs, {required this._facts})
    : _policies = DaoMemoryPolicyRepository(_dbs),
      _notes = DaoAgentWorkingMemoryRepository(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final DaoMemoryFactRepository _facts;
  final DaoMemoryPolicyRepository _policies;
  final DaoAgentWorkingMemoryRepository _notes;

  @override
  Future<ImprovementApplyOutcome> decideAndWrite(
    String workspaceId, {
    required String id,
    required ImprovementStatus from,
    required ImprovementStatus to,
    required String decidedByUserId,
    required String? beforeText,
    required String? afterText,
    required String? appliedRef,
    required DateTime now,
    required ImprovementTextWrite write,
  }) async {
    if (to == ImprovementStatus.proposed || to == from) {
      throw ArgumentError.value(to, 'to', 'must be another decided status');
    }
    final db = _dbs.of(workspaceId);
    final ImprovementApplyOutcome outcome;
    try {
      outcome = await db.transaction(() async {
        final claimed = await db.improvementProposalDao.writeIf(
          id,
          (t) => t.status.equals(from.wire),
          ImprovementProposalsTableCompanion(
            status: Value(to.wire),
            decidedByUserId: Value(decidedByUserId),
            decidedAt: Value(now),
            beforeText: Value.absentIfNull(beforeText),
            afterText: Value.absentIfNull(afterText),
            appliedRef: Value.absentIfNull(appliedRef),
          ),
        );
        if (!claimed) {
          return ImprovementApplyOutcome.alreadyDecided;
        }
        if (!await _stillAsRead(workspaceId, write)) {
          throw const _Changed();
        }
        await _apply(workspaceId, write);
        return ImprovementApplyOutcome.applied;
      });
    } on _Changed {
      return ImprovementApplyOutcome.changedSince;
    }
    if (outcome == ImprovementApplyOutcome.applied &&
        write is ImprovementFactWrite) {
      final factId = write.fact?.id;
      if (factId != null) {
        try {
          await _facts.embedIfMissing(workspaceId, factId);
        } on Object {
          // The decision stands; the backfill embeds the fact later.
        }
      }
    }
    return outcome;
  }

  Future<bool> _stillAsRead(String ws, ImprovementTextWrite write) async {
    switch (write) {
      case ImprovementFactWrite(:final expected, :final fact):
        final id = expected?.id ?? fact!.id;
        final current = await _facts.getById(ws, id);
        return _sameFact(current, expected);
      case ImprovementPolicyWrite(:final expected, :final policy):
        final id = expected?.id ?? policy!.id;
        final current = await _policies.getById(ws, id);
        return _samePolicy(current, expected);
      case ImprovementNoteWrite(:final expected, :final note):
        final current = await _notes.getByAgent(ws, note.agentId);
        return _sameNote(current, expected);
    }
  }

  Future<void> _apply(String ws, ImprovementTextWrite write) async {
    switch (write) {
      case ImprovementFactWrite(:final expected, :final fact):
        if (fact == null) {
          await _facts.delete(ws, expected!.id);
        } else {
          await _facts.writeUnembedded(fact);
        }
      case ImprovementPolicyWrite(:final expected, :final policy):
        if (policy == null) {
          await _policies.delete(ws, expected!.id);
        } else {
          await _policies.upsert(policy);
        }
      case ImprovementNoteWrite(:final note):
        await _notes.upsert(note);
    }
  }

  static bool _sameFact(MemoryFact? a, MemoryFact? b) => a == null || b == null
      ? a == b
      : a.workspaceId == b.workspaceId &&
            a.content == b.content &&
            a.supersededBy == b.supersededBy &&
            a.updatedAt.isAtSameMomentAs(b.updatedAt);

  static bool _samePolicy(MemoryPolicy? a, MemoryPolicy? b) =>
      a == null || b == null
      ? a == b
      : a.workspaceId == b.workspaceId &&
            a.rule == b.rule &&
            a.active == b.active &&
            a.updatedAt.isAtSameMomentAs(b.updatedAt);

  static bool _sameNote(AgentWorkingMemory? a, AgentWorkingMemory? b) =>
      a == null || b == null
      ? a == b
      : a.workspaceId == b.workspaceId &&
            a.content == b.content &&
            a.updatedAt.isAtSameMomentAs(b.updatedAt);
}

class _Changed implements Exception {
  const _Changed();
}
