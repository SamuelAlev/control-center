/// Kind of a code symbol extracted from source code.
///
/// Persisted as [name] in the `code_symbols.kind` column. The tree-sitter
/// extraction layer maps raw grammar node types onto these values — that
/// mapping is the contract between the parser and storage. Enum names that
/// would collide with Dart keywords are suffixed with `Kind`
/// (`classKind`, `enumKind`, `typedefKind`).
enum CodeSymbolKind {
  /// A free function (top-level or local).
  function('Function'),

  /// A method declared on a class, mixin, or extension.
  method('Method'),

  /// A class declaration.
  classKind('Class'),

  /// An instance or static field.
  field('Field'),

  /// An enum declaration.
  enumKind('Enum'),

  /// A constructor (generative or factory).
  constructor('Constructor'),

  /// A getter.
  getter('Getter'),

  /// A setter.
  setter('Setter'),

  /// A typedef / type alias.
  typedefKind('Typedef'),

  /// An extension declaration.
  extension('Extension'),

  /// A mixin declaration.
  mixin('Mixin'),

  /// A top-level or static variable / constant.
  variable('Variable');

  const CodeSymbolKind(this.label);

  /// Human-readable label for display.
  final String label;

  /// Parses a persisted [name] back into a [CodeSymbolKind], case-insensitively.
  /// Returns null for null or unrecognized input.
  static CodeSymbolKind? tryParse(String? value) {
    if (value == null) {
      return null;
    }
    for (final kind in CodeSymbolKind.values) {
      if (kind.name.toLowerCase() == value.toLowerCase()) {
        return kind;
      }
    }
    return null;
  }
}
