import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the **spacing**, **radius**, and **elevation**
/// metric tokens (`AppSpacing`, `AppRadii`, `AppShadows` / `CcElevation`).
///
/// These are the rhythm of the design system: a tight 2→48 spacing scale, a
/// deliberately small radius set (2px default, 4px for cards/overlays), and two
/// shadows — `golden` (floating overlays) and `soft` (raised surfaces).

const _path = '[Foundations]/Tokens';

@widgetbook.UseCase(name: 'Scale', type: SpacingScale, path: _path)
Widget spacingScaleUseCase(BuildContext context) => const SpacingScale();

@widgetbook.UseCase(name: 'Scale', type: RadiusScale, path: _path)
Widget radiusScaleUseCase(BuildContext context) => const RadiusScale();

@widgetbook.UseCase(name: 'Shadows', type: ElevationScale, path: _path)
Widget elevationScaleUseCase(BuildContext context) => const ElevationScale();

/// Specimen: the [AppSpacing] step scale rendered as accent bars.
class SpacingScale extends StatelessWidget {
  /// Creates a [SpacingScale] specimen.
  const SpacingScale({super.key});

  static const _steps = <(String, double)>[
    ('xxs', AppSpacing.xxs),
    ('xs', AppSpacing.xs),
    ('sm', AppSpacing.sm),
    ('md', AppSpacing.md),
    ('lg', AppSpacing.lg),
    ('xl', AppSpacing.xl),
    ('xxl', AppSpacing.xxl),
    ('xxxl', AppSpacing.xxxl),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final step in _steps)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      step.$1,
                      style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                    ),
                  ),
                  Container(width: step.$2, height: 16, color: t.accent),
                  AppSpacing.hGapSm,
                  Text(
                    '${step.$2.toStringAsFixed(0)}px',
                    style: CcTypography.monoNum.copyWith(color: t.textTertiary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Specimen: the [AppRadii] corner-radius set.
class RadiusScale extends StatelessWidget {
  /// Creates a [RadiusScale] specimen.
  const RadiusScale({super.key});

  static const _radii = <(String, BorderRadius)>[
    ('brXs · 2', AppRadii.brXs),
    ('brSm · 2', AppRadii.brSm),
    ('brMd · 2', AppRadii.brMd),
    ('brLg · 4', AppRadii.brLg),
    ('brXl · 4', AppRadii.brXl),
    ('pill · 999', BorderRadius.all(Radius.circular(AppRadii.pill))),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.xl,
        children: [
          for (final r in _radii)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 56,
                  decoration: BoxDecoration(
                    color: t.surface,
                    borderRadius: r.$2,
                    border: Border.all(color: t.borderPrimary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  r.$1,
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Specimen: the [CcElevation] shadows + the overlay z-index scale.
class ElevationScale extends StatelessWidget {
  /// Creates an [ElevationScale] specimen.
  const ElevationScale({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;

    Widget card(String label, List<BoxShadow> shadow) => Container(
          width: 200,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: t.borderPrimary),
            boxShadow: shadow,
          ),
          child: Text(label, style: CcTypography.bodySm.copyWith(color: t.textPrimary)),
        );

    const z = <(String, int)>[
      ('tooltip', CcElevation.tooltip),
      ('popover / dropdown', CcElevation.popover),
      ('menu', CcElevation.menu),
      ('toast', CcElevation.toast),
      ('dialog', CcElevation.dialog),
    ];

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xxl,
            runSpacing: AppSpacing.xxl,
            children: [
              card('floating · golden', CcElevation.floating),
              card('raised · soft', CcElevation.raised),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(
            'Z-INDEX SCALE',
            style: CcTypography.label.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final layer in z)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      '${layer.$2}',
                      style: CcTypography.monoNum.copyWith(color: t.accent),
                    ),
                  ),
                  Text(
                    layer.$1,
                    style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
