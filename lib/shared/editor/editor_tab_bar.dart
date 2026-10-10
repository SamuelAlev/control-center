import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_layout_node.dart';
import 'package:control_center/shared/editor/editor_tab.dart';
import 'package:control_center/shared/editor/editor_tab_face.dart';
import 'package:control_center/shared/editor/editor_tab_ghost.dart';
import 'package:control_center/shared/editor/editor_tab_landing.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/gestures.dart'
    show kMiddleMouseButton, PointerSignalEvent, PointerScrollEvent;
import 'package:flutter/semantics.dart' show SemanticsRole;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Callback fired when a tab is dropped on this bar at [insertIndex] (an
/// insertion index, 0 .. tab count). [data] carries the dragged tab + its
/// source leaf, so the bar's owner can reorder (same leaf) or move (cross leaf).
typedef TabReorderDrop = void Function(TabDragData data, int insertIndex);

/// A VS Code-style editor tab strip with bordered, draggable tabs.
///
/// Renders one bordered cell per tab: a vertical separator on the right of every
/// tab, a continuous bottom rule under the strip and a 2px accent rule on top of
/// the active tab — whose background blends into the editor body below so the tab
/// visually "opens" onto its content.
///
/// Tabs are [Draggable]: drag one within this bar to reorder, or onto another
/// pane to move/split it. The tab itself lifts ([EditorTabGhost]): held at the
/// point it was grabbed, it rides the strip while the pointer is over one and
/// tears free over the panes. The whole strip is a single [DragTarget]; while
/// a tab hovers, an animated gap opens at the insertion point (neighbours
/// slide aside, Chrome-style) and the dragged tab's own slot collapses. On
/// release the strip snaps to its final layout — which the open gap already
/// showed — and the tab glides into its slot ([EditorTabLanding]), wherever
/// that slot ended up. All of it respects reduced motion. Tab bodies are owned
/// by the caller; this widget renders chrome + selection + drag only. Trailing
/// [actions] (close / split / new-tab menu) are right-aligned.
class EditorTabBar extends StatefulWidget {
  /// Creates an [EditorTabBar].
  const EditorTabBar({
    super.key,
    required this.leafId,
    required this.tabs,
    required this.labels,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.onReorderDrop,
    this.onTabClosed,
    this.onTabContextMenu,
    this.onUntitledDraft,
    this.icons,
    this.leadings,
    this.trailings,
    this.dirty,
    this.scrambling,
    this.inlineActions = const [],
    this.actions = const [],
  }) : assert(labels.length == tabs.length),
       assert(icons == null || icons.length == labels.length),
       assert(leadings == null || leadings.length == labels.length),
       assert(trailings == null || trailings.length == labels.length),
       assert(dirty == null || dirty.length == labels.length),
       assert(scrambling == null || scrambling.length == labels.length);

  /// Id of the leaf this bar belongs to (carried in drag payloads).
  final String leafId;

  /// The tab instances, used as drag payloads (identity preserved on move).
  final List<EditorTab> tabs;

  /// Tab labels, already localized. Parallel to [tabs].
  final List<String> labels;

  /// Optional per-tab leading icon. Must match [labels] length when provided.
  final List<IconData>? icons;

  /// Optional per-tab leading WIDGET builders, taking precedence over [icons]
  /// entry by entry. For leadings the bundled icon font cannot express (an
  /// SVG brand logo): the builder is called with the tab's resolved label
  /// color so the widget can tint itself like an icon. Must match [labels]
  /// length when provided.
  final List<Widget Function(Color color)?>? leadings;

  /// Optional per-tab trailing status builders. Each receives the tab's
  /// resolved label color and renders between the label and close slot.
  final List<Widget Function(Color color)?>? trailings;

  /// Optional per-tab unsaved-changes ("dirty") flag. When a tab is dirty its
  /// close slot shows a filled dot instead of being empty; hovering the tab
  /// still swaps to the close button. Must match [labels] length when provided.
  final List<bool>? dirty;

  /// Optional per-tab "label still being worked out" flag (a conversation
  /// title a model is generating). A scrambling tab churns the letters of its
  /// label until the flag clears, then settles into it. Must match [labels]
  /// length when provided.
  final List<bool>? scrambling;

  /// Index of the selected tab.
  final int selectedIndex;

  /// Called with the tapped tab index.
  final ValueChanged<int> onTabSelected;

  /// Called when a tab is dropped on this bar.
  final TabReorderDrop onReorderDrop;

  /// Called with a tab index to close it — from the per-tab close button (shown
  /// on hover / when selected) or a middle-click on the tab. Null disables both.
  final ValueChanged<int>? onTabClosed;

  /// Called on a secondary (right) click of a tab, with its index and the global
  /// pointer position — the host opens a context menu there. Null disables it.
  ///
  /// Right-clicking deliberately does NOT select the tab (so you can close one
  /// without loading it), which means the returned future is the strip's only
  /// way to know how long its menu stands open: it paints the tab as the menu's
  /// target until the future completes. Complete it when the menu closes.
  final Future<void> Function(int index, Offset globalPosition)?
  onTabContextMenu;

  /// Called when the user double-clicks the empty space in the tab row (the
  /// gap between the last tab and the trailing actions) to open an untitled
  /// draft. Null disables.
  final VoidCallback? onUntitledDraft;

  /// Inline actions rendered inside the scroll viewport, immediately after the
  /// last tab (the `[+]` new-tab menu). They scroll with the tabs.
  final List<Widget> inlineActions;

  /// Trailing header actions, right-aligned (split / close-group / sidebar
  /// toggle). Pinned outside the scroll viewport.
  final List<Widget> actions;

  /// Strip height, bottom rule included — matches VS Code's editor tab bar.
  ///
  /// Public because any strip rendered beside this one (the messaging IDE
  /// sidebar's `CcTabs`) has to be exactly this tall: a sub-pixel difference
  /// leaves a visible jog in the rule where the two meet.
  static const double height = 35;

  @override
  State<EditorTabBar> createState() => _EditorTabBarState();
}

class _EditorTabBarState extends State<EditorTabBar> {
  /// Index of the tab under the pointer, or null. Drives the hover wash.
  int? _hovered;

  /// The tab whose context menu is currently open, or null. Held by identity,
  /// not index, because the menu is async and the tab set can shift under it.
  /// Right-click no longer selects, so this wash is the only thing saying which
  /// tab "Close" will act on once the pointer moves onto the menu.
  EditorTab? _contextMenuTab;

  /// Insertion index a hovering drag would land at, or null when none. Drives
  /// the animated drop gap at that boundary.
  int? _dropIndex;

  /// Index of the tab currently being dragged OUT of this bar, or null. Its
  /// slot collapses while the drag is in flight (the floating feedback chip
  /// stands in for it) and re-expands if the drag is cancelled.
  int? _draggingIndex;

  /// Width of the drop gap for the drag currently hovering this bar — the
  /// dragged tab's own cell width when known, else [_fallbackGapWidth].
  double _hoverGapWidth = _fallbackGapWidth;

  /// Whether the drop gaps animate. True while a drag is live; flipped false
  /// on an accepted drop so the gap snaps shut in the same frame the dropped
  /// tab claims its space (animating it closed would double-count the width).
  bool _gapsAnimate = true;

  /// Bumped on every accepted drop that touches this strip. It keys the slots'
  /// [AnimatedSize]s, so the strip's post-drop layout appears at once instead
  /// of each positional slot easing from the width of the tab it used to hold
  /// — the open gap already previewed that layout, and the landing flight
  /// carries the motion.
  int _settleEpoch = 0;

  /// The tab scroller's viewport: the lane a carried tab rides while over this
  /// strip, so it never slides over the pinned trailing actions.
  final GlobalKey _laneKey = GlobalKey();

  /// Per-cell keys so a hovering drag can measure tab boundaries.
  List<GlobalKey> _tabKeys = const [];

  /// Per-tab keyboard focus. The strip is ONE Tab stop — the selected tab;
  /// the others skip traversal and are reached with the arrow keys (the
  /// roving-focus pattern of a tab list), so Tab moves past the strip instead
  /// of walking every tab.
  final List<FocusNode> _tabFocus = [];

  /// Drives horizontal scrolling of the tab strip.
  final ScrollController _scrollController = ScrollController();

  /// Full-IDE pointer shield active while a tab is being dragged. See
  /// [_beginDragShield].
  OverlayEntry? _dragShield;

  /// Drop-gap width when the dragged tab's cell couldn't be measured (e.g. a
  /// cross-bar drag whose payload carries no width).
  static const double _fallbackGapWidth = 160;

  @override
  void dispose() {
    _endDragShield();
    _scrollController.dispose();
    for (final node in _tabFocus) {
      node.dispose();
    }
    super.dispose();
  }

  void _ensureFocusNodes(int count) {
    while (_tabFocus.length < count) {
      _tabFocus.add(FocusNode(debugLabel: 'editor-tab'));
    }
    while (_tabFocus.length > count) {
      _tabFocus.removeLast().dispose();
    }
    for (var i = 0; i < count; i++) {
      _tabFocus[i].skipTraversal = i != widget.selectedIndex;
    }
  }

  /// Arrow keys move focus along the strip (wrapping), Home/End jump to its
  /// ends, Enter/Space select. Moving focus does not select: opening a tab can
  /// boot a rig or spawn a shell, so that waits for an explicit activation.
  KeyEventResult _onTabKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final count = widget.tabs.length;
    final key = event.logicalKey;
    if (event is KeyDownEvent &&
        (key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space)) {
      widget.onTabSelected(index);
      return KeyEventResult.handled;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    int? target;
    if (key == LogicalKeyboardKey.arrowRight) {
      target = rtl ? index - 1 : index + 1;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      target = rtl ? index + 1 : index - 1;
    } else if (key == LogicalKeyboardKey.home) {
      target = 0;
    } else if (key == LogicalKeyboardKey.end) {
      target = count - 1;
    }
    if (target == null || count == 0) {
      return KeyEventResult.ignored;
    }
    final next = target % count;
    final node = _tabFocus[next];
    node.requestFocus();
    final cell = _tabKeys[next].currentContext;
    if (cell != null) {
      Scrollable.ensureVisible(cell);
    }
    return KeyEventResult.handled;
  }

  /// While a tab is being dragged, drop a transparent [PointerInterceptor] over
  /// the whole IDE so an embedded editor/browser `<iframe>` (a web platform
  /// view) can't swallow the drag's pointer stream the moment the cursor crosses
  /// into it — otherwise the drag (and the [DragTarget] drop-edge tracking used
  /// to split panes) freezes over the iframe. Unlike the resize shield this must
  /// NOT absorb: the drop still has to hit-test the DragTargets in the panes
  /// below. Wrapping the interceptor in [IgnorePointer] keeps the shield out of
  /// Flutter's hit-test walk (so those DragTargets are still found) while the
  /// DOM element keeps intercepting at the browser level (so events keep
  /// reaching Flutter and the drag stays live). No-op off-web.
  void _beginDragShield() {
    if (_dragShield != null) {
      return;
    }
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }
    _dragShield = OverlayEntry(
      builder: (_) => Positioned.fill(
        child: IgnorePointer(
          child: PointerInterceptor(child: const SizedBox.expand()),
        ),
      ),
    );
    overlay.insert(_dragShield!);
  }

  void _endDragShield() {
    _dragShield?.remove();
    _dragShield = null;
  }

  /// Opens tab [index]'s context menu WITHOUT selecting it, holding the tab's
  /// wash for as long as the menu stands open.
  Future<void> _openContextMenu(int index, Offset globalPosition) async {
    final tab = widget.tabs[index];
    setState(() => _contextMenuTab = tab);
    try {
      await widget.onTabContextMenu!(index, globalPosition);
    } finally {
      if (mounted && identical(_contextMenuTab, tab)) {
        setState(() => _contextMenuTab = null);
      }
    }
  }

  void _ensureKeys(int count) {
    if (_tabKeys.length != count) {
      _tabKeys = List.generate(count, (_) => GlobalKey());
    }
  }

  /// Maps the pointer's global position to the insertion index it implies:
  /// before the tab it is left-of-center over, after otherwise; clamped to the
  /// ends so dragging past the last tab appends.
  int _insertionIndexFor(Offset globalPosition) {
    for (var i = 0; i < _tabKeys.length; i++) {
      final box = _tabKeys[i].currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) {
        continue;
      }
      final origin = box.localToGlobal(Offset.zero);
      final rect = origin & box.size;
      if (globalPosition.dx < rect.center.dx) {
        return i;
      }
      if (globalPosition.dx < rect.right) {
        return i + 1;
      }
    }
    return widget.tabs.length;
  }

  void _onDragMove(DragTargetDetails<TabDragData> details) {
    // The ghost rides this strip while the pointer is over it.
    final box = _laneKey.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      EditorTabDragSession.current?.enterLane(
        this,
        box.localToGlobal(Offset.zero) & box.size,
      );
    }
    final next = _insertionIndexFor(details.offset);
    final width = details.data.width ?? _fallbackGapWidth;
    if (next != _dropIndex || width != _hoverGapWidth || !_gapsAnimate) {
      setState(() {
        _dropIndex = next;
        _hoverGapWidth = width;
        _gapsAnimate = true;
      });
    }
  }

  void _clearDrop() {
    EditorTabDragSession.current?.leaveLane(this);
    if (_dropIndex != null) {
      setState(() => _dropIndex = null);
    }
  }

  /// Rendered width of tab [index]'s cell from the last layout, or null before
  /// first layout / while its slot is collapsed.
  double? _measuredWidthOf(int index) {
    final box =
        _tabKeys[index].currentContext?.findRenderObject() as RenderBox?;
    return (box != null && box.hasSize) ? box.size.width : null;
  }

  /// The drag anchor for tab [index]: opens the [EditorTabDragSession] (before
  /// the avatar exists, so its first hit test already finds it) and keeps the
  /// avatar's origin AT the pointer, so every drop target keeps reading the
  /// pointer from `details.offset`. The ghost does the grab-point offset.
  Offset _beginSession(int index, BuildContext cell, Offset position) {
    final box = cell.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final origin = box.localToGlobal(Offset.zero);
      EditorTabDragSession.current = EditorTabDragSession(
        tab: widget.tabs[index],
        face: _ghostFace(index),
        grab: position - origin,
        size: box.size,
        origin: origin,
      );
    }
    return Offset.zero;
  }

  /// The face a lifted tab shows: the tab as selected, with its close slot
  /// reserved but empty.
  Widget _ghostFace(int index) {
    return EditorTabFace(
      label: widget.labels[index],
      selected: true,
      icon: widget.icons?[index],
      leading: widget.leadings?[index],
      trailing: widget.trailings?[index],
      reserveAffordance: widget.onTabClosed != null,
    );
  }

  /// A drag left this bar with tab [index]: collapse its slot and pre-open the
  /// drop gap in its place, so the strip stays visually still until the drag
  /// actually moves somewhere.
  void _onDragStarted(int index) {
    _beginDragShield();
    setState(() {
      _draggingIndex = index;
      _hoverGapWidth = _measuredWidthOf(index) ?? _fallbackGapWidth;
      _gapsAnimate = true;
      _dropIndex = index;
    });
  }

  /// The drag ended (accepted anywhere, or cancelled): launch the landing
  /// flight and restore the slot. On a cancel the tab is still here, its slot
  /// re-expands and the flight carries it home; on an accepted move the layout
  /// mutation rebuilds the strips and the flight finds the tab's new slot. The
  /// avatar can outlive this bar (moving a leaf's last tab away closes the
  /// leaf), so guard.
  void _onDragEnded(DraggableDetails details) {
    _endDragShield();
    final session = EditorTabDragSession.current;
    EditorTabDragSession.current = null;
    if (!mounted) {
      return;
    }
    if (session != null) {
      EditorTabLanding.fly(context, session);
    }
    setState(() {
      _draggingIndex = null;
      _dropIndex = null;
      if (details.wasAccepted) {
        _gapsAnimate = false;
        _settleEpoch++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    _ensureKeys(widget.tabs.length);
    _ensureFocusNodes(widget.tabs.length);
    // The strip carries the continuous bottom rule (the divider under the tabs).
    // Inactive tabs sit ON that rule; the ACTIVE tab paints a bottom border in
    // the body color that overpaints the rule, so it visually "opens" onto its
    // content (VS Code parity).
    return SizedBox(
      height: EditorTabBar.height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: t.bgSecondary,
          border: Border(bottom: BorderSide(color: t.borderPrimary)),
        ),
        child: DragTarget<TabDragData>(
          onWillAcceptWithDetails: (_) => true,
          onMove: _onDragMove,
          onLeave: (_) => _clearDrop(),
          onAcceptWithDetails: (details) {
            final index = _dropIndex ?? widget.tabs.length;
            // The open gap already shows the strip as it will be after the
            // drop, so the strip snaps straight to it: the gap shuts in the
            // same frame the dropped tab claims its space, and no slot eases
            // from the width of the tab it held before. The landing flight
            // (launched by the source bar) carries the motion.
            setState(() {
              _dropIndex = null;
              _gapsAnimate = false;
              _settleEpoch++;
            });
            widget.onReorderDrop(details.data, index);
          },
          builder: (context, candidate, rejected) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The tab strip + inline actions scroll horizontally when
                // overflowing. Wheel-over-tabs (vertical wheel on desktop,
                // trackpad on web) is translated into horizontal scroll. The
                // CcScrollbar overlays a thin thumb at the bottom while
                // scrolling (no reserved row → no layout shift).
                Expanded(
                  child: Listener(
                    key: _laneKey,
                    onPointerSignal: _onPointerSignal,
                    child: CcScrollbar(
                      controller: _scrollController,
                      color: t.fgQuaternary,
                      thickness: 4,
                      scrollbarOrientation: ScrollbarOrientation.bottom,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        scrollDirection: Axis.horizontal,
                        // Keep the drag-reorder hit-test on the tabs; the
                        // scroller only reacts to wheel/drag-from-trackpad,
                        // not left-button drags (those reorder).
                        physics: const ClampingScrollPhysics(),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // A (usually zero-width) drop gap sits at every
                            // insertion boundary; the hovered one opens to the
                            // dragged tab's width, sliding neighbours aside.
                            for (var i = 0; i < widget.labels.length; i++) ...[
                              _buildGap(i),
                              _buildTab(i),
                            ],
                            _buildGap(widget.labels.length),
                            ...widget.inlineActions,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Trailing actions are pinned outside the scroller, sized to
                // their content so the tab strip gets ALL the remaining width
                // (not a 50/50 split with the scroller).
                _buildTrailing(t),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Translates a vertical wheel/trackpad scroll into a horizontal tab scroll
  /// (so hovering the tabs and spinning the wheel scrolls them, VS Code-style).
  /// Horizontal scroll signals pass through unchanged.
  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      final sc = _scrollController;
      if (!sc.hasClients) {
        return;
      }
      final max = sc.position.maxScrollExtent;
      if (max <= 0) {
        return;
      }
      // Prefer the horizontal delta when present (trackpad horizontal swipe);
      // otherwise fall back to the vertical wheel.
      final delta = event.scrollDelta.dx != 0
          ? event.scrollDelta.dx
          : event.scrollDelta.dy;
      if (delta == 0) {
        return;
      }
      final next = (sc.offset + delta).clamp(0.0, max);
      if ((next - sc.offset).abs() > 0) {
        sc.jumpTo(next);
      }
    }
  }

  /// The animated drop gap at insertion boundary [index] (before tab [index];
  /// `tabs.length` is the trailing edge). Always present so activation
  /// animates from zero width instead of popping in. With reduced motion the
  /// resolved duration is zero and the gap simply appears — still a clear
  /// positional indicator, without the slide.
  Widget _buildGap(int index) {
    return AnimatedContainer(
      duration: _gapsAnimate
          ? CcMotion.resolve(context, CcMotion.normal)
          : Duration.zero,
      curve: CcMotion.standard,
      width: _dropIndex == index ? _hoverGapWidth : 0,
    );
  }

  Widget _buildTab(int index) {
    final selected = index == widget.selectedIndex;
    // A tab holding an open context menu reads as hovered: the pointer is over
    // the menu overlay by then, so the real hover has already left.
    final hovered =
        index == _hovered || identical(widget.tabs[index], _contextMenuTab);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final labelColor = EditorTabFace.labelColorFor(t, selected: selected);

    final focusNode = _tabFocus[index];
    final cell = KeyedSubtree(
      key: _tabKeys[index],
      // A tab to assistive tech — selected or not, activated by tap — and a
      // keyboard stop with a visible focus ring (see [_onTabKey]).
      child: Semantics(
        container: true,
        role: SemanticsRole.tab,
        selected: selected,
        child: Focus(
          focusNode: focusNode,
          onKeyEvent: (_, event) => _onTabKey(index, event),
          child: FocusRing(
            focusNode: focusNode,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = index),
              onExit: (_) => setState(
                () => _hovered = _hovered == index ? null : _hovered,
              ),
              child: GestureDetector(
                onTap: () => widget.onTabSelected(index),
                // Right-click opens the menu WITHOUT selecting the tab, so closing a
                // tab from its menu never first loads its body (a rig boots, a PTY
                // spawns, a diff re-scrolls). The tab is washed for the menu's
                // lifetime instead — see [_openContextMenu].
                onSecondaryTapUp: widget.onTabContextMenu == null
                    ? null
                    : (details) =>
                          _openContextMenu(index, details.globalPosition),
                // Invisible while a released drag of this tab is still gliding
                // into this slot — see [EditorTabLanding].
                child: EditorTabLandingSlot(
                  tab: widget.tabs[index],
                  child: EditorTabFace(
                    label: widget.labels[index],
                    selected: selected,
                    hovered: hovered,
                    icon: widget.icons?[index],
                    leading: widget.leadings?[index],
                    trailing: widget.trailings?[index],
                    scrambling: widget.scrambling?[index] ?? false,
                    // Hovering shows the close button; otherwise a dirty tab
                    // shows an unsaved-changes dot, a selected clean tab shows
                    // the close button and an unselected clean tab shows
                    // nothing — VS Code behaviour.
                    reserveAffordance: widget.onTabClosed != null,
                    affordance: widget.onTabClosed == null
                        ? null
                        : _buildTabAffordance(
                            index: index,
                            hovered: hovered,
                            selected: selected,
                            color: labelColor,
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // While this tab's avatar is in flight its slot collapses (the drop gap
    // stands in for it); a cancelled drag re-expands it. The AnimatedSize
    // element survives the drag-state rebuilds, so both directions animate —
    // until an accepted drop re-keys it (see [_settleEpoch]). Reduced motion
    // skips AnimatedSize entirely (the slot snaps) — it cannot take a zero
    // duration: its controller would complete synchronously inside its own
    // performLayout and re-dirty the render object mid-layout.
    final Widget collapsible = _draggingIndex == index
        ? const SizedBox(width: 0, height: EditorTabBar.height)
        : cell;
    final slot = CcMotion.reduced(context)
        ? collapsible
        : AnimatedSize(
            key: ValueKey(_settleEpoch),
            duration: CcMotion.normal,
            curve: CcMotion.standard,
            alignment: AlignmentDirectional.centerStart,
            child: collapsible,
          );

    final draggable = Draggable<TabDragData>(
      data: TabDragData(
        sourceLeafId: widget.leafId,
        tabIndex: index,
        tab: widget.tabs[index],
        // Measured from the previous frame's layout — the avatar snapshots
        // this at drag start, so the receiving bar's gap matches the cell.
        width: _measuredWidthOf(index),
      ),
      dragAnchorStrategy: (_, cell, position) =>
          _beginSession(index, cell, position),
      // The drag shield (begun in _onDragStarted) protects the drag from the
      // IDE's iframes — see _beginDragShield. onDragEnd fires whether the drop
      // was accepted or cancelled.
      onDragStarted: () => _onDragStarted(index),
      onDragEnd: _onDragEnded,
      feedback: const EditorTabGhost(),
      child: slot,
    );
    // Middle-click closes the tab (VS Code parity). A passive [Listener] so it
    // never steals the left-button drag/select gestures below it.
    return Listener(
      onPointerDown: (event) {
        if (widget.onTabClosed != null && event.buttons == kMiddleMouseButton) {
          widget.onTabClosed!(index);
        }
      },
      child: draggable,
    );
  }

  /// The 16×16 close/dirty slot content for tab [index]. Hover always wins with
  /// the close button; otherwise a dirty tab shows the unsaved dot, a selected
  /// clean tab shows the close button and everything else shows nothing.
  Widget? _buildTabAffordance({
    required int index,
    required bool hovered,
    required bool selected,
    required Color color,
  }) {
    final isDirty =
        widget.dirty != null &&
        index < widget.dirty!.length &&
        widget.dirty![index];
    if (hovered) {
      return _TabCloseButton(
        color: color,
        tabLabel: widget.labels[index],
        onTap: () => widget.onTabClosed!(index),
      );
    }
    if (isDirty) {
      return _DirtyDot(color: color);
    }
    if (selected) {
      return _TabCloseButton(
        color: color,
        tabLabel: widget.labels[index],
        onTap: () => widget.onTabClosed!(index),
      );
    }
    return null;
  }

  Widget _buildTrailing(DesignSystemTokens t) {
    // Sized to the actions (no Expanded), so the tab scroller keeps all the
    // remaining width. The bottom rule is drawn once by the strip, so the
    // actions row adds none of its own.
    return Row(mainAxisSize: MainAxisSize.min, children: widget.actions);
  }
}

/// The small filled circle shown in a tab's affordance slot when the file has
/// unsaved changes — VS Code's dirty indicator. Swaps to the close button when
/// the tab is hovered (handled by the caller). Non-interactive.
class _DirtyDot extends StatelessWidget {
  const _DirtyDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// The small per-tab close (×) button. Its slot is always reserved by the
/// caller (so the label never shifts); the button itself appears on hover / when
/// selected. Tapping closes the tab — the nested [CcTappable] wins the tap
/// over the cell's select gesture and its opaque hit-test keeps a drag from
/// starting on it.
class _TabCloseButton extends StatelessWidget {
  const _TabCloseButton({
    required this.color,
    required this.tabLabel,
    required this.onTap,
  });

  final Color color;

  /// The tab's label, so the button is announced as "Close Overview" rather
  /// than a bare "Close" beside every tab.
  final String tabLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      // Resilient lookup: this bar is pumped bare in tests and sub-windows,
      // where no AppLocalizations delegate may be mounted.
      semanticLabel: Localizations.of<AppLocalizations>(
        context,
        AppLocalizations,
      )?.closeTabNamed(tabLabel),
      borderRadius: BorderRadius.circular(3),
      builder: (context, states) => DecoratedBox(
        decoration: BoxDecoration(
          color: states.contains(WidgetState.hovered)
              ? t.hover
              : const Color(0x00000000),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Center(
          child: Icon(
            AppIcons.x,
            size: 13,
            color: states.contains(WidgetState.hovered) ? t.fg : color,
          ),
        ),
      ),
    );
  }
}
