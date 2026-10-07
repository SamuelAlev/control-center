import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'spacing_scale.stories.g.dart';

/// Foundation stories for the **spacing**, **radius** and **elevation**
/// metric tokens (`AppSpacing`, `AppRadii`, `AppShadows` / `CcElevation`).
///
/// These are the rhythm of the design system: a tight 2→48 spacing scale, a
/// deliberately small radius set (2px default, 4px for cards/overlays) and two
/// shadows — `golden` (floating overlays) and `soft` (raised surfaces).

const _path = '[Foundations]/Tokens';

const component = ComponentMeta(name: 'SpacingScale', path: _path);

const meta = Meta(Showcase.new);

final $Scale = _Story(args: _Args.fixed(preview: spacingScaleStory));

Widget spacingScaleStory(BuildContext context) => const SpacingScale();

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
                      style: CcTypography.bodySm.copyWith(
                        color: t.textSecondary,
                      ),
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
