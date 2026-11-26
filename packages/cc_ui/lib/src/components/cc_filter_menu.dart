import 'dart:async';

import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_focus_trap.dart';
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

part 'cc_filter_menu_rows.dart';

const Color _transparent = Color(0x00000000);

/// One selectable value inside a [CcFilterCategory] flyout — a checkbox row
/// with an optional avatar/icon and a right-aligned population count.
@immutable
class CcFilterOption {
  /// Creates a [CcFilterOption].
  const CcFilterOption({
    required this.value,
    required this.label,
    required this.count,
    this.countLabel,
    this.icon,
    this.leading,
    this.pinned = false,
  });

  /// The value toggled into the category's selection set.
  final String value;

  /// The row's text.
  final String label;

  /// How many items in the filtered population match this option. Options
  /// with a zero count are hidden from the list (and summarised by the
  /// category's footer) unless [pinned] or currently selected.
  final int count;

  /// Localized count text shown right-aligned (e.g. "3 pull requests").
  /// Falls back to the bare [count].
  final String? countLabel;

  /// Optional leading icon (an [IconData] from the bundled icon font —
  /// declare app glyphs via `tool/gen_icon_seams.py`; see [CcIcons]).
  final IconData? icon;

  /// Optional leading widget (e.g. an avatar); takes precedence over [icon].
  final Widget? leading;

  /// Pinned options render first and stay visible even at a zero [count]
  /// (e.g. a "Current user" row).
  final bool pinned;
}

/// One filter dimension listed in the [CcFilterMenu] root panel. Hovering or
/// activating its row opens a flyout of checkbox [options]; toggles mutate a
/// copy of [selected] and report it through [onChanged] without closing the
/// menu. An empty selection conventionally means "no filter".
@immutable
class CcFilterCategory {
  /// Creates a [CcFilterCategory].
  const CcFilterCategory({
    required this.id,
    required this.label,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.icon,
    this.searchHint,
    this.hiddenCountLabel,
  });

  /// Stable id (drives which flyout is open across rebuilds).
  final String id;

  /// The category row's text (e.g. "Author").
  final String label;

  /// Optional leading icon for the category row (also used by the footer).
  final IconData? icon;

  /// The category's selectable options.
  final List<CcFilterOption> options;

  /// The currently selected values.
  final Set<String> selected;

  /// Called with the next selection whenever an option row is toggled.
  final ValueChanged<Set<String>> onChanged;

  /// Placeholder for the flyout's search field; falls back to
  /// [CcFilterMenu.optionSearchHint].
  final String? searchHint;

  /// Builds the localized footer summarising how many zero-count options are
  /// hidden from the list (e.g. "105 options not matching any pull
  /// requests"). No footer is shown when null or when nothing is hidden.
  final String Function(int hidden)? hiddenCountLabel;
}

/// Compact multi-dimension filter: category panel + searchable checkbox
/// flyouts with counts. Hover/→/Enter opens flyout (grace for diagonal reach);
/// toggles keep the menu open; Esc/← step back. → and ← open and close only at
/// the caret's edge of the search text, so they still move the caret. Up/Down
/// and Enter drive the list; with an empty search, Home/End jump and Space
/// toggles. Opening moves focus in, Tab stays inside, closing returns it to
/// the trigger. Panels supply their own [DefaultTextStyle] (root overlay
/// otherwise gets WidgetsApp's 48px fallback).
class CcFilterMenu extends StatefulWidget {
  /// Creates a [CcFilterMenu].
  const CcFilterMenu({
    super.key,
    required this.target,
    required this.categories,
    this.searchHint,
    this.optionSearchHint,
    this.emptySearchLabel,
    this.semanticLabel,
  });

  /// The trigger widget the menu anchors to (kept inert — the menu wraps it
  /// in its own [CcTappable], so a real button underneath would swallow the
  /// toggle tap).
  final Widget target;

  /// The filter dimensions listed in the root panel.
  final List<CcFilterCategory> categories;

  /// Placeholder for the root panel's search field (e.g. "Add filter…").
  final String? searchHint;

  /// Default placeholder for the flyouts' search fields (e.g. "Filter…").
  final String? optionSearchHint;

