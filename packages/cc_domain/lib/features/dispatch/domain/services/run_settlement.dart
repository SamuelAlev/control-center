import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/run_end_reason.dart';

/// The one place a run's end is written and announced.
///
/// Every path that ends a run (the dispatch service's finish, failure and
/// stop, the dispatch session's own failure write, the silence watchdog, the
/// orphan reaper, the kill and `agent_run_log.completeIfActive` operations)
/// stamps its terminal row through [settle]. The write is the repository's
/// conditional `completeIfActive`, which only the first terminal writer wins;
/// the winner, and only the winner, publishes [AgentRunSettled] after the row
/// is written. That is what makes the event exactly-once per run without any
/// in-memory bookkeeping: a second stop, a late finish racing a stop, or the
/// reaper finding a row a live process already closed all write nothing and
/// publish nothing.
class RunSettlement {
  /// Creates a [RunSettlement] over [runLogs], publishing on [eventBus].
  const RunSettlement({required this.runLogs, required this.eventBus});

  /// The run-log store the terminal row is written to.
  final AgentRunLogRepository runLogs;

  /// Where [AgentRunSettled] goes. Null in narrow tests: the row is still
  /// written, nothing is announced.
  final DomainEventBus? eventBus;

  /// Writes [terminal] (a row carrying its terminal [RunStatus]) with
  /// [endReason] in the same write, and publishes [AgentRunSettled] when this
  /// write was the one that ended the run.
  ///
  /// Returns whether it was. [writeCost] is passed through to
  /// `completeIfActive`: false when the caller has no final usage report, so
  /// a separately written cost is kept. [limitResetsAt] is the provider's
  /// reset time for a run that ended on a usage limit.
  ///
  /// The event's requester is the run row's `requestedByUserId`, written
  /// when the run was dispatched: the person who started it, or null for a
  /// run the server started. No caller names it, so a run ended by a
  /// stranger to it (the reaper at boot, a person's kill) still names the
  /// person whose run it was, and `completeIfActive` never writes the
  /// column, so the terminal row a caller built cannot change it.
  ///
  /// A row with no workspace (none is written today) is ended but not
  /// announced: every settlement listener is workspace-scoped.
  ///
  /// A subagent's child row (role `sub`, or one with a parent run) is written
  /// the same way but publishes nothing: it ends inside its parent's run, and
  /// the parent's settlement is the run's end.
  Future<bool> settle(
    AgentRunLog terminal, {
    required RunEndReason endReason,
    bool writeCost = true,
    DateTime? limitResetsAt,
  }) async {
    if (terminal.status != RunStatus.completed &&
        terminal.status != RunStatus.error) {
      throw ArgumentError.value(
        terminal.status,
        'terminal.status',
        'a settlement writes a terminal status',
      );
    }
    final won = await runLogs.completeIfActive(
      terminal.copyWith(endReason: endReason),
      writeCost: writeCost,
    );
    if (!won) {
      return false;
    }
    final bus = eventBus;
    final workspaceId = terminal.workspaceId;
    if (bus == null ||
        workspaceId == null ||
        workspaceId.isEmpty ||
        terminal.role == AgentRunRole.sub ||
        terminal.parentRunId != null) {
      return true;
    }
    // Read back what was just written: the cost a separate usage write
    // landed (writeCost: false keeps it), the child cost folded in by
    // subagents, the wake ids and the requester recorded at creation. A
    // failed read still announces the end from the row the caller wrote,
    // so a flaky store cannot swallow the one event every reader waits on.
    AgentRunLog row = terminal;
    try {
      row = await runLogs.getById(workspaceId, terminal.id) ?? terminal;
    } on Object {
      row = terminal;
    }
    bus.publish(
      AgentRunSettled(
        agentId: row.agentId,
        workspaceId: workspaceId,
        spaceId: row.spaceId,
        conversationId: row.conversationId,
        runId: row.id,
        status: terminal.status,
        endReason: endReason,
        costMicros: row.totalCostMicrosWithChildren,
        limitResetsAt: endReason == RunEndReason.usageLimit
            ? limitResetsAt
            : null,
        wakeIds: row.wakeIds,
        requestedByUserId: row.requestedByUserId,
        wakeReason: row.wakeReason,
        occurredAt: DateTime.now(),
      ),
    );
    return true;
  }
}
