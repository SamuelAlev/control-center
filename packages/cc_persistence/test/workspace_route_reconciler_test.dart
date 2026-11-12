import 'package:cc_domain/core/domain/ports/secret_store_port.dart';
import 'package:cc_domain/core/domain/services/webhook_secret_vault.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import 'helpers/seed_agents.dart';
import 'helpers/seed_platform.dart';
import 'helpers/test_database.dart';

/// [WorkspaceRouteReconciler] makes `workspace_routes` agree with the rows
/// its keys point at, in both directions.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late WebhookSecretVault vault;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    vault = WebhookSecretVault(InMemorySecretStore());
    await seedTestWorkspace(global, dbs, 'ws1');
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  WorkspaceRouteReconciler reconciler() => WorkspaceRouteReconciler(
    global: global,
    workspaces: dbs,
    webhookSecrets: vault,
  );

  Future<String?> resolve(WorkspaceRouteKind kind, String key) =>
      global.workspaceRouteDao.resolve(kind, key);

  test('restores a missing route', () async {
    await dbs
        .of('ws1')
        .customStatement(
          'INSERT INTO pipeline_runs (id, template_id, workspace_id) '
          "VALUES ('run-1', 'tpl', 'ws1')",
        );

    final report = await reconciler().run();

    expect(report.restored, 1);
    expect(await resolve(WorkspaceRouteKind.pipelineRun, 'run-1'), 'ws1');
  });

  test('drops a route whose row is gone', () async {
    await global.workspaceRouteDao.put(
      WorkspaceRouteKind.pipelineRun,
      'run-gone',
      'ws1',
    );

    final report = await reconciler().run();

    expect(report.removed, 1);
    expect(await resolve(WorkspaceRouteKind.pipelineRun, 'run-gone'), isNull);
  });

  test('drops a route into a workspace that no longer exists', () async {
    // The schema only routes into a registered workspace; a deleted one
    // keeps its registry row.
    await seedWorkspaceRow(global, 'ws-gone');
    await global.workspaceRouteDao.put(
      WorkspaceRouteKind.pipelineRun,
      'run-x',
      'ws-gone',
    );
    await global.workspaceRegistryDao.deleteWorkspace('ws-gone');

    await reconciler().run();

    expect(await resolve(WorkspaceRouteKind.pipelineRun, 'run-x'), isNull);
  });

  test('keeps a webhook route keyed by the HMAC and drops one keyed by the '
      'raw token', () async {
    const token = 'webhook-secret';
    final routeKey = await vault.webhookRouteKey(token);
    final ref = WebhookSecretVault.pipelineTriggerRef('ws1', routeKey);
    await vault.write(ref, token);
    await seedPipelineTemplate(dbs.of('ws1'), 'tpl');
    await dbs.of('ws1').customStatement(
      'INSERT INTO pipeline_triggers '
      '(id, event_type, template_id, workspace_id, webhook_token_ref, '
      'enabled) '
      "VALUES ('trigger', 'webhook', 'tpl', 'ws1', ?, 1)",
      [ref],
    );
    // A raw token must never be a key: whoever reads the routes table would
    // hold a live webhook secret.
    await global.workspaceRouteDao.put(
      WorkspaceRouteKind.webhookToken,
      token,
      'ws1',
    );

    final report = await reconciler().run();

    expect(await resolve(WorkspaceRouteKind.webhookToken, token), isNull);
    expect(await resolve(WorkspaceRouteKind.webhookToken, routeKey), 'ws1');
    expect(report.removed, 1);
    expect(report.restored, 1);
  });

  test('drops the secure companion of a revoked invite', () async {
    await global.workspaceRouteDao.put(
      WorkspaceRouteKind.inviteCode,
      'code-hash',
      'ws1',
    );

    await reconciler().run();

    expect(await resolve(WorkspaceRouteKind.inviteCode, 'code-hash'), isNull);
    expect(await global.select(global.inviteSecureRoutesTable).get(), isEmpty);
  });

  test('leaves a correct table alone', () async {
    await dbs
        .of('ws1')
        .customStatement(
          'INSERT INTO workspace_invites '
          '(id, workspace_id, code_hash, created_by, expires_at) '
          "VALUES ('inv', 'ws1', 'code-hash', 'owner', 4102444800)",
        );
    await global.workspaceRouteDao.put(
      WorkspaceRouteKind.inviteCode,
      'code-hash',
      'ws1',
    );

    final report = await reconciler().run();

    expect((report.removed, report.restored), (0, 0));
    expect(await resolve(WorkspaceRouteKind.inviteCode, 'code-hash'), 'ws1');
    expect(
      await global.select(global.inviteSecureRoutesTable).get(),
      hasLength(1),
    );
  });
}
