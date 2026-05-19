import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/conversation_repository.dart';
import 'package:cc_server_core/src/review_fix_dispatch.dart';
import 'package:test/test.dart';

/// Pins the "send these PR-review findings to an agent" path to the MESSAGING
/// lane.
///
/// It used to call `AgentDispatchService.dispatch` directly, which starts the
/// process but creates no `agent_turn` message row and never consumes the
/// returned event stream: the fix conversation rendered empty while its run log
/// sat at `pending` forever. Everything the operator could see said "an agent
/// is working" and nothing they could read ever changed.
void main() {
  group('buildReviewFixDispatch', () {
    test(
      'posts the brief and dispatches into the named conversation',
      () async {
        final messaging = _RecordingMessagingPort();
        final conversations = _FakeConversationRepository();
        final dispatch = buildReviewFixDispatch(
          messaging: messaging,
          conversations: conversations,
        );

        await dispatch(
          workspaceId: 'ws-1',
          agentId: 'agent-1',
          prompt: 'Address the following review findings.',
          spaceId: 'space-1',
          conversationId: 'conv-fix',
          requestedByUserId: 'user-1',
        );

        // The human's brief lands in the conversation, attributed to them.
        expect(messaging.userMessages, hasLength(1));
        expect(messaging.userMessages.single, {
          'workspaceId': 'ws-1',
          'spaceId': 'space-1',
          'content': 'Address the following review findings.',
          'senderUserId': 'user-1',
          'conversationId': 'conv-fix',
        });

        // ...and the run is dispatched into the SAME conversation, through the
        // messaging path that creates the turn row and consumes the stream.
        expect(messaging.dispatches, hasLength(1));
        expect(messaging.dispatches.single, {
          'workspaceId': 'ws-1',
          'spaceId': 'space-1',
          'agentId': 'agent-1',
          'prompt': 'Address the following review findings.',
          'conversationId': 'conv-fix',
          'requestedByUserId': 'user-1',
        });

        // A named conversation is used as-is; nothing is minted for it.
        expect(conversations.ensureCalls, isEmpty);
      },
    );

    test(
      'falls back to the space standing conversation, never the space id',
      () async {
        final messaging = _RecordingMessagingPort();
        final conversations = _FakeConversationRepository();
        final dispatch = buildReviewFixDispatch(
          messaging: messaging,
          conversations: conversations,
        );

        await dispatch(
          workspaceId: 'ws-1',
          agentId: 'agent-1',
          prompt: 'Fix it.',
          spaceId: 'space-1',
        );

        expect(conversations.ensureCalls, [('ws-1', 'space-1')]);
        expect(
          messaging.userMessages.single['conversationId'],
          'standing-conv',
        );
        expect(messaging.dispatches.single['conversationId'], 'standing-conv');
        // Conversation ids are their own uuids — the space id names no row.
        expect(messaging.dispatches.single['conversationId'], isNot('space-1'));
      },
    );

    test('attributes to the owner when no acting user is known', () async {
      final messaging = _RecordingMessagingPort();
      final dispatch = buildReviewFixDispatch(
        messaging: messaging,
        conversations: _FakeConversationRepository(),
      );

      await dispatch(
        workspaceId: 'ws-1',
        agentId: 'agent-1',
        prompt: 'Fix it.',
        spaceId: 'space-1',
        conversationId: 'conv-fix',
      );

      // Null is passed through rather than a sentinel: the messaging service
      // resolves it to the server owner.
      expect(messaging.userMessages.single['senderUserId'], isNull);
      expect(messaging.dispatches.single['requestedByUserId'], isNull);
    });
  });
}

class _RecordingMessagingPort implements MessagingPort {
  final List<Map<String, dynamic>> userMessages = [];
  final List<Map<String, dynamic>> dispatches = [];

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String spaceId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    userMessages.add({
      'workspaceId': workspaceId,
      'spaceId': spaceId,
      'content': content,
      'senderUserId': senderUserId,
      'conversationId': conversationId,
    });
  }

  @override
  Future<String?> dispatchAgent({
    required String workspaceId,
    required String spaceId,
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
    dispatches.add({
      'workspaceId': workspaceId,
      'spaceId': spaceId,
      'agentId': agentId,
      'prompt': prompt,
      'conversationId': conversationId,
      'requestedByUserId': requestedByUserId,
    });
    return 'run-1';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');

  /// Context and branch surfaces this fake does not exercise.
  @override
  Future<ConversationShakeResult> shakeConversation({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    String target = 'tool_output',
  }) async => const ConversationShakeResult();

  @override
  Future<ConversationSideChannelResult> askAside({
    required String workspaceId,
    required String spaceId,
    String? conversationId,
    required String kind,
    String input = '',
  }) async => const ConversationSideChannelResult();

  @override
  Future<GuidedGoalStepResult> guidedGoalStep({
    required String workspaceId,
    required String rough,
    List<String> transcript = const [],
  }) async => const GuidedGoalStepResult();
}

class _FakeConversationRepository implements ConversationRepository {
  final List<(String, String)> ensureCalls = [];

  @override
  Future<Conversation> ensure({
    required String workspaceId,
    required String spaceId,
  }) async {
    ensureCalls.add((workspaceId, spaceId));
    return Conversation(
      id: 'standing-conv',
      workspaceId: workspaceId,
      spaceId: spaceId,
      title: 'Main',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not stubbed');
}
