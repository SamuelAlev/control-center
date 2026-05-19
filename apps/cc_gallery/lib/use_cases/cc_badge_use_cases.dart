import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcBadge] — the design system's small status pill.
///
/// Status is carried by tint *and* label text (and a leading icon), never color
/// alone, per the accessibility bar. The builders return the component directly;
/// the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Feedback';

/// Every semantic variant side by side, labelled with real agent/PR states.
@widgetbook.UseCase(name: 'Variants', type: CcBadge, path: _path)
Widget ccBadgeVariantsUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'With icon', type: CcBadge, path: _path)
Widget ccBadgeWithIconUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcBadge(label: 'Running', variant: CcBadgeVariant.success, icon: LucideIcons.play),
        CcBadge(label: 'Review', variant: CcBadgeVariant.warning, icon: LucideIcons.eye),
        CcBadge(label: 'Failed', variant: CcBadgeVariant.danger, icon: LucideIcons.circleX),
        CcBadge(label: 'Workspace', variant: CcBadgeVariant.brand, icon: LucideIcons.gitBranch),
        CcBadge(label: 'Synced', variant: CcBadgeVariant.info, icon: LucideIcons.refreshCw),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcBadge, path: _path)
Widget ccBadgePlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: CcBadgeVariant.values,
    labelBuilder: (v) => v.name,
  );
  final label = context.knobs.string(label: 'Label', initialValue: 'Running');
  final withIcon = context.knobs.boolean(label: 'Leading icon', initialValue: true);
  return Center(
    child: CcBadge(
      variant: variant,
      label: label,
      icon: withIcon ? LucideIcons.activity : null,
    ),
  );
}
