import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:drift/drift.dart';

/// Maps between [WakeRule] and `wake_rules` rows.
///
/// The trigger is stored flat in the `trigger_*` columns. Drift reads a
/// `dateTime()` column back as a local time in whole seconds; every time
/// is turned back into UTC here (slots are whole seconds already). A row the entity or
/// its trigger refuses reads as null and is left out of lists.
class WakeRuleMapper {
  /// Creates a [WakeRuleMapper].
  const WakeRuleMapper();

  /// The rule [row] holds, or null when it is not a valid rule.
  WakeRule? tryToDomain(WakeRulesTableData row) {
    final deliver = WakeDeliverWire.tryParse(row.deliver);
    final whenBusy = WakeWhenBusyWire.tryParse(row.whenBusy);
    final origin = WakeRuleOriginWire.tryParse(row.origin);
    final status = WakeRuleStatusWire.tryParse(row.status);
    final endReason = WakeRuleEndReasonWire.tryParse(row.endReason);
    if (deliver == null ||
        whenBusy == null ||
        origin == null ||
        status == null ||
        (row.endReason != null && endReason == null)) {
      return null;
    }
    try {
      final trigger = _trigger(row);
      if (trigger == null) {
        return null;
      }
      return WakeRule(
        id: row.id,
        workspaceId: row.workspaceId,
        spaceId: row.spaceId,
        conversationId: row.conversationId,
        agentId: row.agentId,
        trigger: trigger,
        note: row.note,
        deliver: deliver,
        whenBusy: whenBusy,
        maxRuns: row.maxRuns,
        costCapMicros: row.costCapMicros,
        expiresAt: row.expiresAt.toUtc(),
        runCount: row.runCount,
        skipCount: row.skipCount,
        costMicros: row.costMicros,
        lastFiredAt: row.lastFiredAt?.toUtc(),
        nextFireAt: row.nextFireAt?.toUtc(),
        nextDelaySeconds: row.nextDelaySeconds,
        goalId: row.goalId,
        rootRuleId: row.rootRuleId,
        origin: origin,
        createdByRunId: row.createdByRunId,
        createdByUserId: row.createdByUserId,
        requestedByUserId: row.requestedByUserId,
        noteEditedByUserId: row.noteEditedByUserId,
        status: status,
        endReason: endReason,
        createdAt: row.createdAt.toUtc(),
        updatedAt: row.updatedAt.toUtc(),
      );
    } on ArgumentError {
      return null;
    }
  }

  static WakeTrigger? _trigger(WakeRulesTableData row) {
    switch (row.triggerKind) {
      case OnceAt.kindName:
        final at = row.triggerAt;
        return at == null ? null : OnceAt(at.toUtc());
      case Every.kindName:
        final seconds = row.intervalSeconds;
        return seconds == null ? null : Every(Duration(seconds: seconds));
      case Cron.kindName:
        final expression = row.cronExpression;
        final timeZone = row.timeZone;
        return expression == null || timeZone == null
            ? null
            : Cron(expression, timeZone);
      case SelfPaced.kindName:
        return const SelfPaced();
      case OnEvent.kindName:
        final kind = WakeEventKindWire.tryParse(row.eventKind);
        return kind == null ? null : OnEvent(kind, targetId: row.eventTargetId);
    }
    return null;
  }

  /// The valid rules among [rows], in order.
  List<WakeRule> toDomainList(Iterable<WakeRulesTableData> rows) => [
    for (final row in rows) ?tryToDomain(row),
  ];

  /// Every column of [rule], the trigger flattened.
  WakeRulesTableCompanion toCompanion(WakeRule rule) {
    final trigger = rule.trigger;
    return WakeRulesTableCompanion(
      id: Value(rule.id),
      workspaceId: Value(rule.workspaceId),
      spaceId: Value(rule.spaceId),
      conversationId: Value(rule.conversationId),
      agentId: Value(rule.agentId),
      triggerKind: Value(trigger.kind),
      triggerAt: Value(trigger is OnceAt ? trigger.at : null),
      intervalSeconds: Value(
        trigger is Every ? trigger.interval.inSeconds : null,
      ),
      cronExpression: Value(trigger is Cron ? trigger.expression : null),
      timeZone: Value(trigger is Cron ? trigger.timeZone : null),
      eventKind: Value(trigger is OnEvent ? trigger.eventKind.wire : null),
      eventTargetId: Value(trigger is OnEvent ? trigger.targetId : null),
      note: Value(rule.note),
      deliver: Value(rule.deliver.wire),
      whenBusy: Value(rule.whenBusy.wire),
      maxRuns: Value(rule.maxRuns),
      costCapMicros: Value(rule.costCapMicros),
      expiresAt: Value(rule.expiresAt),
      runCount: Value(rule.runCount),
      skipCount: Value(rule.skipCount),
      costMicros: Value(rule.costMicros),
      lastFiredAt: Value(rule.lastFiredAt),
      nextFireAt: Value(rule.nextFireAt),
      nextDelaySeconds: Value(rule.nextDelaySeconds),
      goalId: Value(rule.goalId),
      rootRuleId: Value(rule.rootRuleId),
      origin: Value(rule.origin.wire),
      createdByRunId: Value(rule.createdByRunId),
      createdByUserId: Value(rule.createdByUserId),
      requestedByUserId: Value(rule.requestedByUserId),
      noteEditedByUserId: Value(rule.noteEditedByUserId),
      status: Value(rule.status.wire),
      endReason: Value(rule.endReason?.wire),
      createdAt: Value(rule.createdAt),
      updatedAt: Value(rule.updatedAt),
    );
  }
}
