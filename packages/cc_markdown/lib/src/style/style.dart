import 'package:cc_markdown/src/mermaid/mermaid_style.dart';
import 'package:flutter/widgets.dart';

/// How soft line breaks (single newlines inside a paragraph) render.
enum CcSoftBreakMode {
  /// Render as a newline (GitHub-comment / chat behavior — the default).
  newline,

  /// Render as a space (strict CommonMark).
  space,
}

/// The unified cc_markdown stylesheet: a plain immutable value type with NO
/// Theme coupling — the app builds one from its design tokens (Theme access
/// happens app-side) and passes it in.
///
/// Full value equality is deliberate: the streaming widget's block memo keys
/// on style equality, so a token-driven rebuild that produces an equal style
/// is a non-event.
@immutable
class CcMarkdownStyle {
  /// Creates a [CcMarkdownStyle].
  const CcMarkdownStyle({
    this.paragraph,
    this.h1,
    this.h2,
    this.h3,
    this.h4,
    this.h5,
    this.h6,
    this.code,
    this.inlineCode,
    this.link,
    this.blockquote,
    this.bold,
    this.italic,
    this.strikethrough,
    this.listBullet,
    this.tableHead,
    this.tableBody,
    this.h1Padding,
    this.h2Padding,
    this.h3Padding,
    this.h4Padding,
    this.h5Padding,
    this.h6Padding,
    this.blockquoteDecoration,
    this.blockquotePadding,
    this.codeblockDecoration,
    this.codeblockPadding,
    this.inlineCodePadding,
    this.inlineCodeRadius,
    this.tableBorder,
    this.tableHeadDecoration,
    this.tableCellPadding,
    this.horizontalRuleColor,
    this.blockSpacing = 12.0,
    this.listIndent = 24.0,
    this.listItemGap = 4.0,
    this.checkbox,
    this.softBreakMode = CcSoftBreakMode.newline,
    this.mermaid,
  });

  /// Base paragraph text style. All inline styles merge onto this.
  final TextStyle? paragraph;

  /// Heading styles, levels 1–6.
  final TextStyle? h1, h2, h3, h4, h5, h6;

  /// Code-block text style (used by the default code builder when no
  /// `codeBuilder` callback is supplied).
  final TextStyle? code;

  /// Inline code span style.
  final TextStyle? inlineCode;

  /// Link style.
  final TextStyle? link;

  /// Blockquote text style.
  final TextStyle? blockquote;

  /// Bold / italic / strikethrough overrides (defaults derive from
  /// [paragraph] with weight/style/decoration applied).
  final TextStyle? bold, italic, strikethrough;

  /// List marker style.
  final TextStyle? listBullet;

  /// Table header / body cell styles.
  final TextStyle? tableHead, tableBody;

  /// Per-level heading padding.
  final EdgeInsets? h1Padding,
      h2Padding,
      h3Padding,
      h4Padding,
      h5Padding,
      h6Padding;

  /// Blockquote container decoration.
  final BoxDecoration? blockquoteDecoration;

  /// Blockquote container padding.
  final EdgeInsets? blockquotePadding;

  /// Code-block container decoration (default code builder only).
  final BoxDecoration? codeblockDecoration;

  /// Code-block container padding (default code builder only).
  final EdgeInsets? codeblockPadding;

  /// Inline-code chip padding (default inline-code builder).
  final EdgeInsets? inlineCodePadding;

  /// Inline-code chip corner radius (default inline-code builder).
  final double? inlineCodeRadius;

  /// Table border.
  final TableBorder? tableBorder;

  /// Table header-row decoration.
  final BoxDecoration? tableHeadDecoration;

  /// Padding inside each table cell.
  final EdgeInsets? tableCellPadding;

  /// Thematic break color.
  final Color? horizontalRuleColor;

  /// Vertical gap between sibling blocks.
  final double blockSpacing;

  /// Indentation per list nesting level.
  final double listIndent;

  /// Vertical gap between items of a tight list.
  final double listItemGap;

