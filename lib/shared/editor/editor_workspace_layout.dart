// RTL carve-out: this solver computes explicit viewport rectangles and
// physical clip alignments after mirroring horizontal split order for RTL.
import 'dart:math' as math;

import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Minimum extent along the split axis for a pane in an editor workspace.
const double kEditorMinPaneExtent = 120;

/// Hit-target thickness centered on each split seam.
const double kEditorDividerHitSize = 8;

/// Placement metadata for one draggable divider seam between two siblings of
/// an [EditorSplitNode].
class EditorDividerPlacement {
  /// Creates an [EditorDividerPlacement].
  const EditorDividerPlacement({
    required this.splitNode,
    required this.dividerIndex,
    required this.axis,
    required this.splitExtent,
    required this.hitRect,
    required this.isRtl,
  });

  /// Owning split node.
  final EditorSplitNode splitNode;

  /// Index of the divider (`0 <= dividerIndex < splitNode.children.length - 1`).
  final int dividerIndex;

  /// Split axis.
  final Axis axis;

  /// Available extent of [splitNode] along [axis].
  final double splitExtent;

  /// Physical hit-test rectangle in workspace coordinates.
  final Rect hitRect;

  /// Whether horizontal drag deltas must be inverted for RTL layout.
  final bool isRtl;

  /// Stable identifier for keying the divider widget.
  String get id => '${splitNode.id}:$dividerIndex';
}

/// Solved flat geometry for an entire [EditorNode] tree inside a viewport.
class EditorWorkspaceLayout {
  /// Creates an [EditorWorkspaceLayout].
  const EditorWorkspaceLayout({
    required this.leafRects,
    required this.leaves,
    required this.leafOrder,
    required this.dividers,
  });

  /// Target rectangle per leaf id.
  final Map<String, Rect> leafRects;

  /// Leaf nodes keyed by id.
  final Map<String, EditorLeafNode> leaves;

  /// Leaves in deterministic tree order.
  final List<String> leafOrder;

  /// Dividers in tree order.
  final List<EditorDividerPlacement> dividers;
}

/// Computes normalized child extents summing to [available] while honoring
/// `min(kEditorMinPaneExtent, available / weights.length)`.
List<double> _solveSplitExtents(List<double> weights, double available) {
  final n = weights.length;
  if (n == 0 || available <= 0) {
    return List.filled(n, 0);
  }
  final clamped = [for (final w in weights) w <= 0 ? 0.0 : w];
  final sum = clamped.fold<double>(0, (a, b) => a + b);
  final norm = sum <= 0
      ? List.filled(n, 1 / n)
      : [for (final w in clamped) w / sum];

  final effectiveMin = math.min(kEditorMinPaneExtent, available / n);
  final extents = [
    for (final w in norm) math.max(effectiveMin, w * available),
  ];

  final total = extents.fold<double>(0, (a, b) => a + b);
  final excess = total - available;
  if (excess > 1e-6) {
    final slackCapacity = extents.fold<double>(
      0,
      (acc, e) => acc + math.max(0, e - effectiveMin),
    );
    if (slackCapacity > 0) {
      final keepRatio = ((slackCapacity - excess) / slackCapacity).clamp(
        0.0,
        1.0,
      );
      for (var i = 0; i < n; i++) {
        final over = math.max(0.0, extents[i] - effectiveMin);
        extents[i] = effectiveMin + over * keepRatio;
      }
    }
  }
  return extents;
}

