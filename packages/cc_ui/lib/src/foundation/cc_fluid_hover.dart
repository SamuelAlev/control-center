import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

// RTL carve-out: the hover highlight is placed in canvas coordinates from
// pointer geometry, not reading direction.

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

/// Nearest-target hover for compact, stable collections. Highlight follows the
/// nearest enabled item (gaps/padding included); containing row wins, else
/// center distance along [axis]. One geometry pass per frame.
///
/// Only when every enabled item is a safe target and layout stays stable —
/// not mixed cards, sparse layouts, or reordering rows. Shared non-interactive
/// overlay; reduced motion snaps. Scrollables and layout shifts retarget
/// after layout; animate travel only when the active item changes.
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
  ///
  /// A snapshot: it registers no dependency on the pointer entering or
  /// leaving (that would rebuild every item of the group on each crossing).
  /// Listen to [pointerInsideOf] to react to it.
  static bool isPointerInside(BuildContext context) =>
      pointerInsideOf(context)?.value ?? false;

  /// Whether the pointer is inside the surrounding hover group, as a
  /// listenable, or null outside an item scope.
  ///
  /// The scope itself only notifies its item when that item's active state
  /// changes, so the group's enter/exit does not rebuild every row; a reader
  /// that needs the crossing (see [CcTappable]) listens to this instead and
  /// repaints only when its own resolved state changes.
  static ValueListenable<bool>? pointerInsideOf(BuildContext context) =>
      _CcFluidHoverItemScope.maybeOf(context)?.pointerInside;

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

  /// Wrapper keys by item identity: the child's own key when it has one, its
  /// index otherwise. Keyed by identity rather than position so a row moving
  /// (a space jumping to the top of a recency-sorted list) carries its
  /// element, and with it its state, instead of every row from 0 to its old
  /// index remounting.
  Map<Object, GlobalKey> _keysById = {};

  /// This build's wrapper keys in item order — what [_pick] measures.
  List<GlobalKey> _itemKeys = const [];

  /// The item identities of the last build, to notice a reorder.
  List<Object> _itemIds = const [];

  final List<ScrollPosition> _ancestorScrolls = [];

  /// Item rects relative to the container, measured once and reused by every
  /// pointer move until layout or scrolling can have moved an item. Null
  /// when stale.
  List<Rect?>? _rectCache;

  int? _activeIndex;
  Rect? _displayRect;
  Offset? _pendingPosition;
  Offset? _lastPosition;
  Offset? _globalPosition;
  int? _frameCallbackId;
  int _pointerSession = 0;
  bool _pointerInside = false;
  bool _postFramePickScheduled = false;

  /// The wash. Geometry updates write here and leave the rows alone: a space
  /// opening under the pointer changes bounds every frame, and rebuilding the
  /// group to follow it drops the animation off the refresh rate.
  final ValueNotifier<_HoverHighlight?> _highlight = ValueNotifier(null);

  /// [_pointerInside] as the items see it. Published together with the
  /// active-index change (not on the raw enter event), so a row's own hover
  /// and the group's choice hand over in the same frame.
  final ValueNotifier<bool> _pointerInsideListenable = ValueNotifier(false);

  /// The rows [CcFluidHover.itemBuilder] returned on the last build that had a
  /// reason to call it: a new widget or a dependency change. A rebuild of this
  /// state alone (the active row moved) reuses them, so Flutter skips every
  /// row whose item scope did not change instead of re-running each builder.
  List<Widget>? _builtItems;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _builtItems = null;
    _rectCache = null;
    _bindAncestorScrolls();
  }

  @override
  void didUpdateWidget(covariant CcFluidHover oldWidget) {
    super.didUpdateWidget(oldWidget);
    _builtItems = null;
    // New items or new geometry: re-measure before the next pick.
    _rectCache = null;
    if (oldWidget.itemCount != widget.itemCount) {
      if ((_activeIndex ?? -1) >= widget.itemCount) {
        _setActive(null, null);
      }
      // A shorter or longer list moves the row under a still pointer.
      _queuePickAfterLayout();
    }
  }

  @override
  void dispose() {
    _unbindAncestorScrolls();
    final callbackId = _frameCallbackId;
    if (callbackId != null) {
      SchedulerBinding.instance.cancelFrameCallbackWithId(callbackId);
    }
    _highlight.dispose();
    _pointerInsideListenable.dispose();
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

  void _onEnter(PointerEnterEvent event) {
    _pointerInside = true;
    _pointerSession++;
    // Anything may have moved while the pointer was elsewhere.
    _rectCache = null;
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

  void _onScroll() {
    _rectCache = null;
    _queuePickAfterLayout();
  }

  /// [SizeChangedLayoutNotification] is dispatched mid-layout. Scheduling the
  /// pick for after the frame keeps the measurement off the layout phase;
  /// a synchronous [setState] here would rebuild while the tree is still
  /// laying out.
  ///
  /// Handled here and stopped: an enclosing group gets its own notification
  /// from its own item notifier whenever this group's resize changes the
  /// size of that item, which is the only way its rects can move. Letting
  /// every nested resize bubble made each ancestor group re-pick too.
  bool _onDescendantLayout(SizeChangedLayoutNotification _) {
    _rectCache = null;
    _queuePickAfterLayout();
    return true;
  }

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

    final rects = _rectCache ??= _measure(containerBox);
    for (var index = 0; index < rects.length; index++) {
      final rect = rects[index];
      if (rect == null) {
        continue;
      }
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

  /// Each item's rect relative to [containerBox], null for one that is not
  /// laid out (an unbuilt row of a lazy list). Walking every item to the
  /// container is the expensive part of a pick, so it runs once per layout
  /// change rather than once per pointer move.
  List<Rect?> _measure(RenderBox containerBox) {
    return [
      for (final key in _itemKeys)
        if (key.currentContext?.findRenderObject() case final RenderBox box
            when box.hasSize && box.attached)
          box.localToGlobal(Offset.zero, ancestor: containerBox) & box.size
        else
          null,
    ];
  }

  Widget _wrapItem(int index, GlobalKey key, Widget child) {
    // Size changes (a space expanding under the pointer, a sibling collapsing)
    // must retarget the wash. Pointer events do not fire for a layout shift,
    // so the highlight would keep the rectangle it measured before the shift
    // until the cursor moved.
    final keyed = KeyedSubtree(
      key: key,
      child: SizeChangedLayoutNotifier(child: child),
    );
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
      pointerInside: _pointerInsideListenable,
      child: keyed,
    );
  }

  void _setActive(int? index, Rect? rect) {
    if (!mounted) {
      return;
    }
    // Published here, beside the active change, rather than on the raw
    // enter/exit: the row under a just-entered pointer keeps its own hover
    // until the group has picked it, so nothing blinks in between.
    _pointerInsideListenable.value = _pointerInside;
    if (_activeIndex == index && _displayRect == rect) {
      return;
    }
    final changed = _activeIndex != index;
    _activeIndex = index;
    if (rect != null) {
      _displayRect = rect;
    }
    final shown = _displayRect;
    if (shown != null) {
      _highlight.value = _HoverHighlight(
        rect: shown,
        visible: index != null,
        // Same item, new geometry (the row grew or scrolled): snap so the
        // wash does not trail the row by [CcMotion.fast]. A new item travels.
        snap: !changed,
        session: _pointerSession,
      );
    }
    if (!changed) {
      return;
    }
    setState(() {});
    widget.onActiveIndexChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final nextKeys = <Object, GlobalKey>{};
    final ids = <Object>[];
    final orderedKeys = <GlobalKey>[];
    final items = <Widget>[];
    final built = _builtItems ??= [
      for (var index = 0; index < widget.itemCount; index++)
        widget.itemBuilder(context, index),
    ];
    for (var index = 0; index < widget.itemCount; index++) {
      final child = built[index];
      final ownKey = child.key;
      // A key repeated within the group (or absent) falls back to the slot,
      // so two wrappers never share one GlobalKey.
      final Object id = ownKey != null && !nextKeys.containsKey(ownKey)
          ? ownKey
          : _IndexSlot(index);
      final key = nextKeys[id] = _keysById[id] ?? GlobalKey();
      ids.add(id);
      orderedKeys.add(key);
      items.add(_wrapItem(index, key, child));
    }
    // Keys of items no longer built are dropped with this map.
    _keysById = nextKeys;
    _itemKeys = orderedKeys;
    if (!listEquals(ids, _itemIds)) {
      _itemIds = ids;
      _rectCache = null;
      // A reorder moves a different row under a still pointer.
      _queuePickAfterLayout();
    }

    return NotificationListener<SizeChangedLayoutNotification>(
      onNotification: _onDescendantLayout,
      child: MouseRegion(
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
              // A gap or padding change moves items without resizing them.
              SizeChangedLayoutNotifier(
                child: widget.layoutBuilder(context, items),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  // Its own layer: the wash travels and fades for
                  // [CcMotion.fast] on every row change, and without a
                  // boundary each of those frames repainted the rows under
                  // it as well.
                  child: RepaintBoundary(
                    child: _FluidHoverWash(
                      highlight: _highlight,
                      color: widget.highlightColor,
                      borderRadius: widget.borderRadius,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverHighlight {
  const _HoverHighlight({
    required this.rect,
    required this.visible,
    required this.snap,
    required this.session,
  });

  final Rect rect;
  final bool visible;
  final bool snap;
  final int session;
}

/// The shared wash. Listens to geometry on its own so a row changing size
/// does not rebuild the items behind it.
class _FluidHoverWash extends StatelessWidget {
  const _FluidHoverWash({
    required this.highlight,
    required this.color,
    required this.borderRadius,
  });

  final ValueNotifier<_HoverHighlight?> highlight;
  final Color? color;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? context.ds.hover;
    return ValueListenableBuilder<_HoverHighlight?>(
      valueListenable: highlight,
      builder: (context, highlight, _) {
        if (highlight == null) {
          return const SizedBox.shrink();
        }
        final travel = highlight.snap
            ? Duration.zero
            : CcMotion.resolveTravel(context, CcMotion.fast);
        final fade = CcMotion.resolveFade(context, CcMotion.fast);
        return AnimatedOpacity(
          key: const ValueKey<String>('cc-fluid-hover-highlight'),
          opacity: highlight.visible ? 1 : 0,
          duration: fade,
          curve: CcMotion.standard,
          child: TweenAnimationBuilder<Rect>(
            key: ValueKey<int>(highlight.session),
            tween: _CcRectTween(begin: highlight.rect, end: highlight.rect),
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
                      color: resolved,
                      borderRadius: borderRadius,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CcRectTween extends Tween<Rect> {
  _CcRectTween({required super.begin, required super.end});

  @override
  Rect lerp(double t) => Rect.lerp(begin, end, t)!;
}

/// The identity of an item that has no key of its own: its position.
@immutable
class _IndexSlot {
  const _IndexSlot(this.index);

  final int index;

  @override
  bool operator ==(Object other) => other is _IndexSlot && other.index == index;

  @override
  int get hashCode => index.hashCode;
}

class _CcFluidHoverItemScope extends InheritedWidget {
  const _CcFluidHoverItemScope({
    required this.active,
    required this.pointerInside,
    required super.child,
  });

  final bool active;

  /// The group's pointer-inside flag. A stable listenable rather than a
  /// value, so the pointer crossing the group edge notifies no item: only
  /// [active] flipping does, and that is the two rows trading the wash.
  final ValueListenable<bool> pointerInside;

  static _CcFluidHoverItemScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CcFluidHoverItemScope>();

  @override
  bool updateShouldNotify(_CcFluidHoverItemScope oldWidget) =>
      active != oldWidget.active ||
      !identical(pointerInside, oldWidget.pointerInside);
}

class _CcFluidHoverConsumedScope extends InheritedWidget {
  const _CcFluidHoverConsumedScope({required super.child});

  static _CcFluidHoverConsumedScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_CcFluidHoverConsumedScope>();

  @override
  bool updateShouldNotify(_CcFluidHoverConsumedScope oldWidget) => false;
}
