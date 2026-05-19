import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

/// The semantic tone of a live-state indicator. Maps a domain state to a color
/// family — kept abstract here so cc_ui stays free of app vocabulary and
/// localization. The caller resolves e.g. `connected → positive` and supplies a
/// localized label.
enum CcStatusTone {
  /// Up / connected / healthy / running.
  positive,

  /// Down / failed / errored / unhealthy.
  negative,

  /// Degraded / warning / pending.
  caution,

  /// Idle / stopped / unknown.
  neutral,

  /// Informational, no health connotation.
  info,
}

/// A small filled dot that signals a live state by color *and* is always paired
/// with a text label (never color-alone), per the accessibility bar in
/// DESIGN.md.
class CcStatusDot extends StatelessWidget {
  /// Creates a [CcStatusDot].
  const CcStatusDot({super.key, required this.tone, this.size = 8});

  /// The tone driving the dot color.
  final CcStatusTone tone;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _dotColor(t, tone),
        shape: BoxShape.circle,
      ),
    );
  }
}

/// Resolves the solid dot color for a [CcStatusTone].
Color _dotColor(DesignSystemTokens t, CcStatusTone tone) => switch (tone) {
  CcStatusTone.positive => t.success,
  CcStatusTone.negative => t.danger,
  CcStatusTone.caution => t.warn,
  CcStatusTone.neutral => t.fgQuaternary,
  CcStatusTone.info => t.accent,
};

/// Resolves the soft capsule fill for a [CcStatusTone].
Color _fillColor(DesignSystemTokens t, CcStatusTone tone) => switch (tone) {
  CcStatusTone.positive => t.successSoft,
  CcStatusTone.negative => t.dangerSoft,
  CcStatusTone.caution => t.warnSoft,
  CcStatusTone.neutral => t.bgSecondary,
  CcStatusTone.info => t.accentSoft,
};

/// Resolves the label text color for a [CcStatusTone].
Color _textColor(DesignSystemTokens t, CcStatusTone tone) => switch (tone) {
  CcStatusTone.positive => t.success,
  CcStatusTone.negative => t.danger,
  CcStatusTone.caution => t.warn,
  CcStatusTone.neutral => t.textTertiary,
  CcStatusTone.info => t.accent,
};

/// A live-state tag: a [CcStatusDot] + a short [label] inside a soft capsule.
///
/// Conveys connection / health / lifecycle states (`connected`, `failed`,
/// `running`, `stopped`, `healthy`, `unhealthy`, …) by tone *and* label *and* a
/// dot — three redundant cues so the state never rests on color alone. The
/// caller maps its domain state to a [CcStatusTone] and a localized [label].
class CcStatusTag extends StatelessWidget {
  /// Creates a [CcStatusTag].
  const CcStatusTag({
    super.key,
    required this.label,
    required this.tone,
    this.dot = true,
  });

  /// The localized state label (e.g. "Connected", "Stopped").
  final String label;

  /// The semantic tone driving the tint.
  final CcStatusTone tone;

  /// Whether to render the leading status dot.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _fillColor(t, tone),
        borderRadius: const BorderRadius.all(Radius.circular(AppRadii.pill)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot) ...[
              CcStatusDot(tone: tone, size: 7),
              const SizedBox(width: AppSpacing.xs),
            ],
            // A tag label never wraps: truncate with an ellipsis and let the
            // tooltip disclose the full text.
            Flexible(
              child: CcTruncatedText(
                label,
                style: CcTypography.label.copyWith(color: _textColor(t, tone)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
