import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/unified/unified_diff_measurement.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:flutter/widgets.dart';

/// Wraps [PrInlineThreadBlock] and reports its height after every layout so
/// the unified diff can reserve the exact gap under the anchor row.
///
/// A one-shot post-frame measure on this wrapper's `build` is not enough:
/// opening the reply composer is an inner `setState` that never rebuilds the
/// host, so the card would overflow the next file until something else (a
/// highlight click) forced a parent rebuild. [HeightReporter] observes the
/// render object, so that growth is reported on the same layout pass.
class MeasuredInlineThread extends StatelessWidget {
  /// Creates a measured inline thread.
  const MeasuredInlineThread({
    super.key,
    required this.thread,
    required this.controller,
    required this.onMeasured,
    this.collapsed = false,
    this.focused = false,
    this.resolveBusy = false,
    this.canResolve = true,
    this.onToggleCollapsed,
    this.onSetResolved,
  });

  /// The thread to render.
  final PrInlineThread thread;

  /// Controller backing reply/resolve/retry actions.
  final PrInlineCommentsController controller;

  /// Called after layout with the block's measured height.
  final ValueChanged<double> onMeasured;

  /// Whether to render the one-line summary instead of the full card.
  final bool collapsed;

  /// Whether this is the focused conversation (matches the active highlight).
  final bool focused;

  /// Whether a resolve write is in flight for this thread.
  final bool resolveBusy;

  /// Whether resolving this thread would actually change anything.
  final bool canResolve;

  /// Flips [collapsed]. Null hides the affordance.
  final VoidCallback? onToggleCollapsed;

  /// Marks the conversation resolved / reopened. Null hides the affordance.
  final ValueChanged<bool>? onSetResolved;

  @override
  Widget build(BuildContext context) {
    return HeightReporter(
      onMeasured: onMeasured,
      child: PrInlineThreadBlock(
        thread: thread,
        controller: controller,
        collapsed: collapsed,
        focused: focused,
        resolveBusy: resolveBusy,
        canResolve: canResolve,
        onToggleCollapsed: onToggleCollapsed,
        onSetResolved: onSetResolved,
      ),
    );
  }
}
