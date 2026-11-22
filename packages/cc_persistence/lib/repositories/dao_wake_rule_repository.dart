import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_persistence/database/cross_workspace_queries.dart';
import 'package:cc_persistence/database/daos/wake_rule_dao.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/database/workspace_database_manager.dart';
import 'package:cc_persistence/mappers/wake_rule_mapper.dart';
import 'package:cc_persistence/repositories/refused_rows.dart';
import 'package:drift/drift.dart';

/// Drift-backed [WakeRuleRepository].
///
/// Resolves `_dbs.of(workspaceId).wakeRuleDao` per call;
/// [insertWithinLimits] picks the file from the rule's own workspace.
/// [workspacesWithActiveRules] is the one read that spans files. Every
/// change after the insert is one conditional statement on the stored row.
/// A row the entity refuses is left out and reported through the warning
/// sink; one that has not ended is ended (`invalid_row`) by the read.
class DaoWakeRuleRepository implements WakeRuleRepository {
  /// Creates a [DaoWakeRuleRepository] over the per-workspace databases.
  /// `clock` stamps the `updated_at` of a refused rule a read ends.
  DaoWakeRuleRepository(this._dbs, {this._clock = DateTime.now})
    : _cross = CrossWorkspaceQueries(_dbs);

  final WorkspaceDatabaseManager _dbs;
  final CrossWorkspaceQueries _cross;
  final DateTime Function() _clock;
  final WakeRuleMapper _mapper = const WakeRuleMapper();

  static const _notEnded = ['active', 'paused'];

  WakeRuleDao _dao(String workspaceId) => _dbs.of(workspaceId).wakeRuleDao;

  Future<List<WakeRule>> _list(
    String workspaceId,
    Iterable<WakeRulesTableData> rows,
  ) => mapSettlingRefused(
    dbs: _dbs,
    workspaceId: workspaceId,
    repository: 'WakeRuleRepository',
    table: 'wake_rules',
    rows: rows,
    map: _mapper.tryToDomain,
    isOpen: (row) => _notEnded.contains(row.status),
    idOf: (row) => row.id,
    settle: (ids) async {
      var ended = 0;
      for (final id in ids) {
        if (await _dao(workspaceId).writeIf(
          id,
          (t) => t.status.isIn(_notEnded),
          WakeRulesTableCompanion(
            status: Value(WakeRuleStatus.ended.wire),
            endReason: Value(WakeRuleEndReason.invalidRow.wire),
            updatedAt: Value(_clock()),
          ),
        )) {
          ended++;
        }
      }
      return ended;
    },
    settledAs: 'ended (${WakeRuleEndReason.invalidRow.wire})',
  );

  static Set<String>? _wires(Set<WakeRuleStatus>? statuses) =>
      statuses == null ? null : {for (final s in statuses) s.wire};

  @override
  Future<WakeRuleLimit?> insertWithinLimits(
    WakeRule rule, {
    required int perConversation,
    required int perAgent,
    required int perWorkspace,
    required WakeLineageCap? lineage,
  }) {
    final db = _dbs.of(rule.workspaceId);
    // One transaction: the count and the insert see the same rows, so two
    // creates at once cannot both pass a limit.
    return db.transaction(() async {
      final open = await _list(
        rule.workspaceId,
        await db.wakeRuleDao.listNotEnded(),
      );
      final ofAgent = [
        for (final r in open)
          if (r.agentId == rule.agentId) r,
      ];
      if (ofAgent
              .where((r) => r.conversationId == rule.conversationId)
              .length >=
          perConversation) {
        return WakeRuleLimit.conversation;
      }
      if (ofAgent.length >= perAgent) {
        return WakeRuleLimit.agent;
      }
      if (open.length >= perWorkspace) {
        return WakeRuleLimit.workspace;
      }
      if (lineage != null) {
        final spent = await db.wakeRuleDao.lineageTotals(lineage.rootRuleId);
        if (spent.runs >= lineage.maxRuns ||
            spent.costMicros >= lineage.costCapMicros) {
          return WakeRuleLimit.lineage;
        }
      }
      await db.wakeRuleDao.insert(_mapper.toCompanion(rule));
      return null;
    });
  }

  @override
  Future<WakeLineageTotals> lineageTotals(
    String workspaceId,
    String rootRuleId,
  ) => _dao(workspaceId).lineageTotals(rootRuleId);

  @override
  Future<bool> recordFire(
    String workspaceId, {
    required String id,
    required int costMicrosDelta,
    required DateTime? nextFireAt,
    required DateTime firedAt,
  }) {
    _nonNegative(costMicrosDelta, 'costMicrosDelta');
    final table = _dao(workspaceId).wakeRulesTable;
    return _dao(workspaceId).writeIf(
      id,
      (t) => t.status.equals(WakeRuleStatus.active.wire),
      WakeRulesTableCompanion.custom(
        runCount: table.runCount + const Constant(1),
        costMicros: table.costMicros + Variable(costMicrosDelta),
        lastFiredAt: Variable(firedAt),
        nextFireAt: Variable(nextFireAt),
        updatedAt: Variable(firedAt),
      ),
    );
  }

