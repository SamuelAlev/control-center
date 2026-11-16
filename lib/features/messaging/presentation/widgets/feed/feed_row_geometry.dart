import 'package:control_center/features/messaging/presentation/widgets/feed/anchor_follow_physics.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// One laid-out feed row as the list sliver placed it.
///
/// `leadingEdge` and `trailingEdge` are scroll offsets inside the list sliver:
/// for the reverse feed the leading edge is the row's bottom and the trailing
/// edge its top.
typedef FeedRowPlacement = ({
  int index,
  double leadingEdge,
  double trailingEdge,
});

/// Reads row geometry straight off the feed's list sliver.
///
/// The scroll anchor is a row identity plus where that row sits, so holding the
/// reader's place means asking the list where the row is now. That question is
/// answered here from the sliver's own bookkeeping: each child's
/// `layoutOffset` and the extent the list recorded for its index. Neither read
/// touches `RenderBox.size`, so it is legal in the middle of the viewport's
/// layout, which is exactly where the scroll physics needs it.
class FeedRowGeometry {
  /// Creates a geometry reader over the list driven by [controller].
  FeedRowGeometry(this.controller);

  /// The list's extent bookkeeping (measured extents by index).
  final ListController controller;

  RenderSliverMultiBoxAdaptor? _sliver;

  /// Locates the list sliver under the scrollable at [scrollableContext].
  ///
  /// Cheap after the first call: a sliver that is still attached is reused.
  void attach(BuildContext? scrollableContext) {
    final current = _sliver;
    if (current != null && current.attached) {
      return;
    }
    _sliver = null;
    final root = scrollableContext?.findRenderObject();
    if (root != null) {
      _sliver = _findSliver(root);
    }
  }

  /// Forgets the sliver (the list was torn down).
  void detach() => _sliver = null;

  /// Whether a live sliver is attached.
  bool get isAttached => _sliver?.attached ?? false;

  static RenderSliverMultiBoxAdaptor? _findSliver(RenderObject root) {
    if (root is RenderSliverMultiBoxAdaptor) {
      return root;
    }
    RenderSliverMultiBoxAdaptor? found;
    root.visitChildren((child) {
      found ??= _findSliver(child);
    });
    return found;
  }

  /// Width the list lays its rows out at, or null before the first layout.
  double? get crossAxisExtent {
    final sliver = _sliver;
    if (sliver == null || !sliver.attached) {
      return null;
    }
    return sliver.constraints.crossAxisExtent;
  }

  /// Scroll extent laid out before the list sliver (the feed's padding).
  double get precedingScrollExtent {
    final sliver = _sliver;
    if (sliver == null || !sliver.attached) {
      return 0;
    }
    return sliver.constraints.precedingScrollExtent;
  }

  /// Where the row at [index] is laid out, or null when it is not a laid-out
  /// child right now.
  FeedRowPlacement? placementOf(int index) {
    final sliver = _sliver;
    if (sliver == null || !sliver.attached || !controller.isAttached) {
      return null;
    }
    var child = sliver.firstChild;
    while (child != null) {
      final data = child.parentData! as SliverMultiBoxAdaptorParentData;
      if (data.index == index) {
        return _placement(data);
      }
      child = sliver.childAfter(child);
    }
    return null;
  }

  /// Every laid-out row, in index order.
  List<FeedRowPlacement> placements() {
    final sliver = _sliver;
    if (sliver == null || !sliver.attached || !controller.isAttached) {
      return const [];
    }
    final out = <FeedRowPlacement>[];
    var child = sliver.firstChild;
    while (child != null) {
      final data = child.parentData! as SliverMultiBoxAdaptorParentData;
      final placement = _placement(data);
      if (placement != null) {
        out.add(placement);
      }
      child = sliver.childAfter(child);
    }
    return out;
  }

  /// The reader's place right now: the row under the viewport's top edge.
  ///
  /// The top edge is where a reader's eyes are anchored in a document, and it
  /// is the edge that should stay put when something below it opens or grows.
  /// [keyOf] maps a list index to its row key; a row without one cannot anchor.
  /// Returns null while nothing is laid out.
  FeedScrollAnchor? anchorAtTop(
    ScrollPosition position,
    String? Function(int index) keyOf,
  ) {
    if (!position.hasPixels || !position.hasViewportDimension) {
      return null;
    }
    final rows = placements();
    if (rows.isEmpty) {
      return null;
    }
    final top =
        position.pixels + position.viewportDimension - precedingScrollExtent;
    FeedRowPlacement? hit;
    for (final row in rows) {
      if (row.leadingEdge <= top && top < row.trailingEdge) {
        hit = row;
        break;
      }
    }
    // The viewport's top edge is past the last laid-out row (a short feed):
    // the farthest row is the one on top.
    hit ??= rows.reduce((a, b) => a.trailingEdge >= b.trailingEdge ? a : b);
    final key = keyOf(hit.index);
    if (key == null) {
      return null;
    }
    return (
      rowKey: key,
      trailingEdge: hit.trailingEdge,
      pixels: position.pixels,
    );
  }

  FeedRowPlacement? _placement(SliverMultiBoxAdaptorParentData data) {
    final index = data.index;
    final offset = data.layoutOffset;
    if (index == null ||
        offset == null ||
        index < 0 ||
        index >= controller.numberOfItems) {
      return null;
    }
    final (extent, _) = controller.extentForIndex(index);
    return (index: index, leadingEdge: offset, trailingEdge: offset + extent);
  }
}
