import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_slider.stories.g.dart';

/// Stories for [CcSlider] — the continuous/stepped value control.
///
/// Hovering the track aims a future value (ghost + chip) without committing;
/// a click writes it. The committed reading sits in mono at the start edge.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcSlider', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcSliderPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    divisions: IntArg(
      0,
      name: 'Divisions (0 = continuous)',
      style: const SliderIntArgStyle(min: 0, max: 10, divisions: 10),
    ),
    enabled: BoolArg(true, name: 'Enabled'),
    showValue: BoolArg(true, name: 'Show value'),
    showSteps: BoolArg(true, name: 'Show steps'),
    labelled: BoolArg(false, name: 'Label prefix'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccSliderPlaygroundStory(context, args)),
);

final $ContinuousAndStepped = _Story(
  name: 'Continuous and stepped',
  args: _Args.fixed(preview: ccSliderVariantsStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcSliderPlayground {
  CcSliderPlayground({
    required this.divisions,
    required this.enabled,
    required this.showValue,
    required this.showSteps,
    required this.labelled,
  });

  final int divisions;
  final bool enabled;
  final bool showValue;
  final bool showSteps;
  final bool labelled;
}

/// Continuous, stepped, labelled and disabled — the states the app uses.
Widget ccSliderVariantsStory(BuildContext context) =>
    const Center(child: _SliderShowcase());

/// Interactive playground — drive every arg to see the full state space.
Widget ccSliderPlaygroundStory(
  BuildContext context,
  CcSliderPlaygroundArgs args,
) {
  final divisions = args.divisions;
  final enabled = args.enabled;
  final showValue = args.showValue;
  final showSteps = args.showSteps;
  final labelled = args.labelled;
  return Center(
    child: _SliderShowcase(
      divisions: divisions == 0 ? null : divisions,
      enabled: enabled,
      showValue: showValue,
      showSteps: showSteps,
      label: labelled ? 'Volume' : null,
      single: true,
    ),
  );
}

/// Holds slider state so the gallery entry is actually draggable.
class _SliderShowcase extends StatefulWidget {
  const _SliderShowcase({
    this.divisions,
    this.enabled = true,
    this.showValue = true,
    this.showSteps,
    this.label,
    this.single = false,
  });

  final int? divisions;
  final bool enabled;
  final bool showValue;
  final bool? showSteps;
  final String? label;
  final bool single;

  @override
  State<_SliderShowcase> createState() => _SliderShowcaseState();
}

class _SliderShowcaseState extends State<_SliderShowcase> {
  double _continuous = 0.7;
  double _stepped = 0.5;
  double _named = 1;
  double _opacity = 0.75;
  double _concurrency = 4;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    Widget labelled(String caption, Widget slider) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          caption,
          style: CcTypography.label.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(width: 320, child: slider),
      ],
    );

    if (widget.single) {
      return labelled(
        'Hover the track to aim, click to set',
        CcSlider(
          value: _continuous,
          divisions: widget.divisions,
          showValue: widget.showValue,
          showSteps: widget.showSteps,
          label: widget.label,
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
          'Continuous',
          CcSlider(
            value: _continuous,
            semanticLabel: 'Continuous value',
            semanticFormatter: (v) => '${(v * 100).round()} percent',
            onChanged: (v) => setState(() => _continuous = v),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        labelled(
          'Steps',
          CcSlider(
            value: _stepped,
            divisions: 4,
            semanticLabel: 'Stepped value',
            onChanged: (v) => setState(() => _stepped = v),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        labelled(
          'Named steps',
          CcSlider(
            value: _named,
            min: 0,
            max: 2,
            divisions: 2,
            stepLabels: const ['Low', 'Medium', 'High'],
            showValue: false,
            semanticLabel: 'Effort',
            onChanged: (v) => setState(() => _named = v),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        labelled(
          'Labelled',
          CcSlider(
            value: _opacity,
            divisions: 20,
            label: 'Opacity',
            semanticLabel: 'Opacity',
            onChanged: (v) => setState(() => _opacity = v),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        labelled(
          'Integer range',
          CcSlider(
            value: _concurrency,
            min: 1,
            max: 8,
            divisions: 7,
            semanticLabel: 'Concurrency',
            semanticFormatter: (v) => '${v.round()}',
            onChanged: (v) => setState(() => _concurrency = v),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
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
