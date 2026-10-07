import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'radius_scale.stories.g.dart';

/// Foundation stories for the **spacing**, **radius** and **elevation**
/// metric tokens (`AppSpacing`, `AppRadii`, `AppShadows` / `CcElevation`).
///
/// These are the rhythm of the design system: a tight 2→48 spacing scale, a
/// deliberately small radius set (2px default, 4px for cards/overlays) and two
/// shadows — `golden` (floating overlays) and `soft` (raised surfaces).

const _path = '[Foundations]/Tokens';

const component = ComponentMeta(name: 'RadiusScale', path: _path);

const meta = Meta(Showcase.new);

final $Scale = _Story(args: _Args.fixed(preview: radiusScaleStory));

Widget radiusScaleStory(BuildContext context) => const RadiusScale();

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
