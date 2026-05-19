// Hunk → symbol mapping: the join between a unified diff and the code graph.
//
// A file list tells a reviewer WHERE the change is; a symbol list tells them
// WHAT changed. "auth_service.dart, 340 lines" and "`AuthService.refresh` and
// `AuthService._retry` changed" are the same diff described at two very
// different altitudes, and only the second one can be reasoned about.
//
// Pure: line arithmetic over already-parsed diff lines and already-read symbol
// spans. No I/O, no natives.

import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/cohort_insights.dart';

/// Maps a diff's changed lines onto the symbols that contain them.
class ChangedSymbolMapper {
  /// Creates a [ChangedSymbolMapper].
  const ChangedSymbolMapper();

  /// Returns the symbols touched by [parsedPatchByFile], most-changed first.
  ///
  /// [symbolsByFile] holds the symbol spans of each changed file. Additions are
  /// matched against `newLine` (head-side spans) and deletions against
  /// `oldLine`; when the spans come from the base partition the head-side match
  /// is approximate, which is why the caller stamps [SymbolSource] alongside.
  ///
  /// A changed line inside several nested spans (a method inside a class)
  /// attributes to the SMALLEST containing span — the method, not the class —
  /// so the result names the unit of work rather than the file's outermost
  /// declaration.
  List<ChangedSymbol> map({
    required Map<String, List<DiffLine>> parsedPatchByFile,
    required Map<String, List<SymbolSpan>> symbolsByFile,
  }) {
    final added = <SymbolSpan, int>{};
    final removed = <SymbolSpan, int>{};

    for (final entry in parsedPatchByFile.entries) {
      final spans = symbolsByFile[entry.key];
      if (spans == null || spans.isEmpty) {
        continue;
      }
      for (final line in entry.value) {
        switch (line.kind) {
          case DiffLineKind.addition:
            final n = line.newLine;
            if (n == null) {
              continue;
            }
            final span = _smallestContaining(spans, n);
            if (span != null) {
              added[span] = (added[span] ?? 0) + 1;
            }
          case DiffLineKind.deletion:
            final o = line.oldLine;
            if (o == null) {
              continue;
            }
            final span = _smallestContaining(spans, o);
            if (span != null) {
              removed[span] = (removed[span] ?? 0) + 1;
            }
          case DiffLineKind.context:
          case DiffLineKind.hunkHeader:
          case DiffLineKind.expandGap:
            continue;
        }
      }
    }

    final touched = {...added.keys, ...removed.keys};
    final result = [
      for (final span in touched)
        ChangedSymbol(
          symbol: span,
          addedLines: added[span] ?? 0,
          removedLines: removed[span] ?? 0,
        ),
    ];
    result.sort((a, b) {
      final byChanged = b.changedLines.compareTo(a.changedLines);
      if (byChanged != 0) {
        return byChanged;
      }
      final byFile = a.symbol.filePath.compareTo(b.symbol.filePath);
      if (byFile != 0) {
        return byFile;
      }
      return a.symbol.startLine.compareTo(b.symbol.startLine);
    });
    return result;
  }

  /// The smallest span in [spans] containing [line], or null when none does
  /// (a change between top-level declarations — an import, a constant).
  SymbolSpan? enclosingSymbol(int line, List<SymbolSpan> spans) =>
      _smallestContaining(spans, line);

  SymbolSpan? _smallestContaining(List<SymbolSpan> spans, int line) {
    SymbolSpan? best;
    for (final span in spans) {
      if (!span.contains(line)) {
        continue;
      }
      if (best == null || span.lineCount < best.lineCount) {
        best = span;
      }
    }
    return best;
  }
}
