# cc_markdown

In-repo typed-AST Markdown parser and Flutter widget renderer for one-shot content and growing LLM streams. It replaces the former two-engine compatibility layer. Public entry points include `CcMarkdown`, `CcStreamingMarkdown`, `CcMarkdownStreamController`, `CcBlockNode`/`CcInlineNode` and the `CcCustomBlock`/`CcCustomInline` plugin leaves.

```dart
import 'package:cc_markdown/cc_markdown.dart';

CcMarkdown(data: markdown, style: myStyle, selectable: true);
CcStreamingMarkdown.value(data: accumulatedText, style: myStyle);
```

Build `CcMarkdownStyle` from host design tokens; supply highlighting via `codeBuilder`. The parser handles GFM headings, lists, tables, code, links and references, footnotes, `<details>` and emoji shortcodes, tolerates malformed HTML and does not throw. Plugins are priority-ordered with trigger dispatch; bundled plugins handle thinking, artifacts and tool calls. The renderer uses one `Text.rich` per paragraph and `WidgetSpan`s for inline builders. `CcSelectionScope` provides feed-level selection and artifact-copy filtering. An always-on LRU caches parses by source, plugin-set identity and options; use `parseEphemeral` for volatile intermediates. Streaming seals immutable blocks and reparses only the new tail; sealed widgets are reused by identity.

## Mermaid limits

A **closed** ` ```mermaid ` fence becomes `CcMermaid`, lazily parsed at render time by `CcMermaidView`; an open fence remains code while streaming. Supported dialects: `flowchart`/`graph`, `stateDiagram(-v2)`, `classDiagram`, `erDiagram`, `sequenceDiagram`, `pie` and `timeline`. Other dialects, such as `gantt`, fall back to source as a code block rather than rendering a diagram. Pure-Dart dialect parsers and layout produce a `CcMermaidScene`, drawn by `CustomPainter` without WebView or JS. Graph dialects use a compound layered layout: each subgraph is laid out as its own box, edges cross box borders through ports, coordinates come from Brandes–Köpf and edges route orthogonally. As in mermaid, an edge naming a subgraph attaches to its border, and a subgraph's `direction` applies only when nothing links across that border. Style with `CcMermaidStyle` or `CcMarkdownStyle.mermaid`; author colors (`%%{init}%%`, `classDef`, `style`) are parsed but **not applied** to protect theme/contrast. Diagrams scale down to width, scroll below `minScale` and expose `mermaidSemanticLabel` to screen readers.

Parser, AST, plugins, cache and streaming boundary scanner are pure Dart; rendering and layout use Flutter widgets. Only `selection/selection_region.dart` and `selection/context_menu.dart` import Material for selection controls. No Riverpod, host-app dependency or bundled syntax highlighter. To measure parser/stream/cache/diagram parse costs from this package, run `fvm dart run benchmark/parser_bench.dart`; Flutter text-metric-dependent layout is covered separately by `test/mermaid/mermaid_layout_test.dart`.