/// Projects [root] into flat leaf rectangles and divider placements inside
/// [size].
EditorWorkspaceLayout solveEditorWorkspaceLayout(
  EditorNode root,
  Size size,
  TextDirection textDirection, {
  double dividerHitSize = kEditorDividerHitSize,
}) {
  final leafRects = <String, Rect>{};
  final leaves = <String, EditorLeafNode>{};
  final leafOrder = <String>[];
  final dividers = <EditorDividerPlacement>[];

  void visit(EditorNode node, Rect rect) {
    if (node is EditorLeafNode) {
      leafRects[node.id] = rect;
      leaves[node.id] = node;
      leafOrder.add(node.id);
      return;
    }
    final split = node as EditorSplitNode;
    final isHorizontal = split.axis == Axis.horizontal;
    final isRtl = isHorizontal && textDirection == TextDirection.rtl;
    final available = isHorizontal ? rect.width : rect.height;
    final extents = _solveSplitExtents(split.weights, available);
    final n = split.children.length;

    var cursor = isHorizontal
        ? (isRtl ? rect.right : rect.left)
        : rect.top;
    final seams = <double>[];

    for (var i = 0; i < n; i++) {
      final extent = extents[i];
      late final Rect childRect;
      if (isHorizontal) {
        if (isRtl) {
          childRect = Rect.fromLTWH(
            cursor - extent,
            rect.top,
            extent,
            rect.height,
          );
          cursor -= extent;
        } else {
          childRect = Rect.fromLTWH(cursor, rect.top, extent, rect.height);
          cursor += extent;
        }
      } else {
        childRect = Rect.fromLTWH(rect.left, cursor, rect.width, extent);
        cursor += extent;
      }
      if (i < n - 1) {
        seams.add(cursor);
      }
      visit(split.children[i], childRect);
    }

    for (var i = 0; i < seams.length; i++) {
      final seam = seams[i];
      final hitRect = isHorizontal
          ? Rect.fromLTWH(
              seam - dividerHitSize / 2,
              rect.top,
              dividerHitSize,
              rect.height,
            )
          : Rect.fromLTWH(
              rect.left,
              seam - dividerHitSize / 2,
              rect.width,
              dividerHitSize,
            );
      dividers.add(
        EditorDividerPlacement(
          splitNode: split,
          dividerIndex: i,
          axis: split.axis,
          splitExtent: available,
          hitRect: hitRect,
          isRtl: isRtl,
        ),
      );
    }
  }

  visit(
    root,
    Rect.fromLTWH(
      0,
      0,
      math.max(0, size.width),
      math.max(0, size.height),
    ),
  );
  return EditorWorkspaceLayout(
    leafRects: leafRects,
    leaves: leaves,
    leafOrder: leafOrder,
    dividers: dividers,
  );
}

/// Transfers [delta] logical pixels across [dividerIndex] in [split] within
/// [available] total extent along `split.axis`. Returns `true` if weights
/// changed.
bool resizeEditorSplit(
  EditorSplitNode split,
  int dividerIndex,
  double delta,
  double available,
) {
  if (dividerIndex < 0 ||
      dividerIndex + 1 >= split.children.length ||
      delta == 0 ||
      available <= 0) {
    return false;
  }
  final extents = _solveSplitExtents(split.weights, available);
  final effectiveMin = math.min(
    kEditorMinPaneExtent,
    available / split.children.length,
  );
  final before = extents[dividerIndex];
  final after = extents[dividerIndex + 1];
  final maxGrow = math.max(0.0, after - effectiveMin);
  final maxShrink = math.max(0.0, before - effectiveMin);
  final applied = delta.clamp(-maxShrink, maxGrow).toDouble();
  if (applied.abs() < 1e-6) {
    return false;
  }
  extents[dividerIndex] = before + applied;
  extents[dividerIndex + 1] = after - applied;
  for (var i = 0; i < extents.length; i++) {
    split.weights[i] = extents[i] / available;
  }
  return true;
}

/// Computes live divider placements for the current animated [animatedLeafRects]
/// so seams travel smoothly along with resizing panes.
List<EditorDividerPlacement> computeAnimatedDividers(
  EditorNode root,
  Map<String, Rect> animatedLeafRects,
  TextDirection textDirection, {
  double dividerHitSize = kEditorDividerHitSize,
}) {
  final dividers = <EditorDividerPlacement>[];

  Rect? boundsOf(EditorNode node) {
    if (node is EditorLeafNode) {
      return animatedLeafRects[node.id];
    }
    final split = node as EditorSplitNode;
    final childBounds = [for (final c in split.children) boundsOf(c)];
    Rect? union;
    for (final b in childBounds) {
      if (b != null) {
        union = union == null ? b : union.expandToInclude(b);
      }
    }
    if (union == null) {
      return null;
    }
    final isHorizontal = split.axis == Axis.horizontal;
    final isRtl = isHorizontal && textDirection == TextDirection.rtl;
    final available = isHorizontal ? union.width : union.height;
    for (var i = 0; i < split.children.length - 1; i++) {
      final a = childBounds[i];
      final b = childBounds[i + 1];
      if (a == null || b == null) {
        continue;
      }
      final double seam;
      final Rect hitRect;
      if (isHorizontal) {
        seam = isRtl ? (a.left + b.right) / 2 : (a.right + b.left) / 2;
        hitRect = Rect.fromLTWH(
          seam - dividerHitSize / 2,
          union.top,
          dividerHitSize,
          union.height,
        );
      } else {
        seam = (a.bottom + b.top) / 2;
        hitRect = Rect.fromLTWH(
          union.left,
          seam - dividerHitSize / 2,
          union.width,
          dividerHitSize,
        );
      }
      dividers.add(
        EditorDividerPlacement(
          splitNode: split,
          dividerIndex: i,
          axis: split.axis,
          splitExtent: available,
          hitRect: hitRect,
          isRtl: isRtl,
        ),
      );
    }
    return union;
  }

  boundsOf(root);
  return dividers;
}

