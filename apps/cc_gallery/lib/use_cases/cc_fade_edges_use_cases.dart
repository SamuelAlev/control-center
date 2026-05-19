import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcFadeEdges] — the scroll-affordance gradient.
///
/// It says "there is more this way" without a scrollbar, which matters on the
/// surfaces that scroll inside a dense layout (the roster, a transcript, a
/// filter list).

const _path = '[Primitives]';

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
@widgetbook.UseCase(name: 'Axes', type: CcFadeEdges, path: _path)
Widget ccFadeEdgesAxesUseCase(BuildContext context) {
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

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcFadeEdges, path: _path)
Widget ccFadeEdgesPlaygroundUseCase(BuildContext context) {
  final horizontal = context.knobs.boolean(label: 'Horizontal');
  final start = context.knobs.boolean(label: 'Fade start', initialValue: true);
  final end = context.knobs.boolean(label: 'Fade end', initialValue: true);
  final extent = context.knobs.double.slider(
    label: 'Fade extent',
    initialValue: 0.12,
    max: 0.5,
  );
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
