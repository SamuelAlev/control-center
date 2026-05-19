import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/pr_generation.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [PrLifecycleRepository] fake: keyed by workspace, no RPC needed.
class _FakePrLifecycleRepository implements PrLifecycleRepository {
  final Map<String, List<PrGeneration>> _byWorkspace = {};
  final _controllers = <String, StreamController<List<PrGeneration>>>{};

  void seed(String workspaceId, List<PrGeneration> prs) {
    _byWorkspace[workspaceId] = prs;
    _controllers[workspaceId]?.add(prs);
  }

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) {
    _controllers.putIfAbsent(
      workspaceId,
      () => StreamController<List<PrGeneration>>.broadcast(onListen: () {}),
    );
    Future.microtask(
      () =>
          _controllers[workspaceId]?.add(_byWorkspace[workspaceId] ?? const []),
    );
    return _controllers[workspaceId]!.stream;
  }

  /// Closes every spawned controller so no sink is left open at tear-down.
  void dispose() {
    for (final c in _controllers.values) {
      c.close();
    }
    _controllers.clear();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}

PrGeneration _pr({
  required String id,
  required String workspaceId,
  String? title,
}) {
  final now = DateTime(2024);
  return PrGeneration(
    id: id,
    workspaceId: workspaceId,
    status: const Draft(),
    title: title,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('pullRequestsProvider', () {
    late _FakePrLifecycleRepository repo;

    setUp(() {
      repo = _FakePrLifecycleRepository();
      addTearDown(repo.dispose);
    });

    test('returns empty list when no PRs exist', () async {
      final container = ProviderContainer(
        overrides: [prLifecycleRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(pullRequestsProvider('ws-empty'), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final prs = container.read(pullRequestsProvider('ws-empty')).value;
      expect(prs, isEmpty);
    });

    test('returns pull requests for a workspace', () async {
      const wsId = 'ws-pr';
      repo.seed(wsId, [
        _pr(id: 'pr-1', workspaceId: wsId, title: 'Add feature'),
      ]);

      final container = ProviderContainer(
        overrides: [prLifecycleRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(pullRequestsProvider(wsId), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final prs = container.read(pullRequestsProvider(wsId)).value;
      expect(prs?.length, 1);
      expect(prs?.first.id, 'pr-1');
    });

    test('returns only PRs for the specified workspace', () async {
      const wsId1 = 'ws-pr-1';
      const wsId2 = 'ws-pr-2';
      repo.seed(wsId1, [_pr(id: 'pr-a', workspaceId: wsId1, title: 'PR A')]);
      repo.seed(wsId2, [_pr(id: 'pr-b', workspaceId: wsId2, title: 'PR B')]);

      final container = ProviderContainer(
        overrides: [prLifecycleRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container.listen(pullRequestsProvider(wsId1), (_, _) {});
      container.listen(pullRequestsProvider(wsId2), (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final p1 = container.read(pullRequestsProvider(wsId1)).value;
      final p2 = container.read(pullRequestsProvider(wsId2)).value;
      expect(p1?.length, 1);
      expect(p1?.first.title, 'PR A');
      expect(p2?.length, 1);
      expect(p2?.first.title, 'PR B');
    });
  });
}
