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
        g.covers('/data/spaces/s1/repos/shop-ui/node_modules/.bin/husky'),
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

    test(
      're-answering the same path replaces rather than duplicates',
      () async {
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
      },
    );

    test(
      'revoke removes the decision so the operator is asked again',
      () async {
        await repo.upsert(grant(id: 'g1', path: '/data/repos'));
        await repo.revoke('ws1', 'g1');
        expect(await repo.decisionFor('ws1', '/data/repos/app'), isNull);
        expect(await repo.grants('ws1'), isEmpty);
      },
    );

    group('searchGrants', () {
      setUp(() async {
        for (var i = 0; i < 5; i++) {
          await repo.upsert(
            grant(
              id: 'g$i',
              path: '/data/spaces/s$i/repos',
              at: DateTime.utc(2026, 1, 1 + i),
            ),
          );
        }
        await repo.upsert(
          grant(
            id: 'under',
            path: '/data/cc_server/repos',
            at: DateTime.utc(2026, 2, 1),
          ),
        );
        await repo.upsert(
          grant(id: 'other-ws', ws: 'ws2', path: '/data/spaces/s9/repos'),
        );
      });

      test('pages newest first with the full total', () async {
        final first = await repo.searchGrants('ws1', limit: 4);
        final second = await repo.searchGrants('ws1', limit: 4, offset: 4);

        expect(first.total, 6);
        expect(second.total, 6);
        expect(first.grants.map((g) => g.id), ['under', 'g4', 'g3', 'g2']);
        expect(second.grants.map((g) => g.id), ['g1', 'g0']);
      });

      test('matches a case-insensitive substring of the path', () async {
        final page = await repo.searchGrants(
          'ws1',
          query: 'S3/REPOS',
          limit: 10,
        );
        expect(page.grants.map((g) => g.id), ['g3']);
        expect(page.total, 1);
      });

      test('treats % and _ literally', () async {
        // Paths carry underscores; `_` as a LIKE wildcard would match
        // `ccXserver`, and stripping it would stop `cc_server` matching.
        final under = await repo.searchGrants(
          'ws1',
          query: 'cc_server',
          limit: 10,
        );
        expect(under.grants.map((g) => g.id), ['under']);

        final percent = await repo.searchGrants('ws1', query: '%', limit: 10);
        expect(percent.grants, isEmpty);
        expect(percent.total, 0);
      });

      test('a blank query lists everything in the workspace only', () async {
        final page = await repo.searchGrants('ws2', query: '  ', limit: 10);
        expect(page.grants.map((g) => g.id), ['other-ws']);
        expect(page.total, 1);
      });
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
