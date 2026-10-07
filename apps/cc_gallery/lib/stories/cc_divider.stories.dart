import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_divider.stories.g.dart';

/// Stories for [CcDivider] — the design system's 1px separator hairline.
///
/// The stories below are listed under `Components → Containers → CcDivider`
/// (the `ComponentMeta` name and bracketed `path` segments). The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcDivider', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcDividerPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    axis: EnumArg<Axis>(Axis.values.first, name: 'Axis', values: Axis.values),
    thickness: DoubleArg(
      1,
      name: 'Thickness',
      style: const SliderDoubleArgStyle(min: 1, max: 8, divisions: 7),
    ),
    indent: DoubleArg(
      0,
      name: 'Indent',
      style: const SliderDoubleArgStyle(min: 0, max: 48, divisions: 48),
    ),
    endIndent: DoubleArg(
      0,
      name: 'End indent',
      style: const SliderDoubleArgStyle(min: 0, max: 48, divisions: 48),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccDividerPlaygroundStory(context, args)),
);

final $Horizontal = _Story(
  args: _Args.fixed(preview: ccDividerHorizontalStory),
);

final $ThicknessIndent = _Story(
  name: 'Thickness & indent',
  args: _Args.fixed(preview: ccDividerThicknessIndentStory),
);

final $Vertical = _Story(args: _Args.fixed(preview: ccDividerVerticalStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcDividerPlayground {
  CcDividerPlayground({
    required this.axis,
    required this.thickness,
    required this.indent,
    required this.endIndent,
  });

  final Axis axis;
  final double thickness;
  final double indent;
  final double endIndent;
}

/// A horizontal hairline separating two stacked sections.
Widget ccDividerHorizontalStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Open pull requests',
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
          const SizedBox(height: 12),
          const CcDivider(),
          const SizedBox(height: 12),
          Text(
            'Merged this week',
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        ],
      ),
    ),
  );
}

/// A vertical rule splitting inline content, e.g. metadata in a PR row.
Widget ccDividerVerticalStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final label = CcTypography.bodySm.copyWith(color: t.textSecondary);
  return Center(
    child: SizedBox(
      height: 20,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('claude-opus-4', style: label),
          const SizedBox(width: 12),
          const CcDivider(axis: Axis.vertical),
          const SizedBox(width: 12),
          Text('control-center', style: label),
          const SizedBox(width: 12),
          const CcDivider(axis: Axis.vertical),
          const SizedBox(width: 12),
          Text('workspace · main', style: label),
        ],
      ),
    ),
  );
}

/// Thickness and indent treatments — a hairline, a heavier rule and an inset
/// line that stops short of both edges.
Widget ccDividerThicknessIndentStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final caption = CcTypography.bodySm.copyWith(color: t.textSecondary);
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hairline (1px)', style: caption),
          const SizedBox(height: 8),
          const CcDivider(),
          const SizedBox(height: 20),
          Text('Heavy (3px)', style: caption),
          const SizedBox(height: 8),
          const CcDivider(thickness: 3),
          const SizedBox(height: 20),
          Text('Inset (indent 32, endIndent 32)', style: caption),
          const SizedBox(height: 8),
          const CcDivider(indent: 32, endIndent: 32),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccDividerPlaygroundStory(
  BuildContext context,
  CcDividerPlaygroundArgs args,
) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final axis = args.axis;
  final thickness = args.thickness;
  final indent = args.indent;
  final endIndent = args.endIndent;
  final divider = CcDivider(
    axis: axis,
    thickness: thickness,
    indent: indent,
    endIndent: endIndent,
  );
  final label = CcTypography.bodySm.copyWith(color: t.textSecondary);
  return Center(
    child: axis == Axis.horizontal
        ? SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pipeline run', style: label),
                const SizedBox(height: 12),
                divider,
                const SizedBox(height: 12),
                Text('Review session', style: label),
              ],
            ),
          )
        : SizedBox(
            height: 24,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Repo', style: label),
                const SizedBox(width: 12),
                divider,
                const SizedBox(width: 12),
                Text('Agent', style: label),
              ],
            ),
          ),
  );
}
