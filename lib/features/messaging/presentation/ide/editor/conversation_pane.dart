import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_feed.dart';
import 'package:control_center/features/messaging/presentation/widgets/thread_panel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chat editor tab: a single conversation rendered as the IDE editor's
/// primary surface.
///
/// Extracted verbatim from the legacy private `_ActiveChannelPane`. The header
/// actions that used to toggle side panels now *focus* editor tabs / sidebar
/// sections instead — the chrome lives outside this pane (editor tabs + the IDE
/// sidebar), so toggling local state would be a lie.
class ConversationPane extends ConsumerWidget {
  /// Creates a [ConversationPane].
  const ConversationPane({
    super.key,
    required this.channelId,
    required this.onFocusTerminal,
    required this.onFocusSourceControl,
  });

  /// The conversation to render.
  final String channelId;

  /// Focus (or open) the editor's terminal tab.
  final VoidCallback onFocusTerminal;

  /// Switch the IDE sidebar to the Source Control tab.
  final VoidCallback onFocusSourceControl;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channelsAsync = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId))
        : ref.watch(channelsProvider);

    if (channelsAsync.isLoading) {
      return const Center(child: CcSpinner());
    }

    final channel = channelsAsync.value
        ?.where((c) => c.id == channelId)
        .firstOrNull;

    if (channel == null) {
      return const _NoConversationState();
    }

    final threadParentId = ref.watch(selectedThreadMessageIdProvider);

    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              ChannelHeader(
                channel: channel,
                onManage: () => _handleManage(context, ref, channel.isDm),
                onDelete: () => _handleDeleteChannel(context, ref),
                // The terminal/changes panels now live in editor tabs / the
                // sidebar. Keep the header params wired so the buttons still
                // appear; route them to *focus* actions rather than local
                // toggles.
                onToggleTerminal: onFocusTerminal,
                terminalOpen: false,
                onToggleChanges: onFocusSourceControl,
                changesOpen: false,
              ),
              const Divider(height: 1),
              Expanded(
                child: ChannelMessageFeed(
                  key: ValueKey('feed-$channelId'),
                  channelId: channelId,
                  onReplyInThread: (messageId) {
                    ref.read(selectedThreadMessageIdProvider.notifier).state =
                        messageId;
                  },
                ),
              ),
              const Divider(height: 1),
              // Composer aligns with the centered message column.
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: conversationColumnWidth,
                  ),
                  child: ChannelInputBar(channelId: channelId),
                ),
              ),
            ],
          ),
        ),
        if (threadParentId != null)
          ThreadPanel(
            channelId: channelId,
            parentMessageId: threadParentId,
            onClose: () {
              ref.read(selectedThreadMessageIdProvider.notifier).state = null;
            },
          ),
      ],
    );
  }

  void _handleManage(BuildContext context, WidgetRef ref, bool isDm) {
    showDialog(
      context: context,
      builder: (_) => ManageChannelDialog(channelId: channelId, isDm: isDm),
    );
  }

  Future<void> _handleDeleteChannel(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteConversation,
        content: Text(l10n.deleteConversationConfirm),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          CcButton(
            variant: CcButtonVariant.destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    await ref.read(messagingServiceProvider).deleteChannel(channelId);
    if (context.mounted) {
      ref.read(selectedChannelIdProvider.notifier).select(null);
    }
  }
}

/// Shown when the pane's channel id no longer resolves (deleted / stale id).
class _NoConversationState extends StatelessWidget {
  const _NoConversationState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.messageSquareDashed,
            size: 56,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(l10n.selectConversation, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
