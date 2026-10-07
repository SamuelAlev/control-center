import 'package:cc_gallery/doc_page.dart';
import 'package:cc_gallery/showcase.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'welcome.stories.g.dart';

/// A documentation page of the gallery's Storybook-style intro section.
///
/// Each page is a one-story component under the `[Docs]` category, with no
/// generated component docs (`noDocs`). The `[Docs]` category and the leading
/// `Welcome` page are floated to the front of the navigation by
/// `orderedComponents` in `main.dart`.

const _path = '[Docs]';

const component = ComponentMeta(
  name: 'Welcome',
  path: _path,
  docsBuilder: noDocs,
);

const meta = Meta(Showcase.new);

final $Welcome = _Story(args: _Args.fixed(preview: welcomeStory));

/// Overview of cc_ui and the gallery.
Widget welcomeStory(BuildContext context) => const Welcome();

/// The gallery's landing/overview page.
class Welcome extends StatelessWidget {
  /// Creates the welcome page.
  const Welcome({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      eyebrow: 'Control Center · Design system',
      title: 'cc_ui',
      lede:
          'The in-repo design system for Control Center — the cockpit for '
          'multi-agent software development. Every visual component the app '
          'ships lives here and this gallery is its live catalogue.',
      children: [
        DocSection(
          title: 'What this is',
          children: [
            DocText(
              'A Widgetbook gallery of every design token and Cc* component, '
              'rendered exactly as the app renders them. Use it to browse the '
              'system, audit a component across its states and check both '
              'themes before shipping UI.',
            ),
            DocBullets([
              (
                'Docs',
                'these pages — orientation, principles, theming, usage.',
              ),
              ('Foundations', 'the raw tokens: color, type, spacing, motion.'),
              ('Components', 'the Cc* widget library, each with a playground.'),
            ]),
          ],
        ),
        DocSection(
          title: 'Brand',
          children: [
            DocText(
              'A living, agentic system with the restraint of an operator '
              'tool. Three words: alive, composed, precise. The interface '
              'conveys that autonomous work is happening through honest '
              'presence and status, never through ornament.',
            ),
            DocText(
              'Visually that is a warm near-white canvas, ink-black text and a '
              'single orange accent — quiet by default, with expression '
              'reserved for a few earned moments.',
            ),
          ],
        ),
        DocSection(
          title: 'Purist by construction',
          children: [
            DocText(
              'cc_ui builds on package:flutter/widgets.dart only — no Material, '
              'no Cupertino, no Scaffold or ink. Design tokens travel through '
              'the CcTheme inherited widget and every surface is a Cc* '
              'component. That is what keeps the system from reading as a '
              'default component kit.',
            ),
          ],
        ),
        DocSection(
          title: 'Getting around',
          children: [
            DocBullets([
              (
                'Theme',
                'toggle Light / Dark in the addons panel — every page repaints '
                    'from the live tokens.',
              ),
              (
                'Viewport',
                'switch desktop widths to exercise dense and collapsed layouts.',
              ),
              (
                'Playground',
                'each component opens on its interactive playground; drive the '
                    'args to see its full state space.',
              ),
            ]),
          ],
        ),
      ],
    );
  }
}
