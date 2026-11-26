import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_fluid_hover.dart';
import 'package:cc_ui/src/foundation/cc_focus_trap.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_row_reveal.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typeahead.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// Natural height of a [CcSelectRow] (its `minHeight`; vertical padding plus
/// one line of `bodySm` never exceeds it).
const double _kOptionRowHeight = 40;

/// Lists this long scroll instead of growing: the panel caps at
/// [_kScrollsFromOption] − 0.5 rows so the half-visible last row signals
/// there is more below (scrollbars are not always shown).
const int _kScrollsFromOption = 6;

/// A single option in a [CcSelect], [CcAutocomplete] or [CcMultiSelect].
///
/// Keep [label] brief and factual — a name, not a description. When the list
/// has no natural order (recency, severity, a workflow sequence), present the
/// options alphabetically. Long labels never wrap: they truncate with an
/// ellipsis and disclose the full text in a tooltip.
///
/// Options are text-only by design: a dropdown never carries decorative
/// images or icons, so there is deliberately no icon slot.
@immutable
class CcSelectOption<T> {
  /// Creates a [CcSelectOption].
  const CcSelectOption({required this.value, required this.label});

  /// The underlying value this option carries.
  final T value;

  /// The human-readable label shown in the trigger and the list.
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcSelectOption<T> &&
          other.value == value &&
          other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// Flat single-select (Material `DropdownButton` replacement). Trigger shows
/// selection or [hintText]; panel of rows with check on selected. Opening
/// moves focus into the panel; Up/Down/Home/End and typed letters move the
/// highlight, Enter/Space pick it, Esc closes; focus returns to the trigger.
/// The trigger's accessible name is [label] (or [semanticLabel]) and its value
/// the selection. Always provide [label]; use
/// [helperText] for persistent guidance (not [hintText]). Prefer [CcRadioGroup]
/// for two mutually exclusive values.
class CcSelect<T> extends StatefulWidget {
  /// Creates a [CcSelect].
  const CcSelect({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hintText,
    this.enabled = true,
    this.chevronIcon = CcIcons.chevronDown,
    this.checkIcon = CcIcons.check,
    this.semanticLabel,
    this.label,
    this.helperText,
    this.errorText,
    this.warnText,
  });

  /// The selectable options.
  final List<CcSelectOption<T>> options;

  /// The currently selected value, or null when nothing is selected.
  final T? value;

  /// Called with the chosen value when a row is selected.
  final ValueChanged<T> onChanged;

  /// Placeholder shown when [value] is null.
  final String? hintText;

  /// Whether the control is interactive.
  final bool enabled;

  /// Trailing chevron icon (rotates when open).
  final IconData chevronIcon;

  /// Trailing check icon drawn on the selected row.
  final IconData checkIcon;

  /// Accessible name for the trigger when it differs from [label] (or when
  /// there is no visible label).
  final String? semanticLabel;

  /// Optional persistent label rendered above the trigger; also the
  /// trigger's accessible name.
  final String? label;

  /// Optional helper text rendered beneath the trigger when there is no error.
  final String? helperText;

  /// When non-null the trigger shows an error message beneath it.
  final String? errorText;

  /// When non-null (and there is no error) the trigger shows a warning message
  /// beneath it.
  final String? warnText;

  @override
  State<CcSelect<T>> createState() => _CcSelectState<T>();
}

class _CcSelectState<T> extends State<CcSelect<T>> {
  final CcOverlayController _controller = CcOverlayController();
  final FocusNode _listFocus = FocusNode(debugLabel: 'CcSelect list');

  /// Keeps the arrow-key highlight inside the scrolled viewport.
  final CcRowReveal _rows = CcRowReveal();

  final CcTypeahead _typeahead = CcTypeahead();

