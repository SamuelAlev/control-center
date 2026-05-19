import 'package:control_center/features/messaging/domain/ports/messaging_port.dart';

class SendChannelMessageUseCase {
  SendChannelMessageUseCase(this._messagingService);

  final MessagingPort _messagingService;

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
