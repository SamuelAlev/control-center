import 'package:cc_infra/src/skills/active_repo_tracker.dart';
import 'package:test/test.dart';

void main() {
  const reposDir = '/data/ws/spaces/sp1/repos';
  const known = {'web-app', 'api', 'web-app-legacy'};

  ActiveRepoTracker tracker() =>
      ActiveRepoTracker(reposDir: reposDir, knownRepos: known);

  group('write-class touches switch the active repo', () {
    test('absolute path under the repos dir', () {
      final t = tracker();
      expect(
        t.observe('edit', {'file_path': '$reposDir/web-app/src/x.ts'}),
        'web-app',
      );
      expect(t.active, 'web-app');
    });

    test('relative path through the overlay symlink', () {
      final t = tracker();
      expect(t.observe('write', {'path': 'repos/api/lib/main.dart'}), 'api');
    });

    test('absolute path that does not share the repos-dir prefix', () {
      // One side has been through a symlink, so only the `repos/` segment
      // matches — this is the /var vs /private/var case on macOS.
      final t = tracker();
      expect(
        t.observe('Edit', {'file_path': '/private/data/x/repos/api/go.mod'}),
        'api',
      );
    });

    test('a later write in another repo switches again', () {
      final t = tracker()..observe('write', {'path': 'repos/web-app/a.ts'});
      expect(t.observe('write', {'path': 'repos/api/b.dart'}), 'api');
      expect(t.active, 'api');
    });

    test('re-touching the same repo reports no change', () {
      final t = tracker()..observe('write', {'path': 'repos/api/b.dart'});
      expect(t.observe('edit', {'file_path': 'repos/api/c.dart'}), isNull);
      expect(t.active, 'api');
    });

    test('bash cwd', () {
      final t = tracker();
      expect(t.observe('bash', {'cwd': '$reposDir/web-app'}), 'web-app');
    });

    test('bash command text, for adapters whose shell takes no cwd', () {
      // Claude Code's Bash has no cwd parameter; the agent writes `cd …`.
      final t = tracker();
      expect(
        t.observe('Bash', {'command': 'cd repos/api && dart test'}),
        'api',
      );
    });
  });

  group('read-class touches only seed', () {
    test('a read seeds when nothing is active', () {
      final t = tracker();
      expect(
        t.observe('read', {'file_path': 'repos/web-app/README.md'}),
        'web-app',
      );
    });

    test('a read never switches away from an active repo', () {
      final t = tracker()..observe('write', {'path': 'repos/api/b.dart'});
      expect(
        t.observe('read', {'file_path': 'repos/web-app/src/x.ts'}),
        isNull,
      );
      expect(t.active, 'api', reason: 'a cross-repo glance must not thrash');
    });

    test('a read command string is not scanned', () {
      final t = tracker();
      expect(t.observe('grep', {'command': 'rg repos/api'}), isNull);
    });
  });

  group('inert inputs', () {
    test('paths outside repos/ never clear the active repo', () {
      final t = tracker()..observe('write', {'path': 'repos/api/b.dart'});
      expect(t.observe('write', {'path': 'notes.md'}), isNull);
      expect(t.observe('write', {'file_path': '/tmp/scratch'}), isNull);
      expect(t.active, 'api');
    });

    test('an unknown slug is ignored', () {
      final t = tracker();
      expect(t.observe('write', {'path': 'repos/not-a-repo/x'}), isNull);
      expect(t.active, isNull);
    });

    test('traversal cannot name a repo', () {
      final t = tracker();
      expect(t.observe('write', {'path': 'repos/../../etc/passwd'}), isNull);
      expect(t.active, isNull);
    });

    test('a directory merely ending in "repos" does not match', () {
      final t = tracker();
      expect(t.observe('write', {'path': 'backup-repos/api/x'}), isNull);
      expect(t.observe('write', {'path': 'myrepos/api/x'}), isNull);
      expect(t.active, isNull);
    });

    test('a longer repo name is not truncated to a shorter one', () {
      final t = tracker();
      expect(
        t.observe('write', {'path': 'repos/web-app-legacy/x.ts'}),
        'web-app-legacy',
      );
    });

    test('non-file tools are ignored', () {
      final t = tracker();
      expect(t.observe('task', {'prompt': 'work in repos/api'}), isNull);
      expect(t.observe('todo_write', {'todos': <String>[]}), isNull);
      expect(t.active, isNull);
    });
  });

  group('seed', () {
    test('scopes a single-repo space before the first turn', () {
      final t = tracker();
      expect(t.seed('api'), isTrue);
      expect(t.active, 'api');
      expect(t.seed('api'), isFalse, reason: 'idempotent');
    });

    test('refuses an unknown slug', () {
      final t = tracker();
      expect(t.seed('nope'), isFalse);
      expect(t.active, isNull);
    });

    test('a seeded repo still yields to a write elsewhere', () {
      final t = tracker()..seed('api');
      expect(t.observe('edit', {'file_path': 'repos/web-app/x.ts'}), 'web-app');
    });
  });

  test('an empty knownRepos accepts any plausible slug', () {
    final t = ActiveRepoTracker(reposDir: reposDir);
    expect(t.observe('write', {'path': 'repos/anything/x'}), 'anything');
  });

  test('windows-style separators normalize', () {
    final t = tracker();
    expect(t.observe('write', {'path': r'repos\api\lib\main.dart'}), 'api');
  });
}
