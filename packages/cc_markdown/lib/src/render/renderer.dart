/// The widget renderer: blocks → a `Column`, inlines → ONE `Text.rich` per
/// paragraph (the hard contract that keeps span runs whole for selection,
/// `find.text` matching, and inline chip embedding).
///
/// Core node types render through built-in code (an exhaustive switch — fast,
/// no registry lookups on the hot path); the [CcBuilderRegistry] carries
/// OVERRIDES and custom-node builders, consulted first with per-node
/// fall-through via [CcNodeBuilder.canBuild].
library;

import 'dart:ui' show BoxHeightStyle;

import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/mermaid/render/mermaid_view.dart';
import 'package:cc_markdown/src/render/node_builder.dart';
import 'package:cc_markdown/src/render/render_context.dart';
import 'package:cc_markdown/src/style/style.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/widgets.dart';

/// Renders cc_markdown ASTs to widgets.
final class CcRenderer {
  /// Creates a [CcRenderer].
  CcRenderer({required this.style, CcBuilderRegistry? builders})
    : builders = builders ?? CcBuilderRegistry.empty;

  /// The active stylesheet.
  final CcMarkdownStyle style;

  /// Override/custom-node builders.
  final CcBuilderRegistry builders;

  /// Renders [blocks] into a column. When [context] carries footnotes, a
  /// definitions section is appended after the last block.
  Widget render(List<CcBlockNode> blocks, {CcRenderContext? context}) {
    final ctx = _bind(context);
    final children = <Widget>[];
    for (final block in blocks) {
      final widget = _renderBlock(block, ctx);
      if (widget == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(SizedBox(height: style.blockSpacing));
      }
      children.add(widget);
    }
    if (ctx.footnotes.isNotEmpty) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: style.blockSpacing));
      }
      children.add(_renderFootnoteSection(ctx));
    }
    if (children.isEmpty) {
      return const SizedBox.shrink();
    }
    if (children.length == 1) {
      return children.first;
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// Renders [nodes] as one rich text run with [baseStyle].
  Widget renderInline(
    List<CcInlineNode> nodes,
    TextStyle? baseStyle,
    CcRenderContext context,
  ) {
    return _RichInlineText(
      nodes: nodes,
      baseStyle: baseStyle,
      renderer: this,
      context: _bind(context),
    );
  }

  /// Binds the nested-render closures so custom builders can recurse.
  CcRenderContext _bind(CcRenderContext? context) {
    final base = context ?? CcRenderContext(style: style);
    if (base.renderBlocks != null) {
      return base;
    }
    // Nested rendering (list items, blockquotes, details bodies, footnote
    // definitions) strips the footnote list so the end-of-document footnote
    // section is emitted exactly ONCE, at the root — otherwise a footnote
    // definition's own body would re-emit the section and recurse forever.
    late CcRenderContext child;
    child = base.copyWith(
      footnotes: const [],
      renderBlocks: (blocks) => render(blocks, context: child),
      renderInlines: (nodes, baseStyle) =>
          renderInline(nodes, baseStyle, child),
    );
    // The returned root context keeps base.footnotes (for the section) but its
    // nested-render callbacks route through the footnote-free child context.
    return base.copyWith(
      renderBlocks: child.renderBlocks,
      renderInlines: child.renderInlines,
    );
  }

  Widget? _renderBlock(CcBlockNode block, CcRenderContext ctx) {
    final override = builders.builderFor(block.nodeType);
    if (override != null && override.canBuild(block)) {
      return override.build(block, style, ctx);
    }
    switch (block) {
      case CcParagraph(:final children):
        if (children.isEmpty) {
          return null;
        }
        return renderInline(children, style.paragraph, ctx);
      case CcHeading(:final level, :final children):
        final heading = renderInline(
          children,
          style.headingStyle(level) ?? style.paragraph,
          ctx,
        );
        final padding = style.headingPadding(level);
        return padding == null
            ? heading
            : Padding(padding: padding, child: heading);
      case CcCodeBlock(:final code, :final language):
        final builder = ctx.codeBuilder;
        if (builder != null) {
          return builder(code, language, cache: ctx.codeCache);
        }
        return Container(
          width: double.infinity,
          decoration: style.codeblockDecoration,
          padding: style.codeblockPadding ?? const EdgeInsets.all(12),
          child: Text(code, style: style.code ?? style.paragraph),
        );
      case CcMermaid(:final source):
        // The engine draws the diagram; an unsupported dialect or a broken body
        // falls back to the SAME code rendering the fence would otherwise have
        // got, so the author never loses their content.
        return CcMermaidView(
          source: source,
          style: style.resolvedMermaid,
          onTapNode: ctx.onTapLink == null
              ? null
              : (nodeId, href) {
                  if (href != null && href.isNotEmpty) {
                    ctx.onTapLink!(href);
                  }
                },
          fallbackBuilder: (source, reason) => _mermaidFallback(source, ctx),
        );
      case CcBlockquote(:final children):
        return Container(
          decoration:
              style.blockquoteDecoration ??
              const BoxDecoration(
                border: Border(
                  left: BorderSide(color: Color(0x33888888), width: 3),
                ),
              ),
          padding:
              style.blockquotePadding ??
              const EdgeInsets.only(left: 12, top: 2, bottom: 2),
          child: DefaultTextStyle.merge(
            style: style.blockquote,
            child: ctx.renderBlocks!(children),
          ),
        );
      case final CcList list:
        return _renderList(list, ctx);
      case final CcTable table:
        return _renderTable(table, ctx);
      case CcThematicBreak():
        return Container(
          height: 1,
          margin: const EdgeInsets.symmetric(vertical: 4),
          color: style.horizontalRuleColor ?? const Color(0x33888888),
        );
      case CcHtmlBlock(:final raw):
        final nodes = htmlBlockInlineNodes(raw);
        if (nodes.isEmpty) {
          return null;
        }
        return renderInline(nodes, style.paragraph, ctx);
      case final CcDetails details:
        return _CcDetailsView(details: details, renderer: this, context: ctx);
      case CcFootnoteDef():
        // Definitions render from the document-level footnote section.
        return null;
      case final CcCustomBlock custom:
        return _missingBuilder(custom);
    }
  }

  /// Renders an undrawable mermaid fence as a `mermaid` code block — through
  /// the host's [CcRenderContext.codeBuilder] when there is one, so the diagram
  /// source lands in the app's normal code chrome (copy button, highlighting).
  Widget _mermaidFallback(String source, CcRenderContext ctx) {
    final builder = ctx.codeBuilder;
    if (builder != null) {
      return builder(source, 'mermaid', cache: ctx.codeCache);
    }
    return Container(
      width: double.infinity,
      decoration: style.codeblockDecoration,
      padding: style.codeblockPadding ?? const EdgeInsets.all(12),
      child: Text(source, style: style.code ?? style.paragraph),
    );
  }

  Widget _renderList(CcList list, CcRenderContext ctx) {
    final itemCtx = ctx.copyWith(listLevel: ctx.listLevel + 1);
    final rows = <Widget>[];
    var number = list.start;
    for (final item in list.items) {
      if (rows.isNotEmpty) {
        rows.add(
          SizedBox(height: list.tight ? style.listItemGap : style.blockSpacing),
        );
      }
      Widget marker;
      if (item.checked != null && style.checkbox != null) {
        marker = style.checkbox!(item.checked!);
      } else if (item.checked != null) {
        marker = Text(
          item.checked! ? '☑' : '☐',
          style: style.listBullet ?? style.paragraph,
        );
      } else if (list.ordered) {
        marker = Text('$number.', style: style.listBullet ?? style.paragraph);
      } else {
        marker = Text('•', style: style.listBullet ?? style.paragraph);
      }
      number++;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: style.listIndent,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 2),
                  child: marker,
                ),
              ),
            ),
            Expanded(child: itemCtx.renderBlocks!(item.children)),
          ],
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _renderTable(CcTable table, CcRenderContext ctx) {
    final cellPadding =
        style.tableCellPadding ??
        const EdgeInsets.symmetric(horizontal: 10, vertical: 6);

    final columnCount = _tableColumnCount(table);
    final columnWidths = _tableColumnWidths(table, columnCount);
    final baseBorder =
        style.tableBorder ?? TableBorder.all(color: const Color(0x33888888));
    final hasSpans =
        table.header.any((c) => c.span > 1) ||
        table.rows.any((row) => row.any((c) => c.span > 1));

    Widget cellContent(List<CcTableCell> cells, int i, {required bool head}) =>
        Padding(
          padding: cellPadding,
          child: _alignedCell(
            i < table.alignments.length ? table.alignments[i] : null,
            i < cells.length
                ? renderInline(
                    cells[i].children,
                    head
                        ? (style.tableHead ?? style.paragraph)
                        : (style.tableBody ?? style.paragraph),
                    ctx,
                  )
                : const SizedBox.shrink(),
          ),
        );

    TableRow buildRow(List<CcTableCell> cells, {required bool head}) {
      return TableRow(
        decoration: head ? style.tableHeadDecoration : null,
        children: [
          for (var i = 0; i < columnCount; i++)
            cellContent(cells, i, head: head),
        ],
      );
    }

    // `Table` cannot merge cells, so a table containing colspans swaps
    // `verticalInside` for interleaved 1px border-strip COLUMNS (content
    // columns at even indices, strips at odd). A strip inside a span renders
    // nothing, so the spanned cells read as one merged cell — GitHub's
    // "Changed Files" divider row — while every other row keeps its grid.
    // Strips are `fill`-aligned to run the full row height; content cells
    // stay `middle`, so every row keeps at least one height-driving cell.
    final vertical = baseBorder.verticalInside;
    TableRow buildSpanRow(List<CcTableCell> cells, {required bool head}) {
      final covered = List<bool>.filled(columnCount, false);
      var remaining = 0;
      for (var j = 0; j < columnCount; j++) {
        if (remaining > 0) {
          covered[j] = true;
          remaining--;
          continue;
        }
        if (j < cells.length) {
          remaining = cells[j].span - 1;
        }
      }
      return TableRow(
        decoration: head ? style.tableHeadDecoration : null,
        children: [
          for (var j = 0; j < columnCount; j++) ...[
            if (j > 0)
              covered[j]
                  ? const SizedBox.shrink()
                  : TableCell(
                      verticalAlignment: TableCellVerticalAlignment.fill,
                      child: ColoredBox(color: vertical.color),
                    ),
            if (covered[j])
              const SizedBox.shrink()
            else
              cellContent(cells, j, head: head),
          ],
        ],
      );
    }

    // Size the table to the available width rather than a hardcoded 900 (which
    // forced even a two-column table to overflow — and clip — any narrower
    // surface, and left a stub 900px table stranded on a wide one). The table
    // now fills the surface width (a readable 320px floor engages the
    // horizontal scroll on a very narrow bubble); when every column is short it
    // shrink-wraps to its content instead of stretching (see below).
    //
    // Short, media-free columns get IntrinsicColumnWidth via [_tableColumnWidths]
    // so a "Name / Link"-style table hugs its labels instead of splitting 50/50,
    // while columns carrying media or long text stay FlexColumnWidth (the
    // default) and absorb the remaining width — matching GitHub, where the label
    // column hugs and the link column fills. Intrinsic width is only ever
    // assigned to media-free columns: image/custom builders use LayoutBuilder,
    // which throws during the intrinsic measurement pass.
    final Table tableWidget;
    if (hasSpans) {
      tableWidget = Table(
        // Vertical lines come from the strip columns; the border keeps only
        // the outside edges and the horizontal separators.
        border: TableBorder(
          top: baseBorder.top,
          right: baseBorder.right,
          bottom: baseBorder.bottom,
          left: baseBorder.left,
          horizontalInside: baseBorder.horizontalInside,
        ),
        columnWidths: {
          for (final entry in columnWidths.entries) entry.key * 2: entry.value,
          for (var j = 1; j < columnCount; j++)
            2 * j - 1: FixedColumnWidth(vertical.width),
        },
        defaultColumnWidth: const FlexColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          buildSpanRow(table.header, head: true),
          for (final row in table.rows) buildSpanRow(row, head: false),
        ],
      );
    } else {
      tableWidget = Table(
        border: baseBorder,
        columnWidths: columnWidths,
        defaultColumnWidth: const FlexColumnWidth(),
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          buildRow(table.header, head: true),
          for (final row in table.rows) buildRow(row, head: false),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final avail = constraints.maxWidth;
        final maxTableWidth = avail.isFinite
            ? avail.clamp(320.0, double.infinity)
            : 900.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxTableWidth),
            child: tableWidget,
          ),
        );
      },
    );
  }

  /// Positions a table cell's content per its column alignment. `Align` only
  /// places the text BLOCK; a multi-line cell (`28.97%<br/>+2.20%`) must also
  /// align its lines within the block via `textAlign`, or a right-aligned
  /// column reads as left-aligned (GitHub aligns every line).
  static Widget _alignedCell(CcTableAlign? align, Widget child) {
    final (alignment, textAlign) = switch (align) {
      CcTableAlign.center => (Alignment.center, TextAlign.center),
      CcTableAlign.right => (AlignmentDirectional.centerEnd, TextAlign.end),
      _ => (AlignmentDirectional.centerStart, null),
    };
    return Align(
      alignment: alignment,
      child: textAlign == null
          ? child
          : DefaultTextStyle.merge(textAlign: textAlign, child: child),
    );
  }

  Widget _renderFootnoteSection(CcRenderContext ctx) {
    final base = style.paragraph ?? const TextStyle();
    // `apply(fontSizeFactor:)` asserts when fontSize is null, so only scale
    // when the base style actually carries a size.
    final small = base.fontSize == null
        ? base
        : base.apply(fontSizeFactor: 0.85);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 1,
          margin: const EdgeInsets.only(bottom: 8),
          color: style.horizontalRuleColor ?? const Color(0x33888888),
        ),
        for (final def in ctx.footnotes) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: Text('${def.index}.', style: small)),
              Expanded(
                child: DefaultTextStyle.merge(
                  style: small,
                  child: ctx.renderBlocks!(def.children),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
        ],
      ],
    );
  }

  Widget _missingBuilder(CcNode node) {
    assert(() {
      debugPrint('cc_markdown: no builder registered for "${node.nodeType}"');
      return true;
    }());
    if (kDebugMode) {
      return Text('⟨missing builder: ${node.nodeType}⟩');
    }
    return const SizedBox.shrink();
  }
}

