import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/infrastructure/speech/speech_transcriber_providers.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_feed.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/queued_messages_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/agent_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/channel_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/file_mention_source.dart';
import 'package:control_center/shared/widgets/composer/mention/sources/scratchpad_mention_source.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The "Activity" tab: the live discussion feed for the ticket's channel plus
/// a rich composer for talking to (and dispatching) agents. When the ticket
/// has no channel yet, shows a hint to assign an agent.
class TicketActivityTab extends StatelessWidget {
  /// Creates a [TicketActivityTab].
  const TicketActivityTab({super.key, required this.ticket});

  /// The ticket being viewed.
  final Ticket ticket;

  @override
  Widget build(BuildContext context) {
    final channelId = ticket.channelId;
    if (channelId == null) {
      return const _NoDiscussion();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        children: [
          Expanded(child: ChannelMessageFeed(channelId: channelId)),
          _CommentBar(ticket: ticket),
        ],
      ),
    );
  }
}

class _NoDiscussion extends StatelessWidget {
  const _NoDiscussion();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.messagesSquare, size: 32, color: t.fgQuaternary),
          const SizedBox(height: 10),
          Text(
            l10n.assignTo,
            style: TextStyle(color: t.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Rich composer for the ticket discussion: `@mention` an agent to dispatch
/// them, voice dictation, and file attachments — the same input used across
/// channel and thread chat, so talking to agents feels identical everywhere.
class _CommentBar extends ConsumerWidget {
  const _CommentBar({required this.ticket});
  final Ticket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final channelId = ticket.channelId;
    if (channelId == null) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final workspaceId = ticket.workspaceId;

    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const [];
    final channels =
        ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const [];
    final List<Repo> repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value ?? const [];
    final fileSearch = ref.watch(fileSearchProvider);
    final transcriber = ref.watch(speechTranscriberProvider);

    final sources = <MentionSource>[
      AgentMentionSource(agents),
      ChannelMentionSource([
        for (final c in channels)
          ChannelMentionItem(id: c.id, name: c.name, isDm: c.isDm),
      ]),
      ScratchpadMentionSource(workspaceId: workspaceId),
      if (repos.isNotEmpty)
        FileMentionSource(
          search: fileSearch,
          roots: [for (final r in repos) r.path],
        ),
    ];

    final key = (workspaceId: workspaceId, conversationId: channelId);
    final isBusy = ref.watch(conversationBusyProvider(key));
    final queued = ref.watch(queuedMessagesProvider(key));

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (queued.isNotEmpty)
            _QueuedStrip(
              messages: queued,
              onRemove: (i) =>
                  ref.read(queuedMessagesProvider(key).notifier).removeAt(i),
            ),
          Composer(
            sources: sources,
            hint: l10n.ticketDispatchHint,
            transcriber: transcriber,
            isBusy: isBusy,
            onStop: isBusy ? () => _stop(ref, key) : null,
            onSubmit: (submission) => _handleSubmit(ref, key, submission),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit(
    WidgetRef ref,
    ConversationRunsKey key,
    ComposerSubmission submission,
  ) async {
    final buffer = StringBuffer(submission.text.trim());
    for (final a in submission.attachments) {
      if (a.kind == 'file' && a.path != null) {
        if (buffer.isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write(a.path);
      }
    }
    final content = buffer.toString().trim();
    if (content.isEmpty) {
      return;
    }
    // While an agent is still working, park the message and let it dispatch
    // when the conversation next goes idle. Otherwise send immediately.
    if (ref.read(conversationBusyProvider(key))) {
      ref.read(queuedMessagesProvider(key).notifier).enqueue(content);
      return;
    }
    await ref.read(messagingServiceProvider).sendAndDispatch(
          key.conversationId,
          content,
          workspaceId: key.workspaceId,
        );
  }

  Future<void> _stop(WidgetRef ref, ConversationRunsKey key) async {
    final runs =
        ref.read(conversationActiveRunsProvider(key)).asData?.value ?? const [];
    if (runs.isEmpty) {
      return;
    }
    await ref
        .read(messagingServiceProvider)
        .stopRuns(runs.map((r) => r.id).toList());
  }
}

/// A compact strip above the composer listing messages queued while an agent
/// is busy, each removable before it is dispatched.
class _QueuedStrip extends StatelessWidget {
  const _QueuedStrip({required this.messages, required this.onRemove});

  final List<String> messages;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < messages.length; i++)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
              decoration: BoxDecoration(
                color: t.bgSecondary,
                borderRadius: AppRadii.brSm,
                border: Border.all(color: t.borderSecondary),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.clock, size: 13, color: t.fgQuaternary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      messages[i],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: t.textSecondary),
                    ),
                  ),
                  FTooltip(
                    tipBuilder: (_, _) => Text(l10n.removeQueuedMessage),
                    child: IconButton(
                      icon: Icon(
                        LucideIcons.x,
                        size: 14,
                        color: t.fgQuaternary,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: () => onRemove(i),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
