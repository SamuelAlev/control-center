import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_spinner.stories.g.dart';

/// Stories for [CcSpinner] — the indeterminate progress indicator used while
/// agents think, pipelines run and pull requests load.
///
/// The stories below are listed under `Components → Feedback → CcSpinner` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. When motion is reduced the arc stops rotating and shows a static
/// partial ring instead.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcSpinner', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcSpinnerPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    size: DoubleArg(
      28,
      name: 'Size',
      style: const SliderDoubleArgStyle(min: 12, max: 64, divisions: 52),
    ),
    strokeWidth: DoubleArg(
      2,
      name: 'Stroke width',
      style: const SliderDoubleArgStyle(min: 1, max: 8, divisions: 7),
    ),
    useAccent: BoolArg(true, name: 'Use accent color'),
    label: StringArg('Running pipeline', name: 'Semantic label'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccSpinnerPlaygroundStory(context, args)),
);

final $Colors = _Story(args: _Args.fixed(preview: ccSpinnerColorsStory));

final $Sizes = _Story(args: _Args.fixed(preview: ccSpinnerSizesStory));

final $StrokeWidths = _Story(
  name: 'Stroke widths',
  args: _Args.fixed(preview: ccSpinnerStrokeWidthsStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcSpinnerPlayground {
  CcSpinnerPlayground({
    required this.size,
    required this.strokeWidth,
    required this.useAccent,
    required this.label,
  });

  final double size;
  final double strokeWidth;
  final bool useAccent;
  final String label;
}

/// The size scale side by side — from inline (next to a label) to a standalone
/// loading state filling an empty panel.
Widget ccSpinnerSizesStory(BuildContext context) {
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
Widget ccSpinnerStrokeWidthsStory(BuildContext context) {
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
Widget ccSpinnerColorsStory(BuildContext context) {
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

/// Interactive playground — drive every arg to see the full state space.
Widget ccSpinnerPlaygroundStory(
  BuildContext context,
  CcSpinnerPlaygroundArgs args,
) {
  final size = args.size;
  final strokeWidth = args.strokeWidth;
  final useAccent = args.useAccent;
  final label = args.label;
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
