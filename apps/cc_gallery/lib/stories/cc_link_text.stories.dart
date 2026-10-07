import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_link_text.stories.g.dart';

/// Stories for [CcLinkText] — inline text that reads as a link.
///
/// The underline is drawn from a token rather than the text decoration so it
/// keeps its own contrast against the surface; a link is never signalled by
/// color alone.

const _path = '[Components]/Typography';

const component = ComponentMeta(name: 'CcLinkText', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcLinkTextPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    text: StringArg('github.com/anthropics/control-center', name: 'Text'),
    maxLines: IntArg(
      0,
      name: 'Max lines (0 = unbounded)',
      style: const SliderIntArgStyle(min: 0, max: 4, divisions: 4),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccLinkTextPlaygroundStory(context, args),
  ),
);

final $InContext = _Story(
  name: 'In context',
  args: _Args.fixed(preview: ccLinkTextInContextStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcLinkTextPlayground {
  CcLinkTextPlayground({required this.text, required this.maxLines});

  final String text;
  final int maxLines;
}

/// A link in running text, and one standing on its own.
Widget ccLinkTextInContextStory(BuildContext context) {
  final t = context.ds;
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CcLinkText(
            'Open the pull request',
            style: CcTypography.body.copyWith(color: t.fgBrandPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcLinkText(
            'A longer link that wraps across more than one line so the '
            'underline can be seen following the text rather than the box',
            style: CcTypography.bodySm.copyWith(color: t.fgBrandPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          CcLinkText(
            'Truncated to a single line with an ellipsis when the row is tight',
            style: CcTypography.bodySm.copyWith(color: t.fgBrandPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccLinkTextPlaygroundStory(
  BuildContext context,
  CcLinkTextPlaygroundArgs args,
) {
  final t = context.ds;
  final text = args.text;
  final maxLines = args.maxLines;
  return Center(
    child: SizedBox(
      width: 320,
      child: CcLinkText(
        text,
        style: CcTypography.body.copyWith(color: t.fgBrandPrimary),
        maxLines: maxLines == 0 ? null : maxLines,
        overflow: maxLines == 0 ? null : TextOverflow.ellipsis,
      ),
    ),
  );
}
