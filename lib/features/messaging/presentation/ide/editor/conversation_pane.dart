import 'dart:async';

import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/message_feed.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_header.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_input_bar.dart';
import 'package:control_center/features/messaging/presentation/widgets/steering_queue_list.dart';
import 'package:control_center/features/messaging/presentation/widgets/takeover_banner.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/pending_space_sends_provider.dart';
import 'package:control_center/features/presence/presentation/widgets/spotlight_banner.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer.dart'
    show composerHorizontalMargin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The chat editor tab: one conversation (stream) inside a space rendered as
/// the IDE editor's primary surface. A space can host several parallel
/// conversations — flat equals, one of which may be a thread anchored to a
/// message. [conversationId] selects which one this pane shows; null resolves
/// the space's standing conversation.
class ConversationPane extends ConsumerWidget {
  /// Creates a [ConversationPane].
  const ConversationPane({
    super.key,
    required this.spaceId,
    this.conversationId,
    this.onSelectConversation,
  });

  /// The space to render.
  final String spaceId;

  /// The conversation (stream) inside the space. Null ⇒ resolve the space's
  /// standing conversation (see [standingConversationIdProvider]).
  final String? conversationId;

  /// Called when the user opens another conversation from inside this pane
  /// (opening a thread, starting one) — the host maps it to opening/focusing
  /// that conversation's chat tab. Conversations are editor tabs; there is no
  /// in-pane switcher strip.
  final void Function(String conversationId)? onSelectConversation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final spacesAsync = workspaceId != null
        ? ref.watch(workspaceSpacesProvider(workspaceId))
        : ref.watch(spacesProvider);

    if (spacesAsync.isLoading) {
      return const Center(child: CcSpinner());
    }

    final space = spacesAsync.value?.where((c) => c.id == spaceId).firstOrNull;

    if (space == null) {
      return const _NoConversationState();
    }

    // A tab that names no conversation renders the space's standing one,
    // resolved server-side. There is deliberately no `?? spaceId` fallback:
    // that id names no conversation row, so the feed would be empty and the
    // first send would fail the message table's foreign key.
    final convId =
        conversationId ??
        ref.watch(standingConversationIdProvider(spaceId)).value;

    // The header keeps the space's name while the standing conversation
    // resolves — the pane must not blink out of existence on every open —
    // then shows the conversation's own title once one is open.
    if (convId == null) {
      return Column(
        children: [
          SpaceHeader(
            space: space,
            onManage: () => _handleManage(context, ref),
            onArchive: () => unawaited(_handleArchiveSpace(context, ref)),
          ),
          const CcDivider(),
          const Expanded(child: Center(child: CcSpinner())),
        ],
      );
    }

    final conversation =
        (ref.watch(spaceConversationsProvider(spaceId)).value ??
                const <Conversation>[])
            .where((c) => c.id == convId)
            .firstOrNull;

