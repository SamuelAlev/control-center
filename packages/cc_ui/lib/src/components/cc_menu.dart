import 'dart:async';
import 'dart:math' as math;

import 'package:cc_ui/fuzzy.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_panel_search_field.dart';
import 'package:cc_ui/src/foundation/cc_row_reveal.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// One [CcMenu] row: action, select option, submenu, section heading, or divider.
/// Short verb labels; don't repeat the trigger's shared action. Put
/// [destructive] last, after a [CcMenuItem.divider].
///
/// [selected]: leading check; reserve check gutter for the whole column when any
/// sibling is selectable. [trailing]: only for a bound shortcut.
/// [trailingChild]: a short status chip in that same slot, used instead of
/// [trailing]. [searchText]: extra match terms (e.g. words lifted into a
/// [CcMenuItem.section] heading).
/// [CcMenuItem.submenu]: one nesting level max; omit shared parent terms from
/// child labels; only in [showCcMenuAt], not flat [CcMenu].
@immutable
class CcMenuItem {
  /// Creates an action / selectable [CcMenuItem].
  const CcMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.leading,
    this.trailing,
    this.trailingChild,
    this.searchText,
    this.selected = false,
    this.destructive = false,
    this.enabled = true,
  }) : isDivider = false,
       isSection = false,
       children = const [];

  /// Creates a row that opens a flyout of [children] (a nested menu).
  const CcMenuItem.submenu({
    required this.label,
    required this.children,
    this.icon,
    this.leading,
    this.searchText,
    this.enabled = true,
  }) : onSelected = _noop,
       trailing = null,
       trailingChild = null,
       selected = false,
       destructive = false,
       isDivider = false,
       isSection = false;

  /// A non-interactive separator row — use it to set the destructive group
  /// apart at the end of the menu, or to group related actions.
  const CcMenuItem.divider()
    : label = '',
      onSelected = _noop,
      icon = null,
      leading = null,
      trailing = null,
      trailingChild = null,
      searchText = null,
      selected = false,
      destructive = false,
      enabled = false,
      isDivider = true,
      isSection = false,
      children = const [];

  /// A non-interactive heading naming the group of rows beneath it, rendered
  /// as a mono uppercase eyebrow (the same treatment as `CcSidebarGroup`).
  ///
  /// A heading earns its place when it lets the rows below it SHED a word —
  /// five labels ending in "(VM)" become five plain names under one VIRTUAL
  /// MACHINE heading, which is the difference between reading to the end of
  /// every line and reading the first word. Pass [CcMenuItem.searchText] on
  /// those rows so the shed word still matches when the menu is searched.
  ///
  /// Give [label] in sentence case like any other string; the uppercase is a
  /// rendering treatment, not the copy.
  const CcMenuItem.section(this.label)
    : onSelected = _noop,
      icon = null,
      leading = null,
      trailing = null,
      trailingChild = null,
      searchText = null,
      selected = false,
      destructive = false,
      enabled = false,
      isDivider = false,
      isSection = true,
      children = const [];

  static void _noop() {}

  /// The row's text.
  final String label;

  /// Invoked when the row is selected (the menu closes first).
  final VoidCallback onSelected;

  /// Optional leading icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see [CcIcons]).
  final IconData? icon;

  /// Optional leading WIDGET builder, taking precedence over [icon]. For
  /// leadings the bundled icon font cannot express (an SVG brand logo): the
  /// builder receives the row's resolved label color so the widget can tint
  /// itself like an icon.
  final Widget Function(Color color)? leading;

  /// Optional right-aligned keyboard-shortcut hint (e.g. `⌘W`). Purely visual.
  final String? trailing;

  /// Optional right-aligned status chip. Drawn instead of [trailing].
  final Widget? trailingChild;

  /// Extra words a searchable menu matches this row on, never rendered
  /// (synonyms, or a term its section heading lifted out of the label).
  final String? searchText;

  /// Whether this row is selected — draws a leading check mark.
  final bool selected;

  /// Whether this is a destructive action — rendered in the danger color.
  final bool destructive;

  /// Whether the row can be selected.
  final bool enabled;

  /// Whether this entry renders as a hairline separator instead of a row.
  final bool isDivider;

  /// Whether this entry renders as a non-interactive group heading.
  final bool isSection;

  /// Child rows shown in a flyout submenu; empty for a leaf row.
  final List<CcMenuItem> children;

  /// Whether this row opens a submenu.
  bool get hasChildren => children.isNotEmpty;

  /// Whether the keyboard highlight may land on this row. Dividers, section
  /// headings and disabled rows are skipped.
  bool get isSelectable => !isDivider && !isSection && enabled;
}

