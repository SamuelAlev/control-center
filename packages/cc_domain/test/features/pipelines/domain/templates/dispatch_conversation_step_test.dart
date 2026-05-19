import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/ports/agent_dispatch_port.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_process_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/dispatch_conversation_step.dart';
import 'package:test/test.dart';

class _FakeMessagingPort implements MessagingPort {
  _FakeMessagingPort({this.existingChannels = const {}});

  /// Channel ids `channelExists` reports as live.
  final Set<String> existingChannels;

  final List<String> createdChannels = [];
  final List<({String channelId, String agentId})> addedAgents = [];
  final List<bool> addRenameFlags = [];
  final List<({String channelId, String content})> userMessages = [];
  final List<({String channelId, String agentId})> dispatched = [];
  Mode? createdWithMode;

  /// Every workspace id the port was called with, so a test can assert the step
  /// threads ONE workspace through the whole conversation setup rather than
  /// mixing (which, against real databases, would write to two files).
  final Set<String> seenWorkspaceIds = {};

  @override
  Future<bool> channelExists(String workspaceId, String channelId) async {
    seenWorkspaceIds.add(workspaceId);
    return existingChannels.contains(channelId);
  }

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    List<String> repoIds = const [],
  }) async {
    seenWorkspaceIds.add(workspaceId);
    createdChannels.add(name);
    createdWithMode = mode;
    return Channel(
      id: 'hidden-${createdChannels.length}',
      name: name,
      workspaceId: workspaceId,
      pipelineRunId: pipelineRunId,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    addedAgents.add((channelId: channelId, agentId: agentId));
    addRenameFlags.add(renameForGroup);
  }

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    userMessages.add((channelId: channelId, content: content));
  }

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String channelId,
    required String agentId,
    required String prompt,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    String? requestedByUserId,
    WakeContext? wakeContext,
    String? conversationId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    seenWorkspaceIds.add(workspaceId);
    dispatched.add((channelId: channelId, agentId: agentId));
    return 'run-${dispatched.length}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _FakeAgentDispatchPort implements AgentDispatchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

class _FakeRunRepository implements PipelineRunRepository {
  final List<({String stepRunId, String? channelId})> linked = [];

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    Object? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    linked.add((stepRunId: stepRunId, channelId: channelId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('${invocation.memberName} not stubbed');
}

const _ctx = PipelineContext(
  pipelineRunId: 'run-1',
  templateId: 'orchestration_plan_p1',
  stepId: 'sub_a',
  stepRunId: 'steprun-1',
  workspaceId: 'ws-1',
  state: {},
);

void main() {
  group('dispatchConversationStep — where the work lands', () {
    test(
      'runs in the configured conversation instead of a hidden one',
      () async {
        final messaging = _FakeMessagingPort(existingChannels: {'chan-plan'});
        final runs = _FakeRunRepository();

        final result = await dispatchConversationStep(
          ctx: _ctx,
          messagingPort: messaging,
          agentDispatchPort: _FakeAgentDispatchPort(),
          stepProcessRegistry: StepProcessRegistry(),
          runRepository: runs,
          agentIds: ['agent-1'],
          prompt: 'Do the work',
          label: 'Step one',
          channelId: 'chan-plan',
        );

        expect(
          messaging.createdChannels,
          isEmpty,
          reason:
              'the plan\'s room must be reused, not shadowed by a hidden one',
        );
        expect(messaging.userMessages.single.channelId, 'chan-plan');
        expect(messaging.dispatched.single.channelId, 'chan-plan');
        // The agent joins the room's roster (so the channel sidebar shows it),
        // without renaming the operator's conversation; the step-run links back.
        expect(messaging.addedAgents.single, (
          channelId: 'chan-plan',
          agentId: 'agent-1',
        ));
        expect(messaging.addRenameFlags, [false]);
        expect(runs.linked.single.channelId, 'chan-plan');
        expect(result.suspendUntilTaskIds, ['run-1']);
      },
    );

    test(
      'falls back to a hidden conversation when no channel is configured',
      () async {
        final messaging = _FakeMessagingPort();

        await dispatchConversationStep(
          ctx: _ctx,
          messagingPort: messaging,
          agentDispatchPort: _FakeAgentDispatchPort(),
          stepProcessRegistry: StepProcessRegistry(),
          runRepository: _FakeRunRepository(),
          agentIds: ['agent-1'],
          prompt: 'Do the work',
          label: 'Step one',
          mode: Mode.chat,
        );

        expect(messaging.createdChannels, ['Step one']);
        expect(messaging.createdWithMode, Mode.chat);
        expect(messaging.dispatched.single.channelId, 'hidden-1');
        expect(messaging.addedAgents, isEmpty);
      },
    );

    test(
      'falls back to a hidden conversation when the configured room is gone',
      () async {
        // The operator deleted the plan's channel after authoring it: the step must
        // still run rather than write against a missing row.
        final messaging = _FakeMessagingPort();

        await dispatchConversationStep(
          ctx: _ctx,
          messagingPort: messaging,
          agentDispatchPort: _FakeAgentDispatchPort(),
          stepProcessRegistry: StepProcessRegistry(),
          runRepository: _FakeRunRepository(),
          agentIds: ['agent-1'],
          prompt: 'Do the work',
          channelId: 'chan-deleted',
        );

        expect(messaging.createdChannels, hasLength(1));
        expect(messaging.dispatched.single.channelId, 'hidden-1');
      },
    );
  });
}
