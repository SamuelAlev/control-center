import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_resizable.stories.g.dart';

/// Stories for [CcResizable] — a row or column of regions separated by
/// draggable hairline dividers (e.g. the tree / diff split in PR review).
///
/// The builders return the component directly — the gallery's theme addon
/// supplies the [CcTheme] + canvas. Drag the hairline between regions to
/// resize.

const _path = '[Components]/Layout';

const component = ComponentMeta(name: 'CcResizable', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcResizablePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    horizontal: BoolArg(true, name: 'Horizontal'),
    thickness: DoubleArg(
      1,
      name: 'Divider thickness',
      style: const SliderDoubleArgStyle(min: 0, max: 6, divisions: 6),
    ),
    hitSize: DoubleArg(
      8,
      name: 'Divider hit size',
      style: const SliderDoubleArgStyle(min: 6, max: 24, divisions: 18),
    ),
    firstLabel: StringArg('Repos', name: 'First label'),
    secondLabel: StringArg('Claude session', name: 'Second label'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccResizablePlaygroundStory(context, args),
  ),
);

final $HorizontalSplit = _Story(
  name: 'Horizontal split',
  args: _Args.fixed(preview: ccResizableHorizontalStory),
);

final $ThreeRegions = _Story(
  name: 'Three regions',
  args: _Args.fixed(preview: ccResizableThreeStory),
);

final $VerticalSplit = _Story(
  name: 'Vertical split',
  args: _Args.fixed(preview: ccResizableVerticalStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcResizablePlayground {
  CcResizablePlayground({
    required this.horizontal,
    required this.thickness,
    required this.hitSize,
    required this.firstLabel,
    required this.secondLabel,
  });

  final bool horizontal;
  final double thickness;
  final double hitSize;
  final String firstLabel;
  final String secondLabel;
}

/// A labelled pane used as region content in the stories.
Widget _pane(BuildContext context, String label, Color color) {
  final t = context.designSystem!;
  return ColoredBox(
    color: color,
    child: Center(
      child: Text(
        label,
        style: CcTypography.bodySm.copyWith(color: t.textPrimary),
      ),
    ),
  );
}

/// A horizontal split — the canonical tree / diff layout from PR review.
Widget ccResizableHorizontalStory(BuildContext context) {
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
Widget ccResizableVerticalStory(BuildContext context) {
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
Widget ccResizableThreeStory(BuildContext context) {
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
Widget ccResizablePlaygroundStory(
  BuildContext context,
  CcResizablePlaygroundArgs args,
) {
  final t = context.designSystem!;
  final horizontal = args.horizontal;
  final thickness = args.thickness;
  final hitSize = args.hitSize;
  final firstLabel = args.firstLabel;
  final secondLabel = args.secondLabel;
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