/// Strips HTML tags from tolerated raw HTML, decoding nothing — a plain
/// "don't garble" fallback for [CcHtmlBlock].
String stripHtmlTags(String raw) => raw.replaceAll(RegExp('<[^>]*>'), '');

final RegExp _htmlBlockAnchor = RegExp(
  r'''<a\s[^<>]*?href\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s<>]+))[^<>]*>([\s\S]*?)</a\s*>''',
  caseSensitive: false,
);

/// Converts a tolerated raw-HTML chunk into inline nodes: `<a href>` anchors
/// become tappable [CcLink]s, everything else is tag-stripped text — the
/// clickable upgrade of [stripHtmlTags] for [CcHtmlBlock] (GitHub bodies
/// carry `<p><a href=…>…</a></p>` linkbacks routinely).
List<CcInlineNode> htmlBlockInlineNodes(String raw) {
  final nodes = <CcInlineNode>[];
  var last = 0;
  for (final m in _htmlBlockAnchor.allMatches(raw)) {
    final before = stripHtmlTags(raw.substring(last, m.start));
    if (before.trim().isNotEmpty) {
      nodes.add(CcText(before));
    }
    final url = m.group(1) ?? m.group(2) ?? m.group(3) ?? '';
    final label = stripHtmlTags(m.group(4) ?? '').trim();
    if (url.isNotEmpty) {
      nodes.add(
        CcLink(url: url, children: [CcText(label.isEmpty ? url : label)]),
      );
    }
    last = m.end;
  }
  final tail = stripHtmlTags(raw.substring(last));
  if (tail.trim().isNotEmpty) {
    nodes.add(CcText(tail));
  }
  return nodes;
}

