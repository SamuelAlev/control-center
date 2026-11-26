import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A small fact for `SettingsEntityRow.meta`.
///
/// Most are numbers — a version, a count, a size, a price — so the value takes
/// the UI face with tabular figures. A machine string (a hash, a fingerprint,
/// a transport id) sets [code] and takes the code face instead.
class SettingsMetaFact extends StatelessWidget {
  /// Creates a [SettingsMetaFact].
  const SettingsMetaFact({
    super.key,
    required this.value,
    this.label,
    this.icon,
    this.code = false,
  });

  /// The value.
  final String value;

  /// Optional word before it ("context", "installed").
  final String? label;

  /// Optional leading glyph.
  final IconData? icon;

  /// Renders the value in the code face, for machine strings.
  final bool code;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final valueStyle = CcTypography.caption.copyWith(color: t.textSecondary);
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
          style: code
              ? CcFonts.code(textStyle: valueStyle)
              : CcFonts.numeric(textStyle: valueStyle),
        ),
      ],
    );
  }
}
