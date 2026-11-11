import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/ports/forge_pr_client.dart';
import 'package:cc_infra/testing/http_client.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/forge/forge_provider_factories.dart';
import 'package:cc_server_core/src/pr_review/agent_pr_requesters.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// Every forge client the server builds passes an approval through the
/// guard it was built with, before anything reaches the forge: the one
/// chokepoint a submitted review, a published review (approve on ship) and
/// any other approval share.
void main() {
  late TestHttpClient http;
  late List<({String repo, String workspaceId, String? actor, int pr})> asked;

  Repo repo(ForgeHost forge) => Repo(
    id: 'r-${forge.wire}',
    name: 'widgets',
    path: '/tmp/widgets',
    remoteOwner: 'acme',
    remoteName: 'widgets',
    forge: forge,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
  );

  setUp(() {
    asked = [];
    http = TestHttpClient(
      handler: (request) => httpTextResponse(request, const {'id': 1}),
    );
  });

  ForgeApprovalGuard refusing(
    Repo repo, {
    required String workspaceId,
    String? actingUserId,
  }) => (client, prNumber) async {
    asked.add((
      repo: repo.fullName,
      workspaceId: workspaceId,
      actor: actingUserId,
      pr: prNumber,
    ));
    throw const ValidationException('refused');
  };

  for (final forge in [
    ForgeHost.github,
    ForgeHost.gitlab,
    ForgeHost.bitbucket,
  ]) {
    test('${forge.wire}: an approval meets the guard first, a comment does '
        'not', () async {
      final client = forgePrClientBuilder(forge, http, approvalGuard: refusing)(
        repo(forge),
        workspaceId: 'w1',
        actingUserId: 'alice',
      );

      await expectLater(
        client.submitReview(
          prNumber: 5,
          verdict: ForgeReviewVerdict.approve,
          body: 'LGTM',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(asked, [
        (repo: 'acme/widgets', workspaceId: 'w1', actor: 'alice', pr: 5),
      ]);
      expect(http.requests, isEmpty, reason: 'nothing reached the forge');

      await client.submitReview(
        prNumber: 5,
        verdict: ForgeReviewVerdict.comment,
        body: 'A note',
      );
      expect(asked, hasLength(1));
      expect(http.requests, isNotEmpty);
    });
  }

  test(
    'the server\'s own guard refuses an approval nobody is behind',
    () async {
      final global = createTestGlobalDatabase();
      final dbs = createTestWorkspaceDatabases(global: global);
      await seedTestWorkspace(global, dbs, 'w1');
      final requesters = AgentPrRequesters(
        cacheFor: (ws) => dbs.of(ws).cacheDao,
        crossWorkspace: CrossWorkspaceQueries(dbs),
        viewer: (_, _, _) async => null,
      );
      for (final forge in [
        ForgeHost.github,
        ForgeHost.gitlab,
        ForgeHost.bitbucket,
      ]) {
        final client = forgePrClientBuilder(
          forge,
          http,
          approvalGuard: requesters.guardFor,
        )(repo(forge), workspaceId: 'w1');
        await expectLater(
          client.submitReview(prNumber: 5, verdict: ForgeReviewVerdict.approve),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.message,
              'message',
              contains('Only a person can approve'),
            ),
          ),
          reason: forge.wire,
        );
      }
      expect(http.requests, isEmpty);
    },
  );
}
