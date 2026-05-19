import 'dart:async';
import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
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

/// A single row in a [CcMenu] — an action, a single/multi-select option, a
/// submenu, or a divider.
///
/// Keep labels short verbs describing the action and don't repeat the menu
/// trigger's shared action in every row (a "Move to" menu lists targets, not
/// "Move to X" / "Move to Y"). Place destructive rows ([destructive]) last,
/// separated from the safe actions by a [CcMenuItem.divider].
///
/// Modifiers:
/// * [selected] draws a leading check mark (single- or multi-select). When any
///   sibling is selectable the whole column reserves the check gutter so
///   selected and unselected rows stay left-aligned.
/// * [trailing] shows a right-aligned keyboard-shortcut hint (e.g. `⌘W`). Only
///   set it for a shortcut that is actually bound — a hint for a dead shortcut
///   is a broken affordance.
/// * [CcMenuItem.submenu] nests a flyout of [children] behind a caret. Avoid
///   more than one nesting level and omit a term shared by every child from
///   the child labels (a "Split" submenu lists "Up"/"Down", not "Split up").
///   Submenus render only in the pointer-anchored [showCcMenuAt]; a flat
///   [CcMenu] dropdown does not open them.
@immutable
class CcMenuItem {
  /// Creates an action / selectable [CcMenuItem].
  const CcMenuItem({
    required this.label,
    required this.onSelected,
    this.icon,
    this.trailing,
    this.selected = false,
    this.destructive = false,
    this.enabled = true,
  }) : isDivider = false,
       children = const [];

  /// Creates a row that opens a flyout of [children] (a nested menu).
  const CcMenuItem.submenu({
    required this.label,
    required this.children,
    this.icon,
    this.enabled = true,
  }) : onSelected = _noop,
       trailing = null,
       selected = false,
       destructive = false,
       isDivider = false;

  /// A non-interactive separator row — use it to set the destructive group
  /// apart at the end of the menu, or to group related actions.
  const CcMenuItem.divider()
    : label = '',
      onSelected = _noop,
      icon = null,
      trailing = null,
      selected = false,
      destructive = false,
      enabled = false,
      isDivider = true,
      children = const [];

  static void _noop() {}

  /// The row's text.
  final String label;

  /// Invoked when the row is selected (the menu closes first).
  final VoidCallback onSelected;

  /// Optional leading icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see [CcIcons]).
  final IconData? icon;

  /// Optional right-aligned keyboard-shortcut hint (e.g. `⌘W`). Purely visual.
  final String? trailing;

  /// Whether this row is selected — draws a leading check mark.
  final bool selected;

  /// Whether this is a destructive action — rendered in the danger color.
  final bool destructive;

  /// Whether the row can be selected.
  final bool enabled;

  /// Whether this entry renders as a hairline separator instead of a row.
  final bool isDivider;

  /// Child rows shown in a flyout submenu; empty for a leaf row.
  final List<CcMenuItem> children;

  /// Whether this row opens a submenu.
  bool get hasChildren => children.isNotEmpty;
}

/// A flat dropdown menu — the cc_ui replacement for Material's
/// `PopupMenuButton`.
///
/// Tapping [target] opens a floating panel (golden float, hairline border,
/// large radius) listing [items] as flat [CcTappable] rows with a hover wash.
/// Destructive rows render their label and icon in `t.danger`. Selecting a row
/// closes the menu, then calls the item's `onSelected`.
///
/// This anchored dropdown is intentionally flat — it renders [CcMenuItem.icon],
/// [CcMenuItem.selected] (check gutter) and [CcMenuItem.trailing], but does NOT
/// open [CcMenuItem.submenu] flyouts. Use [showCcMenuAt] (right-click / context
/// menus) when you need cascading submenus.
///
/// Trigger guidance: the [target] must telegraph that it opens a list — a
/// labeled button carries a trailing caret ([CcButton.trailing] with a
/// chevron), an overflow trigger is the ellipsis icon button. The panel is
/// never narrower than its trigger and grows with long labels up to
/// [maxWidth], where rows truncate with a tooltip instead of wrapping.
class CcMenu extends StatefulWidget {
  /// Creates a [CcMenu].
  const CcMenu({
    super.key,
    required this.target,
    required this.items,
    this.targetAnchor = Alignment.bottomLeft,
    this.followerAnchor = Alignment.topLeft,
    this.offset = const Offset(0, 6),
    this.minWidth = 180,
    this.maxWidth = 320,
    this.semanticLabel,
  });

