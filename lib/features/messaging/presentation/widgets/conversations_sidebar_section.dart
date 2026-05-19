import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/presentation/ide/editor/messaging_tab_kinds.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_sidebar_item.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/editor/host/editor_tab_url_sync.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Spaces" group rendered inline in the global app sidebar: the space
/// list with its `+` action, empty hint and space rows. A separate
/// [ConsumerWidget] so space/selection watches rebuild only this group, not
/// the Work/Team/Knowledge groups.
///
/// Tapping a row navigates to that space ([spaceRoute]); the URL is the
/// source of truth for the open space, so the row's active highlight follows
/// the route's `:spaceId` and clears the moment the user navigates away.
class ConversationsSidebarSection extends ConsumerWidget {
  /// Creates a [ConversationsSidebarSection].
  const ConversationsSidebarSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Keeps the read-cursor side effect alive while the sidebar is mounted: it
    // stamps the user's read cursor on selection so the unseen dot clears.
    ref.watch(selectedSpaceReadCursorEffectProvider);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    // The URL is the source of truth for the open space: a row reads as
    // selected iff its id is the route's `:spaceId`. The sidebar lives in the
    // shell (above the route's page), so the child route's path parameters
    // aren't in scope here — derive the id from the full location instead.
    // Reading GoRouterState makes the section rebuild on navigation, so the
    // highlight clears the moment the user leaves the space surface.
    final routeSpaceId = selectedSpaceIdFromLocation(
      GoRouterState.of(context).uri.path,
      workspaceId,
    );
    final spaces = workspaceId != null
        ? ref.watch(workspaceVisibleSpacesProvider(workspaceId))
        : ref.watch(visibleSpacesProvider);
    final l10n = AppLocalizations.of(context);

    // Partition by kind: human/system conversations stay in the main section
    // with their unread signals; agent↔agent DMs move to a separate, collapsed,
    // muted section so agent chatter never touches the human unread counts.
    final humanSpaces = spaces.where((c) => !c.kind.isAgentPeer).toList();
    final agentSpaces = spaces.where((c) => c.kind.isAgentPeer).toList();

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _SidebarSection(
          label: l10n.spaces,
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
                icon: AppIcons.plus,
                size: CcButtonSize.sm,
                variant: CcButtonVariant.ghost,
                tooltip: l10n.newSpace,
                onPressed: () => showNewSpaceDialog(context, ref),
              ),
            ],
          ),
          children: [
            if (humanSpaces.isEmpty)
              _EmptyHint(text: l10n.noSpacesYet)
            else
              for (final space in humanSpaces)
                _SpaceEntry(
                  space: space,
                  selected: space.id == routeSpaceId,
                  onPress: () => _selectAndNavigate(context, ref, space.id),
                ),
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
                SpaceSidebarItem(
                  space: space,
                  selected: space.id == routeSpaceId,
                  muted: true,
                  onPress: () => _selectAndNavigate(context, ref, space.id),
                ),
            ],
          ),
        ],
      ],
    );
  }

  void _selectAndNavigate(BuildContext context, WidgetRef ref, String spaceId) {
    // Navigate only — MessagingScreen mirrors the URL into the selection
    // provider, keeping the URL the single source of truth.
    GoRouter.of(context).go(spaceRoute(context.currentWorkspaceId!, spaceId));
  }
}

/// One space in the sidebar, folder-style: the space row plus — when the space
/// holds parallel conversations — a flat indented row per ACTIVE conversation
/// beneath it, the same set the space opens as editor tabs, with a quiet count
/// chip on the space row. Solo-first: a single-conversation space renders just
/// the space row (the row itself opens that conversation).
class _SpaceEntry extends ConsumerWidget {
  const _SpaceEntry({
    required this.space,
    required this.selected,
    required this.onPress,
  });

  /// The space to render.
  final Space space;

  /// Whether this space is the route's selected space.
  final bool selected;

  /// Tap handler for the space row itself.
  final VoidCallback onPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations =
        ref.watch(spaceConversationsProvider(space.id)).value ??
        const <Conversation>[];
    final active = conversations
        .where((c) => !c.isArchived)
        .toList(growable: false);
    final listed = active.length > 1;
    // Which of the rows below is actually working. Only hand the space row's
    // spinner down when a row the user can see will pick it up — a run in an
    // archived conversation, or one carrying no conversation id, has no visible
    // home and must keep its signal on the space.
    final busyIds = listed
        ? ref.watch(spaceBusyConversationIdsProvider(space.id))
        : const <String>{};
    final busyHere = listed && active.any((c) => busyIds.contains(c.id));
    final row = SpaceSidebarItem(
      space: space,
      selected: selected,
      conversationCount: listed ? active.length : null,
      runningShownOnConversations: busyHere,
      onPress: onPress,
    );
    if (!listed) {
      return row;
    }

