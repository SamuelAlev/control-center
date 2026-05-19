import 'package:control_center/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_thread_widget.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:flutter/material.dart';

/// Wraps [PrInlineThreadBlock] and reports its post-layout height back to the
/// unified diff view so the next layout pass can reserve the exact gap under
/// the anchor row. Mirrors the old per-file viewer's measured-thread wrapper.
class MeasuredInlineThread extends StatefulWidget {
  /// Creates a measured inline thread.
  const MeasuredInlineThread({
    super.key,
    required this.thread,
    required this.controller,
    required this.onMeasured,
  });

  /// The thread to render.
  final PrInlineThread thread;

  /// Controller backing reply/resolve/retry actions.
  final PrInlineCommentsController controller;

  /// Called post-frame with the block's measured height.
  final ValueChanged<double> onMeasured;

  @override
  State<MeasuredInlineThread> createState() => _MeasuredInlineThreadState();
}

class _MeasuredInlineThreadState extends State<MeasuredInlineThread> {
  final _key = GlobalKey();

  void _reportSize() {
    final ctx = _key.currentContext;
    if (ctx == null) {
      return;
    }
    final box = ctx.findRenderObject();
    if (box is RenderBox && box.hasSize) {
      widget.onMeasured(box.size.height);
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
    return KeyedSubtree(
      key: _key,
      child: PrInlineThreadBlock(
        thread: widget.thread,
        controller: widget.controller,
      ),
    );
  }
}
