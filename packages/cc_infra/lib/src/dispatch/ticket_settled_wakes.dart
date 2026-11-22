import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/ticketing_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/agent_goal_run_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/peer_ask_text.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_frame.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verdict.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/ticketing/domain/repositories/ticket_repository.dart';
import 'package:cc_domain/features/ticketing/domain/value_objects/delegation_brief.dart';
import 'package:cc_infra/src/dispatch/peer_wakes.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';

/// The facts a completion wake carries about a finished run (plan section
/// 10, "The completion wake's shape"): its final message, a summary, and
/// whether a goal of the run passed verification.
class CompletionFacts {
  /// Reads facts over the run's message and its goals.
  const CompletionFacts({
    required this._messages,
    required this._runLogs,
    this._goals,
  });

  final MessagingRepository _messages;
  final AgentRunLogRepository _runLogs;
  final AgentGoalRunRepository? _goals;

  /// The final message of run [runId] (empty when it has none).
  Future<String> finalAnswer(String workspaceId, String runId) async {
    final message = await _messages.getMessageById(workspaceId, runId);
    return message == null ? '' : finalAnswerOf(message);
  }

  /// `true` when a goal of [run] (its agent, in its conversation, finished
  /// after the run started) completed with a passing verdict, `false` when
  /// its last verification did not pass, null when none ran.
  Future<bool?> verified(AgentRunLog run) async {
    final goals = _goals;
    final ws = run.workspaceId;
    final conversation = run.conversationId;
    if (goals == null || ws == null || conversation == null) {
      return null;
    }
    final candidates = [
      for (final goal in await goals.listByWorkspace(ws))
        if (goal.agentId == run.agentId &&
            goal.conversationId == conversation &&
            goal.verification != null &&
            !goal.updatedAt.isBefore(run.startedAt))
          goal,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final goal = candidates.firstOrNull;
    if (goal == null) {
      return null;
    }
    return goal.status == AgentGoalStatus.completed &&
        goal.verification?.verdict?.verdict == GoalVerdictOutcome.pass;
  }

  /// The run row, scoped to [workspaceId].
  Future<AgentRunLog?> run(String workspaceId, String runId) =>
      _runLogs.getById(workspaceId, runId);

  /// The latest run of [ticketId], scoped to [workspaceId].
  Future<AgentRunLog?> latestRunForTicket(
    String workspaceId,
    String ticketId,
  ) => _runLogs.latestForTicket(workspaceId, ticketId);
}

/// The `childCompleted` wake that tells [delegatorAgentId] in
/// [conversationId] that [workerAgentId]'s work ended. [status] is the
/// ticket's end (`completed`, `failed`, `cancelled`) or a member run's;
/// [payload] the worker's final message (cut to the payload limit). The
/// typed detail carries the summary, the artifacts, whether verification
/// passed and the brief's "done means".
Wake childCompletedWake({
  required String id,
  required String workspaceId,
  required String spaceId,
  required String conversationId,
  required String delegatorAgentId,
  required String workerAgentId,
  required String workerName,
  required String status,
  required String dedupKey,
  required DateTime now,
  String payload = '',
  String? ticketId,
  String? workerRunId,
  String? workerConversationId,
  String? delegatingRunId,
  String? requestedByUserId,
  String? summary,
  Map<String, List<String>> artifacts = const {},
  bool? verified,
  List<String> doneMeans = const [],
  Map<String, Object?> fields = const {},
}) {
  final shortSummary = summary == null || summary.trim().isEmpty
      ? null
      : cutWithNote(
          summary.trim(),
          PeerAskLimits.maxSummaryChars,
          where: 'the worker',
        );
  final known = {
    for (final MapEntry(:key, :value) in artifacts.entries)
      if (value.isNotEmpty) key: value,
  };
  return Wake(
    id: id,
    workspaceId: workspaceId,
    spaceId: spaceId,
    conversationId: conversationId,
    agentId: delegatorAgentId,
    reason: WakeReason.childCompleted,
    payload: cutWithNote(
      payload,
      Wake.maxPayloadLength,
      where: "the worker's conversation",
    ),
    detail: WakeDetail(
      ticketId: ticketId,
      sourceAgentId: workerAgentId,
      sourceRunId: workerRunId,
      sourceConversationId: workerConversationId,
      messageId: workerRunId,
      status: status,
      fields: {
        WakeFields.sourceAgentName: workerName,
        WakeFields.summary: ?shortSummary,
        if (known.isNotEmpty) WakeFields.artifacts: known,
        WakeFields.verified: ?verified,
        if (doneMeans.isNotEmpty) WakeFields.doneMeans: doneMeans,
        ...fields,
        // The completion continues the delegating run's chain of wakes.
        WakeFields.continuesRunId: ?delegatingRunId,
      },
    ),
    dedupKey: dedupKey,
    notBefore: now,
    requestedByUserId: requestedByUserId,
    createdAt: now,
  );
}

/// Wakes the agent that delegated a ticket when the ticket completes, fails
/// or is cancelled (plan section 10, defect 18): one `childCompleted` wake
/// (`ticket:<id>:settled`) in the conversation the ticket was delegated
/// from (`Ticket.delegatedFromConversationId`), for whoever the delegating
/// run acted for (read from that run's row; null for a bot run).
class TicketSettledWakes {
  /// Creates the listener. [sink] is late-bound (the wake queue is built
  /// after the ticket workflow).
  TicketSettledWakes({
    required this._tickets,
    required this._agents,
    required this._conversations,
    required this._facts,
    this._clock = DateTime.now,
  });

