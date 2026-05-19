/// Feature toggles and safety caps for [CcParser].
///
/// Defaults are the GitHub-flavored profile the app targets. All parsing is
/// non-throwing: input beyond a cap degrades to literal paragraph text.
class CcParseOptions {
  /// Creates a [CcParseOptions].
  const CcParseOptions({
    this.tables = true,
    this.strikethrough = true,
    this.autolinkExtension = true,
    this.footnotes = true,
    this.details = true,
    this.htmlBlocks = true,
    this.taskLists = true,
    this.setextHeadings = true,
    this.indentedCode = true,
    this.mermaid = true,
    this.emoji = true,
    this.maxBlockDepth = 32,
    this.maxInlineDepth = 16,
  });

  /// GFM pipe tables.
  final bool tables;

  /// GFM `~~strikethrough~~`.
  final bool strikethrough;

  /// GFM bare-URL / `www.` autolinks (plain `<url>` autolinks are always on).
  final bool autolinkExtension;

  /// Footnote references and definitions.
  final bool footnotes;

  /// `<details>`/`<summary>` disclosure blocks as first-class nodes.
  final bool details;

  /// Interpret tolerated raw-HTML blocks (the GitHub bot subset: `<table>`,
  /// `<details>`, headings, lists, `<pre>`, inline formatting) into
  /// first-class nodes. Off, they stay raw [CcHtmlBlock] fallbacks.
  final bool htmlBlocks;

  /// `- [x]` task-list checkboxes.
  final bool taskLists;

  /// Setext (`===`/`---` underline) headings.
  final bool setextHeadings;

  /// 4-space indented code blocks.
  final bool indentedCode;

  /// Lift a CLOSED ```` ```mermaid ```` fence into a first-class [CcMermaid]
  /// node (rendered as a diagram) instead of a code block. A still-open fence
  /// stays a code block, so a streaming diagram reads as code until the
  /// closing marker arrives rather than flickering through partial layouts.
  final bool mermaid;

  /// GitHub `:shortcode:` emoji (`:tada:` → 🎉), resolved against the gemoji
  /// table GitHub itself renders with. An unknown name stays literal text,
  /// which is also what GitHub's ~23 CUSTOM image shortcodes (`:octocat:`,
  /// `:shipit:`) do here — they are images, not characters.
  final bool emoji;

  /// Maximum container nesting (blockquotes/lists) before falling back to
  /// paragraph text.
  final int maxBlockDepth;

  /// Maximum inline nesting before falling back to literal text.
  final int maxInlineDepth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcParseOptions &&
          tables == other.tables &&
          strikethrough == other.strikethrough &&
          autolinkExtension == other.autolinkExtension &&
          footnotes == other.footnotes &&
          details == other.details &&
          htmlBlocks == other.htmlBlocks &&
          taskLists == other.taskLists &&
          setextHeadings == other.setextHeadings &&
          indentedCode == other.indentedCode &&
          mermaid == other.mermaid &&
          emoji == other.emoji &&
          maxBlockDepth == other.maxBlockDepth &&
          maxInlineDepth == other.maxInlineDepth;

  @override
  int get hashCode => Object.hash(
    tables,
    strikethrough,
    autolinkExtension,
    footnotes,
    details,
    htmlBlocks,
    taskLists,
    setextHeadings,
    indentedCode,
    mermaid,
    emoji,
    maxBlockDepth,
    maxInlineDepth,
  );
}
