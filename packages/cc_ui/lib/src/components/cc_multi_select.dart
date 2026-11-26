import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_select.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_focus_trap.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_row_reveal.dart';
import 'package:cc_ui/src/foundation/cc_submit_keeps_focus.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_strings.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

part 'cc_multi_select_rows.dart';
part 'cc_multi_select_trigger.dart';

const Color _transparent = Color(0x00000000);

/// Natural height of a multi-select option row (32px checkbox target plus
/// 16px of vertical padding).
const double _kOptionRowHeight = 48;

/// Lists this long scroll instead of growing: the panel caps at 5.5 rows so
/// the half-visible last row signals there is more below.
const int _kScrollsFromOption = 6;

/// Flat multi-select like [CcSelect], with per-row checkboxes and a [Set] of
/// values. Trigger summarises via [countLabel] (✕ clears all) + [hintText], or
/// [showChips] for dismissible chips. Toggles call [onChanged] without closing.
/// On reopen, selected options rise (alphanumeric); order is frozen while open.
///
/// Closes on Esc or outside click; focus then returns to the trigger. Without
/// [filterable], opening moves focus into the panel and Tab stays there; with
/// it, focus stays in the field (typing filters, Tab away closes). Arrows
/// highlight, Space/Enter toggle it (only Enter while the filter has focus).
/// Rows never take focus: the list node owns the keyboard. [selectAllLabel]
/// pins a noun-named select-all row; otherwise "Clear all" while any value is
/// selected. The trigger's ✕ buttons are Tab stops of their own beside it.
///
/// [filterable]: typed query narrows the list; filter ✕ clears query only.
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

  /// Accessible name of the trigger; defaults to [hintText]. The selection is
  /// read as its value.
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

  /// Keyboard owner of a non-filterable open panel. The rows are not
  /// focusable, so Enter/Space reach [_onKey] and act on the highlighted row
  /// instead of activating whichever row happened to hold focus.
  final FocusNode _listFocus = FocusNode(debugLabel: 'CcMultiSelect list');

  /// The trigger's own focus stop; a closing filterable field hands focus
  /// back to it, since the filter text it held leaves the tree.
  final FocusNode _triggerFocus = FocusNode(debugLabel: 'CcMultiSelect');

  /// Spans the trigger and its ✕ buttons; while it holds focus a filterable
  /// panel stays open.
  final FocusNode _fieldFocus = FocusNode(
    debugLabel: 'CcMultiSelect field',
    canRequestFocus: false,
    skipTraversal: true,
  );

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
    _listFocus.dispose();
    _triggerFocus.dispose();
    _fieldFocus.dispose();
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
    if (!widget.filterable) {
      return;
    }
    final open = _controller.isOpen;
    // Opening swaps the summary for the filter text and closing swaps it
    // back, so focus has to follow onto whichever exists after this frame.
    final returnFocus = !open && _fieldFocus.hasFocus;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (open && _controller.isOpen) {
        _filterFocus.requestFocus();
      } else if (returnFocus && !_controller.isOpen) {
        _triggerFocus.requestFocus();
      }
    });
  }

  /// A filterable panel closes once focus has left the field and its ✕
  /// buttons, checked after the frame so the focus hand-over between the
  /// summary and the filter text never reads as leaving.
  void _onFieldFocusChange(bool focused) {
    if (focused || !widget.filterable) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _controller.isOpen &&
          !_fieldFocus.hasFocus &&
          !_panelScope.hasFocus) {
        _controller.hide();
      }
    });
    WidgetsBinding.instance.ensureVisualUpdate();
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
    } else if ((key == LogicalKeyboardKey.space && !filterTyping) ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
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
        // filterable field keeps text focus (Space stays with the text). The
        // node itself never takes focus.
        focusNode: _fieldFocus,
        onKeyEvent: widget.filterable ? _onKey : null,
        onFocusChange: _onFieldFocusChange,
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
          triggerFocusNode: _triggerFocus,
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
              // A filterable panel holds nothing to focus; without this its
              // empty scope would be a Tab stop after the field.
              child: ExcludeFocus(
                excluding: widget.filterable,
                child: CcFocusTrap(
                  // Take focus from the trigger and hold Tab inside the panel so
                  // Escape and the arrow keys work without the mouse; focus goes
                  // back on close. A filterable field keeps text focus instead.
                  node: _panelScope,
                  autofocus: !widget.filterable,
                  child: Focus(
                    focusNode: _listFocus,
                    autofocus: !widget.filterable,
                    canRequestFocus: !widget.filterable,
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
                                  context.ccStrings.noMatches,
                                  style: CcTypography.caption.copyWith(
                                    color: t.textTertiary,
                                  ),
                                ),
                              )
                            else
                              CcFluidHover(
                                itemCount: options.length,
                                onActiveIndexChanged: (index) {
                                  if (index != null && _highlighted != index) {
                                    setState(() => _highlighted = index);
                                  }
                                },
                                itemBuilder: (context, i) => KeyedSubtree(
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
                                layoutBuilder: (context, items) => Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: items,
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
      ),
    );
  }
}
