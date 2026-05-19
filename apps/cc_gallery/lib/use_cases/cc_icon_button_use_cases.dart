import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
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
          icon: CcIcons.rocket,
          variant: CcButtonVariant.primary,
          onPressed: _noop,
          tooltip: 'Deploy agent',
        ),
        CcIconButton(
          icon: CcIcons.gitPullRequest,
          variant: CcButtonVariant.secondary,
          onPressed: _noop,
          tooltip: 'Open pull request',
        ),
        CcIconButton(
          icon: CcIcons.sparkles,
          variant: CcButtonVariant.accent,
          onPressed: _noop,
          tooltip: 'Ask Claude',
        ),
        CcIconButton(
          icon: CcIcons.folderGit2,
          variant: CcButtonVariant.line,
          onPressed: _noop,
          tooltip: 'Browse repo',
        ),
        CcIconButton(
          icon: CcIcons.settings,
          onPressed: _noop,
          tooltip: 'Workspace settings',
        ),
        CcIconButton(icon: CcIcons.lock, onPressed: null, tooltip: 'Locked'),
      ],
    ),
  );
}

/// The loading state — the glyph spins in place (keeping the action
/// identifiable) and the button stops responding until the work completes.
@widgetbook.UseCase(name: 'Loading', type: CcIconButton, path: _path)
Widget ccIconButtonLoadingUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        CcIconButton(
          icon: CcIcons.refreshCw,
          loading: true,
          onPressed: _noop,
          tooltip: 'Refreshing',
        ),
        CcIconButton(
          icon: CcIcons.refreshCw,
          variant: CcButtonVariant.secondary,
          loading: true,
          onPressed: _noop,
          tooltip: 'Refreshing',
        ),
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
            icon: CcIcons.play,
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
          icon: CcIcons.star,
          color: t.accent,
          onPressed: _noop,
          tooltip: 'Starred',
        ),
        CcIconButton(
          icon: CcIcons.bell,
          color: t.textSecondary,
          onPressed: _noop,
          tooltip: 'Mute notifications',
        ),
        const CcIconButton(
          icon: CcIcons.bookmark,
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
  final loading = context.knobs.boolean(label: 'Loading');
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
      icon: CcIcons.refreshCw,
      variant: variant,
      size: size,
      loading: loading,
      onPressed: enabled ? () {} : null,
      tooltip: withTooltip ? tooltip : null,
    ),
  );
}
