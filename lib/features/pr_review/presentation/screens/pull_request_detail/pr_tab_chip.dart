import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A small pill count badge.
class CountBadge extends StatelessWidget {
  /// Creates a [CountBadge].
  const CountBadge({super.key, required this.count, this.selected = false});

  /// Number to display in the badge.
  final int count;

  /// Whether the parent tab is selected — drives the badge fill.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: selected ? t.bgPrimary : t.bgSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: DefaultTextStyle.merge(
        style: TextStyle(
          fontSize: 11,
          color: selected ? t.textPrimary : t.textTertiary,
          fontWeight: FontWeight.w700,
        ),
        child: Text('$count'),
      ),
    );
  }
}