// ─────────────────────────────────────────────────────────────────────────────
// Highlight + filtering (shared by the flat dropdown and the cascade overlay)
// ─────────────────────────────────────────────────────────────────────────────

/// Index of the first row the highlight may land on, or -1 when the list holds
/// no selectable row.
int _firstSelectable(List<CcMenuItem> items) {
  for (var i = 0; i < items.length; i++) {
    if (items[i].isSelectable) {
      return i;
    }
  }
  return -1;
}

/// Moves a highlight index over [items] by [delta], wrapping around and
/// skipping dividers, section headings and disabled rows. Returns [from]
/// unchanged when nothing is selectable.
///
/// [from] may be -1 ("nothing highlighted"), in which case a downward step
/// lands on the first selectable row and an upward step on the last.
int _moveHighlight(List<CcMenuItem> items, int from, int delta) {
  final n = items.length;
  if (n == 0) {
    return -1;
  }
  var i = from;
  for (var step = 0; step < n; step++) {
    i = (i + delta) % n;
    if (i < 0) {
      i += n;
    }
    if (items[i].isSelectable) {
      return i;
    }
  }
  return from;
}

/// The rows a searchable menu shows for [query].
///
/// An empty query returns [items] verbatim — the authored order, headings and
/// dividers intact, because that grouped list IS the menu every time it opens
/// before anyone types.
///
/// A non-empty query returns a FLAT, globally ranked list with every heading
/// and divider dropped. Ranking across the whole menu is the point of typing;
/// keeping the groups would pin each match inside its section and bury the best
/// one. It also means a heading can never outlive the rows it named.
List<CcMenuItem> _filterItems(List<CcMenuItem> items, String query) {
  final q = query.trim();
  if (q.isEmpty) {
    return items;
  }
  final scored = <(CcMenuItem item, int score, int index)>[];
  for (var i = 0; i < items.length; i++) {
    final item = items[i];
    if (item.isDivider || item.isSection) {
      continue;
    }
    // Label and keywords are scored independently and the better one wins: a
    // combined string would let a match straddle the seam and would blunt the
    // shorter-target tiebreak, so a keyword hit could outrank a label hit.
    final byLabel = fuzzyScore(q, item.label);
    final byKeyword = item.searchText == null
        ? null
        : fuzzyScore(q, item.searchText!);
    final score = switch ((byLabel, byKeyword)) {
      (null, null) => null,
      (final a?, null) => a,
      (null, final b?) => b,
      (final a?, final b?) => math.max(a, b),
    };
    if (score == null) {
      continue;
    }
    scored.add((item, score, i));
  }
  // Stable on the authored order within an equal score.
  scored.sort(
    (a, b) => a.$2 != b.$2 ? b.$2.compareTo(a.$2) : a.$3.compareTo(b.$3),
  );
  return [for (final s in scored) s.$1];
}

/// Flat dropdown menu (Material `PopupMenuButton` replacement). Tap [target]
/// for a floating panel of [CcTappable] rows; destructive rows use `t.danger`.
/// Selection closes then calls `onSelected`.
///
/// Arrows move an index highlight (skip dividers/sections/disabled); Enter
/// activates; Esc dismisses. Index (not focus) so [searchable] can keep focus
/// in the search field. Flat only — no [CcMenuItem.submenu]; use [showCcMenuAt]
/// for cascading menus. Panel ≥ trigger width, grows to [maxWidth], then
/// truncates with tooltip.
class CcMenu extends StatefulWidget {
  /// Creates a [CcMenu].
  const CcMenu({
    super.key,
    required this.target,
    required this.items,
    this.controller,
    this.targetAnchor = AlignmentDirectional.bottomStart,
    this.followerAnchor = AlignmentDirectional.topStart,
    this.offset = const Offset(0, 6),
    this.minWidth = 180,
    this.maxWidth = 320,
    this.searchable = false,
    this.searchHint,
    this.emptySearchLabel,
    this.toggleOnTargetTap = true,
    this.semanticLabel,
  });

  /// The trigger widget the menu anchors to.
  final Widget target;

  /// The menu rows.
  final List<CcMenuItem> items;

  /// Optional external open/close controller; an internal one is created when
  /// null. Tapping the target toggles it either way — pass one to OBSERVE the
  /// open state, which a hover-revealed trigger needs: the open panel's
  /// full-screen dismiss barrier ends the trigger's hover, so without this the
  /// trigger fades out from under its own menu.
  final CcOverlayController? controller;

