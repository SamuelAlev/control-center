import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Semantic confidence color, shared by every memory surface so a fact reads
/// the same in the list, the graph, and the detail sheet. High = success,
/// mid = warning, low = error — paired with a number and a fill length, never
/// color alone (see DESIGN.md "Status-Never-Alone Rule").
Color memoryConfidenceColor(BuildContext context, double confidence) {
  final tokens = context.designSystem;
  if (confidence >= 0.8) {
    return tokens?.fgSuccessPrimary ?? const Color(0xFF079455);
  }
  if (confidence >= 0.5) {
    return tokens?.fgWarningPrimary ?? const Color(0xFFCA8504);
  }
  return tokens?.fgErrorPrimary ?? const Color(0xFFD92D20);
}

/// A compact confidence indicator: a filled track plus the percentage. The
/// fill length and the number both encode the value, so it survives grayscale
/// and color blindness.
class ConfidenceMeter extends StatelessWidget {
  /// Creates a [ConfidenceMeter].
  const ConfidenceMeter({
    super.key,
    required this.confidence,
    this.compact = false,
  });

  /// Confidence in the 0–1 range.
  final double confidence;

  /// Tighter sizing and no tooltip, for dense surfaces like graph nodes.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final color = memoryConfidenceColor(context, confidence);
    final clamped = confidence.clamp(0.0, 1.0);
    final trackWidth = compact ? 24.0 : 40.0;
    final trackHeight = compact ? 4.0 : 5.0;
    final track = tokens?.bgQuaternary ?? const Color(0xFFF2F0E9);

    final meter = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: track,
            borderRadius: BorderRadius.circular(trackHeight),
          ),
          child: SizedBox(
            width: trackWidth,
            height: trackHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: clamped == 0 ? 0.04 : clamped,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(trackHeight),
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: compact ? 5 : 6),
        Text(
          '${(clamped * 100).round()}%',
          style: (compact
                  ? context.theme.typography.xs
                  : context.theme.typography.sm)
              .copyWith(
            color: tokens?.textTertiary ?? context.theme.colors.mutedForeground,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );

    if (compact) {
      return meter;
    }
    return FTooltip(
      tipBuilder: (_, _) => Text(AppLocalizations.of(context).confidenceTooltip),
      child: meter,
    );
  }
}
