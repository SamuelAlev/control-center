import 'dart:async';

import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// Configuration for a single region of a [CcResizable].
///
/// A region is a plain config object (not a widget): it carries its sizing
/// constraints and a [builder] for its content, and is laid out by the parent
/// [CcResizable] at the extent currently held by the [CcResizableController].
@immutable
class CcResizableRegion {
  /// Creates a [CcResizableRegion] from a [builder].
  const CcResizableRegion({
    required this.initialExtent,
    required this.builder,
    this.minExtent = 0,
    this.maxExtent,
  })  : assert(initialExtent >= 0, 'initialExtent must be non-negative'),
        assert(minExtent >= 0, 'minExtent must be non-negative'),
        assert(
          maxExtent == null || maxExtent >= minExtent,
          'maxExtent must be >= minExtent',
        );

  /// Creates a [CcResizableRegion] that renders a fixed [child].
  CcResizableRegion.child({
    required Widget child,
    required double initialExtent,
    double minExtent = 0,
    double? maxExtent,
  }) : this(
          initialExtent: initialExtent,
          minExtent: minExtent,
          maxExtent: maxExtent,
          builder: ((BuildContext _) => child),
        );

  /// The extent (width for [Axis.horizontal], height for [Axis.vertical]) the
  /// region starts at, before any drag.
  final double initialExtent;

  /// The smallest extent a drag may shrink this region to.
  final double minExtent;

  /// The largest extent a drag may grow this region to, or null for unbounded.
  final double? maxExtent;

  /// Builds the region's content.
  final Widget Function(BuildContext context) builder;
}

/// Holds and mutates the per-region extents of a [CcResizable].
///
/// Each region's extent is clamped to its `[minExtent, maxExtent]` and the
/// total of all extents is kept equal to the available space. Dragging a
/// divider transfers extent between the two regions it separates via
/// [resizeBy]; the controller notifies listeners so the [CcResizable] relays
/// out. Persistence of the resulting [extents] is the caller's responsibility.
class CcResizableController extends ChangeNotifier {
  /// Creates a [CcResizableController] for the given [regions].
  CcResizableController(List<CcResizableRegion> regions)
      : _mins = [for (final r in regions) r.minExtent],
        _maxs = [for (final r in regions) r.maxExtent],
        _extents = [for (final r in regions) r.initialExtent];

  final List<double> _mins;
  final List<double?> _maxs;
  List<double> _extents;
  double? _available;

  /// The current extent of every region, in order.
  List<double> get extents => List<double>.unmodifiable(_extents);

  /// The number of regions.
  int get length => _extents.length;

  /// The total available extent along the resize axis, or null until the first
  /// layout pass has reported it.
  double? get available => _available;

  double _clampExtent(int index, double value) {
    final min = _mins[index];
    final max = _maxs[index];
    var clamped = value < min ? min : value;
    if (max != null && clamped > max) {
      clamped = max;
    }
    return clamped;
  }

  /// Records the [available] extent reported by layout and rescales the
  /// extents to fill it. Returns true when the extents changed.
  bool setAvailable(double available) {
    if (_available == available) {
      return false;
    }
    _available = available;
    return _normalize(notify: true);
  }

  /// Drags the divider after region [index] by [delta] logical pixels (positive
  /// grows region [index] and shrinks region `index + 1`). The applied delta is
  /// clamped so neither region violates its bounds; the pair's combined extent
  /// is preserved. Returns true when extents changed.
  bool resizeBy(int index, double delta) {
    if (index < 0 || index + 1 >= _extents.length || delta == 0) {
      return false;
    }
    final before = _extents[index];
    final after = _extents[index + 1];

    final newBefore = _clampExtent(index, before + delta);
    final appliedByBefore = newBefore - before;

    final newAfter = _clampExtent(index + 1, after - appliedByBefore);
    final appliedByAfter = after - newAfter;

    // The transferable amount is the smaller of what each region can absorb so
    // the pair's combined extent is preserved exactly.
    final applied =
        appliedByBefore.abs() < appliedByAfter.abs() ? appliedByBefore : appliedByAfter;
    if (applied == 0) {
      return false;
    }

    _extents[index] = before + applied;
    _extents[index + 1] = after - applied;
    notifyListeners();
    return true;
  }

  /// Replaces the extents wholesale (e.g. restoring persisted sizes), clamping
  /// each and re-fitting to the available space.
  void setExtents(List<double> extents) {
    assert(
      extents.length == _extents.length,
      'extents length must match region count',
    );
    _extents = [
      for (var i = 0; i < extents.length; i++) _clampExtent(i, extents[i]),
    ];
    _normalize(notify: true);
  }

