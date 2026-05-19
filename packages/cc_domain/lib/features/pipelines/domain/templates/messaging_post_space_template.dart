import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the `messaging.postSpace` body.
///
/// Posts a message to a messaging space. Reads `spaceId` and `content`
/// from pipeline state (which may come from trigger payload or upstream
/// steps). Uses the MessagingPort abstraction so it works with any
/// messaging backend.
///
/// Optional keys:
/// - `spaceId` — target space. Required.
/// - `content` — message body with `{{key}}` substitution. Required.
void registerMessagingPostSpaceBody(
  PipelineBodyRegistry registry, {
  required MessagingPort messagingPort,
}) {
  registry.registerBody(BuiltInBodyKeys.messagingPostSpace, (ctx) async {
    final spaceId = ctx.requireString('space_id');
    final content = ctx.requireString('content');

    try {
      await messagingPort.sendUserMessage(ctx.workspaceId, spaceId, content);
    } on Object catch (e) {
      return StepResult.failed(
        'messaging.postSpace: failed to send to $spaceId: $e',
      );
    }

    return StepResult.ok(
      mutatedState: {
        'posted_space_id': spaceId,
        'posted_at': DateTime.now().toIso8601String(),
      },
    );
  });
}
