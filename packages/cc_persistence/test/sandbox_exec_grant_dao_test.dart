import 'package:cc_domain/features/sandboxing/domain/entities/sandbox_exec_grant.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  SandboxExecGrant grant({
    required String id,
    String ws = 'ws1',
    required String path,
    SandboxExecGrantDecision decision = SandboxExecGrantDecision.allow,
    DateTime? at,
  }) => SandboxExecGrant(
    id: id,
    workspaceId: ws,
    path: path,
    decision: decision,
    createdAt: at ?? DateTime.utc(2026, 1, 1),
  );

  group('SandboxExecGrant entity', () {
    test('covers matches the tree but not a same-prefix sibling', () {
      final g = grant(id: 'g1', path: '/data/spaces/s1/repos');
      expect(g.covers('/data/spaces/s1/repos'), isTrue);
      expect(
        g.covers('/data/spaces/s1/repos/web-app/node_modules/.bin/husky'),
        isTrue,
      );
      expect(
        g.covers('/data/spaces/s1/repos-secrets/tool'),
        isFalse,
        reason: 'a prefix match must respect segment boundaries',
      );
    });

    test('refuses a relative path', () {
      expect(
        () => grant(id: 'g1', path: 'repos'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses a workspace-less grant', () {
      expect(
        () => grant(id: 'g1', ws: '', path: '/data/repos'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('DaoSandboxExecGrantRepository', () {
    late DaoSandboxExecGrantRepository repo;

    setUp(() {
      repo = DaoSandboxExecGrantRepository(dbs);
    });

    test('decisionFor returns null before anyone was asked', () async {
      expect(await repo.decisionFor('ws1', '/data/repos/app'), isNull);
    });

    test('decisionFor resolves the MOST SPECIFIC covering grant', () async {
      // A later, narrower answer has to beat an earlier broad one, or revoking
      // one repo would mean revoking the whole tree and re-answering for all.
      await repo.upsert(
        grant(
          id: 'broad',
          path: '/data/repos',
          decision: SandboxExecGrantDecision.allow,
        ),
      );
      await repo.upsert(
        grant(
          id: 'narrow',
          path: '/data/repos/secret-app',
          decision: SandboxExecGrantDecision.deny,
        ),
      );

      final outer = await repo.decisionFor('ws1', '/data/repos/other/bin/tool');
      expect(outer?.id, 'broad');
      expect(outer?.decision, SandboxExecGrantDecision.allow);

      final inner = await repo.decisionFor(
        'ws1',
        '/data/repos/secret-app/bin/tool',
      );
      expect(inner?.id, 'narrow');
      expect(inner?.decision, SandboxExecGrantDecision.deny);
    });

    test('a deny row is remembered, not treated as "never asked"', () async {
      await repo.upsert(
        grant(
          id: 'g1',
          path: '/data/repos',
          decision: SandboxExecGrantDecision.deny,
        ),
      );
      final found = await repo.decisionFor('ws1', '/data/repos/app/bin/x');
      expect(found, isNotNull);
      expect(found!.decision, SandboxExecGrantDecision.deny);
    });

    test('re-answering the same path replaces rather than duplicates', () async {
      await repo.upsert(
        grant(
          id: 'first',
          path: '/data/repos',
          decision: SandboxExecGrantDecision.deny,
        ),
      );
      await repo.upsert(
        grant(
          id: 'second',
          path: '/data/repos',
          decision: SandboxExecGrantDecision.allow,
        ),
      );
      final all = await repo.grants('ws1');
      expect(all, hasLength(1));
      expect(all.single.id, 'second');
      expect(all.single.decision, SandboxExecGrantDecision.allow);
    });

    test('revoke removes the decision so the operator is asked again', () async {
      await repo.upsert(grant(id: 'g1', path: '/data/repos'));
      await repo.revoke('ws1', 'g1');
      expect(await repo.decisionFor('ws1', '/data/repos/app'), isNull);
      expect(await repo.grants('ws1'), isEmpty);
    });

    test('a grant never leaks into another workspace', () async {
      // The same checkout registered in two workspaces is two decisions: the
      // grants live in each workspace's own database file, so a `ws1` answer
      // must not silently open the same tree for `ws2`.
      await repo.upsert(grant(id: 'g1', ws: 'ws1', path: '/data/repos'));

      expect(await repo.decisionFor('ws1', '/data/repos/app'), isNotNull);
      expect(await repo.decisionFor('ws2', '/data/repos/app'), isNull);
      expect(await repo.grants('ws2'), isEmpty);
    });
  });
}
