import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// An open inline composer request, anchored under display rows
/// `[startDisplayLine, endDisplayLine]` of `fileIndex`.
@immutable
class ComposerRequest {
  /// Creates a composer request anchored on the given display rows.
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

  /// Index of the file this composer is attached to.
  final int fileIndex;

  /// Display line the composer is anchored under.
  final int anchorDisplayLine;

  /// First display line of the selected range.
  final int startDisplayLine;

  /// Last display line of the selected range.
  final int endDisplayLine;

  /// Optional start column of a partial-line selection.
  final int? startCol;

  /// Optional end column of a partial-line selection.
  final int? endCol;

  /// Diff side (`old` / `new`) the range belongs to.
  final String side;

  /// First source line number of the range.
  final int lineNoStart;

  /// Last source line number of the range.
  final int lineNoEnd;

  /// Code quoted into the composer.
  final String originalCode;

  /// Whether this is a review comment or a suggestion.
  final PrInlineThreadKind kind;

  /// Comment draft shown alongside the editable replacement.
  final String initialComment;
}

/// Reports its child's laid-out height once per frame via [onMeasured], so the
/// document can reserve an exact gap for an inline composer (mirrors
/// `MeasuredInlineThread` for non-thread children).
class MeasuredHeight extends StatefulWidget {
  /// Creates a [MeasuredHeight] wrapper.
  const MeasuredHeight({
    super.key,
    required this.child,
    required this.onMeasured,
  });

  /// Child whose height is reported.
  final Widget child;

  /// Called once per frame with the child's laid-out height.
  final ValueChanged<double> onMeasured;

  @override
  State<MeasuredHeight> createState() => _MeasuredHeightState();
}

class _MeasuredHeightState extends State<MeasuredHeight> {
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
  /// Creates a [HeightReporter].
  const HeightReporter({
    super.key,
    required super.child,
    required this.onMeasured,
  });

  /// Called after every layout with the child's height.
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

/// Render object that reports its child's height after every layout.
class RenderHeightReporter extends RenderProxyBox {
  /// Creates a [RenderHeightReporter] that notifies [onMeasured].
  RenderHeightReporter(this.onMeasured);

  /// Callback invoked when the laid-out height changes.
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