  /// Localized text shown when a flyout search matches no option.
  final String? emptySearchLabel;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcFilterMenu> createState() => _CcFilterMenuState();
}

class _CcFilterMenuState extends State<CcFilterMenu> {
  final OverlayPortalController _portal = OverlayPortalController();
  final GlobalKey _targetKey = GlobalKey();
  final GlobalKey<_FlyoutPanelState> _flyoutKey =
      GlobalKey<_FlyoutPanelState>();
  final Map<String, GlobalKey> _categoryRowKeys = {};

  /// Keeps the arrow-key highlight inside the scrolled category list.
  final CcRowReveal _rows = CcRowReveal();

  final TextEditingController _rootQuery = TextEditingController();
  final FocusNode _rootField = FocusNode(debugLabel: 'CcFilterMenu.search');

  // Focus scope for the open menu: traps Tab within the panels instead of
  // leaking to the background.
  final FocusScopeNode _scope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );

  /// The category whose flyout is open, with the row rect (in the host
  /// overlay's coordinates) it anchors to.
  String? _openCategoryId;
  Rect? _flyoutAnchor;

  /// Keyboard highlight over the filtered category rows (-1 = none).
  int _rootHighlight = -1;

  // Grace timer for the diagonal-travel problem: hovering a sibling category
  // while a flyout is open switches the flyout only after a beat, so the
  // pointer can reach the open flyout diagonally without it vanishing.
  Timer? _switchTimer;

  // Bounds the post-frame retries used when the trigger geometry isn't laid
  // out yet on the frame the portal first shows.
  int _geometryRetries = 0;
  static const int _maxGeometryRetries = 5;

  @override
  void dispose() {
    _switchTimer?.cancel();
    _rootQuery.dispose();
    _rootField.dispose();
    _scope.dispose();
    super.dispose();
  }

  List<CcFilterCategory> get _filteredCategories {
    final q = _rootQuery.text.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.categories;
    }
    return [
      for (final c in widget.categories)
        if (c.label.toLowerCase().contains(q)) c,
    ];
  }

  CcFilterCategory? get _openCategory {
    for (final c in widget.categories) {
      if (c.id == _openCategoryId) {
        return c;
      }
    }
    return null;
  }

  void _toggleMenu() => _portal.isShowing ? _closeMenu() : _openMenu();

  void _openMenu() {
    _rootQuery.clear();
    _openCategoryId = null;
    _flyoutAnchor = null;
    _rootHighlight = -1;
    _geometryRetries = 0;
    // Rebuild the trigger so it reports itself expanded.
    setState(_portal.show);
  }

  void _closeMenu() {
    _switchTimer?.cancel();
    if (mounted) {
      setState(_portal.hide);
    } else {
      _portal.hide();
    }
  }

  void _onRootQueryChanged(String _) {
    setState(() {
      _rootHighlight = -1;
      // The open flyout's category may have been filtered away.
      if (_openCategoryId != null &&
          !_filteredCategories.any((c) => c.id == _openCategoryId)) {
        _closeFlyout();
      }
    });
  }

  // ── Flyout management ──────────────────────────────────────────────────────

  /// Resolves the category row's rect in the host overlay's coordinates so
  /// the flyout layout can anchor beside it.
  Rect? _rowRect(String categoryId) {
    final rowContext = _categoryRowKeys[categoryId]?.currentContext;
    if (rowContext == null || !rowContext.mounted) {
      return null;
    }
    final rowBox = rowContext.findRenderObject() as RenderBox?;
    final overlayBox =
        Overlay.of(rowContext, rootOverlay: false).context.findRenderObject()
            as RenderBox?;
    if (rowBox == null || overlayBox == null || !rowBox.hasSize) {
      return null;
    }
    final topLeft = rowBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & rowBox.size;
  }

  void _openFlyout(String categoryId, {bool focusSearch = false}) {
    _switchTimer?.cancel();
    final anchor = _rowRect(categoryId);
    if (anchor == null) {
      return;
    }
    setState(() {
      _openCategoryId = categoryId;
      _flyoutAnchor = anchor;
    });
    if (focusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _flyoutKey.currentState?.focusSearch();
        }
      });
    }
  }

  void _closeFlyout({bool refocusRoot = false}) {
    _switchTimer?.cancel();
    setState(() {
      _openCategoryId = null;
      _flyoutAnchor = null;
    });
    if (refocusRoot) {
      _rootField.requestFocus();
    }
  }

  void _hoverCategory(int index, String categoryId) {
    if (_rootHighlight != index) {
      setState(() => _rootHighlight = index);
    }
    if (_openCategoryId == categoryId) {
      _switchTimer?.cancel();
      return;
    }
    if (_openCategoryId == null) {
      _openFlyout(categoryId);
    } else {
      // Another flyout is open — switch after a grace so a diagonal reach
      // into the open flyout doesn't yank it away mid-travel.
      _switchTimer?.cancel();
      _switchTimer = Timer(const Duration(milliseconds: 120), () {
        if (mounted && _portal.isShowing) {
          _openFlyout(categoryId);
        }
      });
    }
  }

  /// Entering the open flyout commits to it — cancel any pending switch.
  void _cancelPendingSwitch() => _switchTimer?.cancel();

  // ── Keyboard ───────────────────────────────────────────────────────────────

  void _moveRootHighlight(int delta) {
    final n = _filteredCategories.length;
    if (n == 0) {
      return;
    }
    final previous = _rootHighlight;
    var i = (previous + delta) % n;
    if (i < 0) {
      i += n;
    }
    setState(() => _rootHighlight = i);
    _rows.reveal(i, from: previous);
  }

  void _setRootHighlight(int index) {
    if (index < 0 || index >= _filteredCategories.length) {
      return;
    }
    final previous = _rootHighlight;
    setState(() => _rootHighlight = index);
    _rows.reveal(index, from: previous);
  }

  /// The search text the caret is in: the flyout's when it has focus, else
  /// the root panel's.
  TextEditingValue get _focusedQuery {
    final flyout = _flyoutKey.currentState;
    if (flyout != null && flyout.searchHasFocus) {
      return flyout.query;
    }
    return _rootQuery.value;
  }

  void _activateHighlightedCategory() {
    final categories = _filteredCategories;
    if (_rootHighlight < 0 || _rootHighlight >= categories.length) {
      return;
    }
    _openFlyout(categories[_rootHighlight].id, focusSearch: true);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final flyoutOpen = _openCategoryId != null;

    if (key == LogicalKeyboardKey.escape) {
      if (flyoutOpen) {
        _closeFlyout(refocusRoot: true);
      } else {
        _closeMenu();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      final delta = key == LogicalKeyboardKey.arrowDown ? 1 : -1;
      if (flyoutOpen) {
        _flyoutKey.currentState?.moveHighlight(delta);
      } else {
        _moveRootHighlight(delta);
      }
      return KeyEventResult.handled;
    }
    // Horizontal arrows follow reading direction: the key pointing toward the
    // flyout's side (end) opens, the other steps back to the category list.
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final intoFlyoutKey = isRtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final outOfFlyoutKey = isRtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    // ← and → also move the caret: they leave the search text only from its
    // edge (or an empty field), the way a cascading menu inside a text box
    // behaves.
    final query = _focusedQuery;
    final caret = query.selection;
    final atStart =
        query.text.isEmpty ||
        (caret.isValid && caret.isCollapsed && caret.baseOffset == 0);
    final atEnd =
        query.text.isEmpty ||
        (caret.isValid &&
            caret.isCollapsed &&
            caret.baseOffset == query.text.length);
    if (key == intoFlyoutKey && !flyoutOpen && atEnd) {
      _activateHighlightedCategory();
      return KeyEventResult.handled;
    }
    if (key == outOfFlyoutKey && flyoutOpen && atStart) {
      _closeFlyout(refocusRoot: true);
      return KeyEventResult.handled;
    }
    // With nothing typed there is no caret to move and no word to space, so
    // Home/End and Space work the list.
    if (query.text.isEmpty) {
      if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
        final toEnd = key == LogicalKeyboardKey.end;
        final flyout = _flyoutKey.currentState;
        if (flyoutOpen && flyout != null) {
          flyout.highlightEdge(end: toEnd);
        } else {
          _setRootHighlight(toEnd ? _filteredCategories.length - 1 : 0);
        }
        return KeyEventResult.handled;
      }
      if (key == LogicalKeyboardKey.space && flyoutOpen) {
        _flyoutKey.currentState?.toggleHighlighted();
        return KeyEventResult.handled;
      }
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (flyoutOpen) {
        _flyoutKey.currentState?.toggleHighlighted();
      } else {
        _activateHighlightedCategory();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: _buildOverlay,
      child: KeyedSubtree(
        key: _targetKey,
        child: CcTappable(
          onPressed: _toggleMenu,
          semanticLabel: widget.semanticLabel,
          semanticExpanded: _portal.isShowing,
          builder: (context, states) => widget.target,
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    // Resolve the trigger's rect in the host overlay's coordinate space (same
    // discipline as CcOverlayAnchor, including the capped post-frame retry for
    // the first frame, when the trigger may not be laid out yet).
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final targetBox =
        _targetKey.currentContext?.findRenderObject() as RenderBox?;
    Rect? targetRect;
    if (overlayBox != null &&
        targetBox != null &&
        overlayBox.attached &&
        targetBox.attached &&
        targetBox.hasSize) {
      final topLeft = targetBox.localToGlobal(
        Offset.zero,
        ancestor: overlayBox,
      );
      targetRect = topLeft & targetBox.size;
      _geometryRetries = 0;
    } else if (_geometryRetries < _maxGeometryRetries) {
      _geometryRetries++;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _portal.isShowing) {
          setState(() {});
        }
      });
    }

    // Root-overlay content sits outside any route's text theme — supply a
    // complete design-system base style (same discipline as showCcDialog).
    final theme = context.ccTheme;
    final t = theme?.tokens ?? DesignSystemTokens.light();
    final baseStyle = CcFonts.ui(
      family: theme?.fontFamily,
      textStyle: CcTypography.body.copyWith(
        color: t.textPrimary,
        decoration: TextDecoration.none,
      ),
    );

    final openCategory = _openCategory;

    // The trigger keeps focus while the menu opens; the trap moves it to the
    // root search field (its autofocus) and returns it on close.
    return CcFocusTrap(
      node: _scope,
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: _onKey,
        child: DefaultTextStyle(
          style: baseStyle,
          child: Stack(
            children: [
              // Dismiss barrier. The interceptor keeps it (and the panels)
              // clickable over an embedded iframe on web (no-op elsewhere).
              // A screen reader gets the same close as a dismiss action.
              Positioned.fill(
                child: Semantics(
                  container: true,
                  label: context.ccStrings.dismiss,
                  onDismiss: _closeMenu,
                  child: PointerInterceptor(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _closeMenu,
                      onSecondaryTap: _closeMenu,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomSingleChildLayout(
                  delegate: _RootPanelLayout(targetRect),
                  child: PointerInterceptor(child: _buildRootPanel(context)),
                ),
              ),
              if (openCategory != null && _flyoutAnchor != null)
                Positioned.fill(
                  child: CustomSingleChildLayout(
                    delegate: _FlyoutLayout(
                      _flyoutAnchor!,
                      Directionality.of(context),
                    ),
                    child: PointerInterceptor(
                      child: MouseRegion(
                        onEnter: (_) => _cancelPendingSwitch(),
                        child: _FlyoutPanel(
                          key: _flyoutKey,
                          category: openCategory,
                          searchHint:
                              openCategory.searchHint ??
                              widget.optionSearchHint,
                          emptySearchLabel: widget.emptySearchLabel,
                        ),
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

  Widget _buildRootPanel(BuildContext context) {
    final categories = _filteredCategories;
    _rows.resize(categories.length);
    return _FilterPanelSurface(
      width: 248,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcPanelSearchField(
            controller: _rootQuery,
            focusNode: _rootField,
            hintText: widget.searchHint,
            autofocus: true,
            onChanged: _onRootQueryChanged,
          ),
          const _PanelDivider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: CcFluidHover(
                itemCount: categories.length,
                onActiveIndexChanged: (index) {
                  if (index != null) {
                    _hoverCategory(index, categories[index].id);
                  }
                },
                itemBuilder: (context, i) => KeyedSubtree(
                  key: _rows.keyAt(i),
                  child: KeyedSubtree(
                    key: _categoryRowKeys.putIfAbsent(
                      categories[i].id,
                      GlobalKey.new,
                    ),
                    child: _CategoryRow(
                      category: categories[i],
                      highlighted: i == _rootHighlight,
                      open: categories[i].id == _openCategoryId,
                      onActivate: () =>
                          _openFlyout(categories[i].id, focusSearch: true),
                    ),
                  ),
                ),
                layoutBuilder: (context, items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: items,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flyout
// ─────────────────────────────────────────────────────────────────────────────

class _FlyoutPanel extends StatefulWidget {
  const _FlyoutPanel({
    super.key,
    required this.category,
    required this.searchHint,
    required this.emptySearchLabel,
  });

  final CcFilterCategory category;
  final String? searchHint;
  final String? emptySearchLabel;

  @override
  State<_FlyoutPanel> createState() => _FlyoutPanelState();
}

class _FlyoutPanelState extends State<_FlyoutPanel> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _field = FocusNode(debugLabel: 'CcFilterMenu.flyoutSearch');

  /// Keeps the arrow-key highlight inside the scrolled option list.
  final CcRowReveal _rows = CcRowReveal();

  /// Keyboard highlight over the visible options (-1 = none).
  int _highlight = -1;

  @override
  void didUpdateWidget(_FlyoutPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category.id != widget.category.id) {
      // Hover switched the flyout to another category — this panel now shows
      // a different option list; stale search/highlight would mislead.
      _query.clear();
      _highlight = -1;
    }
  }

  @override
  void dispose() {
    _query.dispose();
    _field.dispose();
    super.dispose();
  }

  /// Focuses the flyout's search field (explicit activation — click, `→`,
  /// `Enter`; hover-open deliberately leaves focus in the root field).
  void focusSearch() => _field.requestFocus();

  /// Whether the caret is in this flyout's search field.
  bool get searchHasFocus => _field.hasFocus;

  /// The flyout's search text and caret.
  TextEditingValue get query => _query.value;

  /// Highlights the first or last visible option.
  void highlightEdge({required bool end}) {
    final n = _visibleOptions.length;
    if (n == 0) {
      return;
    }
    final previous = _highlight;
    final i = end ? n - 1 : 0;
    setState(() => _highlight = i);
    _rows.reveal(i, from: previous);
  }

  /// The options shown: pinned first, then the rest in the given order.
  /// Zero-count options are hidden (summarised by the footer) unless pinned
  /// or currently selected; the search query narrows by label.
  List<CcFilterOption> get _visibleOptions {
    final q = _query.text.trim().toLowerCase();
    final pinned = <CcFilterOption>[];
    final rest = <CcFilterOption>[];
    for (final option in widget.category.options) {
      final selected = widget.category.selected.contains(option.value);
      if (option.count == 0 && !selected && !option.pinned) {
        continue;
      }
      if (q.isNotEmpty && !option.label.toLowerCase().contains(q)) {
        continue;
      }
      (option.pinned ? pinned : rest).add(option);
    }
    return [...pinned, ...rest];
  }

  int get _hiddenCount => widget.category.options
      .where(
        (o) =>
            o.count == 0 &&
            !o.pinned &&
            !widget.category.selected.contains(o.value),
      )
      .length;

  void _toggle(CcFilterOption option) {
    final next = Set<String>.of(widget.category.selected);
    if (!next.add(option.value)) {
      next.remove(option.value);
    }
    widget.category.onChanged(next);
  }

  /// Moves the keyboard highlight by [delta] (wraps around).
  void moveHighlight(int delta) {
    final n = _visibleOptions.length;
    if (n == 0) {
      return;
    }
    final previous = _highlight;
    var i = (previous + delta) % n;
    if (i < 0) {
      i += n;
    }
    setState(() => _highlight = i);
    _rows.reveal(i, from: previous);
  }

  /// Toggles the keyboard-highlighted option, if any.
  void toggleHighlighted() {
    final options = _visibleOptions;
    if (_highlight >= 0 && _highlight < options.length) {
      _toggle(options[_highlight]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final options = _visibleOptions;
    _rows.resize(options.length);
    final hidden = _hiddenCount;
    final footer = widget.category.hiddenCountLabel;

    return _FilterPanelSurface(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CcPanelSearchField(
            controller: _query,
            focusNode: _field,
            hintText: widget.searchHint,
            onChanged: (_) => setState(() => _highlight = -1),
          ),
          const _PanelDivider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: options.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        widget.emptySearchLabel ?? context.ccStrings.noMatches,
                        style: CcTypography.bodySm.copyWith(color: t.muted),
                      ),
                    )
                  : CcFluidHover(
                      itemCount: options.length,
                      onActiveIndexChanged: (index) {
                        if (index != null && _highlight != index) {
                          setState(() => _highlight = index);
                        }
                      },
                      itemBuilder: (context, i) => KeyedSubtree(
                        key: _rows.keyAt(i),
                        child: _OptionRow(
                          option: options[i],
                          checked: widget.category.selected.contains(
                            options[i].value,
                          ),
                          highlighted: i == _highlight,
                          onToggle: () => _toggle(options[i]),
                        ),
                      ),
                      layoutBuilder: (context, items) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: items,
                      ),
                    ),
            ),
          ),
          if (footer != null && hidden > 0) ...[
            const _PanelDivider(),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + AppSpacing.xxs,
              ),
              child: Row(
                children: [
                  if (widget.category.icon != null) ...[
                    Icon(widget.category.icon, size: 16, color: t.muted),
                    AppSpacing.hGapSm,
                  ],
                  Expanded(
                    child: Text(
                      footer(hidden),
                      style: CcTypography.caption.copyWith(color: t.muted),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared panel chrome
// ─────────────────────────────────────────────────────────────────────────────

/// The floating panel chrome shared by the root panel and flyouts: golden
/// float, hairline border, large radius, fixed [width].
class _FilterPanelSurface extends StatelessWidget {
  const _FilterPanelSurface({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final card = CcCardTokens.panel(t);
    return SizedBox(
      width: width,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card.bg,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: card.border),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(borderRadius: AppRadii.brLg, child: child),
      ),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return SizedBox(height: 1, child: ColoredBox(color: t.borderSecondary));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Layout delegates
// ─────────────────────────────────────────────────────────────────────────────

/// Places the root panel under the trigger's bottom-left corner, flipping
/// above when below lacks room, clamped fully on screen with an 8px inset.
/// A null [targetRect] (trigger not laid out on the first frame) parks the
/// panel at the top-left inset for one frame.
class _RootPanelLayout extends SingleChildLayoutDelegate {
  const _RootPanelLayout(this.targetRect);

  final Rect? targetRect;

  static const double _inset = 8;
  static const double _gap = 6;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.deflate(const EdgeInsets.all(_inset)).loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final target = targetRect;
    if (target == null) {
      return const Offset(_inset, _inset);
    }
    var dy = target.bottom + _gap;
    if (dy + childSize.height > size.height - _inset &&
        target.top - _gap - childSize.height >= _inset) {
      dy = target.top - _gap - childSize.height; // flip above
    }
    final dx = target.left.clamp(
      _inset,
      (size.width - childSize.width - _inset).clamp(_inset, size.width),
    );
    dy = dy.clamp(
      _inset,
      (size.height - childSize.height - _inset).clamp(_inset, size.height),
    );
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_RootPanelLayout oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}

/// Places a flyout on the END side of its category row's [anchor] rect (right
/// in LTR, left in RTL), flipping to the start side when it would overflow and
/// clamped on screen — the same geometry as a cascading menu's submenu.
class _FlyoutLayout extends SingleChildLayoutDelegate {
  const _FlyoutLayout(this.anchor, this.textDirection);

  final Rect anchor;
  final TextDirection textDirection;

  static const double _inset = 8;
  static const double _overlap = 4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.deflate(const EdgeInsets.all(_inset)).loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Prefer opening toward the end side, slightly overlapping the panel's
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
    // Align the flyout's top with the row, then clamp on screen.
    final dy = (anchor.top - _overlap).clamp(
      _inset,
      (size.height - childSize.height - _inset).clamp(_inset, size.height),
    );
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_FlyoutLayout oldDelegate) =>
      oldDelegate.anchor != anchor ||
      oldDelegate.textDirection != textDirection;
}
