import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/classify_ship_show_ask_use_case.dart';
import 'package:test/test.dart';

PullRequest _pr({
  required int number,
  bool isDraft = false,
  PrState state = PrState.open,
}) =>
    PullRequest(
      id: number,
      number: number,
      title: 'Test PR',
      body: '',
      state: state,
      isDraft: isDraft,
      author: null,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      repoFullName: 'test/repo',
      htmlUrl: 'https://example.com',
    );

PrFile _file({
  required String filename,
  int additions = 0,
  int deletions = 0,
}) =>
    PrFile(
      filename: filename,
      status: PrFileStatus.modified,
      additions: additions,
      deletions: deletions,
      patch: '',
    );

CheckRun _check({
  required String name,
  CheckRunStatus status = CheckRunStatus.completed,
  CheckRunConclusion? conclusion,
}) =>
    CheckRun(name: name, status: status, conclusion: conclusion);

void main() {
  const useCase = ClassifyShipShowAskUseCase();

  group('ClassifyShipShowAskUseCase', () {
    group('ask lane', () {
      test('draft PR', () {
        final result = useCase.classify(
          pr: _pr(number: 1, isDraft: true),
          files: [_file(filename: 'src/app.dart', additions: 5)],
          checks: [
            _check(
              name: 'ci',
              conclusion: CheckRunConclusion.success,
            ),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('CI failing', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/app.dart', additions: 5)],
          checks: [
            _check(
              name: 'ci',
              conclusion: CheckRunConclusion.failure,
            ),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — auth', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/auth/login.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — security', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'lib/security/firewall.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — payment', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/payment/checkout.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — billing', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/billing/invoice.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — migration', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'migrations/001_add_users.sql', additions: 5),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — schema', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'db/schema.rb', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — database', () => () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'src/database/connection.dart', additions: 5),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — /core/', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/core/config.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — /api/', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/api/routes.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('critical path — /shared/', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/shared/utils.dart', additions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('large change — >100 LOC', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/app.dart', additions: 60, deletions: 41)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });

      test('large change — >5 files', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'src/a.dart', additions: 1),
            _file(filename: 'src/b.dart', additions: 1),
            _file(filename: 'src/c.dart', additions: 1),
            _file(filename: 'src/d.dart', additions: 1),
            _file(filename: 'src/e.dart', additions: 1),
            _file(filename: 'src/f.dart', additions: 1),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ask);
        expect(result.reason, isNotEmpty);
      });
    });

    group('ship lane', () {
      test('doc-only changes', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'README.md', additions: 10),
            _file(filename: 'docs/guide.rst', additions: 5),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ship);
        expect(result.reason, isNotEmpty);
      });

      test('test-only changes', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'test/foo_test.dart', additions: 30),
            _file(filename: 'spec/bar_spec.dart', additions: 20),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ship);
        expect(result.reason, isNotEmpty);
      });

      test('small change — ≤20 LOC, ≤2 files with passing CI', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/app.dart', additions: 10, deletions: 5)],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ship);
        expect(result.reason, isNotEmpty);
      });

      test('small change — single file, exact 20 LOC', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'src/app.dart', additions: 10, deletions: 10),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.ship);
        expect(result.reason, isNotEmpty);
      });
    });

    group('show lane', () {
      test('moderate change — 21-100 LOC', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'src/app.dart', additions: 30, deletions: 5),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.show);
        expect(result.reason, isNotEmpty);
      });

      test('moderate change — 3-5 files', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'src/a.dart', additions: 1),
            _file(filename: 'src/b.dart', additions: 1),
            _file(filename: 'src/c.dart', additions: 1),
            _file(filename: 'src/d.dart', additions: 1),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        expect(result.lane, ShipShowAskLane.show);
        expect(result.reason, isNotEmpty);
      });
    });

    group('edge cases', () {
      test('no checks means CI passes', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/app.dart', additions: 5)],
          checks: [],
        );

        expect(result.lane, ShipShowAskLane.ship);
        expect(result.reason, isNotEmpty);
      });

      test('mixed doc+code files → not doc-only', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'README.md', additions: 15),
            _file(filename: 'src/app.dart', additions: 15),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        // Not doc-only, but also >20 LOC, so falls to show lane (not ship)
        expect(result.lane, ShipShowAskLane.show);
        expect(result.reason, isNotEmpty);
      });

      test('mixed test+code files → not test-only', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'test/foo_test.dart', additions: 15),
            _file(filename: 'src/app.dart', additions: 15),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        // Not test-only, but also >20 LOC, falls to show lane
        expect(result.lane, ShipShowAskLane.show);
        expect(result.reason, isNotEmpty);
      });

      test('single file with additions+deletions counts correctly', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [
            _file(filename: 'src/app.dart', additions: 30, deletions: 30),
          ],
          checks: [
            _check(name: 'ci', conclusion: CheckRunConclusion.success),
          ],
        );

        // 30+30 = 60 LOC → show lane (21-100)
        expect(result.lane, ShipShowAskLane.show);
        expect(result.reason, isNotEmpty);
      });

      test('in-progress CI → treat as passing', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/app.dart', additions: 5)],
          checks: [
            _check(name: 'ci', status: CheckRunStatus.inProgress),
          ],
        );

        // In-progress checks are not "completed", so _allCiPassing returns
        // true (no completed checks → CI is passing).
        expect(result.lane, ShipShowAskLane.ship);
      });

      test('queued CI → treat as passing', () {
        final result = useCase.classify(
          pr: _pr(number: 1),
          files: [_file(filename: 'src/app.dart', additions: 5)],
          checks: [
            _check(name: 'ci', status: CheckRunStatus.queued),
          ],
        );

        expect(result.lane, ShipShowAskLane.ship);
      });
    });
  });
}
