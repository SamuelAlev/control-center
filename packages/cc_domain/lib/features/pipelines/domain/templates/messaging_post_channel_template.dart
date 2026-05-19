import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the `messaging.postChannel` body.
///
/// Posts a message to a messaging channel. Reads `channelId` and `content`
/// from pipeline state (which may come from trigger payload or upstream
/// steps). Uses the MessagingPort abstraction so it works with any
/// messaging backend.
///
/// Optional keys:
/// - `channelId` — target channel. Required.
/// - `content` — message body with `{{key}}` substitution. Required.
void registerMessagingPostChannelBody(
  PipelineBodyRegistry registry, {
  required MessagingPort messagingPort,
}) {
  registry.registerBody(BuiltInBodyKeys.messagingPostChannel, (ctx) async {
    final channelId = ctx.requireString('channelId');
    final content = ctx.requireString('content');

    try {
      await messagingPort.sendUserMessage(channelId, content);
    } on Object catch (e) {
      return StepResult.failed(
        'messaging.postChannel: failed to send to $channelId: $e',
      );
    }

    return StepResult.ok(mutatedState: {
      'postedChannelId': channelId,
      'postedAt': DateTime.now().toIso8601String(),
    });
  });
}
