import 'package:cc_domain/core/domain/value_objects/entity_ref.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';

/// Sends a user message to a channel and dispatches agents.
class SendChannelMessageUseCase {
  /// Creates a [SendChannelMessageUseCase].
  SendChannelMessageUseCase(this._messagingService);

  final MessagingPort _messagingService;

  /// Sends content to the channel and dispatches mentioned agents.
  Future<void> execute({
    required String content,
    required String channelId,
    String? workspaceId,
    List<StructuredMention>? structuredMentions,
    List<EntityRef>? entityRefs,
    String? parentMessageId,
  }) async {
    await _messagingService.sendAndDispatch(
      channelId,
      content,
      workspaceId: workspaceId,
      structuredMentions: structuredMentions,
      entityRefs: entityRefs,
      parentMessageId: parentMessageId,
    );
  }
}
