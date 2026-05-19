import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Channels" group rendered inline in the global app sidebar: the channel
/// list with its `+` action, empty hint, and channel rows. A separate
/// [ConsumerWidget] so channel/selection watches rebuild only this group, not
/// the Work/Team/Knowledge groups.
///
/// Tapping a row navigates to that channel ([channelRoute]); the URL is the
/// source of truth for the open channel, so the row's active highlight follows
/// the route's `:channelId` and clears the moment the user navigates away.
class ConversationsSidebarSection extends ConsumerWidget {
  /// Creates a [ConversationsSidebarSection].
  const ConversationsSidebarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the read-cursor side effect alive while the sidebar is mounted: it
    // stamps the user's read cursor on selection so the unseen dot clears.
    ref.watch(selectedChannelReadCursorEffectProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // The URL is the source of truth for the open channel: a row reads as
    // selected iff its id is the route's `:channelId`. The sidebar lives in the
    // shell (above the route's page), so the child route's path parameters
    // aren't in scope here — derive the id from the full location instead.
    // Reading GoRouterState makes the section rebuild on navigation, so the
    // highlight clears the moment the user leaves the channel surface.
    final routeChannelId = selectedChannelIdFromLocation(
      GoRouterState.of(context).uri.path,
      workspaceId,
    );
    final channels = workspaceId != null
        ? ref.watch(workspaceVisibleChannelsProvider(workspaceId))
        : ref.watch(visibleChannelsProvider);
    final l10n = AppLocalizations.of(context);

    // Partition by origin: human/system conversations stay in the main section
    // with their unread signals; agent↔agent DMs move to a separate, collapsed,
    // muted section so agent chatter never touches the human unread counts.
    final humanChannels = channels.where((c) => !c.origin.isAgentDm).toList();
    final agentChannels = channels.where((c) => c.origin.isAgentDm).toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SidebarSection(
          label: l10n.channels,
          action: CcIconButton(
            icon: AppIcons.plus,
            size: CcButtonSize.sm,
            variant: CcButtonVariant.ghost,
            tooltip: l10n.newChannel,
            onPressed: () => showNewChannelDialog(context, ref),
          ),
          children: [
            if (humanChannels.isEmpty)
              _EmptyHint(text: l10n.noChannelsYet)
            else
              for (final channel in humanChannels)
                ChannelSidebarItem(
                  channel: channel,
                  selected: channel.id == routeChannelId,
                  onPress: () => _selectAndNavigate(context, ref, channel.id),
                ),
          ],
        ),
        if (agentChannels.isNotEmpty)
          _SidebarSection(
            label: l10n.agentsSectionLabel,
            initiallyExpanded: false,
            children: [
              for (final channel in agentChannels)
                ChannelSidebarItem(
                  channel: channel,
                  selected: channel.id == routeChannelId,
                  muted: true,
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
    // Navigate only — MessagingScreen mirrors the URL into the selection
    // provider, keeping the URL the single source of truth.
    GoRouter.of(
      context,
    ).go(channelRoute(context.currentWorkspaceId!, channelId));
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
    required this.children,
    this.action,
    this.initiallyExpanded = true,
  });

  final String label;
  final Widget? action;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  State<_SidebarSection> createState() => _SidebarSectionState();
}

class _SidebarSectionState extends State<_SidebarSection> {
  late bool _expanded = widget.initiallyExpanded;

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
          // While the sidebar's width animates the header (label + `+` +
          // chevron) fades out — kept in the layout so the section height
          // never jumps — and stops taking taps. The item bodies below fade
          // their own labels.
          Builder(
            builder: (context) {
              final transitioning =
                  CcSidebarScope.transitioningOf(context) ?? false;
              return AnimatedOpacity(
                opacity: transitioning ? 0 : 1,
                duration: CcMotion.fast,
                curve: CcMotion.standard,
                child: IgnorePointer(
                  ignoring: transitioning,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Row(
                      children: [
                        // The label is tappable to toggle (a wide hit
                        // target), with the `+` action and the disclosure
                        // chevron trailing — in that order (`LABEL  +  ⌄`).
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
                        // While transitioning the trailing widgets leave the
                        // layout too (the faded header keeps only its
                        // ellipsizing label): the `+` action and chevron are
                        // fixed-width and would overflow the narrowing row.
                        if (widget.action != null && !transitioning)
                          widget.action!,
                        if (!transitioning)
                          _SectionChevron(
                            expanded: expanded,
                            onToggle: _toggle,
                            color: color,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
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

/// Opens the "New channel" dialog, creates the channel (with zero or more
/// agents), and navigates to it.
Future<void> showNewChannelDialog(BuildContext context, WidgetRef ref) async {
  // The route's `:workspaceId` is the source of truth — read it directly so the
  // new channel always lands in the workspace the user is viewing, never a
  // stale/lagging `activeWorkspaceIdProvider` value. (We're inside the workspace
  // shell here, so the param is always present.)
  final workspaceId = context.currentWorkspaceId!;
  final agents = await ref.read(workspaceAgentsProvider(workspaceId).future);
  final repos = await ref.read(reposForWorkspaceProvider(workspaceId).future);
  if (!context.mounted) {
    return;
  }
  final result = await showCcDialog<_ChannelSpec>(
    context: context,
    builder: (_) => _CreateChannelDialog(agents: agents, repos: repos),
  );
  if (result == null || result.name.isEmpty) {
    return;
  }

  final service = ref.read(messagingServiceProvider);
  final channel = await service.createChannel(
    workspaceId,
    result.name,
    result.agentIds,
    repoIds: result.repoIds,
  );
  // Opened from the global sidebar: surface the new conversation. The URL is
  // the source of truth, so navigation drives the selection.
  if (context.mounted) {
    GoRouter.of(context).go(channelRoute(workspaceId, channel.id));
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Text(
        text,
        style: CcTypography.caption.copyWith(
          color: context.designSystem?.textTertiary,
        ),
      ),
    );
  }
}

// ── Dialogs ────────────────────────────────────────────────────────────────

class _ChannelSpec {
  const _ChannelSpec({
    required this.name,
    required this.agentIds,
    required this.repoIds,
  });

  final String name;
  final List<String> agentIds;

  /// The repos this channel provisions worktrees for. Empty means "all
  /// workspace repos" (the provisioner's default).
  final List<String> repoIds;
}

class _CreateChannelDialog extends StatefulWidget {
  const _CreateChannelDialog({required this.agents, required this.repos});

  final List<Agent> agents;
  final List<Repo> repos;

  @override
  State<_CreateChannelDialog> createState() => _CreateChannelDialogState();
}

class _CreateChannelDialogState extends State<_CreateChannelDialog> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};

  /// Repos to provision. Defaults to ALL workspace repos so the channel behaves
  /// like before selection existed; the user narrows it here.
  late final Set<String> _selectedRepoIds = {
    for (final r in widget.repos) r.id,
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Only offer a repo picker when there's a real choice to make.
    final showRepoPicker = widget.repos.length > 1;
    return CcDialog(
      title: l10n.newChannel,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcTextField(
              controller: _nameController,
              hintText: l10n.channelName,
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
              onChanged: (next) => setState(
                () => _selectedIds
                  ..clear()
                  ..addAll(next),
              ),
            ),
            if (showRepoPicker) ...[
              const SizedBox(height: 12),
              CcMultiSelect<String>(
                values: _selectedRepoIds,
                hintText: l10n.channelReposHint,
                options: widget.repos
                    .map(
                      (repo) =>
                          CcSelectOption(value: repo.id, label: repo.fullName),
                    )
                    .toList(),
                onChanged: (next) => setState(
                  () => _selectedRepoIds
                    ..clear()
                    ..addAll(next),
                ),
              ),
            ],
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
            // Persist the selection only when it's a real subset; selecting all
            // (or the single-repo / no-repo case) leaves it empty = all repos.
            final repoIds = _selectedRepoIds.length == widget.repos.length
                ? const <String>[]
                : _selectedRepoIds.toList();
            Navigator.of(context).pop(
              _ChannelSpec(
                name: name,
                agentIds: _selectedIds.toList(),
                repoIds: repoIds,
              ),
            );
          },
          child: Text(l10n.create),
        ),
      ],
    );
  }
}
