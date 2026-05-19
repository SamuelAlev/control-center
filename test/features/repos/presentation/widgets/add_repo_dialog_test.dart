import 'package:control_center/features/repos/presentation/widgets/add_repo_dialog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('registerReposFromPaths', () {
    test('registers every picked folder in pick order', () async {
      final calls = <String>[];
      final outcome = await registerReposFromPaths(
        (workspaceId, path) async {
          calls.add('$workspaceId:$path');
          return 'id-$path';
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
          return 'id-$path';
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
          return 'id';
        },
        'ws-1',
        const [],
      );

      expect(called, isFalse);
      expect(outcome.added, isEmpty);
      expect(outcome.failed, isEmpty);
    });
  });
}
