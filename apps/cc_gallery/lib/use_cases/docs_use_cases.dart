import 'package:cc_gallery/doc_page.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Documentation pages for the gallery — the Storybook-style intro section.
///
/// Each page is a single-use-case component under the `[Docs]` category, so it
/// shows as one clickable entry in the sidebar (`enableLeafComponents`). The
/// `[Docs]` category and the leading `Welcome` page are floated to the front of
/// the navigation by `orderedNav` in `main.dart`.

const _path = '[Docs]';

// ─────────────────────────────────────────────────────────────────────────
// Welcome
// ─────────────────────────────────────────────────────────────────────────

/// Overview of cc_ui and the gallery.
@widgetbook.UseCase(name: 'Welcome', type: Welcome, path: _path)
Widget welcomeUseCase(BuildContext context) => const Welcome();

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
          'ships lives here, and this gallery is its live catalogue.',
      children: [
        DocSection(
          title: 'What this is',
          children: [
            DocText(
              'A Widgetbook gallery of every design token and Cc* component, '
              'rendered exactly as the app renders them. Use it to browse the '
              'system, audit a component across its states, and check both '
              'themes before shipping UI.',
            ),
            DocBullets([
              ('Docs', 'these pages — orientation, principles, theming, usage.'),
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
              'Visually that is a warm near-white canvas, ink-black text, and a '
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
              'the CcTheme inherited widget, and every surface is a Cc* '
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
                    'knobs to see its full state space.',
              ),
            ]),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Principles
// ─────────────────────────────────────────────────────────────────────────

/// The five core design principles.
@widgetbook.UseCase(name: 'Principles', type: Principles, path: _path)
Widget principlesUseCase(BuildContext context) => const Principles();

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
                'motion, color, and "life" must report real agent state — '
                    'thinking, running, blocked, done, cost. If it conveys '
                    'nothing an agent is doing, it is cut.',
              ),
              (
                'Situational command in one glance',
                'surface status, ownership, and the next action by default; '
                    'bury nothing essential a level deep.',
              ),
              (
                'Distinctive through behavior, not skins',
                'the point of difference is how living agent work is '
                    'represented, not a louder palette.',
              ),
              (
                'Product discipline, earned brand moments',
                'day-to-day surfaces stay quiet, dense, and consistent; '
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
              ('', 'Generic SaaS dashboard — gradient hero-metric cards, '
                  'identical card grids, purple gradients.'),
              ('', 'Heavy enterprise IDE chrome — gray-on-gray density with no '
                  'hierarchy.'),
              ('', 'Default component-kit / template feel — the out-of-the-box '
                  'reading this work exists to escape.'),
              ('', 'Playful / consumer / cute — emoji, springy or elastic '
                  'motion, toy-like blobs.'),
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

// ─────────────────────────────────────────────────────────────────────────
// Theming
// ─────────────────────────────────────────────────────────────────────────

/// How tokens, themes, and fonts work.
@widgetbook.UseCase(name: 'Theming', type: Theming, path: _path)
Widget themingUseCase(BuildContext context) => const Theming();

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
              'Manrope for UI text, JetBrains Mono for code. Resolve fonts via '
              'CcFonts.ui / CcFonts.code — never a raw family string. Use the '
              'CcTypography scale (display, title, body, caption, label) for '
              'sizing.',
            ),
            DocText(
              'Hierarchy comes from size and color, never weight: the UI runs a '
              'single 400 weight, and the uppercase tracked label eyebrow is '
              'the one exception.',
            ),
          ],
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Usage
// ─────────────────────────────────────────────────────────────────────────

/// How to consume cc_ui and contribute to the gallery.
@widgetbook.UseCase(name: 'Usage', type: Usage, path: _path)
Widget usageUseCase(BuildContext context) => const Usage();

/// The usage / getting-started page.
class Usage extends StatelessWidget {
  /// Creates the usage page.
  const Usage({super.key});

  @override
  Widget build(BuildContext context) {
    return const DocPage(
      eyebrow: 'Guide',
      title: 'Using cc_ui',
      lede:
          'Build UI exclusively from the Cc* components, themed by CcTheme. '
          'The host app renders these on top of its Material root without '
          'depending on Material.',
      children: [
        DocSection(
          title: 'Components',
          children: [
            DocText(
              'Reach for the Cc* family for every surface — CcButton, '
              'CcTextField, CcDialog, CcSidebar, CcCard, CcTooltip, and the '
              'rest. Browse them under Components.',
            ),
            DocCode(
              'CcButton(\n'
              "  label: 'Add agent',\n"
              '  onPressed: _addAgent,\n'
              ');',
            ),
          ],
        ),
        DocSection(
          title: 'Overlays',
          children: [
            DocText(
              'Anything presented into the root overlay (dialogs, toasts, '
              'popovers, sub-windows) sits above the route Material, so it does '
              'not inherit a usable text theme. showCcDialog wraps content in a '
              'complete design-system DefaultTextStyle; any new off-Material '
              'overlay surface must do the same.',
            ),
          ],
        ),
        DocSection(
          title: 'Do / don’t',
          children: [
            DocBullets([
              ('Do', 'read tokens via context.designSystem and resolve fonts '
                  'via CcFonts.'),
              ('Do', 'write user-facing copy in sentence case — "Add agent", '
                  'not "Add Agent".'),
              ('Don’t', 'import material.dart or cupertino.dart inside '
                  'cc_ui — it builds on widgets only.'),
              ('Don’t', 'create hierarchy with font weight; use size and '
                  'color.'),
            ]),
          ],
        ),
        DocSection(
          title: 'Adding to this gallery',
          children: [
            DocText(
              'Annotate a builder with @widgetbook.UseCase (set name, type, and '
              'a [Category]/Folder path), then regenerate the navigation tree:',
            ),
            DocCode(
              'flutter pub run build_runner build --delete-conflicting-outputs',
            ),
          ],
        ),
      ],
    );
  }
}
