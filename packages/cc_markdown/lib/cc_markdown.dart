/// Control Center markdown engine.
///
/// A self-contained, performance-first markdown stack: typed sealed AST,
/// hand-written GitHub-flavored parser with a plugin API, an always-on LRU
/// parse cache, a widget renderer (one `Text.rich` per paragraph), selection
/// primitives, and first-class incremental streaming for LLM output.
///
/// Consumers import only this barrel:
///
/// ```dart
/// import 'package:cc_markdown/cc_markdown.dart';
/// ```
///
/// Public API is exported here; everything under `src/` is private.
library;

// AST.
export 'package:cc_markdown/src/ast/document.dart';
export 'package:cc_markdown/src/ast/nodes.dart';

// Cache.
export 'package:cc_markdown/src/cache/parse_cache.dart';
export 'package:cc_markdown/src/codec/markdown_ast_codec.dart';

// Mermaid diagrams.
export 'package:cc_markdown/src/mermaid/layout/graph_layout.dart'
    show layoutMermaidGraph;
export 'package:cc_markdown/src/mermaid/layout/pie_layout.dart'
    show layoutMermaidPie;
export 'package:cc_markdown/src/mermaid/layout/scene.dart';
export 'package:cc_markdown/src/mermaid/layout/scene_ops.dart'
    show primitiveBounds, translatePrimitive;
export 'package:cc_markdown/src/mermaid/layout/sequence_layout.dart'
    show layoutMermaidSequence;
export 'package:cc_markdown/src/mermaid/layout/timeline_layout.dart'
    show layoutMermaidTimeline;
export 'package:cc_markdown/src/mermaid/mermaid_style.dart';
export 'package:cc_markdown/src/mermaid/model.dart';
export 'package:cc_markdown/src/mermaid/parse/mermaid_parser.dart'
    show
        clearMermaidParseCache,
        kCcMermaidMaxEdges,
        kCcMermaidMaxNodes,
        kCcMermaidMaxSteps,
        parseMermaid;
export 'package:cc_markdown/src/mermaid/render/mermaid_view.dart'
    show
        CcMermaidFallbackBuilder,
        CcMermaidRenderPlan,
        CcMermaidView,
        clearMermaidSceneCache,
        mermaidSemanticLabel,
        resolveMermaidRenderPlan;

// Parser.
export 'package:cc_markdown/src/parser/parse_options.dart';
export 'package:cc_markdown/src/parser/parser.dart';

// Plugins.
export 'package:cc_markdown/src/plugins/ai/ai_nodes.dart';
export 'package:cc_markdown/src/plugins/ai/ai_plugins.dart';
export 'package:cc_markdown/src/plugins/plugin.dart';

// Render.
export 'package:cc_markdown/src/render/node_builder.dart';
export 'package:cc_markdown/src/render/render_context.dart';
export 'package:cc_markdown/src/render/renderer.dart';

// Selection.
export 'package:cc_markdown/src/selection/context_menu.dart';
export 'package:cc_markdown/src/selection/copy_filter.dart';
export 'package:cc_markdown/src/selection/selection_region.dart';
export 'package:cc_markdown/src/selection/selection_scope.dart';

// Streaming.
export 'package:cc_markdown/src/stream/boundary_scanner.dart';
export 'package:cc_markdown/src/stream/stream_controller.dart';
export 'package:cc_markdown/src/stream/streaming_markdown.dart';

// Style.
export 'package:cc_markdown/src/style/style.dart';

// Widgets.
export 'package:cc_markdown/src/widgets/cc_markdown_widget.dart';
