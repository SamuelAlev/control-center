import 'package:cc_gallery/showcase.dart';
import 'package:cc_gallery/stories/support/markdown_samples.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_markdown.stories.g.dart';

/// Stories for the cc_markdown engine: one-shot rendering, live streaming, and
/// a compact variant. The gallery builds its own [CcMarkdownStyle] from cc_ui
/// tokens (it cannot import the host app's `appMarkdownStyle`); the shared
/// fixtures live in `support/markdown_samples.dart`.

const _path = '[Components]/Content';

const component = ComponentMeta(name: 'CcMarkdown', path: _path);

const meta = Meta(Showcase.new);

final $Compact = _Story(args: _Args.fixed(preview: ccMarkdownCompactStory));

final $Document = _Story(args: _Args.fixed(preview: ccMarkdownDocumentStory));

final $MermaidInMarkdown = _Story(
  name: 'Mermaid in markdown',
  args: _Args.fixed(preview: ccMermaidInMarkdownStory),
);

/// A full one-shot document exercising every core block + inline.
Widget ccMarkdownDocumentStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: CcMarkdown(
          data: markdownKitchenSink,
          selectable: true,
          style: galleryMarkdownStyle(context),
        ),
      ),
    ),
  );
}

/// The compact style variant, side by side conceptually with the default.
Widget ccMarkdownCompactStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 480,
      child: SingleChildScrollView(
        child: CcMarkdown(
          data: markdownKitchenSink,
          selectable: true,
          style: galleryMarkdownStyle(context, compact: true),
        ),
      ),
    ),
  );
}

/// The same fence inside a markdown document, so the block spacing and the
/// engine's fallback path can be checked in context.
Widget ccMermaidInMarkdownStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 640,
      child: SingleChildScrollView(
        child: CcMarkdown(
          data:
              '''
## Deployment flow

```mermaid
${mermaidSamples.first.$2.trim()}
```

An unsupported dialect degrades to its source:

```mermaid
gantt
  title Not drawn
  section A
  task :a1, 2024-01-01, 30d
```
''',
          selectable: true,
          style: galleryMarkdownStyle(
            context,
          ).copyWith(mermaid: galleryMermaidStyle(context)),
        ),
      ),
    ),
  );
}
