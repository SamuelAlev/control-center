import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header for the messaging inner sidebar.
class MessagingInnerSidebarHeader extends StatelessWidget {
  /// Creates a new [MessagingInnerSidebarHeader].
  const MessagingInnerSidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 16,
            color: colors.mutedForeground,
          ),
          const SizedBox(width: 8),
          Text(
            l10n.messagingLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Builds the FSidebarGroup list for the messaging inner sidebar.
class MessagingInnerSidebar extends ConsumerWidget {
  /// Creates a new [MessagingInnerSidebar].
  const MessagingInnerSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(selectedChannelIdProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final dms = workspaceId != null
        ? ref.watch(workspaceDmChannelsProvider(workspaceId))
        : ref.watch(dmChannelsProvider);
    final groups = workspaceId != null
        ? ref.watch(workspaceGroupChannelsProvider(workspaceId))
        : ref.watch(groupChannelsProvider);
    final l10n = AppLocalizations.of(context);

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        FSidebarGroup(
          label: Text(l10n.directMessages),
          action: FButton.icon(
            size: FButtonSizeVariant.xs,
            variant: FButtonVariant.ghost,
            onPress: () => showNewDmDialog(context, ref),
            child: const Icon(LucideIcons.plus, size: 14),
          ),
          children: [
            if (dms.isEmpty)
              _EmptyHint(text: l10n.noDirectMessagesYet)
            else
              for (final channel in dms)
                _ChannelSidebarItem(
                  channel: channel,
                  selected: channel.id == selectedId,
                  onPress: () => ref
                      .read(selectedChannelIdProvider.notifier)
                      .select(channel.id),
                ),
          ],
        ),
        FSidebarGroup(
          label: Text(l10n.groups),
          action: FButton.icon(
            size: FButtonSizeVariant.xs,
            variant: FButtonVariant.ghost,
            onPress: () => showNewGroupDialog(context, ref),
            child: const Icon(LucideIcons.plus, size: 14),
          ),
          children: [
            if (groups.isEmpty)
              _EmptyHint(text: l10n.noGroupsYet)
            else
              for (final channel in groups)
                _ChannelSidebarItem(
                  channel: channel,
                  selected: channel.id == selectedId,
                  onPress: () => ref
                      .read(selectedChannelIdProvider.notifier)
                      .select(channel.id),
                ),
          ],
        ),
      ],
    );
  }

}

/// Opens the "New direct message" dialog, creates the channel for the
/// chosen agent, and selects it.
Future<void> showNewDmDialog(BuildContext context, WidgetRef ref) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  final agents = workspaceId != null
      ? await ref.read(workspaceAgentsProvider(workspaceId).future)
      : await ref.read(agentsProvider.future);
  if (!context.mounted) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  if (agents.isEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.noAgentsRegisteredYet)));
    return;
  }
  final selected = await showDialog<Agent>(
    context: context,
    builder: (_) => _SelectAgentDialog(agents: agents, title: l10n.newMessage),
  );
  if (selected == null) {
    return;
  }

  final service = ref.read(messagingServiceProvider);
  final channel = await service.openDm(selected.id, workspaceId: workspaceId);
  ref.read(selectedChannelIdProvider.notifier).select(channel.id);
}

/// Opens the "New group" dialog, creates the group channel, and selects
/// it.
Future<void> showNewGroupDialog(BuildContext context, WidgetRef ref) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  final agents = workspaceId != null
      ? await ref.read(workspaceAgentsProvider(workspaceId).future)
      : await ref.read(agentsProvider.future);
  if (!context.mounted) {
    return;
  }
  final result = await showDialog<_GroupSpec>(
    context: context,
    builder: (_) => _CreateGroupDialog(agents: agents),
  );
  if (result == null || result.name.isEmpty) {
    return;
  }

  final service = ref.read(messagingServiceProvider);
  final channel = await service.createGroup(
    result.name,
    result.agentIds,
    workspaceId: workspaceId,
  );
  ref.read(selectedChannelIdProvider.notifier).select(channel.id);
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
    );
  }
}

class _ChannelSidebarItem extends ConsumerWidget {
  const _ChannelSidebarItem({
    required this.channel,
    required this.selected,
    required this.onPress,
  });

  final Channel channel;
  final bool selected;
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(
      channelParticipantsProvider(channel.id),
    );
    final participants = participantsAsync.value ?? const [];
    final l10n = AppLocalizations.of(context);

    String label;
    Widget icon;