/// One rich-text run. Owns the tap recognizers its spans create and disposes
/// them on unmount / rebuild (a stateless span tree would leak them).
class _RichInlineText extends StatefulWidget {
  const _RichInlineText({
    required this.nodes,
    required this.baseStyle,
    required this.renderer,
    required this.context,
  });

  final List<CcInlineNode> nodes;
  final TextStyle? baseStyle;
  final CcRenderer renderer;
  final CcRenderContext context;

  @override
  State<_RichInlineText> createState() => _RichInlineTextState();
}

class _RichInlineTextState extends State<_RichInlineText> {
  final List<GestureRecognizer> _recognizers = [];

  /// The recognizers that belong to links — membership is how the underline
  /// paint pass finds a link's character ranges in the laid-out paragraph.
  final Set<GestureRecognizer> _linkRecognizers = {};

  /// Character ranges (offsets into the paragraph's plain text) covered by
  /// engine-rendered links. Recomputed every build.
  final List<(int, int)> _linkRanges = [];

  /// Key on the inner [RichText] so the underline painter can query the REAL
  /// [RenderParagraph] — the boxes always match what is on screen instead of
  /// drifting from a mirrored [TextPainter].
  final GlobalKey _textKey = GlobalKey();

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    _linkRecognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final spans = _buildSpans(widget.nodes, widget.baseStyle);
    _collectLinkRanges(spans);
    final text = Text.rich(
      key: _textKey,
      TextSpan(style: widget.baseStyle, children: spans),
    );
    if (_linkRanges.isEmpty) {
      return text;
    }
    final linkStyle = widget.renderer.style.link;
    return CustomPaint(
      foregroundPainter: _CcLinkUnderlinePainter(
        textKey: _textKey,
        ranges: _linkRanges,
        color: linkStyle?.decorationColor ?? linkStyle?.color,
        fontSize: linkStyle?.fontSize ?? widget.baseStyle?.fontSize ?? 14,
      ),
      child: text,
    );
  }

  /// Flattens the span tree into paragraph-text offsets and records the
  /// ranges whose spans carry a link recognizer. Non-[TextSpan] inlines
  /// occupy one U+FFFC placeholder each and are skipped (chips draw their
  /// own chrome).
  void _collectLinkRanges(List<InlineSpan> spans) {
    _linkRanges.clear();
    var offset = 0;
    void walk(List<InlineSpan> list, {required bool inLink}) {
      for (final span in list) {
        if (span is! TextSpan) {
          offset += 1;
          continue;
        }
        final linked = inLink || _linkRecognizers.contains(span.recognizer);
        final length = (span.text ?? '').length;
        if (linked && length > 0) {
          _linkRanges.add((offset, offset + length));
        }
        offset += length;
        final children = span.children;
        if (children != null) {
          walk(children, inLink: linked);
        }
      }
    }

    walk(spans, inLink: false);
  }

  List<InlineSpan> _buildSpans(List<CcInlineNode> nodes, TextStyle? base) {
    final style = widget.renderer.style;
    final ctx = widget.context;
    final spans = <InlineSpan>[];
    for (final node in nodes) {
      final override = widget.renderer.builders.builderFor(node.nodeType);
      if (override != null && override.canBuild(node)) {
        spans.add(
          WidgetSpan(
            alignment: override.placeholderAlignment,
            // Inert unless the builder opts into baseline alignment.
            baseline: TextBaseline.alphabetic,
            child: override.build(node, style, ctx),
          ),
        );
        continue;
      }
      switch (node) {
        case CcText(:final text):
          spans.add(TextSpan(text: text));
        case CcSoftBreak():
          spans.add(
            TextSpan(
              text: style.softBreakMode == CcSoftBreakMode.newline ? '\n' : ' ',
            ),
          );
        case CcHardBreak():
          spans.add(const TextSpan(text: '\n'));
        case CcEmphasis(:final children):
          spans.add(
            TextSpan(
              style:
                  style.italic ?? const TextStyle(fontStyle: FontStyle.italic),
              children: _buildSpans(children, base),
            ),
          );
        case CcStrong(:final children):
          spans.add(
            TextSpan(
              style: style.bold ?? const TextStyle(fontWeight: FontWeight.w600),
              children: _buildSpans(children, base),
            ),
          );
        case CcStrikethrough(:final children):
          spans.add(
            TextSpan(
              style:
                  style.strikethrough ??
                  const TextStyle(decoration: TextDecoration.lineThrough),
              children: _buildSpans(children, base),
            ),
          );
        case CcInlineCode(:final code):
          spans.add(
            TextSpan(text: code, style: style.inlineCode ?? style.code),
          );
        case final CcLink link:
          final recognizer = TapGestureRecognizer()
            ..onTap = () => ctx.onTapLink?.call(link.url);
          _recognizers.add(recognizer);
          _linkRecognizers.add(recognizer);
          final linkStyle =
              style.link ??
              const TextStyle(decoration: TextDecoration.underline);
          spans.add(
            TextSpan(
              // The underline is NOT painted by the text engine: it hugs the
              // baseline and strikes through descenders (no
              // `text-underline-offset` / `text-decoration-skip-ink` exists
              // on the pinned SDK). _CcLinkUnderlinePainter draws it below
              // the glyphs instead; the style's color/decorationColor stay
              // as the painter's inputs.
              style: linkStyle.copyWith(decoration: TextDecoration.none),
              children: _buildSpansWithRecognizer(
                link.children,
                base,
                recognizer,
              ),
            ),
          );
        case final CcImage image:
          final imageBuilder = ctx.imageBuilder;
          Widget child;
          if (imageBuilder != null) {
            child = imageBuilder(image.url, image.alt, image.title);
          } else {
            child = GestureDetector(
              onTap: ctx.onTapImage == null
                  ? null
                  : () => ctx.onTapImage!(image.url, image.alt, image.title),
              child: Image.network(
                image.url,
                errorBuilder: (_, _, _) =>
                    Text('🖼 ${image.alt}', style: widget.baseStyle),
              ),
            );
          }
          spans.add(
            WidgetSpan(alignment: PlaceholderAlignment.middle, child: child),
          );
        case CcFootnoteRef(:final index):
          final refBase = style.link ?? const TextStyle();
          spans.add(
            TextSpan(
              text: '[$index]',
              // Only scale when a size exists (apply asserts on null fontSize).
              style: refBase.fontSize == null
                  ? refBase
                  : refBase.apply(fontSizeFactor: 0.75),
            ),
          );
        case CcInlineHtml(:final raw):
          spans.add(TextSpan(text: stripHtmlTags(raw)));
        case final CcCustomInline custom:
          spans.add(
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: widget.renderer._missingBuilder(custom),
            ),
          );
      }
    }
    return spans;
  }

  /// Like [_buildSpans] but attaches [recognizer] to every text span so the
  /// whole link label is tappable.
  List<InlineSpan> _buildSpansWithRecognizer(
    List<CcInlineNode> nodes,
    TextStyle? base,
    GestureRecognizer recognizer,
  ) {
    final spans = _buildSpans(nodes, base);
    List<InlineSpan> attach(List<InlineSpan> input) => [
      for (final span in input)
        if (span is TextSpan)
          TextSpan(
            text: span.text,
            style: span.style,
            recognizer: recognizer,
            children: span.children == null ? null : attach(span.children!),
          )
        else
          span,
    ];
    return attach(spans);
  }
}

