/// The cc_markdown typed AST.
///
/// A Dart 3 sealed hierarchy with two roots — [CcInlineNode] and [CcBlockNode]
/// — so blocks and inlines can be switched exhaustively and independently. The
/// ONLY open leaves are [CcCustomInline] / [CcCustomBlock], which parser
/// plugins subclass; an exhaustive switch over the sealed tree ends with a
/// custom arm that dispatches to the builder registry.
///
/// Every node is immutable, const-constructible, and value-equal (deep list
/// equality with an `identical` fast path). Value equality is the memoization
/// lever: the streaming widget reuses the identical widget instance for a
/// sealed block whose nodes compare equal across frames, and tests assert ASTs
/// directly.
///
/// Nodes deliberately carry NO source offsets — offsets live on the streaming
/// layer's `CcSealedBlock`. Offsets in `==` would defeat memoization, and
/// selection copies rendered text, not source.
library;

/// Deep list equality with an identity fast path.
bool ccListEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}

/// Base type of every AST node.
sealed class CcNode {
  /// Creates a [CcNode].
  const CcNode();

  /// Stable string key for the widget builder registry (e.g. `'paragraph'`).
  String get nodeType;
}

/// Base type of every inline (span-level) node.
sealed class CcInlineNode extends CcNode {
  /// Creates a [CcInlineNode].
  const CcInlineNode();
}

/// Base type of every block-level node.
sealed class CcBlockNode extends CcNode {
  /// Creates a [CcBlockNode].
  const CcBlockNode();
}

/// Open extension point for inline parser plugins. Subclass this (never
/// [CcInlineNode] directly — it is sealed) and register a widget builder for
/// your [CcNode.nodeType].
abstract class CcCustomInline extends CcInlineNode {
  /// Creates a [CcCustomInline].
  const CcCustomInline();
}

/// Open extension point for block parser plugins. Subclass this (never
/// [CcBlockNode] directly — it is sealed) and register a widget builder for
/// your [CcNode.nodeType].
abstract class CcCustomBlock extends CcBlockNode {
  /// Creates a [CcCustomBlock].
  const CcCustomBlock();
}

// ---------------------------------------------------------------------------
// Inline nodes
// ---------------------------------------------------------------------------

/// Plain text run.
final class CcText extends CcInlineNode {
  /// Creates a [CcText].
  const CcText(this.text);

  /// The literal text.
  final String text;

  @override
  String get nodeType => 'text';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CcText && text == other.text;

  @override
  int get hashCode => Object.hash(nodeType, text);

  @override
  String toString() =>
      'CcText(${text.length > 40 ? '${text.substring(0, 40)}…' : text})';
}

/// A soft line break (single newline inside a paragraph).
final class CcSoftBreak extends CcInlineNode {
  /// Creates a [CcSoftBreak].
  const CcSoftBreak();

  @override
  String get nodeType => 'soft_break';

  @override
  bool operator ==(Object other) => other is CcSoftBreak;

  @override
  int get hashCode => nodeType.hashCode;
}

/// A hard line break (trailing two spaces, backslash, or `<br>`).
final class CcHardBreak extends CcInlineNode {
  /// Creates a [CcHardBreak].
  const CcHardBreak();

  @override
  String get nodeType => 'hard_break';

  @override
  bool operator ==(Object other) => other is CcHardBreak;

  @override
  int get hashCode => nodeType.hashCode;
}

/// Emphasis (`*text*` / `_text_`).
final class CcEmphasis extends CcInlineNode {
  /// Creates a [CcEmphasis].
  const CcEmphasis(this.children);

  /// The emphasized content.
  final List<CcInlineNode> children;

  @override
  String get nodeType => 'emphasis';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcEmphasis && ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, Object.hashAll(children));
}

/// Strong emphasis (`**text**` / `__text__`).
final class CcStrong extends CcInlineNode {
  /// Creates a [CcStrong].
  const CcStrong(this.children);

  /// The strongly-emphasized content.
  final List<CcInlineNode> children;

  @override
  String get nodeType => 'strong';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcStrong && ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, Object.hashAll(children));
}

/// GFM strikethrough (`~~text~~`).
final class CcStrikethrough extends CcInlineNode {
  /// Creates a [CcStrikethrough].
  const CcStrikethrough(this.children);

  /// The struck-through content.
  final List<CcInlineNode> children;

  @override
  String get nodeType => 'strikethrough';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcStrikethrough && ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, Object.hashAll(children));
}

/// Inline code span.
final class CcInlineCode extends CcInlineNode {
  /// Creates a [CcInlineCode].
  const CcInlineCode(this.code);

  /// The literal code (backtick-trimmed per CommonMark).
  final String code;

  @override
  String get nodeType => 'inline_code';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CcInlineCode && code == other.code;

  @override
  int get hashCode => Object.hash(nodeType, code);
}

/// A hyperlink.
final class CcLink extends CcInlineNode {
  /// Creates a [CcLink].
  const CcLink({
    required this.url,
    required this.children,
    this.title,
    this.autolink = false,
  });

  /// The destination URL.
  final String url;

