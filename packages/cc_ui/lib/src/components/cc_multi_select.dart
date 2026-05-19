import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_select.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_row_reveal.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// Natural height of a multi-select option row (32px checkbox target plus
/// 16px of vertical padding).
const double _kOptionRowHeight = 48;

/// Lists this long scroll instead of growing: the panel caps at 5.5 rows so
/// the half-visible last row signals there is more below.
const int _kScrollsFromOption = 6;

/// A flat multi-select dropdown — like [CcSelect] but with per-row checkboxes
/// and a [Set] of selected values.
///
/// The trigger renders the same input-styled box as [CcSelect]; instead of a
/// single label it summarises the selection — a small count tag (`"3 selected"`,
/// built by [countLabel]) carrying a ✕ that clears the whole selection without
/// opening the panel (hovering the ✕ shows a "Clear all" tooltip), followed by
/// the persistent [hintText]. With [showChips] set, each selected label
/// renders as its own dismissible chip instead. The panel lists every option
/// as a [CcTappable] row carrying a [CcCheckbox]; toggling a row mutates the
/// set and calls [onChanged] **without closing** the panel, so several values
/// can be toggled in one open session. When the panel reopens, the selected
/// options rise to the top of the list (in alphanumeric order); the order
/// stays frozen while the panel is open so rows never jump under the pointer.
///
/// With [filterable] set, hovering the field shows a text cursor and the open
/// field takes typed input that narrows the list — options matching the query
/// stay, the rest are temporarily removed — and a ✕ beside the typed text
/// clears just the filter (never the selection). The menu still stays open
/// while options are toggled; it closes on Escape, on clicking outside, or on
/// tabbing away.
///
/// Keyboard: the panel traps focus (`closedLoop`); `↑`/`↓` move a highlight,
/// `Space` toggles the highlighted row and `Esc` closes. While the filter
/// field holds focus, `Space` types a space and `Enter` toggles the
/// highlighted row instead. Provide [selectAllLabel] to pin a parent
/// select-all checkbox at the top of the panel — name it after the noun
/// ("All", "All roles"), never an action verb, since its own checkbox state
/// already says what a tap does. Without it, a "Clear all" row appears while
/// any value is selected.
class CcMultiSelect<T> extends StatefulWidget {
  /// Creates a [CcMultiSelect].
  const CcMultiSelect({
    super.key,
    required this.options,
    required this.values,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.showChips = false,
    this.filterable = false,
    this.countLabel,
    this.selectAllLabel,
    this.chevronIcon = CcIcons.chevronDown,
    this.semanticLabel,
  });

  /// The selectable options.
  final List<CcSelectOption<T>> options;

  /// The currently selected values.
  final Set<T> values;

  /// Called with the next selection whenever a row is toggled.
  final ValueChanged<Set<T>> onChanged;

  /// Placeholder shown when nothing is selected.
  final String? hintText;

  /// Whether the control is interactive.
  final bool enabled;

  /// Show selected labels as chips in the trigger instead of a count.
  final bool showChips;

  /// When true the open field takes typed input that narrows the option list
  /// (case-insensitive substring on the label); a ✕ beside the typed text
  /// clears the filter without touching the selection.
  final bool filterable;

  /// Builds the summary text from the count when [showChips] is false.
  /// Defaults to `"<n> selected"`.
  final String Function(int count)? countLabel;

  /// When non-null, pins a parent select-all checkbox row with this label at
  /// the top of the panel: unchecked selects every option, checked or
  /// indeterminate clears the selection. Describe the set ("All", "All
  /// roles"), not an action.
  final String? selectAllLabel;

  /// Trailing chevron icon (rotates when open).
  final IconData chevronIcon;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcMultiSelect<T>> createState() => _CcMultiSelectState<T>();
}

class _CcMultiSelectState<T> extends State<CcMultiSelect<T>> {
  final CcOverlayController _controller = CcOverlayController();
  final FocusScopeNode _panelScope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  final TextEditingController _filterText = TextEditingController();
  final FocusNode _filterFocus = FocusNode(debugLabel: 'CcMultiSelect filter');

