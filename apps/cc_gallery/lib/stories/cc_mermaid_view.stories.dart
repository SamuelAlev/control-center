import 'package:cc_gallery/showcase.dart';
import 'package:cc_gallery/stories/support/markdown_samples.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_mermaid_view.stories.g.dart';

/// Stories for the cc_markdown engine: one-shot rendering, live streaming, and
/// a compact variant. The gallery builds its own [CcMarkdownStyle] from cc_ui
/// tokens (it cannot import the host app's `appMarkdownStyle`); the shared
/// fixtures live in `support/markdown_samples.dart`.

const _path = '[Components]/Content';

const component = ComponentMeta(name: 'CcMermaidView', path: _path);

const meta = Meta(Showcase.new);

final $MermaidDiagrams = _Story(
  name: 'Mermaid diagrams',
  args: _Args.fixed(preview: ccMermaidStory),
);

/// Every mermaid dialect the engine draws, in one scroll — the reference for
/// checking a shape, a marker, or a theme change at a glance.
Widget ccMermaidStory(BuildContext context) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final style = galleryMermaidStyle(context);
  return Center(
    child: SizedBox(
      width: 760,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (title, source) in mermaidSamples) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: t.textTertiary,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: t.bgSecondary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: t.borderSecondary),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CcMermaidView(source: source, style: style),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
  );
}
