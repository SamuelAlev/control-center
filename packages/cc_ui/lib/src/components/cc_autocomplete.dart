import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_select.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// Filters [options] for a typed [query]. Return the matches in display order.
typedef CcAutocompleteFilter<T> =
    List<CcSelectOption<T>> Function(
      List<CcSelectOption<T>> options,
      String query,
    );

/// A flat autocomplete field — an input whose typed query filters a list of
/// [CcSelectOption]s, shown in a floating panel anchored below the field.
///
/// The field is an input-styled box wrapping an [EditableText] (no Material).
/// Clicking anywhere in the field opens the menu; as the user types, [filter]
/// (or a default case-insensitive `contains` on the label) narrows [options]
/// and the best-matching (first) option stays highlighted. The matches render
/// in a width-matched floating panel of [CcTappable] rows. Selecting a row —
/// by tap or by keyboard (`↑`/`↓` to highlight, `Enter` to choose, `Esc` to
/// close) — fills the field with the option's display string (via
/// [displayString], defaulting to its label), closes the panel and calls
/// [onSelected]. A ✕ appears to the right of any typed text and clears the
/// input. The field keeps focus while the list is open. An empty match list
/// shows a "No results" row.
///
/// Pass [onCustomValue] for combo-box behavior: when the typed text matches
/// no option, clicking outside the field, pressing Tab, or pressing Enter
/// commits it as a custom value and the field keeps displaying it. An exact
/// option match is always a selection, never a custom commit.
class CcAutocomplete<T> extends StatefulWidget {
  /// Creates a [CcAutocomplete].
  const CcAutocomplete({
    super.key,
    required this.options,
    required this.onSelected,
    this.hintText,
    this.displayString,
    this.filter,
    this.onCustomValue,
    this.onCleared,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.semanticLabel,
  });

  /// The full set of options to filter.
  final List<CcSelectOption<T>> options;

  /// Called with the chosen value when a row is selected.
  final ValueChanged<T> onSelected;

  /// Placeholder shown while the field is empty.
  final String? hintText;

  /// Maps an option to the string written into the field on selection and used
  /// for the default filter. Defaults to the option's label.
  final String Function(CcSelectOption<T> option)? displayString;

  /// Custom filter; defaults to a case-insensitive `contains` on the display
  /// string.
  final CcAutocompleteFilter<T>? filter;

  /// Enables combo-box behavior: called with the typed text when it matches
  /// no option and the user commits it (Enter, Tab, or clicking outside).
  final ValueChanged<String>? onCustomValue;

  /// Called when the field's ✕ clears the input. Pair with [onCustomValue] in
  /// combo-box uses that treat an empty field as "unset".
  final VoidCallback? onCleared;

  /// Whether the field is interactive.
  final bool enabled;

  /// Optional external text controller.
  final TextEditingController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Accessibility label for the field.
  final String? semanticLabel;

  @override
  State<CcAutocomplete<T>> createState() => _CcAutocompleteState<T>();
}

class _CcAutocompleteState<T> extends State<CcAutocomplete<T>> {
  final CcOverlayController _controller = CcOverlayController();
  TextEditingController? _internalText;
  FocusNode? _internalFocus;
  List<CcSelectOption<T>> _matches = const [];
  int? _highlighted;

  /// Shared tap-region group for the field and the panel. Without it a tap on
  /// a panel row is OUTSIDE the EditableText's tap region, which unfocuses
  /// the field mid-gesture — and a focus-loss panel hide would then cancel
  /// the row's tap before it selects (keyboard selection was unaffected).
  final Object _tapGroup = Object();

  /// The last committed custom value (combo-box mode) — re-committing the
  /// same text (e.g. Tab after Enter) must not fire twice.
  String? _committedCustom;

  /// Set when the panel closes for a reason that is not a commit: Escape or
  /// an option selection. Outside-tap close commits a pending custom value.
  bool _suppressCommitOnHide = false;

  /// Whether the current text was typed by the user since the last selection
  /// or programmatic seed. A committed selection reopens to the FULL option
  /// list — filtering by the selected option's own label would open a one-row
  /// menu.
  bool _userEdited = false;

