import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// The geometry used to choose the nearest item in a [CcFluidHover] group.
enum CcFluidHoverAxis {
  /// Vertical lists such as menus and sidebars.
  y,

  /// Horizontal strips such as tabs and segmented controls.
  x,

  /// Two-dimensional groups such as compact grids of links.
  xy,
}

/// Lays out the item widgets registered by [CcFluidHover].
typedef CcFluidHoverLayoutBuilder =
    Widget Function(BuildContext context, List<Widget> items);

/// Whether item [index] must be skipped by fluid hover selection.
typedef CcFluidHoverDisabledPredicate = bool Function(int index);

/// Whether item [index] is a hard boundary between independent hover groups.
typedef CcFluidHoverBoundaryPredicate = bool Function(int index);

/// Opt-in contract for heterogeneous containers such as [CcSidebar].
///
/// Homogeneous controls already know which entries are enabled. Containers
/// accepting arbitrary widgets use this marker to avoid treating headers,
/// dividers, and static content as hover targets. A wrapper around an
/// interactive row (a popover target, a composite accordion) must implement
/// this too, or the enclosing group treats it as a nested surface rather than
/// a row — see [CcSidebarGroup].
abstract interface class CcFluidHoverTarget {
  /// Whether this widget currently participates in nearest-target hover.
  bool get fluidHoverEnabled;
}

/// A nearest-target hover group for compact, stable collections.
///
/// One highlight follows the pointer to the nearest enabled item, including
/// while the pointer crosses inter-item gaps or the collection's padding. A
/// row containing the pointer always wins; otherwise distance is measured to
/// each item's center along [axis]. Pointer moves are coalesced to one geometry
/// pass per animation frame.
///
/// Use this only when every enabled item is a safe target, items sit close
/// together, and their relative positions stay stable while the pointer is in
/// the group. Do not use it for mixed interactive/static cards, destructive
/// gap-click behavior, sparse layouts, or independently reordering rows.
///
/// The highlight is one non-interactive overlay shared by every item. It moves
/// with a transform and only interpolates width/height when target extents
/// differ. Reduced motion keeps nearest-item selection but snaps the visual
/// between targets.
///
/// A still pointer over a scrolling list is the same gesture as a moving
/// pointer over a still list. Ancestor and descendant scrollables both
/// retarget after the scroll layout commits. Travel animates only when the
/// active item changes; the same item's rect tracks without lag.
class CcFluidHover extends StatefulWidget {
  /// Creates a fluid hover group.
  const CcFluidHover({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.layoutBuilder,
    this.axis = CcFluidHoverAxis.y,
    this.isItemDisabled,
    this.isItemBoundary,
    this.onActiveIndexChanged,
    this.highlightColor,
    this.borderRadius = AppRadii.brSm,
    this.clipBehavior = Clip.none,
    this.mouseCursor,
  });

  /// Number of stable items in this group.
  final int itemCount;

  /// Builds item [index]. Indices must remain stable while visible.
  final IndexedWidgetBuilder itemBuilder;

  /// Lays out the registered item widgets.
  ///
  /// The builder may insert gaps or padding around [items], but must include
  /// every item exactly once and must not reorder them.
  final CcFluidHoverLayoutBuilder layoutBuilder;

  /// Axis used for nearest-center distance.
  final CcFluidHoverAxis axis;

  /// Disabled items are never highlighted or considered as nearest targets.
  final CcFluidHoverDisabledPredicate? isItemDisabled;

  /// Boundary items are not targets and stop the highlight while underneath
  /// the pointer. Use them for section headers, dividers, or nested groups.
  final CcFluidHoverBoundaryPredicate? isItemBoundary;

  /// Reports pointer-driven active-index changes. `null` means the pointer left
  /// the group or no enabled item could be measured.
  final ValueChanged<int?>? onActiveIndexChanged;

  /// Highlight fill. Defaults to the design system hover wash.
  final Color? highlightColor;

