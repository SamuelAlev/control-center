import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_fade_edges.stories.g.dart';

/// Stories for [CcFadeEdges] — the scroll-affordance gradient.
///
/// It says "there is more this way" without a scrollbar, which matters on the
/// surfaces that scroll inside a dense layout (the roster, a transcript, a
/// filter list).

const _path = '[Primitives]';

const component = ComponentMeta(name: 'CcFadeEdges', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcFadeEdgesPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    horizontal: BoolArg(false, name: 'Horizontal'),
    start: BoolArg(true, name: 'Fade start'),
    end: BoolArg(true, name: 'Fade end'),
    extent: DoubleArg(
      0.12,
      name: 'Fade extent',
      style: const SliderDoubleArgStyle(min: 0, max: 0.5, divisions: 50),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccFadeEdgesPlaygroundStory(context, args),
  ),
);

final $Axes = _Story(args: _Args.fixed(preview: ccFadeEdgesAxesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcFadeEdgesPlayground {
  CcFadeEdgesPlayground({
    required this.horizontal,
    required this.start,
    required this.end,
    required this.extent,
  });

  final bool horizontal;
  final bool start;
  final bool end;
  final double extent;
}

Widget _rows(BuildContext context, {Axis axis = Axis.vertical}) {
  final t = context.ds;
  final children = [
    for (var i = 1; i <= 20; i++)
      Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Text(
          'Row $i',
          style: CcTypography.bodySm.copyWith(color: t.textSecondary),
        ),
      ),
  ];
  return axis == Axis.vertical
      ? ListView(children: children)
      : ListView(scrollDirection: Axis.horizontal, children: children);
}

/// Vertical and horizontal, each over a real scrollable.
Widget ccFadeEdgesAxesStory(BuildContext context) {
  return Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          height: 220,
          child: CcFadeEdges(child: _rows(context)),
        ),
        const SizedBox(width: AppSpacing.xl),
        SizedBox(
          width: 260,
          height: 60,
          child: CcFadeEdges(
            axis: Axis.horizontal,
            child: _rows(context, axis: Axis.horizontal),
          ),
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccFadeEdgesPlaygroundStory(
  BuildContext context,
  CcFadeEdgesPlaygroundArgs args,
) {
  final horizontal = args.horizontal;
  final start = args.start;
  final end = args.end;
  final extent = args.extent;
  return Center(
    child: SizedBox(
      width: horizontal ? 320 : 200,
      height: horizontal ? 60 : 240,
      child: CcFadeEdges(
        axis: horizontal ? Axis.horizontal : Axis.vertical,
        fadeStart: start,
        fadeEnd: end,
        fadeExtent: extent,
        child: _rows(
          context,
          axis: horizontal ? Axis.horizontal : Axis.vertical,
        ),
      ),
    ),
  );
}
