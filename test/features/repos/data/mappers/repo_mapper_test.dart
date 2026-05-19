import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/features/repos/data/mappers/repo_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = RepoMapper();

  group('RepoMapper', () {
    test('creates const instance', timeout: const Timeout.factor(2), () {
      expect(mapper, isNotNull);
    });

    test('toDomain maps all fields correctly', timeout: const Timeout.factor(2), () {
      final row = ReposTableData(
        id: 'r1',
        name: 'acme/project',
        path: '/path/to/repo',
        githubOwner: 'acme',
        githubRepoName: 'project',
        createdAt: DateTime(2026, 1, 15),
        updatedAt: DateTime(2026, 3, 20),
      );

      final domain = mapper.toDomain(row);

      expect(domain.id, 'r1');
      expect(domain.name, 'acme/project');
      expect(domain.path, '/path/to/repo');
      expect(domain.githubOwner, 'acme');
      expect(domain.githubRepoName, 'project');
      expect(domain.createdAt, DateTime(2026, 1, 15));
      expect(domain.updatedAt, DateTime(2026, 3, 20));
    });

    test(
      'toDomain maps repo with empty github fields',
      timeout: const Timeout.factor(2),
      () {
        final row = ReposTableData(
          id: 'r2',
          name: 'local-only',
          path: '/local/repo',
          githubOwner: '',
          githubRepoName: '',
          createdAt: DateTime(2025, 6, 1),
          updatedAt: DateTime(2025, 6, 2),
        );

        final domain = mapper.toDomain(row);

        expect(domain.githubOwner, '');
        expect(domain.githubRepoName, '');
        expect(domain.hasGitHubRemote, isFalse);
      },
    );

    test('toDomainList converts empty list', timeout: const Timeout.factor(2), () {
      final result = mapper.toDomainList(const []);
      expect(result, isEmpty);
    });

    test('toDomainList maps multiple items', timeout: const Timeout.factor(2), () {
      final rows = [
        ReposTableData(
          id: 'r1',
          name: 'a/b',
          path: '/a',
          githubOwner: 'a',
          githubRepoName: 'b',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        ReposTableData(
          id: 'r2',
          name: 'c/d',
          path: '/c',
          githubOwner: 'c',
          githubRepoName: 'd',
          createdAt: DateTime(2026, 2, 1),
          updatedAt: DateTime(2026, 2, 1),
        ),
      ];

      final result = mapper.toDomainList(rows);

      expect(result.length, 2);
      expect(result[0].id, 'r1');
      expect(result[1].id, 'r2');
    });

    test(
      'toDomainList returns growable=false list',
      timeout: const Timeout.factor(2),
      () {
        final rows = [
          ReposTableData(
            id: 'r1',
            name: 'a/b',
            path: '/a',
            githubOwner: 'a',
            githubRepoName: 'b',
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
