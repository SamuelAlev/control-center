import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'elevation_scale.stories.g.dart';

/// Foundation stories for the **spacing**, **radius** and **elevation**
/// metric tokens (`AppSpacing`, `AppRadii`, `AppShadows` / `CcElevation`).
///
/// These are the rhythm of the design system: a tight 2→48 spacing scale, a
/// deliberately small radius set (2px default, 4px for cards/overlays) and two
/// shadows — `golden` (floating overlays) and `soft` (raised surfaces).

const _path = '[Foundations]/Tokens';

const component = ComponentMeta(name: 'ElevationScale', path: _path);

const meta = Meta(Showcase.new);

final $Shadows = _Story(args: _Args.fixed(preview: elevationScaleStory));

Widget elevationScaleStory(BuildContext context) => const ElevationScale();

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
      child: Text(
        label,
        style: CcTypography.bodySm.copyWith(color: t.textPrimary),
      ),
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