/// The default `<details>` disclosure widget: a chevron + summary header
/// toggling the body. Widgets-only; apps override via the `'details'`
/// builder registration for design-system chrome.
class _CcDetailsView extends StatefulWidget {
  const _CcDetailsView({
    required this.details,
    required this.renderer,
    required this.context,
  });

  final CcDetails details;
  final CcRenderer renderer;
  final CcRenderContext context;

  @override
  State<_CcDetailsView> createState() => _CcDetailsViewState();
}

class _CcDetailsViewState extends State<_CcDetailsView> {
  late bool _open = widget.details.open;

  @override
  Widget build(BuildContext context) {
    final style = widget.renderer.style;
    final summary = widget.details.summary.isEmpty
        ? [const CcText('Details')]
        : widget.details.summary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _open = !_open),
          child: Row(
            children: [
              Text(_open ? '▾ ' : '▸ ', style: style.paragraph),
              Expanded(
                child: widget.renderer.renderInline(
                  summary,
                  (style.paragraph ?? const TextStyle()).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  widget.context,
                ),
              ),
            ],
          ),
        ),
        if (_open)
          Padding(
            padding: const EdgeInsets.only(left: 16, top: 6),
            child: widget.context.renderBlocks!(widget.details.children),
          ),
      ],
    );
  }
}

