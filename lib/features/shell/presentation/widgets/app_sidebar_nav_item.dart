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
