import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/messaging/domain/entities/channel.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/pr_status_badge.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Conversations" group rendered inline in the global app sidebar: the
/// Direct messages and Groups lists with their `+` actions, empty hints, and
/// channel rows. A separate [ConsumerWidget] so channel/selection watches
/// rebuild only this group, not the Work/Team/Knowledge groups.
///
/// Extracted from the former messaging-screen inner sidebar; tapping a row both
/// selects the channel ([selectedChannelIdProvider]) and navigates to the
/// conversation surface. The row's active highlight follows the route — it
/// lights only while on [messagingRoute] — so navigating away (to the dashboard,
/// tickets, …) clears it even though the channel stays selected for the user's
/// return.
class ConversationsSidebarSection extends ConsumerWidget {
  /// Creates a [ConversationsSidebarSection].
  const ConversationsSidebarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the read-cursor side effect alive while the sidebar is mounted: it
    // stamps the user's read cursor on selection so the unseen dot clears.
    ref.watch(selectedChannelReadCursorEffectProvider);
    final selectedId = ref.watch(selectedChannelIdProvider);
    // The active highlight follows the route as the source of truth: a channel
    // reads as selected only while the messaging surface is on screen. This
    // depends on GoRouterState, so the section rebuilds on navigation and the
    // highlight clears the moment the user leaves [messagingRoute].
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final onMessaging = workspaceId != null &&
        GoRouterState.of(context).matchedLocation == messagingRoute(workspaceId);
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
            icon: AppIcons.plus,
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
                  selected: onMessaging && channel.id == selectedId,
                  onPress: () => _selectAndNavigate(context, ref, channel.id),
                ),
          ],
        ),
        _SidebarSection(
          label: l10n.groups,
          action: CcIconButton(
            icon: AppIcons.plus,
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
                  selected: onMessaging && channel.id == selectedId,
                  onPress: () => _selectAndNavigate(context, ref, channel.id),
                ),
          ],
        ),
      ],
    );
  }

  void _selectAndNavigate(
    BuildContext context,
    WidgetRef ref,
    String channelId,
  ) {
    ref.read(selectedChannelIdProvider.notifier).select(channelId);
    GoRouter.of(context).go(messagingRoute(context.currentWorkspaceId!));
  }
}

/// A labelled, collapsible sidebar section: a branded mono-eyebrow header whose
/// label + rotating chevron toggle the section, carrying a trailing [action]
/// button, above its [children].
///
/// [CcSidebarGroup] renders the same eyebrow + chevron treatment when
/// `collapsible`, but has no slot for a trailing action, so the header is
/// composed here (matching the group's eyebrow styling) and an [AnimatedSize]
/// gates a label-less [CcSidebarGroup] holding the items.
class _SidebarSection extends StatefulWidget {
  const _SidebarSection({
    required this.label,
    required this.action,
    required this.children,
  });

  final String label;
  final Widget action;
  final List<Widget> children;

  @override
  State<_SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<_SidebarSection> {
  bool _expanded = true;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final color = context.designSystem?.textTertiary;
    final expanded = _expanded;
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
                // The label is tappable to toggle (a wide hit target), with the
                // `+` action and the disclosure chevron trailing — in that order
                // (`LABEL  +  ⌄`).
                Expanded(
                  child: CcTappable(
                    onPressed: _toggle,
                    borderRadius: AppRadii.brSm,
                    semanticLabel: widget.label,
                    builder: (context, states) => Text(
                      widget.label.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcFonts.code(
                        textStyle: CcTypography.label,
                        family: context.ccTheme?.monoFontFamily,
                      ).copyWith(color: color),
                    ),
                  ),
                ),
                widget.action,
                _SectionChevron(
                  expanded: expanded,
                  onToggle: _toggle,
                  color: color,
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: CcMotion.resolve(context, CcMotion.normal),
            curve: CcMotion.standard,
            alignment: Alignment.topCenter,
            child: expanded
                ? CcSidebarGroup(children: widget.children)
                : const SizedBox(width: double.infinity, height: 0),
          ),
        ],
      ),
    );
  }
}

