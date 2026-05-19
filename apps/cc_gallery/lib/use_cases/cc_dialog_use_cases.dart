import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcDialog] — the design system's flat, floating modal surface.
///
/// The builders render the dialog panel directly (centered) so its surface,
/// title, body, and action row are all visible at rest. In the app it is
/// presented over a frosted scrim via `showCcDialog`; here the panel stands
/// alone against the gallery canvas.

const _path = '[Components]/Navigation & Overlays';

void _noop() {}

/// The canonical confirm dialog: title, body copy, and a right-aligned cancel
/// plus destructive action pair.
@widgetbook.UseCase(name: 'Confirm', type: CcDialog, path: _path)
Widget ccDialogConfirmUseCase(BuildContext context) {
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

/// A title-less, action-less dialog — a pure informational surface that relies
/// on the barrier tap (or an embedded control) to dismiss.
@widgetbook.UseCase(name: 'Content only', type: CcDialog, path: _path)
Widget ccDialogContentOnlyUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Wide single action', type: CcDialog, path: _path)
Widget ccDialogWideUseCase(BuildContext context) {
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

/// Interactive playground — drive title, body, action count, and width.
@widgetbook.UseCase(name: 'Playground', type: CcDialog, path: _path)
Widget ccDialogPlaygroundUseCase(BuildContext context) {
  final withTitle = context.knobs.boolean(
    label: 'Show title',
    initialValue: true,
  );
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Discard changes?',
  );
  final body = context.knobs.string(
    label: 'Body',
    initialValue:
        'Your draft review will be lost. The pull request stays open on GitHub.',
  );
  final actionCount = context.knobs.object.dropdown<int>(
    label: 'Actions',
    options: const [0, 1, 2],
    labelBuilder: (v) => '$v',
    initialOption: 2,
  );
  final maxWidth = context.knobs.double.slider(
    label: 'Max width',
    min: 320,
    max: 720,
    initialValue: 480,
  );

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
