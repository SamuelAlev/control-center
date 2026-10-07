import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_dialog.stories.g.dart';

/// Stories for [CcDialog] — the design system's flat, floating modal surface.
///
/// The builders render the dialog panel directly (centered) so its surface,
/// title, body and action row are all visible at rest. In the app it is
/// presented over a frosted scrim via `showCcDialog`; here the panel stands
/// alone against the gallery canvas.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcDialog', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcDialogPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    withTitle: BoolArg(true, name: 'Show title'),
    title: StringArg('Discard changes?', name: 'Title'),
    body: StringArg(
      'Your draft review will be lost. The pull request stays open on GitHub.',
      name: 'Body',
    ),
    actionCount: SingleArg<int>(
      2,
      name: 'Actions',
      values: const [0, 1, 2],
      labelBuilder: (v) => '$v',
    ),
    maxWidth: DoubleArg(
      480,
      name: 'Max width',
      style: const SliderDoubleArgStyle(min: 320, max: 720, divisions: 100),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccDialogPlaygroundStory(context, args)),
);

final $Confirm = _Story(args: _Args.fixed(preview: ccDialogConfirmStory));

final $ContentOnly = _Story(
  name: 'Content only',
  args: _Args.fixed(preview: ccDialogContentOnlyStory),
);

final $TypeToConfirm = _Story(
  name: 'Type to confirm',
  args: _Args.fixed(preview: ccDialogTypeToConfirmStory),
);

final $WideSingleAction = _Story(
  name: 'Wide single action',
  args: _Args.fixed(preview: ccDialogWideStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcDialogPlayground {
  CcDialogPlayground({
    required this.withTitle,
    required this.title,
    required this.body,
    required this.actionCount,
    required this.maxWidth,
  });

  final bool withTitle;
  final String title;
  final String body;
  final int actionCount;
  final double maxWidth;
}

void _noop() {}

/// The canonical confirm dialog: title, body copy and a right-aligned cancel
/// plus destructive action pair.
Widget ccDialogConfirmStory(BuildContext context) {
  return const Center(
    child: CcDialog(
      title: 'Delete agent?',
      content: Text(
        'This permanently removes the agent and its run history. '
        'Open pull requests stay on GitHub.',
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.secondary,
          onPressed: _noop,
          child: Text('Cancel'),
        ),
        CcButton(
          variant: CcButtonVariant.destructive,
          onPressed: _noop,
          child: Text('Delete'),
        ),
      ],
    ),
  );
}

/// The high-impact confirmation ladder rung: `showCcConfirmDialog` with
/// `typeToConfirm` keeps the destructive action disabled until the user types
/// the resource name back exactly; the prompt sets the name in a copyable chip
/// and the field repeats it as its placeholder. Tap the trigger to run the
/// real flow.
Widget ccDialogTypeToConfirmStory(BuildContext context) {
  return Center(
    child: Builder(
      builder: (context) => CcButton(
        variant: CcButtonVariant.destructive,
        onPressed: () => showCcConfirmDialog(
          context: context,
          title: 'Delete workspace',
          message:
              'Every agent, channel, run log and memory fact in '
              '"acme-prod" is destroyed. This cannot be undone.',
          confirmLabel: 'Delete workspace',
          cancelLabel: 'Cancel',
          danger: true,
          typeToConfirm: 'acme-prod',
        ),
        child: const Text('Delete workspace'),
      ),
    ),
  );
}

/// A title-less, action-less dialog — a pure informational surface that relies
/// on the barrier tap (or an embedded control) to dismiss.
Widget ccDialogContentOnlyStory(BuildContext context) {
  return const Center(
    child: CcDialog(
      content: Text(
        'Indexing the workspace repos. The code graph and memory facts '
        'become searchable as soon as the first pass completes.',
      ),
    ),
  );
}

/// A wider single-action dialog driving a primary call to action, sized past
/// the default 480 cap to host richer body content.
Widget ccDialogWideStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: CcDialog(
      maxWidth: 600,
      title: 'Merge pull request',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Claude Opus reviewed 14 files and left no blocking comments. '
            'Squash and merge into main when you are ready.',
          ),
          AppSpacing.vGapSm,
          Text(
            'control-center · feature/pipeline-conditionals',
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ),
      actions: const [
        CcButton(onPressed: _noop, child: Text('Squash and merge')),
      ],
    ),
  );
}

/// Interactive playground — drive title, body, action count and width.
Widget ccDialogPlaygroundStory(
  BuildContext context,
  CcDialogPlaygroundArgs args,
) {
  final withTitle = args.withTitle;
  final title = args.title;
  final body = args.body;
  final actionCount = args.actionCount;
  final maxWidth = args.maxWidth;

  return Center(
    child: CcDialog(
      title: withTitle ? title : null,
      maxWidth: maxWidth,
      content: Text(body),
      actions: [
        if (actionCount >= 2)
          const CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: _noop,
            child: Text('Cancel'),
          ),
        if (actionCount >= 1)
          const CcButton(onPressed: _noop, child: Text('Discard')),
      ],
    ),
  );
}
