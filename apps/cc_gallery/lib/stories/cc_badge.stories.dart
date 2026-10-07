import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_badge.stories.g.dart';

/// Stories for [CcBadge] — the design system's small status pill.
///
/// Status is carried by tint *and* label text (and a leading icon), never color
/// alone, per the accessibility bar. The builders return the component directly;
/// the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcBadge', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcBadgePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    variant: EnumArg<CcBadgeVariant>(
      CcBadgeVariant.values.first,
      name: 'Variant',
      values: CcBadgeVariant.values,
    ),
    label: StringArg('Running', name: 'Label'),
    withIcon: BoolArg(true, name: 'Leading icon'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccBadgePlaygroundStory(context, args)),
);

final $Variants = _Story(args: _Args.fixed(preview: ccBadgeVariantsStory));

final $WithIcon = _Story(
  name: 'With icon',
  args: _Args.fixed(preview: ccBadgeWithIconStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcBadgePlayground {
  CcBadgePlayground({
    required this.variant,
    required this.label,
    required this.withIcon,
  });

  final CcBadgeVariant variant;
  final String label;
  final bool withIcon;
}

/// Every semantic variant side by side, labelled with real agent/PR states.
Widget ccBadgeVariantsStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcBadge(label: 'Idle'),
        CcBadge(label: 'Claude Opus', variant: CcBadgeVariant.brand),
        CcBadge(label: 'Merged', variant: CcBadgeVariant.success),
        CcBadge(label: 'Blocked', variant: CcBadgeVariant.warning),
        CcBadge(label: 'Failed', variant: CcBadgeVariant.danger),
        CcBadge(label: 'Draft', variant: CcBadgeVariant.info),
      ],
    ),
  );
}

/// Variants paired with a leading icon — the icon reinforces meaning so status
/// is legible without relying on tint.
Widget ccBadgeWithIconStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcBadge(
          label: 'Running',
          variant: CcBadgeVariant.success,
          icon: CcIcons.play,
        ),
        CcBadge(
          label: 'Review',
          variant: CcBadgeVariant.warning,
          icon: CcIcons.eye,
        ),
        CcBadge(
          label: 'Failed',
          variant: CcBadgeVariant.danger,
          icon: CcIcons.circleX,
        ),
        CcBadge(
          label: 'Workspace',
          variant: CcBadgeVariant.brand,
          icon: CcIcons.gitBranch,
        ),
        CcBadge(
          label: 'Synced',
          variant: CcBadgeVariant.info,
          icon: CcIcons.refreshCw,
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccBadgePlaygroundStory(
  BuildContext context,
  CcBadgePlaygroundArgs args,
) {
  final variant = args.variant;
  final label = args.label;
  final withIcon = args.withIcon;
  return Center(
    child: CcBadge(
      variant: variant,
      label: label,
      icon: withIcon ? CcIcons.activity : null,
    ),
  );
}
