import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_tooltip.stories.g.dart';

/// Stories for [CcTooltip] — a hover-driven, ink-dark helper panel.
///
/// The stories below are listed under `Components → Feedback → CcTooltip` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] and
/// canvas. Hover the target to dwell the tooltip into view.

const _path = '[Components]/Feedback';

const component = ComponentMeta(name: 'CcTooltip', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTooltipPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    message: StringArg('Deploy this agent to the workspace', name: 'Message'),
    maxWidth: DoubleArg(
      280,
      name: 'Max width',
      style: const SliderDoubleArgStyle(min: 120, max: 400, divisions: 70),
    ),
    showDelayMs: DoubleArg(
      500,
      name: 'Show delay (ms)',
      style: const SliderDoubleArgStyle(min: 0, max: 1500, divisions: 75),
    ),
    placement: EnumArg<CcTooltipPlacement>(
      CcTooltipPlacement.values.first,
      name: 'Placement',
      values: CcTooltipPlacement.values,
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccTooltipPlaygroundStory(context, args)),
);

final $Default = _Story(args: _Args.fixed(preview: ccTooltipDefaultStory));

final $LongAndShort = _Story(
  name: 'Long and short',
  args: _Args.fixed(preview: ccTooltipLongAndShortStory),
);

final $Placements = _Story(
  args: _Args.fixed(preview: ccTooltipPlacementsStory),
);

final $RichContent = _Story(
  name: 'Rich content',
  args: _Args.fixed(preview: ccTooltipRichContentStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTooltipPlayground {
  CcTooltipPlayground({
    required this.message,
    required this.maxWidth,
    required this.showDelayMs,
    required this.placement,
  });

  final String message;
  final double maxWidth;
  final double showDelayMs;
  final CcTooltipPlacement placement;
}

void _noop() {}

/// The default: a short plain-text message anchored beneath its target.
Widget ccTooltipDefaultStory(BuildContext context) {
  return const Center(
    child: CcTooltip(
      message: 'Re-run the failed checks',
      child: CcButton(onPressed: _noop, child: Text('Hover me')),
    ),
  );
}

/// A long message that wraps within [CcTooltip.maxWidth] versus a short one,
/// so the panel sizing across content lengths is visible side by side.
Widget ccTooltipLongAndShortStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 32,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcTooltip(
          message: 'Merge',
          child: CcButton(onPressed: _noop, child: Text('Short')),
        ),
        CcTooltip(
          message:
              'This pull request targets a protected branch. Squash and merge '
              'requires a passing review from a code owner on the workspace.',
          child: CcButton(onPressed: _noop, child: Text('Wraps to max width')),
        ),
      ],
    ),
  );
}

/// Rich [CcTooltip.tip] content instead of a plain message — an icon row plus
/// a label, the kind of detail a pipeline status chip surfaces on hover.
Widget ccTooltipRichContentStory(BuildContext context) {
  final t = context.designSystem;
  return Center(
    child: CcTooltip(
      tip: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CcIcons.gitBranch, size: 14, color: t?.textWhite),
          const SizedBox(width: 6),
          Text(
            'agent/refactor-auth · 3 commits ahead',
            style: CcTypography.caption.copyWith(color: t?.textWhite),
          ),
        ],
      ),
      child: const CcButton(onPressed: _noop, child: Text('Workspace status')),
    ),
  );
}

/// Interactive playground — drive the message, dwell, width and placement.
Widget ccTooltipPlaygroundStory(
  BuildContext context,
  CcTooltipPlaygroundArgs args,
) {
  final message = args.message;
  final maxWidth = args.maxWidth;
  final showDelayMs = args.showDelayMs;
  final placement = args.placement;
  return Center(
    child: CcTooltip(
      message: message,
      maxWidth: maxWidth,
      showDelay: Duration(milliseconds: showDelayMs.round()),
      placement: placement,
      child: const CcButton(onPressed: _noop, child: Text('Hover me')),
    ),
  );
}

/// Every placement rendered at once, so the caret direction on each side is
/// visible together (hover each target to dwell its tooltip in).
Widget ccTooltipPlacementsStory(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 48,
      runSpacing: 32,
      alignment: WrapAlignment.center,
      children: [
        for (final placement in CcTooltipPlacement.values)
          CcTooltip(
            message: 'Caret points back at the trigger',
            placement: placement,
            child: CcButton(onPressed: _noop, child: Text(placement.name)),
          ),
      ],
    ),
  );
}
