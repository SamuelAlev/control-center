import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header bar displaying channel info and actions.
class ChannelHeader extends ConsumerWidget {
  /// Creates a new [ChannelHeader].
  const ChannelHeader({
    super.key,
    required this.channel,
    required this.onManage,
    required this.onDelete,
    this.onToggleTerminal,
    this.terminalOpen = false,
  });

  /// The channel to display.
  final Channel channel;
  /// Callback to manage participants.
  final VoidCallback onManage;
  /// Callback to delete the channel.
  final VoidCallback onDelete;
  /// Callback to open / close the container terminal side panel.
  final VoidCallback? onToggleTerminal;
  /// Whether the terminal panel is currently visible.
  final bool terminalOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = context.theme.colors;
    final participantsAsync = ref.watch(
      channelParticipantsProvider(channel.id),
    );
    final participants = participantsAsync.value ?? const [];
    final agents = participants.where((p) => !p.isUser).toList();
    final l10n = AppLocalizations.of(context);

    String title;
    String subtitle;

    if (channel.isDm && agents.length == 1) {
      final agentAsync = ref.watch(agentDetailProvider(agents.first.agentId));
      title = agentAsync.value?.name ?? '...';
      subtitle = agentAsync.value?.title ?? l10n.directMessage;
    } else {
      title = channel.name.isNotEmpty ? channel.name : l10n.groupLabel;
      subtitle = agents.isEmpty
          ? l10n.noAgents
          : l10n.agentCount(agents.length, agents.length);
    }

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          if (channel.isDm && agents.isNotEmpty)
            AgentAvatar(
              agentId: agents.first.agentId,
              name: title,
              size: 28,
            )
          else
            Icon(LucideIcons.users, size: 20, color: colors.mutedForeground),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _ParticipantAvatars(participants: agents),
          const SizedBox(width: 8),
          if (onToggleTerminal != null)
            FTooltip(
              tipAnchor: Alignment.topCenter,
              childAnchor: Alignment.bottomCenter,
              tipBuilder: (_, _) => Text(
                terminalOpen
                    ? l10n.hideContainerTerminal
                    : l10n.openContainerTerminal,
              ),
              child: FButton.icon(
                onPress: onToggleTerminal,
                child: Icon(
                  terminalOpen ? LucideIcons.x : LucideIcons.terminal,
                  size: 16,
                ),
              ),
            ),
          if (onToggleTerminal != null) const SizedBox(width: 4),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(l10n.manageParticipants),
            child: FButton.icon(
              onPress: onManage,
              child: const Icon(LucideIcons.users, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          FTooltip(
            tipAnchor: Alignment.topCenter,
            childAnchor: Alignment.bottomCenter,
            tipBuilder: (_, _) => Text(l10n.deleteConversation),
            child: FButton.icon(
              onPress: onDelete,
              child: const Icon(LucideIcons.trash2, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipantAvatars extends ConsumerWidget {
  const _ParticipantAvatars({required this.participants});

  final List<ChannelParticipant> participants;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = participants.take(3).toList();
    const size = 22.0;
    const overlap = 14.0;
    final totalWidth = shown.isEmpty
        ? 0.0
        : size + (shown.length - 1) * overlap;

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: i * overlap,
              child: AgentAvatar(
                agentId: shown[i].agentId,
                size: size,
              ),
            ),
        ],
      ),
    );
  }
}

/// Dialog for managing channel participants.
class ManageChannelDialog extends ConsumerStatefulWidget {
  /// Creates a new [ManageChannelDialog].
  const ManageChannelDialog({
    super.key,
    required this.channelId,
    required this.isDm,
  });

  /// Channel to manage.
  final String channelId;
  /// Whether the channel is a DM.
  final bool isDm;

