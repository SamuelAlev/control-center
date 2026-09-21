import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_view.dart';
import 'package:flutter_test/flutter_test.dart';

Repo _repo(String id, String owner, String name) => Repo(
  id: id,
  name: '$owner/$name',
  path: '/repos/$owner/$name',
  remoteOwner: owner,
  remoteName: name,
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  final repos = [_repo('rA', 'acme', 'alpha'), _repo('rB', 'acme', 'beta')];

  test('empty list yields null', () {
    expect(
      prListSelectedRepoId(repos: const [], repoFullName: 'acme/alpha'),
      isNull,
    );
  });

  test('empty query selects the first repo', () {
    expect(prListSelectedRepoId(repos: repos, repoFullName: null), 'rA');
    expect(prListSelectedRepoId(repos: repos, repoFullName: ''), 'rA');
    expect(prListSelectedRepoId(repos: repos, repoFullName: '  '), 'rA');
  });

  test('matches owner/repo case-insensitively', () {
    expect(prListSelectedRepoId(repos: repos, repoFullName: 'acme/beta'), 'rB');
    expect(prListSelectedRepoId(repos: repos, repoFullName: 'Acme/Beta'), 'rB');
  });

  test('unknown query falls back to the first repo', () {
    expect(
      prListSelectedRepoId(repos: repos, repoFullName: 'other/gone'),
      'rA',
    );
  });
}
