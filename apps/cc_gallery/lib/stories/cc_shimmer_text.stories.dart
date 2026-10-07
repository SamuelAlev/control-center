import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_shimmer_text.stories.g.dart';

/// Stories for [CcShimmerText] — a one-line live status ("Thinking…",
/// "Running tests…") with a band of light sweeping through it in reading
/// order.
///
/// The stories below are listed under `Components → Feedback →
/// CcShimmerText`. With reduced motion the label renders still, in its
/// style's own colour.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcShimmerText', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcShimmerTextPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    text: StringArg('Thinking…', name: 'Text'),
    durationMs: IntArg(
      2000,
      name: 'Duration (ms)',
      style: const SliderIntArgStyle(min: 500, max: 5000, divisions: 45),
    ),
    spread: DoubleArg(
      2,
      name: 'Spread (px per character)',
      style: const SliderDoubleArgStyle(min: 0.5, max: 6, divisions: 11),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccShimmerTextPlaygroundStory(context, args),
  ),
);

final $StatusLines = _Story(
  name: 'Status lines',
  args: _Args.fixed(preview: ccShimmerTextStatusLinesStory),
);

final $Sizes = _Story(args: _Args.fixed(preview: ccShimmerTextSizesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcShimmerTextPlayground {
  CcShimmerTextPlayground({
    required this.text,
    required this.durationMs,
    required this.spread,
  });

  final String text;
  final int durationMs;
  final double spread;
}

/// The live lines an agent turn shows between steps, in the transcript's
/// caption style. Longer lines get a proportionally wider band, so each one
/// reads at the same pace.
Widget ccShimmerTextStatusLinesStory(BuildContext context) {
  final style = CcTypography.caption.copyWith(fontWeight: FontWeight.w500);
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in const [
          'Thinking…',
          'Reading lib/main.dart…',
          'Running tests…',
          'Searching the codebase for "WorkspaceDatabaseManager"…',
        ]) ...[
          CcShimmerText(line, style: style),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    ),
  );
}

/// The type scale: caption (transcript), body small and body.
Widget ccShimmerTextSizesStory(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcShimmerText('Thinking…', style: CcTypography.caption),
        SizedBox(height: AppSpacing.md),
        CcShimmerText('Thinking…', style: CcTypography.bodySm),
        SizedBox(height: AppSpacing.md),
        CcShimmerText('Thinking…', style: CcTypography.body),
      ],
    ),
  );
}

/// Interactive playground — tune the band's speed and width.
Widget ccShimmerTextPlaygroundStory(
  BuildContext context,
  CcShimmerTextPlaygroundArgs args,
) {
  return Center(
    child: CcShimmerText(
      args.text,
      duration: Duration(milliseconds: args.durationMs),
      spread: args.spread,
      style: CcTypography.body,
    ),
  );
}
