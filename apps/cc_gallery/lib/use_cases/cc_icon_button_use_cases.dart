import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcIconButton] — the square, icon-only sibling of [CcButton].
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Buttons → CcIconButton` (from
/// [CcIconButton] as the `type` and the bracketed `path` segments). The
/// builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas.

const _path = '[Components]/Buttons';

void _noop() {}

/// Every color variant side by side, plus the disabled treatment.
@widgetbook.UseCase(name: 'Variants', type: CcIconButton, path: _path)
Widget ccIconButtonVariantsUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcIconButton(
          icon: LucideIcons.rocket,
          variant: CcButtonVariant.primary,
          onPressed: _noop,
          tooltip: 'Deploy agent',
        ),
        CcIconButton(
          icon: LucideIcons.gitPullRequest,
          variant: CcButtonVariant.secondary,
          onPressed: _noop,
          tooltip: 'Open pull request',
        ),
        CcIconButton(
          icon: LucideIcons.sparkles,
          variant: CcButtonVariant.accent,
          onPressed: _noop,
          tooltip: 'Ask Claude',
        ),
        CcIconButton(
          icon: LucideIcons.folderGit2,
          variant: CcButtonVariant.line,
          onPressed: _noop,
          tooltip: 'Browse repo',
        ),
        CcIconButton(
          icon: LucideIcons.settings,
          onPressed: _noop,
          tooltip: 'Workspace settings',
        ),
        CcIconButton(
          icon: LucideIcons.trash2,
          variant: CcButtonVariant.destructive,
          onPressed: _noop,
          tooltip: 'Delete workspace',
        ),
        CcIconButton(icon: LucideIcons.lock, onPressed: null),
      ],
    ),
  );
}

/// The size scale — md is a 36px box, sm a 32px box.
@widgetbook.UseCase(name: 'Sizes', type: CcIconButton, path: _path)
Widget ccIconButtonSizesUseCase(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final size in CcButtonSize.values)
          CcIconButton(
            icon: LucideIcons.play,
            size: size,
            variant: CcButtonVariant.primary,
            onPressed: _noop,
            tooltip: 'Run pipeline (${size.name})',
          ),
      ],
    ),
  );
}

/// A custom [CcIconButton.color] override signals an active toolbar
/// affordance without changing the variant background.
@widgetbook.UseCase(name: 'Active color', type: CcIconButton, path: _path)
Widget ccIconButtonActiveColorUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcIconButton(
          icon: LucideIcons.star,
          color: t.accent,
          onPressed: _noop,
          tooltip: 'Starred',
        ),
        CcIconButton(
          icon: LucideIcons.bell,
          color: t.textSecondary,
          onPressed: _noop,
          tooltip: 'Mute notifications',
        ),
        const CcIconButton(
          icon: LucideIcons.bookmark,
          onPressed: _noop,
          tooltip: 'Bookmark thread',
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcIconButton, path: _path)
Widget ccIconButtonPlaygroundUseCase(BuildContext context) {
  final variant = context.knobs.object.dropdown(
    label: 'Variant',
    options: CcButtonVariant.values,
    labelBuilder: (v) => v.name,
  );
  final size = context.knobs.object.dropdown(
    label: 'Size',
    options: CcButtonSize.values,
    labelBuilder: (v) => v.name,
  );
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final withTooltip = context.knobs.boolean(
    label: 'Tooltip',
    initialValue: true,
  );
  final tooltip = context.knobs.string(
    label: 'Tooltip text',
    initialValue: 'Restart agent',
  );
  return Center(
    child: CcIconButton(
      icon: LucideIcons.refreshCw,
      variant: variant,
      size: size,
      onPressed: enabled ? () {} : null,
      tooltip: withTooltip ? tooltip : null,
    ),
  );
}
