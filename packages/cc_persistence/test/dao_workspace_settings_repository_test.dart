import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Exercises the workspace-scoped settings store.
///
/// The properties that matter here are not "does a value round-trip" but the
/// two the database split exists to guarantee: one workspace never sees
/// another's settings and the repository resolves its DAO per call rather than
/// pinning the first workspace it saw.
void main() {
  late WorkspaceDatabaseManager workspaces;
  late DaoWorkspaceSettingsRepository repo;

  setUp(() {
    workspaces = createTestWorkspaceDatabases();
    repo = DaoWorkspaceSettingsRepository(workspaces);
  });

  tearDown(() => workspaces.closeAll());

  test('set + get round-trips a value', () async {
    await repo.set('ws-1', 'branch_template', '{type}/{slug}');
    expect(await repo.get('ws-1', 'branch_template'), '{type}/{slug}');
  });

  test('get returns null for an unknown key', () async {
    expect(await repo.get('ws-1', 'missing'), isNull);
  });

  test('set with null deletes the value', () async {
    await repo.set('ws-1', 'branch_template', 'x');
    await repo.set('ws-1', 'branch_template', null);
    expect(await repo.get('ws-1', 'branch_template'), isNull);
  });

  test('getAll returns every key for the workspace', () async {
    await repo.set('ws-1', 'a', '1');
    await repo.set('ws-1', 'b', '2');
    expect(await repo.getAll('ws-1'), {'a': '1', 'b': '2'});
  });

  test('watchAll emits the live settings map', () async {
    await repo.set('ws-1', 'a', '1');
    expect(await repo.watchAll('ws-1').first, {'a': '1'});
  });

  group('workspace isolation', () {
    test('a value written to one workspace is invisible in another', () async {
      await repo.set('ws-1', 'branch_template', 'one');
      await repo.set('ws-2', 'branch_template', 'two');

      expect(await repo.get('ws-1', 'branch_template'), 'one');
      expect(await repo.get('ws-2', 'branch_template'), 'two');
      expect(await repo.getAll('ws-1'), {'branch_template': 'one'});
    });

    test(
      'a workspace with no settings reads empty, not the neighbour\'s',
      () async {
        await repo.set('ws-1', 'branch_template', 'one');
        expect(await repo.getAll('ws-2'), isEmpty);
      },
    );

    test(
      'the repository does not pin the first workspace it resolved',
      () async {
        // The leak the split makes impossible and the one a cached DAO field
        // would reintroduce: read ws-1 first, then write ws-2 and read it back.
        await repo.getAll('ws-1');
        await repo.set('ws-2', 'k', 'v');
        expect(await repo.get('ws-2', 'k'), 'v');
        expect(await repo.get('ws-1', 'k'), isNull);
      },
    );
  });

  group('quotas', () {
    test('accepts a value at the byte limit', () async {
      final atLimit = 'x' * DaoWorkspaceSettingsRepository.maxValueBytes;
      await repo.set('ws-1', 'big', atLimit);
      expect(await repo.get('ws-1', 'big'), atLimit);
    });

    test('rejects a value over the byte limit', () async {
      final tooBig = 'x' * (DaoWorkspaceSettingsRepository.maxValueBytes + 1);
      await expectLater(
        repo.set('ws-1', 'big', tooBig),
        throwsA(isA<ValidationException>()),
      );
      expect(await repo.get('ws-1', 'big'), isNull);
    });

    test('measures the limit in UTF-8 bytes, not code units', () async {
      final overInBytes =
          'é' * (DaoWorkspaceSettingsRepository.maxValueBytes ~/ 2 + 1);
      expect(
        overInBytes.length,
        lessThan(DaoWorkspaceSettingsRepository.maxValueBytes),
      );
      await expectLater(
        repo.set('ws-1', 'accents', overInBytes),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects an empty key', () async {
      await expectLater(
        repo.set('ws-1', '', 'v'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects a new key once the per-workspace cap is reached', () async {
      for (
        var i = 0;
        i < DaoWorkspaceSettingsRepository.maxKeysPerWorkspace;
        i++
      ) {
        await repo.set('ws-1', 'k$i', 'v');
      }
      await expectLater(
        repo.set('ws-1', 'one-too-many', 'v'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('an at-quota workspace can still edit and delete', () async {
      for (
        var i = 0;
        i < DaoWorkspaceSettingsRepository.maxKeysPerWorkspace;
        i++
      ) {
        await repo.set('ws-1', 'k$i', 'v');
      }
      await repo.set('ws-1', 'k0', 'updated');
      expect(await repo.get('ws-1', 'k0'), 'updated');
      await repo.set('ws-1', 'k0', null);
      await repo.set('ws-1', 'fresh', 'v');
      expect(await repo.get('ws-1', 'fresh'), 'v');
    });

    test('the key cap is per workspace, not global', () async {
      for (
        var i = 0;
        i < DaoWorkspaceSettingsRepository.maxKeysPerWorkspace;
        i++
      ) {
        await repo.set('ws-1', 'k$i', 'v');
      }
      await repo.set('ws-2', 'mine', 'v');
      expect(await repo.get('ws-2', 'mine'), 'v');
    });
  });
}
