part of 'app_sidebar.dart';

/// One routed destination of the global sidebar.
///
/// Watches only whether ITS destination is active (a `.select` over the
/// logical route), so a navigation rebuilds the row losing the highlight and
/// the row gaining it, nothing else. A [CcFluidHoverTarget] so the enclosing
/// group washes it like the plain [CcSidebarItem] it renders.
class _ShellNavItem extends ConsumerWidget implements CcFluidHoverTarget {
  const _ShellNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.logicalPath,
    required this.target,
    this.match = ShellNavMatch.section,
    this.iconBuilder,
    this.badge,
  });

  final IconData icon;
  final String label;

  /// The destination's prefix-stripped path, e.g. `/inbox`.
  final String logicalPath;

  /// The full (workspace-prefixed) route a press navigates to.
  final String target;

  /// How [logicalPath] is compared with the current logical route.
  final ShellNavMatch match;

  final Widget Function(Color color, double size)? iconBuilder;

  /// Builds the trailing badge for the row's selection state. Watches made
  /// here belong to this row, so a count change repaints only it.
  final Widget? Function(WidgetRef ref, bool selected)? badge;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = GoRouter.of(context);
    final selected = ref.watch(
      shellLogicalRouteProvider(
        router,
      ).select((logical) => shellRouteMatches(logical, logicalPath, match)),
    );
    return CcSidebarItem(
      icon: icon,
      label: label,
      iconBuilder: iconBuilder,
      badge: badge?.call(ref, selected),
      selected: selected,
      onPressed: () => router.go(target),
    );
  }
}

/// The Tickets entry of the global sidebar: the [_TicketsAccordion] expanded,
/// a single icon-only nav item in the rail. A dedicated widget so the swap is
/// driven by [CcSidebarScope] — the same deferred, animation-aware flag the
/// items themselves flip on — rather than the instantly-updating provider.
class _TicketsNavSlot extends StatelessWidget {
  const _TicketsNavSlot({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final collapsed = CcSidebarScope.collapsedOf(context) ?? false;
    if (!collapsed) {
      return _TicketsAccordion(workspaceId: workspaceId);
    }
    final l10n = AppLocalizations.of(context);
    return _ShellNavItem(
      icon: AppIcons.ticket,
      label: l10n.navTickets,
      logicalPath: '/tickets',
      target: ticketsRoute(workspaceId),
    );
  }
}

/// The Spaces slot of the global sidebar: the inline space list
/// ([ConversationsSidebarSection]) expanded, a single icon opening the
/// spaces directory page in the rail. Scope-driven like [_TicketsNavSlot].
class _SpacesNavSlot extends StatelessWidget {
  const _SpacesNavSlot({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    final collapsed = CcSidebarScope.collapsedOf(context) ?? false;
    if (!collapsed) {
      return const ConversationsSidebarSection();
    }
    final l10n = AppLocalizations.of(context);
    return CcSidebarGroup(
      children: [
        _ShellNavItem(
          icon: AppIcons.messagesSquare,
          label: l10n.spaces,
          logicalPath: '/spaces',
          target: spacesRoute(workspaceId),
        ),
      ],
    );
  }
}

/// The "Tickets" entry rendered as a collapsible accordion: pressing the
/// header navigates to all tickets, while a trailing chevron toggles the
/// project list; the children are "All tickets", one row per (non-archived)
/// project and a "New project" action. When there is no active workspace it
/// degrades to a plain nav item.
///
/// [CcSidebarItem] is a flat row with no nesting, so the accordion is composed
/// here from a header [CcSidebarItem] plus a [CcCollapsible]-gated
/// [CcSidebarBranch] (tree rail, flush children, nested hover). The composite
/// is not itself a [CcFluidHoverTarget], so the enclosing group treats it as
/// a hover boundary: the header row and the nested branch keep their own
/// wash instead of the parent highlighting Inbox or Pull requests.
class _TicketsAccordion extends ConsumerStatefulWidget {
  const _TicketsAccordion({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_TicketsAccordion> createState() => _TicketsAccordionState();
}

class _TicketsAccordionState extends ConsumerState<_TicketsAccordion> {
  // Sticky open/closed state. Seeded from the route on the first build, then
  // auto-expanded when entering the tickets/projects area — but never
  // auto-collapsed on leaving, so navigating away from "All tickets" no
  // longer snaps the accordion shut.
  bool? _expanded;

  static bool _isTicketsArea(String logical) =>
      logical == '/tickets' ||
      logical.startsWith('/tickets/') ||
      logical.startsWith('/projects/');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final wsId = widget.workspaceId;
    final router = GoRouter.of(context);
    final area = shellLogicalRouteProvider(router).select(_isTicketsArea);
    // Auto-expand only when entering the tickets/projects area from
    // elsewhere; a manual collapse while already inside the area is respected
    // and leaving the area never forces it closed. A listener, so other
    // navigations never rebuild the accordion.
    ref.listen<bool>(area, (previous, inArea) {
      if (inArea && previous != true && _expanded != true) {
        setState(() => _expanded = true);
      }
    });
    final bool expanded = _expanded ?? ref.read(area);
    _expanded = expanded;

    final projects =
        (ref.watch(workspaceProjectsProvider(wsId)).asData?.value ??
                const <Project>[])
            .where((p) => p.status != ProjectStatus.archived)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        CcSidebarItem(
          icon: AppIcons.ticket,
          label: l10n.navTickets,
          // The header is a group container, not a selectable leaf; the active
          // state is owned by the "All tickets" child (and project children).
          selected: false,
          badge: _ExpandChevron(
            expanded: expanded,
            onTap: () => setState(() => _expanded = !expanded),
          ),
          onPressed: () => router.go(ticketsRoute(wsId)),
        ),
        CcCollapsible(
          expanded: expanded,
          child: CcSidebarBranch(
            children: [
              _ShellNavItem(
                icon: AppIcons.list,
                label: l10n.allTickets,
                logicalPath: '/tickets',
                target: ticketsRoute(wsId),
              ),
              for (final p in projects)
                _ShellNavItem(
                  key: ValueKey(p.id),
                  icon: AppIcons.dot,
                  label: p.name,
                  logicalPath: '/projects/${p.id}',
                  match: ShellNavMatch.exact,
                  target: projectOverviewRoute(wsId, p.id),
                  badge: (_, selected) =>
                      ProjectGlyph(color: p.color, onBrandFill: selected),
                ),
              CcSidebarItem(
                icon: AppIcons.plus,
                label: l10n.newProject,
                onPressed: () => unawaited(_newProject(context, wsId)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _newProject(BuildContext context, String wsId) async {
    final router = GoRouter.of(context);
    final id = await showProjectDialog(context, workspaceId: wsId);
    if (id != null && context.mounted) {
      router.go(projectOverviewRoute(wsId, id));
    }
  }
}

/// A small rotating chevron used as the trailing affordance on the Tickets
/// accordion header. Tapping it toggles the project list without navigating.
class _ExpandChevron extends StatelessWidget {
  const _ExpandChevron({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onTap,
      semanticLabel: expanded ? l10n.collapse : l10n.expand,
      builder: (context, states) => AnimatedRotation(
        duration: CcMotion.resolveToggle(context, CcMotion.moderate),
        curve: CcMotion.standard,
        turns: expanded ? 0 : -0.25,
        child: Icon(
          AppIcons.chevronDown,
          size: 14,
          color: states.contains(WidgetState.hovered)
              ? t.textSecondary
              : t.textTertiary,
        ),
      ),
    );
  }
}