  /// The optional link title.
  final String? title;

  /// The link label content.
  final List<CcInlineNode> children;

  /// True when the link was produced by an autolink (`<url>` or the GFM
  /// bare-URL extension) rather than `[label](url)` syntax — i.e. the label IS
  /// the URL. Replaces fragile `textContent == href` checks downstream.
  final bool autolink;

  @override
  String get nodeType => 'link';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcLink &&
          url == other.url &&
          title == other.title &&
          autolink == other.autolink &&
          ccListEquals(children, other.children);

  @override
  int get hashCode =>
      Object.hash(nodeType, url, title, autolink, Object.hashAll(children));
}

/// An image.
final class CcImage extends CcInlineNode {
  /// Creates a [CcImage].
  const CcImage({required this.url, required this.alt, this.title});

  /// The image URL.
  final String url;

  /// The alt text (passed VERBATIM to image builders — callers encode
  /// sentinels like dimensions in it).
  final String alt;

  /// The optional title (passed VERBATIM to image builders).
  final String? title;

  @override
  String get nodeType => 'image';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcImage &&
          url == other.url &&
          alt == other.alt &&
          title == other.title;

  @override
  int get hashCode => Object.hash(nodeType, url, alt, title);
}

/// A footnote reference (`[^label]`).
final class CcFootnoteRef extends CcInlineNode {
  /// Creates a [CcFootnoteRef].
  const CcFootnoteRef({required this.label, required this.index});

  /// The footnote label as written.
  final String label;

  /// 1-based render order of the referenced definition.
  final int index;

  @override
  String get nodeType => 'footnote_ref';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcFootnoteRef && label == other.label && index == other.index;

  @override
  int get hashCode => Object.hash(nodeType, label, index);
}

/// Raw inline HTML that the parser tolerated but does not interpret.
final class CcInlineHtml extends CcInlineNode {
  /// Creates a [CcInlineHtml].
  const CcInlineHtml(this.raw);

  /// The raw tag text (e.g. `<sup>`).
  final String raw;

  @override
  String get nodeType => 'inline_html';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CcInlineHtml && raw == other.raw;

  @override
  int get hashCode => Object.hash(nodeType, raw);
}

// ---------------------------------------------------------------------------
// Block nodes
// ---------------------------------------------------------------------------

/// A paragraph.
final class CcParagraph extends CcBlockNode {
  /// Creates a [CcParagraph].
  const CcParagraph(this.children);

  /// The paragraph's inline content.
  final List<CcInlineNode> children;

  @override
  String get nodeType => 'paragraph';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcParagraph && ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, Object.hashAll(children));
}

/// An ATX or setext heading.
final class CcHeading extends CcBlockNode {
  /// Creates a [CcHeading].
  const CcHeading({required this.level, required this.children});

  /// Heading level, 1–6.
  final int level;

  /// The heading's inline content.
  final List<CcInlineNode> children;

  @override
  String get nodeType => 'heading';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcHeading &&
          level == other.level &&
          ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, level, Object.hashAll(children));
}

/// A fenced or indented code block.
final class CcCodeBlock extends CcBlockNode {
  /// Creates a [CcCodeBlock].
  const CcCodeBlock({
    required this.code,
    this.language,
    this.fenced = true,
    this.closed = true,
  });

  /// The literal code, without the trailing newline.
  final String code;

  /// The info-string language (first word), or null.
  final String? language;

  /// Whether the block came from a fence (vs 4-space indentation).
  final bool fenced;

  /// False while a streaming fence has not seen its closing marker yet, so
  /// renderers can present a still-open block sanely.
  final bool closed;

  @override
  String get nodeType => 'code_block';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcCodeBlock &&
          code == other.code &&
          language == other.language &&
          fenced == other.fenced &&
          closed == other.closed;

  @override
  int get hashCode => Object.hash(nodeType, code, language, fenced, closed);
}

/// A mermaid diagram, lifted out of a ```` ```mermaid ```` fence.
///
/// The node carries the diagram SOURCE verbatim, never a parsed diagram: the
/// mermaid grammar is parsed lazily at render time (memoized by source), so
/// the AST stays cheap to compare, cheap to cache, and codec-encodable — and
/// the pure-Dart markdown parse island never pulls in the diagram engine.
final class CcMermaid extends CcBlockNode {
  /// Creates a [CcMermaid].
  const CcMermaid(this.source);

  /// The fence body: mermaid source, without the fence lines.
  final String source;

  @override
  String get nodeType => 'mermaid';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CcMermaid && source == other.source;

  @override
  int get hashCode => Object.hash(nodeType, source);

  @override
  String toString() =>
      'CcMermaid(${source.length > 40 ? '${source.substring(0, 40)}…' : source})';
}

/// A blockquote.
final class CcBlockquote extends CcBlockNode {
  /// Creates a [CcBlockquote].
  const CcBlockquote(this.children);

  /// The quoted blocks.
  final List<CcBlockNode> children;

  @override
  String get nodeType => 'blockquote';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcBlockquote && ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(nodeType, Object.hashAll(children));
}

