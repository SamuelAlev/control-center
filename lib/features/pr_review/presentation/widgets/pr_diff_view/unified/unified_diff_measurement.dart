import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// An open inline composer request, anchored under display rows
/// `[startDisplayLine, endDisplayLine]` of [fileIndex].
@immutable
class ComposerRequest {
  const ComposerRequest({
    required this.fileIndex,
    required this.anchorDisplayLine,
    required this.startDisplayLine,
    required this.endDisplayLine,
    required this.startCol,
    required this.endCol,
    required this.side,
    required this.lineNoStart,
    required this.lineNoEnd,
    required this.originalCode,
    required this.kind,
    this.initialComment = '',
  });

  final int fileIndex;
  final int anchorDisplayLine;
  final int startDisplayLine;
  final int endDisplayLine;
  final int? startCol;
  final int? endCol;
  final String side;
  final int lineNoStart;
  final int lineNoEnd;
  final String originalCode;
  final PrInlineThreadKind kind;

  /// Comment draft shown alongside the editable replacement.
  final String initialComment;
}

/// Reports its child's laid-out height once per frame via [onMeasured], so the
/// document can reserve an exact gap for an inline composer (mirrors
/// [MeasuredInlineThread] for non-thread children).
class MeasuredHeight extends StatefulWidget {
  const MeasuredHeight({
    super.key,
    required this.child,
    required this.onMeasured,
  });
  final Widget child;
  final ValueChanged<double> onMeasured;

  @override
  State<MeasuredHeight> createState() => MeasuredHeightState();
}

class MeasuredHeightState extends State<MeasuredHeight> {
  final _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void didUpdateWidget(covariant MeasuredHeight oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        widget.onMeasured(box.size.height);
      }
    });
  }

  @override
  Widget build(BuildContext context) =>
      KeyedSubtree(key: _key, child: widget.child);
}

/// Reports its child's height after EVERY layout (not just once), so a child
/// that grows after the first frame — the Markdown preview, which starts as a
/// loader then lays out the fetched content — keeps the document's reserved
/// body height exact. A one-shot post-frame measure ([MeasuredHeight]) misses
/// that async growth and leaves the body too short.
class HeightReporter extends SingleChildRenderObjectWidget {
  const HeightReporter({
    super.key,
    required super.child,
    required this.onMeasured,
  });

  final ValueChanged<double> onMeasured;

  @override
  RenderHeightReporter createRenderObject(BuildContext context) =>
      RenderHeightReporter(onMeasured);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderHeightReporter renderObject,
  ) {
    renderObject.onMeasured = onMeasured;
  }
}

class RenderHeightReporter extends RenderProxyBox {
  RenderHeightReporter(this.onMeasured);

  ValueChanged<double> onMeasured;
  double _lastReported = -1;

  @override
  void performLayout() {
    super.performLayout();
    final h = size.height;
    if ((h - _lastReported).abs() >= 0.5) {
      _lastReported = h;
      onMeasured(h);
    }
  }
}
