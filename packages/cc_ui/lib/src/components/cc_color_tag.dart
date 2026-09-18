import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// A read-only tag whose fill is a forge-assigned hex color (GitHub/GitLab
/// labels). Status never rests on color alone: the [label] is always visible,
/// and ink is picked for WCAG contrast against that fill.
///
/// Square corners match [CcChip]. An empty or unparseable [color] falls back
/// to the muted secondary fill so a names-only payload still renders a chip.
class CcColorTag extends StatelessWidget {
  /// Creates a [CcColorTag].
  const CcColorTag({
    super.key,
    required this.label,
    this.color = '',
    this.tooltip,
    this.compact = false,
  });

  /// The tag's text (`bug`, `dependencies`).
  final String label;

  /// 6-digit sRGB hex, with or without a leading `#`. Empty when unknown.
  final String color;

  /// Optional hover disclosure (the forge's label description). When null,
  /// a truncated [label] still discloses itself via [CcTruncatedText].
  final String? tooltip;

  /// Tighter padding and type for dense rows (inbox, activity feed).
  final bool compact;

  /// Parses a 3- or 6-digit hex (optional `#`) into an opaque sRGB color.
  static Color? parseHex(String raw) {
    var hex = raw.trim();
    if (hex.startsWith('#')) {
      hex = hex.substring(1);
    }
    if (hex.length == 3) {
      hex = '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}';
    }
    if (hex.length != 6) {
      return null;
    }
    final value = int.tryParse(hex, radix: 16);
    if (value == null) {
      return null;
    }
    return Color(0xFF000000 | value);
  }

  /// Picks white or near-black ink for [background] by WCAG relative
  /// luminance, so a mid yellow (`#ffff00`) stays readable.
  static Color inkOn(Color background) {
    final luminance = _relativeLuminance(background);
    final white = 1.05 / (luminance + 0.05);
    final black = (luminance + 0.05) / 0.05;
    return white >= black ? const Color(0xFFFFFFFF) : const Color(0xFF0D0D0D);
  }

  static double _relativeLuminance(Color c) {
    double linear(double channel) => channel <= 0.04045
        ? channel / 12.92
        : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final parsed = parseHex(color);
    final Color background;
    final Color foreground;
    final Color border;
    if (parsed == null) {
      background = t.bgSecondary;
      foreground = t.textTertiary;
      border = t.borderSecondary;
    } else {
      background = parsed;
      foreground = inkOn(parsed);
      border = foreground.withValues(alpha: 0.14);
    }

    final padH = compact ? AppSpacing.xs : AppSpacing.sm;
    final padV = compact ? AppSpacing.xxs : AppSpacing.xs;
    final fontSize = compact ? 11.0 : 12.0;

    Widget chip = Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: border),
        ),
        child: Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: padH,
            vertical: padV,
          ),
          child: CcTruncatedText(
            label,
            style: TextStyle(
              fontSize: fontSize,
              height: 1.3,
              fontWeight: CcTypography.regularWeight,
              color: foreground,
            ),
          ),
        ),
      ),
    );

    final tip = tooltip?.trim();
    if (tip != null && tip.isNotEmpty) {
      chip = CcTooltip(message: tip, child: chip);
    }
    return chip;
  }
}