    return Column(
      children: [
        SpaceHeader(
          space: space,
          conversation: conversation,
          onManage: () => _handleManage(context, ref),
          onArchive: () => unawaited(_handleArchiveSpace(context, ref)),
        ),
        // Thread parent link: when this pane shows a thread, a compact row
        // points back at the anchor message's conversation.
        _ThreadParentLink(spaceId: spaceId, conversationId: convId),
        const CcDivider(),
        // Someone else is spotlighting this space (PRD 16 §5).
        SpotlightBanner(spaceId: spaceId),
        // A take-over of this space's worktree is active (PRD 16 §8).
        TakeoverBanner(spaceId: spaceId),
        Expanded(
          child: SpaceMessageFeed(
            key: ValueKey('feed-$convId'),
            spaceId: spaceId,
            conversationId: convId,
            onStartThread: (message) => _startThread(context, ref, message),
            // A thread opens exactly the way the switcher opens any
            // conversation — it IS one.
            onOpenThread: onSelectConversation,
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
                _SpaceProvisioningBanner(spaceId: spaceId),
                _TypingIndicator(spaceId: spaceId),
                // Queued steering cards: mid-run nudges the user typed while
                // an agent works, waiting to be injected. Between the trail
                // and the composer, where "what I asked for that hasn't
                // landed yet" is read at a glance — and drawn onto the
                // composer's top edge, so it owns its own insets rather than
                // being padded from here. Renders nothing when the
                // conversation's queue is empty.
                SteeringQueueList(spaceId: spaceId, conversationId: convId),
                SpaceInputBar(spaceId: spaceId, conversationId: convId),
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
      builder: (_) => ManageSpaceDialog(spaceId: spaceId),
    );
  }

  /// Archives the space — reversible, so no confirmation. The space leaves
  /// the sidebar and the URL drops back to the space list (its data still
  /// exists, so without navigation the pane would keep rendering a space the
  /// sidebar has already shelved); the archive trigger beside the sidebar's
  /// `+` restores it.
  Future<void> _handleArchiveSpace(BuildContext context, WidgetRef ref) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    await ref
        .read(messagingServiceProvider)
        .archiveSpace(ref.requireWorkspaceId(), spaceId);
    if (context.mounted && workspaceId != null) {
      // URL is the source of truth: drop back to the space list (no selection).
      GoRouter.of(context).go(spacesRoute(workspaceId));
    }
  }

  /// Opens a thread anchored to [anchor]: a fresh conversation seeded with the
  /// anchor message, then focuses its editor tab like the switcher's onSelect.
  Future<void> _startThread(
    BuildContext context,
    WidgetRef ref,
    Message anchor,
  ) async {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final controller = TextEditingController();
    final title = await showCcDialog<String>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.startThread,
        content: CcTextField(
          controller: controller,
          autofocus: true,
          hintText: l10n.conversationTitleOptionalHint,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    // Null is a cancel; an EMPTY title is a real choice — the thread starts
    // untitled and the title model names it after its first message.
    if (title == null) {
      return;
    }
    final conv = await ref
        .read(conversationRepositoryProvider)
        .create(
          workspaceId: workspaceId,
          spaceId: spaceId,
          title: title,
          anchorMessageId: anchor.id,
        );
    onSelectConversation?.call(conv.id);
  }
}

/// Renders a "↳ parent" link when [conversationId] is a thread: the anchor's
/// conversation title, tapping it navigates to the anchor message in the
/// parent stream. Renders nothing for ordinary conversations.
class _ThreadParentLink extends ConsumerWidget {
  const _ThreadParentLink({
    required this.spaceId,
    required this.conversationId,
  });

  final String spaceId;
  final String conversationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final conversations = workspaceId == null
        ? const <Conversation>[]
        : ref.watch(spaceConversationsProvider(spaceId)).value ??
              const <Conversation>[];
    final conv = conversations.where((c) => c.id == conversationId).firstOrNull;
    final anchorId = conv?.anchorMessageId;
    if (conv == null || anchorId == null) {
      return const SizedBox.shrink();
    }
    final anchor = workspaceId == null
        ? null
        : ref
              .watch(
                threadAnchorProvider((
                  workspaceId: workspaceId,
                  anchorMessageId: anchorId,
                )),
              )
              .value;
    final parent = anchor == null
        ? null
        : conversations.where((c) => c.id == anchor.conversationId).firstOrNull;
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final excerpt = anchor == null
        ? ''
        : (anchor.content.length > 60
              ? '${anchor.content.substring(0, 60)}…'
              : anchor.content);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: workspaceId == null
            ? null
            : () => GoRouter.of(
                context,
              ).go(spaceRoute(workspaceId, spaceId, messageId: anchorId)),
        child: Container(
          width: double.infinity,
          color: ds.bgSecondary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xxs,
          ),
          child: Row(
            children: [
              Icon(AppIcons.gitBranch, size: 12, color: ds.fgTertiary),
              const SizedBox(width: AppSpacing.xxs),
              Expanded(
                child: Text(
                  parent == null
                      ? excerpt
                      : '${conversationDisplayName(parent, AppLocalizations.of(context))} — $excerpt',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: ds.fgTertiary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown when the pane's space id no longer resolves (deleted / stale id).
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

/// Status strip above the composer while the space's conversation workspace
/// is provisioning, was stopped, or failed. Hidden when ready.
///
/// Every variant aligns to the composer box below: the progress line starts its
/// spinner on the composer's left border and the tinted stopped/failed card
/// spans exactly the composer's width, so the strip reads as attached to the
/// composer rather than to the pane.
class _SpaceProvisioningBanner extends ConsumerWidget {
  const _SpaceProvisioningBanner({required this.spaceId});

  final String spaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(spaceProvisioningStatusProvider(spaceId));
    if (status == SpaceProvisioningStatus.ready) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();

    if (status.isStopped) {
      // Stopped and failed share the shape (a retry unblocks both) and differ
      // in voice: nothing broke when the operator stopped it, so that variant
      // stays neutral rather than shouting in danger red.
      final wasCancelled = status == SpaceProvisioningStatus.cancelled;
      final tint = wasCancelled ? ds.fgSecondary : ds.danger;
      return Container(
        margin: const EdgeInsets.symmetric(
          horizontal: composerHorizontalMargin,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        color: tint.withValues(alpha: 0.08),
        child: Row(
          children: [
            Icon(
              wasCancelled ? AppIcons.circleStop : AppIcons.triangleAlert,
              size: 16,
              color: tint,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                wasCancelled
                    ? l10n.workspacePrepStopped
                    : l10n.workspacePrepFailed,
                style: TextStyle(
                  color: tint,
                  fontSize: 13,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () =>
                  ref.read(retrySpaceProvisioningProvider)(spaceId),
              child: Text(l10n.retry),
            ),
          ],
        ),
      );
    }

    // provisioning
    final pendingCount = ref.watch(pendingSpaceSendsProvider(spaceId)).length;
    final step = ref.watch(spaceProvisioningStepProvider(spaceId));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: composerHorizontalMargin,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const CcSpinner(size: 14),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              provisioningStepLabel(l10n, step),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ds.fgSecondary,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          if (pendingCount > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                l10n.messageWillSendWhenReady(pendingCount),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ds.fgTertiary,
                  fontSize: 12,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ],
          const Spacer(),
          // Cloning a large repo is minutes of work with nothing to do but
          // wait, and it is not always the repo you meant. The stop is here,
          // next to what it stops.
          CcIconButton(
            icon: AppIcons.circleStop,
            tooltip: l10n.stopWorkspacePrepTooltip,
            onPressed: () => _confirmStop(context, ref, l10n),
          ),
        ],
      ),
    );
  }

  /// Confirms, then stops the space's preparation. Confirmed because it
  /// discards a clone that may be minutes in — cheap to restart, but not free,
  /// and never what a mis-click should cost.
  Future<void> _confirmStop(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final cancel = ref.read(cancelSpaceProvisioningProvider);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.stopWorkspacePrep,
      message: l10n.stopWorkspacePrepConfirm,
      confirmLabel: l10n.stopWorkspacePrep,
      cancelLabel: l10n.cancel,
      danger: true,
    );
    if (confirmed) {
      await cancel(spaceId);
    }
  }
}

/// Slim "`<name>` is typing…" line above the composer when another HUMAN is
/// typing in this space (PRD 16 §1). Agent "typing" is already conveyed by
/// their live status elsewhere, so this only surfaces human co-authors.
class _TypingIndicator extends ConsumerWidget {
  const _TypingIndicator({required this.spaceId});

  final String spaceId;

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
      if (p.typingInSpaceId == spaceId) {
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
