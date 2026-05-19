import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:test/test.dart';

PullRequest _pr({required String repoFullName, int number = 33373}) =>
    PullRequest(
      id: number,
      number: number,
      title: 'A change',
      body: '',
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
      // The mappers set `id` to the PR number, which is unique only within its
      // repo. Equality on `id` alone made app-server#33373 equal
      // web-app#33373 — the entity-level form of the wrong-repo fetch.
      final appServer = _pr(repoFullName: 'Frontify/app-server');
      final webApp = _pr(repoFullName: 'Frontify/web-app');

      expect(appServer == webApp, isFalse);
      expect(appServer.hashCode == webApp.hashCode, isFalse);
    });

    test('the same number in the same repo IS the same PR', () {
      final a = _pr(repoFullName: 'Frontify/app-server');
      final b = _pr(repoFullName: 'Frontify/app-server');

      expect(a == b, isTrue);
      expect(a.hashCode == b.hashCode, isTrue);
    });

    test('a Set keyed by identity keeps both same-numbered PRs', () {
      final set = {
        _pr(repoFullName: 'Frontify/app-server'),
        _pr(repoFullName: 'Frontify/web-app'),
      };
      expect(set.length, 2);
    });
  });
}