/// The rotating disclosure chevron trailing a [_SidebarSection] header. Tapping
/// it toggles the section — a sibling affordance to the tappable label — and it
/// rotates to point right when collapsed, matching the Tickets accordion and
/// [CcSidebarGroup]'s collapsible header.
class _SectionChevron extends StatelessWidget {
  const _SectionChevron({
    required this.expanded,
    required this.onToggle,
    required this.color,
  });

  final bool expanded;
  final VoidCallback onToggle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: AnimatedRotation(
            duration: CcMotion.normal,
            curve: CcMotion.standard,
            turns: expanded ? 0 : -0.25,
            child: Icon(AppIcons.chevronDown, size: 14, color: color),
          ),
        ),
      ),
    );
  }
}

/// Opens the "New direct message" dialog, creates the channel for the
/// chosen agent, and selects it.
Future<void> showNewDmDialog(BuildContext context, WidgetRef ref) async {
  // The route's `:workspaceId` is the source of truth — read it directly so the
  // new conversation always lands in the workspace the user is viewing, never a
  // stale/lagging `activeWorkspaceIdProvider` value. (We're inside the workspace
  // shell here, so the param is always present.)
  final workspaceId = context.currentWorkspaceId!;
  final agents = await ref.read(workspaceAgentsProvider(workspaceId).future);
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
  final selected = await showCcDialog<Agent>(
    context: context,
    builder: (_) => _SelectAgentDialog(agents: agents, title: l10n.newMessage),
  );
  if (selected == null) {
    return;
  }

  final service = ref.read(messagingServiceProvider);
  final channel = await service.openDm(selected.id, workspaceId: workspaceId);
  ref.read(selectedChannelIdProvider.notifier).select(channel.id);
  // Opened from the global sidebar: surface the new conversation.
  if (context.mounted) {
    GoRouter.of(context).go(messagingRoute(workspaceId));
  }
}