  final TicketRepository _tickets;
  final AgentRepository _agents;
  final ConversationRepository _conversations;
  final CompletionFacts _facts;
  final DateTime Function() _clock;
  final List<StreamSubscription<Object>> _subs = [];

  /// Where the wakes go; null inserts nothing.
  Future<bool> Function(Wake wake)? sink;

  /// The ticket metadata key naming the run that delegated it.
  static const String delegatingRunKey = 'delegatedByRunId';

  /// Starts listening on [eventBus].
  void start(DomainEventBus eventBus) {
    _subs
      ..add(
        eventBus.on<TicketCompleted>().listen(
          (e) => unawaited(_guarded(e.workspaceId, e.ticketId, 'completed')),
        ),
      )
      ..add(
        eventBus.on<TicketFailed>().listen(
          (e) => unawaited(_guarded(e.workspaceId, e.ticketId, 'failed')),
        ),
      )
      ..add(
        eventBus.on<TicketCancelled>().listen(
          (e) => unawaited(_guarded(e.workspaceId, e.ticketId, 'cancelled')),
        ),
      );
  }

  /// Stops listening.
  Future<void> stop() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }

  Future<void> _guarded(String ws, String ticketId, String status) async {
    try {
      await onTicketSettled(ws, ticketId, status);
    } on Object catch (e, st) {
      CcInfraLog.error(
        'ticket settled wakes: ticket $ticketId ($status) failed: $e',
        e,
        st,
      );
    }
  }

  /// Wakes [ticketId]'s delegator with [status]; true when a wake was
  /// written (false for a ticket nobody delegated from a conversation, or
  /// a second time).
  Future<bool> onTicketSettled(
    String workspaceId,
    String ticketId,
    String status,
  ) async {
    final sink = this.sink;
    final ticket = await _tickets.getById(workspaceId, ticketId);
    if (sink == null || ticket == null || ticket.workspaceId != workspaceId) {
      return false;
    }
    final delegator = ticket.delegatedByAgentId;
    final conversationId = ticket.delegatedFromConversationId;
    final worker = ticket.assignedAgentId;
    if (delegator == null || conversationId == null || worker == null) {
      return false;
    }
    final conversation = await _conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (conversation == null) {
      return false;
    }
    final run = await _facts.latestRunForTicket(workspaceId, ticketId);
    final answer = run == null
        ? ''
        : await _facts.finalAnswer(workspaceId, run.id);
    final delegatingRun = switch (ticket.metadata[delegatingRunKey]) {
      final String id when id.isNotEmpty => await _facts.run(workspaceId, id),
      _ => null,
    };
    final now = _clock();
    return sink(
      childCompletedWake(
        id: 'ticket-$ticketId-settled',
        workspaceId: workspaceId,
        spaceId: conversation.spaceId,
        conversationId: conversationId,
        delegatorAgentId: delegator,
        workerAgentId: worker,
        workerName:
            (await _agents.getById(workspaceId, worker))?.name ?? worker,
        status: status,
        dedupKey: 'ticket:$ticketId:settled',
        now: now,
        payload: status == 'failed' ? (ticket.errorMessage ?? answer) : answer,
        ticketId: ticketId,
        workerRunId: run?.id,
        workerConversationId: run?.conversationId,
        delegatingRunId: delegatingRun?.id,
        requestedByUserId: delegatingRun?.agentId == delegator
            ? delegatingRun?.requestedByUserId
            : null,
        summary: status == 'failed'
            ? ticket.errorMessage
            : (run?.summary ?? answer),
        artifacts: {'pullRequests': ticket.linkedPrIds},
        verified: run == null ? null : await _facts.verified(run),
        doneMeans:
            DelegationBrief.fromMetadata(ticket.metadata)?.doneMeans ??
            const [],
      ),
    );
  }
}
