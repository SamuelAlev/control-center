/// Value object that wraps a sensitive token string.
///
/// [toString] masks the value so it never leaks in logs.
class Token {
  /// Creates a [Token] wrapping [value].
  const Token(this.value);

  /// The raw token value.
  final String value;

  /// Whether [value] is empty.
  bool get isEmpty => value.isEmpty;

  /// Whether [value] is not empty.
  bool get isNotEmpty => value.isNotEmpty;

  @override
  String toString() => 'Token(****)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Token &&
          runtimeType == other.runtimeType &&
          value == other.value;

  @override
  int get hashCode => value.hashCode;
}