/// Paints link underlines BELOW the descent line, full width — the Carbon
/// model — which the text engine cannot do (no `text-underline-offset` /
/// `text-decoration-skip-ink` exists on the pinned SDK; its underline hugs
/// the baseline and strikes through g/j/p/q/y).
///
/// Ratio-based skip-ink (gaps at hardcoded fractions of each descender) was
/// tried and rejected: without a glyph-outline API the stroke windows can
/// never match the actual font, so the line either crossed the descender
/// ink or dropped the glyph's tail. Sitting just under the fragment's
/// glyph-tight bottom clears every descender, for every font, at full width.
///
/// Boxes come from the paragraph's REAL [RenderParagraph], so wrapping,
/// scaling, and selection all track exactly.
class _CcLinkUnderlinePainter extends CustomPainter {
  _CcLinkUnderlinePainter({
    required this.textKey,
    required this.ranges,
    this.color,
    required this.fontSize,
  });

  /// Key on the [RichText] whose [RenderParagraph] supplies the boxes.
  final GlobalKey textKey;

  /// Character ranges of engine-rendered links, in paragraph plain-text
  /// offsets (see [_RichInlineTextState._collectLinkRanges]).
  final List<(int, int)> ranges;

  /// Underline colour — the link style's (softened) decoration colour.
  final Color? color;