  /// Point on the target the panel aligns to (directional — mirrors in RTL).
  final AlignmentGeometry targetAnchor;

  /// Point on the panel aligned to [targetAnchor].
  final AlignmentGeometry followerAnchor;

  /// Extra offset applied to the panel. With directional anchors the `dx` is
  /// logical (toward the reading direction's end) and mirrors under RTL.
  final Offset offset;

  /// Minimum width of the menu panel. The open panel is additionally floored
  /// to the trigger's width so it never reads narrower than its button.
  final double minWidth;

  /// Maximum width of the menu panel; longer row labels truncate with an
  /// ellipsis and disclose their full text in a tooltip. A [searchable] menu
  /// takes this as its DEFINITE width.
  final double maxWidth;

  /// Whether a prefocused search field is pinned above the rows, filtering
  /// them as you type (see [_filterItems] for what a query does to headings).
  ///
  /// Opt-in, and worth it somewhere past a dozen rows: a text field in a
  /// four-row dropdown is chrome nobody asked for. A searchable panel also
  /// takes a definite [maxWidth] instead of shrink-wrapping, because a menu
  /// that resizes on every keystroke cannot be read while typing.
  final bool searchable;

  /// Placeholder for the search field.
  final String? searchHint;

  /// Row shown when a query matches nothing. Omitted when null.
  final String? emptySearchLabel;

  /// Whether tapping the target toggles the menu.
  ///
  /// Turn this OFF when [target] is itself a button (a [CcIconButton] overflow
  /// trigger) and drive a [controller] from its own `onPressed`. Left on, the
  /// target is wrapped in a second tappable, so which of the two nested
  /// recognizers wins the gesture arena decides whether the menu opens — and
  /// the target renders none of the hover/press feedback that tells a user it
  /// is a button at all.
  final bool toggleOnTargetTap;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcMenu> createState() => _CcMenuState();
}

class _CcMenuState extends State<CcMenu> {
  CcOverlayController? _internal;

  CcOverlayController get _controller =>
      widget.controller ?? (_internal ??= CcOverlayController());

  // Focus scope for the open menu: `closedLoop` traps Tab/Shift-Tab within the
  // menu instead of leaking to the background. What holds primary focus is the
  // search field when searchable, and the panel's own key-handling node
  // otherwise — never a row, since rows run on the highlight index.
  final FocusScopeNode _panelScope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  final TextEditingController _query = TextEditingController();
  final FocusNode _field = FocusNode(debugLabel: 'CcMenu.search');
  final ScrollController _scroll = ScrollController();

  /// Keeps the arrow-key highlight inside the scrolled viewport.
  final CcRowReveal _rows = CcRowReveal();

