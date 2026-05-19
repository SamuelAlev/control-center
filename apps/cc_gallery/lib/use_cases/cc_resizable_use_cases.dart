import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcResizable] — a row or column of regions separated by
/// draggable hairline dividers (e.g. the tree / diff split in PR review).
///
/// Each builder is annotated with `@widgetbook.UseCase`; the builders return
/// the component directly — the gallery's theme addon supplies the [CcTheme]
/// + canvas. Drag the hairline between regions to resize.

const _path = '[Components]/Layout';

/// A labelled pane used as region content in the use-cases.
Widget _pane(BuildContext context, String label, Color color) {
  final t = context.designSystem!;
  return ColoredBox(
    color: color,
    child: Center(
      child: Text(label, style: CcTypography.bodySm.copyWith(color: t.textPrimary)),
    ),
  );
}

/// A horizontal split — the canonical tree / diff layout from PR review.
@widgetbook.UseCase(name: 'Horizontal split', type: CcResizable, path: _path)
Widget ccResizableHorizontalUseCase(BuildContext context) {
  final t = context.designSystem!;
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 320,
      child: CcResizable(
        axis: Axis.horizontal,
        regions: [
          CcResizableRegion.child(
            child: _pane(context, 'File tree', t.bgSecondary),
            initialExtent: 180,
            minExtent: 120,
          ),
          CcResizableRegion.child(
            child: _pane(context, 'Diff', t.surface),
            initialExtent: 380,
            minExtent: 200,
          ),
        ],
      ),
    ),
  );
}

/// A vertical split — stack a diff over an agent run log.
@widgetbook.UseCase(name: 'Vertical split', type: CcResizable, path: _path)
Widget ccResizableVerticalUseCase(BuildContext context) {
  final t = context.designSystem!;
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      width: 480,
      height: 360,
      child: CcResizable(
        axis: Axis.vertical,
        regions: [
          CcResizableRegion.child(
            child: _pane(context, 'Diff', t.surface),
            initialExtent: 220,
            minExtent: 120,
          ),
          CcResizableRegion.child(
            child: _pane(context, 'Agent run log', t.bgSecondary),
            initialExtent: 120,
            minExtent: 80,
          ),
        ],
      ),
    ),
  );
}

/// Three regions — a workspace layout with sidebar, editor and inspector.
@widgetbook.UseCase(name: 'Three regions', type: CcResizable, path: _path)
Widget ccResizableThreeUseCase(BuildContext context) {
  final t = context.designSystem!;
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 320,
      child: CcResizable(
        axis: Axis.horizontal,
        regions: [
          CcResizableRegion.child(
            child: _pane(context, 'Workspaces', t.bgSecondary),
            initialExtent: 160,
            minExtent: 120,
            maxExtent: 240,
          ),
          CcResizableRegion.child(
            child: _pane(context, 'Pipeline', t.surface),
            initialExtent: 360,
            minExtent: 220,
          ),
          CcResizableRegion.child(
            child: _pane(context, 'Inspector', t.bgSecondary),
            initialExtent: 200,
            minExtent: 140,
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive axis, divider chrome and region bounds.
@widgetbook.UseCase(name: 'Playground', type: CcResizable, path: _path)
Widget ccResizablePlaygroundUseCase(BuildContext context) {
  final t = context.designSystem!;
  final horizontal = context.knobs.boolean(label: 'Horizontal', initialValue: true);
  final thickness = context.knobs.double.slider(
    label: 'Divider thickness',
    initialValue: 1,
    min: 0,
    max: 6,
  );
  final hitSize = context.knobs.double.slider(
    label: 'Divider hit size',
    initialValue: 8,
    min: 6,
    max: 24,
  );
  final firstLabel = context.knobs.string(label: 'First label', initialValue: 'Repos');
  final secondLabel =
      context.knobs.string(label: 'Second label', initialValue: 'Claude session');
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      width: 520,
      height: 320,
      child: CcResizable(
        axis: horizontal ? Axis.horizontal : Axis.vertical,
        dividerThickness: thickness,
        dividerHitSize: hitSize,
        regions: [
          CcResizableRegion.child(
            child: _pane(context, firstLabel, t.bgSecondary),
            initialExtent: 200,
            minExtent: 120,
          ),
          CcResizableRegion.child(
            child: _pane(context, secondLabel, t.surface),
            initialExtent: 300,
            minExtent: 160,
          ),
        ],
      ),
    ),
  );
}
