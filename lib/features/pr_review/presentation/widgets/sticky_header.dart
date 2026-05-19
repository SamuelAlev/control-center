import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Inherited widget that tells descendant [StickyHeader]s how much
/// vertical space at the top of the viewport is already occupied by a
/// pinned sliver (e.g. a tab strip). Sticky headers will pin themselves
/// below that inset instead of at viewport y = 0.
class StickyHeaderInset extends InheritedWidget {
  /// Creates a [StickyHeaderInset] with the given [top] inset in logical
  /// pixels.
  const StickyHeaderInset({super.key, required this.top, required super.child});

  /// Pixels of viewport-top space occupied by an ancestor pinned sliver.
  final double top;

  /// Returns the nearest enclosing [StickyHeaderInset.top], or 0 if none.
  static double of(BuildContext context) {
    final inset = context
        .dependOnInheritedWidgetOfExactType<StickyHeaderInset>();
    return inset?.top ?? 0.0;
  }

  @override
  bool updateShouldNotify(StickyHeaderInset oldWidget) => oldWidget.top != top;
}

/// A header that pins to the top of the nearest ancestor `Scrollable`'s
/// viewport while its content is in view, then yields when the content
/// scrolls past — mirroring `SliverPersistentHeader(pinned: true)` inside a
/// `SliverMainAxisGroup` but at the box level so it can live inside a
/// `SingleChildScrollView`.
class StickyHeader extends MultiChildRenderObjectWidget {
  /// Creates a [StickyHeader].
  StickyHeader({super.key, required Widget header, required Widget content})
    : super(children: [content, header]);

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderStickyHeader(
      scrollable: Scrollable.of(context),
      topInset: StickyHeaderInset.of(context),
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final r = renderObject as _RenderStickyHeader;
    r.scrollable = Scrollable.of(context);
    r.topInset = StickyHeaderInset.of(context);
  }
}

class _StickyParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderStickyHeader extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StickyParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StickyParentData> {
  _RenderStickyHeader({
    required ScrollableState scrollable,
    double topInset = 0.0,
  }) : _scrollable = scrollable,
       _topInset = topInset;

  ScrollableState _scrollable;
  ScrollableState get scrollable => _scrollable;
  set scrollable(ScrollableState value) {
    if (value == _scrollable) {
      return;
    }
    if (attached) {
      _scrollable.position.removeListener(_onScrollChanged);
    }
    _scrollable = value;
    if (attached) {
      _scrollable.position.addListener(_onScrollChanged);
    }
    _invalidateSelfTopCache();
  }

  double _lastPaintedOffsetY = -1;

  /// Cache of [_computeHeaderOffset]'s `localToGlobal` result, in viewport
  /// coordinates, plus the scroll offset at which it was captured. Lets us
  /// estimate the new selfTop by simply subtracting the scroll delta most
  /// of the time, instead of walking the render tree on every scroll
  /// tick. With dozens of [StickyHeader]s on a long PR, the tree-walk
  /// dominated the per-frame scroll cost.
  double _cachedSelfTopInViewport = double.nan;
  double _cachedScrollOffset = double.nan;

  /// Last-seen `maxScrollExtent` of the parent scrollable. When the extent
  /// grows it means content above us got taller (e.g. an earlier file
  /// finished its precompute and expanded from a loading placeholder to its
  /// full natural height) — that shifts our absolute position in the
  /// document but the cache's delta-from-scroll math doesn't notice,
  /// because our [performLayout] isn't called for a pure parent reposition.
  /// Tracking the extent gives us a separate "content shifted" signal.
  double _lastSeenMaxScrollExtent = double.nan;

  /// Soft cap on how far we can drift from the cached scroll offset
  /// before doing a full re-walk. Inside this window, the cached
  /// selfTop minus the scroll delta is correct unless an *ancestor*'s
  /// layout shifted us (e.g. an earlier file finishes precomputing and
  /// grows). The cap keeps that drift bounded: at most one viewport's
  /// worth before we recheck.
  static const double _selfTopCacheRefreshDistance = 800;

