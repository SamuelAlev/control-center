// Uses Material's SelectionArea for platform-adaptive selection handles and
// toolbar. Selection is the deliberate Material island of this package
// (together with context_menu.dart); parser/AST/render stay widgets-only.
import 'package:cc_markdown/src/selection/context_menu.dart';
import 'package:cc_markdown/src/selection/copy_filter.dart';
import 'package:flutter/material.dart';

/// A selection region for markdown content: `SelectionArea` + the
/// overlay-line copy filter + the adaptive context menu.
///
/// Per-widget selection wraps ONE of these around a rendered document. Feeds
/// that render many messages should instead place one region around the whole
/// feed and mark the subtree with `CcSelectionScope` so each message renders
/// non-selectable text under the shared region.
class CcSelectionRegion extends StatelessWidget {
  /// Creates a [CcSelectionRegion] around [child].
  const CcSelectionRegion({
    required this.child,
    this.contextMenuBuilder,
    super.key,
  });

  /// The selectable subtree.
  final Widget child;

  /// Custom context menu; defaults to [ccDefaultSelectionContextMenu].
  final Widget Function(BuildContext, SelectableRegionState)?
  contextMenuBuilder;

  @override
  Widget build(BuildContext context) {
    return CcSelectionCopyFilter(
      child: SelectionArea(
        contextMenuBuilder: contextMenuBuilder ?? ccDefaultSelectionContextMenu,
        child: child,
      ),
    );
  }
}
