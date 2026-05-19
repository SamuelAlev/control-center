import 'package:cc_markdown/src/ast/document.dart';
import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/parser/block_parser.dart';
import 'package:cc_markdown/src/parser/inline_parser.dart';
import 'package:cc_markdown/src/parser/parse_options.dart';
import 'package:cc_markdown/src/plugins/plugin.dart';

/// The cc_markdown parser facade.
///
/// Stateless and reusable; construction is cheap. Parsing never throws —
/// malformed input degrades to paragraph text.
final class CcParser {
  /// Creates a [CcParser].
  const CcParser({
    this.plugins = CcPluginSet.empty,
    this.options = const CcParseOptions(),
  });

  /// Registered parser plugins.
  final CcPluginSet plugins;

  /// Feature toggles and safety caps.
  final CcParseOptions options;

  /// Parses [source] into a [CcDocument] (blocks + link refs + footnotes).
  CcDocument parseDocument(String source) =>
      parseMarkdownDocument(source, options: options, plugins: plugins);

  /// Parses [source] and returns just the block list.
  List<CcBlockNode> parse(String source) => parseDocument(source).blocks;

  /// Parses [source] as INLINE content only — the pass a GFM table cell gets.
  ///
  /// Emphasis, inline code, links, autolinks, strikethrough and inline HTML are
  /// recognized; a leading `#`, `- ` or ``` ``` ``` is literal text, because a
  /// cell is not a block context.
  ///
  /// This exists for callers holding TYPED data whose fields may still carry
  /// inline markdown (an artifact table cell, a chart label). Block-parsing
  /// such a field and digging the paragraph back out is not the same thing: it
  /// turns `- x` into a list and `# x` into a heading, neither of which a cell
  /// can render.
  ///
  /// Link REFERENCES (`[x][ref]`) do not resolve here — a lone field carries no
  /// document to collect definitions from — and footnote syntax stays literal.
  List<CcInlineNode> parseInline(String source) =>
      CcInlineParser(options: options, plugins: plugins).parse(source);
}
