import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Last-row free-text field for an [AskUserCard]: placeholder plus a trailing
/// index that becomes a submit arrow once there is text to send.
class AskUserFreeTextRow extends StatelessWidget {
  /// Creates an [AskUserFreeTextRow].
  const AskUserFreeTextRow({
    super.key,
    required this.index,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.enabled,
    required this.hasText,
    required this.showSubmitArrow,
    required this.onSubmit,
    this.onChanged,
  });

  /// 1-based keyboard index.
  final int index;

  /// Text being composed.
  final TextEditingController controller;

  /// Focus node for the field.
  final FocusNode focusNode;

  /// Empty-state hint.
  final String hintText;

  /// When false the field is read-only.
  final bool enabled;

  /// Whether [controller] currently has non-whitespace text.
  final bool hasText;

  /// Single-select: arrow appears when there is text (the row submits).
  final bool showSubmitArrow;

  /// Submits the typed answer.
  final VoidCallback onSubmit;

  /// Rebuilds the parent so the trailing mark can swap.
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final duration = CcMotion.resolveFade(context, CcMotion.fast);
    final highlighted = hasText || focusNode.hasFocus;

    return AnimatedContainer(
      duration: duration,
      curve: CcMotion.standard,
      color: highlighted ? t.hoverStrong : const Color(0x00000000),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(
            child: CcTextField(
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              chromeless: true,
              hintText: hintText,
              textStyle: CcTypography.body.copyWith(color: t.textPrimary),
              onChanged: onChanged,
              onSubmitted: enabled && hasText ? (_) => onSubmit() : null,
              textInputAction: TextInputAction.done,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (showSubmitArrow && hasText && enabled)
            CcTappable(
              onPressed: onSubmit,
              semanticLabel: hintText,
              builder: (context, states) => SizedBox(
                width: 28,
                height: 28,
                child: ColoredBox(
                  color: t.fg,
                  child: Icon(
                    AppIcons.arrowRight,
                    size: 14,
                    color: t.bgPrimary,
                  ),
                ),
              ),
            )
          else
            SizedBox(
              width: 28,
              child: Center(
                child: Text(
                  '$index',
                  style: CcFonts.code(
                    textStyle: CcTypography.monoNum.copyWith(
                      color: t.textTertiary,
                      fontWeight: CcTypography.semiboldWeight,
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
