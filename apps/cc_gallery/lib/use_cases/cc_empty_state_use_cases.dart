import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcEmptyState] — the design system's centered "nothing here
/// yet" surface. Stacks a muted icon, a primary message, an optional teaching
/// description, and an optional action widget.
///
/// Builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas.

const _path = '[Components]/Containers';

void _noop() {}

/// Just the icon and message — the minimal empty surface.
@widgetbook.UseCase(name: 'Message only', type: CcEmptyState, path: _path)
Widget ccEmptyStateMessageOnlyUseCase(BuildContext context) {
  return const CcEmptyState(
    icon: LucideIcons.inbox,
    message: 'No pull requests',
  );
}

/// Icon, message, and a teaching description line.
@widgetbook.UseCase(
  name: 'With description',
  type: CcEmptyState,
  path: _path,
)
Widget ccEmptyStateWithDescriptionUseCase(BuildContext context) {
  return const CcEmptyState(
    icon: LucideIcons.gitPullRequest,
    message: 'No open pull requests',
    description:
        'When an agent opens a PR in this workspace, it will show up here '
        'for review.',
  );
}

/// The full layout — icon, message, description, and a primary action.
@widgetbook.UseCase(name: 'With action', type: CcEmptyState, path: _path)
Widget ccEmptyStateWithActionUseCase(BuildContext context) {
  return const CcEmptyState(
    icon: LucideIcons.boxes,
    message: 'No workspaces yet',
    description:
        'Create a workspace to give your agents an isolated Git worktree to '
        'work in.',
    action: CcButton(
      icon: LucideIcons.plus,
      onPressed: _noop,
      child: Text('Create workspace'),
    ),
  );
}

/// Interactive playground — drive every prop to explore the state space.
@widgetbook.UseCase(name: 'Playground', type: CcEmptyState, path: _path)
Widget ccEmptyStatePlaygroundUseCase(BuildContext context) {
  final message = context.knobs.string(
    label: 'Message',
    initialValue: 'No pipelines configured',
  );
  final description = context.knobs.string(
    label: 'Description',
    initialValue:
        'Pipelines automate multi-agent work across your repos. Add one to '
        'get started.',
  );
  final withDescription = context.knobs.boolean(
    label: 'Show description',
    initialValue: true,
  );
  final withAction = context.knobs.boolean(label: 'Show action');
  final iconSize = context.knobs.double.slider(
    label: 'Icon size',
    initialValue: 48,
    min: 24,
    max: 96,
  );
  final maxWidth = context.knobs.double.slider(
    label: 'Max width',
    initialValue: 320,
    min: 200,
    max: 520,
  );
  return CcEmptyState(
    icon: LucideIcons.workflow,
    message: message,
    description: withDescription ? description : null,
    iconSize: iconSize,
    maxWidth: maxWidth,
    action: withAction
        ? const CcButton(
            icon: LucideIcons.plus,
            onPressed: _noop,
            child: Text('Add pipeline'),
          )
        : null,
  );
}
