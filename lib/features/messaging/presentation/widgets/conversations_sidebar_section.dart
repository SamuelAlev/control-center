import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_folders_list.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_group.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

part 'conversations_sidebar_archived.dart';

/// The "Spaces" group rendered inline in the global app sidebar: the space
/// list with its `+` action, empty hint and space rows. A separate
/// consumer so space watches rebuild only this group, not the Work/Team/
/// Knowledge groups.
///
/// Tapping a row navigates to that space ([spaceRoute]); the URL is the
/// source of truth for the open space, so the row's active highlight follows
/// the route's `:spaceId` and clears the moment the user navigates away. Each
/// row reads that highlight itself ([watchRouteSpaceSelected]): this section
/// does not depend on the route at all, so a navigation never rebuilds it.
class ConversationsSidebarSection extends ConsumerStatefulWidget {
  /// Creates a [ConversationsSidebarSection].
  const ConversationsSidebarSection({super.key});

  @override
  ConsumerState<ConversationsSidebarSection> createState() =>
      _ConversationsSidebarSectionState();
}

class _ConversationsSidebarSectionState
    extends ConsumerState<ConversationsSidebarSection> {
  /// The row last built for each space. A list change (a reorder when another
  /// space gets a message, a rename) hands the framework the SAME widget for
  /// every space whose rendered fields did not change, so those cards are
  /// skipped instead of rebuilt.
  final Map<String, SpaceSidebarGroup> _rows = {};

  SpaceSidebarGroup _row(Space space) {
    final cached = _rows[space.id];
    if (cached != null && sameSidebarSpace(cached.space, space)) {
      return cached;
    }
    return _rows[space.id] = SpaceSidebarGroup(
      key: ValueKey(space.id),
      space: space,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the read-cursor side effect alive while the sidebar is mounted: it
    // stamps the user's read cursor on selection so the unseen dot clears.
    ref.watch(selectedSpaceReadCursorEffectProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // Value-stable: re-emits only when a rendered field or the order of the
    // visible spaces changes, not on every message that bumps `updatedAt`.
    final spaces = workspaceId != null
        ? ref.watch(workspaceVisibleSpacesProvider(workspaceId))
        : ref.watch(visibleSpacesProvider);
    final l10n = AppLocalizations.of(context);

    // Partition by kind: human/system conversations stay in the main section
    // with their unread signals; agent↔agent DMs move to a separate, collapsed,
    // muted section so agent chatter never touches the human unread counts.
    final humanSpaces = spaces.where((c) => !c.kind.isAgentPeer).toList();
    final agentSpaces = spaces.where((c) => c.kind.isAgentPeer).toList();
    final humanIds = {for (final space in humanSpaces) space.id};
    _rows.removeWhere((id, _) => !humanIds.contains(id));

    // A plain column, not a shrink-wrapped non-scrolling ListView: this sits
    // inside the sidebar's own scrolling list, so a nested viewport bought
    // nothing but a second layout pass over every row.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _SidebarSection(
          label: l10n.spaces,
          collapsible: false,
          action: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // The archive sits LEFT of the `+`: shelving a space is the
              // quieter, less frequent act, so it takes the outer slot and
              // never pushes the creation affordance around.
              CcIconButton(
                icon: AppIcons.archive,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                tooltip: l10n.archivedSpaces,
                onPressed: () => showArchivedSpacesDialog(context),
              ),
              CcIconButton(
                icon: AppIcons.folder,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                tooltip: l10n.newSpaceFolder,
                onPressed: workspaceId == null
                    ? null
                    : () => showNewSpaceFolderDialog(context, ref, workspaceId),
              ),
              CcIconButton(
                icon: AppIcons.plus,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                tooltip: l10n.newSpace,
                onPressed: () => showNewSpaceDialog(context, ref),
              ),
            ],
          ),
          children: [
            if (humanSpaces.isEmpty) _EmptyHint(text: l10n.noSpacesYet),
            if (workspaceId != null)
              SpaceFoldersList(
                workspaceId: workspaceId,
                spaces: humanSpaces,
                spaceBuilder: _row,
              )
            else
              for (final space in humanSpaces) _row(space),
          ],
        ),
        // The sections carry no edge padding (so the list meets the sidebar's
        // hairlines flush), so the air between them is added here.
        if (agentSpaces.isNotEmpty) ...[
          AppSpacing.vGapSm,
          _SidebarSection(
            label: l10n.agentsSectionLabel,
            initiallyExpanded: false,
            children: [
              for (final space in agentSpaces)
                RouteSpaceSidebarItem(
                  key: ValueKey(space.id),
                  space: space,
                  muted: true,
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// A labelled sidebar section: a branded mono-eyebrow header carrying a
/// trailing [action], above its [children].
///
/// When [collapsible], the label and a rotating chevron toggle the section
/// (the agent-peer list starts collapsed). Spaces stay open: no caret, and
/// the label does not toggle.
///
/// [CcSidebarGroup] renders the same eyebrow + chevron treatment when
/// `collapsible`, but has no slot for a trailing action, so the header is
/// composed here (matching the group's eyebrow styling) and a [CcCollapsible]
/// gates a label-less [CcSidebarGroup] holding the items.
class _SidebarSection extends StatefulWidget {
  const _SidebarSection({
    required this.label,
    required this.children,
    this.action,
    this.collapsible = true,
    this.initiallyExpanded = true,
  });

  final String label;
  final Widget? action;
  final List<Widget> children;

  /// Whether the header caret and label hide [children].
  final bool collapsible;

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
    final expanded = !widget.collapsible || _expanded;
    final labelStyle = CcFonts.code(
      textStyle: CcTypography.label,
      family: context.ccTheme?.monoFontFamily,
    ).copyWith(color: color);
    final labelText = Text(
      widget.label.toUpperCase(),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: labelStyle,
    );
    // No vertical padding of its own: this section is the whole scrolling body
    // of the sidebar, so its edges meet the hairlines above and below, each of
    // which already carries [AppSpacing.xs]. Its own air on top of that read as
    // dead space at both ends of the list. Air BETWEEN stacked sections is the
    // caller's to add.
    return Column(
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
                  padding: const EdgeInsetsDirectional.only(start: 10),
                  child: Row(
                    children: [
                      // A collapsible section's label is a wide hit target
                      // for the toggle. Spaces is not: the label is text,
                      // and the trailing action sits beside it with no caret.
                      Expanded(
                        child: widget.collapsible
                            ? CcTappable(
                                onPressed: _toggle,
                                borderRadius: AppRadii.brSm,
                                semanticLabel: widget.label,
                                builder: (context, states) => labelText,
                              )
                            : labelText,
                      ),
                      // While transitioning the trailing widgets leave the
                      // layout too (the faded header keeps only its
                      // ellipsizing label): the `+` action and chevron are
                      // fixed-width and would overflow the narrowing row.
                      if (widget.action != null && !transitioning)
                        widget.action!,
                      if (widget.collapsible && !transitioning)
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
        // Collapsible sections animate their body; once open, CcCollapsible
        // follows the group's height directly, so a card changing height
        // inside never re-animates. Spaces stay open and skip the clip.
        if (widget.collapsible)
          CcCollapsible(
            expanded: expanded,
            child: CcSidebarGroup(children: widget.children),
          )
        else
          CcSidebarGroup(children: widget.children),
      ],
    );
  }
}

/// The rotating disclosure chevron trailing a [_SidebarSection] header. Tapping
/// it toggles the section — a sibling affordance to the tappable label — and it
/// rotates to point right when collapsed, matching the Tickets accordion and
/// [CcSidebarGroup]'s collapsible header.
///
/// The hit box is [kCcSidebarItemExtent] so the chevron shares the same 32px
/// slot as the archive/`+` [CcIconButton]s beside it — otherwise the 14px
/// glyph with a 4px pad sits tighter against the plus than the plus sits
/// against the archive.
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
        child: SizedBox(
          width: kCcSidebarItemExtent,
          height: kCcSidebarItemExtent,
          child: Center(
            child: AnimatedRotation(
              duration: CcMotion.resolveToggle(context, CcMotion.normal),
              curve: CcMotion.standard,
              turns: expanded ? 0 : -0.25,
              child: Icon(AppIcons.chevronDown, size: 14, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the "New space" dialog, creates the space (with zero or more
/// agents) and navigates to it.
Future<void> showNewSpaceDialog(BuildContext context, WidgetRef ref) async {
  // The route's `:workspaceId` is the source of truth — read it directly so the
  // new space always lands in the workspace the user is viewing, never a
  // stale/lagging `activeWorkspaceIdProvider` value. (We're inside the workspace
  // shell here, so the param is always present.) Read through the router, not
  // `GoRouterState`: that lookup would subscribe the sidebar to every later
  // navigation.
  final workspaceId = routeWorkspaceIdOf(context)!;
  // A bare `ref.read(...future)` adds no listener, and Riverpod pauses an
  // unlistened provider — so on a screen that doesn't already watch these
  // streams the future never resolved and the `+` did nothing until some
  // other screen subscribed. Hold a listener across the awaits.
  final agentsSub = ref.listenManual(
    workspaceAgentsProvider(workspaceId),
    (_, _) {},
  );
  final reposSub = ref.listenManual(
    reposForWorkspaceProvider(workspaceId),
    (_, _) {},
  );
  final List<Agent> agents;
  final List<Repo> repos;
  try {
    agents = await ref.read(workspaceAgentsProvider(workspaceId).future);
    repos = await ref.read(reposForWorkspaceProvider(workspaceId).future);
  } finally {
    agentsSub.close();
    reposSub.close();
  }
  if (!context.mounted) {
    return;
  }
  final result = await showCcDialog<_SpaceSpec>(
    context: context,
    builder: (_) => _CreateSpaceDialog(agents: agents, repos: repos),
  );
  if (result == null || result.name.isEmpty) {
    return;
  }

  final service = ref.read(messagingServiceProvider);
  final space = await service.createSpace(
    workspaceId,
    result.name,
    result.agentIds,
    repoIds: result.repoIds,
  );
  // Opened from the global sidebar: surface the new conversation. The URL is
  // the source of truth, so navigation drives the selection.
  if (context.mounted) {
    GoRouter.of(context).go(spaceRoute(workspaceId, space.id));
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

class _SpaceSpec {
  const _SpaceSpec({
    required this.name,
    required this.agentIds,
    required this.repoIds,
  });

  final String name;
  final List<String> agentIds;

  /// The repos this space provisions worktrees for. Null means "all workspace
  /// repos" (the provisioner's default); an EMPTY list means the space checks
  /// out no repos at all (every repo deselected).
  final List<String>? repoIds;
}

class _CreateSpaceDialog extends StatefulWidget {
  const _CreateSpaceDialog({required this.agents, required this.repos});

  final List<Agent> agents;
  final List<Repo> repos;

  @override
  State<_CreateSpaceDialog> createState() => _CreateSpaceDialogState();
}

class _CreateSpaceDialogState extends State<_CreateSpaceDialog> {
  final _nameController = TextEditingController();
  final Set<String> _selectedIds = {};

  /// Repos to provision. Defaults to ALL workspace repos so the space behaves
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
    // Offered whenever the workspace has any repo: even with a single repo
    // there is a real choice — deselecting it creates a repo-less space.
    final showRepoPicker = widget.repos.isNotEmpty;
    return CcDialog(
      title: l10n.newSpace,
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcTextField(controller: _nameController, hintText: l10n.spaceName),
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
                hintText: l10n.spaceReposHint,
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
            // Persist the selection only when it's a real subset: selecting
            // all (or the no-repo workspace) means null = "all repos", which
            // also follows repos added to the workspace later. An explicitly
            // emptied selection stays an empty list — a space with nothing
            // checked out.
            final repoIds = _selectedRepoIds.length == widget.repos.length
                ? null
                : _selectedRepoIds.toList();
            Navigator.of(context).pop(
              _SpaceSpec(
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