  @override
  ConsumerState<ManageChannelDialog> createState() =>
      _ManageChannelDialogState();
}

class _ManageChannelDialogState extends ConsumerState<ManageChannelDialog> {
  @override
  Widget build(BuildContext context) {
    final participants =
        ref.watch(channelParticipantsProvider(widget.channelId)).value ??
        const [];
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId)).value ?? const []
        : ref.watch(agentsProvider).value ?? const [];
    final l10n = AppLocalizations.of(context);
    final existingIds = participants.map((p) => p.agentId).toSet();
    final channelParticipants = participants.where((p) => !p.isUser).toList();

    return FDialog(
      title: Text(l10n.manageParticipants),
      body: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (channelParticipants.isNotEmpty) ...[
              Text(
                l10n.currentParticipants,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              ...channelParticipants.map(
                (p) => _ParticipantRow(
                  participant: p,
                  onRemove: () => _removeAgent(p.agentId),
                ),
              ),
              const Divider(height: 24),
            ],
            Text(
              l10n.inviteAgent,
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            _InviteSection(
              agents: agents,
              existingIds: existingIds,
              onInvite: _inviteAgent,
            ),
          ],
        ),
      ),
      actions: [
        FButton(
          variant: FButtonVariant.outline,
          onPress: () => Navigator.of(context).pop(),
          child: Text(l10n.close),
        ),
      ],
    );
  }

  Future<void> _removeAgent(String agentId) async {
    await ref
        .read(messagingServiceProvider)
        .removeParticipant(widget.channelId, agentId);
  }

  Future<void> _inviteAgent(String agentId) async {
    if (widget.isDm) {
    final l10n = AppLocalizations.of(context);
      final result = await showFDialog<String>(
        context: context,
        builder: (ctx, style, animation) => FDialog(
          style: style,
          animation: animation,
          title: Text(l10n.convertToGroup),
          body: Text(
            l10n.convertToGroupBody,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FButton(
                    variant: FButtonVariant.outline,
                    onPress: () => Navigator.pop(ctx, 'cancel'),
                    child: Text(l10n.cancel),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    variant: FButtonVariant.destructive,
                    onPress: () => Navigator.pop(ctx, 'fresh'),
                    child: Text(l10n.startFresh),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () => Navigator.pop(ctx, 'keep'),
                    child: Text(l10n.keepMessages),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
      if (result == null || result == 'cancel') {
        return;
      }

      final service = ref.read(messagingServiceProvider);
      if (result == 'fresh') {
        await service.clearChannelMessages(widget.channelId);
      }
      await service.addAgentToChannel(widget.channelId, agentId);
    } else {
      await ref
          .read(messagingServiceProvider)
          .addAgentToChannel(widget.channelId, agentId);
    }
  }
}

class _ParticipantRow extends ConsumerWidget {
  const _ParticipantRow({required this.participant, required this.onRemove});

  final ChannelParticipant participant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentAsync = ref.watch(agentDetailProvider(participant.agentId));
    final name = agentAsync.value?.name ?? '...';
    final title = agentAsync.value?.title ?? '';
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          AgentAvatar(
            agentId: participant.agentId,
            name: name,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.bodyMedium),
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          FTooltip(
            tipBuilder: (_, _) => Text(l10n.remove),
            child: FButton.icon(
              onPress: onRemove,
              child: const Icon(LucideIcons.x, size: 16),
            ),
          ),
        ],
      ),
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
            (a) => Material(
              type: MaterialType.transparency,
              child: ListTile(
                leading: AgentAvatar(
                  agentId: a.id,
                  name: a.name,
                  size: 22,
                  showHoverCard: false,
                ),
                title: Text(a.name),
                subtitle: a.title.isNotEmpty ? Text(a.title) : null,
                dense: true,
                onTap: () {
                  widget.onInvite(a.id);
                  Navigator.of(context).pop();
                },
              ),
            ),
          )
        else ...[
          DropdownButtonFormField<Agent>(
            initialValue: _selected,
            items: available
                .map((a) => DropdownMenuItem(value: a, child: Text(a.name)))
                .toList(),
            onChanged: (v) => setState(() => _selected = v),
            decoration: InputDecoration(
              hintText: l10n.selectAnAgent,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FButton(
              onPress: _selected == null
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
