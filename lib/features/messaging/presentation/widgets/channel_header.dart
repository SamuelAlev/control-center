import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel_participant.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_search_dialog.dart';
import 'package:control_center/features/messaging/presentation/widgets/context_meter_chip.dart';
import 'package:control_center/features/messaging/providers/channel_autonomy_provider.dart';
import 'package:control_center/features/messaging/providers/channel_checker_provider.dart';
import 'package:control_center/features/messaging/providers/channel_takeover_provider.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/presence/presentation/widgets/whos_here_strip.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Header bar displaying channel info and actions.
class ChannelHeader extends ConsumerWidget {
  /// Creates a new [ChannelHeader].
  const ChannelHeader({
    super.key,
    required this.channel,
    required this.onManage,
    required this.onDelete,
  });

  /// The channel to display.
  final Channel channel;

  /// Callback to manage participants.
  final VoidCallback onManage;

  /// Callback to delete the channel.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final participantsAsync = ref.watch(
      channelParticipantsProvider(channel.id),
    );
    final participants = participantsAsync.value ?? const [];
    // The wire never carries the "reverted" flag, so a session-scoped notifier
    // tracks whether this channel has a revert the user can still undo (redo).
    final hasUndoableRevert = ref.watch(
      channelHasUndoableRevertProvider(channel.id),
    );
    final agents = participants.where((p) => !p.isUser).toList();
    final l10n = AppLocalizations.of(context);

    final title = channel.name.isNotEmpty ? channel.name : l10n.channelLabel;
    final subtitle = agents.isEmpty
        ? l10n.noAgents
        : l10n.agentCount(agents.length, agents.length);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(AppIcons.users, size: 20, color: tokens.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // One line, always: the header is a fixed 56px band, so a long
                // channel name that wrapped pushed the subtitle past the bottom
                // edge (a 2px RenderFlex overflow). Truncate and disclose the
                // full name on hover instead of stealing a second line.
                CcTruncatedText(
                  title,
                  style: CcTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: CcTypography.caption.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Context-window telemetry for a single-agent channel (one agent ⇒
          // one context window to meter).
          if (agents.length == 1)
            ContextMeterChip(
              channelId: channel.id,
              agentId: agents.first.principalId,
            ),
          const SizedBox(width: 8),
          // Who else (human or agent) is here right now (PRD 16 §1–§3).
          // Renders nothing in solo mode or when nobody targets this channel.
          WhosHereStrip(channelId: channel.id),
          const SizedBox(width: 4),
          _PresentToggleButton(channelId: channel.id),
          const SizedBox(width: 4),
          _TakeoverButton(channelId: channel.id),
          const SizedBox(width: 4),
          if (hasUndoableRevert) ...[
            CcTooltip(
              targetAnchor: Alignment.bottomCenter,
              followerAnchor: Alignment.topCenter,
              message: l10n.undoRevert,
              child: CcIconButton(
                icon: AppIcons.rotateCw,
                semanticLabel: l10n.undoRevert,
                onPressed: () => _undoRevert(context, ref),
              ),
            ),
            const SizedBox(width: 4),
          ],
          const SizedBox(width: 4),
          CcTooltip(
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            message: l10n.searchInConversation,
            child: CcIconButton(
              icon: AppIcons.search,
              semanticLabel: l10n.searchInConversation,
              onPressed: () => showCcDialog<void>(
                context: context,
                builder: (_) => ChannelSearchDialog(channelId: channel.id),
              ),
            ),
          ),
          const SizedBox(width: 4),
          CcTooltip(
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            message: l10n.manageParticipants,
            child: CcIconButton(
              icon: AppIcons.users,
              semanticLabel: l10n.manageParticipants,
              onPressed: onManage,
            ),
          ),
          const SizedBox(width: 4),
          CcTooltip(
            targetAnchor: Alignment.bottomCenter,
            followerAnchor: Alignment.topCenter,
            message: l10n.deleteConversation,
            child: CcIconButton(
              icon: AppIcons.trash2,
              semanticLabel: l10n.deleteConversation,
              onPressed: onDelete,
            ),
          ),
        ],
      ),
    );
  }

  /// Undoes the most-recent revert in this conversation (redo): the latest
  /// reverted batch reappears in the live message stream. The toast handle is
  /// captured before the await so it survives the async gap.
  Future<void> _undoRevert(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    final count = await ref
        .read(conversationCheckpointControllerProvider)
        .unrevert(channel.id);
    toast?.show(
      count > 0 ? l10n.revertUndone : l10n.nothingToRevert,
      variant: count > 0 ? CcToastVariant.success : CcToastVariant.neutral,
    );
  }
}

