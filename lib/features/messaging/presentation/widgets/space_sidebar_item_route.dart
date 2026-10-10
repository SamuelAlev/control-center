part of 'space_sidebar_item.dart';

/// A [SpaceSidebarItem] that reads its own selection from the route and opens
/// its space on press. The flat rows (agent DMs, the spaces directory page)
/// use it so a navigation rebuilds only the rows whose highlight changed.
class RouteSpaceSidebarItem extends ConsumerWidget
    implements CcFluidHoverTarget {
  /// Creates a [RouteSpaceSidebarItem].
  const RouteSpaceSidebarItem({
    super.key,
    required this.space,
    this.muted = false,
  });

  /// The space to render.
  final Space space;

  /// See [SpaceSidebarItem.muted].
  final bool muted;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SpaceSidebarItem(
      space: space,
      selected: watchRouteSpaceSelected(context, ref, space.id),
      muted: muted,
      onPress: () => openSpaceFromSidebar(context, space.id),
    );
  }
}