  void _invalidateSelfTopCache() {
    _cachedSelfTopInViewport = double.nan;
    _cachedScrollOffset = double.nan;
  }

  void _onScrollChanged() {
    // Detect content-extent changes (sibling files growing above us) and
    // invalidate the cache so the next [_computeHeaderOffset] re-walks the
    // render tree. Without this, the cached selfTopInViewport stays anchored
    // to the file's *old* document position even after siblings push us
    // down, and the header sticks at a stale Y — sometimes far below the
    // viewport top, sometimes refusing to pin at all.
    final maxExtent = _scrollable.position.maxScrollExtent;
    if (!_lastSeenMaxScrollExtent.isNaN &&
        (maxExtent - _lastSeenMaxScrollExtent).abs() > 0.5) {
      _invalidateSelfTopCache();
    }
    _lastSeenMaxScrollExtent = maxExtent;

    final newOffset = _computeHeaderOffset();
    if ((newOffset - _lastPaintedOffsetY).abs() > 0.5) {
      _lastPaintedOffsetY = -1;
      markNeedsPaint();
    }
  }

  double _topInset;
  double get topInset => _topInset;
  set topInset(double value) {
    if (value == _topInset) {
      return;
    }
    _topInset = value;
    markNeedsPaint();
  }

  /// Vertical translation applied to the header in the most recent paint.
  /// Used by [hitTestChildren] so taps land on the header where it is
  /// visually drawn, not where it sits in layout.
  double _headerOffsetY = 0;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _scrollable.position.addListener(_onScrollChanged);
  }

  @override
  void detach() {
    _scrollable.position.removeListener(_onScrollChanged);
    super.detach();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StickyParentData) {
      child.parentData = _StickyParentData();
    }
  }

  RenderBox get _contentBox => firstChild!;
  RenderBox get _headerBox => lastChild!;

  @override
  double computeMinIntrinsicWidth(double height) {
    return math.max(
      _headerBox.getMinIntrinsicWidth(height),
      _contentBox.getMinIntrinsicWidth(height),
    );
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return math.max(
      _headerBox.getMaxIntrinsicWidth(height),
      _contentBox.getMaxIntrinsicWidth(height),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    return _headerBox.getMinIntrinsicHeight(width) +
        _contentBox.getMinIntrinsicHeight(width);
  }

  @override
  double computeMaxIntrinsicHeight(double width) {
    return _headerBox.getMaxIntrinsicHeight(width) +
        _contentBox.getMaxIntrinsicHeight(width);
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final cs = constraints.loosen();
    final headerSize = _headerBox.getDryLayout(cs);
    final contentSize = _contentBox.getDryLayout(cs);
    return constraints.constrain(
      Size(
        math.max(headerSize.width, contentSize.width),
        headerSize.height + contentSize.height,
      ),
    );
  }

  @override
  void performLayout() {
    final cs = constraints.loosen();
    _headerBox.layout(cs, parentUsesSize: true);
    _contentBox.layout(cs, parentUsesSize: true);

    final width = constraints.constrainWidth(
      math.max(_headerBox.size.width, _contentBox.size.width),
    );
    final height = constraints.constrainHeight(
      _headerBox.size.height + _contentBox.size.height,
    );
    size = Size(width, height);

    (_headerBox.parentData! as _StickyParentData).offset = Offset.zero;
    (_contentBox.parentData! as _StickyParentData).offset = Offset(
      0,
      _headerBox.size.height,
    );

    // Layout may have moved us within the viewport (e.g. an earlier file
    // grew after its content finished precomputing) — the cached
    // selfTopInViewport is now stale.
    _invalidateSelfTopCache();
  }

  /// Computes how far down (in our local coordinate system) the header
  /// should be painted so it stays pinned to the viewport top while the
  /// group is in view, clamped so it can't escape the group's bounds.
  double _computeHeaderOffset() {
    final viewport = RenderAbstractViewport.maybeOf(this);
    if (viewport == null) {
      return 0;
    }

    final scrollPos = _scrollable.position.pixels;

    // Fast path: estimate selfTopInViewport by adjusting the cached value
    // for the scroll delta since we captured it. Skips the full
    // `localToGlobal` tree walk on every scroll tick — the bulk of the
    // per-frame cost when many [StickyHeader]s coexist on the page. We
    // refresh from scratch when the cache is unset, when we drift more
    // than [_selfTopCacheRefreshDistance], or when [performLayout] /
    // [scrollable] setter mark the cache invalid.
    double selfTopInViewport;
    if (_cachedSelfTopInViewport.isNaN ||
        (scrollPos - _cachedScrollOffset).abs() >
            _selfTopCacheRefreshDistance) {
      final viewportObj = viewport as RenderObject;
      selfTopInViewport = localToGlobal(Offset.zero, ancestor: viewportObj).dy;
      _cachedSelfTopInViewport = selfTopInViewport;
      _cachedScrollOffset = scrollPos;
    } else {
      selfTopInViewport =
          _cachedSelfTopInViewport - (scrollPos - _cachedScrollOffset);
    }

    final headerHeight = _headerBox.size.height;
    final selfHeight = size.height;
    final maxTranslation = math.max(0.0, selfHeight - headerHeight);
    return (_topInset - selfTopInViewport).clamp(0.0, maxTranslation);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final contentOffset =
        offset + (_contentBox.parentData! as _StickyParentData).offset;
    context.paintChild(_contentBox, contentOffset);

    // Paint is the source of truth — invalidate the cache so we walk the
    // tree fresh. Sibling files can grow asynchronously (precompute
    // finishing, loading-box → real height) without `applyContentDimensions`
    // calling `notifyListeners()` on the scroll position — that only fires
    // when pixels actually move. So our `_onScrollChanged` invalidation can
    // miss the growth, leaving a stale `_cachedSelfTopInViewport` anchored
    // to the file's old document Y. By the time paint runs (we're painted
    // because the parent's layout dirtied), layout has settled and the walk
    // is safe; the cache is only used between paints by the scroll listener
    // where delta-from-scroll math is correct by construction.
    _invalidateSelfTopCache();
    _headerOffsetY = _computeHeaderOffset();
    _lastPaintedOffsetY = _headerOffsetY;

    // When the header is pinned against the ancestor top inset, hide its
    // top 1px border by painting the widget 1px higher and clipping the
    // top 1px. This keeps the header content flush with the tab strip
    // without leaving a visible gap where the border was clipped.
    if (_headerOffsetY > 0) {
      context.pushClipRect(
        false,
        offset,
        Rect.fromLTWH(
          0,
          _headerOffsetY,
          _headerBox.size.width,
          _headerBox.size.height - 1,
        ),
        (PaintingContext ctx, Offset off) {
          ctx.paintChild(_headerBox, off + Offset(0, _headerOffsetY - 1));
        },
      );
    } else {
      context.paintChild(_headerBox, offset + Offset(0, _headerOffsetY));
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    // Header takes priority where it's visually drawn.
    final headerOffset = Offset(0, _headerOffsetY);
    final headerRect = headerOffset & _headerBox.size;
    if (headerRect.contains(position)) {
      final hit = result.addWithPaintOffset(
        offset: headerOffset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return _headerBox.hitTest(result, position: transformed);
        },
      );
      if (hit) {
        return true;
      }
    }

    // Otherwise fall through to content at its layout position.
    final contentParentData = _contentBox.parentData! as _StickyParentData;
    return result.addWithPaintOffset(
      offset: contentParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return _contentBox.hitTest(result, position: transformed);
      },
    );
  }
}
