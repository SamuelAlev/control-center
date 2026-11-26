import 'dart:math' as math;

import 'package:cc_ui/src/components/cc_hit_target.dart';
import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_spinner.dart';
import 'package:cc_ui/src/components/cc_tooltip.dart';
import 'package:cc_ui/src/components/cc_truncated_text.dart';
import 'package:cc_ui/src/foundation/cc_motion.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// A tag whose fill is a forge-assigned hex color (GitHub/GitLab labels),
/// optionally carrying a color-matched ghost remove button via [onRemove].
///
/// Status never rests on color alone: the [label] is always visible, and ink
/// is picked for WCAG contrast against that fill. Square corners match
/// [CcChip]. An empty or unparseable [color] falls back to the muted secondary
/// fill so a names-only payload still renders a chip.
class CcColorTag extends StatelessWidget {
  /// Creates a [CcColorTag].
  const CcColorTag({
    super.key,
    required this.label,
    this.color = '',
    this.tooltip,
    this.compact = false,
    this.onRemove,
    this.removing = false,
    this.removeSemanticLabel,
    this.trailing,
  }) : assert(
         trailing == null || (onRemove == null && !removing),
         'Pass either onRemove/removing or trailing, not both.',
       );

  /// The tag's text (`bug`, `dependencies`).
  final String label;

  /// 6-digit sRGB hex, with or without a leading `#`. Empty when unknown.
  final String color;

  /// Optional hover disclosure (the forge's label description). When null,
  /// a truncated [label] still discloses itself via [CcTruncatedText].
  final String? tooltip;

  /// Tighter padding and type for dense rows (inbox, activity feed).
  final bool compact;

  /// When non-null, renders an always-visible small ghost `×` button at the
  /// trailing edge of the tag matching the tag's foreground ink.
  final VoidCallback? onRemove;

  /// When true, replaces the `×` glyph with a small spinner colored with the
  /// tag's ink inside the same button box while disabling taps.
  final bool removing;

  /// Optional accessible name override for the remove button. Defaults to
  /// `CcStrings.remove(label)`.
  final String? removeSemanticLabel;

  /// Optional custom control drawn inside the tag after the [label]. Icons
  /// inherit the tag's ink through [IconTheme].
  final Widget? trailing;

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
    final Color ghostHover;
    final Color ghostPressed;
    if (parsed == null) {
      background = t.bgSecondary;
      foreground = t.textTertiary;
      border = t.borderSecondary;
      ghostHover = t.hover;
      ghostPressed = t.hoverStrong;
    } else {
      background = parsed;
      foreground = inkOn(parsed);
      border = foreground.withValues(alpha: 0.14);
      ghostHover = foreground.withValues(alpha: 0.16);
      ghostPressed = foreground.withValues(alpha: 0.26);
    }

    final padH = compact ? AppSpacing.xs : AppSpacing.sm;
    final padV = compact ? AppSpacing.xxs : AppSpacing.xs;
    final fontSize = compact ? 11.0 : 12.0;

    final text = CcTruncatedText(
      label,
      style: TextStyle(
        fontSize: fontSize,
        height: 1.3,
        fontWeight: CcTypography.regularWeight,
        color: foreground,
      ),
    );

    final hasRemove = onRemove != null || removing;
    final Widget content;
    if (hasRemove) {
      final buttonPad = compact ? 1.0 : AppSpacing.xxs;
      content = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                padH,
                padV,
                AppSpacing.xxs,
                padV,
              ),
              child: text,
            ),
          ),
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              0,
              buttonPad,
              buttonPad,
              buttonPad,
            ),
            child: _TagRemoveButton(
              foreground: foreground,
              ghostHover: ghostHover,
              ghostPressed: ghostPressed,
              compact: compact,
              removing: removing,
              semanticLabel:
                  removeSemanticLabel ?? context.ccStrings.remove(label),
              onPressed: onRemove,
            ),
          ),
        ],
      );
    } else if (trailing != null) {
      content = Padding(
        padding: EdgeInsetsDirectional.fromSTEB(padH, padV, AppSpacing.xxs, padV),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: text),
            const SizedBox(width: AppSpacing.xxs),
            IconTheme.merge(
              data: IconThemeData(color: foreground),
              child: trailing!,
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: EdgeInsetsDirectional.symmetric(horizontal: padH, vertical: padV),
        child: text,
      );
    }

    Widget chip = Semantics(
      label: label,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: border),
        ),
        child: content,
      ),
    );

    final tip = tooltip?.trim();
    if (tip != null && tip.isNotEmpty) {
      chip = CcTooltip(message: tip, child: chip);
    }
    return chip;
  }
}

class _TagRemoveButton extends StatelessWidget {
  const _TagRemoveButton({
    required this.foreground,
    required this.ghostHover,
    required this.ghostPressed,
    required this.compact,
    required this.removing,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Color foreground;
  final Color ghostHover;
  final Color ghostPressed;
  final bool compact;
  final bool removing;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final boxSize = compact ? 16.0 : 20.0;
    final iconSize = compact ? 10.0 : 12.0;
    final spinnerSize = compact ? 9.0 : 10.0;

    // The glyph box is 16/20px; the target reaches 24px into the tag's
    // padding without moving the layout.
    return CcHitTarget(
      child: CcTappable(
        onPressed: removing ? null : onPressed,
        focusableWhenDisabled: removing,
        borderRadius: AppRadii.brSm,
        semanticLabel: semanticLabel,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          final pressed = states.contains(WidgetState.pressed);
          final focused = states.contains(WidgetState.focused);

          final Color bg;
          if (removing) {
            bg = ghostHover.withValues(alpha: 0);
          } else if (pressed) {
            bg = ghostPressed;
          } else if (hovered) {
            bg = ghostHover;
          } else {
            bg = ghostHover.withValues(alpha: 0);
          }
          final iconColor = hovered || pressed || focused
              ? foreground
              : foreground.withValues(alpha: 0.85);

          Widget child = AnimatedContainer(
            duration: CcMotion.resolveFade(context, CcMotion.fast),
            curve: CcMotion.standard,
            width: boxSize,
            height: boxSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: bg, borderRadius: AppRadii.brSm),
            child: removing
                ? CcSpinner(
                    size: spinnerSize,
                    strokeWidth: 1.5,
                    color: foreground,
                  )
                : ExcludeSemantics(
                    child: Icon(CcIcons.x, size: iconSize, color: iconColor),
                  ),
          );

          if (pressed && !removing) {
            child = Transform.translate(
              offset: const Offset(0, 1),
              child: child,
            );
          }
          return child;
        },
      ),
    );
  }
}