  @override
  Future<bool> recordLoopFire(
    String workspaceId, {
    required String id,
    required DateTime firedAt,
  }) {
    final table = _dao(workspaceId).wakeRulesTable;
    return _dao(workspaceId).writeIf(
      id,
      (t) =>
          t.status.equals(WakeRuleStatus.active.wire) &
          t.triggerKind.equals(SelfPaced.kindName),
      WakeRulesTableCompanion.custom(
        runCount: table.runCount + const Constant(1),
        lastFiredAt: Variable(firedAt),
        updatedAt: Variable(firedAt),
      ),
    );
  }

  @override
  Future<bool> setNextAfterRun(
    String workspaceId, {
    required String id,
    required DateTime? delivered,
    required DateTime nextFireAt,
    required DateTime now,
  }) => _dao(workspaceId).writeIf(
    id,
    (t) =>
        t.status.equals(WakeRuleStatus.active.wire) &
        t.triggerKind.equals(SelfPaced.kindName) &
        (delivered == null
            ? t.nextFireAt.isNull()
            : t.nextFireAt.isNull() | t.nextFireAt.equals(delivered)),
    WakeRulesTableCompanion(
      nextFireAt: Value(nextFireAt),
      nextDelaySeconds: const Value(null),
      updatedAt: Value(now),
    ),
  );

  @override
  Future<bool> recordSkip(
    String workspaceId, {
    required String id,
    required DateTime? nextFireAt,
    required DateTime now,
  }) {
    final table = _dao(workspaceId).wakeRulesTable;
    return _dao(workspaceId).writeIf(
      id,
      (t) => t.status.equals(WakeRuleStatus.active.wire),
      WakeRulesTableCompanion.custom(
        skipCount: table.skipCount + const Constant(1),
        nextFireAt: Variable(nextFireAt),
        updatedAt: Variable(now),
      ),
    );
  }

  @override
  Future<int?> addCost(
    String workspaceId, {
    required String id,
    required int micros,
    required DateTime now,
  }) {
    _nonNegative(micros, 'micros');
    return _dao(workspaceId).addCost(id, micros, now);
  }