/// Opens the "New group" dialog, creates the group channel, and selects
/// it.
Future<void> showNewGroupDialog(BuildContext context, WidgetRef ref) async {
  // The route's `:workspaceId` is the source of truth — read it directly so the
  // new group always lands in the workspace the user is viewing, never a
  // stale/lagging `activeWorkspaceIdProvider` value.
  final workspaceId = context.currentWorkspaceId!;
  final agents = await ref.read(workspaceAgentsProvider(workspaceId).future);
  if (!context.mounted) {
    return;
  }
  final result = await showCcDialog<_GroupSpec>(
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
  // Opened from the global sidebar: surface the new conversation.
  if (context.mounted) {
    GoRouter.of(context).go(messagingRoute(workspaceId));
  }
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

    final status = ref.watch(channelStatusProvider(channel.id));
    final unread = ref.watch(channelUnreadProvider(channel.id));
    final running = status == ChannelStatus.running;

    String label;
    Widget leading;
    // Whether the leading slot already carries the running signal (a spinner).
    // Group channels do; DMs keep their avatar, so their running state stays on
    // the trailing indicator.
    bool leadingHandlesRunning;

    if (channel.isDm) {
      leadingHandlesRunning = false;
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
      leadingHandlesRunning = true;
      label = channel.name.isNotEmpty ? channel.name : l10n.groupLabel;
      leading = _GroupChannelLeading(channelId: channel.id, running: running);
    }

    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showDeleteMenu(context, ref, details.globalPosition),
      child: _ChannelRow(
        leading: leading,
        label: label,
        selected: selected,
        status: status,
        unread: unread,
        leadingHandlesRunning: leadingHandlesRunning,
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
              AppIcons.trash2,
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

/// A channel navigation row that reproduces [CcSidebarItem]'s exact look — the
/// `accentSoft` fill + reserved 1px `accent` border when [selected], the same
/// hover/pressed washes and padding — so channels read as first-class sidebar
/// items. It can't be a [CcSidebarItem] itself because that widget's icon-only
/// API hosts neither a [leading] widget (an agent avatar / PR badge / spinner)
/// nor the [onLongPress] used for the delete menu.
class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.leading,
    required this.label,
    required this.selected,
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    required this.onPress,
    required this.onLongPress,
  });

  final Widget leading;
  final String label;
  final bool selected;
  final ChannelStatus status;
  /// Whether the channel has unseen agent messages (drives the notification dot
  /// on idle channels).
  final bool unread;
  /// Whether the leading slot already shows the running signal (group channels
  /// spin; DMs don't). Suppresses a redundant trailing running dot when true.
  final bool leadingHandlesRunning;
  final VoidCallback onPress;
  final VoidCallback onLongPress;

  Color _background(DesignSystemTokens t, Set<WidgetState> states) {
    if (selected) {
      return t.accentSoft;
    }
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return t.hover;
    }
    // Alpha-0 hover colour (not transparent-black), mirroring CcSidebarItem, so
    // the AnimatedContainer lerps only alpha on hover↔idle (no dark-gray flash).
    return t.hover.withValues(alpha: 0);
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
        return AnimatedContainer(
          duration: CcMotion.fast,
          curve: CcMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: _background(t, states),
            borderRadius: AppRadii.brSm,
            // A 1px border is reserved on every row (alpha-0 when idle) so the
            // layout never shifts when [selected] toggles the brand border on —
            // mirrors CcSidebarItem's selected treatment.
            border: Border.all(
              color: selected ? t.accent : t.accent.withValues(alpha: 0),
              width: 1,
            ),
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
              if (_ChannelTrailing.shouldShow(
                status: status,
                unread: unread,
                leadingHandlesRunning: leadingHandlesRunning,
              )) ...[
                const SizedBox(width: AppSpacing.sm),
                _ChannelTrailing(
                  status: status,
                  unread: unread,
                  leadingHandlesRunning: leadingHandlesRunning,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Trailing indicator on a channel row. Differentiated by shape as well as
/// colour (never status-by-colour-alone per DESIGN.md):
/// - `needsInput` → a ringed accent target (the actionable "answer me" signal).
/// - `running` → a small muted dot, but only when the leading slot doesn't
///   already carry a spinner (DMs). Group channels spin on the leading slot, so
///   they render nothing here to avoid a redundant double indicator.
/// - `idle` + unread → a filled accent dot (the "agent finished, you have
///   unseen messages" notification). Needs-input wins over it.
class _ChannelTrailing extends StatelessWidget {
  const _ChannelTrailing({
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
  });

  final ChannelStatus status;
  final bool unread;
  final bool leadingHandlesRunning;

  /// Whether anything should render at all (avoids reserving trailing space
  /// when there's no signal).
  static bool shouldShow({
    required ChannelStatus status,
    required bool unread,
    required bool leadingHandlesRunning,
  }) {
    switch (status) {
      case ChannelStatus.needsInput:
        return true;
      case ChannelStatus.running:
        return !leadingHandlesRunning;
      case ChannelStatus.idle:
        return unread;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    switch (status) {
      case ChannelStatus.needsInput:
        // Ringed accent target — the strongest call to action.
        return Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: t.accent, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
          ),
        );
      case ChannelStatus.running:
        // DMs only — group channels spin on the leading slot.
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: t.textTertiary,
            shape: BoxShape.circle,
          ),
        );
      case ChannelStatus.idle:
        // The unseen-messages notification dot (accent, distinct from the
        // muted running dot by colour).
        return Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: t.accent,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

/// The leading icon for a non-DM (group) channel: a spinner while an agent is
/// running, otherwise the PR status badge when the conversation is linked to a
/// PR (resolved from the review-channel association + cached GitHub state), and
/// the plain hash as the default. The PR badge hydrates from cache after the
/// first paint, so the row renders instantly with the hash and never blocks.
class _GroupChannelLeading extends ConsumerWidget {
  const _GroupChannelLeading({required this.channelId, required this.running});

  final String channelId;
  final bool running;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (running) {
      return const CcSpinner(size: 18);
    }
    final pr = ref.watch(channelPrDetailProvider(channelId)).value;
    final status = PrSidebarStatus.fromPullRequest(pr);
    if (status != null) {
      return PrStatusBadge(status: status);
    }
    return const Icon(AppIcons.hash, size: 18);
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
