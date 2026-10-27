import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_harness/slash_command.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/messaging_mention_sources.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/messaging_slash_commands.dart';
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
/// A message typed while an agent is already working — attachments included —
/// becomes a queued steering card. Anything else is sent immediately, or
/// parked while the space is still provisioning.
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
  final command = _analyticsCommand(parsedCommand);
  if (dispatched == null) {
    ref.track(
      AnalyticsEvents.slashCommandRun(
        command: command ?? 'none',
        workspaceId: workspaceId,
        spaceId: spaceId,
      ),
    );
    return;
  }
  final content = dispatched;
  void trackSent(String delivery) => ref.track(
    AnalyticsEvents.messageSent(
      workspaceId: workspaceId,
      spaceId: spaceId,
      conversationId: conversationId,
      delivery: delivery,
      charCount: content.length,
      attachmentCount: submission.attachments.length,
      agentMentionCount: submission.mentions
          .where((m) => m.kind == 'agent')
          .length,
      otherMentionCount: submission.mentions
          .where((m) => m.kind != 'agent')
          .length,
      slashCommand: command,
    ),
  );

  // Mid-run steering: if agents are already working in this conversation and
  // the user submits a conversational message (no @agent, no slash command),
  // the submission becomes a QUEUED STEERING CARD (the strip below the trail)
  // instead of a new turn — the server persists it as a conversation row, live
  // harness runs inject it at their next turn boundary, and anything still
  // queued when the last run ends is converted to a normal message.
  // Files were uploaded on insertion; queued steering reuses their catalog
  // ids without moving bytes again.
  // No toast: the card appearing in the strip IS the feedback.
  final hasAgentMention = submission.mentions.any((m) => m.kind == 'agent');
  if (!parsedCommand.isCommand &&
      !hasAgentMention &&
      (content.trim().isNotEmpty || submission.attachments.isNotEmpty)) {
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
      final attachmentRefs = ref
          .read(spaceMessageSendProvider.notifier)
          .attachmentMetadata(submission.attachments);
      final port = ref.read(messagingServiceProvider);
      final queued = await port.enqueueSteering(
        workspaceId: workspaceId,
        spaceId: spaceId,
        conversationId: conversationId,
        content: content,
        attachments: attachmentRefs,
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
        trackSent(AnalyticsEvents.messageDeliverySteer);
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
          workspaceId: workspaceId,
          structuredMentions: structured,
          entityRefs: entityRefs,
          attachments: submission.attachments,
        );
    trackSent(AnalyticsEvents.messageDeliveryQueued);
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
  trackSent(AnalyticsEvents.messageDeliverySend);
}

/// The slash command's analytics name: built-in and composer commands by
/// name, skills as `skill`, anything else (a repo's own command, whose name
/// can say what the project is) as `custom`. Null when there is no command.
String? _analyticsCommand(ParsedSlashCommand parsed) {
  final name = parsed.command;
  if (name == null) {
    return null;
  }
  if (name.startsWith(skillCommandPrefix)) {
    return 'skill';
  }
  if (harnessBuiltinCommands.contains(name) ||
      kMessagingSlashCommands.any((c) => c.name == name)) {
    return name;
  }
  return 'custom';
}

/// The message text as it is STORED — references intact.
///
/// Uploaded files retain their inline references; the server resolves the
/// catalog-backed blob references at dispatch time. A repository-file mention
/// is already a server-side checkout path and stays a reference. Its
/// out-of-band path is appended only when there is no inline reference.
String _renderContent(ComposerSubmission submission) {
  final text = submission.text.trim();
  final named = {for (final match in findFileRefs(text)) match.name};
  final buffer = StringBuffer(text);
  for (final a in submission.attachments) {
    if (a.payload != null &&
        a.kind == 'file' &&
        a.path != null &&
        !named.contains(a.refName)) {
      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer.write(a.path);
    }
  }
  return buffer.toString();
}
