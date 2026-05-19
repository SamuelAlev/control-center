import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_select.dart';
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
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// A flat multi-select dropdown — like [CcSelect] but with per-row checkboxes
/// and a [Set] of selected values.
///
/// The trigger renders the same input-styled box as [CcSelect]; instead of a
/// single label it summarises the selection — either a count
/// (`"3 selected"`, built by [countLabel]) or, when [showChips] is set, the
/// selected option labels as small chips. The panel lists every option as a
/// [CcTappable] row carrying a [CcCheckbox]; toggling a row mutates the set and
/// calls [onChanged] **without closing** the panel, so several values can be
/// toggled in one open session.
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
    this.countLabel,
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

  /// Builds the summary text from the count when [showChips] is false.
  /// Defaults to `"<n> selected"`.
  final String Function(int count)? countLabel;

  /// Trailing chevron icon (rotates when open).
  final IconData chevronIcon;

  /// Accessibility label for the trigger.
  final String? semanticLabel;

  @override
  State<CcMultiSelect<T>> createState() => _CcMultiSelectState<T>();
}

class _CcMultiSelectState<T> extends State<CcMultiSelect<T>> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void initState() {
    super.initState();
    // Rebuild on open/close so the trigger's focused border and chevron
    // rotation reflect the controller state — isOpen is captured at build time.
    _controller.addListener(_onOpenChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onOpenChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onOpenChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _toggle() {
    if (widget.enabled) {
      _controller.toggle();
    }
  }

  void _toggleOption(CcSelectOption<T> option) {
    final next = Set<T>.of(widget.values);
    if (!next.add(option.value)) {
      next.remove(option.value);
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      matchTargetWidth: true,
      target: _CcMultiSelectTrigger<T>(
        options: widget.options,
        values: widget.values,
        hintText: widget.hintText,
        enabled: widget.enabled,
        showChips: widget.showChips,
        countLabel: widget.countLabel,
        chevronIcon: widget.chevronIcon,
        isOpen: _controller.isOpen,
        semanticLabel: widget.semanticLabel,
        onPressed: widget.enabled ? _toggle : null,
      ),
      overlayBuilder: _buildPanel,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);

    return DecoratedBox(
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
                for (final option in widget.options)
                  _CcMultiSelectRow<T>(
                    option: option,
                    checked: widget.values.contains(option.value),
                    onToggle: () => _toggleOption(option),
                  ),
              ],
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
    required this.countLabel,
    required this.chevronIcon,
    required this.isOpen,
    required this.semanticLabel,
    required this.onPressed,
  });

  final List<CcSelectOption<T>> options;
  final Set<T> values;
  final String? hintText;
  final bool enabled;
  final bool showChips;
  final String Function(int count)? countLabel;
  final IconData chevronIcon;
  final bool isOpen;
  final String? semanticLabel;
  final VoidCallback? onPressed;

  List<CcSelectOption<T>> get _selectedOptions =>
      options.where((o) => values.contains(o.value)).toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final input = CcInputTokens.resolve(t);
    final duration = CcMotion.resolve(context, CcMotion.fast);
    final hasValue = values.isNotEmpty;

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      semanticLabel: semanticLabel ?? hintText,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final borderColor = !enabled
            ? t.borderDisabled
            : isOpen
                ? input.borderFocused
                : hovered
                    ? t.lineStrong
                    : input.border;

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
              Expanded(child: _buildSummary(t, input, enabled, hasValue)),
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
            _CcSummaryChip(label: option.label, enabled: enabled),
        ],
      );
    }

    final count = values.length;
    final text = countLabel?.call(count) ?? '$count selected';
    return Text(
      text,
      style: CcTypography.bodySm.copyWith(
        color: enabled ? input.text : t.textDisabled,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _CcSummaryChip extends StatelessWidget {
  const _CcSummaryChip({required this.label, required this.enabled});

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
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
        child: Text(
          label,
          style: CcTypography.caption.copyWith(
            color: enabled ? t.textPrimary : t.textDisabled,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _CcMultiSelectRow<T> extends StatelessWidget {
  const _CcMultiSelectRow({
    required this.option,
    required this.checked,
    required this.onToggle,
  });

  final CcSelectOption<T> option;
  final bool checked;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

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
            : hovered
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
                if (option.icon != null) ...[
                  Icon(option.icon, size: 16, color: t.textSecondary),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
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
