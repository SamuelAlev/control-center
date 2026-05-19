import 'package:cc_persistence/database/workspace/workspace_database.dart';
import 'package:cc_persistence/mappers/repo_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = RepoMapper();

  group('RepoMapper', () {
    test('creates const instance', timeout: const Timeout.factor(2), () {
      expect(mapper, isNotNull);
    });

    test(
      'toDomain maps all fields correctly',
      timeout: const Timeout.factor(2),
      () {
        final row = ReposTableData(
          id: 'r1',
          forge: 'github',
          name: 'acme/project',
          path: '/path/to/repo',
          remoteOwner: 'acme',
          remoteName: 'project',
          position: 0,
          linkedAt: DateTime(2026),
          createdAt: DateTime(2026, 1, 15),
          updatedAt: DateTime(2026, 3, 20),
        );

        final domain = mapper.toDomain(row);

        expect(domain.id, 'r1');
        expect(domain.name, 'acme/project');
        expect(domain.path, '/path/to/repo');
        expect(domain.remoteOwner, 'acme');
        expect(domain.remoteName, 'project');
        expect(domain.createdAt, DateTime(2026, 1, 15));
        expect(domain.updatedAt, DateTime(2026, 3, 20));
      },
    );

    test(
      'toDomain maps repo with empty github fields',
      timeout: const Timeout.factor(2),
      () {
        final row = ReposTableData(
          id: 'r2',
          forge: 'github',
          name: 'local-only',
          path: '/local/repo',
          remoteOwner: '',
          remoteName: '',
          position: 0,
          linkedAt: DateTime(2026),
          createdAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 6, 2),
        );

        final domain = mapper.toDomain(row);

        expect(domain.remoteOwner, '');
        expect(domain.remoteName, '');
        expect(domain.hasForgeRemote, isFalse);
      },
    );

    test(
      'toDomainList converts empty list',
      timeout: const Timeout.factor(2),
      () {
        final result = mapper.toDomainList(const []);
        expect(result, isEmpty);
      },
    );

    test(
      'toDomainList maps multiple items',
      timeout: const Timeout.factor(2),
      () {
        final rows = [
          ReposTableData(
            id: 'r1',
            forge: 'github',
            name: 'a/b',
            path: '/a',
            remoteOwner: 'a',
            remoteName: 'b',
            position: 0,
            linkedAt: DateTime(2026),
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
          ReposTableData(
            id: 'r2',
            forge: 'github',
            name: 'c/d',
            path: '/c',
            remoteOwner: 'c',
            remoteName: 'd',
            position: 0,
            linkedAt: DateTime(2026),
            createdAt: DateTime(2026, 2, 1),
            updatedAt: DateTime(2026, 2, 1),
          ),
        ];

        final result = mapper.toDomainList(rows);

        expect(result.length, 2);
        expect(result[0].id, 'r1');
        expect(result[1].id, 'r2');
      },
    );

    test(
      'toDomainList returns growable=false list',
      timeout: const Timeout.factor(2),
      () {
        final rows = [
          ReposTableData(
            id: 'r1',
            forge: 'github',
            name: 'a/b',
            path: '/a',
            remoteOwner: 'a',
            remoteName: 'b',
            position: 0,
            linkedAt: DateTime(2026),
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ),
        ];

        final result = mapper.toDomainList(rows);

        expect(
          () => result.add(result.first),
          throwsA(isA<UnsupportedError>()),
        );
      },
    );
  });
}
