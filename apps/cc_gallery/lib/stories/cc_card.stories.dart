import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_card.stories.g.dart';

/// Stories for [CcCard] — the design system's flat panel surface.
///
/// Depth comes from the hairline border, not elevation. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcCard', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcCardPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    useSurface: BoolArg(false, name: 'Surface tokens'),
    interactive: BoolArg(true, name: 'Interactive'),
    padding: DoubleArg(
      16,
      name: 'Padding',
      style: const SliderDoubleArgStyle(min: 0, max: 40, divisions: 40),
    ),
    body: StringArg('Reviewing the workspace pipeline run.', name: 'Body'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccCardPlaygroundStory(context, args)),
);

final $Interactive = _Story(args: _Args.fixed(preview: ccCardInteractiveStory));

final $Padding = _Story(args: _Args.fixed(preview: ccCardPaddingStory));

final $Surfaces = _Story(args: _Args.fixed(preview: ccCardSurfacesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcCardPlayground {
  CcCardPlayground({
    required this.useSurface,
    required this.interactive,
    required this.padding,
    required this.body,
  });

  final bool useSurface;
  final bool interactive;
  final double padding;
  final String body;
}

/// A small block of body copy rendered with the design-system text color.
Widget _copy(BuildContext context, String text) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Text(text, style: CcTypography.body.copyWith(color: t.textSecondary));
}

/// The two token surfaces side by side: the white `panel` and the tighter
/// secondary `surface`.
Widget ccCardSurfacesStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        SizedBox(
          width: 260,
          child: CcCard(
            tokens: CcCardTokens.panel(t),
            child: _copy(
              context,
              'Panel — the default white workspace surface.',
            ),
          ),
        ),
        SizedBox(
          width: 260,
          child: CcCard(
            tokens: CcCardTokens.surface(t),
            child: _copy(context, 'Surface — the tighter secondary container.'),
          ),
        ),
      ],
    ),
  );
}

/// An interactive card that washes to the hover color and exposes itself as a
/// semantic button. Hover and press it in the canvas.
Widget ccCardInteractiveStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  return Center(
    child: SizedBox(
      width: 300,
      child: CcCard(
        interactive: true,
        onPressed: () {},
        semanticLabel: 'Open pull request',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'feat: stream agent transcripts',
              style: CcTypography.label.copyWith(color: t.textPrimary),
            ),
            const SizedBox(height: 6),
            _copy(context, '#482 · opened by claude-opus · 3 files changed'),
          ],
        ),
      ),
    ),
  );
}

/// Padding scale — from a dense zero-inset row to a roomy detail panel.
Widget ccCardPaddingStory(BuildContext context) {
  return Center(
    child: Wrap(
      spacing: 16,
      runSpacing: 16,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: [
        SizedBox(
          width: 220,
          child: CcCard(
            padding: EdgeInsets.zero,
            child: _copy(context, 'No padding — host owns the insets.'),
          ),
        ),
        SizedBox(
          width: 220,
          child: CcCard(child: _copy(context, 'Default padding (md).')),
        ),
        SizedBox(
          width: 220,
          child: CcCard(
            padding: const EdgeInsets.all(28),
            child: _copy(context, 'Roomy padding for a detail panel.'),
          ),
        ),
      ],
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccCardPlaygroundStory(BuildContext context, CcCardPlaygroundArgs args) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final useSurface = args.useSurface;
  final interactive = args.interactive;
  final padding = args.padding;
  final body = args.body;
  return Center(
    child: SizedBox(
      width: 300,
      child: CcCard(
        tokens: useSurface ? CcCardTokens.surface(t) : CcCardTokens.panel(t),
        interactive: interactive,
        onPressed: interactive ? () {} : null,
        semanticLabel: 'Workspace card',
        padding: EdgeInsets.all(padding),
        child: _copy(context, body),
      ),
    ),
  );
}
