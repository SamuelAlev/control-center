import 'package:cc_markdown/src/ast/document.dart';
import 'package:cc_markdown/src/ast/nodes.dart';
import 'package:cc_markdown/src/parser/block_parser.dart';
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
}
