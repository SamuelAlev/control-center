/// Where in a code mode script a tool call was made: a 1-based line and
/// column in the script as the model wrote it.
///
/// A display hint, nothing more. The runner that reports it executes
/// model-written code, so a site is untrusted input: it places a call in the
/// script's structure when a transcript or a record is shown, and nothing that
/// decides may read it (policy, approval text, fingerprints, audit summaries,
/// digests). Out-of-range or malformed sites are dropped by [tryParse] rather
/// than refused, so a bad one costs the row nothing but its position.
class ScriptCallSite {
  /// Creates a site. Throws [ArgumentError] when [line] or [column] is outside
  /// 1..[maxPosition].
  ScriptCallSite(this.line, this.column) {
    _requireInRange(line, 'line');
    _requireInRange(column, 'column');
  }

  /// The largest line or column a site may name (2^20). A script is at most a
  /// few hundred KiB, so a larger position is not one the model wrote.
  static const int maxPosition = 1048576;

  /// Rebuilds from [toJson]'s output, or returns null for anything that is
  /// not exactly a list of two integers, each in 1..[maxPosition].
  static ScriptCallSite? tryParse(Object? json) {
    if (json is! List || json.length != 2) {
      return null;
    }
    final [line, column] = json;
    if (line is! int || column is! int) {
      return null;
    }
    if (!_inRange(line) || !_inRange(column)) {
      return null;
    }
    return ScriptCallSite(line, column);
  }

  /// The 1-based line.
  final int line;

  /// The 1-based column.
  final int column;

  /// The wire form: `[line, column]`.
  List<int> toJson() => [line, column];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScriptCallSite && other.line == line && other.column == column;

  @override
  int get hashCode => Object.hash(ScriptCallSite, line, column);

  @override
  String toString() => 'ScriptCallSite($line:$column)';

  static bool _inRange(int value) => value >= 1 && value <= maxPosition;

  static void _requireInRange(int value, String name) {
    if (!_inRange(value)) {
      throw ArgumentError.value(
        value,
        name,
        'must be between 1 and $maxPosition',
      );
    }
  }
}
