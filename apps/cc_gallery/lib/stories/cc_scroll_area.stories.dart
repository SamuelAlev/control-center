import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_scroll_area.stories.g.dart';

/// Stories for [CcScrollArea] — the scroll-aware edge-affordance container.
///
/// Unlike the static [CcFadeEdges], each edge hints only while content
/// actually remains beyond it: at the top only the bottom fades, mid-scroll
/// both do, at the bottom only the top does, and a list that fits shows no
/// hint at all. Scroll the lists to watch the hints follow
/// (`CcScrollAreaState` tracks the edges from the child's scroll
/// notifications).

const _path = '[Primitives]';

const component = ComponentMeta(name: 'CcScrollArea', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcScrollAreaPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    horizontal: BoolArg(false, name: 'Horizontal'),
    start: BoolArg(true, name: 'Fade start'),
    end: BoolArg(true, name: 'Fade end'),
    fadeSize: DoubleArg(
      32,
      name: 'Fade size (px)',
      style: const SliderDoubleArgStyle(min: 0, max: 96, divisions: 96),
    ),
    rows: IntArg(
      20,
      name: 'Rows',
      style: const SliderIntArgStyle(min: 1, max: 40, divisions: 39),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccScrollAreaPlaygroundStory(context, args),
  ),
);

final $Axes = _Story(args: _Args.fixed(preview: ccScrollAreaAxesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcScrollAreaPlayground {
  CcScrollAreaPlayground({
    required this.horizontal,
    required this.start,
    required this.end,
    required this.fadeSize,
    required this.rows,
  });

  final bool horizontal;
  final bool start;
  final bool end;
  final double fadeSize;
  final int rows;
}

Widget _rows(
  BuildContext context, {
  int count = 20,
  Axis axis = Axis.vertical,
}) {
  final t = context.ds;
  final children = [
    for (var i = 1; i <= count; i++)
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

Widget _framed(BuildContext context, Widget child) {
  final t = context.ds;
  return DecoratedBox(
    decoration: BoxDecoration(border: Border.all(color: t.borderSecondary)),
    child: child,
  );
}

/// Vertical and horizontal, each over a real scrollable — scroll to see the
/// hints appear and disappear at the edges.
Widget ccScrollAreaAxesStory(BuildContext context) {
  return Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          height: 220,
          child: _framed(context, CcScrollArea(child: _rows(context))),
        ),
        const SizedBox(width: AppSpacing.xl),
        SizedBox(
          width: 260,
          height: 60,
          child: _framed(
            context,
            CcScrollArea(
              axis: Axis.horizontal,
              child: _rows(context, axis: Axis.horizontal),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every arg, including a row count low
/// enough that the content fits and no hint shows.
Widget ccScrollAreaPlaygroundStory(
  BuildContext context,
  CcScrollAreaPlaygroundArgs args,
) {
  final horizontal = args.horizontal;
  final start = args.start;
  final end = args.end;
  final fadeSize = args.fadeSize;
  final rows = args.rows;
  return Center(
    child: SizedBox(
      width: horizontal ? 320 : 200,
      height: horizontal ? 60 : 240,
      child: _framed(
        context,
        CcScrollArea(
          axis: horizontal ? Axis.horizontal : Axis.vertical,
          fadeStart: start,
          fadeEnd: end,
          fadeSize: fadeSize,
          child: _rows(
            context,
            count: rows,
            axis: horizontal ? Axis.horizontal : Axis.vertical,
          ),
        ),
      ),
    ),
  );
}
