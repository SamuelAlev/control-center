import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/editor/editor_layout_controller.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab_group.dart';
import 'package:flutter/widgets.dart';

/// A reusable VS Code-style editor grid: a tiling split-tree of tab groups with
/// drag-to-reorder, drag-to-split and drag-between-panes — the same surface the
/// messaging IDE and the PR detail page both render.
///
/// The engine is kind-agnostic: it renders [layout]'s tree and delegates every
/// tab body to [buildBody] and every feature-specific affordance (icons,
/// labels, the `[+]` menu, a sidebar toggle) to [chrome]. The host owns the
/// [layout] controller's lifecycle (create / dispose / persist) and any sidebar
/// composed around this widget.
class EditorWorkspace extends StatelessWidget {
  /// Creates an [EditorWorkspace].
  const EditorWorkspace({
    super.key,
    required this.layout,
    required this.buildBody,
    required this.chrome,
    this.onResized,
  });

  /// The split-tree controller (owned/disposed by the host).
  final EditorLayoutController layout;

  /// Builds a tab's kept-alive body.
  final EditorBodyBuilder buildBody;

  /// Feature-specific chrome (icons / labels / `[+]` menu / sidebar toggle).
  final EditorChrome chrome;

  /// Called after a divider drag changes region weights, so the host can
  /// persist the new sizes. The weight mutation itself is already applied.
  final VoidCallback? onResized;

  @override
  Widget build(BuildContext context) {
    // Rebuild whenever the tree changes (split / move / close / select). The
    // host may also listen to [layout] for its own bookkeeping — both are fine.
    return AnimatedBuilder(
      animation: layout,
      builder: (context, _) => _buildNode(layout.root),
    );
  }

  Widget _buildNode(EditorNode node) {
    if (node is EditorLeafNode) {
      return EditorTabGroup(
        key: ValueKey(node.id),
        leafId: node.id,
        controller: node.controller,
        layout: layout,
        buildBody: buildBody,
        canCloseGroup: layout.leafCount > 1,
        chrome: chrome,
      );
    }
    final split = node as EditorSplitNode;
    return LayoutBuilder(
      builder: (context, constraints) {
        final total = split.axis == Axis.horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final hasSpace = total.isFinite && total > 0;
        return CcResizable(
          // The id+child-count key re-seeds CcResizable's extents from the node
          // weights whenever the split's arity changes (a new sibling pane),
          // while preserving the user's dragged sizes across ordinary rebuilds.
          key: ValueKey('${split.id}:${split.children.length}'),
          axis: split.axis,
          onResize: (extents) => _onSplitResized(split, extents),
          regions: [
            for (var i = 0; i < split.children.length; i++)
              CcResizableRegion(
                initialExtent: hasSpace ? split.weights[i] * total : 240,
                minExtent: 120,
                builder: (context) => _buildNode(split.children[i]),
              ),
          ],
        );
      },
    );
  }

  void _onSplitResized(EditorSplitNode split, List<double> extents) {
    if (extents.length != split.weights.length) {
      return;
    }
    final sum = extents.fold<double>(0, (a, b) => a + b);
    if (sum <= 0) {
      return;
    }
    for (var i = 0; i < extents.length; i++) {
      split.weights[i] = extents[i] / sum;
    }
    onResized?.call();
  }
}
