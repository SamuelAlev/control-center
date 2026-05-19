import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// A single option in a [CcSelect], [CcAutocomplete] or [CcMultiSelect].
@immutable
class CcSelectOption<T> {
  /// Creates a [CcSelectOption].
  const CcSelectOption({
    required this.value,
    required this.label,
    this.icon,
  });

  /// The underlying value this option carries.
  final T value;

  /// The human-readable label shown in the trigger and the list.
  final String label;

  /// An optional leading icon (a `lucide_icons_flutter` [IconData]).
  final IconData? icon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcSelectOption<T> &&
          other.value == value &&
          other.label == label &&
          other.icon == icon;

  @override
  int get hashCode => Object.hash(value, label, icon);
}

/// A flat single-select dropdown — the cc_ui replacement for Material's
/// `DropdownButton`.
///
/// The trigger is an input-styled bordered box (panel fill, hairline border,
/// 2px radius) showing the selected option's label or [hintText], with a
/// trailing chevron that rotates a half-turn while open. Tapping toggles a
/// floating panel (golden float, width-matched to the trigger) of [CcTappable]
/// rows; the selected row shows a trailing check. Arrow keys move a highlighted
/// index, Enter selects it, Escape closes (mapped by [CcOverlayAnchor]).
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

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcSelect<T>> createState() => _CcSelectState<T>();
}

class _CcSelectState<T> extends State<CcSelect<T>> {
  final CcOverlayController _controller = CcOverlayController();
  final FocusNode _listFocus = FocusNode(debugLabel: 'CcSelect list');
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
    super.dispose();
  }

  void _onOpenChanged() {
    if (!mounted) return;
    // Always rebuild so the trigger reflects the new open/closed state —
    // otherwise the focused border (and chevron rotation) gets stuck on the
    // value captured at the last build and never reverts when closing.
    setState(() {
      _highlighted = _controller.isOpen
          ? widget.options.indexWhere((o) => o.value == widget.value)
          : -1;
    });
    if (_controller.isOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.isOpen) {
          _listFocus.requestFocus();
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
    setState(() => _highlighted = next);
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
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      if (_highlighted >= 0 && _highlighted < widget.options.length) {
        _select(widget.options[_highlighted]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      matchTargetWidth: true,
      target: _CcSelectTrigger(
        label: _selectedLabel,
        hintText: widget.hintText,
        icon: _selectedIcon,
        chevronIcon: widget.chevronIcon,
        enabled: widget.enabled,
        isOpen: _controller.isOpen,
        semanticLabel: widget.semanticLabel,
        onPressed: widget.enabled ? _toggle : null,
      ),
      overlayBuilder: _buildPanel,
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

  IconData? get _selectedIcon {
    for (final option in widget.options) {
      if (option.value == widget.value) {
        return option.icon;
      }
    }
    return null;
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);

    return Focus(
      focusNode: _listFocus,
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
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < widget.options.length; i++)
                    CcSelectRow<T>(
                      option: widget.options[i],
                      selected: widget.options[i].value == widget.value,
                      highlighted: i == _highlighted,
                      checkIcon: widget.checkIcon,
                      onPressed: () => _select(widget.options[i]),
                      onHover: (hovered) {
                        if (hovered) {
                          setState(() => _highlighted = i);
                        }
                      },
                    ),
                ],
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
    required this.icon,
    required this.chevronIcon,
    required this.enabled,
    required this.isOpen,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String? label;
  final String? hintText;
  final IconData? icon;
  final IconData chevronIcon;
  final bool enabled;
  final bool isOpen;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final input = CcInputTokens.resolve(t);
    final duration = CcMotion.resolve(context, CcMotion.fast);
    final hasValue = label != null;
    final text = label ?? hintText ?? '';

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: semanticLabel ?? label ?? hintText,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final borderColor = !enabled
            ? t.borderDisabled
            : isOpen
                ? input.borderFocused
                : hovered
                    ? t.lineStrong
                    : input.border;
        final textColor = !enabled
            ? t.textDisabled
            : hasValue
                ? input.text
                : input.placeholder;

        // Plain Container (not AnimatedContainer) so the border snaps instantly
        // on hover/open/focus. Animating the border caused a visible alpha-bump
        // flicker because borderPrimary (opaque) and lineStrong (16% alpha)
        // have very different alphas — Color.lerp peaks dark at t≈0.5.
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: enabled ? input.bg : t.bgDisabled,
            borderRadius: AppRadii.brSm,
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: textColor),
                AppSpacing.hGapSm,
              ],
              Expanded(
                child: Text(
                  text,
                  style: CcTypography.bodySm.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
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
  });

  /// The option this row represents.
  final CcSelectOption<T> option;

  /// Whether this row is the current selection (shows a trailing check).
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
    final t = context.designSystem ?? DesignSystemTokens.light();

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      semanticLabel: option.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        if (hovered && onHover != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onHover!(true));
        }
        final wash = pressed
            ? t.hoverStrong
            : (hovered || highlighted)
                ? t.hover
                : _transparent;
        final color = selected ? t.textPrimary : t.textSecondary;

        return DecoratedBox(
          decoration: BoxDecoration(color: wash),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: 16, color: color),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: CcTypography.bodySm.copyWith(color: color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (selected) ...[
                  AppSpacing.hGapSm,
                  Icon(checkIcon, size: 16, color: t.accent),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
