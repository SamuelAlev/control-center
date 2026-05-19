import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// A single segmented tab chip. Selected chips get a filled rounded background;
/// the rest are transparent. Mirrors the tab style used on the workspace and
/// ticket detail pages, and drives the Diff tab's Files/Commits sub-strip.
class PrTabChip extends StatelessWidget {
  /// Creates a [PrTabChip].
  const PrTabChip({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    this.fontSize = 14,
  });

  /// Leading glyph.
  final IconData icon;

  /// Chip label.
  final String label;

  /// Whether this chip is the active tab.
  final bool selected;

  /// Tap handler.
  final VoidCallback onTap;

  /// Optional trailing count badge.
  final int? count;

  /// Label font size — dial down for secondary chips (e.g. the Diff toolbar's
  /// tree toggle) that shouldn't weigh as much as the tab strip.
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = selected ? t.textPrimary : t.textTertiary;
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? t.bgSecondary : const Color(0x00000000),
          borderRadius: AppRadii.brSm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
            DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: fontSize,
                color: fg,
                fontWeight: FontWeight.w600,
              ),
              child: Text(label),
            ),
            if (count != null) ...[
              const SizedBox(width: 6),
              CountBadge(count: count!, selected: selected),
            ],
          ],
        ),
      ),
    );
  }
}

/// A small pill count badge, tuned to stay legible on a selected [PrTabChip].
class CountBadge extends StatelessWidget {
  /// Creates a [CountBadge].
  const CountBadge({super.key, required this.count, this.selected = false});

  /// Number to display in the badge.
  final int count;

  /// Whether the parent tab chip is selected — drives the badge fill.
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
