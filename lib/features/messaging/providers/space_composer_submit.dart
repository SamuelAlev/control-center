import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/messaging_mention_sources.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/space_local_command_dispatch.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_space_sends_provider.dart';
import 'package:control_center/features/messaging/providers/space_message_send_provider.dart';
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Sends what the space composer submitted.
///
/// Slash commands that the client handles itself never reach the server.
/// Plain text typed while an agent is already working becomes a queued
/// steering card. Anything else is sent immediately, or parked while the
/// space is still provisioning.
Future<void> submitSpaceComposer({
  required WidgetRef ref,
  required BuildContext context,
  required String spaceId,
  required String conversationId,
  required ComposerSubmission submission,
}) async {
  final rawContent = _renderContent(submission);
  final workspaceId = ref.requireWorkspaceId();

  final parsedCommand = parseSlashCommand(rawContent.trim());
  final dispatched = await dispatchLocalSlashCommand(
    ref: ref,
    context: context,
    parsed: parsedCommand,
    rawContent: rawContent,
    spaceId: spaceId,
    conversationId: conversationId,
    workspaceId: workspaceId,
  );
  if (dispatched == null) {
    return;
  }
  final content = dispatched;

  // Mid-run steering: if agents are already working in this conversation and
  // the user submits plain conversational text (no @agent, no slash command),
  // the submission becomes a QUEUED STEERING CARD (the strip below the trail)
  // instead of a new turn — the server persists it as a conversation row, live
  // harness runs inject it at their next turn boundary, and anything still
  // queued when the last run ends is converted to a normal message.
  // No toast: the card appearing in the strip IS the feedback.
  final hasAgentMention = submission.mentions.any((m) => m.kind == 'agent');
  if (!parsedCommand.isCommand &&
      !hasAgentMention &&
      submission.attachments.isEmpty &&
      content.trim().isNotEmpty) {
    final activeRuns =
        ref
            .read(
              conversationActiveRunsProvider((
                workspaceId: workspaceId,
                conversationId: conversationId,
              )),
            )
            .asData
            ?.value ??
        const [];
    if (activeRuns.isNotEmpty) {
      final port = ref.read(messagingServiceProvider);
      final queued = await port.enqueueSteering(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        content: content,
      );
      if (queued != null) {
        // Remember whether ANY live run can inject mid-run: the strip's
        // "steer now" button is hidden for external-CLI transports (their
        // cards wait for run end), and this is the one moment the answer is
        // authoritative.
        ref
            .read(
              steeringSteerableProvider((
                spaceId: spaceId,
                conversationId: conversationId,
              )).notifier,
            )
            .set(queued.steerable);
        return;
      }
      // The run ended between the read above and the enqueue — fall
      // through to a normal send.
    }
  }

  final structured = <StructuredMention>[
    for (final m in submission.mentions.where((m) => m.kind == 'agent'))
      if (m.payload?['agentId'] != null)
        StructuredMention(
          agentId: m.payload!['agentId'] as String,
          raw: '@${m.label}',
        ),
  ];
  final entityRefs = entityRefsFromMentions(submission.mentions);

  // Gate on provisioning: send now when ready, otherwise park the submission
  // until the background workspace setup completes. The queue auto-flushes on
  // the provisioning → ready transition.
  final status = ref.read(spaceProvisioningStatusProvider(spaceId));
  if (status != SpaceProvisioningStatus.ready) {
    ref
        .read(pendingSpaceSendsProvider(spaceId).notifier)
        .enqueue(
          content: content,
          structuredMentions: structured,
          entityRefs: entityRefs,
          attachments: submission.attachments,
        );
    return;
  }

  await ref
      .read(spaceMessageSendProvider.notifier)
      .send(
        content: content,
        spaceId: spaceId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        structuredMentions: structured,
        entityRefs: entityRefs,
        attachments: submission.attachments,
      );
}

/// The message text as it is STORED — references intact.
///
/// A `@[file:<name>]` token is not expanded here, and that is the point. This
/// client is routinely not the machine the agent runs on, so its paths mean
/// nothing on the far side; the bytes travel instead, and the server replaces
/// each token IN PLACE with the path it wrote them to. In place matters: the
/// position is the meaning — "compare ⟦before.png⟧ with ⟦after.png⟧"
/// collapses into nonsense if the paths are appended as a list at the end.
/// Keeping the token is also what makes the sent bubble read like the
/// composer did: the transcript draws it as the same chip.
///
/// Attachments carrying no reference — a scratchpad, or a picture attached by
/// a composer that inserts no token — keep the old trailing-line behaviour,
/// so nothing that used to reach the agent stops doing so.
String _renderContent(ComposerSubmission submission) {
  final text = submission.text.trim();
  final named = {for (final match in findFileRefs(text)) match.name};
  final buffer = StringBuffer(text);
  for (final a in submission.attachments) {
    if (a.kind == 'file' && a.path != null && !named.contains(a.refName)) {
      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer.write(a.path);
    }
  }
  return buffer.toString();
}
