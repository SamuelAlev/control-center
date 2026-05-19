import 'dart:async';

import 'package:cc_domain/core/domain/entities/channel_message.dart';
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
/// - If the run had no schema and no `outputJson`, the agent's last channel
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
  })  : _eventBus = eventBus,
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
      if (runId == null || conversationId == null) {
        return;
      }
      final run = await _runLogs.getById(runId);
      if (run == null) {
        return;
      }
      // Only pipeline-dispatched runs need a fallback payload.
      if (run.pipelineRunId == null || run.pipelineStepRunId == null) {
        return;
      }
      // Already has explicit output — nothing to do.
      if (run.outputJson != null) {
        return;
      }
      // A schema-declaring run cannot be satisfied by free-form text — let the
      // engine's harvest fail the step loudly with the real reason.
      if (run.expectedOutputSchema != null) {
        CcDomainLog.warning('AgentRunTaskCompleter: Run ${run.id} ended without submit_output, but it requires '
          'structured output — leaving the step to fail on harvest.',
        );
        return;
      }
      // No schema, no output: harvest the agent's last message as a
      // best-effort payload.
      final lastMessage = await _latestAgentMessage(conversationId, run.agentId);
      CcDomainLog.warning('AgentRunTaskCompleter: Harvesting last message for run ${run.id} — agent finished without '
        'calling submit_output. This is a fallback.',
      );
      await _runLogs.upsert(
        run.copyWith(outputJson: {'result': lastMessage ?? ''}),
      );
    } on Object catch (e, st) {
      CcDomainLog.error('AgentRunTaskCompleter: Failed to harvest output for run ${event.runId}',
        e,
        st,
      );
    }
  }

  /// Returns the most recent agent-authored message content for [agentId]
  /// in [channelId], or null if nothing matched.
  Future<String?> _latestAgentMessage(
    String channelId,
    String agentId,
  ) async {
    final messages = await _messaging.getMessages(channelId);
    ChannelMessage? best;
    for (final m in messages) {
      if (m.senderId != agentId) {
        continue;
      }
      if (m.senderType != ChannelSenderType.agent) {
        continue;
      }
      if (best == null || m.createdAt.isAfter(best.createdAt)) {
        best = m;
      }
    }
    return best?.content;
  }
}
