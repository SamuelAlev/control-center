import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_progress_bar.stories.g.dart';

/// Stories for [CcProgressBar] — the design system's flat horizontal progress
/// indicator.
///
/// The stories below are listed under `Components → Feedback → CcProgressBar`
/// (the `ComponentMeta` name and bracketed `path` segments). The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas. A bare progress bar fills its parent's width, so the
/// builders constrain it with a [SizedBox] for a readable preview.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcProgressBar', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcProgressBarPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    indeterminate: BoolArg(false, name: 'Indeterminate'),
    value: DoubleArg(
      0.6,
      name: 'Value',
      style: const SliderDoubleArgStyle(min: 0, max: 1, divisions: 100),
    ),
    height: DoubleArg(
      4,
      name: 'Height',
      style: const SliderDoubleArgStyle(min: 2, max: 16, divisions: 14),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccProgressBarPlaygroundStory(context, args),
  ),
);

final $Determinate = _Story(
  args: _Args.fixed(preview: ccProgressBarDeterminateStory),
);

final $Heights = _Story(args: _Args.fixed(preview: ccProgressBarHeightsStory));

final $Indeterminate = _Story(
  args: _Args.fixed(preview: ccProgressBarIndeterminateStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcProgressBarPlayground {
  CcProgressBarPlayground({
    required this.indeterminate,
    required this.value,
    required this.height,
  });

  final bool indeterminate;
  final double value;
  final double height;
}

/// The determinate fill at a few fractions, from empty to complete.
Widget ccProgressBarDeterminateStory(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final step in const <(String, double)>[
            ('Cloning repo', 0.0),
            ('Indexing code graph', 0.25),
            ('Running checks', 0.6),
            ('Merging worktree', 0.9),
            ('Pipeline complete', 1.0),
          ]) ...[
            Text(
              '${step.$1} · ${(step.$2 * 100).round()}%',
              style: CcTypography.bodySm.copyWith(color: t?.textSecondary),
            ),
            const SizedBox(height: 6),
            CcProgressBar(value: step.$2),
            const SizedBox(height: 18),
          ],
        ],
      ),
    ),
  );
}

/// The indeterminate state — a short segment slides back and forth when motion
/// is allowed and collapses to a static 30% bar under reduced motion.
Widget ccProgressBarIndeterminateStory(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Agent is thinking…',
            style: CcTypography.bodySm.copyWith(color: t?.textSecondary),
          ),
          const SizedBox(height: 6),
          const CcProgressBar(semanticLabel: 'Claude is working'),
        ],
      ),
    ),
  );
}

/// The height scale — thin trackers for inline rows up to chunky deck bars.
Widget ccProgressBarHeightsStory(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: 320,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final height in const <double>[2, 4, 8, 12]) ...[
            Text(
              '${height.toInt()} px',
              style: CcTypography.bodySm.copyWith(color: t?.textSecondary),
            ),
            const SizedBox(height: 6),
            CcProgressBar(value: 0.65, height: height),
            const SizedBox(height: 18),
          ],
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccProgressBarPlaygroundStory(
  BuildContext context,
  CcProgressBarPlaygroundArgs args,
) {
  final indeterminate = args.indeterminate;
  final value = args.value;
  final height = args.height;
  return Center(
    child: SizedBox(
      width: 320,
      child: CcProgressBar(
        value: indeterminate ? null : value,
        height: height,
        semanticLabel: 'Workspace sync progress',
      ),
    ),
  );
}