  /// The link's font size, driving the offset and thickness ratios.
  final double fontSize;

  /// Depth-first search for the paragraph that lays out the keyed [RichText].
  /// The key sits on a `Text.rich`, whose first render-object descendant is
  /// the paragraph itself UNLESS an interactive ancestor (SelectionArea adds
  /// a MouseRegion) wraps it — the probe that assumed `is RenderParagraph`
  /// silently painted nothing on every selectable surface.
  static RenderParagraph? _findParagraph(RenderObject? node) {
    if (node is RenderParagraph) {
      return node;
    }
    RenderParagraph? found;
    node?.visitChildren((child) {
      found ??= _findParagraph(child);
    });
    return found;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final renderObject = _findParagraph(
      textKey.currentContext?.findRenderObject(),
    );
    if (renderObject == null || !renderObject.hasSize) {
      return;
    }
    final plain = renderObject.text.toPlainText();
    if (plain.isEmpty) {
      return;
    }
    final gap = (fontSize * 0.1).clamp(1.0, 3.0).toDouble();
    final thickness = (fontSize * 0.06).clamp(1.0, 2.0).toDouble();
    final paint = Paint()
      ..color = color ?? const Color(0xFF000000)
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    for (final (rawStart, rawEnd) in ranges) {
      final start = rawStart.clamp(0, plain.length);
      final end = rawEnd.clamp(0, plain.length);
      if (end <= start) {
        continue;
      }
      // Glyph-tight boxes, one per wrapped fragment: the line sits just
      // under the fragment's ink — descenders included — at full width.
      final boxes = renderObject.getBoxesForSelection(
        TextSelection(baseOffset: start, extentOffset: end),
        boxHeightStyle: BoxHeightStyle.tight,
      );
      for (final box in boxes) {
        if (box.right - box.left < 1) {
          continue;
        }
        final y = box.bottom + gap;
        canvas.drawLine(Offset(box.left, y), Offset(box.right, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CcLinkUnderlinePainter oldDelegate) => true;
}

/// The number of columns in [table] — the header width, which body rows are
/// normalized to (a stray longer row is tolerated by taking the max).
int _tableColumnCount(CcTable table) {
  var count = table.header.length;
  for (final row in table.rows) {
    if (row.length > count) {
      count = row.length;
    }
  }
  return count;
}

/// Column length above which a column is treated as "wide" (prose, URLs, long
/// values) and left flexible rather than shrunk to its intrinsic width.
const int _kNarrowColumnCharBudget = 24;

/// Per-column [TableColumnWidth] overrides. Short, media-free columns are set
/// to [IntrinsicColumnWidth] so they hug their content (a "Name / Link" table
/// no longer splits 50/50); every other column falls through to the table's
/// default [FlexColumnWidth] and absorbs the remaining width.
///
/// The two outcomes this produces, both GitHub-like:
///  * mixed — some short, some wide/media columns: the short ones hug while the
///    wide ones fill, so the table spans the surface width with tight labels;
///  * uniformly short — every column intrinsic: the table shrink-wraps to its
///    content (no flex column to stretch it) rather than sprawling.
///
/// Intrinsic sizing is assigned ONLY to media-free columns: image and custom
/// inline builders use `LayoutBuilder`, which throws when the `Table` runs its
/// intrinsic-width measurement pass.
Map<int, TableColumnWidth> _tableColumnWidths(CcTable table, int columnCount) {
  if (columnCount == 0) {
    return const {};
  }
  final hasMedia = List<bool>.filled(columnCount, false);
  final maxLen = List<int>.filled(columnCount, 0);

  void scan(List<CcTableCell> cells) {
    for (var i = 0; i < cells.length && i < columnCount; i++) {
      final metrics = _inlineMetrics(cells[i].children);
      if (metrics.media) {
        hasMedia[i] = true;
      }
      if (metrics.length > maxLen[i]) {
        maxLen[i] = metrics.length;
      }
    }
  }

  scan(table.header);
  for (final row in table.rows) {
    scan(row);
  }

  final widths = <int, TableColumnWidth>{};
  for (var i = 0; i < columnCount; i++) {
    if (!hasMedia[i] && maxLen[i] <= _kNarrowColumnCharBudget) {
      widths[i] = const IntrinsicColumnWidth();
    }
  }
  return widths;
}

/// Plain-text length and whether a run of inline [nodes] contains media
/// (an image or a custom inline that may size itself with a `LayoutBuilder`).
({int length, bool media}) _inlineMetrics(List<CcInlineNode> nodes) {
  var length = 0;
  var media = false;

  void walk(List<CcInlineNode> ns) {
    for (final node in ns) {
      switch (node) {
        case CcText(:final text):
          length += text.length;
        case CcInlineCode(:final code):
          length += code.length;
        case CcInlineHtml(:final raw):
          length += raw.length;
        case CcEmphasis(:final children):
          walk(children);
        case CcStrong(:final children):
          walk(children);
        case CcStrikethrough(:final children):
          walk(children);
        case CcLink(:final children):
          walk(children);
        case CcSoftBreak():
        case CcHardBreak():
          length += 1;
        case CcFootnoteRef():
          length += 3;
        case CcImage():
        case CcCustomInline():
          media = true;
      }
    }
  }

  walk(nodes);
  return (length: length, media: media);
}
