import 'package:cc_gallery/doc_page.dart';
import 'package:cc_gallery/showcase.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'usage.stories.g.dart';

/// A documentation page of the gallery's Storybook-style intro section.
///
/// Each page is a one-story component under the `[Docs]` category, with no
/// generated component docs (`noDocs`). The `[Docs]` category and the leading
/// `Welcome` page are floated to the front of the navigation by
/// `orderedComponents` in `main.dart`.

const _path = '[Docs]';

const component = ComponentMeta(
  name: 'Usage',
  path: _path,
  docsBuilder: noDocs,
);

const meta = Meta(Showcase.new);

final $Usage = _Story(args: _Args.fixed(preview: usageStory));

/// How to consume cc_ui and contribute to the gallery.
Widget usageStory(BuildContext context) => const Usage();

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
              'CcTextField, CcDialog, CcSidebar, CcCard, CcTooltip and the '
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
              (
                'Do',
                'read tokens via context.designSystem and resolve fonts '
                    'via CcFonts.',
              ),
              (
                'Do',
                'write user-facing copy in sentence case — "Add agent", '
                    'not "Add Agent".',
              ),
              (
                'Don’t',
                'import material.dart or cupertino.dart inside '
                    'cc_ui — it builds on widgets only.',
              ),
              (
                'Don’t',
                'create hierarchy with font weight; use size and '
                    'color.',
              ),
            ]),
          ],
        ),
        DocSection(
          title: 'Adding to this gallery',
          children: [
            DocText(
              'Add a lib/stories/<component>.stories.dart file: a '
              'ComponentMeta (name and a [Category]/Folder path), a '
              'Meta(Showcase.new) and one \$-prefixed _Story per state, then '
              'generate its part and the navigation tree:',
            ),
            DocCode('dart run build_runner build'),
          ],
        ),
      ],
    );
  }
}
