import 'package:cc_gallery/doc_page.dart';
import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'theming.stories.g.dart';

/// A documentation page of the gallery's Storybook-style intro section.
///
/// Each page is a one-story component under the `[Docs]` category, with no
/// generated component docs (`noDocs`). The `[Docs]` category and the leading
/// `Welcome` page are floated to the front of the navigation by
/// `orderedComponents` in `main.dart`.

const _path = '[Docs]';

const component = ComponentMeta(
  name: 'Theming',
  path: _path,
  docsBuilder: noDocs,
);

const meta = Meta(Showcase.new);

final $Theming = _Story(args: _Args.fixed(preview: themingStory));

/// How tokens, themes and fonts work.
Widget themingStory(BuildContext context) => const Theming();

/// The theming & tokens page.
class Theming extends StatelessWidget {
  /// Creates the theming page.
  const Theming({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return DocPage(
      eyebrow: 'Foundations',
      title: 'Theming & tokens',
      lede:
          'Read semantic tokens, never raw colors. Tokens resolve from the '
          'nearest CcTheme and lerp between Light and Dark.',
      children: [
        const DocSection(
          title: 'Reading tokens',
          children: [
            DocText(
              'Read the semantic tokens with the context.designSystem '
              'extension; read the full config (brightness, reduced-motion, '
              'resolved fonts) with context.ccTheme. Both fall back gracefully '
              'when there is no CcTheme ancestor.',
            ),
            DocCode(
              'final t = context.designSystem!;\n'
              'return ColoredBox(\n'
              '  color: t.canvas,\n'
              "  child: Text('Hi', style: CcTypography.body.copyWith(color: t.fg)),\n"
              ');',
            ),
          ],
        ),
        DocSection(
          title: 'Core aliases',
          children: [
            const DocText(
              'The warm near-white / ink-black / single-orange system. These '
              'are the tokens day-to-day surfaces reach for first:',
            ),
            DocSwatches([
              ('canvas', t.canvas),
              ('surface', t.surface),
              ('panel', t.panel),
              ('sidebar', t.sidebar),
              ('fg', t.fg),
              ('muted', t.muted),
              ('accent', t.accent),
              ('accentSoft', t.accentSoft),
            ]),
            const DocText(
              'Borders run from borderSoft (the softest hairline) to lineStrong '
              '(dividers that must show); hover and hoverStrong are the subtle '
              'fg washes for rows and pressed states. The full set lives under '
              'Foundations → Tokens.',
            ),
          ],
        ),
        const DocSection(
          title: 'Light & dark',
          children: [
            DocText(
              'There is one token set per brightness; CcTheme animates between '
              'them by lerping every token. Build against the semantic name '
              '(accent, canvas, fg) and both themes come for free — toggle the '
              'addon to verify.',
            ),
          ],
        ),
        const DocSection(
          title: 'Type & fonts',
          children: [
            DocText(
              'Manrope for UI text, Fira Code for code. Resolve fonts via '
              'CcFonts.ui / CcFonts.code — never a raw family string. Use the '
              'CcTypography scale (display, title, body, caption, label) for '
              'sizing.',
            ),
            DocText(
              'Hierarchy comes from size and color, never weight: the UI runs a '
              'single 400 weight and the uppercase tracked label eyebrow is '
              'the one exception.',
            ),
          ],
        ),
      ],
    );
  }
}
