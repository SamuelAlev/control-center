import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcDivider] — the design system's 1px separator hairline.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Containers → CcDivider` (from [CcDivider] as
/// the `type` and the bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

/// A horizontal hairline separating two stacked sections.
@widgetbook.UseCase(name: 'Horizontal', type: CcDivider, path: _path)
Widget ccDividerHorizontalUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open pull requests',
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 12),
          const CcDivider(),
          const SizedBox(height: 12),
          Text(
            'Merged this week',
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    ),
  );
}

/// A vertical rule splitting inline content, e.g. metadata in a PR row.
@widgetbook.UseCase(name: 'Vertical', type: CcDivider, path: _path)
Widget ccDividerVerticalUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final label = CcTypography.bodySm.copyWith(color: t.textSecondary);
  return Center(
    child: SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('claude-opus-4', style: label),
          const SizedBox(width: 12),
          const CcDivider(axis: Axis.vertical),
          const SizedBox(width: 12),
          Text('control-center', style: label),
          const SizedBox(width: 12),
          const CcDivider(axis: Axis.vertical),
          const SizedBox(width: 12),
          Text('workspace · main', style: label),
        ],
      ),
    ),
  );
}

/// Thickness and indent treatments — a hairline, a heavier rule, and an inset
/// line that stops short of both edges.
@widgetbook.UseCase(name: 'Thickness & indent', type: CcDivider, path: _path)
Widget ccDividerThicknessIndentUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final caption = CcTypography.bodySm.copyWith(color: t.textSecondary);
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hairline (1px)', style: caption),
          const SizedBox(height: 8),
          const CcDivider(),
          const SizedBox(height: 20),
          Text('Heavy (3px)', style: caption),
          const SizedBox(height: 8),
          const CcDivider(thickness: 3),
          const SizedBox(height: 20),
          Text('Inset (indent 32, endIndent 32)', style: caption),
          const SizedBox(height: 8),
          const CcDivider(indent: 32, endIndent: 32),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcDivider, path: _path)
Widget ccDividerPlaygroundUseCase(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final axis = context.knobs.object.dropdown(
    label: 'Axis',
    options: Axis.values,
    labelBuilder: (a) => a.name,
  );
  final thickness = context.knobs.double.slider(
    label: 'Thickness',
    initialValue: 1,
    min: 1,
    max: 8,
  );
  final indent = context.knobs.double.slider(
    label: 'Indent',
    initialValue: 0,
    min: 0,
    max: 48,
  );
  final endIndent = context.knobs.double.slider(
    label: 'End indent',
    initialValue: 0,
    min: 0,
    max: 48,
  );
  final divider = CcDivider(
    axis: axis,
    thickness: thickness,
    indent: indent,
    endIndent: endIndent,
  );
  final label = CcTypography.bodySm.copyWith(color: t.textSecondary);
  return Center(
    child: axis == Axis.horizontal
        ? SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pipeline run', style: label),
                const SizedBox(height: 12),
                divider,
                const SizedBox(height: 12),
                Text('Review session', style: label),
              ],
            ),
          )
        : SizedBox(
            height: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Repo', style: label),
                const SizedBox(width: 12),
                divider,
                const SizedBox(width: 12),
                Text('Agent', style: label),
              ],
            ),
          ),
  );
}
