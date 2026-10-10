import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:test/test.dart';

PullRequest _pr({
  required String repoFullName,
  int number = 33373,
  String body = '',
}) => PullRequest(
  id: number,
  number: number,
  title: 'A change',
  body: body,
  state: PrState.open,
  isDraft: false,
  author: null,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
  repoFullName: repoFullName,
  htmlUrl: 'https://github.com/$repoFullName/pull/$number',
);

void main() {
  group('PullRequest identity', () {
    test('the same number in two repos is NOT the same PR', () {
      // The mappers set `id` to the PR number, which is unique only within its repo.
      final repoA = _pr(repoFullName: 'controlcenter/repo-a');
      final repoB = _pr(repoFullName: 'controlcenter/repo-b');

      expect(repoA == repoB, isFalse);
      expect(repoA.hashCode == repoB.hashCode, isFalse);
    });

    test('the same number in the same repo IS the same PR', () {
      final a = _pr(repoFullName: 'controlcenter/repo-a');
      final b = _pr(repoFullName: 'controlcenter/repo-a');

      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
    });

    test('the same number in two repos is never isSamePr', () {
      final repoA = _pr(repoFullName: 'controlcenter/repo-a');
      final repoB = _pr(repoFullName: 'controlcenter/repo-b');

      expect(repoA.isSamePr(repoB), isFalse);
      expect(repoA.identityKey == repoB.identityKey, isFalse);
    });

    test('two snapshots of one PR are the same PR but not equal', () {
      final before = _pr(repoFullName: 'controlcenter/repo-a', body: 'old');
      final after = _pr(repoFullName: 'controlcenter/repo-a', body: 'new');

      expect(before == after, isFalse);
      expect(before.isSamePr(after), isTrue);
      expect(before.identityKey, after.identityKey);
    });

    test('a Set keyed by identity keeps both same-numbered PRs', () {
      final set = {
        _pr(repoFullName: 'controlcenter/repo-a'),
        _pr(repoFullName: 'controlcenter/repo-b'),
      };
      expect(set.length, 2);
    });
  });
}
