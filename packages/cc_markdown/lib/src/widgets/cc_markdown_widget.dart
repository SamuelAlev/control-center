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
/// content never re-parses, plugins or not. The AST → widget render is
/// memoized per element on everything it reads (the identical parse, the
/// style by value, the builders and callbacks by identity), so a parent
/// rebuild that changes none of them hands back the identical subtree and
/// `Element.update` skips it.
///
/// When an ancestor owns selection (one region per feed, marked by
/// [CcSelectionScope]), the widget renders plain non-selectable text under
/// it; otherwise `selectable: true` wraps this document in its own
/// [CcSelectionRegion].
class CcMarkdown extends StatefulWidget {
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
    this.onTaskCheckboxChanged,
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

  /// Task-list checkbox toggle. [index] is document-order and matches
  /// [toggleMarkdownTaskListItem]. Null keeps the boxes read-only.
  final void Function(int index, bool checked)? onTaskCheckboxChanged;

  /// Whether the rendered text is selectable.
  final bool selectable;

  /// Whether to isolate the document in a [RepaintBoundary].
  final bool useRepaintBoundary;

  /// Parse without inserting into the global cache (volatile content).
  final bool ephemeral;

  @override
  State<CcMarkdown> createState() => _CcMarkdownState();
}

class _CcMarkdownState extends State<CcMarkdown> {
  /// The last rendered subtree and everything it was rendered from. Held by
  /// IDENTITY except the style (value-equal styles rebuilt from the same
  /// tokens are a non-event): a parent passing a NEW callback closure must
  /// re-render, or the memoized subtree keeps firing the stale one.
  Widget? _memo;
  List<CcBlockNode>? _memoNodes;
  CcMarkdownStyle? _memoStyle;
  CcBuilderRegistry? _memoBuilders;
  void Function(String url)? _memoOnTapLink;
  void Function(String url, String? alt, String? title)? _memoOnTapImage;
  CcImageBuilder? _memoImageBuilder;
  CcCodeBuilder? _memoCodeBuilder;
  void Function(int index, bool checked)? _memoOnTaskCheckboxChanged;
  bool? _memoSelectable;
  bool? _memoRepaintBoundary;

  @override
  Widget build(BuildContext context) {
    final widget = this.widget;
    final List<CcBlockNode> nodes = widget.ephemeral
        ? CcMarkdownCache.parseEphemeral(
            widget.data,
            widget.plugins,
            options: widget.options,
          )
        : CcMarkdownCache.parseCached(
            widget.data,
            widget.plugins,
            options: widget.options,
          );

    final resolvedStyle = widget.style ?? const CcMarkdownStyle();
    final ancestorOwnsSelection = CcSelectionScope.of(context);
    final selectable = widget.selectable && !ancestorOwnsSelection;
    final memo = _memo;
    if (memo != null &&
        identical(_memoNodes, nodes) &&
        _memoStyle == resolvedStyle &&
        identical(_memoBuilders, widget.builders) &&
        identical(_memoOnTapLink, widget.onTapLink) &&
        identical(_memoOnTapImage, widget.onTapImage) &&
        identical(_memoImageBuilder, widget.imageBuilder) &&
        identical(_memoCodeBuilder, widget.codeBuilder) &&
        identical(_memoOnTaskCheckboxChanged, widget.onTaskCheckboxChanged) &&
        _memoSelectable == selectable &&
        _memoRepaintBoundary == widget.useRepaintBoundary) {
      return memo;
    }

    final renderer = CcRenderer(
      style: resolvedStyle,
      builders: widget.builders,
    );
    final rendered = renderer.render(
      nodes,
      context: CcRenderContext(
        style: resolvedStyle,
        onTapLink: widget.onTapLink,
        onTapImage: widget.onTapImage,
        imageBuilder: widget.imageBuilder,
        codeBuilder: widget.codeBuilder,
        onTaskCheckboxChanged: widget.onTaskCheckboxChanged,
        taskCheckboxCursor: widget.onTaskCheckboxChanged == null
            ? null
            : CcTaskCheckboxCursor(),
        selectable: selectable,
        footnotes: [
          for (final node in nodes)
            if (node is CcFootnoteDef) node,
        ],
      ),
    );

    final content = selectable ? CcSelectionRegion(child: rendered) : rendered;
    final result = widget.useRepaintBoundary
        ? RepaintBoundary(child: content)
        : content;
    _memo = result;
    _memoNodes = nodes;
    _memoStyle = resolvedStyle;
    _memoBuilders = widget.builders;
    _memoOnTapLink = widget.onTapLink;
    _memoOnTapImage = widget.onTapImage;
    _memoImageBuilder = widget.imageBuilder;
    _memoCodeBuilder = widget.codeBuilder;
    _memoOnTaskCheckboxChanged = widget.onTaskCheckboxChanged;
    _memoSelectable = selectable;
    _memoRepaintBoundary = widget.useRepaintBoundary;
    return result;
  }
}
