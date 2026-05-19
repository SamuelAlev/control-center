import 'dart:async';

import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
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

/// A compact filter dropdown: a trigger opening a panel of filter categories,
/// each disclosing a searchable checkbox flyout with per-option population
/// counts — the pattern for narrowing a large list (PR inboxes, tables) by
/// several dimensions from one unobtrusive button.
///
/// The root panel carries its own search field to jump to a category; each
/// flyout carries one to narrow its options. Hovering a category opens its
/// flyout beside the row (with a short grace when another flyout is already
/// open, so a diagonal reach survives); clicking, `→`, or `Enter` opens it
/// and moves focus into its search field. Toggling an option never closes
/// the menu, so several values compose in one open session. `Esc`/`←` step
/// back out of a flyout, `Esc` at the root closes the menu.
///
/// Like every off-Material overlay surface, the panels supply their own
/// complete [DefaultTextStyle] — root-overlay content would otherwise inherit
/// WidgetsApp's 48px error fallback.
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
    _portal.show();
  }

  void _closeMenu() {
    _switchTimer?.cancel();
    _portal.hide();
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
    var i = (_rootHighlight + delta) % n;
    if (i < 0) {
      i += n;
    }
    setState(() => _rootHighlight = i);
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
    if (key == LogicalKeyboardKey.arrowRight && !flyoutOpen) {
      _activateHighlightedCategory();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft && flyoutOpen) {
      _closeFlyout(refocusRoot: true);
      return KeyEventResult.handled;
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

    return FocusScope(
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
              Positioned.fill(
                child: PointerInterceptor(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _closeMenu,
                    onSecondaryTap: _closeMenu,
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
                    delegate: _FlyoutLayout(_flyoutAnchor!),
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
    return _FilterPanelSurface(
      width: 248,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelSearchField(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < categories.length; i++)
                    KeyedSubtree(
                      key: _categoryRowKeys.putIfAbsent(
                        categories[i].id,
                        GlobalKey.new,
                      ),
                      child: _CategoryRow(
                        category: categories[i],
                        highlighted: i == _rootHighlight,
                        open: categories[i].id == _openCategoryId,
                        onHover: () => _hoverCategory(i, categories[i].id),
                        onActivate: () =>
                            _openFlyout(categories[i].id, focusSearch: true),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Root panel rows
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.highlighted,
    required this.open,
    required this.onHover,
    required this.onActivate,
  });

  final CcFilterCategory category;
  final bool highlighted;
  final bool open;
  final VoidCallback onHover;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final selectedCount = category.selected.length;

    return MouseRegion(
      onEnter: (_) => onHover(),
      child: CcTappable(
        onPressed: onActivate,
        showFocusRing: false,
        canRequestFocus: false,
        semanticLabel: category.label,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          final active = hovered || highlighted || open;
          final wash = pressed
              ? t.hoverStrong
              : (active ? t.hover : _transparent);
          return Container(
            constraints: const BoxConstraints(minHeight: 40),
            alignment: Alignment.centerLeft,
            decoration: BoxDecoration(color: wash),
            // A 2px inset accent bar marks the keyboard-highlighted row
            // (edge-to-edge rows have no radius, so focus rides the edge).
            foregroundDecoration: highlighted
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
                  if (category.icon != null) ...[
                    Icon(category.icon, size: 16, color: t.textSecondary),
                    AppSpacing.hGapSm,
                  ],
                  Expanded(
                    child: CcTruncatedText(
                      category.label,
                      style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                    ),
                  ),
                  if (selectedCount > 0) ...[
                    AppSpacing.hGapSm,
                    Text(
                      '$selectedCount',
                      style: CcTypography.caption.copyWith(color: t.accent),
                    ),
                  ],
                  AppSpacing.hGapSm,
                  Icon(CcIcons.chevronRight, size: 14, color: t.textTertiary),
                ],
              ),
            ),
          );
        },
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
    var i = (_highlight + delta) % n;
    if (i < 0) {
      i += n;
    }
    setState(() => _highlight = i);
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    final options = _visibleOptions;
    final hidden = _hiddenCount;
    final footer = widget.category.hiddenCountLabel;

    return _FilterPanelSurface(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelSearchField(
            controller: _query,
            focusNode: _field,
            hintText: widget.searchHint,
            onChanged: (_) => setState(() => _highlight = -1),
          ),
          const _PanelDivider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (options.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Text(
                        widget.emptySearchLabel ?? 'No matches',
                        style: CcTypography.bodySm.copyWith(color: t.muted),
                      ),
                    )
                  else
                    for (var i = 0; i < options.length; i++)
                      _OptionRow(
                        option: options[i],
                        checked: widget.category.selected.contains(
                          options[i].value,
                        ),
                        highlighted: i == _highlight,
                        onToggle: () => _toggle(options[i]),
                      ),
                ],
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

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.checked,
    required this.highlighted,
    required this.onToggle,
  });

  final CcFilterOption option;
  final bool checked;
  final bool highlighted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return CcTappable(
      onPressed: onToggle,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: option.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final wash = pressed
            ? t.hoverStrong
            : (hovered || highlighted ? t.hover : _transparent);
        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: wash),
          foregroundDecoration: highlighted
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
                // The row is the tap target; the checkbox is a passive mirror
                // so its own gesture never competes with the row's tappable.
                IgnorePointer(
                  child: CcCheckbox(value: checked, onChanged: (_) {}),
                ),
                AppSpacing.hGapMd,
                if (option.leading != null) ...[
                  option.leading!,
                  AppSpacing.hGapSm,
                ] else if (option.icon != null) ...[
                  Icon(option.icon, size: 16, color: t.textSecondary),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: CcTruncatedText(
                    option.label,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
                AppSpacing.hGapMd,
                Text(
                  option.countLabel ?? '${option.count}',
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
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
    final t = context.designSystem ?? DesignSystemTokens.light();
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
    final t = context.designSystem ?? DesignSystemTokens.light();
    return SizedBox(height: 1, child: ColoredBox(color: t.borderSecondary));
  }
}

/// The borderless search field pinned at the top of a panel — an
/// [EditableText] with a placeholder, no box chrome (the panel's divider
/// below it is the only separation), and pointer selection wired the same
/// way as [CcTextField] (click-drag, double-click word select).
class _PanelSearchField extends StatefulWidget {
  const _PanelSearchField({
    required this.controller,
    required this.focusNode,
    this.hintText,
    this.autofocus = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final bool autofocus;
  final ValueChanged<String>? onChanged;

  @override
  State<_PanelSearchField> createState() => _PanelSearchFieldState();
}

class _PanelSearchFieldState extends State<_PanelSearchField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  late final TextSelectionGestureDetectorBuilder _selectionGestureBuilder =
      TextSelectionGestureDetectorBuilder(delegate: this);

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final input = CcInputTokens.resolve(t);
    final textStyle = DefaultTextStyle.of(
      context,
    ).style.merge(CcTypography.bodySm.copyWith(color: t.textPrimary));

    final editable = EditableText(
      key: editableTextKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      maxLines: 1,
      minLines: 1,
      keyboardType: TextInputType.text,
      onChanged: widget.onChanged,
      style: textStyle,
      cursorColor: input.cursor,
      backgroundCursorColor: input.placeholder,
      selectionColor: input.selection,
      // Desktop-first: no drag handles; pointer selection comes from the
      // gesture detector below, keyboard selection from default shortcuts.
      selectionControls: null,
      rendererIgnoresPointer: true,
      cursorOpacityAnimates: true,
    );

    return _selectionGestureBuilder.buildGestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Hint sits behind the editable text while empty.
            if (widget.hintText != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? Text(
                        widget.hintText!,
                        style: CcTypography.bodySm.copyWith(
                          color: input.placeholder,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
            editable,
          ],
        ),
      ),
    );
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

/// Places a flyout to the right of its category row's [anchor] rect, flipping
/// to the left when it would overflow, and clamped on screen — the same
/// geometry as a cascading menu's submenu.
class _FlyoutLayout extends SingleChildLayoutDelegate {
  const _FlyoutLayout(this.anchor);

  final Rect anchor;

  static const double _inset = 8;
  static const double _overlap = 4;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.deflate(const EdgeInsets.all(_inset)).loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    // Prefer opening rightward, slightly overlapping the panel's edge.
    var dx = anchor.right - _overlap;
    if (dx + childSize.width > size.width - _inset) {
      dx = anchor.left - childSize.width + _overlap; // flip to the left
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
      oldDelegate.anchor != anchor;
}