(EditorSplitNode, int)? _findParent(EditorNode root, String leafId) {
  if (root is EditorSplitNode) {
    for (var i = 0; i < root.children.length; i++) {
      final child = root.children[i];
      if (child is EditorLeafNode && child.id == leafId) {
        return (root, i);
      }
      final nested = _findParent(child, leafId);
      if (nested != null) {
        return nested;
      }
    }
  }
  return null;
}

/// Computes the starting rectangle and content-pinning alignment for a newly
/// created leaf [leafId] sliding open from its split seam.
({Rect fromRect, Alignment alignment}) computeEnteringPaneStart({
  required EditorNode root,
  required String leafId,
  required Rect toRect,
  required Map<String, Rect> prevRects,
  required TextDirection textDirection,
  ({String leafId, Axis axis, bool before})? splitOrigin,
}) {
  late final Axis axis;
  late final bool before;

  if (splitOrigin != null && splitOrigin.leafId == leafId) {
    axis = splitOrigin.axis;
    before = splitOrigin.before;
  } else {
    final parentRef = _findParent(root, leafId);
    if (parentRef == null) {
      axis = Axis.horizontal;
      before = false;
    } else {
      final (split, idx) = parentRef;
      axis = split.axis;
      if (idx == 0) {
        before = true;
      } else if (idx == split.children.length - 1) {
        before = false;
      } else {
        // Infer which sibling gave up space to host the middle insertion.
        final prevSibling = split.children[idx - 1];
        if (prevSibling is EditorLeafNode &&
            prevRects.containsKey(prevSibling.id)) {
          final r = prevRects[prevSibling.id]!;
          final shrankFromEnd = axis == Axis.horizontal
              ? (textDirection == TextDirection.rtl
                    ? r.left < toRect.right - 1
                    : r.right > toRect.left + 1)
              : r.bottom > toRect.top + 1;
          before = !shrankFromEnd;
        } else {
          before = false;
        }
      }
    }
  }

  if (axis == Axis.horizontal) {
    final isRtl = textDirection == TextDirection.rtl;
    final physicallyLeft = isRtl ? !before : before;
    if (physicallyLeft) {
      return (
        fromRect: Rect.fromLTWH(toRect.left, toRect.top, 0, toRect.height),
        alignment: Alignment.topRight,
      );
    }
    return (
      fromRect: Rect.fromLTWH(toRect.right, toRect.top, 0, toRect.height),
      alignment: Alignment.topLeft,
    );
  }

  if (before) {
    return (
      fromRect: Rect.fromLTWH(toRect.left, toRect.top, toRect.width, 0),
      alignment: Alignment.bottomLeft,
    );
  }
  return (
    fromRect: Rect.fromLTWH(toRect.left, toRect.bottom, toRect.width, 0),
    alignment: Alignment.topLeft,
  );
}

bool _overlapsRange(double aStart, double aEnd, double bStart, double bEnd) =>
    math.min(aEnd, bEnd) - math.max(aStart, bStart) > 1;