  /// Highlight shape.
  final BorderRadius borderRadius;

  /// Stack clipping. Defaults to none so sidebar badges may overflow rows.
  final Clip clipBehavior;

  /// Cursor for the whole collection, including inter-item gaps and padding.
  ///
  /// Item [CcTappable]s still win while the pointer is over a row. Set this
  /// on dense nav lists so a gutter never drops the cursor back to the
  /// default arrow. Null defers to the ancestor (menus, tabs).
  final MouseCursor? mouseCursor;

  /// Whether [context] is inside one of this group's registered items.
  static bool hasItemScope(BuildContext context) =>
      _CcFluidHoverItemScope.maybeOf(context) != null;

  /// Whether the pointer is currently inside the surrounding hover group.
  static bool isPointerInside(BuildContext context) =>
      _CcFluidHoverItemScope.maybeOf(context)?.pointerInside ?? false;

  /// Whether the item containing [context] is the pointer's nearest target.
  static bool isItemActive(BuildContext context) =>
      _CcFluidHoverItemScope.maybeOf(context)?.active ?? false;

  /// Whether the nearest [CcTappable] descendant should use this group's
  /// pointer state. Nested controls inside that tappable remain independent.
  static bool controlsTappable(BuildContext context) =>
      hasItemScope(context) &&
      _CcFluidHoverConsumedScope.maybeOf(context) == null;

  /// Marks the nearest tappable as the item-level interaction owner.
  static Widget consumeTappable(Widget child) =>
      _CcFluidHoverConsumedScope(child: child);
  @override
  State<CcFluidHover> createState() => _CcFluidHoverState();
}

class _CcFluidHoverState extends State<CcFluidHover> {
  final GlobalKey _containerKey = GlobalKey();
  List<GlobalKey> _itemKeys = const [];
  final List<ScrollPosition> _ancestorScrolls = [];

  int? _activeIndex;
  Rect? _displayRect;
  Offset? _pendingPosition;
  Offset? _lastPosition;
  Offset? _globalPosition;
  int? _frameCallbackId;
  int _pointerSession = 0;
  bool _pointerInside = false;
  bool _postFramePickScheduled = false;
  bool _geometryOnlyUpdate = false;

  @override
  void initState() {
    super.initState();
    _syncKeys();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bindAncestorScrolls();
  }

