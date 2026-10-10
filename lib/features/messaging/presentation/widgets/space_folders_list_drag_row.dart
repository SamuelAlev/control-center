part of 'space_folders_list.dart';

/// Keeps the existing sidebar row and its hover semantics while making the
/// whole space a drag source in both sidebar layouts.
class _DraggableSpaceRow extends StatelessWidget implements CcFluidHoverTarget {
  const _DraggableSpaceRow({
    super.key,
    required this.space,
    required this.workspaceId,
    required this.available,
    required this.onDropOnSpace,
    required this.onDragStarted,
    required this.onDragEnd,
    required this.child,
  });

  final Space space;
  final String workspaceId;
  final Map<String, Space> available;
  final void Function(String sourceId, String targetId) onDropOnSpace;
  final VoidCallback onDragStarted;
  final ValueChanged<DraggableDetails> onDragEnd;
  final Widget child;

  @override
  bool get fluidHoverEnabled => true;

  @override
  Widget build(BuildContext context) {
    final tokens = context.ds;
    return DragTarget<_SpaceDragData>(
      onWillAcceptWithDetails: (details) =>
          details.data.workspaceId == workspaceId &&
          available.containsKey(details.data.spaceId),
      onAcceptWithDetails: (details) {
        if (details.data.spaceId != space.id) {
          onDropOnSpace(details.data.spaceId, space.id);
        }
      },
      builder: (context, candidates, _) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color:
                candidates.any(
                  (candidate) =>
                      candidate != null && candidate.spaceId != space.id,
                )
                ? tokens.accent
                : const Color(0x00000000),
          ),
          borderRadius: AppRadii.brSm,
        ),
        child: Draggable<_SpaceDragData>(
          data: (workspaceId: workspaceId, spaceId: space.id),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          onDragStarted: onDragStarted,
          onDragEnd: onDragEnd,
          feedback: DefaultTextStyle(
            style: CcTypography.body.copyWith(
              color: tokens.textPrimary,
              decoration: TextDecoration.none,
            ),
            child: SizedBox(
              width: 220,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.bgSecondary,
                  borderRadius: AppRadii.brSm,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Text(
                    space.name.isEmpty
                        ? AppLocalizations.of(context).spaceLabel
                        : space.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.4, child: child),
          child: child,
        ),
      ),
    );
  }
}
