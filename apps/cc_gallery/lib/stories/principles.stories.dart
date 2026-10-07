import 'package:cc_gallery/doc_page.dart';
import 'package:cc_gallery/showcase.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'principles.stories.g.dart';

/// A documentation page of the gallery's Storybook-style intro section.
///
/// Each page is a one-story component under the `[Docs]` category, with no
/// generated component docs (`noDocs`). The `[Docs]` category and the leading
/// `Welcome` page are floated to the front of the navigation by
/// `orderedComponents` in `main.dart`.

const _path = '[Docs]';

const component = ComponentMeta(
  name: 'Principles',
  path: _path,
  docsBuilder: noDocs,
);

const meta = Meta(Showcase.new);

final $Principles = _Story(args: _Args.fixed(preview: principlesStory));

/// The five core design principles.
Widget principlesStory(BuildContext context) => const Principles();

/// The design-principles page.
class Principles extends StatelessWidget {
  /// Creates the principles page.
  const Principles({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      eyebrow: 'Foundations',
      title: 'Design principles',
      lede:
          'Five rules govern every surface. When a design choice is in '
          'tension, these decide it.',
      children: [
        DocSection(
          title: 'The five',
          children: [
            DocBullets([
              (
                'Presence over decoration',
                'motion, color and "life" must report real agent state — '
                    'thinking, running, blocked, done, cost. If it conveys '
                    'nothing an agent is doing, it is cut.',
              ),
              (
                'Situational command in one glance',
                'surface status, ownership and the next action by default; '
                    'bury nothing essential a level deep.',
              ),
              (
                'Distinctive through behavior, not skins',
                'the point of difference is how living agent work is '
                    'represented, not a louder palette.',
              ),
              (
                'Product discipline, earned brand moments',
                'day-to-day surfaces stay quiet, dense and consistent; '
                    'expression is reserved for a few thresholds.',
              ),
              (
                'Team-ready, solo-first',
                'optimize for one operator today, but keep attribution and '
                    'ownership legible so team use is additive, not a rewrite.',
              ),
            ]),
          ],
        ),
        DocSection(
          title: 'Anti-references',
          children: [
            DocText(
              'Hard constraints. If a surface drifts toward any of these, it is '
              'wrong:',
            ),
            DocBullets([
              (
                '',
                'Generic SaaS dashboard — gradient hero-metric cards, '
                    'identical card grids, purple gradients.',
              ),
              (
                '',
                'Heavy enterprise IDE chrome — gray-on-gray density with no '
                    'hierarchy.',
              ),
              (
                '',
                'Default component-kit / template feel — the out-of-the-box '
                    'reading this work exists to escape.',
              ),
              (
                '',
                'Playful / consumer / cute — emoji, springy or elastic '
                    'motion, toy-like blobs.',
              ),
            ]),
          ],
        ),
        DocSection(
          title: 'Accessibility',
          children: [
            DocText(
              'Target WCAG 2.1 AA. Never status by color alone — pair it with '
              'an icon, label, or shape. Every animation has a reduced-motion '
              'path. Keyboard-first, with visible 2px focus rings.',
            ),
          ],
        ),
      ],
    );
  }
}
