import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';

/// Sends a user message to a channel and dispatches agents.
class SendChannelMessageUseCase {
  /// Creates a [SendChannelMessageUseCase].
  SendChannelMessageUseCase(this._messagingService);

  final MessagingPort _messagingService;

  /// Sends content to a conversation in the channel and dispatches mentioned
  /// agents. [conversationId] defaults to the channel's `main` conversation.
  Future<void> execute({
    required String content,
    required String channelId,
    required String workspaceId,
    String? conversationId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
  }) async {
    await _messagingService.sendAndDispatch(
      workspaceId,
      channelId,
      content,
      conversationId: conversationId,
      structuredMentions: structuredMentions,
      entityRefs: entityRefs,
    );
  }
}