  /// The trigger widget the menu anchors to.
  final Widget target;

  /// The menu rows.
  final List<CcMenuItem> items;

  /// Point on the target the panel aligns to.
  final Alignment targetAnchor;

  /// Point on the panel aligned to [targetAnchor].
  final Alignment followerAnchor;

  /// Extra offset applied to the panel.
  final Offset offset;

  /// Minimum width of the menu panel. The open panel is additionally floored
  /// to the trigger's width so it never reads narrower than its button.
  final double minWidth;

  /// Maximum width of the menu panel; longer row labels truncate with an
  /// ellipsis and disclose their full text in a tooltip.
  final double maxWidth;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcMenu> createState() => _CcMenuState();
}

class _CcMenuState extends State<CcMenu> {
  final CcOverlayController _controller = CcOverlayController();

  // Focus scope for the open menu: autofocus lands focus on the first row (so
  // keyboard Escape works) and `closedLoop` traps Tab/Shift-Tab within the
  // menu instead of leaking to the background.
  final FocusScopeNode _panelScope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  @override
  void dispose() {
    _controller.dispose();
    _panelScope.dispose();
    super.dispose();
  }

  void _select(CcMenuItem item) {
    _controller.hide();
    item.onSelected();
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      targetAnchor: widget.targetAnchor,
      followerAnchor: widget.followerAnchor,
      offset: widget.offset,
      target: CcTappable(
        onPressed: _controller.toggle,
        semanticLabel: widget.semanticLabel,
        builder: (context, states) => widget.target,
      ),
      overlayBuilder: _buildPanel,
      // The menu often floats over the IDE's embedded editor/browser iframe;
      // shield it so its rows stay clickable there (no-op off-web).
      interceptPointer: true,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    // Never render the panel narrower than its trigger; when the trigger is
    // wider than the cap, matching the trigger wins.
    final minWidth = math.max(widget.minWidth, targetSize?.width ?? 0);
    final maxWidth = math.max(widget.maxWidth, minWidth);
    final showCheckGutter = widget.items.any((i) => i.selected);
    return FocusScope(
      node: _panelScope,
      autofocus: true,
      child: _MenuSurface(
        minWidth: minWidth,
        maxWidth: maxWidth,
        // Edge-to-edge rows: no panel padding, so the hover wash and the row
        // divider run the full width of the menu.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in widget.items)
              if (item.isDivider)
                const _CcMenuDivider()
              else
                _CcMenuRow(
                  item: item,
                  showCheckGutter: showCheckGutter,
                  onActivate: () => _select(item),
                ),
          ],
        ),
      ),
    );
  }
}

