import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_empty_state.stories.g.dart';

/// Stories for [CcEmptyState] — the design system's centered "nothing here yet"
/// surface. Stacks a muted icon, a primary message, an optional teaching
/// description and an optional action widget.
///
/// Builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcEmptyState', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcEmptyStatePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    message: StringArg('No pipelines configured', name: 'Message'),
    description: StringArg(
      'Pipelines automate multi-agent work across your repos. Add one to '
      'get started.',
      name: 'Description',
    ),
    withDescription: BoolArg(true, name: 'Show description'),
    withAction: BoolArg(false, name: 'Show action'),
    size: EnumArg<CcEmptyStateSize>(
      CcEmptyStateSize.values.first,
      name: 'Size',
      values: CcEmptyStateSize.values,
    ),
    iconSize: DoubleArg(
      48,
      name: 'Icon size',
      style: const SliderDoubleArgStyle(min: 24, max: 96, divisions: 72),
    ),
    maxWidth: DoubleArg(
      320,
      name: 'Max width',
      style: const SliderDoubleArgStyle(min: 200, max: 520, divisions: 80),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccEmptyStatePlaygroundStory(context, args),
  ),
);

final $Compact = _Story(args: _Args.fixed(preview: ccEmptyStateCompactStory));

final $MessageOnly = _Story(
  name: 'Message only',
  args: _Args.fixed(preview: ccEmptyStateMessageOnlyStory),
);

final $WithAction = _Story(
  name: 'With action',
  args: _Args.fixed(preview: ccEmptyStateWithActionStory),
);

final $WithDescription = _Story(
  name: 'With description',
  args: _Args.fixed(preview: ccEmptyStateWithDescriptionStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcEmptyStatePlayground {
  CcEmptyStatePlayground({
    required this.message,
    required this.description,
    required this.withDescription,
    required this.withAction,
    required this.size,
    required this.iconSize,
    required this.maxWidth,
  });

  final String message;
  final String description;
  final bool withDescription;
  final bool withAction;
  final CcEmptyStateSize size;
  final double iconSize;
  final double maxWidth;
}

void _noop() {}

/// Just the icon and message — the minimal empty surface.
Widget ccEmptyStateMessageOnlyStory(BuildContext context) {
  return const CcEmptyState(icon: CcIcons.inbox, message: 'No pull requests');
}

/// Nested-card density — body-sized copy, small icon.
Widget ccEmptyStateCompactStory(BuildContext context) {
  return const CcEmptyState(
    icon: CcIcons.lock,
    size: CcEmptyStateSize.sm,
    message:
        'No decisions recorded yet. You\'ll be asked the first time an agent '
        'needs to run a program from its working copy.',
  );
}

/// Icon, message and a teaching description line.
Widget ccEmptyStateWithDescriptionStory(BuildContext context) {
  return const CcEmptyState(
    icon: CcIcons.gitPullRequest,
    message: 'No open pull requests',
    description:
        'When an agent opens a PR in this workspace, it will show up here '
        'for review.',
  );
}

/// The full layout — icon, message, description and a primary action.
Widget ccEmptyStateWithActionStory(BuildContext context) {
  return const CcEmptyState(
    icon: CcIcons.boxes,
    message: 'No workspaces yet',
    description:
        'Create a workspace to give your agents an isolated Git worktree to '
        'work in.',
    action: CcButton(
      icon: CcIcons.plus,
      onPressed: _noop,
      child: Text('Create workspace'),
    ),
  );
}

/// Interactive playground — drive every prop to explore the state space.
Widget ccEmptyStatePlaygroundStory(
  BuildContext context,
  CcEmptyStatePlaygroundArgs args,
) {
  final message = args.message;
  final description = args.description;
  final withDescription = args.withDescription;
  final withAction = args.withAction;
  final size = args.size;
  final iconSize = args.iconSize;
  final maxWidth = args.maxWidth;
  return CcEmptyState(
    icon: CcIcons.workflow,
    size: size,
    message: message,
    description: withDescription ? description : null,
    iconSize: iconSize,
    maxWidth: maxWidth,
    action: withAction
        ? const CcButton(
            icon: CcIcons.plus,
            onPressed: _noop,
            child: Text('Add pipeline'),
          )
        : null,
  );
}
