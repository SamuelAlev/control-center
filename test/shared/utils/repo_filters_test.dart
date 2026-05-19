import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:control_center/shared/utils/repo_filters.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Repo _repo({
  String id = '1',
  String owner = 'acme',
  String repoName = 'project',
}) {
  return Repo(
    id: id,
    name: '$owner/$repoName',
    path: '/repos/$owner/$repoName',
    remoteOwner: owner,
    remoteName: repoName,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

Repo _localRepo({String id = 'local'}) {
  return Repo(
    id: id,
    name: '/tmp/local-repo',
    path: '/tmp/local-repo',
    remoteOwner: '',
    remoteName: '',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('forgeLinkedReposOf', () {
    test('returns repos with GitHub remote from loaded AsyncValue', () {
      final repos = [_repo(owner: 'acme', repoName: 'app')];
      final result = forgeLinkedReposOf(AsyncData(repos));

      expect(result.length, 1);
      expect(result.first.remoteOwner, 'acme');
    });

    test('filters out repos without GitHub remote', () {
      final repos = [
        _repo(id: '1', owner: 'acme', repoName: 'app'),
        _localRepo(id: '2'),
        _repo(id: '3', owner: 'other', repoName: 'lib'),
      ];
      final result = forgeLinkedReposOf(AsyncData(repos));

      expect(result.length, 2);
      expect(result[0].id, '1');
      expect(result[1].id, '3');
    });

    test('returns empty list when AsyncValue is loading', () {
      final result = forgeLinkedReposOf(
        const AsyncValue<List<Repo>>.loading(),
      );

      expect(result, isEmpty);
    });

    test('returns empty list when AsyncValue has error', () {
      final result = forgeLinkedReposOf(
        AsyncValue<List<Repo>>.error(Exception('Failed'), StackTrace.empty),
      );

      expect(result, isEmpty);
    });

    test('returns empty list when all repos are local', () {
      final repos = [_localRepo(), _localRepo(id: '2')];
      final result = forgeLinkedReposOf(AsyncData(repos));

      expect(result, isEmpty);
    });

    test('returns growable=false list', () {
      final repos = [_repo()];
      final result = forgeLinkedReposOf(AsyncData(repos));

      expect(() => result.add(_repo()), throwsUnsupportedError);
    });
  });
}
