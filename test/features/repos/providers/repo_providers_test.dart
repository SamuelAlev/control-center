import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final testRepo = Repo(
  id: 'repo-1',
  name: 'my-repo',
  path: '/path/to/repo',
  remoteOwner: 'owner',
  remoteName: 'my-repo',
  createdAt: DateTime(2024),
  updatedAt: DateTime(2024),
);

void main() {
  group('reposForWorkspaceProvider', () {
    test('emits repos for workspace', () async {
      final container = ProviderContainer(
        overrides: [
          reposForWorkspaceProvider(
            'ws-1',
          ).overrideWith((ref) => Stream.value([testRepo])),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(reposForWorkspaceProvider('ws-1'), (
        prev,
        next,
      ) {
        values.add(next);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, hasLength(1));
      expect(values.last.value!.first.id, 'repo-1');
    });

    test('emits every repo the workspace owns', () async {
      final repo2 = Repo(
        id: 'repo-2',
        name: 'other-repo',
        path: '/path/other',
        remoteOwner: 'owner',
        remoteName: 'other-repo',
        createdAt: DateTime(2024),
        updatedAt: DateTime(2024),
      );

      final container = ProviderContainer(
        overrides: [
          reposForWorkspaceProvider(
            'ws-1',
          ).overrideWith((ref) => Stream.value([testRepo, repo2])),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(reposForWorkspaceProvider('ws-1'), (
        prev,
        next,
      ) {
        values.add(next);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, hasLength(2));
    });

    test('emits empty when no repos', () async {
      final container = ProviderContainer(
        overrides: [
          reposForWorkspaceProvider(
            'ws-2',
          ).overrideWith((ref) => Stream.value(const [])),
        ],
      );
      addTearDown(container.dispose);

      final values = <AsyncValue<List<Repo>>>[];
      final sub = container.listen(reposForWorkspaceProvider('ws-2'), (
        prev,
        next,
      ) {
        values.add(next);
      });
      addTearDown(sub.close);

      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(values.isNotEmpty, isTrue);
      expect(values.last.value, isEmpty);
    });
  });
}
