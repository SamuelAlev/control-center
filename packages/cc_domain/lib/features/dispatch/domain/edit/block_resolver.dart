/// The block-resolution seam: an abstract [BlockResolver] port plus its
/// [BlockSpan] result and the [BlockResolutionException] thrown when a
/// replace/delete block cannot be resolved.
///
/// The hashline core declares the contract only. A tree-sitter-backed
/// implementation lives in the infrastructure layer and is injected into the
/// patcher — this package never depends on a parser.
library;

/// A resolved 1-indexed inclusive line span of a block.
///
/// `startLine` and `endLine` are both inclusive; a single-line block has
/// `startLine == endLine`.
class BlockSpan {
  /// Creates a [BlockSpan].
  const BlockSpan({required this.startLine, required this.endLine});

  /// First line of the block (1-indexed, inclusive).
  final int startLine;

  /// Last line of the block (1-indexed, inclusive).
  final int endLine;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockSpan &&
          other.startLine == startLine &&
          other.endLine == endLine;

  @override
  int get hashCode => Object.hash(startLine, endLine);

  @override
  String toString() => 'BlockSpan($startLine..$endLine)';
}

/// Resolves a block anchor to the line span of the syntactic construct that
/// begins on the anchor line.
///
/// Pure seam: implementations parse `text` (with the language inferred from
/// `path`) and return the [BlockSpan] of the construct beginning on `line`, or
/// null when no block can be resolved (unrecognized language, blank or
/// out-of-range line, no node begins there, or the resolved subtree has a
/// syntax error). The hashline core injects an implementation; it never
/// provides one.
abstract class BlockResolver {
  /// Resolve the block beginning on the 1-indexed [line] of [text].
  ///
  /// Returns the construct's inclusive [BlockSpan], or null when it cannot be
  /// resolved.
  BlockSpan? resolveBlock({
    required String path,
    required String text,
    required int line,
  });
}

/// Thrown when a replace/delete block edit cannot be safely resolved.
///
/// Unlike an insert-after block (which lowers to a plain after-anchor insert),
/// a replace/delete block has no safe fallback when its span is unknown or
/// collapses to a single line, so the patcher must reject it and prompt a
/// re-read. The [message] is surfaced verbatim to the caller.
class BlockResolutionException implements Exception {
  /// Creates a [BlockResolutionException].
  const BlockResolutionException(this.message);

  /// Human-readable description of why the block could not be resolved.
  final String message;

  @override
  String toString() => 'BlockResolutionException: $message';
}
