import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcSpinner] — the indeterminate progress indicator used while
/// agents think, pipelines run, and pull requests load.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Feedback → CcSpinner`. The builders return
/// the component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. When motion is reduced the arc stops rotating and shows a static
/// partial ring instead.

const _path = '[Components]/Feedback';

/// The size scale side by side — from inline (next to a label) to a standalone
/// loading state filling an empty panel.
@widgetbook.UseCase(name: 'Sizes', type: CcSpinner, path: _path)
Widget ccSpinnerSizesUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 32,
      runSpacing: 24,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcSpinner(size: 14),
        CcSpinner(size: 18),
        CcSpinner(size: 28),
        CcSpinner(size: 48),
      ],
    ),
  );
}

/// The stroke scale — a hairline arc through to a chunky one, at a fixed size.
@widgetbook.UseCase(name: 'Stroke widths', type: CcSpinner, path: _path)
Widget ccSpinnerStrokeWidthsUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 32,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcSpinner(size: 40, strokeWidth: 1.5),
        CcSpinner(size: 40, strokeWidth: 3),
        CcSpinner(size: 40, strokeWidth: 5),
      ],
    ),
  );
}

/// Color overrides — the default accent arc beside semantic tokens for
/// success (pipeline passing) and danger (run failing). Colors are read from
/// the design-system tokens, never hardcoded.
@widgetbook.UseCase(name: 'Colors', type: CcSpinner, path: _path)
Widget ccSpinnerColorsUseCase(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: Wrap(
      spacing: 32,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const CcSpinner(size: 32, semanticLabel: 'Loading agent'),
        CcSpinner(size: 32, color: t?.success),
        CcSpinner(size: 32, color: t?.danger),
        CcSpinner(size: 32, color: t?.textSecondary),
      ],
    ),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcSpinner, path: _path)
Widget ccSpinnerPlaygroundUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 28,
    min: 12,
    max: 64,
  );
  final strokeWidth = context.knobs.double.slider(
    label: 'Stroke width',
    initialValue: 2,
    min: 1,
    max: 8,
  );
  final useAccent = context.knobs.boolean(
    label: 'Use accent color',
    initialValue: true,
  );
  final label = context.knobs.string(
    label: 'Semantic label',
    initialValue: 'Running pipeline',
  );
  final t = context.designSystem;
  return Center(
    child: CcSpinner(
      size: size,
      strokeWidth: strokeWidth,
      color: useAccent ? null : t?.textSecondary,
      semanticLabel: label.isEmpty ? null : label,
    ),
  );
}