/// One list item. A value class, not a node — its rendering is owned by the
/// parent list's builder.
final class CcListItem {
  /// Creates a [CcListItem].
  const CcListItem({required this.children, this.checked});

  /// The item's block content.
  final List<CcBlockNode> children;

  /// Task-list state: null = not a task, true/false = checked/unchecked.
  final bool? checked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcListItem &&
          checked == other.checked &&
          ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(checked, Object.hashAll(children));
}

/// An ordered or unordered list.
final class CcList extends CcBlockNode {
  /// Creates a [CcList].
  const CcList({
    required this.ordered,
    required this.items,
    this.start = 1,
    this.tight = true,
  });

  /// True for `1.`-style lists, false for bullets.
  final bool ordered;

  /// Start number of an ordered list.
  final int start;

  /// Tight lists render item content without paragraph spacing.
  final bool tight;

  /// The items.
  final List<CcListItem> items;

  @override
  String get nodeType => 'list';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcList &&
          ordered == other.ordered &&
          start == other.start &&
          tight == other.tight &&
          ccListEquals(items, other.items);

  @override
  int get hashCode =>
      Object.hash(nodeType, ordered, start, tight, Object.hashAll(items));
}

/// Cell alignment in a GFM table column.
enum CcTableAlign {
  /// `:---`
  left,

  /// `:---:`
  center,

  /// `---:`
  right,
}

/// One table cell. A value class, not a node.
final class CcTableCell {
  /// Creates a [CcTableCell].
  const CcTableCell(this.children, {this.span = 1});

  /// The cell's inline content.
  final List<CcInlineNode> children;

  /// Columns this cell spans (HTML `colspan`; 1 for GFM cells). A spanning
  /// cell is always followed by `span - 1` empty placeholder cells so every
  /// row keeps the table's full column count — the renderer merges them
  /// visually by dropping the vertical borders inside the span.
  final int span;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcTableCell &&
          span == other.span &&
          ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(span, Object.hashAll(children));
}

/// A GFM table.
final class CcTable extends CcBlockNode {
  /// Creates a [CcTable].
  const CcTable({
    required this.header,
    required this.alignments,
    required this.rows,
  });

  /// Header cells.
  final List<CcTableCell> header;

  /// Per-column alignment (null = unspecified).
  final List<CcTableAlign?> alignments;

  /// Body rows, each normalized to the header width.
  final List<List<CcTableCell>> rows;

  @override
  String get nodeType => 'table';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! CcTable ||
        !ccListEquals(header, other.header) ||
        !ccListEquals(alignments, other.alignments) ||
        rows.length != other.rows.length) {
      return false;
    }
    for (var i = 0; i < rows.length; i++) {
      if (!ccListEquals(rows[i], other.rows[i])) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    nodeType,
    Object.hashAll(header),
    Object.hashAll(alignments),
    Object.hashAll(rows.map(Object.hashAll)),
  );
}

/// A thematic break (`---`, `***`, `___`).
final class CcThematicBreak extends CcBlockNode {
  /// Creates a [CcThematicBreak].
  const CcThematicBreak();

  @override
  String get nodeType => 'thematic_break';

  @override
  bool operator ==(Object other) => other is CcThematicBreak;

  @override
  int get hashCode => nodeType.hashCode;
}

/// A raw HTML block the parser tolerated but does not interpret.
final class CcHtmlBlock extends CcBlockNode {
  /// Creates a [CcHtmlBlock].
  const CcHtmlBlock(this.raw);

  /// The raw block text.
  final String raw;

  @override
  String get nodeType => 'html_block';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is CcHtmlBlock && raw == other.raw;

  @override
  int get hashCode => Object.hash(nodeType, raw);
}

/// A `<details>`/`<summary>` disclosure block (first-class, GitHub-style).
final class CcDetails extends CcBlockNode {
  /// Creates a [CcDetails].
  const CcDetails({
    required this.summary,
    required this.children,
    this.open = false,
  });

  /// The summary line's inline content (empty → renderer supplies a default).
  final List<CcInlineNode> summary;

  /// The body blocks.
  final List<CcBlockNode> children;

  /// Whether the block carries the `open` attribute (render expanded).
  final bool open;

  @override
  String get nodeType => 'details';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcDetails &&
          open == other.open &&
          ccListEquals(summary, other.summary) &&
          ccListEquals(children, other.children);

  @override
  int get hashCode => Object.hash(
    nodeType,
    open,
    Object.hashAll(summary),
    Object.hashAll(children),
  );
}

/// A footnote definition (`[^label]: content`).
final class CcFootnoteDef extends CcBlockNode {
  /// Creates a [CcFootnoteDef].
  const CcFootnoteDef({
    required this.label,
    required this.index,
    required this.children,
  });

  /// The label as written.
  final String label;

  /// 1-based render order.
  final int index;

  /// The definition's block content.
  final List<CcBlockNode> children;

  @override
  String get nodeType => 'footnote_def';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcFootnoteDef &&
          label == other.label &&
          index == other.index &&
          ccListEquals(children, other.children);

  @override
  int get hashCode =>
      Object.hash(nodeType, label, index, Object.hashAll(children));
}
