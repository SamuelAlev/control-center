import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final testRepo = Repo(
  id: 'repo-1',
  name: 'my-repo',
  path: '/path/to/repo',
  githubOwner: 'owner',
  githubRepoName: 'my-repo',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('reposProvider', () {
    test('emits repos list', () async {
      final container = ProviderContainer(
        overrides: [
          reposProvider.overrideWith(
            (ref) => Stream.value([testRepo]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(reposProvider, (prev, next) {
        values.add(next);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, hasLength(1));
      expect(values.last.value!.first.id, 'repo-1');
    });

    test('emits empty list', () async {
      final container = ProviderContainer(
        overrides: [
          reposProvider.overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(reposProvider, (prev, next) {
        values.add(next);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, isEmpty);
    });

    test('emits multiple repos', () async {
      final repo2 = Repo(
        id: 'repo-2',
        name: 'other-repo',
        path: '/path/other',
        githubOwner: 'owner',
        githubRepoName: 'other-repo',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          reposProvider.overrideWith(
            (ref) => Stream.value([testRepo, repo2]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(reposProvider, (prev, next) {
        values.add(next);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, hasLength(2));
    });
  });

  group('reposForWorkspaceProvider', () {
    test('emits repos for workspace', () async {
      final container = ProviderContainer(
        overrides: [
          reposForWorkspaceProvider('ws-1').overrideWith(
            (ref) => Stream.value([testRepo]),
          ),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(
        reposForWorkspaceProvider('ws-1'),
        (prev, next) {
          values.add(next);
        },
      );
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, hasLength(1));
      expect(values.last.value!.first.id, 'repo-1');
    });

    test('emits empty when no repos', () async {
      final container = ProviderContainer(
        overrides: [
          reposForWorkspaceProvider('ws-2').overrideWith(
            (ref) => Stream.value(const []),
          ),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(
        reposForWorkspaceProvider('ws-2'),
        (prev, next) {
          values.add(next);
        },
      );
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, isEmpty);
    });
  });
}
