import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:flutter/widgets.dart';

/// Displays the age of a PR. The label warms with age via [ageColor] (neutral →
/// yellow → orange → red), then flips to a flat, semibold dark red once the PR
/// is stale ([isStaleAge], older than 30 days) so a long-unreviewed PR still
/// stands out.
class AgeText extends StatelessWidget {
  /// Creates an [AgeText].
  const AgeText({
    super.key,
    required this.ageText,
    required this.date,
    required this.neutral,
    required this.style,
  });

  /// Display text for the age (e.g. "3 days ago").
  final String ageText;

  /// The date this age is based on.
  final DateTime? date;

  /// Neutral color fallback when the age is fresh.
  final Color neutral;

  /// Text style override.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (isStaleAge(date)) {
      return Text(
        ageText,
        style: (style ?? const TextStyle()).copyWith(
          color: DesignSystemPalette.red800,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    return Text(
      ageText,
      style: style?.copyWith(color: ageColor(date, neutral: neutral)),
    );
  }
}