  @override
  Future<bool> setNext(
    String workspaceId, {
    required String id,
    required DateTime? nextFireAt,
    required int? nextDelaySeconds,
    required DateTime now,
  }) {
    if (nextDelaySeconds != null &&
        (nextDelaySeconds < SelfPaced.minDelay.inSeconds ||
            nextDelaySeconds > SelfPaced.maxDelay.inSeconds)) {
      throw ArgumentError.value(
        nextDelaySeconds,
        'nextDelaySeconds',
        'must be ${SelfPaced.minDelay.inSeconds} to '
            '${SelfPaced.maxDelay.inSeconds} seconds',
      );
    }
    return _dao(workspaceId).writeIf(
      id,
      (t) =>
          t.status.isIn(_notEnded) &
          (nextDelaySeconds == null
              ? const Constant(true)
              : t.triggerKind.equals(SelfPaced.kindName)),
      WakeRulesTableCompanion(
        nextFireAt: Value(nextFireAt),
        nextDelaySeconds: Value(nextDelaySeconds),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<bool> transition(
    String workspaceId, {
    required String id,
    required Set<WakeRuleStatus> from,
    required WakeRuleStatus to,
    required WakeRuleEndReason? endReason,
    required DateTime now,
  }) {
    if ((to == WakeRuleStatus.ended) != (endReason != null)) {
      throw ArgumentError.value(
        endReason,
        'endReason',
        'is set exactly when the rule ends',
      );
    }
    if (from.isEmpty) {
      return Future.value(false);
    }
    return _dao(workspaceId).writeIf(
      id,
      (t) => t.status.isIn([for (final s in from) s.wire]),
      WakeRulesTableCompanion(
        status: Value(to.wire),
        endReason: Value(endReason?.wire),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<bool> setTerms(
    String workspaceId, {
    required String id,
    required String note,
    required WakeWhenBusy whenBusy,
    required String? noteEditedByUserId,
    required DateTime now,
  }) {
    if (note.length > WakeRule.maxNoteLength) {
      throw ArgumentError.value(
        note.length,
        'note',
        'must be at most ${WakeRule.maxNoteLength} characters',
      );
    }
    return _dao(workspaceId).writeIf(
      id,
      (t) => t.status.isIn(_notEnded),
      WakeRulesTableCompanion(
        note: Value(note),
        whenBusy: Value(whenBusy.wire),
        noteEditedByUserId: noteEditedByUserId == null
            ? const Value.absent()
            : Value(noteEditedByUserId),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<bool> setLimits(
    String workspaceId, {
    required String id,
    required DateTime expiresAt,
    required int? maxRuns,
    required int costCapMicros,
    required DateTime now,
  }) {
    if (maxRuns != null && maxRuns <= 0) {
      throw ArgumentError.value(maxRuns, 'maxRuns', 'must be positive');
    }
    if (costCapMicros <= 0) {
      throw ArgumentError.value(
        costCapMicros,
        'costCapMicros',
        'must be positive',
      );
    }
    return _dao(workspaceId).writeIf(
      id,
      (t) =>
          t.status.isIn(_notEnded) &
          t.createdAt.isSmallerOrEqualValue(expiresAt),
      WakeRulesTableCompanion(
        expiresAt: Value(expiresAt),
        maxRuns: Value(maxRuns),
        costCapMicros: Value(costCapMicros),
        updatedAt: Value(now),
      ),
    );
  }

  static void _nonNegative(int value, String name) {
    if (value < 0) {
      throw ArgumentError.value(value, name, 'must not be negative');
    }
  }

  @override
  Future<WakeRule?> getById(String workspaceId, String id) async {
    final row = await _dao(workspaceId).getById(id);
    return row == null ? null : (await _list(workspaceId, [row])).firstOrNull;
  }

  @override
  Future<List<WakeRule>> listForConversation(
    String workspaceId,
    String conversationId, {
    Set<WakeRuleStatus>? statuses,
  }) async => _list(
    workspaceId,
    await _dao(
      workspaceId,
    ).listForConversation(conversationId, statuses: _wires(statuses)),
  );

  @override
  Future<List<WakeRule>> listForAgent(
    String workspaceId,
    String agentId, {
    Set<WakeRuleStatus>? statuses,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listForAgent(agentId, statuses: _wires(statuses)),
  );

  @override
  Future<List<WakeRule>> listActiveByEvent(
    String workspaceId,
    WakeEventKind kind,
  ) async =>
      _list(workspaceId, await _dao(workspaceId).listActiveByEvent(kind.wire));

  @override
  Future<List<WakeRule>> listCreatedByRun(
    String workspaceId, {
    required String conversationId,
    required String agentId,
    required String runId,
  }) async => _list(
    workspaceId,
    await _dao(workspaceId).listCreatedByRun(
      conversationId: conversationId,
      agentId: agentId,
      runId: runId,
    ),
  );

  @override
  Future<List<WakeRule>> listByGoal(String workspaceId, String goalId) async =>
      _list(workspaceId, await _dao(workspaceId).listByGoal(goalId));

  @override
  Future<List<WakeRule>> listByRoot(
    String workspaceId,
    String rootRuleId,
  ) async =>
      _list(workspaceId, await _dao(workspaceId).listByRoot(rootRuleId));

  @override
  Future<List<WakeRule>> listByRequester(
    String workspaceId,
    String userId,
  ) async =>
      _list(workspaceId, await _dao(workspaceId).listByRequester(userId));

  @override
  Future<List<WakeRule>> listActive(String workspaceId) async =>
      _list(workspaceId, await _dao(workspaceId).listActive());

  @override
  Future<int> countActive(
    String workspaceId, {
    String? agentId,
    String? conversationId,
  }) async {
    // Counted from the mapped rows, so a refused rule (ended by this read)
    // never counts.
    final rules = await _list(
      workspaceId,
      await _dao(
        workspaceId,
      ).listActive(agentId: agentId, conversationId: conversationId),
    );
    return rules.length;
  }

  @override
  Stream<List<WakeRule>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _dao(workspaceId)
      .watchForConversation(conversationId)
      .asyncMap((rows) => _list(workspaceId, rows));

  @override
  Stream<List<WakeRule>> watchForWorkspace(String workspaceId) =>
      _dao(workspaceId).watchAll().asyncMap((rows) => _list(workspaceId, rows));

  @override
  Future<bool> delete(String workspaceId, String id) =>
      _dao(workspaceId).deleteById(id);

  /// CROSS-WORKSPACE BY DESIGN: the rule service re-arms every active rule
  /// at boot; everything it then reads or writes is workspace-scoped.
  /// Read-only workspaces are skipped (every fire there would fail to
  /// write).
  @override
  Future<List<String>> workspacesWithActiveRules() async {
    final ids = await _cross.fanOut(
      (db) async =>
          await db.wakeRuleDao.hasActiveRules() ? db.workspaceId : null,
      backgroundWriter: 'wake rules',
    );
    return [for (final id in ids) ?id];
  }
}
