import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:control_center/features/repos/presentation/widgets/add_repo_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('registerReposFromPaths', () {
    test('registers every picked folder in pick order', () async {
      final calls = <String>[];
      final outcome = await registerReposFromPaths(
        (workspaceId, path) async {
          calls.add('$workspaceId:$path');
          return (repoId: 'id-$path', issues: const <RepoAccessIssue>[]);
        },
        'ws-1',
        ['/a', '/b', '/c'],
      );

      expect(calls, ['ws-1:/a', 'ws-1:/b', 'ws-1:/c']);
      expect(outcome.added, ['id-/a', 'id-/b', 'id-/c']);
      expect(outcome.failed, isEmpty);
    });

    test('continues past failures and reports them per path', () async {
      final outcome = await registerReposFromPaths(
        (workspaceId, path) async {
          if (path == '/not-a-repo') {
            throw Exception('not a git checkout');
          }
          return (repoId: 'id-$path', issues: const <RepoAccessIssue>[]);
        },
        'ws-1',
        ['/ok-1', '/not-a-repo', '/ok-2'],
      );

      expect(outcome.added, ['id-/ok-1', 'id-/ok-2']);
      expect(outcome.failed.keys, ['/not-a-repo']);
      expect(
        outcome.failed['/not-a-repo'].toString(),
        contains('not a git checkout'),
      );
    });

    test('an empty pick list registers nothing', () async {
      var called = false;
      final outcome = await registerReposFromPaths(
        (workspaceId, path) async {
          called = true;
          return (repoId: 'id', issues: const <RepoAccessIssue>[]);
        },
        'ws-1',
        const [],
      );

      expect(called, isFalse);
      expect(outcome.added, isEmpty);
      expect(outcome.failed, isEmpty);
    });

    test('collects what automation cannot reach in the added repos', () async {
      final outcome = await registerReposFromPaths(
        (workspaceId, path) async => (
          repoId: 'id-$path',
          issues: [
            RepoAccessIssue(
              forge: ForgeHost.github,
              owner: 'acme',
              name: path.substring(1),
              state: RepoAccessState.appNotInstalled,
            ),
          ],
        ),
        'ws-1',
        ['/api', '/web'],
      );

      expect(outcome.issues.map((i) => i.repoFullName), [
        'acme/api',
        'acme/web',
      ]);
    });
  });
}
