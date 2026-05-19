import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:flutter/widgets.dart' show Axis, immutable;

/// Where a tab is being dropped onto a pane, driving the resulting action.
///
/// The four edges split the target pane along the matching axis (left/right →
/// a horizontal split, top/bottom → a vertical split) with the dragged tab in
/// the newly-created sibling. [center] moves the tab *into* the target pane
/// without splitting.
enum DropEdge {
  /// Split horizontally; new pane on the left.
  left,

  /// Split horizontally; new pane on the right.
  right,

  /// Split vertically; new pane on top.
  top,

  /// Split vertically; new pane on the bottom.
  bottom,

  /// Move the tab into the target pane without splitting.
  center,
}

/// Payload carried by a dragged editor tab.
///
/// Identifies the source leaf + the tab's index there, and carries the live
/// [EditorTab] instance so the layout can move (not copy) it — preserving the
/// tab's body identity for keep-alive. See [EditorTab] identity note.
@immutable
class TabDragData {
  /// Creates a [TabDragData].
  const TabDragData({
    required this.sourceLeafId,
    required this.tabIndex,
    required this.tab,
    this.width,
  });

  /// Id of the leaf the tab is being dragged from.
  final String sourceLeafId;

  /// The tab's index within its source leaf at drag start.
  final int tabIndex;

  /// The dragged tab instance.
  final EditorTab tab;

  /// Rendered width of the tab's cell at drag start, when known. Lets the
  /// hovered tab bar open a drop gap of exactly this size (the strip's
  /// slide-aside animation); null falls back to a default gap width.
  final double? width;
}

/// A node in the editor split tree.
///
/// The tree is either a single [EditorLeafNode] (one tab group filling the
/// area) or an [EditorSplitNode] dividing the area, recursively, into child
/// nodes along one axis. This mirrors a tiling window manager / VS Code's
/// editor grid: arbitrary nesting of horizontal and vertical splits.
sealed class EditorNode {
  /// Stable id within the tree (leaf id or split id).
  String get id;
}

/// A leaf of the split tree: exactly one tab group.
final class EditorLeafNode extends EditorNode {
  /// Creates an [EditorLeafNode].
  EditorLeafNode({required this.id, required this.controller});

  @override
  final String id;

  /// Owns this leaf's tabs + selection.
  final EditorTabGroupController controller;
}

/// An internal split: [children] laid out along [axis] at the given [weights].
///
/// [weights] is parallel to [children], non-negative, and normalised to sum to
/// 1 (the controller keeps it so). A horizontal split places children
/// left-to-right; a vertical split top-to-bottom. Splits are n-ary: a third
/// sibling can be added along the same axis rather than forcing nesting.
final class EditorSplitNode extends EditorNode {
  /// Creates an [EditorSplitNode].
  EditorSplitNode({
    required this.id,
    required this.axis,
    required this.children,
    required this.weights,
  }) : assert(children.isNotEmpty, 'a split needs at least one child'),
       assert(
         children.length == weights.length,
         'weights must be parallel to children',
       );

  @override
  final String id;

  /// Layout axis for [children].
  final Axis axis;

  /// Child nodes in display order (mutable; edited by the layout controller).
  final List<EditorNode> children;

  /// Relative sizes parallel to [children], normalised to sum to 1.
  final List<double> weights;
}