/// Icon button toggling whether this client is spotlighting (presenting)
/// this channel to everyone else on the roster (PRD 16 §5).
class _PresentToggleButton extends ConsumerWidget {
  const _PresentToggleButton({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final myPresence = ref.watch(myPresenceProvider);
    final isPresenting = myPresence.spotlightChannelId == channelId;
    final tooltip = isPresenting ? l10n.stopPresenting : l10n.startPresenting;

    return CcTooltip(
      targetAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      message: tooltip,
      child: CcIconButton(
        icon: AppIcons.monitor,
        semanticLabel: tooltip,
        color: isPresenting ? t.accent : null,
        onPressed: () => ref
            .read(myPresenceProvider.notifier)
            .setSpotlight(isPresenting ? null : channelId),
      ),
    );
  }
}

/// Icon button that begins a take-over of this channel's worktree (PRD 16
/// §8). Hidden while a take-over (by anyone) is already active — the
/// conversation-pane banner covers hand-back / status in that case.
class _TakeoverButton extends ConsumerWidget {
  const _TakeoverButton({required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final takeover = ref.watch(takeoverStatusProvider(channelId)).value;
    if (takeover != null) {
      return const SizedBox.shrink();
    }

    return CcTooltip(
      targetAnchor: Alignment.bottomCenter,
      followerAnchor: Alignment.topCenter,
      message: l10n.takeoverTooltip,
      child: CcIconButton(
        icon: AppIcons.userCheck,
        semanticLabel: l10n.takeoverTooltip,
        onPressed: () => _begin(context, ref),
      ),
    );
  }

  /// Begins the take-over, then opens the code-server editor tab on the same
  /// worktree — the natural take-over surface (PRD 16 §8). A failure (e.g.
  /// someone else just took over) surfaces via toast with the server's
  /// message rather than throwing into the widget tree.
  Future<void> _begin(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final toast = CcToastScope.maybeOf(context);
    try {
      await beginChannelTakeover(ref.read(rpcClientProvider), channelId);
    } on RemoteRpcException catch (e) {
      toast?.show(
        l10n.takeoverFailed(e.message),
        variant: CcToastVariant.danger,
      );
      return;
    }
    ref.invalidate(takeoverStatusProvider(channelId));
    ref.read(openCodeServerTabRequestProvider(channelId).notifier).request();
  }
}

/// Dialog for managing channel participants.
class ManageChannelDialog extends ConsumerStatefulWidget {
  /// Creates a new [ManageChannelDialog].
  const ManageChannelDialog({super.key, required this.channelId});

  /// Channel to manage.
  final String channelId;

  @override
  ConsumerState<ManageChannelDialog> createState() =>
      _ManageChannelDialogState();
}

class _ManageChannelDialogState extends ConsumerState<ManageChannelDialog> {
  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final participants =
        ref.watch(channelParticipantsProvider(widget.channelId)).value ??
        const [];
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    final existingIds = participants.map((p) => p.principalId).toSet();
    final channelParticipants = participants.where((p) => !p.isUser).toList();
    final channelAgentIds = channelParticipants
        .map((p) => p.principalId)
        .toSet();
    final channelAgents = agents
        .where((a) => channelAgentIds.contains(a.id))
        .toList();

    return CcDialog(
      title: l10n.manageParticipants,
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (channelParticipants.isNotEmpty) ...[
              Text(
                l10n.currentParticipants,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              ...channelParticipants.map(
                (p) => _ParticipantRow(
                  channelId: widget.channelId,
                  participant: p,
                  onRemove: () => _removeAgent(p.principalId),
                ),
              ),
              const SizedBox(height: 24, child: Center(child: CcDivider())),
            ],
            Text(
              l10n.inviteAgent,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: 8),
            _InviteSection(
              agents: agents,
              existingIds: existingIds,
              onInvite: _inviteAgent,
            ),
            const SizedBox(height: 24, child: Center(child: CcDivider())),
            _CheckerSection(channelId: widget.channelId, agents: channelAgents),
          ],
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _removeAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .removeParticipant(ref.requireWorkspaceId(), widget.channelId, agentId);
  }