/// Shows a cascading [CcMenu]-style floating panel at [position] (global
/// coordinates) — the cc_ui replacement for Material's `showMenu`, for
/// right-click context menus. Supports [CcMenuItem.submenu] flyouts,
/// [CcMenuItem.selected] check marks and [CcMenuItem.trailing] shortcut hints.
///
/// Selecting a row closes the menu first, then calls its `onSelected`; clicking
/// away, right-clicking away, or pressing Escape dismisses it. Keyboard: up/down
/// move the highlight, right/Enter open a submenu, left/Escape step back out.
void showCcMenuAt({
  required BuildContext context,
  required Offset position,
  required List<CcMenuItem> items,
  double minWidth = 180,
  double maxWidth = 320,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  void dismiss() {
    if (entry.mounted) {
      entry.remove();
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
    if (item.isDivider || !item.enabled) {
      return;
    }
    if (item.hasChildren) {
      _openSubmenu(column, row, anchor);
      _moveHighlight(_active, 1); // land on the first row of the flyout
      return;
    }
    widget.onDismiss();
    item.onSelected();
  }

  // ── Keyboard ───────────────────────────────────────────────────────────────

  void _moveHighlight(int column, int delta) {
    final items = _columns[column].items;
    final n = items.length;
    if (n == 0) {
      return;
    }
    var i = _columns[column].highlight;
    for (var step = 0; step < n; step++) {
      i = (i + delta) % n;
      if (i < 0) {
        i += n;
      }
      final item = items[i];
      if (!item.isDivider && item.enabled) {
        setState(() => _columns[column].highlight = i);
        return;
      }
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
      _moveHighlight(column, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _moveHighlight(column, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      final row = data.highlight;
      if (row >= 0 && data.items[row].hasChildren) {
        final rect = _rectOf(column, row);
        if (rect != null) {
          _openSubmenu(column, row, rect);
          _moveHighlight(_active, 1);
        }
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
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
                    : _SubmenuLayoutDelegate(_columns[c].anchor!),
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
        children: [
          for (var i = 0; i < widget.items.length; i++)
            if (widget.items[i].isDivider)
              const _CcMenuDivider()
            else
              KeyedSubtree(
                key: _keys[i],
                child: _CcMenuRow(
                  item: widget.items[i],
                  showCheckGutter: showCheckGutter,
                  highlighted: i == widget.highlight,
                  focusable: false,
                  onHover: () {
                    final rect = rectOf(i);
                    if (rect != null) {
                      widget.onRowHover(i, rect);
                    }
                  },
                  onActivate: () =>
                      widget.onRowActivate(i, rectOf(i) ?? Rect.zero),
                ),
              ),
        ],
      ),
    );
  }
}

/// The floating panel chrome shared by every menu column: golden float, hairline
/// border, large radius; scrolls when taller than the viewport and shrink-wraps
/// to the widest row otherwise.
class _MenuSurface extends StatelessWidget {
  const _MenuSurface({
    required this.minWidth,
    required this.maxWidth,
    required this.child,
  });

  final double minWidth;
  final double maxWidth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final card = CcCardTokens.panel(t);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card.bg,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: card.border),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          child: SingleChildScrollView(
            // Shrink-wrap to the widest row's natural width (like Material's
            // PopupMenu) instead of stretching to the overlay's full width.
            child: IntrinsicWidth(child: child),
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

/// Places a flyout submenu to the right of its parent row's [anchor] rect,
/// flipping to the left when it would overflow and clamped on screen.
class _SubmenuLayoutDelegate extends SingleChildLayoutDelegate {
  const _SubmenuLayoutDelegate(this.anchor);

  final Rect anchor;

  static const double _inset = 8;
  static const double _overlap = 4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.deflate(const EdgeInsets.all(_inset)).loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Prefer opening rightward, slightly overlapping the parent's edge.
    var dx = anchor.right - _overlap;
    if (dx + childSize.width > size.width - _inset) {
      dx = anchor.left - childSize.width + _overlap; // flip to the left
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
      oldDelegate.anchor != anchor;
}

/// The hairline separator rendered for a [CcMenuItem.divider].
class _CcMenuDivider extends StatelessWidget {
  const _CcMenuDivider();

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SizedBox(height: 1, child: ColoredBox(color: t.borderSecondary)),
    );
  }
}

class _CcMenuRow extends StatelessWidget {
  const _CcMenuRow({
    required this.item,
    required this.onActivate,
    this.onHover,
    this.showCheckGutter = false,
    this.highlighted = false,
    this.focusable = true,
  });

  final CcMenuItem item;
  final VoidCallback onActivate;

  /// Fired when the pointer enters the row (drives submenu open + highlight in
  /// the cascading overlay). Null in the flat dropdown.
  final VoidCallback? onHover;

  /// Whether to reserve the leading check-mark gutter (any selectable sibling).
  final bool showCheckGutter;

  /// Whether this row is the keyboard-highlighted one (cascading overlay).
  final bool highlighted;

  /// Whether the row participates in Tab focus traversal (flat dropdown) or is
  /// driven purely by [highlighted] (cascading overlay, keys handled upstream).
  final bool focusable;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = item.destructive ? t.danger : t.textPrimary;

    final row = CcTappable(
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
        final active = hovered || focused || highlighted;
        final wash = pressed
            ? t.hoverStrong
            : (active ? t.hover : const Color(0x00000000));
        final color = disabled ? t.textDisabled : fg;
        final checkColor = disabled ? t.textDisabled : t.accent;

        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: wash),
          // A 2px inset accent bar marks the keyboard-focused/highlighted row
          // (edge-to-edge menu items have no radius, so focus rides the edge).
          foregroundDecoration: (focused || highlighted) && !disabled
              ? BoxDecoration(
                  border: Border(left: BorderSide(color: t.accent, width: 2)),
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
                if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: color),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: CcTruncatedText(
                    item.label,
                    style: CcTypography.bodySm.copyWith(color: color),
                  ),
                ),
                if (item.trailing != null) ...[
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

    if (onHover == null) {
      return row;
    }
    return MouseRegion(onEnter: (_) => onHover!(), child: row);
  }
}