  int _highlight = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOpenChanged);
  }

  @override
  void didUpdateWidget(CcMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller == oldWidget.controller) {
      return;
    }
    (oldWidget.controller ?? _internal)?.removeListener(_onOpenChanged);
    _controller.addListener(_onOpenChanged);
  }

  @override
  void dispose() {
    // An externally supplied controller is the caller's to dispose; only the
    // lazily created internal one is ours.
    _controller.removeListener(_onOpenChanged);
    _internal?.dispose();
    _panelScope.dispose();
    _query.dispose();
    _field.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// Resets per-session state as the panel opens — a reopened menu must not
  /// inherit the last session's query or highlight.
  void _onOpenChanged() {
    if (!_controller.isOpen) {
      return;
    }
    _query.clear();
    setState(() => _highlight = _initialHighlight(widget.items));
  }

  /// Where the highlight starts. A searchable menu pre-highlights its first
  /// row so Enter fires the top result without pressing Down first; a plain
  /// dropdown starts with nothing highlighted, the conventional behaviour for
  /// a menu you opened with the mouse.
  int _initialHighlight(List<CcMenuItem> items) =>
      widget.searchable ? _firstSelectable(items) : -1;

  List<CcMenuItem> get _visibleItems => widget.searchable
      ? _filterItems(widget.items, _query.text)
      : widget.items;

  void _select(CcMenuItem item) {
    if (!item.isSelectable) {
      return;
    }
    _controller.hide();
    item.onSelected();
  }

  void _onQueryChanged(String _) {
    setState(() => _highlight = _firstSelectable(_visibleItems));
    // A re-filtered list is a new list: show it from its first match rather
    // than from wherever the previous list was scrolled to.
    _rows.reveal(_highlight);
  }

  void _moveBy(int delta) {
    final items = _visibleItems;
    final previous = _highlight;
    final next = _moveHighlight(items, previous, delta);
    setState(() => _highlight = next);
    _rows.reveal(next, from: previous);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.escape) {
      // Two-stage: a typed query is the thing Escape undoes first. Only an
      // already-empty field closes the menu, so a mistyped search never costs
      // the whole panel.
      if (widget.searchable && _query.text.isNotEmpty) {
        _query.clear();
        _onQueryChanged('');
        return KeyEventResult.handled;
      }
      _controller.hide();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveBy(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveBy(-1);
      return KeyEventResult.handled;
    }
    // Space activates only in a plain dropdown — in a search field it is a
    // character, and swallowing it would make two-word queries impossible.
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        (key == LogicalKeyboardKey.space && !widget.searchable)) {
      final items = _visibleItems;
      if (_highlight >= 0 && _highlight < items.length) {
        _select(items[_highlight]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      target: widget.toggleOnTargetTap
          ? CcTappable(
              onPressed: _controller.toggle,
              semanticLabel: widget.semanticLabel,
              builder: (context, states) => widget.target,
            )
          : widget.target,
      overlayBuilder: _buildPanel,
      // The menu often floats over the IDE's embedded editor/browser iframe;
      // shield it so its rows stay clickable there (no-op off-web).
      interceptPointer: true,
    );
  }

  List<Widget> _buildItemRuns(
    List<CcMenuItem> items, {
    required bool showCheckGutter,
  }) {
    final result = <Widget>[];
    var run = <int>[];

    void flush() {
      if (run.isEmpty) {
        return;
      }
      final indices = run;
      result.add(
        CcFluidHover(
          itemCount: indices.length,
          isItemDisabled: (localIndex) => !items[indices[localIndex]].enabled,
          onActiveIndexChanged: (localIndex) {
            if (localIndex == null) {
              return;
            }
            final index = indices[localIndex];
            if (_highlight != index) {
              setState(() => _highlight = index);
            }
          },
          itemBuilder: (context, localIndex) {
            final index = indices[localIndex];
            return KeyedSubtree(
              key: _rows.keyAt(index),
              child: _CcMenuRow(
                item: items[index],
                showCheckGutter: showCheckGutter,
                highlighted: index == _highlight,
                focusable: false,
                onActivate: () => _select(items[index]),
              ),
            );
          },
          layoutBuilder: (context, registered) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: registered,
          ),
        ),
      );
      run = <int>[];
    }

    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item.isDivider || item.isSection) {
        flush();
        result.add(
          item.isDivider
              ? const _CcMenuDivider()
              : _CcMenuSection(label: item.label),
        );
      } else {
        run.add(index);
      }
    }
    flush();
    return result;
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    // Never render the panel narrower than its trigger; when the trigger is
    // wider than the cap, matching the trigger wins.
    final minWidth = math.max(widget.minWidth, targetSize?.width ?? 0);
    final maxWidth = math.max(widget.maxWidth, minWidth);
    final items = _visibleItems;
    _rows.resize(items.length);
    final showCheckGutter = items.any((i) => i.selected);

    return FocusScope(
      node: _panelScope,
      autofocus: true,
      child: Focus(
        // Exactly one autofocus per scope: the field claims it when there is
        // one, otherwise this node does so the arrow keys have a listener.
        autofocus: !widget.searchable,
        onKeyEvent: _onKey,
        child: _MenuSurface(
          minWidth: minWidth,
          maxWidth: maxWidth,
          definiteWidth: widget.searchable,
          scrollController: widget.searchable ? _scroll : null,
          header: widget.searchable
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CcPanelSearchField(
                      controller: _query,
                      focusNode: _field,
                      hintText: widget.searchHint,
                      autofocus: true,
                      onChanged: _onQueryChanged,
                    ),
                    const _CcMenuDivider(flush: true),
                  ],
                )
              : null,
          // Edge-to-edge rows: no panel padding, so the hover wash and the row
          // divider run the full width of the menu.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (items.isEmpty && widget.emptySearchLabel != null)
                _CcMenuEmpty(label: widget.emptySearchLabel!),
              ..._buildItemRuns(items, showCheckGutter: showCheckGutter),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a cascading [CcMenu]-style floating panel at [position] (global
/// coordinates) — the cc_ui replacement for Material's `showMenu`, for
/// right-click context menus. Supports [CcMenuItem.submenu] flyouts,
/// [CcMenuItem.selected] check marks, [CcMenuItem.section] headings and
/// [CcMenuItem.trailing] shortcut hints.
///
/// Selecting a row closes the menu first, then calls its `onSelected`; clicking
/// away, right-clicking away, or pressing Escape dismisses it. Keyboard: up/down
/// move the highlight, right/Enter open a submenu, left/Escape step back out.
///
/// [onDismissed] fires exactly once when the panel closes, whichever way it
/// went — for callers that paint an "acting on this row" state on whatever they
/// opened the menu from (the pointer has left that element, so hover cannot
/// carry it) and need to know when to drop it. It runs BEFORE the selected
/// row's `onSelected`.
void showCcMenuAt({
  required BuildContext context,
  required Offset position,
  required List<CcMenuItem> items,
  double minWidth = 180,
  double maxWidth = 320,
  VoidCallback? onDismissed,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  void dismiss() {
    if (entry.mounted) {
      entry.remove();
      onDismissed?.call();
    }
  }

  entry = OverlayEntry(
    builder: (_) => _CcCascadeMenuOverlay(
      position: position,
      items: items,
      minWidth: minWidth,
      maxWidth: math.max(maxWidth, minWidth),
      onDismiss: dismiss,
    ),
  );
  overlay.insert(entry);
}

/// One open column in a cascading menu: its [items], the global [anchor] rect of
/// the parent row that opened it (null for the root, which floats at the
/// pointer) and the keyboard-highlighted row index (-1 = none).
class _MenuColumnData {
  _MenuColumnData({required this.items, required this.anchor})
    : key = GlobalKey<_CcMenuColumnState>();

  final List<CcMenuItem> items;
  final Rect? anchor;
  final GlobalKey<_CcMenuColumnState> key;
  int highlight = -1;
}

class _CcCascadeMenuOverlay extends StatefulWidget {
  const _CcCascadeMenuOverlay({
    required this.position,
    required this.items,
    required this.minWidth,
    required this.maxWidth,
    required this.onDismiss,
  });

  final Offset position;
  final List<CcMenuItem> items;
  final double minWidth;
  final double maxWidth;
  final VoidCallback onDismiss;

  @override
  State<_CcCascadeMenuOverlay> createState() => _CcCascadeMenuOverlayState();
}

class _CcCascadeMenuOverlayState extends State<_CcCascadeMenuOverlay> {
  final FocusNode _focus = FocusNode(debugLabel: 'CcMenu');

  // Grace timer for the diagonal-travel problem: when the pointer leaves a
  // submenu-parent row onto a sibling leaf, don't close the flyout instantly —
  // give a beat to reach the flyout diagonally.
  Timer? _closeTimer;

  late List<_MenuColumnData> _columns = [
    _MenuColumnData(items: widget.items, anchor: null),
  ];

  int get _active => _columns.length - 1;

  @override
  void dispose() {
    _closeTimer?.cancel();
    _focus.dispose();
    super.dispose();
  }

  // ── Column stack management ────────────────────────────────────────────────

  void _openSubmenu(int column, int row, Rect anchor) {
    final item = _columns[column].items[row];
    if (!item.hasChildren || !item.enabled) {
      return;
    }
    // Already open for this exact row → keep it (avoids flicker on re-hover).
    if (_columns.length > column + 1 &&
        _columns[column].highlight == row &&
        identical(_columns[column + 1].items, item.children)) {
      return;
    }
    setState(() {
      _columns[column].highlight = row;
      _columns = [
        ..._columns.sublist(0, column + 1),
        _MenuColumnData(items: item.children, anchor: anchor),
      ];
    });
  }

  void _truncateTo(int column) {
    if (_columns.length > column + 1) {
      setState(() => _columns = _columns.sublist(0, column + 1));
    }
  }

  void _hoverRow(int column, int row, Rect anchor) {
    _closeTimer?.cancel();
    final item = _columns[column].items[row];
    if (_columns[column].highlight != row) {
      setState(() => _columns[column].highlight = row);
    }
    if (item.hasChildren && item.enabled) {
      _openSubmenu(column, row, anchor);
    } else if (_columns.length > column + 1) {
      // A deeper flyout is open and the pointer moved onto a sibling leaf —
      // close it, but only after a short grace so a diagonal reach survives.
      _closeTimer = Timer(const Duration(milliseconds: 220), () {
        if (mounted) {
          _truncateTo(column);
        }
      });
    }
  }

  void _activateRow(int column, int row, Rect anchor) {
    final item = _columns[column].items[row];
    if (item.isDivider || item.isSection || !item.enabled) {
      return;
    }
    if (item.hasChildren) {
      _openSubmenu(column, row, anchor);
      _moveColumnHighlight(_active, 1); // land on the first row of the flyout
      return;
    }
    widget.onDismiss();
    item.onSelected();
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────

  void _moveColumnHighlight(int column, int delta) {
    final data = _columns[column];
    final next = _moveHighlight(data.items, data.highlight, delta);
    if (next != data.highlight) {
      setState(() => data.highlight = next);
    }
  }

  Rect? _rectOf(int column, int row) =>
      _columns[column].key.currentState?.rectOf(row);

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final column = _active;
    final data = _columns[column];

    if (key == LogicalKeyboardKey.escape) {
      if (column > 0) {
        _truncateTo(column - 1);
      } else {
        widget.onDismiss();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _moveColumnHighlight(column, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveColumnHighlight(column, -1);
      return KeyEventResult.handled;
    }
    // Horizontal arrows follow reading direction: the key pointing toward the
    // submenu's fly-out side (end) opens, the other steps back out.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final intoSubmenuKey = isRtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final outOfSubmenuKey = isRtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == intoSubmenuKey) {
      final row = data.highlight;
      if (row >= 0 && data.items[row].hasChildren) {
        final rect = _rectOf(column, row);
        if (rect != null) {
          _openSubmenu(column, row, rect);
          _moveColumnHighlight(_active, 1);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == outOfSubmenuKey) {
      if (column > 0) {
        _truncateTo(column - 1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final row = data.highlight;
      if (row >= 0) {
        final rect = _rectOf(column, row) ?? Rect.zero;
        _activateRow(column, row, rect);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // A raw OverlayEntry sits in the root overlay, outside any route's text
    // theme — the only ambient DefaultTextStyle there is WidgetsApp's error
    // fallback (48px, double yellow underline). Supply a complete design-system
    // base style, same discipline as showCcDialog.
    final theme = context.ccTheme;
    final t = theme?.tokens ?? DesignSystemTokens.light();
    final menuTextStyle = CcFonts.ui(
      family: theme?.fontFamily,
      textStyle: CcTypography.body.copyWith(
        color: t.textPrimary,
        decoration: TextDecoration.none,
      ),
    );

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Stack(
        children: [
          // Dismiss barrier. The interceptor keeps it (and the panels) above
          // any embedded iframe on web (no-op elsewhere).
          Positioned.fill(
            child: PointerInterceptor(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onDismiss,
                onSecondaryTap: widget.onDismiss,
              ),
            ),
          ),
          for (var c = 0; c < _columns.length; c++)
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: c == 0
                    ? _CcMenuAtLayoutDelegate(widget.position)
                    : _SubmenuLayoutDelegate(
                        _columns[c].anchor!,
                        Directionality.of(context),
                      ),
                child: PointerInterceptor(
                  child: DefaultTextStyle(
                    style: menuTextStyle,
                    child: _CcMenuColumn(
                      key: _columns[c].key,
                      items: _columns[c].items,
                      minWidth: widget.minWidth,
                      maxWidth: widget.maxWidth,
                      highlight: _columns[c].highlight,
                      onRowHover: (row, rect) => _hoverRow(c, row, rect),
                      onRowActivate: (row, rect) => _activateRow(c, row, rect),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One rendered column of menu rows (root panel or a flyout). Owns per-row keys
/// so it can report a row's global rect (to anchor a submenu / keyboard open).
class _CcMenuColumn extends StatefulWidget {
  const _CcMenuColumn({
    super.key,
    required this.items,
    required this.minWidth,
    required this.maxWidth,
    required this.highlight,
    required this.onRowHover,
    required this.onRowActivate,
  });

  final List<CcMenuItem> items;
  final double minWidth;
  final double maxWidth;
  final int highlight;
  final void Function(int row, Rect globalRect) onRowHover;
  final void Function(int row, Rect globalRect) onRowActivate;

  @override
  State<_CcMenuColumn> createState() => _CcMenuColumnState();
}

class _CcMenuColumnState extends State<_CcMenuColumn> {
  List<GlobalKey> _keys = const [];

  void _ensureKeys(int count) {
    if (_keys.length != count) {
      _keys = List.generate(count, (_) => GlobalKey());
    }
  }

  /// Global rect of row [i], or null if it isn't laid out yet.
  Rect? rectOf(int i) {
    if (i < 0 || i >= _keys.length) {
      return null;
    }
    final box = _keys[i].currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  List<Widget> _buildItemRuns(bool showCheckGutter) {
    final result = <Widget>[];
    var run = <int>[];

    void flush() {
      if (run.isEmpty) {
        return;
      }
      final indices = run;
      result.add(
        CcFluidHover(
          itemCount: indices.length,
          isItemDisabled: (localIndex) =>
              !widget.items[indices[localIndex]].enabled,
          onActiveIndexChanged: (localIndex) {
            if (localIndex == null) {
              return;
            }
            final row = indices[localIndex];
            final rect = rectOf(row);
            if (rect != null) {
              widget.onRowHover(row, rect);
            }
          },
          itemBuilder: (context, localIndex) {
            final row = indices[localIndex];
            return KeyedSubtree(
              key: _keys[row],
              child: _CcMenuRow(
                item: widget.items[row],
                showCheckGutter: showCheckGutter,
                highlighted: row == widget.highlight,
                focusable: false,
                onActivate: () =>
                    widget.onRowActivate(row, rectOf(row) ?? Rect.zero),
              ),
            );
          },
          layoutBuilder: (context, registered) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: registered,
          ),
        ),
      );
      run = <int>[];
    }

    for (var row = 0; row < widget.items.length; row++) {
      final item = widget.items[row];
      if (item.isDivider || item.isSection) {
        flush();
        result.add(
          item.isDivider
              ? const _CcMenuDivider()
              : _CcMenuSection(label: item.label),
        );
      } else {
        run.add(row);
      }
    }
    flush();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    _ensureKeys(widget.items.length);
    final showCheckGutter = widget.items.any((i) => i.selected);
    return _MenuSurface(
      minWidth: widget.minWidth,
      maxWidth: widget.maxWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: _buildItemRuns(showCheckGutter),
      ),
    );
  }
}

/// The floating panel chrome shared by every menu column: golden float, hairline
/// border, large radius; scrolls when taller than the viewport.
///
/// Two width modes. By default the panel shrink-wraps to its widest row (like
/// Material's PopupMenu) between [minWidth] and [maxWidth]. With
/// [definiteWidth] it takes [maxWidth] flat — what a searchable panel needs,
/// since shrink-wrapping would resize it on every keystroke as the result set
/// changes, and would let [header] and rows disagree about how wide they are.
class _MenuSurface extends StatelessWidget {
  const _MenuSurface({
    required this.minWidth,
    required this.maxWidth,
    required this.child,
    this.header,
    this.scrollController,
    this.definiteWidth = false,
  });

  final double minWidth;
  final double maxWidth;
  final Widget child;

  /// Pinned above the scrolling rows (a search field); scrolls with nothing.
  final Widget? header;

  final ScrollController? scrollController;
  final bool definiteWidth;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final card = CcCardTokens.panel(t);
    final scroller = SingleChildScrollView(
      controller: scrollController,
      // Shrink-wrap to the widest row's natural width instead of stretching to
      // the overlay's full width. At a definite width there is nothing to
      // shrink-wrap to and the extra layout pass is wasted.
      child: definiteWidth ? child : IntrinsicWidth(child: child),
    );
    return ConstrainedBox(
      constraints: definiteWidth
          ? BoxConstraints.tightFor(width: maxWidth)
          : BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card.bg,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: card.border),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: header == null
              ? scroller
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    header!,
                    Flexible(child: scroller),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Places the root panel at the pointer position, flipped/clamped to keep it
/// fully on screen with an 8px inset.
class _CcMenuAtLayoutDelegate extends SingleChildLayoutDelegate {
  const _CcMenuAtLayoutDelegate(this.position);

  final Offset position;

  static const double _inset = 8;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.deflate(const EdgeInsets.all(_inset)).loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final dx = position.dx.clamp(
      _inset,
      (size.width - childSize.width - _inset).clamp(_inset, size.width),
    );
    final dy = position.dy.clamp(
      _inset,
      (size.height - childSize.height - _inset).clamp(_inset, size.height),
    );
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_CcMenuAtLayoutDelegate oldDelegate) =>
      oldDelegate.position != position;
}

/// Places a flyout submenu on the END side of its parent row's [anchor] rect
/// (right in LTR, left in RTL), flipping to the start side when it would
/// overflow and clamped on screen.
class _SubmenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _SubmenuLayoutDelegate(this.anchor, this.textDirection);

  final Rect anchor;
  final TextDirection textDirection;

  static const double _inset = 8;
  static const double _overlap = 4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.deflate(const EdgeInsets.all(_inset)).loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Prefer opening toward the end side, slightly overlapping the parent's
    // edge; flip to the start side on overflow.
    double towardEnd() => anchor.right - _overlap;
    double towardStart() => anchor.left - childSize.width + _overlap;
    var dx = textDirection == TextDirection.rtl ? towardStart() : towardEnd();
    final overflows = textDirection == TextDirection.rtl
        ? dx < _inset
        : dx + childSize.width > size.width - _inset;
    if (overflows) {
      dx = textDirection == TextDirection.rtl ? towardEnd() : towardStart();
    }
    dx = dx.clamp(
      _inset,
      (size.width - childSize.width - _inset).clamp(_inset, size.width),
    );
    // Align the flyout's top with the parent row, then clamp on screen.
    final dy = (anchor.top - _overlap).clamp(
      _inset,
      (size.height - childSize.height - _inset).clamp(_inset, size.height),
    );
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_SubmenuLayoutDelegate oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.textDirection != textDirection;
}

/// The hairline separator rendered for a [CcMenuItem.divider].
class _CcMenuDivider extends StatelessWidget {
  const _CcMenuDivider({this.flush = false});

  /// Whether to drop the vertical breathing room — used under the search
  /// field, where the hairline IS the field's bottom edge.
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final line = SizedBox(
      height: 1,
      child: ColoredBox(color: t.borderSecondary),
    );
    return flush
        ? line
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: line,
          );
  }
}

/// The mono uppercase eyebrow rendered for a [CcMenuItem.section] — the same
/// treatment as `CcSidebarGroup`'s label, so a grouped menu reads as part of
/// the same system as the grouped sidebar.
class _CcMenuSection extends StatelessWidget {
  const _CcMenuSection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Padding(
      // Symmetric horizontals, so direction-neutral by construction.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CcFonts.code(
          textStyle: CcTypography.label,
          family: context.ccTheme?.monoFontFamily,
        ).copyWith(color: t.textTertiary),
      ),
    );
  }
}

/// The "nothing matched" row of a searchable menu.
class _CcMenuEmpty extends StatelessWidget {
  const _CcMenuEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Text(
        label,
        style: CcTypography.bodySm.copyWith(color: t.textTertiary),
      ),
    );
  }
}

class _CcMenuRow extends StatelessWidget {
  const _CcMenuRow({
    required this.item,
    required this.onActivate,
    this.showCheckGutter = false,
    this.highlighted = false,
    this.focusable = true,
  });

  final CcMenuItem item;
  final VoidCallback onActivate;

  /// Whether to reserve the leading check-mark gutter (any selectable sibling).
  final bool showCheckGutter;

  /// Whether this row is the keyboard-highlighted one.
  final bool highlighted;

  /// Whether the row participates in Tab focus traversal, or is driven purely
  /// by [highlighted] (keys handled upstream).
  final bool focusable;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = item.destructive ? t.danger : t.textPrimary;

    return CcTappable(
      onPressed: item.enabled ? onActivate : null,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: focusable,
      semanticLabel: item.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final focused = states.contains(WidgetState.focused);
        final disabled = states.contains(WidgetState.disabled);
        final fluidActive = CcFluidHover.isItemActive(context);
        final active = hovered || focused || highlighted;
        final wash = pressed
            ? t.hoverStrong
            : fluidActive
            ? const Color(0x00000000)
            : (active ? t.hover : const Color(0x00000000));
        final color = disabled ? t.textDisabled : fg;
        final checkColor = disabled ? t.textDisabled : t.accent;

        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(color: wash),
          // A 2px inset accent bar marks the keyboard-focused/highlighted row
          // (edge-to-edge menu items have no radius, so focus rides the edge).
          foregroundDecoration: (focused || highlighted) && !disabled
              ? BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: t.accent, width: 2),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (showCheckGutter) ...[
                  SizedBox(
                    width: 16,
                    child: item.selected
                        ? Icon(CcIcons.check, size: 14, color: checkColor)
                        : null,
                  ),
                  AppSpacing.hGapSm,
                ],
                if (item.leading case final leading?) ...[
                  leading(color),
                  AppSpacing.hGapSm,
                ] else if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: color),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: CcTruncatedText(
                    item.label,
                    style: CcTypography.bodySm.copyWith(color: color),
                  ),
                ),
                if (item.trailingChild != null) ...[
                  AppSpacing.hGapMd,
                  item.trailingChild!,
                ] else if (item.trailing != null) ...[
                  AppSpacing.hGapMd,
                  Text(
                    item.trailing!,
                    style: CcTypography.caption.copyWith(
                      color: disabled ? t.textDisabled : t.textTertiary,
                    ),
                  ),
                ],
                if (item.hasChildren) ...[
                  AppSpacing.hGapSm,
                  Icon(
                    CcIcons.chevronRight,
                    size: 14,
                    color: disabled ? t.textDisabled : t.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