  // Fits the extents to [_available] without breaking per-region bounds. The
  // last region absorbs the leftover so the row/column exactly fills the space.
  bool _normalize({required bool notify}) {
    final available = _available;
    if (available == null || _extents.isEmpty) {
      return false;
    }
    final next = [
      for (var i = 0; i < _extents.length; i++) _clampExtent(i, _extents[i]),
    ];
    final fixedSum = next.fold<double>(0, (sum, e) => sum + e);
    final slack = available - fixedSum;
    if (slack != 0) {
      // Push the slack onto the last region (clamped), then ripple any
      // residual backwards so we never exceed bounds silently.
      var residual = slack;
      for (var i = next.length - 1; i >= 0 && residual != 0; i--) {
        final target = next[i] + residual;
        final clamped = _clampExtent(i, target);
        residual = target - clamped;
        next[i] = clamped;
      }
    }
    final changed = !_listEquals(next, _extents);
    _extents = next;
    if (changed && notify) {
      notifyListeners();
    }
    return changed;
  }

  static bool _listEquals(List<double> a, List<double> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}

/// A row or column of [regions] separated by draggable dividers.
///
/// Each region is laid out at the extent held by [controller] (an internal one
/// is created from the regions when none is supplied). Dragging a divider
/// transfers extent between its two adjacent regions, clamped to each region's
/// `[minExtent, maxExtent]`, and reports the new extents via [onResize].
///
/// The visible divider is a [dividerThickness] hairline in
/// [DesignSystemTokens.lineStrong]; it sits inside a wider invisible hit area
/// that shows a resize cursor, matching DESIGN.md's flat, hairline chrome.
class CcResizable extends StatefulWidget {
  /// Creates a [CcResizable].
  const CcResizable({
    super.key,
    required this.axis,
    required this.regions,
    this.controller,
    this.dividerThickness = 1,
    this.dividerHitSize = 8,
    this.dividerColor,
    this.onResize,
  })  : assert(regions.length > 0, 'regions must not be empty'),
        assert(dividerThickness >= 0, 'dividerThickness must be non-negative'),
        assert(
          dividerHitSize >= dividerThickness,
          'dividerHitSize must be >= dividerThickness',
        );

  /// Whether regions are laid out left-to-right ([Axis.horizontal]) or
  /// top-to-bottom ([Axis.vertical]).
  final Axis axis;

  /// The regions, in display order.
  final List<CcResizableRegion> regions;

  /// Drives the region extents. When null, an internal controller is created
  /// from [regions]' initial/min/max extents.
  final CcResizableController? controller;

  /// Thickness of the visible divider line.
  final double dividerThickness;

  /// Size of the invisible pointer hit area centered on each divider.
  final double dividerHitSize;

  /// Color of the visible divider; defaults to [DesignSystemTokens.lineStrong].
  final Color? dividerColor;

  /// Called with the full extent list whenever a drag changes it.
  final ValueChanged<List<double>>? onResize;

  @override
  State<CcResizable> createState() => _CcResizableState();
}

class _CcResizableState extends State<CcResizable> {
  CcResizableController? _internalController;

  CcResizableController get _controller =>
      widget.controller ??
      (_internalController ??= CcResizableController(widget.regions));

  @override
  void didUpdateWidget(CcResizable oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the regions changed under an internal controller, rebuild it.
    if (widget.controller == null &&
        widget.regions.length != _controller.length) {
      _internalController?.dispose();
      _internalController = CcResizableController(widget.regions);
    }
  }

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  void _onDrag(int dividerIndex, double delta) {
    final changed = _controller.resizeBy(dividerIndex, delta);
    if (changed) {
      widget.onResize?.call(_controller.extents);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isHorizontal = widget.axis == Axis.horizontal;
    final controller = _controller;

    return LayoutBuilder(
      builder: (context, constraints) {
        final total =
            isHorizontal ? constraints.maxWidth : constraints.maxHeight;
        if (total.isFinite) {
          // The divider handles float on top of the seams (below) rather than
          // consuming main-axis space, so the regions share the whole extent.
          // Apply during layout; ChangeNotifier rebuilds via ListenableBuilder.
          controller.setAvailable(total < 0 ? 0 : total);
        }

        return ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final extents = controller.extents;
            final children = <Widget>[];

            // Regions are positioned flush, edge-to-edge: one pane's trailing
            // edge meets the next pane's leading edge with no gap, so neither
            // pane's background shows through between them.
            var offset = 0.0;
            for (var i = 0; i < widget.regions.length; i++) {
              final extent = extents[i];
              children.add(
                Positioned(
                  left: isHorizontal ? offset : 0,
                  right: isHorizontal ? null : 0,
                  top: isHorizontal ? 0 : offset,
                  bottom: isHorizontal ? 0 : null,
                  width: isHorizontal ? extent : null,
                  height: isHorizontal ? null : extent,
                  child: Builder(builder: widget.regions[i].builder),
                ),
              );
              offset += extent;
            }

            // Divider handles overlay each seam, centered on the boundary, so
            // dragging sits on top of the panes rather than between them — it
            // never pushes content. The visible hairline lands on the seam.
            offset = 0;
            for (var i = 0; i < widget.regions.length - 1; i++) {
              offset += extents[i];
              final start = offset - widget.dividerHitSize / 2;
              children.add(
                Positioned(
                  left: isHorizontal ? start : 0,
                  right: isHorizontal ? null : 0,
                  top: isHorizontal ? 0 : start,
                  bottom: isHorizontal ? 0 : null,
                  width: isHorizontal ? widget.dividerHitSize : null,
                  height: isHorizontal ? null : widget.dividerHitSize,
                  child: _CcResizableDivider(
                    axis: widget.axis,
                    thickness: widget.dividerThickness,
                    hitSize: widget.dividerHitSize,
                    color: widget.dividerColor ?? t.lineStrong,
                    activeColor: t.fgBrandPrimary,
                    onDrag: (delta) => _onDrag(i, delta),
                  ),
                ),
              );
            }

            // All children are positioned, so the Stack adopts the incoming
            // (bounded) constraints — CcResizable is always laid out as a pane
            // splitter inside a sized parent.
            return Stack(clipBehavior: Clip.none, children: children);
          },
        );
      },
    );
  }
}

