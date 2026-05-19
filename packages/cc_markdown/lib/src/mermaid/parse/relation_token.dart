/// Finding the relation token inside a class/ER statement.
///
/// Both dialects write `LEFT marker line marker RIGHT` (`Animal <|-- Duck`,
/// `CUSTOMER ||--o{ ORDER`), which a single regex cannot split safely: a
/// one-character marker like `o` (aggregation) is also an ordinary letter, so
/// `Order o-- Item` must not parse as `Ord` + `er o--`. The scanner therefore
/// anchors on the LINE run (`--` / `..`) and only accepts a one-character
/// marker when a word boundary sits on its outer side. Two-character markers
/// (`<|`, `|>`, `||`, `o{`, `}o`) are unambiguous — no identifier contains
/// `|`, `{`, or `}` — so they are always accepted.
library;

/// A relation token located inside a statement.
class MermaidRelationToken {
  /// Creates a [MermaidRelationToken].
  const MermaidRelationToken({
    required this.start,
    required this.end,
    required this.leftMarker,
    required this.line,
    required this.rightMarker,
  });

  /// Index of the token's first character (its left marker, if any).
  final int start;

  /// Index just past the token's last character.
  final int end;

  /// Raw left marker text (empty when absent).
  final String leftMarker;

  /// The line run: `--`/`---`/… or `..`/`...`.
  final String line;

  /// Raw right marker text (empty when absent).
  final String rightMarker;

  /// Whether the line is dotted (`..`).
  bool get dashed => line.startsWith('.');
}

final RegExp _lineRun = RegExp(r'-{2,}|\.{2,}');

bool _isBoundary(int? unit) =>
    unit == null || unit == 0x20 || unit == 0x09 || unit == 0x22 /* " */;

/// Finds the first relation token in [statement], or null when there is none.
///
/// [markers] lists every accepted marker text for both ends, longest-first
/// order is applied internally.
MermaidRelationToken? findRelationToken(
  String statement, {
  required List<String> markers,
}) {
  final sorted = [...markers]..sort((a, b) => b.length.compareTo(a.length));
  for (final run in _lineRun.allMatches(statement)) {
    var start = run.start;
    var leftMarker = '';
    for (final marker in sorted) {
      final from = run.start - marker.length;
      if (from < 0 || !statement.startsWith(marker, from)) {
        continue;
      }
      if (marker.length == 1 &&
          !_isBoundary(from == 0 ? null : statement.codeUnitAt(from - 1))) {
        continue;
      }
      leftMarker = marker;
      start = from;
      break;
    }

    var end = run.end;
    var rightMarker = '';
    for (final marker in sorted) {
      if (!statement.startsWith(marker, run.end)) {
        continue;
      }
      final after = run.end + marker.length;
      if (marker.length == 1 &&
          !_isBoundary(
            after >= statement.length ? null : statement.codeUnitAt(after),
          )) {
        continue;
      }
      rightMarker = marker;
      end = after;
      break;
    }

    if (statement.substring(0, start).trim().isEmpty ||
        statement.substring(end).trim().isEmpty) {
      continue;
    }
    return MermaidRelationToken(
      start: start,
      end: end,
      leftMarker: leftMarker,
      line: run.group(0)!,
      rightMarker: rightMarker,
    );
  }
  return null;
}
