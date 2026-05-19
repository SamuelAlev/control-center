import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';

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
    String? parentMessageId,
  }) async {
    await _messagingService.sendAndDispatch(
      channelId,
      content,
      workspaceId: workspaceId,
      structuredMentions: structuredMentions,
      parentMessageId: parentMessageId,
    );
  }
}
