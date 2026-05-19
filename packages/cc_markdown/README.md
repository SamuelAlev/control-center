# cc_markdown

Control Center's in-repo markdown engine — a custom typed-AST parser and Flutter
widget renderer that replaces `flutter_smooth_markdown` and `flutter_markdown_plus`
with one performance-first stack built for both LLM streaming and normal
one-shot rendering.

## Why

The app rendered markdown through two third-party engines glued together by an
app-side compatibility layer. Both had real gaps (broken nested lists, no setext
headings, naive emphasis; no streaming, no plugins, run-splitting inline
builders) and performance ceilings. cc_markdown replaces them with a single
engine we own end to end.

## What you get

- **Typed sealed AST** (`CcBlockNode` / `CcInlineNode`), value-equal for cheap
  memoization, `CcCustomBlock`/`CcCustomInline` as the only open plugin leaves.
- **Hand-written GitHub-flavored parser**: headings (ATX + setext), fenced +
  indented code, blockquotes with lazy continuation, ordered/unordered/task
  lists, GFM tables, strikethrough, autolinks (incl. bare-URL extension),
  footnotes, link-reference definitions, `<details>`, HTML tolerance. Never
  throws.
- **Plugin API**: priority-ordered block/inline plugins with O(1) trigger
  dispatch. Ships `CcThinkingPlugin` / `CcArtifactPlugin` / `CcToolCallPlugin`.
- **Widget renderer**: one `Text.rich` per paragraph (inline builders embed as
  `WidgetSpan`s), an override registry with per-node `canBuild` fall-through.
- **Always-on LRU parse cache** keyed by `(source, plugin-set identity, parse
options)`, plus `parseEphemeral` for volatile streaming intermediates.
- **First-class incremental streaming**: `CcMarkdownStreamController` seals
  immutable blocks and parses only the newly-sealed delta; `CcStreamingMarkdown`
  memoizes sealed-block widgets by identity so a token rebuilds only the tail.
- **Selection**: `CcSelectionScope` (one region per feed) + copy-artifact
  filtering. The only files that import Material.
- **Native mermaid diagrams**: a ` ```mermaid ` fence becomes a drawn
  diagram, no WebView, no JS bridge, no new dependency (see below).

## Mermaid

A CLOSED ` ```mermaid ` fence parses to a first-class `CcMermaid` AST node
(raw source; the diagram grammar is parsed lazily at render time and memoized)
and renders through `CcMermaidView`. An open fence stays a code block, so a
streaming diagram doesn't flicker through half-parsed layouts.

Supported dialects:

| Dialect               | Coverage                                                                                                                                                                                                                     |
| --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `flowchart` / `graph` | all five directions, 14 vertex shapes, solid/dotted/thick/invisible links, both end markers, pipe + inline edge labels, extra-dash lengths, `&` fan-out, chains, nested `subgraph`, `click`, `:::`/`class`                   |
| `stateDiagram(-v2)`   | `[*]` start/terminal markers, transitions + labels, `state … as`, composite states, `<<choice>>` / `<<fork>>` / `<<join>>`, notes                                                                                            |
| `classDiagram`        | compartment boxes (attributes / methods), stereotypes, generics, inheritance / composition / aggregation / dependency markers, cardinalities, labels, notes                                                                  |
| `erDiagram`           | entity boxes with attribute rows, crow's-foot cardinality at both ends, identifying vs non-identifying lines, relationship labels                                                                                            |
| `sequenceDiagram`     | participants + actors, every arrow form, activations (`+`/`-` and explicit), notes (left/right/over), `loop`/`alt`+`else`/`opt`/`par`+`and`/`critical`+`option`/`break`/`rect` frames, dividers, `autonumber`, self-messages |
| `pie`                 | title, `showData`, labeled legend, in-slice percentages                                                                                                                                                                      |
| `timeline`            | title, `section` bands, periods with multiple events                                                                                                                                                                         |

Everything else (`gantt`, `mindmap`, `journey`, `gitGraph`, …) reports itself as
unsupported and the host renders the source as a code block — the engine **never
throws**, on any input.

How it works: pure-Dart dialect parsers (`src/mermaid/parse/`) build a small
typed model, layout (`src/mermaid/layout/`) turns it into a `CcMermaidScene` of
positioned primitives and a `CustomPainter` draws it. The graph family shares
one layered (Sugiyama-style) layout: cycle-breaking, longest-path ranking with
DOUBLED ranks so edge labels always get a free rank, dummy-node routing,
barycenter ordering with cluster contiguity, median relaxation for coordinates,
then ONE coordinate transform for `LR`/`RL`/`BT`. Scenes carry roles, not colors,
so a theme flip is a repaint.

Style it with `CcMermaidStyle` (or `CcMarkdownStyle.mermaid`). Author theming
(`%%{init}%%`, `classDef`, `style`) is parsed but deliberately **not applied** —
hardcoded hex from an LLM would break dark mode and the contrast floor. Diagrams
scale down to the available width (never up) and start scrolling instead of
shrinking past `minScale`; every diagram also exposes a generated text
alternative (`mermaidSemanticLabel`) to screen readers.

## Usage

```dart
import 'package:cc_markdown/cc_markdown.dart';

// One-shot.
CcMarkdown(data: markdown, style: myStyle, selectable: true);

// Streaming (drop-in for growing LLM text).
CcStreamingMarkdown.value(data: accumulatedText, style: myStyle);
```

Build a `CcMarkdownStyle` from your design tokens (the package never reads a
`Theme`) and pass syntax highlighting in via the `codeBuilder` callback.

## Layering

`ast/`, `parser/`, `plugins/`, `cache/`, `mermaid/model.dart`, `mermaid/parse/`,
and the streaming boundary scanner are pure Dart. `render/`, `mermaid/layout/`,
`mermaid/render/` and the widgets build on `package:flutter/widgets.dart`.
Only `selection/selection_region.dart` and `selection/context_menu.dart` import
Material (for `SelectionArea` / `AdaptiveTextSelectionToolbar`). No Riverpod, no
a syntax highlighter (`highlight` historically, `shiki_flutter` today), no host-app imports — enforced by the app's architecture test.

## Benchmark

`fvm dart run benchmark/parser_bench.dart` — one-shot parse throughput,
streaming-replay per-append cost, cache-hit micro-bench and mermaid dialect
parse cost (~30–55 µs cold for a realistic diagram; layout needs Flutter text
metrics, so it is covered by `test/mermaid/mermaid_layout_test.dart`).
