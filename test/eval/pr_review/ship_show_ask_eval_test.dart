// Eval harness for the Ship / Show / Ask classifier.
//
// Each [_EvalCase] represents a labeled PR scenario. The harness
// reports recall and precision per lane and fails if overall accuracy drops
// below the baseline (75%). Add real historical PR cases here as they become
// available from the dogfood feedback loop.

import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_file.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/usecases/classify_ship_show_ask_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

const _baseline = 0.75;

class _EvalCase {
  const _EvalCase({
    required this.description,
    required this.pr,
    required this.files,
    required this.checks,
    required this.expectedLane,
  });

  final String description;
  final PullRequest pr;
  final List<PrFile> files;
  final List<CheckRun> checks;
  final ShipShowAskLane expectedLane;
}

// ── Factories ────────────────────────────────────────────────────────────────

PullRequest _pr({int number = 1, bool isDraft = false}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'PR $number',
    body: '',
    state: PrState.open,
    isDraft: isDraft,
    author: const PrUser(login: 'dev', avatarUrl: ''),
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
    repoFullName: 'SamuelAlev/foobar',
    htmlUrl: 'https://github.com/SamuelAlev/foobar/pull/$number',
    requestedReviewers: const [],
  );
}

PrFile _file(String path, {int add = 10, int del = 5}) => PrFile(
  filename: path,
  status: PrFileStatus.modified,
  additions: add,
  deletions: del,
  patch: '',
);

CheckRun _passing(String name) => CheckRun(
  name: name,
  status: CheckRunStatus.completed,
  conclusion: CheckRunConclusion.success,
);

CheckRun _failing(String name) => CheckRun(
  name: name,
  status: CheckRunStatus.completed,
  conclusion: CheckRunConclusion.failure,
);

// ── Labeled eval cases ───────────────────────────────────────────────────────

