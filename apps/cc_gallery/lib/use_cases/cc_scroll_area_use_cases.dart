import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcScrollArea] — the scroll-aware edge-affordance container.
///
/// Unlike the static [CcFadeEdges], each edge hints only while content
/// actually remains beyond it: at the top only the bottom fades, mid-scroll
/// both do, at the bottom only the top does, and a list that fits shows no
/// hint at all. Scroll the lists to watch the hints follow
/// (`CcScrollAreaState` tracks the edges from the child's scroll
/// notifications).

const _path = '[Primitives]';

Widget _rows(BuildContext context, {int count = 20, Axis axis = Axis.vertical}) {
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
@widgetbook.UseCase(name: 'Axes', type: CcScrollArea, path: _path)
Widget ccScrollAreaAxesUseCase(BuildContext context) {
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

/// Interactive playground — drive every knob, including a row count low
/// enough that the content fits and no hint shows.
@widgetbook.UseCase(name: 'Playground', type: CcScrollArea, path: _path)
Widget ccScrollAreaPlaygroundUseCase(BuildContext context) {
  final horizontal = context.knobs.boolean(label: 'Horizontal');
  final start = context.knobs.boolean(label: 'Fade start', initialValue: true);
  final end = context.knobs.boolean(label: 'Fade end', initialValue: true);
  final fadeSize = context.knobs.double.slider(
    label: 'Fade size (px)',
    initialValue: 32,
    max: 96,
  );
  final rows = context.knobs.int.slider(
    label: 'Rows',
    initialValue: 20,
    min: 1,
    max: 40,
  );
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
