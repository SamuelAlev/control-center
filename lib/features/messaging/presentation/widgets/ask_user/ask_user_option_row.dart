import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// Trailing index / submit mark. Fixed so swapping the numeral for the hover
/// arrow cannot change the row height. With [AppSpacing.sm] vertical padding
/// the slot sits inside the 44px row minimum (8 + 28 + 8).
const _trailingExtent = 28.0;

/// One numbered choice in an `AskUserCard`: label + optional description,
/// with a trailing index that becomes a submit arrow on hover for
/// single-select.
class AskUserOptionRow extends StatelessWidget {
  /// Creates an [AskUserOptionRow].
  const AskUserOptionRow({
    super.key,
    required this.index,
    required this.label,
    this.description,
    required this.selected,
    required this.multiSelect,
    required this.enabled,
    required this.onPressed,
  });

  /// 1-based keyboard index shown on the trailing edge.
  final int index;

  /// Bold lead-in for the choice.
  final String label;

  /// Optional muted explanation.
  final String? description;

  /// Whether this choice is currently selected (multi-select).
  final bool selected;

  /// Multi-select paints a boxed numeral; single-select paints a bare one
  /// that becomes an arrow on hover.
  final bool multiSelect;

  /// When false the row is inert (answered / submitting).
  final bool enabled;

  /// Activates the choice.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final duration = CcMotion.resolveFade(context, CcMotion.fast);

    return CcTappable(
      onPressed: enabled ? onPressed : null,
      semanticLabel: description == null || description!.isEmpty
          ? label
          : '$label. $description',
      semanticButton: true,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered) && enabled;
        final highlighted = selected || hovered;
        return AnimatedContainer(
          duration: duration,
          curve: CcMotion.standard,
          color: highlighted ? t.hoverStrong : const Color(0x00000000),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _LabelBlock(
                      label: label,
                      description: description,
                      tokens: t,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _TrailingMark(
                    index: index,
                    selected: selected,
                    hovered: hovered,
                    multiSelect: multiSelect,
                    tokens: t,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LabelBlock extends StatelessWidget {
  const _LabelBlock({
    required this.label,
    required this.description,
    required this.tokens,
  });

  final String label;
  final String? description;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final subtitle = description;
    if (subtitle == null || subtitle.isEmpty) {
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: label,
              style: CcTypography.body.copyWith(
                color: tokens.textPrimary,
                fontWeight: CcTypography.semiboldWeight,
              ),
            ),
          ],
        ),
      );
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: CcTypography.body.copyWith(
              color: tokens.textPrimary,
              fontWeight: CcTypography.semiboldWeight,
            ),
          ),
          TextSpan(
            text: ' $subtitle',
            style: CcTypography.body.copyWith(color: tokens.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _TrailingMark extends StatelessWidget {
  const _TrailingMark({
    required this.index,
    required this.selected,
    required this.hovered,
    required this.multiSelect,
    required this.tokens,
  });

  final int index;
  final bool selected;
  final bool hovered;
  final bool multiSelect;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final showArrow = !multiSelect && hovered;
    final numeral = Text(
      '$index',
      style: CcFonts.code(
        textStyle: CcTypography.monoNum.copyWith(
          color: selected ? tokens.bgPrimary : tokens.textTertiary,
          fontWeight: CcTypography.semiboldWeight,
        ),
      ),
    );

    return SizedBox(
      width: _trailingExtent,
      height: _trailingExtent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: showArrow || (multiSelect && selected)
              ? tokens.fg
              : const Color(0x00000000),
          border: multiSelect
              ? Border.all(color: selected ? tokens.fg : tokens.borderPrimary)
              : null,
        ),
        child: Center(
          child: showArrow
              ? Icon(AppIcons.arrowRight, size: 14, color: tokens.bgPrimary)
              : numeral,
        ),
      ),
    );
  }
}
