import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Header for the messaging inner sidebar.
class MessagingInnerSidebarHeader extends StatelessWidget {
  /// Creates a new [MessagingInnerSidebarHeader].
  const MessagingInnerSidebarHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 12),
      child: Row(
        children: [
          Icon(
            LucideIcons.messageSquare,
            size: 16,
            color: tokens?.textTertiary,
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
        _SidebarSection(
          label: l10n.directMessages,
          action: CcIconButton(
            icon: LucideIcons.plus,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            onPressed: () => showNewDmDialog(context, ref),
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
        _SidebarSection(
          label: l10n.groups,
          action: CcIconButton(
            icon: LucideIcons.plus,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            onPressed: () => showNewGroupDialog(context, ref),
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

/// A labelled sidebar section: a branded mono-eyebrow header carrying a trailing
/// [action] button, above its [children].
///
/// [CcSidebarGroup] renders its own eyebrow label but has no slot for a trailing
/// action, so the header is composed here (matching the group's eyebrow styling)
/// and a label-less [CcSidebarGroup] holds the items.
class _SidebarSection extends StatelessWidget {
  const _SidebarSection({
    required this.label,
    required this.action,
    required this.children,
  });

  final String label;
  final Widget action;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final color = tokens?.textTertiary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CcFonts.code(
                      textStyle: CcTypography.label,
                      family: context.ccTheme?.monoFontFamily,
                    ).copyWith(color: color),
                  ),
                ),
                action,
              ],
            ),
          ),
          CcSidebarGroup(children: children),
        ],
      ),
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
    CcToastScope.of(
      context,
    ).show(l10n.noAgentsRegisteredYet, variant: CcToastVariant.neutral);
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
          color: context.designSystem?.textTertiary,
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
    Widget leading;

    if (channel.isDm) {
      final agentParticipant = participants.where((p) => !p.isUser).firstOrNull;
      if (agentParticipant != null) {
        final agentAsync = ref.watch(
          agentDetailProvider(agentParticipant.agentId),
        );
        final name = agentAsync.value?.name ?? '…';
        label = name;
        leading = AgentAvatar(
          agentId: agentParticipant.agentId,
          name: name,
          size: 20,
          showHoverCard: false,
        );
      } else {
        label = l10n.directMessage;
        leading = const CcAvatar(size: 20, initials: '?');
      }
    } else {
      label = channel.name.isNotEmpty ? channel.name : l10n.groupLabel;
      leading = const Icon(LucideIcons.hash, size: 18);
    }

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showDeleteMenu(context, ref, details.globalPosition),
      child: _ChannelRow(
        leading: leading,
        label: label,
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
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteConversation,
        content: Text(
          l10n.deleteNamedConversation(
            channel.name.isNotEmpty ? channel.name : l10n.thisConversation,
          ),
        ),
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

/// A channel navigation row mirroring [CcSidebarItem]'s branded selected
/// treatment, but with a [leading] widget (an agent avatar / hash icon) and an
/// [onLongPress] — neither of which [CcSidebarItem]'s icon-only API can host.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.leading,
    required this.label,
    required this.selected,
    required this.onPress,
    required this.onLongPress,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final VoidCallback onPress;
  final VoidCallback onLongPress;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (selected) {
      return t.panel;
    }
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return t.hover;
    }
    return const Color(0x00000000);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = selected ? t.accent : t.textSecondary;

    return CcTappable(
      onPressed: onPress,
      onLongPress: onLongPress,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      builder: (context, states) {
        return Stack(
          children: [
            AnimatedContainer(
              duration: CcMotion.fast,
              curve: CcMotion.standard,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: _background(t, states),
                borderRadius: AppRadii.brSm,
              ),
              child: Row(
                children: [
                  IconTheme.merge(
                    data: IconThemeData(color: fg, size: 18),
                    child: leading,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: AppRadii.brSm,
                  ),
                ),
              ),
          ],
        );
      },
    );
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
    return CcDialog(
      title: widget.title,
      content: SizedBox(
        width: 300,
        child: CcSelect<Agent>(
          value: _selected,
          hintText: l10n.newMessage,
          options: widget.agents
              .map((agent) => CcSelectOption(value: agent, label: agent.name))
              .toList(),
          onChanged: (agent) => setState(() => _selected = agent),
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context).pop(_selected),
          child: Text(l10n.openLabel),
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
    return CcDialog(
      title: l10n.newGroup,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcTextField(
              controller: _nameController,
              hintText: l10n.groupName,
            ),
            const SizedBox(height: 12),
            CcMultiSelect<String>(
              values: _selectedIds,
              hintText: l10n.addAgents,
              options: widget.agents
                  .map(
                    (agent) =>
                        CcSelectOption(value: agent.id, label: agent.name),
                  )
                  .toList(),
              onChanged: (next) => setState(() => _selectedIds
                ..clear()
                ..addAll(next)),
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.of(context).pop(),
          variant: CcButtonVariant.secondary,
          child: Text(l10n.cancel),
        ),
        CcButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) {
              return;
            }
            Navigator.of(context).pop(
              _GroupSpec(name: name, agentIds: _selectedIds.toList()),
            );
          },
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
