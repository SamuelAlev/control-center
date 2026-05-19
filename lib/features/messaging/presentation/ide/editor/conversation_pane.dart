import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/channel_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_input_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_message_feed.dart';
import 'package:control_center/features/messaging/presentation/widgets/conversation_switcher.dart';
import 'package:control_center/features/messaging/presentation/widgets/takeover_banner.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_channel_sends_provider.dart';
import 'package:control_center/features/presence/presentation/widgets/spotlight_banner.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer.dart'
    show composerHorizontalMargin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The chat editor tab: one conversation (stream) inside a channel rendered as
/// the IDE editor's primary surface. A channel can host several parallel
/// conversations ("parentheses"); [conversationId] selects which one this pane
/// shows (defaults to `main`, whose id equals the channel id).
class ConversationPane extends ConsumerWidget {
  /// Creates a [ConversationPane].
  const ConversationPane({
    super.key,
    required this.channelId,
    this.conversationId,
    this.onSelectConversation,
  });

  /// The channel to render.
  final String channelId;

  /// The conversation (stream) inside the channel. Null ⇒ `main` (== channel
  /// id).
  final String? conversationId;

  /// Called when the user picks a conversation in the switcher — the host maps
  /// it to opening/focusing that conversation's chat tab. Null ⇒ the switcher
  /// still creates parentheses but selecting is a visual no-op.
  final void Function(String conversationId)? onSelectConversation;

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

    final convId = conversationId ?? channelId;

    return Column(
      children: [
        ChannelHeader(
          channel: channel,
          onManage: () => _handleManage(context, ref),
          onDelete: () => _handleDeleteChannel(context, ref),
        ),
        // Conversation switcher: main + open parentheses + "new parenthesis".
        // Hidden when the channel has only its main conversation.
        ConversationSwitcher(
          channelId: channelId,
          activeConversationId: convId,
          onSelect: onSelectConversation,
        ),
        const CcDivider(),
        // Someone else is spotlighting this channel (PRD 16 §5).
        SpotlightBanner(channelId: channelId),
        // A take-over of this channel's worktree is active (PRD 16 §8).
        TakeoverBanner(channelId: channelId),
        Expanded(
          child: ChannelMessageFeed(
            key: ValueKey('feed-$convId'),
            channelId: channelId,
            conversationId: convId,
          ),
        ),
        const CcDivider(),
        // The provisioning banner, the typing line and the composer share ONE
        // centered-column wrapper so they can never drift apart: each status
        // line's text now starts on the composer's own left border instead of
        // hugging the pane edge (~65px further left on a wide pane).
        Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: conversationColumnWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _ChannelProvisioningBanner(channelId: channelId),
                _TypingIndicator(channelId: channelId),
                ChannelInputBar(channelId: channelId, conversationId: convId),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleManage(BuildContext context, WidgetRef ref) {
    showCcDialog<void>(
      context: context,
      builder: (_) => ManageChannelDialog(channelId: channelId),
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

    await ref
        .read(messagingServiceProvider)
        .deleteChannel(ref.requireWorkspaceId(), channelId);
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
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
          Text(
            l10n.selectConversation,
            style: CcTypography.title.copyWith(color: ds.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// Status strip above the composer while the channel's conversation workspace
/// is provisioning or has failed. Hidden when ready.
///
/// Both variants align to the composer box below: the bare progress line starts
/// its spinner on the composer's left border and the failed variant's tinted
/// card spans exactly the composer's width, so the strip reads as attached to
/// the composer rather than to the pane.
class _ChannelProvisioningBanner extends ConsumerWidget {
  const _ChannelProvisioningBanner({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(channelProvisioningStatusProvider(channelId));
    if (status == ChannelProvisioningStatus.ready) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();

    if (status == ChannelProvisioningStatus.failed) {
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: composerHorizontalMargin,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        color: ds.danger.withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(AppIcons.triangleAlert, size: 16, color: ds.danger),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.workspacePrepFailed,
                style: TextStyle(
                  color: ds.danger,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () =>
                  ref.read(retryChannelProvisioningProvider)(channelId),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    // provisioning
    final pendingCount = ref
        .watch(pendingChannelSendsProvider(channelId))
        .length;
    final step = ref.watch(channelProvisioningStepProvider(channelId));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: composerHorizontalMargin,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const CcSpinner(size: 14),
          const SizedBox(width: AppSpacing.xs),
          Text(
            provisioningStepLabel(l10n, step),
            style: TextStyle(
              color: ds.fgSecondary,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Text(
              l10n.messageWillSendWhenReady(pendingCount),
              style: TextStyle(
                color: ds.fgTertiary,
                fontSize: 12,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Slim "`<name>` is typing…" line above the composer when another HUMAN is
/// typing in this channel (PRD 16 §1). Agent "typing" is already conveyed by
/// their live status elsewhere, so this only surfaces human co-authors.
class _TypingIndicator extends ConsumerWidget {
  const _TypingIndicator({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final roster =
        ref.watch(presenceRosterProvider(workspaceId)).value ?? const [];
    final myUserId = ref.watch(currentUserIdProvider);

    String? typingName;
    for (final p in roster) {
      if (p.principal is! UserPrincipal) {
        continue;
      }
      if (p.principal.id == myUserId) {
        continue;
      }
      if (p.typingInChannelId == channelId) {
        typingName = p.displayName;
        break;
      }
    }
    if (typingName == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      // Starts on the composer's left border, like the provisioning line.
      padding: const EdgeInsets.fromLTRB(
        composerHorizontalMargin,
        0,
        composerHorizontalMargin,
        AppSpacing.xs,
      ),
      child: Text(
        l10n.typingIndicator(typingName),
        style: TextStyle(
          color: ds.fgTertiary,
          fontSize: 12,
          fontStyle: FontStyle.italic,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
