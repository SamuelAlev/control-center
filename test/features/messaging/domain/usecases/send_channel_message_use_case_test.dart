import 'package:cc_domain/core/domain/value_objects/conversation_mode.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/usecases/send_channel_message_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeMessagingPort implements MessagingPort {
  @override
  Future<void> retryAgentTurn({
    required String channelId,
    required String failedMessageId,
  }) async {}

  final List<_SendCall> sendCalls = [];
  final List<_DispatchCall> dispatchCalls = [];

  @override
  Future<void> sendUserMessage(String channelId, String content) async {
    sendCalls.add(_SendCall(channelId: channelId, content: content));
  }

  @override
  Future<void> addAgentToChannel(String channelId, String agentId) async {}

  @override
  Future<bool> channelExists(String channelId) async => true;

  @override
  Future<void> refinePlan({
    required String channelId,
    required String feedback,
    String? workspaceId,
  }) async {}

  Future<void> setChannelMode(String channelId, ConversationMode mode) async {}

  @override
  Future<Channel> createGroup(
    String name,
    List<String> agentIds, {
    ConversationMode mode = ConversationMode.chat,
    String? workspaceId,
  String? pipelineRunId,
    }) async => throw UnimplementedError();

  @override
  Future<void> sendAndDispatch(
    String channelId,
    String content, {
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<dynamic>? entityRefs,
    String? parentMessageId,
  }) async {
    sendCalls.add(_SendCall(channelId: channelId, content: content));
  }

  @override
  Future<String?> dispatchAgent({
    required String channelId,
    required String agentId,
    required String prompt,
    String? workspaceId,
    String? ticketId,
    String? pipelineRunId,
    String? pipelineStepId,
    String? inReplyToAgentId,
    WakeContext? wakeContext,
    String? parentMessageId,
    Map<String, dynamic>? expectedOutputSchema,
    OutputContractMode outputContractMode = OutputContractMode.strict,
  }) async {
    dispatchCalls.add(
      _DispatchCall(
        channelId: channelId,
        agentId: agentId,
        prompt: prompt,
      ),
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
      await useCase.execute(content: 'Hello world', channelId: 'ch-1');

      expect(port.sendCalls.length, 1);
      expect(port.sendCalls.first.channelId, 'ch-1');
      expect(port.sendCalls.first.content, 'Hello world');
    });

    test('passes channelId and content correctly', () async {
      await useCase.execute(
        content: '@Architect review this',
        channelId: 'ch-42',
      );

      expect(port.sendCalls.first.channelId, 'ch-42');
      expect(port.sendCalls.first.content, '@Architect review this');
    });

    test('handles empty content', () async {
      await useCase.execute(content: '', channelId: 'ch-1');

      expect(port.sendCalls.length, 1);
    });
  });
}
