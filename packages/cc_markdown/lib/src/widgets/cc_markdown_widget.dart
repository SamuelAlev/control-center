import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/cache/parse_cache.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';
import 'package:cc_markdown/src/render/node_builder.dart';
import 'package:cc_markdown/src/render/render_context.dart';
import 'package:cc_markdown/src/render/renderer.dart';
import 'package:cc_markdown/src/selection/selection_region.dart';
import 'package:cc_markdown/src/selection/selection_scope.dart';
import 'package:cc_markdown/src/style/style.dart';
import 'package:flutter/widgets.dart';

/// One-shot markdown rendering with an always-on process-global parse cache.
///
/// The parse is cached by `(data, plugins identity)` — re-rendering the same
/// content never re-parses, plugins or not. Render-from-AST is cheap and
/// runs per build (styles/theme can change between builds).
///
/// When an ancestor owns selection (one region per feed, marked by
/// [CcSelectionScope]), the widget renders plain non-selectable text under
/// it; otherwise `selectable: true` wraps this document in its own
/// [CcSelectionRegion].
class CcMarkdown extends StatelessWidget {
  /// Creates a [CcMarkdown].
  const CcMarkdown({
    required this.data,
    super.key,
    this.style,
    this.plugins = CcPluginSet.empty,
    this.options = const CcParseOptions(),
    this.builders,
    this.onTapLink,
    this.onTapImage,
    this.imageBuilder,
    this.codeBuilder,
    this.selectable = false,
    this.useRepaintBoundary = true,
    this.ephemeral = false,
  });

  /// The markdown source (also the parse-cache key).
  final String data;

  /// Stylesheet; defaults to bare [CcMarkdownStyle] (inherits ambient text
  /// style through `Text.rich`).
  final CcMarkdownStyle? style;

  /// Parser plugins (identity participates in the cache key — keep sets
  /// process-global).
  final CcPluginSet plugins;

  /// Parse feature toggles.
  final CcParseOptions options;

  /// Widget builder overrides / custom-node builders.
  final CcBuilderRegistry? builders;

  /// Link tap callback.
  final void Function(String url)? onTapLink;

  /// Image tap callback (used by the default image rendering).
  final void Function(String url, String? alt, String? title)? onTapImage;

  /// Custom image renderer (receives alt/title verbatim).
  final CcImageBuilder? imageBuilder;

  /// Custom fenced-code renderer.
  final CcCodeBuilder? codeBuilder;

  /// Whether the rendered text is selectable.
  final bool selectable;

  /// Whether to isolate the document in a [RepaintBoundary].
  final bool useRepaintBoundary;

  /// Parse without inserting into the global cache (volatile content).
  final bool ephemeral;

  @override
  Widget build(BuildContext context) {
    final List<CcBlockNode> nodes = ephemeral
        ? CcMarkdownCache.parseEphemeral(data, plugins, options: options)
        : CcMarkdownCache.parseCached(data, plugins, options: options);

    final resolvedStyle = style ?? const CcMarkdownStyle();
    final renderer = CcRenderer(style: resolvedStyle, builders: builders);
    final ancestorOwnsSelection = CcSelectionScope.of(context);
    final rendered = renderer.render(
      nodes,
      context: CcRenderContext(
        style: resolvedStyle,
        onTapLink: onTapLink,
        onTapImage: onTapImage,
        imageBuilder: imageBuilder,
        codeBuilder: codeBuilder,
        selectable: selectable && !ancestorOwnsSelection,
        footnotes: [
          for (final node in nodes)
            if (node is CcFootnoteDef) node,
        ],
      ),
    );

    final content = (selectable && !ancestorOwnsSelection)
        ? CcSelectionRegion(child: rendered)
        : rendered;
    if (useRepaintBoundary) {
      return RepaintBoundary(child: content);
    }
    return content;
  }
}
