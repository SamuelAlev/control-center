import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_popover.stories.g.dart';

/// Stories for [CcPopover] — a flat floating panel anchored to a trigger.
///
/// The stories below are listed under `Components → Navigation & Overlays →
/// CcPopover` (the `ComponentMeta` name and bracketed `path` segments).
/// Builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcPopover', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcPopoverPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    matchWidth: BoolArg(false, name: 'Match target width'),
    barrierDismissible: BoolArg(true, name: 'Barrier dismissible'),
    offsetY: DoubleArg(
      6,
      name: 'Vertical offset',
      style: const SliderDoubleArgStyle(min: 0, max: 24, divisions: 24),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccPopoverPlaygroundStory(context, args)),
);

final $ControllerDriven = _Story(
  name: 'Controller driven',
  args: _Args.fixed(preview: ccPopoverControllerStory),
);

final $Default = _Story(args: _Args.fixed(preview: ccPopoverDefaultStory));

final $MatchTargetWidth = _Story(
  name: 'Match target width',
  args: _Args.fixed(preview: ccPopoverMatchWidthStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcPopoverPlayground {
  CcPopoverPlayground({
    required this.matchWidth,
    required this.barrierDismissible,
    required this.offsetY,
  });

  final bool matchWidth;
  final bool barrierDismissible;
  final double offsetY;
}

void _noop() {}

/// A simple filter popover anchored under a button — the canonical usage.
Widget ccPopoverDefaultStory(BuildContext context) {
  return Center(
    child: CcPopover(
      semanticLabel: 'Filter pull requests',
      target: const CcButton(
        variant: CcButtonVariant.secondary,
        icon: CcIcons.listFilter,
        onPressed: _noop,
        child: Text('Filter'),
      ),
      overlayBuilder: (context, targetSize) {
        final t = context.designSystem!;
        return SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by status',
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: 10),
                for (final status in const ['Open', 'Merged', 'Closed']) ...[
                  Text(
                    status,
                    style: CcTypography.body.copyWith(color: t.textPrimary),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

/// Width-matched dropdown — the panel is constrained to the trigger's width,
/// the way a select or workspace switcher renders.
Widget ccPopoverMatchWidthStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 260,
      child: CcPopover(
        matchTargetWidth: true,
        semanticLabel: 'Switch workspace',
        target: const CcButton(
          variant: CcButtonVariant.line,
          icon: CcIcons.folderGit2,
          onPressed: _noop,
          child: Text('control-center'),
        ),
        overlayBuilder: (context, targetSize) {
          final t = context.designSystem!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final ws in const ['control-center', 'rift', 'cc-ui'])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    child: Text(
                      ws,
                      style: CcTypography.body.copyWith(color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    ),
  );
}

/// Driven by an external [CcOverlayController] — open/close is owned by the
/// host, here wired to a second button alongside the anchor.
Widget ccPopoverControllerStory(BuildContext context) {
  return const Center(child: _ControllerPopoverDemo());
}

/// Interactive playground — drive placement and dismissal behaviour.
Widget ccPopoverPlaygroundStory(
  BuildContext context,
  CcPopoverPlaygroundArgs args,
) {
  final matchWidth = args.matchWidth;
  final barrierDismissible = args.barrierDismissible;
  final offsetY = args.offsetY;
  return Center(
    child: CcPopover(
      matchTargetWidth: matchWidth,
      barrierDismissible: barrierDismissible,
      offset: Offset(0, offsetY),
      semanticLabel: 'Agent actions',
      target: const CcButton(
        icon: CcIcons.bot,
        onPressed: _noop,
        child: Text('Architect'),
      ),
      overlayBuilder: (context, targetSize) {
        final t = context.designSystem!;
        return SizedBox(
          width: 220,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final action in const ['Dispatch', 'View runs', 'Stop'])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      action,
                      style: CcTypography.body.copyWith(color: t.textPrimary),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

class _ControllerPopoverDemo extends StatefulWidget {
  const _ControllerPopoverDemo();

  @override
  State<_ControllerPopoverDemo> createState() => _ControllerPopoverDemoState();
}

class _ControllerPopoverDemoState extends State<_ControllerPopoverDemo> {
  final _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcButton(
          variant: CcButtonVariant.secondary,
          icon: CcIcons.sparkles,
          onPressed: _controller.show,
          child: const Text('Open details'),
        ),
        const SizedBox(width: 12),
        CcPopover(
          controller: _controller,
          toggleOnTargetTap: false,
          target: const CcButton(
            variant: CcButtonVariant.ghost,
            icon: CcIcons.gitPullRequest,
            onPressed: _noop,
            child: Text('PR #128'),
          ),
          overlayBuilder: (context, targetSize) {
            final t = context.designSystem!;
            return SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wire the dispatch engine',
                      style: CcTypography.title.copyWith(color: t.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reviewed by claude-opus · 3 files changed',
                      style: CcTypography.caption.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