  @override
  void didUpdateWidget(covariant CcFluidHover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemCount != widget.itemCount) {
      _syncKeys();
      if ((_activeIndex ?? -1) >= widget.itemCount) {
        _setActive(null, null);
      }
    }
  }

  @override
  void dispose() {
    _unbindAncestorScrolls();
    final callbackId = _frameCallbackId;
    if (callbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(callbackId);
    }
    super.dispose();
  }

  void _unbindAncestorScrolls() {
    for (final position in _ancestorScrolls) {
      position.removeListener(_onScroll);
    }
    _ancestorScrolls.clear();
  }

  void _bindAncestorScrolls() {
    final next = <ScrollPosition>[];
    var search = context;
    while (true) {
      final scrollable = Scrollable.maybeOf(search);
      if (scrollable == null) {
        break;
      }
      if (next.any((position) => identical(position, scrollable.position))) {
        break;
      }
      next.add(scrollable.position);
      search = scrollable.context;
    }
    if (_sameScrolls(next)) {
      return;
    }
    _unbindAncestorScrolls();
    for (final position in next) {
      position.addListener(_onScroll);
      _ancestorScrolls.add(position);
    }
  }

  bool _sameScrolls(List<ScrollPosition> next) {
    if (next.length != _ancestorScrolls.length) {
      return false;
    }
    for (var i = 0; i < next.length; i++) {
      if (!identical(next[i], _ancestorScrolls[i])) {
        return false;
      }
    }
    return true;
  }

  void _syncKeys() {
    _itemKeys = List<GlobalKey>.generate(
      widget.itemCount,
      (index) => index < _itemKeys.length ? _itemKeys[index] : GlobalKey(),
      growable: false,
    );
  }

  void _onEnter(PointerEnterEvent event) {
    _pointerInside = true;
    _pointerSession++;
    _rememberPointer(event.position, event.localPosition);
    _queuePick(event.localPosition);
  }

  void _onHover(PointerHoverEvent event) {
    _rememberPointer(event.position, event.localPosition);
    _queuePick(event.localPosition);
  }

  void _onExit(PointerExitEvent event) {
    _pointerInside = false;
    _pendingPosition = null;
    _lastPosition = null;
    _globalPosition = null;
    final callbackId = _frameCallbackId;
    if (callbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(callbackId);
      _frameCallbackId = null;
    }
    _setActive(null, null);
  }

  void _rememberPointer(Offset global, Offset local) {
    _globalPosition = global;
    _lastPosition = local;
  }

  void _onScroll() => _queuePickAfterLayout();

  void _queuePick(Offset position) {
    _pendingPosition = position;
    if (_frameCallbackId != null) {
      return;
    }
    _frameCallbackId = SchedulerBinding.instance.scheduleFrameCallback((_) {
      _frameCallbackId = null;
      final pending = _pendingPosition;
      _pendingPosition = null;
      if (!mounted || !_pointerInside || pending == null) {
        return;
      }
      _pick(pending);
    });
  }

  void _queuePickAfterLayout() {
    if (!_pointerInside || _postFramePickScheduled) {
      return;
    }
    _postFramePickScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _postFramePickScheduled = false;
      if (!mounted || !_pointerInside) {
        return;
      }
      final local = _localFromGlobal() ?? _lastPosition;
      if (local == null) {
        return;
      }
      _lastPosition = local;
      _pick(local);
    });
  }

  Offset? _localFromGlobal() {
    final global = _globalPosition;
    final box = _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (global == null || box == null || !box.hasSize || !box.attached) {
      return null;
    }
    return box.globalToLocal(global);
  }

  void _pick(Offset position) {
    final resolved = _localFromGlobal() ?? position;
    final containerBox =
        _containerKey.currentContext?.findRenderObject() as RenderBox?;
    if (containerBox == null || !containerBox.hasSize) {
      _setActive(null, null);
      return;
    }
    if (!(Offset.zero & containerBox.size).contains(resolved)) {
      _setActive(null, null);
      return;
    }

    int? containing;
    int? nearest;
    Rect? containingRect;
    Rect? nearestRect;
    var closestDistance = double.infinity;

    for (var index = 0; index < widget.itemCount; index++) {
      final itemBox =
          _itemKeys[index].currentContext?.findRenderObject() as RenderBox?;
      if (itemBox == null || !itemBox.hasSize || !itemBox.attached) {
        continue;
      }
      final origin = itemBox.localToGlobal(Offset.zero, ancestor: containerBox);
      final rect = origin & itemBox.size;
      if (widget.isItemBoundary?.call(index) ?? false) {
        if (rect.contains(resolved)) {
          _setActive(null, null);
          return;
        }
        continue;
      }
      if (widget.isItemDisabled?.call(index) ?? false) {
        continue;
      }
      if (rect.contains(resolved)) {
        containing = index;
        containingRect = rect;
        break;
      }
      final distance = switch (widget.axis) {
        CcFluidHoverAxis.y => (resolved.dy - rect.center.dy).abs(),
        CcFluidHoverAxis.x => (resolved.dx - rect.center.dx).abs(),
        CcFluidHoverAxis.xy =>
          (resolved.dx - rect.center.dx) * (resolved.dx - rect.center.dx) +
              (resolved.dy - rect.center.dy) * (resolved.dy - rect.center.dy),
      };
      if (distance < closestDistance) {
        closestDistance = distance;
        nearest = index;
        nearestRect = rect;
      }
    }

    _setActive(containing ?? nearest, containingRect ?? nearestRect);
  }

  Widget _wrapItem(int index, Widget child) {
    final keyed = KeyedSubtree(key: _itemKeys[index], child: child);
    // Boundary and disabled items are still measured (so a nested group can
    // stop the highlight, and keys stay stable) but they must NOT publish an
    // item scope. [CcTappable] inside a scope drops its own hover in favour
    // of this group's overlay; wrapping a composite that is never the active
    // target (an accordion, a popover wrapper) would leave that row clickable
    // with no wash.
    final boundary = widget.isItemBoundary?.call(index) ?? false;
    final disabled = widget.isItemDisabled?.call(index) ?? false;
    if (boundary || disabled) {
      return keyed;
    }
    return _CcFluidHoverItemScope(
      active: _pointerInside && _activeIndex == index,
      pointerInside: _pointerInside,
      child: keyed,
    );
  }

  void _setActive(int? index, Rect? rect) {
    if (!mounted) {
      return;
    }
    if (_activeIndex == index && _displayRect == rect) {
      return;
    }
    final changed = _activeIndex != index;
    setState(() {
      _activeIndex = index;
      // Same item, new geometry (the row scrolled): snap so the wash does
      // not trail the row by [CcMotion.fast]. A new item still travels.
      _geometryOnlyUpdate = !changed && rect != null;
      if (rect != null) {
        _displayRect = rect;
      }
    });
    if (changed) {
      widget.onActiveIndexChanged?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final travel = _geometryOnlyUpdate
        ? Duration.zero
        : CcMotion.resolveTravel(context, CcMotion.fast);
    final fade = CcMotion.resolveFade(context, CcMotion.fast);
    final color = widget.highlightColor ?? context.ds.hover;
    final items = <Widget>[
      for (var index = 0; index < widget.itemCount; index++)
        _wrapItem(index, widget.itemBuilder(context, index)),
    ];

    return MouseRegion(
      cursor: widget.mouseCursor ?? MouseCursor.defer,
      onEnter: _onEnter,
      onHover: _onHover,
      onExit: _onExit,
      child: NotificationListener<ScrollNotification>(
        onNotification: (_) {
          _onScroll();
          return false;
        },
        child: Stack(
          key: _containerKey,
          clipBehavior: widget.clipBehavior,
          children: [
            widget.layoutBuilder(context, items),
            if (_displayRect case final Rect rect)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    key: const ValueKey<String>('cc-fluid-hover-highlight'),
                    opacity: _activeIndex == null ? 0 : 1,
                    duration: fade,
                    curve: CcMotion.standard,
                    child: TweenAnimationBuilder<Rect>(
                      key: ValueKey<int>(_pointerSession),
                      tween: _CcRectTween(begin: rect, end: rect),
                      duration: travel,
                      curve: CcMotion.standard,
                      builder: (context, value, _) => Transform.translate(
                        key: const ValueKey<String>('cc-fluid-hover-transform'),
                        offset: value.topLeft,
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: SizedBox(
                            width: value.width,
                            height: value.height,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: widget.borderRadius,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CcRectTween extends Tween<Rect> {
  _CcRectTween({required super.begin, required super.end});

  @override
  Rect lerp(double t) => Rect.lerp(begin, end, t)!;
}

class _CcFluidHoverItemScope extends InheritedWidget {
  const _CcFluidHoverItemScope({
    required this.active,
    required this.pointerInside,
    required super.child,
  });

  final bool active;
  final bool pointerInside;

  static _CcFluidHoverItemScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CcFluidHoverItemScope>();

  @override
  bool updateShouldNotify(_CcFluidHoverItemScope oldWidget) =>
      active != oldWidget.active || pointerInside != oldWidget.pointerInside;
}

class _CcFluidHoverConsumedScope extends InheritedWidget {
  const _CcFluidHoverConsumedScope({required super.child});

  static _CcFluidHoverConsumedScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CcFluidHoverConsumedScope>();

  @override
  bool updateShouldNotify(_CcFluidHoverConsumedScope oldWidget) => false;
}
