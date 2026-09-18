import 'package:cc_ui/src/components/cc_sidebar.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// Nested children of a sidebar accordion, drawn against a vertical rail.
///
/// The rail is a 1px `lineStrong` hairline aligned to the parent row's icon
/// center ([kCcSidebarItemIconCenter]). That is the same structural line as
/// DAG edges and required dividers, so it stays visible on both the light
/// and dark sidebar. Children sit at [AppSpacing.xl] (24px) so their
/// hover/selected pills stay to the end of the rail and never cover it.
/// Inter-item gap is 0: a tree, not a list.
///
/// In the enclosing [CcSidebar]'s collapsed rail the indent and hairline
/// drop so children remain 32px squares.
///
/// Owns a nested [CcFluidHover] so the enclosing [CcSidebarGroup] can treat
/// the branch as a boundary while children still wash. Place the branch as
/// a *direct* group child after its parent row so expanded groups stay flush.
class CcSidebarBranch extends StatelessWidget {
  /// Creates a [CcSidebarBranch].
  const CcSidebarBranch({super.key, required this.children});

  /// Nested rows (typically [CcSidebarItem]s). Empty yields nothing.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    final railCollapsed = CcSidebarScope.collapsedOf(context) ?? false;
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;
    final dropTree = railCollapsed || transitioning;

    return CcFluidHover(
      mouseCursor: SystemMouseCursors.click,
      itemCount: children.length,
      // Same contract as [CcSidebarGroup]: only [CcFluidHoverTarget]s are
      // rows. A nested composite inside the branch is its own boundary.
      isItemBoundary: (index) => children[index] is! CcFluidHoverTarget,
      isItemDisabled: (index) {
        final child = children[index];
        if (child case final CcFluidHoverTarget target) {
          return !target.fluidHoverEnabled;
        }
        return true;
      },
      itemBuilder: (context, index) => children[index],
      layoutBuilder: (context, items) {
        if (dropTree) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in items)
                Align(
                  child: SizedBox(width: kCcSidebarItemExtent, child: item),
                ),
            ],
          );
        }

        return Stack(
          clipBehavior: Clip.none,
          children: [
            const PositionedDirectional(
              start: kCcSidebarItemIconCenter,
              top: 0,
              bottom: 0,
              width: 1,
              child: _CcSidebarBranchRail(),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: items,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The 1px tree spine. Ignore-pointer so the gutter still belongs to the
/// nested hover group (nearest child washes when the pointer is on the rail).
class _CcSidebarBranchRail extends StatelessWidget {
  const _CcSidebarBranchRail();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ColoredBox(
        key: const ValueKey<String>('cc-sidebar-branch-rail'),
        color: context.ds.lineStrong,
      ),
    );
  }
}
