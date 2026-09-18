import 'package:control_center/features/messaging/providers/visible_conversation_spaces.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Refcounts [spaceId] as a visible conversation for as long as this widget
/// is mounted, so the global approval overlay can hide requests this pane
/// already shows inline.
class VisibleConversationRegistrar extends ConsumerStatefulWidget {
  /// Creates a [VisibleConversationRegistrar].
  const VisibleConversationRegistrar({
    super.key,
    required this.spaceId,
    required this.child,
  });

  /// The space whose conversation this subtree is showing.
  final String spaceId;

  /// The pane contents.
  final Widget child;

  @override
  ConsumerState<VisibleConversationRegistrar> createState() =>
      _VisibleConversationRegistrarState();
}

class _VisibleConversationRegistrarState
    extends ConsumerState<VisibleConversationRegistrar> {
  /// Cached in [initState]: [WidgetRef.read] is unsafe once this State is
  /// deactivating, and [dispose] still has to release the refcount.
  late final VisibleConversationSpaces _spaces;

  @override
  void initState() {
    super.initState();
    _spaces = ref.read(visibleConversationSpacesProvider.notifier);
    _spaces.acquire(widget.spaceId);
  }

  @override
  void didUpdateWidget(VisibleConversationRegistrar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spaceId == widget.spaceId) {
      return;
    }
    _spaces.release(oldWidget.spaceId);
    _spaces.acquire(widget.spaceId);
  }

  @override
  void dispose() {
    _spaces.release(widget.spaceId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
