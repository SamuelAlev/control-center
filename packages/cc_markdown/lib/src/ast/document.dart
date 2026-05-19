import 'package:cc_markdown/src/ast/nodes.dart';

/// A resolved link-reference definition (`[label]: url "title"`).
final class CcLinkReference {
  /// Creates a [CcLinkReference].
  const CcLinkReference({required this.url, this.title});

  /// The destination URL.
  final String url;

  /// The optional title.
  final String? title;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CcLinkReference && url == other.url && title == other.title;

  @override
  int get hashCode => Object.hash(url, title);
}

/// A fully parsed markdown document: the block list plus the document-level
/// side tables the inline pass resolved against.
final class CcDocument {
  /// Creates a [CcDocument].
  const CcDocument({
    required this.blocks,
    this.linkRefs = const {},
    this.footnotes = const [],
  });

  /// The top-level blocks in source order. Footnote definitions are NOT in
  /// this list — they render from [footnotes] at the end of the document.
  final List<CcBlockNode> blocks;

  /// Link-reference definitions, keyed by normalized (lowercased, whitespace-
  /// collapsed) label.
  final Map<String, CcLinkReference> linkRefs;

  /// Footnote definitions in first-reference order (their `index` is 1-based
  /// position in this list).
  final List<CcFootnoteDef> footnotes;
}
