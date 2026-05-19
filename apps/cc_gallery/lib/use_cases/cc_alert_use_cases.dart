import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcAlert] — an inline banner that surfaces a status message in
/// flow. Intent reads from the icon, tint, and copy together (never color
/// alone). The builders return the component directly — the gallery's theme
/// addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Feedback';

/// Every semantic variant stacked, each with a matching lucide glyph.
@widgetbook.UseCase(name: 'Variants', type: CcAlert, path: _path)
Widget ccAlertVariantsUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcAlert(
            title: 'Heads up',
            description: Text('Claude Opus is the default model for new agents.'),
            icon: LucideIcons.info,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Workspace synced',
            description: Text('All worktrees are up to date with origin/main.'),
            variant: CcAlertVariant.success,
            icon: LucideIcons.circleCheck,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Budget threshold crossed',
            description: Text('This agent has used 80% of its daily token budget.'),
            variant: CcAlertVariant.warning,
            icon: LucideIcons.triangleAlert,
          ),
          SizedBox(height: 12),
          CcAlert(
            title: 'Failed to open pull request',
            description: Text('GitHub returned 422 — the branch has no commits.'),
            variant: CcAlertVariant.danger,
            icon: LucideIcons.circleX,
          ),
        ],
      ),
    ),
  );
}

/// Title-only banners versus title with a supporting description.
@widgetbook.UseCase(name: 'Title and description', type: CcAlert, path: _path)
Widget ccAlertTitleAndDescriptionUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'With and without icon', type: CcAlert, path: _path)
Widget ccAlertWithIconUseCase(BuildContext context) {
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
            icon: LucideIcons.circleCheck,
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcAlert, path: _path)
Widget ccAlertPlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: CcAlertVariant.values,
    labelBuilder: (v) => v.name,
  );
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Workspace seeded',
  );
  final description = context.knobs.string(
    label: 'Description',
    initialValue: 'The CEO agent created three starter tickets.',
  );
  final withIcon = context.knobs.boolean(label: 'Leading icon', initialValue: true);
  return Center(
    child: SizedBox(
      width: 420,
      child: CcAlert(
        variant: variant,
        title: title,
        description: description.isEmpty ? null : Text(description),
        icon: withIcon ? LucideIcons.bell : null,
      ),
    ),
  );
}