  /// Task-list checkbox factory — the app plugs its design-system checkbox in
  /// here; null renders a plain unicode marker.
  final Widget Function(bool checked)? checkbox;

  /// Soft line break behavior.
  final CcSoftBreakMode softBreakMode;

  /// Diagram stylesheet for ```` ```mermaid ```` fences. Null falls back to the
  /// engine's neutral defaults derived from [paragraph] — pass one built from
  /// your design tokens so diagrams match the surface they sit on.
  final CcMermaidStyle? mermaid;

  /// The mermaid stylesheet to render with: [mermaid] when supplied, otherwise
  /// a neutral one that at least inherits the document's body font and size.
  CcMermaidStyle get resolvedMermaid {
    final explicit = mermaid;
    if (explicit != null) {
      return explicit;
    }
    final base = paragraph;
    if (base == null) {
      return const CcMermaidStyle();
    }
    const fallback = CcMermaidStyle();
    return fallback.copyWith(
      label: fallback.label.copyWith(
        fontFamily: base.fontFamily,
        fontFamilyFallback: base.fontFamilyFallback,
        fontSize: base.fontSize == null ? null : base.fontSize! - 1,
        color: base.color,
      ),
      compartment: (code ?? base).copyWith(
        fontSize: (code?.fontSize ?? base.fontSize ?? 13) - 1,
      ),
    );
  }

  /// Style for the heading at [level] (1-based).
  TextStyle? headingStyle(int level) => switch (level) {
    1 => h1,
    2 => h2,
    3 => h3,
    4 => h4,
    5 => h5,
    _ => h6,
  };

  /// Padding for the heading at [level] (1-based).
  EdgeInsets? headingPadding(int level) => switch (level) {
    1 => h1Padding,
    2 => h2Padding,
    3 => h3Padding,
    4 => h4Padding,
    5 => h5Padding,
    _ => h6Padding,
  };

