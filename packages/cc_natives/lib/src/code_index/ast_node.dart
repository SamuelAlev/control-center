/// One node of a materialized syntax tree.
///
/// **Why materialize at all** rather than walking the native tree in place. A
/// `TSNode` is only valid while its `TSTree` is alive, and the tree is a native
/// allocation an isolate's death does not reclaim. Structural matching wants to
/// backtrack freely — try a child, fail, try the next — and doing that against
/// live pointers means every path out of the matcher has to be a path that
/// frees the tree. Copying the shape out once, into plain Dart objects, makes
/// the matcher a pure function over data and confines native lifetime to a
/// single `try/finally`.
///
/// The copy is shape only: [text] is a view into the source string, not a
/// second allocation of it.
class AstNode {
  /// Creates an [AstNode].
  AstNode({
    required this.type,
    required this.isNamed,
    required this.startByte,
    required this.endByte,
    required this.startLine,
    required this.endLine,
    required this.text,
    required this.children,
    this.fieldName,
  });

  /// The grammar's name for this node (`method_declaration`, `identifier`, …).
  final String type;

  /// Whether the grammar names this node, as opposed to an anonymous token
  /// like `{` or `,`.
  ///
  /// Matching walks NAMED children: a pattern must not have to spell out every
  /// brace and comma the grammar emits, and two grammars disagree about those
  /// far more often than they disagree about structure.
  final bool isNamed;

  /// Byte offset of the first byte, in the UTF-8 encoding of the source.
  final int startByte;

  /// Byte offset one past the last byte.
  final int endByte;

  /// 1-indexed first line.
  final int startLine;

  /// 1-indexed last line.
  final int endLine;

  /// The source text this node spans.
  final String text;

  /// The field the parent gave this node, or null when it is positional.
  final String? fieldName;

  /// Children, in source order, anonymous tokens included.
  final List<AstNode> children;

  /// Children the grammar names.
  Iterable<AstNode> get namedChildren => children.where((c) => c.isNamed);

  /// Every node in this subtree, this one first (pre-order).
  Iterable<AstNode> get descendants sync* {
    yield this;
    for (final child in children) {
      yield* child.descendants;
    }
  }

  @override
  String toString() => '$type[$startLine-$endLine]';
}
