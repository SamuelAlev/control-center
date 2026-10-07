import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'fluid_hover.stories.g.dart';

/// Foundation stories for the **motion** tokens (`CcMotion`).
///
/// Three enter speeds, a faster exit for each, and one fade kept under
/// reduced motion. No component invents its own timing.

const _path = '[Foundations]/Tokens';

const component = ComponentMeta(name: 'FluidHoverSpecimen', path: _path);

const meta = Meta(Showcase.new);

final $FluidHover = _Story(
  name: 'Fluid hover',
  args: _Args.fixed(preview: fluidHoverSpecimenStory),
);

Widget fluidHoverSpecimenStory(BuildContext context) {
  return const FluidHoverSpecimen();
}

/// Shows nearest-target hover motion across one- and two-dimensional layouts.
class FluidHoverSpecimen extends StatelessWidget {
  /// Creates the fluid-hover motion specimen.
  const FluidHoverSpecimen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Center(
      child: Wrap(
        spacing: AppSpacing.xl,
        runSpacing: AppSpacing.xl,
        children: [
          _Specimen(
            label: 'Vertical list',
            width: 260,
            child: CcFluidHover(
              itemCount: 4,
              layoutBuilder: (context, children) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    children[index],
                    if (index != children.length - 1)
                      const SizedBox(height: AppSpacing.xs),
                  ],
                ],
              ),
              itemBuilder: (context, index) => CcTile(
                title: 'Workspace ${index + 1}',
                leadingIcon: CcIcons.folder,
                onTap: () {},
              ),
            ),
          ),
          _Specimen(
            label: 'Horizontal strip',
            width: 360,
            child: CcFluidHover(
              itemCount: 4,
              axis: CcFluidHoverAxis.x,
              layoutBuilder: (context, children) => Row(
                children: [
                  for (var index = 0; index < children.length; index++) ...[
                    Expanded(child: children[index]),
                    if (index != children.length - 1)
                      const SizedBox(width: AppSpacing.xs),
                  ],
                ],
              ),
              itemBuilder: (context, index) => CcTappable(
                onPressed: () {},
                borderRadius: AppRadii.brSm,
                builder: (context, states) => SizedBox(
                  height: 40,
                  child: Center(
                    child: Text(
                      ['Overview', 'Activity', 'Runs', 'Files'][index],
                      style: CcTypography.label.copyWith(
                        color: t.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          _Specimen(
            label: 'Two-dimensional grid',
            width: 360,
            child: SizedBox(
              height: 184,
              child: CcFluidHover(
                itemCount: 6,
                axis: CcFluidHoverAxis.xy,
                borderRadius: AppRadii.brLg,
                layoutBuilder: (context, children) => GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 1.55,
                  children: children,
                ),
                itemBuilder: (context, index) => CcCard(
                  interactive: true,
                  onPressed: () {},
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(CcIcons.code, size: 18, color: t.textSecondary),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Repo ${index + 1}',
                        style: CcTypography.label.copyWith(
                          color: t.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Specimen extends StatelessWidget {
  const _Specimen({
    required this.label,
    required this.width,
    required this.child,
  });

  final String label;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: CcTypography.label.copyWith(color: t.textSecondary),
          ),
          AppSpacing.vGapSm,
          child,
        ],
      ),
    );
  }
}
