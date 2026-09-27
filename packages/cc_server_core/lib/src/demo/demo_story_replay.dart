import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_server_core/src/demo/demo_script.dart';
import 'package:cc_server_core/src/demo/demo_world.dart';
import 'package:uuid/uuid.dart';

/// Plays the fictional Helix peer turn through real workspace-scoped chat and
/// run-log persistence. Tool cards come exclusively from fixture data: this
/// service has no shell, file, git, model, or network executor.
class DemoStoryReplay {
  /// Creates the inert peer-turn publisher.
  DemoStoryReplay({
    required MessagingRepository messaging,
    required ConversationRepository conversations,
    required AgentRunLogRepository runLogs,
    DateTime Function()? now,
  }) : _messaging = messaging, // ignore: prefer_initializing_formals
       _conversations = conversations, // ignore: prefer_initializing_formals
       _runLogs = runLogs, // ignore: prefer_initializing_formals
       _now = now ?? DateTime.now;

  final MessagingRepository _messaging;
  final ConversationRepository _conversations;
  final AgentRunLogRepository _runLogs;
  final DateTime Function() _now;
  static const _uuid = Uuid();

  /// Persists Juno's read/edit/test turn only inside the visitor's actual
  /// Helix walkthrough. A marker sent in another room cannot inject messages
  /// there, nor can a second agent impersonate the reviewer who asked Juno.
  Future<void> playPeer(DemoPeerStep step, HarnessToolContext context) async {
    final workspaceId = context.workspaceId;
    final spaceId = context.spaceId;
    final conversationId = context.conversationId;
    if (workspaceId == null ||
        spaceId == null ||
        conversationId == null ||
        context.agentId != 'demo-agent-reviewer' ||
        step.agent != 'Juno') {
      throw StateError('Not a Helix reviewer walkthrough');
    }
    final space = await _messaging.getSpaceById(workspaceId, spaceId);
    final conversation = await _conversations.getById(
      workspaceId: workspaceId,
      conversationId: conversationId,
    );
    if (space?.name != kDemoAgentSpaceName ||
        conversation?.spaceId != spaceId ||
        conversation?.title != 'HX-124 · Shared run-group walkthrough') {
      throw StateError('Not the Helix walkthrough conversation');
    }

    final runId = '$workspaceId:demo-peer-${_uuid.v4()}';
    final startedAt = _now();
    final segments = <TranscriptSegment>[];
    final metadata = <String, dynamic>{
      'agentName': 'Juno',
      'streamComplete': false,
      'inReplyToAgentId': context.agentId,
      'inReplyToAgentName': 'Ravi',
      'segments': <Map<String, dynamic>>[],
    };
    await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      senderId: 'demo-agent-triage',
      senderType: 'agent',
      messageType: 'agent_turn',
      id: runId,
      content: '',
      metadata: metadata,
    );
    await _runLogs.upsert(
      AgentRunLog(
        id: runId,
        agentId: 'demo-agent-triage',
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        ticketId: '$workspaceId:HX-124',
        startedAt: startedAt,
        status: RunStatus.running,
        liveness: RunLiveness.alive,
        summary: 'Checking the fictional evalkit budget snapshot',
        adapter: 'cc-harness',
        modelId: 'anthropic/claude-sonnet-4-5',
      ),
    );
    for (var i = 0; i < step.tools.length; i++) {
      final tool = step.tools[i];
      final calledAt = _now();
      segments.add(
        ToolSegment(
          toolName: tool.tool,
          toolCallId: '$runId-tool-$i',
          inputs: tool.args,
          startedAt: calledAt,
        ),
      );
      await _messaging.updateMessage(
        workspaceId,
        runId,
        metadata: {...metadata, 'segments': encodeTranscript(segments)},
      );
      await Future<void>.delayed(const Duration(milliseconds: 380));
      segments[segments.length - 1] = ToolSegment(
        toolName: tool.tool,
        toolCallId: '$runId-tool-$i',
        inputs: tool.args,
        outputs: tool.result,
        status: tool.isError ? ToolSegmentStatus.error : ToolSegmentStatus.ok,
        startedAt: calledAt,
        durationMs: _now().difference(calledAt).inMilliseconds,
      );
      await _messaging.updateMessage(
        workspaceId,
        runId,
        metadata: {...metadata, 'segments': encodeTranscript(segments)},
      );
    }
    await Future<void>.delayed(const Duration(milliseconds: 380));
    segments.add(TextSegment(text: step.text, startedAt: _now()));
    await _messaging.updateMessage(
      workspaceId,
      runId,
      content: step.text,
      metadata: {
        ...metadata,
        'streamComplete': true,
        'outcome': 'completed',
        'segments': encodeTranscript(segments),
        'transcriptChars':
            step.text.length +
            step.tools.fold<int>(0, (sum, tool) => sum + tool.result.length),
      },
    );
    final completed = await _runLogs.getById(workspaceId, runId);
    if (completed != null) {
      await _runLogs.upsert(
        completed.copyWith(
          status: RunStatus.completed,
          completedAt: _now(),
          liveness: RunLiveness.productive,
          summary: 'Checked the fictional evalkit budget fix and pinged Ravi',
        ),
      );
    }
  }
}
