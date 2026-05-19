import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcSlider] — the continuous/stepped value control.
///
/// Sliders are keyboard-operable and carry a `semanticLabel` plus a formatter,
/// so the announced value is the one a person means ("70 percent"), not a raw
/// double.

const _path = '[Components]/Inputs';

/// Continuous vs stepped, at the sizes the app actually uses.
@widgetbook.UseCase(name: 'Continuous and stepped', type: CcSlider, path: _path)
Widget ccSliderVariantsUseCase(BuildContext context) =>
    const Center(child: _SliderShowcase());

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcSlider, path: _path)
Widget ccSliderPlaygroundUseCase(BuildContext context) {
  final divisions = context.knobs.int.slider(
    label: 'Divisions (0 = continuous)',
    initialValue: 0,
    max: 10,
  );
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  return Center(
    child: _SliderShowcase(
      divisions: divisions == 0 ? null : divisions,
      enabled: enabled,
      single: true,
    ),
  );
}

/// Holds slider state so the gallery entry is actually draggable.
class _SliderShowcase extends StatefulWidget {
  const _SliderShowcase({
    this.divisions,
    this.enabled = true,
    this.single = false,
  });

  final int? divisions;
  final bool enabled;
  final bool single;

  @override
  State<_SliderShowcase> createState() => _SliderShowcaseState();
}

class _SliderShowcaseState extends State<_SliderShowcase> {
  double _continuous = 0.7;
  double _stepped = 0.5;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    Widget labelled(String label, Widget slider) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: CcTypography.label.copyWith(color: t.textTertiary)),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(width: 280, child: slider),
      ],
    );

    if (widget.single) {
      return labelled(
        'Value ${(_continuous * 100).round()}%',
        CcSlider(
          value: _continuous,
          divisions: widget.divisions,
          semanticLabel: 'Value',
          semanticFormatter: (v) => '${(v * 100).round()} percent',
          onChanged: widget.enabled
              ? (v) => setState(() => _continuous = v)
              : null,
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        labelled(
          'Continuous — ${(_continuous * 100).round()}%',
          CcSlider(
            value: _continuous,
            semanticLabel: 'Continuous value',
            semanticFormatter: (v) => '${(v * 100).round()} percent',
            onChanged: (v) => setState(() => _continuous = v),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        labelled(
          'Stepped (4 divisions)',
          CcSlider(
            value: _stepped,
            divisions: 4,
            semanticLabel: 'Stepped value',
            onChanged: (v) => setState(() => _stepped = v),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        labelled(
          'Disabled',
          const CcSlider(
            value: 0.3,
            semanticLabel: 'Disabled value',
            onChanged: null,
          ),
        ),
      ],
    );
  }
}
