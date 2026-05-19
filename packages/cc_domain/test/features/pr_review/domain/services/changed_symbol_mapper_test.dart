import 'package:cc_domain/features/pr_review/domain/services/changed_symbol_mapper.dart';
import 'package:cc_domain/features/pr_review/domain/services/diff_parser.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/cohort_insights.dart';
import 'package:test/test.dart';

SymbolSpan span(
  String name,
  int start,
  int end, {
  String file = 'lib/auth.dart',
  String kind = 'method',
}) => SymbolSpan(
  name: name,
  qualifiedName: 'AuthService.$name',
  kind: kind,
  filePath: file,
  startLine: start,
  endLine: end,
);

void main() {
  const mapper = ChangedSymbolMapper();

  group('ChangedSymbolMapper', () {
    test('attributes an added line to the symbol containing it', () {
      // A hunk that adds one line at new-line 12.
      const patch = '@@ -10,3 +10,4 @@\n ctx\n ctx\n+added\n ctx\n';
      final result = mapper.map(
        parsedPatchByFile: {'lib/auth.dart': parseUnifiedDiff(patch)},
        symbolsByFile: {
          'lib/auth.dart': [span('refresh', 5, 20)],
        },
      );
      expect(result, hasLength(1));
      expect(result.single.symbol.name, 'refresh');
      expect(result.single.addedLines, 1);
      expect(result.single.removedLines, 0);
    });

    test('attributes to the smallest containing span, not the class', () {
      const patch = '@@ -10,2 +10,3 @@\n ctx\n+added\n ctx\n';
      final result = mapper.map(
        parsedPatchByFile: {'lib/auth.dart': parseUnifiedDiff(patch)},
        symbolsByFile: {
          'lib/auth.dart': [
            span('AuthService', 1, 200, kind: 'class'),
            span('refresh', 5, 20),
          ],
        },
      );
      expect(result.single.symbol.name, 'refresh');
    });

    test('counts deletions against the old-side line numbers', () {
      const patch = '@@ -10,3 +10,2 @@\n ctx\n-gone\n ctx\n';
      final result = mapper.map(
        parsedPatchByFile: {'lib/auth.dart': parseUnifiedDiff(patch)},
        symbolsByFile: {
          'lib/auth.dart': [span('refresh', 5, 20)],
        },
      );
      expect(result.single.removedLines, 1);
      expect(result.single.addedLines, 0);
    });

    test('ignores changes outside every span', () {
      const patch = '@@ -1,2 +1,3 @@\n ctx\n+import x;\n ctx\n';
      final result = mapper.map(
        parsedPatchByFile: {'lib/auth.dart': parseUnifiedDiff(patch)},
        symbolsByFile: {
          'lib/auth.dart': [span('refresh', 50, 80)],
        },
      );
      expect(result, isEmpty);
    });

    test('ignores files with no known symbols', () {
      const patch = '@@ -1,1 +1,2 @@\n ctx\n+added\n';
      final result = mapper.map(
        parsedPatchByFile: {'lib/unknown.dart': parseUnifiedDiff(patch)},
        symbolsByFile: const {},
      );
      expect(result, isEmpty);
    });

    test('sorts by total changed lines, most-changed first', () {
      const big = '@@ -10,1 +10,4 @@\n ctx\n+a\n+b\n+c\n';
      const small = '@@ -10,1 +10,2 @@\n ctx\n+a\n';
      final result = mapper.map(
        parsedPatchByFile: {
          'lib/a.dart': parseUnifiedDiff(small),
          'lib/b.dart': parseUnifiedDiff(big),
        },
        symbolsByFile: {
          'lib/a.dart': [span('small', 1, 40, file: 'lib/a.dart')],
          'lib/b.dart': [span('big', 1, 40, file: 'lib/b.dart')],
        },
      );
      expect(result.first.symbol.name, 'big');
      expect(result.last.symbol.name, 'small');
    });

    test('enclosingSymbol picks the innermost span', () {
      final spans = [
        span('AuthService', 1, 200, kind: 'class'),
        span('refresh', 5, 20),
      ];
      expect(mapper.enclosingSymbol(10, spans)?.name, 'refresh');
      expect(mapper.enclosingSymbol(150, spans)?.name, 'AuthService');
      expect(mapper.enclosingSymbol(500, spans), isNull);
    });
  });

  group('CohortInsights', () {
    test('round-trips through JSON', () {
      final insights = CohortInsights(
        changedSymbols: [
          ChangedSymbol(symbol: span('refresh', 5, 20), addedLines: 3),
        ],
        coveringTests: const ['test/auth_test.dart'],
        symbolSource: SymbolSource.head,
        testCoverageKnown: true,
      );
      final restored = CohortInsights.fromJson(insights.toJson());
      expect(restored, insights);
      expect(restored.coveringTestCount, 1);
    });

    test('degrades to empty on a malformed blob rather than throwing', () {
      final restored = CohortInsights.fromJson({
        'changedSymbols': [
          {'symbol': 'not-a-map'},
          {'nope': 1},
        ],
      });
      expect(restored.changedSymbols, isEmpty);
      expect(restored.symbolSource, SymbolSource.none);
    });

    test('unknown coverage reports null, not zero', () {
      const unknown = CohortInsights(symbolSource: SymbolSource.head);
      expect(unknown.coveringTestCount, isNull);

      const knownZero = CohortInsights(
        symbolSource: SymbolSource.head,
        testCoverageKnown: true,
      );
      expect(knownZero.coveringTestCount, 0);
    });

    test('an absent blob is empty', () {
      expect(CohortInsights.fromJson(null).isEmpty, isTrue);
      expect(CohortInsights.fromJson(const {}).isEmpty, isTrue);
    });
  });
}