  /// A copy with the given fields replaced.
  CcMarkdownStyle copyWith({
    TextStyle? paragraph,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? h4,
    TextStyle? h5,
    TextStyle? h6,
    TextStyle? code,
    TextStyle? inlineCode,
    TextStyle? link,
    TextStyle? blockquote,
    TextStyle? bold,
    TextStyle? italic,
    TextStyle? strikethrough,
    TextStyle? listBullet,
    TextStyle? tableHead,
    TextStyle? tableBody,
    EdgeInsets? h1Padding,
    EdgeInsets? h2Padding,
    EdgeInsets? h3Padding,
    EdgeInsets? h4Padding,
    EdgeInsets? h5Padding,
    EdgeInsets? h6Padding,
    BoxDecoration? blockquoteDecoration,
    EdgeInsets? blockquotePadding,
    BoxDecoration? codeblockDecoration,
    EdgeInsets? codeblockPadding,
    EdgeInsets? inlineCodePadding,
    double? inlineCodeRadius,
    TableBorder? tableBorder,
    BoxDecoration? tableHeadDecoration,
    EdgeInsets? tableCellPadding,
    Color? horizontalRuleColor,
    double? blockSpacing,
    double? listIndent,
    double? listItemGap,
    Widget Function(bool checked)? checkbox,
    CcSoftBreakMode? softBreakMode,
    CcMermaidStyle? mermaid,
  }) {
    return CcMarkdownStyle(
      paragraph: paragraph ?? this.paragraph,
      h1: h1 ?? this.h1,
      h2: h2 ?? this.h2,
      h3: h3 ?? this.h3,
      h4: h4 ?? this.h4,
      h5: h5 ?? this.h5,
      h6: h6 ?? this.h6,
      code: code ?? this.code,
      inlineCode: inlineCode ?? this.inlineCode,
      link: link ?? this.link,
      blockquote: blockquote ?? this.blockquote,
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      strikethrough: strikethrough ?? this.strikethrough,
      listBullet: listBullet ?? this.listBullet,
      tableHead: tableHead ?? this.tableHead,
      tableBody: tableBody ?? this.tableBody,
      h1Padding: h1Padding ?? this.h1Padding,
      h2Padding: h2Padding ?? this.h2Padding,
      h3Padding: h3Padding ?? this.h3Padding,
      h4Padding: h4Padding ?? this.h4Padding,
      h5Padding: h5Padding ?? this.h5Padding,
      h6Padding: h6Padding ?? this.h6Padding,
      blockquoteDecoration: blockquoteDecoration ?? this.blockquoteDecoration,
      blockquotePadding: blockquotePadding ?? this.blockquotePadding,
      codeblockDecoration: codeblockDecoration ?? this.codeblockDecoration,
      codeblockPadding: codeblockPadding ?? this.codeblockPadding,
      inlineCodePadding: inlineCodePadding ?? this.inlineCodePadding,
      inlineCodeRadius: inlineCodeRadius ?? this.inlineCodeRadius,
      tableBorder: tableBorder ?? this.tableBorder,
      tableHeadDecoration: tableHeadDecoration ?? this.tableHeadDecoration,
      tableCellPadding: tableCellPadding ?? this.tableCellPadding,
      horizontalRuleColor: horizontalRuleColor ?? this.horizontalRuleColor,
      blockSpacing: blockSpacing ?? this.blockSpacing,
      listIndent: listIndent ?? this.listIndent,
      listItemGap: listItemGap ?? this.listItemGap,
      checkbox: checkbox ?? this.checkbox,
      softBreakMode: softBreakMode ?? this.softBreakMode,
      mermaid: mermaid ?? this.mermaid,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is CcMarkdownStyle &&
        paragraph == other.paragraph &&
        h1 == other.h1 &&
        h2 == other.h2 &&
        h3 == other.h3 &&
        h4 == other.h4 &&
        h5 == other.h5 &&
        h6 == other.h6 &&
        code == other.code &&
        inlineCode == other.inlineCode &&
        link == other.link &&
        blockquote == other.blockquote &&
        bold == other.bold &&
        italic == other.italic &&
        strikethrough == other.strikethrough &&
        listBullet == other.listBullet &&
        tableHead == other.tableHead &&
        tableBody == other.tableBody &&
        h1Padding == other.h1Padding &&
        h2Padding == other.h2Padding &&
        h3Padding == other.h3Padding &&
        h4Padding == other.h4Padding &&
        h5Padding == other.h5Padding &&
        h6Padding == other.h6Padding &&
        blockquoteDecoration == other.blockquoteDecoration &&
        blockquotePadding == other.blockquotePadding &&
        codeblockDecoration == other.codeblockDecoration &&
        codeblockPadding == other.codeblockPadding &&
        inlineCodePadding == other.inlineCodePadding &&
        inlineCodeRadius == other.inlineCodeRadius &&
        tableBorder == other.tableBorder &&
        tableHeadDecoration == other.tableHeadDecoration &&
        tableCellPadding == other.tableCellPadding &&
        horizontalRuleColor == other.horizontalRuleColor &&
        blockSpacing == other.blockSpacing &&
        listIndent == other.listIndent &&
        listItemGap == other.listItemGap &&
        checkbox == other.checkbox &&
        softBreakMode == other.softBreakMode &&
        mermaid == other.mermaid;
  }

  @override
  int get hashCode => Object.hashAll([
    paragraph,
    h1,
    h2,
    h3,
    h4,
    h5,
    h6,
    code,
    inlineCode,
    link,
    blockquote,
    bold,
    italic,
    strikethrough,
    listBullet,
    tableHead,
    tableBody,
    h1Padding,
    h2Padding,
    h3Padding,
    h4Padding,
    h5Padding,
    h6Padding,
    blockquoteDecoration,
    blockquotePadding,
    codeblockDecoration,
    codeblockPadding,
    inlineCodePadding,
    inlineCodeRadius,
    tableBorder,
    tableHeadDecoration,
    tableCellPadding,
    horizontalRuleColor,
    blockSpacing,
    listIndent,
    listItemGap,
    checkbox,
    softBreakMode,
    mermaid,
  ]);
}
