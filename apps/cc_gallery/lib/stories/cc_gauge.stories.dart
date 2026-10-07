import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_gauge.stories.g.dart';

/// Stories for [CcGauge] — the ring meter used for budget/quota fill.
///
/// A gauge is a value read at a glance, so the label inside the ring carries
/// the number: the arc alone is never the only space.

const _path = '[Components]/Data';

const component = ComponentMeta(name: 'CcGauge', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcGaugePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    value: DoubleArg(
      0.6,
      name: 'Value',
      style: const SliderDoubleArgStyle(min: 0, max: 1, divisions: 100),
    ),
    size: DoubleArg(
      80,
      name: 'Size',
      style: const SliderDoubleArgStyle(min: 32, max: 200, divisions: 84),
    ),
    stroke: DoubleArg(
      8,
      name: 'Stroke width',
      style: const SliderDoubleArgStyle(min: 2, max: 24, divisions: 22),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccGaugePlaygroundStory(context, args)),
);

final $FillLevels = _Story(
  name: 'Fill levels',
  args: _Args.fixed(preview: ccGaugeFillLevelsStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcGaugePlayground {
  CcGaugePlayground({
    required this.value,
    required this.size,
    required this.stroke,
  });

  final double value;
  final double size;
  final double stroke;
}

/// The fill range, from empty to full, with the value spelled out inside.
Widget ccGaugeFillLevelsStory(BuildContext context) {
  final t = context.ds;
  Widget gauge(double value, String label, Color color) => CcGauge(
    value: value,
    color: color,
    semanticLabel: '$label of budget used',
    child: Text(
      label,
      style: CcTypography.label.copyWith(color: t.textPrimary),
    ),
  );

  return Center(
    child: Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        gauge(0, '0%', t.fgBrandPrimary),
        gauge(0.35, '35%', t.fgBrandPrimary),
        gauge(0.72, '72%', t.bgWarningSolid),
        gauge(1, '100%', t.danger),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccGaugePlaygroundStory(
  BuildContext context,
  CcGaugePlaygroundArgs args,
) {
  final t = context.ds;
  final value = args.value;
  final size = args.size;
  final stroke = args.stroke;
  return Center(
    child: CcGauge(
      value: value,
      size: size,
      strokeWidth: stroke,
      semanticLabel: '${(value * 100).round()}% used',
      child: Text(
        '${(value * 100).round()}%',
        style: CcTypography.label.copyWith(color: t.textPrimary),
      ),
    ),
  );
}
