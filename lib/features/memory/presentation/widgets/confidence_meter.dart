import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Semantic confidence color, shared by every memory surface so a fact reads
/// the same in the list, the graph and the detail sheet. High = success,
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
              alignment: AlignmentDirectional.centerStart,
              // `heightFactor` is what gives the fill a height: Align hands
              // down loose constraints, and an empty DecoratedBox takes the
              // smallest size it is offered, which is none at all.
              child: FractionallySizedBox(
                widthFactor: clamped == 0 ? 0.04 : clamped,
                heightFactor: 1,
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
        // A fixed slot in the code face: the tracks of a list line up whether
        // a row says 8% or 100%.
        SizedBox(
          width: compact ? null : 34,
          child: Text(
            '${(clamped * 100).round()}%',
            textAlign: TextAlign.end,
            style: CcFonts.code(
              textStyle: CcTypography.caption.copyWith(
                color: (tokens ?? DesignSystemTokens.light()).textTertiary,
              ),
            ),
          ),
        ),
      ],
    );

    if (compact) {
      return meter;
    }
    return CcTooltip(
      message: AppLocalizations.of(context).confidenceTooltip,
      child: meter,
    );
  }
}

/// A record's type glyph with its confidence along the bottom edge.
///
/// One mark for "what is this and how sure are we", so a list can be scanned
/// down its left edge. The fill's length and colour are the glance; the row
/// states the number in words beside it, so this never carries it alone.
class MemoryConfidenceMarker extends StatelessWidget {
  /// Creates a [MemoryConfidenceMarker].
  const MemoryConfidenceMarker({
    super.key,
    required this.icon,
    required this.confidence,
  });

  /// The record's glyph.
  final IconData icon;

  /// Confidence in the 0–1 range.
  final double confidence;

  static const double _size = 28;
  static const double _barHeight = 3;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final clamped = confidence.clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: _size,
        child: ColoredBox(
          color: t.hover,
          child: Column(
            children: [
              Expanded(
                child: Center(child: Icon(icon, size: 15, color: t.fgTertiary)),
              ),
              SizedBox(
                height: _barHeight,
                child: ColoredBox(
                  color: t.hover,
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: clamped == 0 ? 0.04 : clamped,
                      heightFactor: 1,
                      child: ColoredBox(
                        color: memoryConfidenceColor(context, confidence),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