/// The draggable separator between two regions: a hairline centered in a wider
/// invisible hit area that shows the axis-appropriate resize cursor.
///
/// On a sustained hover (after a short intent delay so a casual cursor pass does
/// not trigger it) and while being dragged, the hairline animates thicker and
/// takes [activeColor] to signal it is grabbable. The animation collapses to an
/// instant change when motion is reduced (see [CcMotion.resolve]).
class _CcResizableDivider extends StatefulWidget {
  const _CcResizableDivider({
    required this.axis,
    required this.thickness,
    required this.hitSize,
    required this.color,
    required this.activeColor,
    required this.onDrag,
  });

  final Axis axis;
  final double thickness;
  final double hitSize;

  /// The resting hairline color.
  final Color color;

  /// The hairline color while hovered or dragged.
  final Color activeColor;

  final ValueChanged<double> onDrag;

  @override
  State<_CcResizableDivider> createState() => _CcResizableDividerState();
}

class _CcResizableDividerState extends State<_CcResizableDivider> {
  /// How long the pointer must rest on the divider before it highlights, so a
  /// cursor merely crossing the seam does not make it flash bold.
  static const Duration _hoverIntent = Duration(milliseconds: 250);

  bool _hovered = false;
  bool _dragging = false;
  Timer? _hoverTimer;

  bool get _active => _hovered || _dragging;

  void _onEnter() {
    _hoverTimer?.cancel();
    _hoverTimer = Timer(_hoverIntent, () {
      if (mounted) {
        setState(() => _hovered = true);
      }
    });
  }

  void _onExit() {
    _hoverTimer?.cancel();
    if (_hovered) {
      setState(() => _hovered = false);
    }
  }

  void _setDragging(bool dragging) {
    if (_dragging != dragging) {
      setState(() => _dragging = dragging);
    }
  }

  @override
  void dispose() {
    _hoverTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHorizontal = widget.axis == Axis.horizontal;
    final cursor = isHorizontal
        ? SystemMouseCursors.resizeColumn
        : SystemMouseCursors.resizeRow;

    // Grow the hairline by 2px when active, clamped so it never exceeds the hit
    // area. The visible line is [thickness] on the main axis and fills the cross
    // axis — the cross-axis dimension must be infinity (not null): wrapped in
    // [Center] it receives loose constraints, so a null extent would let the
    // childless box collapse to zero and the line would never paint.
    final activeThickness = (widget.thickness + 2)
        .clamp(widget.thickness, widget.hitSize)
        .toDouble();
    final lineThickness = _active ? activeThickness : widget.thickness;
    final lineColor = _active ? widget.activeColor : widget.color;

    final line = AnimatedContainer(
      duration: CcMotion.resolve(context, CcMotion.fast),
      curve: CcMotion.standard,
      width: isHorizontal ? lineThickness : double.infinity,
      height: isHorizontal ? double.infinity : lineThickness,
      color: lineColor,
    );

    return MouseRegion(
      cursor: cursor,
      onEnter: (_) => _onEnter(),
      onExit: (_) => _onExit(),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) => _setDragging(true),
        onPointerUp: (_) => _setDragging(false),
        onPointerCancel: (_) => _setDragging(false),
        onPointerMove: (event) {
          final delta = isHorizontal ? event.delta.dx : event.delta.dy;
          if (delta != 0) {
            widget.onDrag(delta);
          }
        },
        child: SizedBox(
          width: isHorizontal ? widget.hitSize : null,
          height: isHorizontal ? null : widget.hitSize,
          child: Center(child: line),
        ),
      ),
    );
  }
}
