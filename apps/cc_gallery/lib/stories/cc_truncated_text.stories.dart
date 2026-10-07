import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_truncated_text.stories.g.dart';

/// Stories for [CcTruncatedText] — single-line text that truncates with an
/// ellipsis and discloses its full content in a tooltip only when actually
/// truncated.
///
/// The stories below are listed under `Components → Content → CcTruncatedText`
/// (the `ComponentMeta` name and bracketed `path` segments). Hover the
/// truncated sample to see the disclosure tooltip.

const _path = '[Components]/Content';

const component = ComponentMeta(name: 'CcTruncatedText', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTruncatedTextPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    text: StringArg('workspaces/acme-prod/agents/reviewer-01', name: 'Text'),
    width: DoubleArg(
      160,
      name: 'Width',
      style: const SliderDoubleArgStyle(min: 40, max: 400, divisions: 90),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccTruncatedTextPlaygroundStory(context, args),
  ),
);

final $FitsVsTruncated = _Story(
  name: 'Fits vs truncated',
  args: _Args.fixed(preview: ccTruncatedTextStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTruncatedTextPlayground {
  CcTruncatedTextPlayground({required this.text, required this.width});

  final String text;
  final double width;
}

/// Fitting text renders as a plain label; the constrained copy truncates and
/// discloses its full text on hover.
Widget ccTruncatedTextStory(BuildContext context) {
  return const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 240, child: CcTruncatedText('Fits without truncation')),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 240,
          child: CcTruncatedText(
            'feature/orchestration-guardrails-rollout-plan-v2-final-really',
          ),
        ),
      ],
    ),
  );
}

/// Interactive playground — shrink the width until the label truncates and the
/// hover tooltip appears.
Widget ccTruncatedTextPlaygroundStory(
  BuildContext context,
  CcTruncatedTextPlaygroundArgs args,
) {
  final text = args.text;
  final width = args.width;
  return Center(
    child: SizedBox(width: width, child: CcTruncatedText(text)),
  );
}