    // The indent drops in rail mode / while the width animates: at the rail's
    // width it would push the rows past the edge (same rule as the Tickets
    // accordion children).
    final railMode =
        (CcSidebarScope.collapsedOf(context) ?? false) ||
        (CcSidebarScope.transitioningOf(context) ?? false);

    // The focused conversation follows the URL: the path names the space and
    // `?tab=` the focused editor tab, so the highlight clears the moment a
    // non-chat tab (or another space) takes focus. A tab-less URL — and the
    // seeded no-arg chat tab's space key — means the standing conversation,
    // resolved only while the space is open (the provider is then already
    // warm from the space surface itself).
    final tabKey = selected
        ? GoRouterState.of(context).uri.queryParameters[editorTabQueryParam]
        : null;
    final standingId = selected
        ? ref.watch(standingConversationIdProvider(space.id)).value
        : null;
    bool focused(Conversation c) {
      if (!selected) {
        return false;
      }
      if (tabKey == null ||
          tabKey == MessagingTabKinds.chatSpaceTabKey(space.id)) {
        return c.id == standingId;
      }
      return tabKey == MessagingTabKinds.chatTabKey(c.id);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        row,
        Padding(
          padding: EdgeInsets.only(left: railMode ? 0 : AppSpacing.md),
          // A label-less group keeps the rows on the sidebar's 4px rhythm.
          child: CcSidebarGroup(
            children: [
              for (final c in active)
                _ConversationRow(
                  key: ValueKey(c.id),
                  conversation: c,
                  spaceId: space.id,
                  selected: focused(c),
                  running: busyIds.contains(c.id),
                  // The last active conversation stays: a space always keeps
                  // one live stream, so archiving it would only mint a fresh
                  // standing one under a different name.
                  canArchive: active.length > 1,
                  onPress: () => GoRouter.of(context).go(
                    spaceRoute(
                      context.currentWorkspaceId!,
                      space.id,
                      tab: MessagingTabKinds.chatTabKey(c.id),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One conversation beneath its space in the global sidebar.
///
/// Built on [SpaceRow] rather than [CcSidebarItem] for one reason: the leading
/// slot has to hold a SPINNER while this conversation's agent is working, and
/// [CcSidebarItem] takes an `IconData`, not a widget. [SpaceRow] reproduces the
/// same look and already handles the rail-mode/width-transition behaviour a
/// hand-rolled row would get subtly wrong.
class _ConversationRow extends ConsumerWidget {
  const _ConversationRow({
    super.key,
    required this.conversation,
    required this.spaceId,
    required this.selected,
    required this.running,
    required this.canArchive,
    required this.onPress,
  });

  final Conversation conversation;
  final String spaceId;
  final bool selected;

  /// Whether an agent run is in flight in THIS conversation.
  final bool running;

  /// Whether archiving is offered — false for a space's last active
  /// conversation, which must stay.
  final bool canArchive;

  final VoidCallback onPress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onSecondaryTapDown: (details) =>
          _showMenu(context, ref, details.globalPosition),
      // Touch parity for the right-click menu — it OPENS the menu, it never
      // archives directly: an archived conversation has no restore surface,
      // so an instant fire is unrecoverable (the space row's long-press CAN
      // archive — archived spaces are restorable from the archive dialog).
      onLongPressStart: (details) =>
          _showMenu(context, ref, details.globalPosition),
      child: SpaceRow(
        leading: running
            // The default accent spinner would vanish into the selected row's
            // solid brand fill, so it follows the row's content colour.
            ? CcSpinner(size: 18, color: selected ? t.accentOn : null)
            : Icon(
                conversation.isThread
                    ? AppIcons.gitBranch
                    : AppIcons.messageSquareText,
                size: 18,
              ),
        label: conversationDisplayName(conversation, l10n),
        selected: selected,
        status: running ? SpaceStatus.running : SpaceStatus.idle,
        // Unread is a SPACE-level signal (`spaceUnreadProvider`) and stays on
        // the space row: duplicating one dot onto every child would say four
        // things are unseen when one is.
        unread: false,
        leadingHandlesRunning: true,
        onPress: onPress,
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref, Offset position) {
    final l10n = AppLocalizations.of(context);
    showCcMenuAt(
      context: context,
      position: position,
      items: [
        CcMenuItem(
          label: l10n.renameConversation,
          icon: AppIcons.pencil,
          onSelected: () => unawaited(_rename(context, ref)),
        ),
        CcMenuItem(
          label: l10n.archiveConversation,
          icon: AppIcons.archive,
          enabled: canArchive,
          onSelected: () => unawaited(_archive(context, ref)),
        ),
      ],
    );
  }

  /// Renames the conversation (the row follows the live watch; the id — and
  /// so any open tab — never changes).
  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return;
    }
    final name = await showRenameDialog(
      context,
      title: AppLocalizations.of(context).renameConversation,
      initialValue: conversation.title,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await ref
        .read(conversationRepositoryProvider)
        .rename(
          workspaceId: workspaceId,
          conversationId: conversation.id,
          title: name,
        );
  }

  Future<void> _archive(BuildContext context, WidgetRef ref) async {
    if (!canArchive) {
      return;
    }
    final workspaceId = context.currentWorkspaceId;
    if (workspaceId == null) {
      return;
    }
    await ref
        .read(conversationRepositoryProvider)
        .setStatus(
          workspaceId: workspaceId,
          conversationId: conversation.id,
          status: ConversationStatus.archived,
        );
    // The row leaves on its own — `spaceConversationsProvider` is a live watch
    // and every list here filters to active. Navigation only needs handling
    // when the archived conversation is the one on screen: leaving `?tab=`
    // pointing at it would hold a tab open for a conversation the sidebar has
    // already dropped.
    if (context.mounted && selected) {
      GoRouter.of(context).go(spaceRoute(workspaceId, spaceId));
    }
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
              duration: CcMotion.normal,
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
  // shell here, so the param is always present.)
  final workspaceId = context.currentWorkspaceId!;
  final agents = await ref.read(workspaceAgentsProvider(workspaceId).future);
  final repos = await ref.read(reposForWorkspaceProvider(workspaceId).future);
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

// ── Dialogs ────────────────────────────────────────────────────────────────

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

/// Opens the archived-spaces dialog (the trigger left of the sidebar's `+`):
/// every archived space of the current workspace, most-recently-archived
/// first. Restore returns a space to the sidebar and opens it; the per-row
/// delete is the one remaining path to permanent deletion, behind a
/// confirmation — archiving itself never destroys anything.
Future<void> showArchivedSpacesDialog(BuildContext context) {
  // Resolved in the SIDEBAR's context, under the router: the dialog mounts in
  // the root overlay, where `GoRouterState.of` — and so `currentWorkspaceId` —
  // has no route above it (same reason [showNewSpaceDialog] reads the id
  // before opening).
  final workspaceId = context.currentWorkspaceId!;
  final router = GoRouter.of(context);
  return showCcDialog<void>(
    context: context,
    builder: (_) =>
        _ArchivedSpacesDialog(workspaceId: workspaceId, router: router),
  );
}

class _ArchivedSpacesDialog extends ConsumerWidget {
  const _ArchivedSpacesDialog({
    required this.workspaceId,
    required this.router,
  });

  /// The workspace whose archived spaces are listed (resolved by the caller,
  /// never from the dialog's overlay context).
  final String workspaceId;

  /// The app's router, captured by the caller for the same reason — restore
  /// navigates to the reopened space.
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final archived = ref.watch(archivedSpacesProvider(workspaceId));
    return CcDialog(
      title: l10n.archivedSpaces,
      content: SizedBox(
        width: 360,
        child: archived.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  l10n.archivedSpacesEmpty,
                  style: CcTypography.caption.copyWith(
                    color: context.designSystem?.textTertiary,
                  ),
                ),
              )
            : ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 320),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final space in archived)
                      CcTile(
                        leadingIcon: AppIcons.archive,
                        title: space.name.isNotEmpty
                            ? space.name
                            : l10n.spaceLabel,
                        subtitle: Text(
                          l10n.archivedWhen(
                            formatRelativeTime(context, space.archivedAt),
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CcIconButton(
                              icon: AppIcons.archiveRestore,
                              size: CcButtonSize.sm,
                              variant: CcButtonVariant.ghost,
                              tooltip: l10n.restoreSpace,
                              onPressed: () =>
                                  unawaited(_restore(context, ref, space)),
                            ),
                            CcIconButton(
                              icon: AppIcons.trash2,
                              size: CcButtonSize.sm,
                              variant: CcButtonVariant.ghost,
                              tooltip: l10n.deleteSpacePermanently,
                              onPressed: () => unawaited(
                                _confirmDeletePermanently(context, ref, space),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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

  /// Restores [space] to the sidebar and opens it — the visible proof the
  /// archive kept everything (messages, participants, worktrees) intact.
  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    Space space,
  ) async {
    await ref
        .read(messagingServiceProvider)
        .unarchiveSpace(workspaceId, space.id);
    if (context.mounted) {
      Navigator.of(context).pop();
      router.go(spaceRoute(workspaceId, space.id));
    }
  }

  Future<void> _confirmDeletePermanently(
    BuildContext context,
    WidgetRef ref,
    Space space,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteSpace,
        content: Text(l10n.deleteSpaceConfirm),
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
    if (confirmed != true || !context.mounted) {
      return;
    }
    await ref.read(messagingServiceProvider).deleteSpace(workspaceId, space.id);
    // No navigation handling: the row drops out of the dialog's watched list
    // on its own, and an archived space cannot be the open route space.
  }
}
