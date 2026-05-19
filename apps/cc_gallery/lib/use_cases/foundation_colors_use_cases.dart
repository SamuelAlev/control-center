import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the design system's **color tokens**.
///
/// Every swatch is read live from `context.designSystem` (the active
/// [DesignSystemTokens]), so switching the gallery's Light/Dark theme addon
/// repaints the whole palette — the canonical way to audit both themes.

const _path = '[Foundations]/Tokens';

/// The curated semantic aliases the product surfaces use day-to-day — the warm
/// near-white / ink-black / single-orange system.
@widgetbook.UseCase(name: 'Semantic palette', type: ColorTokens, path: _path)
Widget colorSemanticUseCase(BuildContext context) {
  final t = context.designSystem!;
  return ColorTokens(
    sections: {
      'Surfaces': [
        ('canvas', t.canvas),
        ('surface', t.surface),
        ('panel', t.panel),
        ('sidebar', t.sidebar),
        ('topbar', t.topbar),
        ('rail', t.rail),
        ('bgOverlay', t.bgOverlay),
      ],
      'Ink & lines': [
        ('fg', t.fg),
        ('muted', t.muted),
        ('idle', t.idle),
        ('borderPrimary', t.borderPrimary),
        ('borderSoft', t.borderSoft),
        ('lineStrong', t.lineStrong),
      ],
      'Interaction': [
        ('hover', t.hover),
        ('hoverStrong', t.hoverStrong),
        ('focusRing', t.focusRing),
      ],
      'Accent (orange)': [
        ('accent', t.accent),
        ('accentHover', t.accentHover),
        ('accentActive', t.accentActive),
        ('accentSoft', t.accentSoft),
        ('accentOn', t.accentOn),
      ],
      'Status': [
        ('success', t.success),
        ('successSoft', t.successSoft),
        ('warn', t.warn),
        ('warnSoft', t.warnSoft),
        ('danger', t.danger),
        ('dangerSoft', t.dangerSoft),
        ('brightYellow', t.brightYellow),
        ('blockEdge', t.blockEdge),
      ],
    },
  );
}

/// The full role scale (backgrounds / text / foreground / borders / feedback)
/// mirroring the design-source CSS variable families.
@widgetbook.UseCase(name: 'Roles & scale', type: ColorTokens, path: _path)
Widget colorRolesUseCase(BuildContext context) {
  final t = context.designSystem!;
  return ColorTokens(
    sections: {
      'Background': [
        ('bgPrimary', t.bgPrimary),
        ('bgSecondary', t.bgSecondary),
        ('bgTertiary', t.bgTertiary),
        ('bgQuaternary', t.bgQuaternary),
        ('bgActive', t.bgActive),
        ('bgDisabled', t.bgDisabled),
        ('bgBrandPrimary', t.bgBrandPrimary),
        ('bgBrandSolid', t.bgBrandSolid),
      ],
      'Text': [
        ('textPrimary', t.textPrimary),
        ('textSecondary', t.textSecondary),
        ('textTertiary', t.textTertiary),
        ('textPlaceholder', t.textPlaceholder),
        ('textDisabled', t.textDisabled),
        ('textBrandPrimary', t.textBrandPrimary),
      ],
      'Foreground (icons)': [
        ('fgPrimary', t.fgPrimary),
        ('fgSecondary', t.fgSecondary),
        ('fgTertiary', t.fgTertiary),
        ('fgQuaternary', t.fgQuaternary),
        ('fgDisabled', t.fgDisabled),
        ('fgBrandPrimary', t.fgBrandPrimary),
      ],
      'Border': [
        ('borderPrimary', t.borderPrimary),
        ('borderSecondary', t.borderSecondary),
        ('borderTertiary', t.borderTertiary),
        ('borderDisabled', t.borderDisabled),
        ('borderBrand', t.borderBrand),
        ('borderError', t.borderError),
      ],
      'Feedback': [
        ('bgErrorPrimary', t.bgErrorPrimary),
        ('fgErrorPrimary', t.fgErrorPrimary),
        ('bgWarningPrimary', t.bgWarningPrimary),
        ('fgWarningPrimary', t.fgWarningPrimary),
        ('bgSuccessPrimary', t.bgSuccessPrimary),
        ('fgSuccessPrimary', t.fgSuccessPrimary),
      ],
    },
  );
}

/// Renders named color [sections] as labelled swatch grids. A specimen widget
/// (not an app component) — it exists so the color tokens have a navigable
/// home in the gallery.
class ColorTokens extends StatelessWidget {
  /// Creates a [ColorTokens] specimen for the given [sections].
  const ColorTokens({required this.sections, super.key});

  /// Ordered map of section label → list of `(token name, color)` pairs.
  final Map<String, List<(String, Color)>> sections;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final entry in sections.entries) ...[
            Text(
              entry.key.toUpperCase(),
              style: CcTypography.label.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.lg,
              children: [
                for (final swatch in entry.value)
                  _Swatch(name: swatch.$1, color: swatch.$2),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ],
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return SizedBox(
      width: 116,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 56,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: t.borderPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(name, style: CcTypography.caption.copyWith(color: t.textSecondary)),
          Text(
            _hex(color),
            style: CcTypography.monoNum.copyWith(
              color: t.textTertiary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  static String _hex(Color c) {
    int ch(double v) => (v * 255).round() & 0xff;
    final r = ch(c.r).toRadixString(16).padLeft(2, '0');
    final g = ch(c.g).toRadixString(16).padLeft(2, '0');
    final b = ch(c.b).toRadixString(16).padLeft(2, '0');
    return '#$r$g$b'.toUpperCase();
  }
}