final _cases = <_EvalCase>[
  // ── Ship cases ───────────────────────────────────────────────────────────
  _EvalCase(
    description: 'Typo fix in README',
    pr: _pr(number: 1),
    files: [_file('README.md', add: 1, del: 1)],
    checks: [_passing('lint')],
    expectedLane: ShipShowAskLane.ship,
  ),
  _EvalCase(
    description: 'Add unit tests only',
    pr: _pr(number: 2),
    files: [_file('test/widgets/button_test.dart', add: 30, del: 0)],
    checks: [_passing('test')],
    expectedLane: ShipShowAskLane.ship,
  ),
  _EvalCase(
    description: 'Small CSS variable rename — 2 files, 15 LOC',
    pr: _pr(number: 3),
    files: [
      _file('src/styles/tokens.css', add: 8, del: 7),
      _file('src/styles/overrides.css', add: 0, del: 0),
    ],
    checks: [_passing('lint'), _passing('build')],
    expectedLane: ShipShowAskLane.ship,
  ),
  _EvalCase(
    description: 'Update CHANGELOG only',
    pr: _pr(number: 4),
    files: [_file('CHANGELOG.md', add: 10, del: 0)],
    checks: [],
    expectedLane: ShipShowAskLane.ship,
  ),
  _EvalCase(
    description: 'Update license year',
    pr: _pr(number: 5),
    files: [_file('LICENSE.txt', add: 1, del: 1)],
    checks: [_passing('lint')],
    expectedLane: ShipShowAskLane.ship,
  ),

  // ── Show cases ───────────────────────────────────────────────────────────
  _EvalCase(
    description: 'New UI component — 80 LOC, 4 files',
    pr: _pr(number: 6),
    files: [
      _file('src/components/Badge.tsx', add: 40, del: 0),
      _file('src/components/Badge.test.tsx', add: 25, del: 0),
      _file('src/components/index.ts', add: 2, del: 0),
      _file('stories/Badge.stories.tsx', add: 15, del: 0),
    ],
    checks: [_passing('build'), _passing('test')],
    expectedLane: ShipShowAskLane.show,
  ),
  _EvalCase(
    description: 'Refactor hooks — 60 LOC, 3 files',
    pr: _pr(number: 7),
    files: [
      _file('src/hooks/useTheme.ts', add: 25, del: 20),
      _file('src/hooks/useTheme.test.ts', add: 10, del: 5),
      _file('src/components/ThemeToggle.tsx', add: 5, del: 5),
    ],
    checks: [_passing('lint'), _passing('test')],
    expectedLane: ShipShowAskLane.show,
  ),
  _EvalCase(
    description: 'Add i18n strings — 5 files, 50 LOC',
    pr: _pr(number: 8),
    files: [
      _file('src/i18n/en.json', add: 20, del: 0),
      _file('src/i18n/de.json', add: 20, del: 0),
      _file('src/i18n/fr.json', add: 10, del: 0),
      _file('src/components/Header.tsx', add: 2, del: 2),
      _file('src/components/Footer.tsx', add: 1, del: 1),
    ],
    checks: [_passing('build')],
    expectedLane: ShipShowAskLane.show,
  ),
  _EvalCase(
    description: 'Bump non-critical dep — 3 files, 30 LOC',
    pr: _pr(number: 9),
    files: [
      _file('package.json', add: 2, del: 2),
      _file('package-lock.json', add: 20, del: 10),
      _file('src/lib/utils.ts', add: 3, del: 3),
    ],
    checks: [_passing('build'), _passing('test')],
    expectedLane: ShipShowAskLane.show,
  ),
  _EvalCase(
    description: 'Update feature flag defaults — 2 files, 35 LOC',
    pr: _pr(number: 10),
    files: [
      _file('src/config/flags.ts', add: 20, del: 15),
      _file('src/config/flags.test.ts', add: 15, del: 5),
    ],
    checks: [_passing('test')],
    expectedLane: ShipShowAskLane.show,
  ),

  // ── Ask cases ────────────────────────────────────────────────────────────
  _EvalCase(
    description: 'Draft PR',
    pr: _pr(number: 11, isDraft: true),
    files: [_file('src/components/Foo.tsx', add: 50, del: 0)],
    checks: [],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'CI failing',
    pr: _pr(number: 12),
    files: [_file('src/utils/format.ts', add: 10, del: 5)],
    checks: [_passing('lint'), _failing('test')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Touches auth module',
    pr: _pr(number: 13),
    files: [_file('src/auth/session.ts', add: 15, del: 5)],
    checks: [_passing('build')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Touches database migration',
    pr: _pr(number: 14),
    files: [_file('db/migration/0042_add_user_table.sql', add: 30, del: 0)],
    checks: [_passing('lint')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Large PR — 400 LOC',
    pr: _pr(number: 15),
    files: [
      _file('src/components/Dashboard.tsx', add: 200, del: 100),
      _file('src/components/Chart.tsx', add: 80, del: 20),
    ],
    checks: [_passing('build')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Many files — 8 files touched',
    pr: _pr(number: 16),
    files: List.generate(
      8,
      (i) => _file('src/components/Widget$i.tsx', add: 5, del: 2),
    ),
    checks: [_passing('test')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Payment flow touched',
    pr: _pr(number: 17),
    files: [_file('src/payment/checkout.ts', add: 20, del: 5)],
    checks: [_passing('lint')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Core API touched',
    pr: _pr(number: 18),
    files: [_file('src/core/api/client.ts', add: 10, del: 8)],
    checks: [_passing('build')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Security module modified',
    pr: _pr(number: 19),
    files: [_file('src/security/csrf.ts', add: 15, del: 10)],
    checks: [_passing('lint'), _passing('test')],
    expectedLane: ShipShowAskLane.ask,
  ),
  _EvalCase(
    description: 'Schema change',
    pr: _pr(number: 20),
    files: [_file('schema/user.graphql', add: 8, del: 2)],
    checks: [_passing('build')],
    expectedLane: ShipShowAskLane.ask,
  ),
];

// ── Harness ──────────────────────────────────────────────────────────────────

void main() {
  const useCase = ClassifyShipShowAskUseCase();

  group('Ship/Show/Ask eval harness', () {
    test('all labeled cases meet the baseline accuracy', () {
      final results = _cases.map((c) {
        final result = useCase.classify(
          pr: c.pr,
          files: c.files,
          checks: c.checks,
        );
        return (
          description: c.description,
          expected: c.expectedLane,
          actual: result.lane,
          correct: result.lane == c.expectedLane,
        );
      }).toList();

      final correct = results.where((r) => r.correct).length;
      final total = results.length;
      final accuracy = correct / total;

      // Report per-case failures for debugging.
      for (final r in results) {
        if (!r.correct) {
          // ignore: avoid_print
          print(
            'FAIL: "${r.description}" — expected ${r.expected.name}, '
            'got ${r.actual.name}',
          );
        }
      }

      // Report per-lane recall/precision.
      for (final lane in ShipShowAskLane.values) {
        final tp = results
            .where((r) => r.expected == lane && r.actual == lane)
            .length;
        final fp = results
            .where((r) => r.expected != lane && r.actual == lane)
            .length;
        final fn = results
            .where((r) => r.expected == lane && r.actual != lane)
            .length;
        final recall = tp == 0 ? 0.0 : tp / (tp + fn);
        final precision = (tp + fp) == 0 ? 0.0 : tp / (tp + fp);
        // ignore: avoid_print
        print(
          '${lane.name}: recall=${(recall * 100).round()}% '
          'precision=${(precision * 100).round()}% '
          '(tp=$tp fp=$fp fn=$fn)',
        );
      }

      // ignore: avoid_print
      print('Overall accuracy: ${(accuracy * 100).round()}% ($correct/$total)');

      expect(
        accuracy,
        greaterThanOrEqualTo(_baseline),
        reason:
            'Accuracy $accuracy is below baseline $_baseline. '
            'Check FAIL lines above.',
      );
    });

    for (final c in _cases) {
      test(c.description, () {
        final result = useCase.classify(
          pr: c.pr,
          files: c.files,
          checks: c.checks,
        );
        expect(result.lane, c.expectedLane, reason: result.reason);
      });
    }
  });
}
