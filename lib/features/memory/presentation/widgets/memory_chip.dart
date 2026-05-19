import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

/// Tone of a [MemoryMetaChip].
enum MemoryChipTone {
  /// Quiet neutral metadata (topic, role, source id).
  neutral,

  /// Error-tinted, for "superseded"-style states.
  error,
}

/// Quiet metadata chip used across the memory surfaces: neutral fill, hairline
/// border, secondary text. Keeps Command Blue reserved for action and
/// selection instead of spending it on category labels.
class MemoryMetaChip extends StatelessWidget {
  /// Creates a [MemoryMetaChip].
  const MemoryMetaChip({
    super.key,
    required this.label,
    this.icon,
    this.tone = MemoryChipTone.neutral,
    this.monospace = false,
  });

  /// Chip text.
  final String label;

  /// Optional leading glyph.
  final IconData? icon;

  /// Visual tone.
  final MemoryChipTone tone;

  /// Render the label in the mono family (for ids / SHAs).
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final isError = tone == MemoryChipTone.error;
    final bg = isError ? tokens.bgErrorPrimary : tokens.bgSecondary;
    final border = isError ? tokens.borderErrorSubtle : tokens.borderSecondary;
    final fg = isError ? tokens.textErrorPrimary : tokens.textTertiary;
    final typography = context.theme.typography;
    final textStyle = (monospace ? typography.xs.copyWith(fontFamily: 'monospace') : typography.xs)
        .copyWith(color: fg, fontWeight: FontWeight.w600);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle,
            ),
          ),
        ],
      ),
    );
  }
}
