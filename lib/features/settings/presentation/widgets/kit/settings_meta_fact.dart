import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A small mono fact for `SettingsEntityRow.meta`.
///
/// Mono because these are machine truths — a version, a count, a path, a price
/// — and the design system reserves Fira Code for exactly that.
class SettingsMetaFact extends StatelessWidget {
  /// Creates a [SettingsMetaFact].
  const SettingsMetaFact({
    super.key,
    required this.value,
    this.label,
    this.icon,
  });

  /// The machine value.
  final String value;

  /// Optional word before it ("context", "installed").
  final String? label;

  /// Optional leading glyph.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: t.fgQuaternary),
          const SizedBox(width: AppSpacing.xs),
        ],
        if (label != null) ...[
          Text(
            label!,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
        Text(
          value,
          style: CcFonts.code(
            textStyle: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ),
      ],
    );
  }
}
