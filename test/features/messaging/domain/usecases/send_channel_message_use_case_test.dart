import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_origin.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingPort implements MessagingPort {
  @override
  Future<void> retryAgentTurn({
    required String workspaceId,
    required String channelId,
    required String failedMessageId,
  }) async {}

  @override
  Future<ConversationCompactionResult> compactConversation({
    required String workspaceId,
    required String channelId,
    String? conversationId,
  }) async => const ConversationCompactionResult(
    status: ConversationCompactionStatus.unavailable,
  );

  final List<_SendCall> sendCalls = [];
  final List<_DispatchCall> dispatchCalls = [];

  @override
  Future<void> sendUserMessage(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    sendCalls.add(_SendCall(channelId: channelId, content: content));
  }

  @override
  Future<void> addAgentToChannel(
    String workspaceId,
    String channelId,
    String agentId, {
    bool renameForGroup = true,
  }) async {}

  @override
  Future<void> removeParticipant(
    String workspaceId,
    String channelId,
    String agentId,
  ) async {}

  @override
  Future<void> deleteChannel(String workspaceId, String channelId) async {}

  @override
  Future<void> clearChannelMessages(
    String workspaceId,
    String channelId,
  ) async {}

  @override
  Future<void> stopRun(String workspaceId, String runLogId) async {}

  @override
  Future<bool> pauseRun(String runLogId) async => false;

  @override
  Future<bool> resumeRun(String runLogId) async => false;

  @override
  Future<bool> steerRun(
    String runLogId,
    String message, {
    bool followUp = false,
  }) async => false;

  @override
  Future<bool> channelExists(String workspaceId, String channelId) async =>
      true;

  @override
  Future<void> refinePlan({
    required String workspaceId,
    required String channelId,
    required String feedback,
  }) async {}

  Future<void> setChannelMode(
    String workspaceId,
    String channelId,
    Mode mode,
  ) async {}

  @override
  Future<Channel> createChannel(
    String workspaceId,
    String name,
    List<String> agentIds, {
    Mode mode = Mode.chat,
    String? pipelineRunId,
    String? createdByUserId,
    ChannelOrigin origin = ChannelOrigin.user,
    List<String> repoIds = const [],
  }) async => throw UnimplementedError();

  @override
  Future<void> sendAndDispatch(
    String workspaceId,
    String channelId,
    String content, {
    String? senderUserId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? conversationId,
    Map<String, dynamic>? metadata,
  }) async {
    sendCalls.add(_SendCall(channelId: channelId, content: content));
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
    dispatchCalls.add(
      _DispatchCall(channelId: channelId, agentId: agentId, prompt: prompt),
    );
    return null;
  }
}

class _SendCall {
  _SendCall({required this.channelId, required this.content});
  final String channelId;
  final String content;
}

class _DispatchCall {
  _DispatchCall({
    required this.channelId,
    required this.agentId,
    required this.prompt,
  });
  final String channelId;
  final String agentId;
  final String prompt;
}

void main() {
  late _FakeMessagingPort port;
  late SendChannelMessageUseCase useCase;

  setUp(() {
    port = _FakeMessagingPort();
    useCase = SendChannelMessageUseCase(port);
  });

  group('execute', () {
    test('delegates to sendAndDispatch', () async {
      await useCase.execute(
        workspaceId: 'ws-1',
        content: 'Hello world',
        channelId: 'ch-1',
      );

      expect(port.sendCalls.length, 1);
      expect(port.sendCalls.first.channelId, 'ch-1');
      expect(port.sendCalls.first.content, 'Hello world');
    });

    test('passes channelId and content correctly', () async {
      await useCase.execute(
        workspaceId: 'ws-1',
        content: '@Architect review this',
        channelId: 'ch-42',
      );

      expect(port.sendCalls.first.channelId, 'ch-42');
      expect(port.sendCalls.first.content, '@Architect review this');
    });

    test('handles empty content', () async {
      await useCase.execute(
        workspaceId: 'ws-1',
        content: '',
        channelId: 'ch-1',
      );

      expect(port.sendCalls.length, 1);
    });
  });
}
