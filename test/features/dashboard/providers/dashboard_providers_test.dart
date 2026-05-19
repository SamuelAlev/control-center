import 'package:cc_persistence/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/dashboard/providers/dashboard_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import '../../../helpers/test_database.dart';

/// `agentRepositoryProvider` + `workspaceRepositoryProvider` are RPC-flipped
/// (composition flip). The dashboard providers exercise the
/// provider→repository→DB path, so point the flipped providers at their
/// Dao-backed server-side counterparts (which read the test DB directly)
/// instead of spinning up the in-process RPC host.
List<Override> _dbOverrides(AppDatabase db) => [
      databaseProvider.overrideWithValue(db),
      agentRepositoryProvider.overrideWith(
        (ref) => ref.watch(daoAgentRepositoryProvider),
      ),
      workspaceRepositoryProvider.overrideWith(
        (ref) => ref.watch(daoWorkspaceRepositoryProvider),
      ),
    ];

void main() {
  group('dashboardStatusProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns zero counts when no workspaces exist', () async {
      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardStatusProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final status = container.read(dashboardStatusProvider).value;
      expect(status?.totalWorkspaces, 0);
    });

    test('aggregates workspace statuses correctly', () async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-1',
          name: 'A1',
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-2',
          name: 'I1',
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-3',
          name: 'E1',
        ),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-4',
          name: 'A2',
        ),
      );

      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardStatusProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final status = container.read(dashboardStatusProvider).value;
      expect(status?.totalWorkspaces, 4);
    });

    test('counts only known statuses', () async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(
          id: 'ws-u',
          name: 'U',
        ),
      );

      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardStatusProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final status = container.read(dashboardStatusProvider).value;
      expect(status?.totalWorkspaces, 1);
    });
  });

  group('dashboardWorkspacesProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty list when no workspaces', () async {
      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardWorkspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final workspaces = container.read(dashboardWorkspacesProvider).value;
      expect(workspaces, isEmpty);
    });

    test('returns all workspaces', () async {
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-1', name: 'W1'),
      );
      await db.workspaceDao.upsertWorkspace(
        WorkspacesTableCompanion.insert(id: 'ws-2', name: 'W2'),
      );

      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardWorkspacesProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final workspaces = container.read(dashboardWorkspacesProvider).value;
      expect(workspaces?.length, 2);
    });
  });

  group('dashboardAgentsProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty list when no agents', () async {
      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardAgentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(dashboardAgentsProvider).value;
      expect(agents, isEmpty);
    });

    test('returns all agents', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'a1',
          name: 'a1',
          title: 'A1',
          agentMdPath: '.kilo/a1.md',
          skills: 's1',
          workspaceId: 'ws-test',
        ),
      );
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'a2',
          name: 'a2',
          title: 'A2',
          agentMdPath: '.kilo/a2.md',
          skills: 's2',
          workspaceId: 'ws-test',
        ),
      );

      final container = ProviderContainer(
        overrides: _dbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(dashboardAgentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(dashboardAgentsProvider).value;
      expect(agents?.length, 2);
    });
  });
}