    if (channel.isDm) {
      final agentParticipant = participants.where((p) => !p.isUser).firstOrNull;
      if (agentParticipant != null) {
        final agentAsync = ref.watch(
          agentDetailProvider(agentParticipant.agentId),
        );
        final name = agentAsync.value?.name ?? '…';
        label = name;
        icon = AgentAvatar(
          agentId: agentParticipant.agentId,
          name: name,
          size: 20,
          showHoverCard: false,
        );
      } else {
        label = l10n.directMessage;
        icon = FAvatar.raw(size: 20, child: const Text('?'));
      }
    } else {
      label = channel.name.isNotEmpty ? channel.name : l10n.groupLabel;
      icon = const Icon(LucideIcons.hash);
    }

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showDeleteMenu(context, ref, details.globalPosition),
      child: FSidebarItem(
        icon: icon,
        label: Text(label, overflow: TextOverflow.ellipsis),
        selected: selected,
        onPress: onPress,
        onLongPress: () => _confirmDelete(context, ref),
      ),
    );
  }

  void _showDeleteMenu(BuildContext context, WidgetRef ref, Offset position) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: [
        PopupMenuItem(
          onTap: () => _confirmDelete(context, ref),
          child: ListTile(
            leading: Icon(
              LucideIcons.trash2,
              size: 16,
              color: tokens?.fgErrorPrimary ?? Colors.red,
            ),
            title: Text(l10n.delete),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
      title: Text(l10n.deleteConversation),
      body: Text(
        l10n.deleteNamedConversation(channel.name.isNotEmpty ? channel.name : l10n.thisConversation),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                variant: FButtonVariant.outline,
                onPress: () => Navigator.pop(ctx, false),
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                variant: FButtonVariant.destructive,
                onPress: () => Navigator.pop(ctx, true),
                child: Text(l10n.delete),
              ),
            ],
          ),
        ),
      ],
      ),
    );
    if (confirmed != true) {
      return;
    }

    final service = ref.read(messagingServiceProvider);
    await service.deleteChannel(channel.id);

    if (context.mounted) {
      final selectedId = ref.read(selectedChannelIdProvider);
      if (selectedId == channel.id) {
        ref.read(selectedChannelIdProvider.notifier).select(null);
      }
    }
  }
}

// ── Dialogs ────────────────────────────────────────────────────────────────

class _SelectAgentDialog extends StatefulWidget {
  const _SelectAgentDialog({required this.agents, required this.title});

  final List<Agent> agents;
  final String title;

  @override
  State<_SelectAgentDialog> createState() => _SelectAgentDialogState();
}

class _SelectAgentDialogState extends State<_SelectAgentDialog> {
  Agent? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FDialog(
      title: Text(widget.title),
      body: SizedBox(
        width: 300,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 300),
          child: FSelectGroup<Agent>(
            control: FMultiValueControl.managedRadio(
              initial: _selected,
              onChange: (v) => setState(() => _selected = v.isEmpty ? null : v.first),
            ),
            children: widget.agents.map((agent) {
              return FSelectGroupItemMixin.radio<Agent>(
                value: agent,
                label: Text(agent.name),
                description: Text(agent.title),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.of(context).pop(),
                variant: FButtonVariant.outline,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: _selected == null
                    ? null
                    : () => Navigator.of(context).pop(_selected),
                child: Text(l10n.openLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupSpec {
  const _GroupSpec({required this.name, required this.agentIds});

  final String name;
  final List<String> agentIds;
}

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog({required this.agents});

  final List<Agent> agents;

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FDialog(
      title: Text(l10n.newGroup),
      body: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FTextField(
              control: FTextFieldControl.managed(controller: _nameController),
              hint: l10n.groupName,
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: FSelectGroup<String>(
                control: FMultiValueControl.managed(
                  initial: _selectedIds,
                  onChange: (v) => setState(() => _selectedIds
                    ..clear()
                    ..addAll(v)),
                ),
                children: widget.agents.map((agent) {
                  return FSelectGroupItemMixin.checkbox<String>(
                    value: agent.id,
                    label: Text(agent.name),
                    description: Text(agent.title),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.of(context).pop(),
                variant: FButtonVariant.outline,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: () {
                  final name = _nameController.text.trim();
                  if (name.isEmpty) {
                    return;
                  }
                  Navigator.of(context).pop(_GroupSpec(name: name, agentIds: _selectedIds.toList()));
                },
                child: Text(l10n.create),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