/// Computes the collapse target rectangle and trailing seam hairline for a
/// closed leaf [fromRect] as neighboring panes expand to claim its space.
({Rect toRect, Border seamBorder}) computeExitingPaneCollapse({
  required Rect fromRect,
  required Map<String, Rect> prevRects,
  required Map<String, Rect> nextRects,
  required Color hairlineColor,
}) {
  var expandRight = false;
  var expandLeft = false;
  var expandDown = false;
  var expandUp = false;
  double? meetX;
  double? meetY;

  for (final entry in nextRects.entries) {
    final prev = prevRects[entry.key];
    if (prev == null) {
      continue;
    }
    final next = entry.value;
    if (_overlapsRange(prev.top, prev.bottom, fromRect.top, fromRect.bottom)) {
      if (prev.right <= fromRect.left + 1 && next.right > fromRect.left + 1) {
        expandRight = true;
        meetX = meetX == null ? next.right : math.max(meetX, next.right);
      }
      if (prev.left >= fromRect.right - 1 && next.left < fromRect.right - 1) {
        expandLeft = true;
      }
    }
    if (_overlapsRange(prev.left, prev.right, fromRect.left, fromRect.right)) {
      if (prev.bottom <= fromRect.top + 1 && next.bottom > fromRect.top + 1) {
        expandDown = true;
        meetY = meetY == null ? next.bottom : math.max(meetY, next.bottom);
      }
      if (prev.top >= fromRect.bottom - 1 && next.top < fromRect.bottom - 1) {
        expandUp = true;
      }
    }
  }

  final side = BorderSide(color: hairlineColor, width: 1);

  if (expandRight && expandLeft) {
    final x = (meetX ?? fromRect.center.dx).clamp(fromRect.left, fromRect.right);
    return (
      toRect: Rect.fromLTWH(x, fromRect.top, 0, fromRect.height),
      seamBorder: Border(left: side, right: side),
    );
  }
  if (expandRight) {
    return (
      toRect: Rect.fromLTWH(fromRect.right, fromRect.top, 0, fromRect.height),
      seamBorder: Border(left: side),
    );
  }
  if (expandLeft) {
    return (
      toRect: Rect.fromLTWH(fromRect.left, fromRect.top, 0, fromRect.height),
      seamBorder: Border(right: side),
    );
  }

  if (expandDown && expandUp) {
    final y = (meetY ?? fromRect.center.dy).clamp(fromRect.top, fromRect.bottom);
    return (
      toRect: Rect.fromLTWH(fromRect.left, y, fromRect.width, 0),
      seamBorder: Border(top: side, bottom: side),
    );
  }
  if (expandDown) {
    return (
      toRect: Rect.fromLTWH(fromRect.left, fromRect.bottom, fromRect.width, 0),
      seamBorder: Border(top: side),
    );
  }
  if (expandUp) {
    return (
      toRect: Rect.fromLTWH(fromRect.left, fromRect.top, fromRect.width, 0),
      seamBorder: Border(bottom: side),
    );
  }

  return (
    toRect: Rect.fromLTWH(fromRect.center.dx, fromRect.top, 0, fromRect.height),
    seamBorder: const Border(),
  );
}

/// Clips and positions a pane's child at [layoutSize] while its outer box
/// animates from zero extent to target size, preventing inner overflow/reflow
/// during a split entrance. When [layoutSize] is null, acts as a pass-through.
class EditorPaneViewport extends SingleChildRenderObjectWidget {
  /// Creates an [EditorPaneViewport].
  const EditorPaneViewport({
    super.key,
    this.layoutSize,
    this.alignment = Alignment.topLeft,
    required super.child,
  });

  /// Fixed inner layout size while entering, or null when settled.
  final Size? layoutSize;

  /// Edge of the animating clip box to pin [child] against.
  final Alignment alignment;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderEditorPaneViewport(layoutSize, alignment);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderEditorPaneViewport renderObject,
  ) {
    renderObject
      ..layoutSize = layoutSize
      ..alignment = alignment;
  }
}

/// The render object behind [EditorPaneViewport].
class RenderEditorPaneViewport extends RenderProxyBox {
  /// Creates a [RenderEditorPaneViewport].
  RenderEditorPaneViewport(this._layoutSize, this._alignment);

  Size? _layoutSize;
  set layoutSize(Size? value) {
    if (_layoutSize == value) {
      return;
    }
    _layoutSize = value;
    markNeedsLayout();
  }

  Alignment _alignment;
  set alignment(Alignment value) {
    if (_alignment == value) {
      return;
    }
    _alignment = value;
    markNeedsLayout();
  }

  final LayerHandle<ClipRectLayer> _clip = LayerHandle<ClipRectLayer>();
  Offset _childOffset = Offset.zero;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      _childOffset = Offset.zero;
      return;
    }
    final target = _layoutSize;
    if (target == null) {
      child.layout(constraints, parentUsesSize: true);
      size = constraints.biggest;
      _childOffset = Offset.zero;
      return;
    }
    size = constraints.biggest;
    child.layout(BoxConstraints.tight(target), parentUsesSize: true);
    _childOffset = _alignment.inscribe(target, Offset.zero & size).topLeft;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }
    if (_layoutSize == null) {
      _clip.layer = null;
      context.paintChild(child, offset);
      return;
    }
    _clip.layer = context.pushClipRect(
      needsCompositing,
      offset,
      Offset.zero & size,
      (context, offset) => context.paintChild(child, offset + _childOffset),
      oldLayer: _clip.layer,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    if (_childOffset != Offset.zero) {
      transform.translateByDouble(_childOffset.dx, _childOffset.dy, 0, 1);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_layoutSize == null) {
      return super.hitTestChildren(result, position: position);
    }
    if (!(Offset.zero & size).contains(position)) {
      return false;
    }
    return result.addWithPaintOffset(
      offset: _childOffset,
      position: position,
      hitTest: (result, transformed) =>
          super.hitTestChildren(result, position: transformed),
    );
  }

  @override
  Rect? describeApproximatePaintClip(RenderObject child) =>
      _layoutSize != null ? Offset.zero & size : null;

  @override
  void dispose() {
    _clip.layer = null;
    super.dispose();
  }
}
