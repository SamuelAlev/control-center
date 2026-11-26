import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_marquee_text.stories.g.dart';

/// Stories for [CcMarqueeText] — single-line text that ellipsizes at rest
/// and, while its row is the active one, travels once to show the part the
/// ellipsis hid.
///
/// The stories below are listed under `Components → Content → CcMarqueeText`.
/// With reduced motion nothing travels; the active text wraps onto its extra
/// lines instead.

const _path = '[Components]/Content';

const component = ComponentMeta(name: 'CcMarqueeText', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcMarqueeTextPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    text: StringArg(
      'Reviews the open pull request against the repository conventions and '
      'reports what it would change',
      name: 'Text',
    ),
    active: BoolArg(true, name: 'Active'),
    width: DoubleArg(
      240,
      name: 'Width',
      style: const SliderDoubleArgStyle(min: 80, max: 480, divisions: 80),
    ),
    velocity: DoubleArg(
      40,
      name: 'Velocity (px/s)',
      style: const SliderDoubleArgStyle(min: 10, max: 160, divisions: 15),
    ),
    reducedMotionLines: IntArg(
      1,
      name: 'Lines when motion is reduced',
      style: const SliderIntArgStyle(min: 1, max: 4, divisions: 3),
    ),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccMarqueeTextPlaygroundStory(context, args),
  ),
);

final $ActiveRow = _Story(
  name: 'Active row',
  args: _Args.fixed(preview: ccMarqueeTextActiveRowStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcMarqueeTextPlayground {
  CcMarqueeTextPlayground({
    required this.text,
    required this.active,
    required this.width,
    required this.velocity,
    required this.reducedMotionLines,
  });

  final String text;
  final bool active;
  final double width;
  final double velocity;
  final int reducedMotionLines;
}

/// A short list where the row under the pointer is the active one: its name
/// and description each travel once, the other rows stay ellipsized.
Widget ccMarqueeTextActiveRowStory(BuildContext context) =>
    const Center(child: _ActiveRowList());

/// Interactive playground — flip Active to restart the pass.
Widget ccMarqueeTextPlaygroundStory(
  BuildContext context,
  CcMarqueeTextPlaygroundArgs args,
) {
  final t = context.designSystem;
  return Center(
    child: SizedBox(
      width: args.width,
      child: CcMarqueeText(
        args.text,
        active: args.active,
        velocity: args.velocity,
        reducedMotionLines: args.reducedMotionLines,
        style: CcTypography.body.copyWith(color: t?.textPrimary),
      ),
    ),
  );
}

class _ActiveRowList extends StatefulWidget {
  const _ActiveRowList();

  @override
  State<_ActiveRowList> createState() => _ActiveRowListState();
}

class _ActiveRowListState extends State<_ActiveRowList> {
  static const _rows = [
    (
      'review-pull-request',
      'Reviews the open pull request against the repository conventions and '
          'reports what it would change',
    ),
    (
      'translate-manual',
      'Translates the manual pages that changed since the last release into '
          'every supported language',
    ),
    ('release-notes', 'Drafts release notes'),
  ];

  var _active = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem;
    return SizedBox(
      width: 280,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, (name, description)) in _rows.indexed)
            MouseRegion(
              onEnter: (_) => setState(() => _active = index),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: index == _active ? t?.hover : null,
                  borderRadius: AppRadii.brMd,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CcMarqueeText(
                        name,
                        active: index == _active,
                        style: CcTypography.body.copyWith(
                          color: t?.textPrimary,
                          fontWeight: CcTypography.mediumWeight,
                        ),
                      ),
                      CcMarqueeText(
                        description,
                        active: index == _active,
                        style: CcTypography.caption.copyWith(
                          color: t?.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
