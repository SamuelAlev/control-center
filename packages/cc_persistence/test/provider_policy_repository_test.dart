import 'package:cc_domain/features/model_routing/model_routing.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoProviderPolicyRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws-a');
    await seedTestWorkspace(global, dbs, 'ws-b');
    repo = DaoProviderPolicyRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  test('persists and reads back a statement', () async {
    await repo.upsert(
      'ws-a',
      'p1',
      const PolicyStatement.denyProvider('openai'),
    );
    final policies = await repo.listForWorkspace('ws-a');
    expect(policies, hasLength(1));
    expect(policies.single.statement.resource, 'openai');
    expect(policies.single.statement.effect, PolicyEffect.deny);
  });

  test('engineFor denies a provider per the stored policy', () async {
    await repo.upsert(
      'ws-a',
      'p1',
      const PolicyStatement.denyProvider('openai'),
    );
    final engine = await repo.engineFor('ws-a');
    expect(engine.allowsProvider('openai'), isFalse);
    expect(engine.allowsProvider('anthropic'), isTrue);
  });

  group('workspace isolation', () {
    test('one workspace never sees another workspace policy', () async {
      await repo.upsert(
        'ws-a',
        'p1',
        const PolicyStatement.denyProvider('openai'),
      );
      expect(await repo.listForWorkspace('ws-b'), isEmpty);
      final engineB = await repo.engineFor('ws-b');
      // ws-b has no deny → openai stays allowed.
      expect(engineB.allowsProvider('openai'), isTrue);
    });

    test('delete is scoped — cannot delete another workspace policy', () async {
      await repo.upsert(
        'ws-a',
        'p1',
        const PolicyStatement.denyProvider('openai'),
      );
      // Attempt to delete ws-a's 'p1' while scoped to ws-b: no-op.
      await repo.delete('ws-b', 'p1');
      expect(await repo.listForWorkspace('ws-a'), hasLength(1));
      // Correct scope deletes it.
      await repo.delete('ws-a', 'p1');
      expect(await repo.listForWorkspace('ws-a'), isEmpty);
    });
  });
}
