/// Kind of a relationship (edge) between two code symbols.
///
/// Persisted as [name] in the `code_edges.kind` column. Names that would
/// collide with Dart keywords are suffixed with `Type` (`extendsType`,
/// `implementsType`).
enum CodeEdgeKind {
  /// Source invokes target (function/method call).
  calls('Calls'),

  /// Source file imports the target library/URI.
  imports('Imports'),

  /// Source class extends target class.
  extendsType('Extends'),

  /// Source class implements target interface.
  implementsType('Implements'),

  /// Source class mixes in the target mixin.
  mixesIn('Mixes in'),

  /// Generic reference (fallback when no more specific kind applies).
  references('References');

  const CodeEdgeKind(this.label);

  /// Human-readable label for display.
  final String label;

  /// Parses a persisted [name] back into a [CodeEdgeKind], case-insensitively.
  /// Returns null for null or unrecognized input.
  static CodeEdgeKind? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final kind in CodeEdgeKind.values) {
      if (kind.name.toLowerCase() == value.toLowerCase()) {
        return kind;
      }
    }
    return null;
  }
}