  /// Last seen controller text — selection-only notifications (a tap moving
  /// the caret) must not re-filter the list or mark the text as user-typed.
  String _lastText = '';

  TextEditingController get _text =>
      widget.controller ?? (_internalText ??= TextEditingController());

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _text.addListener(_onQueryChanged);
    _controller.addListener(_onOverlayChanged);
    _focus.addListener(_onFocusChanged);
    _matches = widget.options;
    _lastText = _text.text;
  }

  @override
  void didUpdateWidget(CcAutocomplete<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.options != widget.options) {
      // Options often arrive async (model lists, branch lists): refresh the
      // matches so a click can open the panel without a keystroke first.
      final filter = widget.filter ?? _defaultFilter;
      setState(() {
        _matches = _userEdited
            ? filter(widget.options, _text.text)
            : widget.options;
      });
    }
  }

  @override
  void dispose() {
    _text.removeListener(_onQueryChanged);
    _controller.removeListener(_onOverlayChanged);
    _focus.removeListener(_onFocusChanged);
    _internalText?.dispose();
    _internalFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _display(CcSelectOption<T> option) =>
      widget.displayString?.call(option) ?? option.label;

  void _onQueryChanged() {
    final query = _text.text;
    if (query == _lastText) {
      // Selection-only change (caret move): the matches don't depend on it.
      return;
    }
    _lastText = query;
    final filter = widget.filter ?? _defaultFilter;
    final next = filter(widget.options, query);
    setState(() {
      _matches = next;
      // Carbon: the best-matching (first) option is highlighted as users
      // type; an untouched full list highlights nothing.
      _highlighted = query.trim().isNotEmpty && next.isNotEmpty ? 0 : null;
      // Editing the text after a commit makes it a new, uncommitted value.
      _committedCustom = null;
      // Only a focused field's text changes are user typing; programmatic
      // writes (parent syncs, selection fill-in) arrive unfocused or are
      // reset by _select right after.
      _userEdited = _focus.hasFocus;
    });
    // Only open the panel for user-driven typing on a focused field. Programmatic
    // controller writes (e.g. parent syncing selectedModelId) update the matches
    // but must not pop the overlay while the user isn't interacting.
    //
    // In combo-box mode a typed value with no matches keeps the panel open on
    // its "No results" row, so clicking outside dismisses it and commits the
    // custom value.
    final committableCustom =
        widget.onCustomValue != null && query.trim().isNotEmpty;
    if (widget.enabled &&
        _focus.hasFocus &&
        (next.isNotEmpty || committableCustom)) {
      _controller.show();
    } else if (next.isEmpty) {
      _controller.hide();
    }
  }

  /// Combo-box custom values: commit the typed text when it names no option.
  /// Fires on Enter (no match), on Tab/focus loss and on outside-tap close.
  void _commitCustom() {
    final onCustomValue = widget.onCustomValue;
    if (onCustomValue == null) {
      return;
    }
    final text = _text.text.trim();
    if (text.isEmpty || text == _committedCustom) {
      return;
    }
    // An exact option match is a selection, not a custom value.
    for (final option in widget.options) {
      if (_display(option).toLowerCase() == text.toLowerCase()) {
        return;
      }
    }
    _committedCustom = text;
    onCustomValue(text);
  }

  void _onOverlayChanged() {
    if (_controller.isOpen) {
      return;
    }
    // A close without the suppress flag is an outside tap: commit a pending
    // custom value. Escape and option selection set the flag first.
    if (_suppressCommitOnHide) {
      _suppressCommitOnHide = false;
    } else {
      _commitCustom();
    }
  }

  void _onFocusChanged() {
    if (_focus.hasFocus) {
      // Clicking anywhere in the field — including directly on the text,
      // where the EditableText claims the tap before the field's own
      // GestureDetector — opens the menu on focus gain.
      _openPanel();
      return;
    }
    // Tabbing away (or any focus loss) commits a pending custom value and
    // closes the panel — Carbon's combo box saves on Tab.
    _hideWithoutCommit();
    _commitCustom();
  }

  /// Opens the panel over a freshly computed match list. A field whose text
  /// is a committed selection (not user-typed this session) opens to the
  /// full option list; mid-typing text keeps its filtered matches.
  void _openPanel() {
    if (!widget.enabled) {
      return;
    }
    final query = _text.text;
    final filter = widget.filter ?? _defaultFilter;
    final next = _userEdited ? filter(widget.options, query) : widget.options;
    final committableCustom =
        widget.onCustomValue != null && query.trim().isNotEmpty;
    setState(() {
      _matches = next;
      _highlighted = _userEdited && query.trim().isNotEmpty && next.isNotEmpty
          ? 0
          : null;
    });
    if (next.isNotEmpty || committableCustom) {
      _controller.show();
    }
  }

  /// Closes the panel without committing — Escape and option selection.
  /// Sets the suppress flag only when a close event will actually follow, so
  /// the flag can never latch and swallow a later outside-tap commit.
  void _hideWithoutCommit() {
    if (_controller.isOpen) {
      _suppressCommitOnHide = true;
      _controller.hide();
    }
  }

  List<CcSelectOption<T>> _defaultFilter(
    List<CcSelectOption<T>> options,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return options;
    }
    return options
        .where((o) => _display(o).toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _select(CcSelectOption<T> option) {
    final value = _display(option);
    _text
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    // The write above looks like typing (the field is focused); it is a
    // committed selection, so the next open shows the full list again.
    _userEdited = false;
    _hideWithoutCommit();
    // Keep the field focused after selection.
    _focus.requestFocus();
    widget.onSelected(option.value);
  }

  /// Enter: pick the highlighted (or best-matching) option; with no matches a
  /// combo box commits the typed text as a custom value instead.
  void _submitted() {
    if (_matches.isNotEmpty) {
      final idx = _highlighted ?? 0;
      _select(_matches[idx.clamp(0, _matches.length - 1)]);
    } else {
      _commitCustom();
    }
  }

  /// The field's ✕: clears the input and shows the full (unfiltered) list.
  void _clearField() {
    _text.clear();
    _focus.requestFocus();
    widget.onCleared?.call();
  }

  void _onFieldTap() {
    if (!widget.enabled) {
      return;
    }
    _focus.requestFocus();
    _openPanel();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _matches.isEmpty) {
      if (event is KeyDownEvent &&
          event.logicalKey == LogicalKeyboardKey.escape) {
        _hideWithoutCommit();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      setState(() {
        final cur = _highlighted;
        _highlighted = cur == null ? 0 : (cur + 1) % _matches.length;
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowUp) {
      setState(() {
        final cur = _highlighted;
        _highlighted = cur == null
            ? _matches.length - 1
            : (cur - 1) % _matches.length;
      });
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.escape) {
      _hideWithoutCommit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      // Ancestor key handler so ↑/↓/Esc drive the floating list while the field
      // keeps text focus. `canRequestFocus: false` keeps it out of the tab order.
      canRequestFocus: false,
      onKeyEvent: _onKey,
      child: CcOverlayAnchor(
        controller: _controller,
        matchTargetWidth: true,
        barrierDismissible: true,
        // The field stays interactive while the panel is open: taps on it
        // (the caret, the clear ✕) reach the field, not the dismiss barrier.
        barrierTargetHole: true,
        target: _CcAutocompleteField(
          controller: _text,
          focusNode: _focus,
          hintText: widget.hintText,
          enabled: widget.enabled,
          semanticLabel: widget.semanticLabel,
          tapGroup: _tapGroup,
          onTap: _onFieldTap,
          onSubmitted: _submitted,
          onClear: widget.enabled ? _clearField : null,
        ),
        overlayBuilder: _buildPanel,
        // Keep suggestions clickable when the field sits over a web platform
        // view (an <iframe>/embedded webview). No-op off-web.
        interceptPointer: true,
      ),
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.ds;
    final card = CcCardTokens.panel(t);

    // The panel shares the field's tap-region group: tapping a row is "inside"
    // the text field's region, so the field keeps focus through selection.
    if (_matches.isEmpty) {
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
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'No results',
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
            ),
          ),
        ),
      );
    }

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
          // Scroll when the match list is taller than the viewport cap imposed by
          // [CcOverlayAnchor]; short lists still shrink-wrap to their rows.
          // Edge-to-edge rows: no panel padding, so the hover wash spans the
          // full width of the list (matches CcSelect's Carbon-style panel).
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < _matches.length; i++)
                  _CcAutocompleteRow<T>(
                    option: _matches[i],
                    highlighted: i == _highlighted,
                    onPressed: () => _select(_matches[i]),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The input-styled field used by [CcAutocomplete].
class _CcAutocompleteField extends StatelessWidget {
  const _CcAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.enabled,
    required this.semanticLabel,
    required this.tapGroup,
    required this.onTap,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final bool enabled;
  final String? semanticLabel;

  /// Tap-region group shared with the dropdown panel, so tapping a panel row
  /// is not "outside" the text field and never unfocuses it mid-gesture.
  final Object tapGroup;

  final VoidCallback onTap;
  final VoidCallback onSubmitted;

  /// Clears the input (the ✕ shown to the right of any typed text).
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final textStyle = CcTypography.bodySm.copyWith(
      color: enabled ? input.text : t.textDisabled,
    );

    return Semantics(
      textField: true,
      label: semanticLabel,
      child: ListenableBuilder(
        listenable: focusNode,
        builder: (context, child) {
          // Field chrome: 1px bottom underline at rest; focus draws the 2px
          // accent outline over the whole box (no layout shift). The outline
          // color is transparent (not null) at rest so the foregroundDecoration
          // is ALWAYS present — toggling it null↔non-null would restructure the
          // Container and reparent the child EditableText, dropping its input
          // connection mid-typing.
          final focused = enabled && focusNode.hasFocus;
          return Container(
            decoration: BoxDecoration(
              color: enabled ? input.bg : t.bgDisabled,
              border: Border(
                bottom: BorderSide(
                  color: enabled ? input.border : t.borderDisabled,
                ),
              ),
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(
                color: focused ? input.borderFocused : _transparent,
                width: 2,
              ),
            ),
            child: child,
          );
        },
        // A Listener (not GestureDetector) so taps on the text itself still
        // reach the field: EditableText wins the gesture arena for those, but
        // pointer events are delivered to every Listener on the hit path —
        // including when the field is already focused and no focus-gain fires.
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => onTap(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      ValueListenableBuilder<TextEditingValue>(
                        valueListenable: controller,
                        builder: (context, value, _) {
                          if (value.text.isNotEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            hintText ?? '',
                            style: textStyle.copyWith(
                              color: input.placeholder,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          );
                        },
                      ),
                      EditableText(
                        controller: controller,
                        focusNode: focusNode,
                        readOnly: !enabled,
                        groupId: tapGroup,
                        style: textStyle,
                        cursorColor: input.cursor,
                        backgroundCursorColor: input.placeholder,
                        selectionColor: input.selection,
                        maxLines: 1,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onSubmitted(),
                        cursorWidth: 1.5,
                      ),
                    ],
                  ),
                ),
                // The ✕ appears to the right of any typed text and clears
                // the input. No vertical divider: it is the field's only
                // interactive element besides the text itself.
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (context, value, _) {
                    if (value.text.isEmpty || onClear == null) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSpacing.sm),
                      child: CcTooltip(
                        message: 'Clear',
                        child: CcTappable(
                          onPressed: onClear,
                          borderRadius: AppRadii.brXs,
                          semanticLabel: 'Clear input',
                          builder: (context, states) => Icon(
                            CcIcons.x,
                            size: 14,
                            color: states.contains(WidgetState.hovered)
                                ? t.textPrimary
                                : t.textTertiary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CcAutocompleteRow<T> extends StatelessWidget {
  const _CcAutocompleteRow({
    required this.option,
    required this.highlighted,
    required this.onPressed,
  });

  final CcSelectOption<T> option;
  final bool highlighted;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
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