  /// Shared tap-region group for the filterable field and the panel: a tap on
  /// an option row must not read as "outside" the filter's EditableText and
  /// blur it mid-filtering.
  final Object _tapGroup = Object();

  /// Keeps the arrow-key highlight inside the scrolled viewport.
  final CcRowReveal _rows = CcRowReveal();

  int? _highlighted;

  /// The selection captured when the panel opened — pins those options to the
  /// top of the list for this open session. Null while closed.
  Set<T>? _openSelection;

  @override
  void initState() {
    super.initState();
    // Rebuild on open/close so the trigger's focused border and chevron
    // rotation reflect the controller state — isOpen is captured at build time.
    _controller.addListener(_onOpenChanged);
    // Rebuild so the panel reflects the filtered list and the trigger shows
    // the clear-filter ✕ once text is present.
    _filterText.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onOpenChanged);
    _controller.dispose();
    _panelScope.dispose();
    _filterText.dispose();
    _filterFocus.dispose();
    super.dispose();
  }

  void _onOpenChanged() {
    if (!mounted) return;
    setState(() {
      // Reset highlight when the panel reopens/closes.
      _highlighted = null;
      // Snapshot the selection at open so the selected options rise to the
      // top of the list on (re)open, but the order stays frozen while the
      // panel is open — toggling a row must never move it under the pointer.
      _openSelection = _controller.isOpen ? Set<T>.of(widget.values) : null;
      // A closed filterable field starts the next session unfiltered.
      if (!_controller.isOpen) {
        _filterText.clear();
      }
    });
    if (_controller.isOpen && widget.filterable) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isOpen) {
          _filterFocus.requestFocus();
        }
      });
    }
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() => _highlighted = null);
    }
  }

  /// The options in display order: while the panel is open, the options that
  /// were selected when it opened come first (alphanumeric by label), the
  /// rest keep their given order.
  List<CcSelectOption<T>> get _displayOptions {
    final pinnedTo = _openSelection;
    if (pinnedTo == null || pinnedTo.isEmpty) {
      return widget.options;
    }
    final pinned = <CcSelectOption<T>>[];
    final rest = <CcSelectOption<T>>[];
    for (final option in widget.options) {
      (pinnedTo.contains(option.value) ? pinned : rest).add(option);
    }
    pinned.sort(
      (a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()),
    );
    return [...pinned, ...rest];
  }

  /// The options in list order: [_displayOptions] narrowed by the typed
  /// filter when one is active (matching options stay, the rest are
  /// temporarily removed).
  List<CcSelectOption<T>> get _listOptions {
    final query = _filterText.text.trim().toLowerCase();
    if (query.isEmpty) {
      return _displayOptions;
    }
    return _displayOptions
        .where((o) => o.label.toLowerCase().contains(query))
        .toList(growable: false);
  }

  void _clearFilter() {
    _filterText.clear();
    _filterFocus.requestFocus();
  }

  void _toggle() {
    if (widget.enabled) {
      _controller.toggle();
    }
  }

  /// Filterable fields never toggle closed on tap: a tap opens the panel (or
  /// keeps it open) and puts the caret in the field so typing can start.
  void _onFieldTap() {
    if (!widget.enabled) {
      return;
    }
    if (!_controller.isOpen) {
      _controller.show();
    }
    _filterFocus.requestFocus();
  }

  void _toggleOption(CcSelectOption<T> option) {
    final next = Set<T>.of(widget.values);
    if (!next.add(option.value)) {
      next.remove(option.value);
    }
    widget.onChanged(next);
  }

  void _clearAll() {
    widget.onChanged({});
  }

  void _removeValue(T value) {
    widget.onChanged(Set<T>.of(widget.values)..remove(value));
  }

  /// Parent select-all semantics: unchecked selects every option; checked or
  /// indeterminate clears the whole selection.
  void _toggleAll() {
    if (widget.values.isEmpty) {
      widget.onChanged({for (final option in widget.options) option.value});
    } else {
      widget.onChanged({});
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _controller.hide();
      return KeyEventResult.handled;
    }
    // While the filter field holds focus, printable keys (incl. Space) belong
    // to the text; only ↑/↓ navigate and Enter toggles the highlighted row.
    final filterTyping = widget.filterable && _filterFocus.hasFocus;
    final options = _listOptions;
    final count = options.length;
    if (count == 0) {
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      final cur = _highlighted;
      final next = cur == null ? 0 : (cur + 1) % count;
      setState(() => _highlighted = next);
      _rows.reveal(next, from: cur ?? -1);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      final cur = _highlighted;
      final next = cur == null ? count - 1 : (cur - 1) % count;
      setState(() => _highlighted = next);
      _rows.reveal(next, from: cur ?? -1);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.space && !filterTyping) {
      final cur = _highlighted;
      if (cur != null && cur < count) {
        _toggleOption(options[cur]);
      }
      return KeyEventResult.handled;
    } else if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter) &&
        filterTyping) {
      final cur = _highlighted;
      if (cur != null && cur < count) {
        _toggleOption(options[cur]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      matchTargetWidth: true,
      // A filterable field stays interactive while the panel is open: taps on
      // the field (the caret, the clear-filter ✕) must reach it, not the
      // dismiss barrier.
      barrierTargetHole: widget.filterable,
      target: Focus(
        // Ancestor key handler so ↑/↓/Enter/Esc drive the open list while the
        // filterable field keeps text focus (Space stays with the text).
        // `canRequestFocus: false` keeps it out of the tab order.
        canRequestFocus: false,
        onKeyEvent: widget.filterable ? _onKey : null,
        child: _CcMultiSelectTrigger<T>(
          options: widget.options,
          values: widget.values,
          hintText: widget.hintText,
          enabled: widget.enabled,
          showChips: widget.showChips,
          filterable: widget.filterable,
          countLabel: widget.countLabel,
          chevronIcon: widget.chevronIcon,
          isOpen: _controller.isOpen,
          semanticLabel: widget.semanticLabel,
          filterController: _filterText,
          filterFocusNode: _filterFocus,
          tapGroup: _tapGroup,
          onPressed: widget.enabled
              ? (widget.filterable ? _onFieldTap : _toggle)
              : null,
          onClearAll: widget.enabled ? _clearAll : null,
          onRemoveValue: widget.enabled ? _removeValue : null,
          onClearFilter: widget.enabled ? _clearFilter : null,
        ),
      ),
      overlayBuilder: _buildPanel,
      // Keep the dropdown clickable when it opens over a web platform view
      // (an <iframe>/embedded webview). No-op off-web.
      interceptPointer: true,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.ds;
    final card = CcCardTokens.panel(t);
    final options = _listOptions;
    _rows.resize(options.length);
    final hasHeaderRow =
        widget.selectAllLabel != null || widget.values.isNotEmpty;
    // Lists of six or more scroll instead of growing: the panel caps at 5.5
    // rows (plus the pinned header row) so the half-visible last row signals
    // there is more below (scrollbars are not always shown).
    final capped = options.length >= _kScrollsFromOption;

    // The panel shares the filter field's tap-region group: toggling a row is
    // "inside" the field's region, so the filter keeps focus while selecting.
    return TextFieldTapRegion(
      groupId: _tapGroup,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: card.bg,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: card.border),
          boxShadow: CcElevation.floating,
        ),
        child: ClipRRect(
          borderRadius: AppRadii.brLg,
          // Scroll when the option list is taller than the viewport cap imposed
          // by [CcOverlayAnchor]; short lists still shrink-wrap to their rows.
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: capped
                  ? (5.5 + (hasHeaderRow ? 1 : 0)) * _kOptionRowHeight
                  : double.infinity,
            ),
            child: SingleChildScrollView(
              child: FocusScope(
                // Trap Tab inside the panel and autofocus the first row so
                // keyboard Escape works and the list is reachable without the
                // mouse. A filterable field keeps text focus instead.
                node: _panelScope,
                autofocus: !widget.filterable,
                child: Focus(
                  canRequestFocus: false,
                  onKeyEvent: _onKey,
                  child: Builder(
                    builder: (context) {
                      final selectedCount = widget.options
                          .where((o) => widget.values.contains(o.value))
                          .length;
                      // Edge-to-edge rows: no panel padding, so the hover wash
                      // spans the full width of the list.
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (widget.selectAllLabel != null)
                            _CcMultiSelectAllRow(
                              label: widget.selectAllLabel!,
                              allSelected:
                                  selectedCount > 0 &&
                                  selectedCount == widget.options.length,
                              someSelected: selectedCount > 0,
                              onToggle: _toggleAll,
                            )
                          else if (widget.values.isNotEmpty)
                            _CcMultiSelectClearRow(onClear: _clearAll),
                          if (options.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              child: Text(
                                'No matching options',
                                style: CcTypography.caption.copyWith(
                                  color: t.textTertiary,
                                ),
                              ),
                            )
                          else
                            for (var i = 0; i < options.length; i++)
                              KeyedSubtree(
                                key: _rows.keyAt(i),
                                child: _CcMultiSelectRow<T>(
                                  option: options[i],
                                  checked: widget.values.contains(
                                    options[i].value,
                                  ),
                                  highlighted: i == _highlighted,
                                  onToggle: () => _toggleOption(options[i]),
                                ),
                              ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CcMultiSelectTrigger<T> extends StatelessWidget {
  const _CcMultiSelectTrigger({
    required this.options,
    required this.values,
    required this.hintText,
    required this.enabled,
    required this.showChips,
    required this.filterable,
    required this.countLabel,
    required this.chevronIcon,
    required this.isOpen,
    required this.semanticLabel,
    required this.filterController,
    required this.filterFocusNode,
    required this.tapGroup,
    required this.onPressed,
    required this.onClearAll,
    required this.onRemoveValue,
    required this.onClearFilter,
  });

  final List<CcSelectOption<T>> options;
  final Set<T> values;
  final String? hintText;
  final bool enabled;
  final bool showChips;
  final bool filterable;
  final String Function(int count)? countLabel;
  final IconData chevronIcon;
  final bool isOpen;
  final String? semanticLabel;

  /// Text controller for the filterable field's typed query.
  final TextEditingController filterController;

  /// Focus node for the filterable field's editable text.
  final FocusNode filterFocusNode;

  /// Tap-region group shared with the panel, so toggling a row never blurs
  /// the filter field.
  final Object tapGroup;

  final VoidCallback? onPressed;

  /// Clears the whole selection from the trigger's count tag ✕.
  final VoidCallback? onClearAll;

  /// Removes a single value from a summary chip's ✕ (showChips mode).
  final ValueChanged<T>? onRemoveValue;

  /// Clears the typed filter text (never the selection).
  final VoidCallback? onClearFilter;

  List<CcSelectOption<T>> get _selectedOptions =>
      options.where((o) => values.contains(o.value)).toList(growable: false);

  /// Whether the field currently shows an interactive clear affordance (the
  /// count tag's ✕, removable chips, or the clear-filter ✕) — that plus the
  /// interactive chevron is exactly when Carbon puts a vertical divider
  /// between the two interactive elements.
  bool get _showsInteractiveClear {
    if (!enabled) {
      return false;
    }
    if (filterable && isOpen && filterController.text.isNotEmpty) {
      return true;
    }
    if (values.isEmpty) {
      return false;
    }
    return showChips ? onRemoveValue != null : onClearAll != null;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final duration = CcMotion.resolve(context, CcMotion.fast);
    final hasValue = values.isNotEmpty;
    final editing = filterable && isOpen && enabled;

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      // A filterable field signals text entry with the I-beam on hover.
      mouseCursor: filterable && enabled ? SystemMouseCursors.text : null,
      semanticLabel: semanticLabel ?? hintText,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        // Field chrome: 1px bottom underline at rest; open draws the 2px accent
        // outline over the whole box (foregroundDecoration, no layout shift).
        // Transparent (not null) at rest keeps the foregroundDecoration always
        // present so the subtree is never restructured on open/close.
        final underlineColor = !enabled ? t.borderDisabled : input.border;
        final outlineColor = enabled && isOpen
            ? input.borderFocused
            : _transparent;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: !enabled
                ? t.bgDisabled
                : hovered
                ? t.bgSecondaryHover
                : input.bg,
            border: Border(bottom: BorderSide(color: underlineColor)),
          ),
          foregroundDecoration: BoxDecoration(
            border: Border.all(color: outlineColor, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: editing
                    ? _buildEditingSummary(t, input, hasValue)
                    : _buildSummary(t, input, enabled, hasValue),
              ),
              if (editing && filterController.text.isNotEmpty) ...[
                AppSpacing.hGapSm,
                // Clears the typed filter text only — never the selection.
                CcTooltip(
                  message: 'Clear filter',
                  child: CcTappable(
                    onPressed: onClearFilter,
                    borderRadius: AppRadii.brXs,
                    semanticLabel: 'Clear filter',
                    builder: (context, states) => Icon(
                      CcIcons.x,
                      size: 14,
                      color: states.contains(WidgetState.hovered)
                          ? t.textPrimary
                          : t.textTertiary,
                    ),
                  ),
                ),
              ],
              if (_showsInteractiveClear) ...[
                AppSpacing.hGapSm,
                const _CcFieldDivider(),
              ],
              AppSpacing.hGapSm,
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: duration,
                curve: CcMotion.standard,
                child: Icon(
                  chevronIcon,
                  size: 16,
                  color: enabled ? t.fgTertiary : t.fgDisabled,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// The open filterable field: the count tag stays pinned at the left and
  /// the rest of the row is the editable query text.
  Widget _buildEditingSummary(
    DesignSystemTokens t,
    CcInputTokens input,
    bool hasValue,
  ) {
    final count = values.length;
    return Row(
      children: [
        if (hasValue && !showChips) ...[
          _CcCountTag(
            label: countLabel?.call(count) ?? '$count selected',
            enabled: enabled,
            onClear: onClearAll,
          ),
          AppSpacing.hGapSm,
        ],
        Expanded(
          child: EditableText(
            controller: filterController,
            focusNode: filterFocusNode,
            groupId: tapGroup,
            style: CcTypography.bodySm.copyWith(color: input.text),
            cursorColor: t.accent,
            backgroundCursorColor: t.hover,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(
    DesignSystemTokens t,
    CcInputTokens input,
    bool enabled,
    bool hasValue,
  ) {
    if (!hasValue) {
      return Text(
        hintText ?? '',
        style: CcTypography.bodySm.copyWith(
          color: enabled ? input.placeholder : t.textDisabled,
        ),
        overflow: TextOverflow.ellipsis,
      );
    }

    if (showChips) {
      final selected = _selectedOptions;
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final option in selected)
            _CcSummaryChip(
              label: option.label,
              enabled: enabled,
              onRemove: onRemoveValue == null
                  ? null
                  : () => onRemoveValue!(option.value),
            ),
        ],
      );
    }

    // A count tag (with its own ✕ to clear the whole selection in place)
    // sits before the persistent hint text, so the field keeps saying what
    // it selects even while values are chosen.
    final count = values.length;
    final text = countLabel?.call(count) ?? '$count selected';
    return Row(
      children: [
        _CcCountTag(label: text, enabled: enabled, onClear: onClearAll),
        if (hintText != null) ...[
          AppSpacing.hGapSm,
          Flexible(
            child: Text(
              hintText!,
              style: CcTypography.bodySm.copyWith(
                color: enabled ? input.placeholder : t.textDisabled,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}

/// A 1px vertical separator between two interactive elements inside an input
/// field (e.g. a clear ✕ and the chevron). Never drawn next to non-interactive
/// content and never between the caret and the placeholder/value text.
class _CcFieldDivider extends StatelessWidget {
  const _CcFieldDivider();

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Container(width: 1, height: 20, color: t.borderPrimary);
  }
}

/// The selection-count tag in the trigger: the count summary plus a ✕ that
/// clears the whole selection without opening the panel.
class _CcCountTag extends StatelessWidget {
  const _CcCountTag({
    required this.label,
    required this.enabled,
    required this.onClear,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = enabled ? t.textPrimary : t.textDisabled;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? t.bgSecondary : t.bgDisabled,
        borderRadius: AppRadii.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: CcTypography.caption.copyWith(color: fg)),
            if (onClear != null) ...[
              const SizedBox(width: AppSpacing.xs),
              CcTooltip(
                message: 'Clear all selected options',
                child: CcTappable(
                  onPressed: onClear,
                  borderRadius: AppRadii.brXs,
                  semanticLabel: 'Clear selection',
                  builder: (context, states) => Icon(
                    CcIcons.x,
                    size: 12,
                    color: states.contains(WidgetState.hovered)
                        ? t.textPrimary
                        : t.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CcSummaryChip extends StatelessWidget {
  const _CcSummaryChip({
    required this.label,
    required this.enabled,
    this.onRemove,
  });

  final String label;
  final bool enabled;

  /// Dismisses this chip's value from the selection (a dismissible tag).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = enabled ? t.textPrimary : t.textDisabled;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: enabled ? t.surface : t.bgDisabled,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: CcTypography.caption.copyWith(color: fg),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (enabled && onRemove != null) ...[
              const SizedBox(width: AppSpacing.xs),
              CcTappable(
                onPressed: onRemove,
                borderRadius: AppRadii.brXs,
                semanticLabel: 'Remove $label',
                builder: (context, states) => Icon(
                  CcIcons.x,
                  size: 12,
                  color: states.contains(WidgetState.hovered)
                      ? t.textPrimary
                      : t.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The pinned parent select-all row: a tristate checkbox whose unchecked
/// state selects every option and whose checked/indeterminate states clear
/// the selection.
class _CcMultiSelectAllRow extends StatelessWidget {
  const _CcMultiSelectAllRow({
    required this.label,
    required this.allSelected,
    required this.someSelected,
    required this.onToggle,
  });

  final String label;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return CcTappable(
      onPressed: onToggle,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(color: hovered ? t.hover : _transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Passive mirror, same as the option rows: the row is the tap
                // target.
                IgnorePointer(
                  child: CcCheckbox(
                    value: allSelected,
                    indeterminate: someSelected && !allSelected,
                    onChanged: (_) {},
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    label,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: CcTypography.mediumWeight,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A "Clear all" affordance pinned at the top of the open multiselect panel
/// while any value is selected (the count tag clears the selection).
class _CcMultiSelectClearRow extends StatelessWidget {
  const _CcMultiSelectClearRow({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return CcTappable(
      onPressed: onClear,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: 'Clear all',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(color: hovered ? t.hover : _transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Clear all',
              style: CcTypography.caption.copyWith(color: t.accent),
            ),
          ),
        );
      },
    );
  }
}

class _CcMultiSelectRow<T> extends StatelessWidget {
  const _CcMultiSelectRow({
    required this.option,
    required this.checked,
    required this.highlighted,
    required this.onToggle,
  });

  final CcSelectOption<T> option;
  final bool checked;
  final bool highlighted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

    return CcTappable(
      onPressed: onToggle,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      semanticLabel: option.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final wash = pressed
            ? t.hoverStrong
            : (hovered || highlighted)
            ? t.hover
            : _transparent;

        return DecoratedBox(
          decoration: BoxDecoration(color: wash),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // The row is the tap target; the checkbox is a passive mirror so
                // its own gesture never competes with the row's CcTappable.
                IgnorePointer(
                  child: CcCheckbox(value: checked, onChanged: (_) {}),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: CcTruncatedText(
                    option.label,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
