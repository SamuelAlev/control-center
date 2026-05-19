import 'package:cc_persistence/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;
import '../../../helpers/test_database.dart';

/// Overrides for a DB-backed test of the agent UI providers.
///
/// `agentRepositoryProvider` / `agentRunLogRepositoryProvider` are RPC-flipped
/// (composition flip): without an override they would spin up the in-process
/// RPC host (and block on a request timeout against a disposed container). These
/// tests exercise the provider→repository→DB path, so point the flipped public
/// providers at their Dao-backed server-side counterparts, which read the test
/// DB directly.
List<Override> agentDbOverrides(AppDatabase db) => [
      databaseProvider.overrideWithValue(db),
      agentRepositoryProvider.overrideWith(
        (ref) => ref.watch(daoAgentRepositoryProvider),
      ),
      agentRunLogRepositoryProvider.overrideWith(
        (ref) => ref.watch(daoAgentRunLogRepositoryProvider),
      ),
    ];

void main() {
  group('agentsProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns empty list when no agents exist', () async {
      final container = ProviderContainer(
        overrides: agentDbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(agentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(agentsProvider).value;
      expect(agents, isEmpty);
    });

    test('returns all agents sorted by name', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'z',
          name: 'zephyr',
          title: 'Z',
          agentMdPath: '.kilo/z.md',
          skills: 'w',
          workspaceId: 'ws-test',
        ),
      );
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'a',
          name: 'alpha',
          title: 'A',
          agentMdPath: '.kilo/a.md',
          skills: 'a',
          workspaceId: 'ws-test',
        ),
      );

      final container = ProviderContainer(
        overrides: agentDbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(agentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(agentsProvider).value;
      expect(agents?.length, 2);
      expect(agents?[0].name, 'alpha');
      expect(agents?[1].name, 'zephyr');
    });

    test('returns agents with correct fields', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'r',
          name: 'reviewer',
          title: 'Code Reviewer',
          agentMdPath: '.kilo/r.md',
          skills: 'review',
          persona: const Value('pedantic'),
          workspaceId: 'ws-test',
        ),
      );

      final container = ProviderContainer(
        overrides: agentDbOverrides(db),
      );
      addTearDown(container.dispose);
      container.listen(agentsProvider, (_, _) {});
      await Future.delayed(const Duration(milliseconds: 50));
      final agents = container.read(agentsProvider).value;
      expect(agents?.length, 1);
      expect(agents?.first.name, 'reviewer');
      expect(agents?.first.persona, 'pedantic');
    });
  });

  group('agentDetailProvider', () {
    late AppDatabase db;

    setUp(() {
      db = createTestDatabase();
    });

    tearDown(() async {
      await db.close();
    });

    test('returns null when agent does not exist', () async {
      final container = ProviderContainer(
        overrides: agentDbOverrides(db),
      );
      addTearDown(container.dispose);
      final agent = await container.read(
        agentDetailProvider('nonexistent').future,
      );
      expect(agent, null);
    });

    test('returns agent by id', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'b',
          name: 'builder',
          title: 'Builder',
          agentMdPath: '.kilo/b.md',
          skills: 'build',
          workspaceId: 'ws-test',
        ),
      );

      final container = ProviderContainer(
        overrides: agentDbOverrides(db),
      );
      addTearDown(container.dispose);
      final agent = await container.read(agentDetailProvider('b').future);
      expect(agent, isNotNull);
      expect(agent!.name, 'builder');
    });

    test('returns correct agent when multiple exist', () async {
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'x',
          name: 'xray',
          title: 'X',
          agentMdPath: '.kilo/x.md',
          skills: 's',
          workspaceId: 'ws-test',
        ),
      );
      await db.agentDao.upsert(
        AgentsTableCompanion.insert(
          id: 'y',
          name: 'yankee',
          title: 'Y',
          agentMdPath: '.kilo/y.md',
          skills: 'p',
          workspaceId: 'ws-test',
        ),
      );

      final container = ProviderContainer(
        overrides: agentDbOverrides(db),
      );
      addTearDown(container.dispose);
      final agent = await container.read(agentDetailProvider('y').future);
      expect(agent!.name, 'yankee');
    });
  });
}