  int _highlighted = -1;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onOpenChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onOpenChanged);
    _controller.dispose();
    _listFocus.dispose();
    _typeahead.dispose();
    super.dispose();
  }

  void _onOpenChanged() {
    if (!mounted) return;
    _typeahead.reset();
    // Always rebuild so the trigger reflects the new open/closed state —
    // otherwise the focused border (and chevron rotation) gets stuck on the
    // value captured at the last build and never reverts when closing.
    setState(() {
      _highlighted = _controller.isOpen
          ? widget.options.indexWhere((o) => o.value == widget.value)
          : -1;
    });
    if (_controller.isOpen) {
      // A long list opens scrolled to the top, which hides the option the
      // field is actually showing. Centre it so the panel opens on the
      // current value, once its rows exist.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isOpen) {
          _rows.reveal(_highlighted);
        }
      });
    }
  }

  void _toggle() {
    if (widget.enabled) {
      _controller.toggle();
    }
  }

  void _select(CcSelectOption<T> option) {
    _controller.hide();
    widget.onChanged(option.value);
  }

  void _move(int delta) {
    if (widget.options.isEmpty) {
      return;
    }
    final count = widget.options.length;
    var next = _highlighted;
    next = next < 0 ? (delta > 0 ? 0 : count - 1) : (next + delta) % count;
    if (next < 0) {
      next += count;
    }
    _moveTo(next);
  }

  void _moveTo(int next) {
    if (next < 0 || next >= widget.options.length) {
      return;
    }
    final previous = _highlighted;
    setState(() => _highlighted = next);
    _rows.reveal(next, from: previous);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _move(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _move(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _moveTo(0);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _moveTo(widget.options.length - 1);
      return KeyEventResult.handled;
    }
    // A Space while letters are being typed is part of the search ("new y").
    final typed = _typeahead.match(
      event,
      count: widget.options.length,
      current: _highlighted,
      labelAt: (index) => widget.options[index].label,
    );
    if (typed != null) {
      _moveTo(typed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      if (_highlighted >= 0 && _highlighted < widget.options.length) {
        _select(widget.options[_highlighted]);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final hasError = widget.errorText != null;
    final hasWarn = widget.warnText != null && !hasError;
    final field = CcOverlayAnchor(
      controller: _controller,
      matchTargetWidth: true,
      target: _CcSelectTrigger(
        label: _selectedLabel,
        hintText: widget.hintText,
        chevronIcon: widget.chevronIcon,
        enabled: widget.enabled,
        isOpen: _controller.isOpen,
        semanticLabel: widget.semanticLabel ?? widget.label,
        semanticHint: hasError || hasWarn
            ? null
            : (widget.helperText ?? widget.hintText),
        onPressed: widget.enabled ? _toggle : null,
      ),
      overlayBuilder: _buildPanel,
      // Keep the dropdown clickable when it opens over a web platform view
      // (an <iframe>/embedded webview). No-op off-web.
      interceptPointer: true,
    );

    final showLabel = widget.label != null;
    final showHelper = widget.helperText != null && !hasError && !hasWarn;
    if (!showLabel && !showHelper && !hasError && !hasWarn) {
      return field;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          // The trigger carries the label as its name.
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        field,
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Semantics(
            liveRegion: true,
            container: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(CcIcons.circleX, size: 13, color: t.danger),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: CcTypography.caption.copyWith(color: t.danger),
                  ),
                ),
              ],
            ),
          ),
        ] else if (hasWarn) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CcIcons.triangleAlert, size: 13, color: t.warn),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.warnText!,
                  style: CcTypography.caption.copyWith(color: t.warn),
                ),
              ),
            ],
          ),
        ] else if (showHelper) ...[
          const SizedBox(height: AppSpacing.xs),
          // Read as the trigger's hint.
          ExcludeSemantics(
            child: Text(
              widget.helperText!,
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
        ],
      ],
    );
  }

  String? get _selectedLabel {
    for (final option in widget.options) {
      if (option.value == widget.value) {
        return option.label;
      }
    }
    return null;
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.ds;
    final card = CcCardTokens.panel(t);
    _rows.resize(widget.options.length);

    // The trigger holds focus as the panel opens, so an autofocus on its own
    // would be dropped; the trap takes it and gives it back on close.
    return CcFocusTrap(
      child: Focus(
        focusNode: _listFocus,
        autofocus: true,
        onKeyEvent: _onKey,
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
            // Longer lists are additionally capped at 5.5 rows so the half-cut
            // sixth row advertises that the list continues.
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: widget.options.length >= _kScrollsFromOption
                    ? (_kScrollsFromOption - 0.5) * _kOptionRowHeight
                    : double.infinity,
              ),
              child: SingleChildScrollView(
                // Edge-to-edge rows: no panel padding, so the hover wash spans
                // the full width of the list.
                child: CcFluidHover(
                  itemCount: widget.options.length,
                  onActiveIndexChanged: (index) {
                    if (index != null && _highlighted != index) {
                      setState(() => _highlighted = index);
                    }
                  },
                  itemBuilder: (context, i) => KeyedSubtree(
                    key: _rows.keyAt(i),
                    child: CcSelectRow<T>._listDriven(
                      option: widget.options[i],
                      selected: widget.options[i].value == widget.value,
                      highlighted: i == _highlighted,
                      checkIcon: widget.checkIcon,
                      onPressed: () => _select(widget.options[i]),
                    ),
                  ),
                  layoutBuilder: (context, items) => Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: items,
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

/// The input-styled trigger box for [CcSelect] and [CcMultiSelect].
class _CcSelectTrigger extends StatelessWidget {
  const _CcSelectTrigger({
    required this.label,
    required this.hintText,
    required this.chevronIcon,
    required this.enabled,
    required this.isOpen,
    required this.semanticLabel,
    required this.semanticHint,
    required this.onPressed,
  });

  /// The selected option's label.
  final String? label;
  final String? hintText;
  final IconData chevronIcon;
  final bool enabled;
  final bool isOpen;

  /// The field's name; the selection is the value, not the name.
  final String? semanticLabel;
  final String? semanticHint;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final duration = CcMotion.resolve(context, CcMotion.fast);
    final hasValue = label != null;
    final text = label ?? hintText ?? '';

    final name = semanticLabel ?? hintText;
    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: name,
      semanticValue: label,
      semanticHint: semanticHint == name ? null : semanticHint,
      semanticExpanded: isOpen,
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
        final textColor = !enabled
            ? t.textDisabled
            : hasValue
            ? input.text
            : input.placeholder;

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
                // Name and value are on the trigger's own node.
                child: ExcludeSemantics(
                  child: CcTruncatedText(
                    text,
                    style: CcTypography.bodySm.copyWith(color: textColor),
                  ),
                ),
              ),
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
}

/// A single option row in a [CcSelect] dropdown panel.
class CcSelectRow<T> extends StatelessWidget {
  /// Creates a [CcSelectRow].
  const CcSelectRow({
    super.key,
    required this.option,
    required this.selected,
    required this.highlighted,
    required this.checkIcon,
    required this.onPressed,
    this.onHover,
  }) : _focusable = true;

  /// A row of a [CcSelect] panel: the panel's key node owns the keyboard and
  /// runs the list on [highlighted], so the row is never a focus stop.
  const CcSelectRow._listDriven({
    super.key,
    required this.option,
    required this.selected,
    required this.highlighted,
    required this.checkIcon,
    required this.onPressed,
  }) : onHover = null,
       _focusable = false;

  final bool _focusable;

  /// The option this row represents.
  final CcSelectOption<T> option;

  /// Whether this row is the current selection (persistent gray wash and a
  /// trailing check).
  final bool selected;

  /// Whether this row is keyboard-highlighted (shows a hover wash).
  final bool highlighted;

  /// The trailing check icon.
  final IconData checkIcon;

  /// Invoked when the row is tapped.
  final VoidCallback onPressed;

  /// Reports pointer hover so the parent can sync the highlighted index.
  final ValueChanged<bool>? onHover;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      // A standalone row (in a popover) is a focus stop and draws its ring; a
      // panel row is driven by the highlight.
      showFocusRing: _focusable,
      canRequestFocus: _focusable,
      semanticLabel: option.label,
      semanticSelected: _focusable ? null : highlighted,
      semanticChecked: selected,
      semanticInMutuallyExclusiveGroup: true,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);
        if (hovered && onHover != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onHover!(true));
        }
        // The selected row carries a persistent neutral wash. Pointer hover is
        // painted once by CcFluidHover; keyboard highlight remains row-local.
        final wash = pressed
            ? t.hoverStrong
            : selected
            ? t.hover
            : fluidActive
            ? _transparent
            : (hovered || highlighted)
            ? t.hover
            : _transparent;
        final color = selected ? t.textPrimary : t.textSecondary;

        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(color: wash),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Expanded(
                  // The row already carries the label; read it once.
                  child: ExcludeSemantics(
                    child: CcTruncatedText(
                      option.label,
                      style: CcTypography.bodySm.copyWith(color: color),
                    ),
                  ),
                ),
                if (selected) ...[
                  AppSpacing.hGapSm,
                  Icon(checkIcon, size: 16, color: t.textPrimary),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