  Future<void> _inviteAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .addAgentToChannel(ref.requireWorkspaceId(), widget.channelId, agentId);
  }
}

class _ParticipantRow extends ConsumerWidget {
  const _ParticipantRow({
    required this.channelId,
    required this.participant,
    required this.onRemove,
  });

  /// The channel this participant belongs to — scopes the autonomy read/write.
  final String channelId;
  final ChannelParticipant participant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final agentAsync = ref.watch(agentDetailProvider(participant.principalId));
    final name = agentAsync.value?.name ?? '...';
    final title = agentAsync.value?.title ?? '';
    final l10n = AppLocalizations.of(context);
    final autonomy =
        ref.watch(channelAutonomyProvider(channelId)).value ??
        const <String, AutonomyLevel?>{};
    final currentLevel = autonomy[participant.principalId];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(
                agentId: participant.principalId,
                name: name,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: CcTypography.body.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: CcTypography.caption.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              CcTooltip(
                message: l10n.remove,
                child: CcIconButton(
                  icon: AppIcons.x,
                  semanticLabel: l10n.remove,
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 34, right: 4),
            child: CcSelect<AutonomyLevel?>(
              label: l10n.autonomyDialLabel,
              options: [
                CcSelectOption(value: null, label: l10n.autonomyDefaultOption),
                CcSelectOption(
                  value: AutonomyLevel.proposeOnly,
                  label: l10n.autonomyProposeOnly,
                ),
                CcSelectOption(
                  value: AutonomyLevel.actWithApproval,
                  label: l10n.autonomyActWithApproval,
                ),
                CcSelectOption(
                  value: AutonomyLevel.actFreely,
                  label: l10n.autonomyActFreely,
                ),
              ],
              value: currentLevel,
              onChanged: (level) => setChannelAutonomy(
                ref.read(rpcClientProvider),
                channelId: channelId,
                agentId: participant.principalId,
                level: level,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The channel's checker-agent row (PRD 16 §13): a select over the channel's
/// own agent participants (+ "None"), bound to `checker.get`/
/// `checker.setForChannel`.
class _CheckerSection extends ConsumerWidget {
  const _CheckerSection({required this.channelId, required this.agents});

  final String channelId;
  final List<Agent> agents;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentCheckerId = ref.watch(channelCheckerProvider(channelId)).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcSelect<String?>(
          label: l10n.checkerLabel,
          options: [
            CcSelectOption(value: null, label: l10n.checkerNone),
            for (final a in agents) CcSelectOption(value: a.id, label: a.name),
          ],
          value: currentCheckerId,
          onChanged: (agentId) async {
            await setChannelChecker(
              ref.read(rpcClientProvider),
              channelId: channelId,
              agentId: agentId,
            );
            ref.invalidate(channelCheckerProvider(channelId));
          },
        ),
        const SizedBox(height: 4),
        Text(
          l10n.checkerCaption,
          style: CcTypography.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _InviteSection extends StatefulWidget {
  const _InviteSection({
    required this.agents,
    required this.existingIds,
    required this.onInvite,
  });

  final List<Agent> agents;
  final Set<String> existingIds;
  final ValueChanged<String> onInvite;

  @override
  State<_InviteSection> createState() => _InviteSectionState();
}

class _InviteSectionState extends State<_InviteSection> {
  Agent? _selected;

  @override
  Widget build(BuildContext context) {
    final available = widget.agents
        .where((a) => !widget.existingIds.contains(a.id))
        .toList();
    final l10n = AppLocalizations.of(context);

    if (available.isEmpty) {
      return Text(
        l10n.allAgentsAlreadyInChannel,
        style: const TextStyle(fontSize: 12),
      );
    }

    return Column(
      children: [
        if (available.length <= 5)
          ...available.map(
            (a) => CcTile(
              leading: AgentAvatar(
                agentId: a.id,
                name: a.name,
                size: 22,
                showHoverCard: false,
              ),
              title: a.name,
              subtitle: a.title.isNotEmpty ? Text(a.title) : null,
              onTap: () {
                widget.onInvite(a.id);
                Navigator.of(context).pop();
              },
            ),
          )
        else ...[
          CcSelect<Agent>(
            value: _selected,
            options: available
                .map((a) => CcSelectOption<Agent>(value: a, label: a.name))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
            hintText: l10n.selectAnAgent,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: CcButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      widget.onInvite(_selected!.id);
                      Navigator.of(context).pop();
                    },
              child: Text(l10n.invite),
            ),
          ),
        ],
      ],
    );
  }
}
