import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_alert.stories.g.dart';

/// Stories for [CcAlert] — an inline banner that surfaces a status message in
/// flow. Intent reads from the icon, tint and copy together (never color
/// alone). The builders return the component directly — the gallery's theme
/// addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcAlert', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcAlertPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    variant: EnumArg<CcAlertVariant>(
      CcAlertVariant.values.first,
      name: 'Variant',
      values: CcAlertVariant.values,
    ),
    title: StringArg('Workspace seeded', name: 'Title'),
    description: StringArg(
      'The CEO agent created three starter tickets.',
      name: 'Description',
    ),
    withIcon: BoolArg(true, name: 'Leading icon'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccAlertPlaygroundStory(context, args)),
);

final $ActionPlacement = _Story(
  name: 'Action placement',
  args: _Args.fixed(preview: ccAlertActionPlacementStory),
);

final $TitleAndDescription = _Story(
  name: 'Title and description',
  args: _Args.fixed(preview: ccAlertTitleAndDescriptionStory),
);

final $Variants = _Story(args: _Args.fixed(preview: ccAlertVariantsStory));

final $WithAndWithoutIcon = _Story(
  name: 'With and without icon',
  args: _Args.fixed(preview: ccAlertWithIconStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcAlertPlayground {
  CcAlertPlayground({
    required this.variant,
    required this.title,
    required this.description,
    required this.withIcon,
  });

  final CcAlertVariant variant;
  final String title;
  final String description;
  final bool withIcon;
}

/// Every semantic variant stacked, each with a matching icon glyph.
Widget ccAlertVariantsStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(
            title: 'Heads up',
            description: Text(
              'Claude Opus is the default model for new agents.',
            ),
            icon: CcIcons.info,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Workspace synced',
            description: Text('All worktrees are up to date with origin/main.'),
            variant: CcAlertVariant.success,
            icon: CcIcons.circleCheck,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Budget threshold crossed',
            description: Text(
              'This agent has used 80% of its daily token budget.',
            ),
            variant: CcAlertVariant.warning,
            icon: CcIcons.triangleAlert,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Failed to open pull request',
            description: Text(
              'GitHub returned 422 — the branch has no commits.',
            ),
            variant: CcAlertVariant.danger,
            icon: CcIcons.circleX,
          ),
        ],
      ),
    ),
  );
}

/// Title-only banners versus title with a supporting description.
Widget ccAlertTitleAndDescriptionStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(title: 'Agent dispatched'),
          SizedBox(height: 12),
          CcAlert(
            title: 'Agent dispatched',
            description: Text('Reviewer is reading the diff on PR #482.'),
          ),
        ],
      ),
    ),
  );
}

/// Without and with a leading status icon, to show the optional glyph slot.
Widget ccAlertWithIconStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(
            title: 'Pipeline complete',
            description: Text('The release pipeline finished in 4m 12s.'),
            variant: CcAlertVariant.success,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Pipeline complete',
            description: Text('The release pipeline finished in 4m 12s.'),
            variant: CcAlertVariant.success,
            icon: CcIcons.circleCheck,
          ),
        ],
      ),
    ),
  );
}

/// The two action slots side by side: [CcAlert.action] takes its own line
/// below the body (the action IS the point), while [CcAlert.trailing] rides
/// the banner's edge and costs no extra height (a standing caveat above a list
/// the reader actually came for). With a trailing control the close (×) moves
/// out beside it so the dismiss affordance stays outermost.
Widget ccAlertActionPlacementStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(
            title: 'Budget threshold crossed',
            description: const Text(
              'This agent has used 80% of its daily token budget.',
            ),
            variant: CcAlertVariant.warning,
            action: CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () {},
              child: const Text('Raise the budget'),
            ),
          ),
          const SizedBox(height: 12),
          CcAlert(
            title: 'GitHub is reporting problems',
            description: const Text(
              'GitHub status: Outage. Pull request data may be stale or '
              'incomplete until it recovers.',
            ),
            variant: CcAlertVariant.danger,
            trailing: CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: () {},
              child: const Text('Open githubstatus.com'),
            ),
            onClose: () {},
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccAlertPlaygroundStory(
  BuildContext context,
  CcAlertPlaygroundArgs args,
) {
  final variant = args.variant;
  final title = args.title;
  final description = args.description;
  final withIcon = args.withIcon;
  return Center(
    child: SizedBox(
      width: 420,
      child: CcAlert(
        variant: variant,
        title: title,
        description: description.isEmpty ? null : Text(description),
        icon: withIcon ? CcIcons.bell : null,
      ),
    ),
  );
}
