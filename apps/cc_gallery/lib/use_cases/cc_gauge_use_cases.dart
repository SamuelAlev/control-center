import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcGauge] — the ring meter used for budget/quota fill.
///
/// A gauge is a value read at a glance, so the label inside the ring carries
/// the number: the arc alone is never the only channel.

const _path = '[Components]/Data';

/// The fill range, from empty to full, with the value spelled out inside.
@widgetbook.UseCase(name: 'Fill levels', type: CcGauge, path: _path)
Widget ccGaugeFillLevelsUseCase(BuildContext context) {
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

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcGauge, path: _path)
Widget ccGaugePlaygroundUseCase(BuildContext context) {
  final t = context.ds;
  final value = context.knobs.double.slider(
    label: 'Value',
    initialValue: 0.6,
    max: 1,
  );
  final size = context.knobs.double.slider(
    label: 'Size',
    initialValue: 80,
    min: 32,
    max: 200,
  );
  final stroke = context.knobs.double.slider(
    label: 'Stroke width',
    initialValue: 8,
    min: 2,
    max: 24,
  );
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
