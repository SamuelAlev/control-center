import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Fallback safety net for pipeline-dispatched runs: when an agent finishes a
/// run without calling `submit_output`, this harvests a best-effort output onto
/// the run so the step can still resume with a payload.
///
/// - If the run declared an `expectedOutputSchema` but produced no
///   `outputJson`, the missing payload is left in place — the engine's harvest
///   will fail the step with a clear reason (free-form chat text cannot satisfy
///   a structured contract).
/// - If the run had no schema and no `outputJson`, the agent's last space
///   message is recorded as `{result: <message>}` so the step completes with a
///   best-effort payload instead of nothing.
///
/// The explicit `submit_output` path always wins (it writes `outputJson`
/// before the run ends); this only fills the gap when the agent never called it.
class AgentRunTaskCompleter {
  /// Creates an [AgentRunTaskCompleter].
  AgentRunTaskCompleter({
    required DomainEventBus eventBus,
    required AgentRunLogRepository runLogRepository,
    required MessagingRepository messagingRepository,
  }) : _eventBus = eventBus,
       _runLogs = runLogRepository,
       _messaging = messagingRepository;

  final DomainEventBus _eventBus;
  final AgentRunLogRepository _runLogs;
  final MessagingRepository _messaging;

  StreamSubscription<AgentRunCompleted>? _sub;

  /// Start listening for `AgentRunCompleted` events.
  void start() {
    _sub = _eventBus.on<AgentRunCompleted>().listen(_onCompleted);
  }

  /// Stop listening.
  void dispose() {
    _sub?.cancel();
  }

  Future<void> _onCompleted(AgentRunCompleted event) async {
    try {
      final runId = event.runId;
      final conversationId = event.conversationId;
      final workspaceId = event.workspaceId;
      // Without a workspace the run cannot be located: the workspace selects
      // the database the run and its messages live in.
      if (runId == null || conversationId == null || workspaceId == null) {
        return;
      }
      final run = await _runLogs.getById(workspaceId, runId);
      if (run == null) {
        return;
      }
      // Only pipeline-dispatched runs need a fallback payload.
      if (run.pipelineRunId == null || run.pipelineStepId == null) {
        return;
      }
      // Already has explicit output — nothing to do.
      if (run.outputJson != null) {
        return;
      }
      // The run is already recorded as failed: whatever it managed to say is
      // not a deliverable, and harvesting it would hand the step a payload that
      // makes a failure look like a result. (Best-effort — the terminal write
      // often lands after this event, which is why the emptiness check below
      // carries the load.)
      if (run.status == RunStatus.error) {
        return;
      }
      // A schema-declaring run cannot be satisfied by free-form text — let the
      // engine's harvest fail the step loudly with the real reason.
      if (run.expectedOutputSchema != null) {
        CcDomainLog.warning(
          'AgentRunTaskCompleter: Run ${run.id} ended without submit_output, but it requires '
          'structured output — leaving the step to fail on harvest.',
        );
        return;
      }
      // No schema, no output: harvest the agent's last message as a
      // best-effort payload.
      //
      // A run's SPACE and its CONVERSATION are different ids (a space holds
      // many conversations), so the conversation is named explicitly rather
      // than passed in the space slot. It used to be the space argument, which
      // only worked while the two were aliased to one value: once a space had
      // real conversations, the read tried to mint a standing conversation
      // whose `space_id` pointed at a conversation, SQLite refused the foreign
      // key (`INSERT OR IGNORE` does not cover FK violations) and every
      // fallback harvest died with it.
      final lastMessage = await _latestAgentMessage(
        run.workspaceId ?? workspaceId,
        run.spaceId,
        run.conversationId ?? conversationId,
        run.agentId,
      );
      // A run that said NOTHING has no output to harvest, and inventing one is
      // how a failed run reached the canvas as a green node. An agent that
      // dies before its first token — an expired credential, a denied command,
      // the silence watchdog — leaves no message, and `{result: ''}` is
      // indistinguishable downstream from a reviewer who genuinely found
      // nothing. Left null, the engine's own guard fails the step and says why.
      //
      // Note the status is deliberately NOT the test here: the terminal write
      // races this event (see `PipelineStepResumeListener`), so it usually
      // still reads `running` at this point. "Produced nothing" is a fact this
      // path can actually establish.
      if (lastMessage == null || lastMessage.trim().isEmpty) {
        CcDomainLog.warning(
          'AgentRunTaskCompleter: Run ${run.id} ended without submit_output and '
          'without any message to fall back on — leaving the step to fail on '
          'harvest.',
        );
        return;
      }
      CcDomainLog.warning(
        'AgentRunTaskCompleter: Harvesting last message for run ${run.id} — agent finished without '
        'calling submit_output. This is a fallback.',
      );
      await _runLogs.upsert(run.copyWith(outputJson: {'result': lastMessage}));
    } on Object catch (e, st) {
      CcDomainLog.error(
        'AgentRunTaskCompleter: Failed to harvest output for run ${event.runId}',
        e,
        st,
      );
    }
  }

  /// Returns the most recent agent-authored message content for [agentId] in
  /// [conversationId] of [workspaceId], or null if nothing matched.
  ///
  /// [spaceId] is only what the read would mint a standing conversation for,
  /// and naming [conversationId] means it never does — so a run whose space
  /// was never recorded still harvests instead of failing.
  Future<String?> _latestAgentMessage(
    String workspaceId,
    String? spaceId,
    String conversationId,
    String agentId,
  ) async {
    final messages = await _messaging.getMessages(
      workspaceId,
      spaceId ?? '',
      conversationId: conversationId,
    );
    Message? best;
    for (final m in messages) {
      if (m.senderId != agentId) {
        continue;
      }
      if (m.senderType != SenderType.agent) {
        continue;
      }
      if (best == null || m.createdAt.isAfter(best.createdAt)) {
        best = m;
      }
    }
    return best?.content;
  }
}
