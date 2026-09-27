import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/subscriptions/subscriptions.dart'
    show SubscriptionStatus, SubscriptionUsage;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/native_staging.dart';

/// The headline demo test: boot the REAL server with demo wiring, walk in off
/// the street through `POST /invites/redeem`, and prove three things at once —
/// a visitor gets a furnished workspace, the execution surface is genuinely
/// unreachable, and two visitors never see each other.
///
/// It boots `runCcServer` itself rather than mocking anything, because the
/// claim being tested is about the composition: that passing `buildDemoWiring`
/// removes ops from the registry and swaps the agent lane wholesale.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for demo server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  /// Boots a demo server on an ephemeral loopback port.
  Future<CcServer> bootDemo(Directory tmp) async {
    await stageServerNatives(tmp.path);
    return runCcServer(
      args: [
        '--data-dir',
        tmp.path,
        '--port',
        '0',
        // Nothing to index and no repos; keeps the boot quick and quiet.
        '--code-index',
        'off',
      ],
      demoBuilder: buildDemoWiring,
    );
  }

  /// Redeems the public demo code, returning the envelope.
  Future<Map<String, dynamic>> redeem(int port, {String code = 'demo'}) async {
    final http = HttpClient();
    try {
      final req = await http.postUrl(
        Uri.parse('http://127.0.0.1:$port/invites/redeem'),
      );
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode({'code': code}));
      final resp = await req.close();
      final body = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        fail('redeem failed (${resp.statusCode}): $body');
      }
      return jsonDecode(body) as Map<String, dynamic>;
    } finally {
      http.close(force: true);
    }
  }

  test(
    'a visitor redeems, lands in a furnished workspace, and cannot execute',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_demo_e2e');
      addTearDown(() => deleteDirBestEffort(tmp));
      final tmpPath = tmp.path;
      final server = await bootDemo(tmp);
      addTearDown(server.shutdown);
      final port = server.rpc.boundPort;

      // ── The door ──
      final envelope = await redeem(port);
      final workspaceId = envelope['workspace_id'] as String;
      final deviceId = envelope['device_id'] as String;
      final psk = envelope['psk'] as String;

      expect(workspaceId, isNotEmpty);
      expect(psk, isNotEmpty);
      expect(envelope['role'], 'admin', reason: 'their own sandbox');
      expect(
        envelope['descriptor'],
        isA<Map<String, dynamic>>(),
        reason: 'the client prefers the descriptor over server_url',
      );
      expect((envelope['user'] as Map)['handle'], startsWith('guest-'));

      // ── The session ──
      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:$port/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();
      client.activeWorkspaceId = workspaceId;

      // ── Furnished: the pillars a visitor lands on are not empty states ──
      final spaces = await client.call('messaging.listSpaces', const {});
      expect(
        spaces['spaces'] as List,
        isNotEmpty,
        reason: 'the demo must never open on an empty space list',
      );
      final spaceNames = [
        for (final s in spaces['spaces'] as List) (s as Map)['name'],
      ];
      expect(spaceNames, contains('eval-review'));

      // Folder membership comes from the visitor's own synced preference,
      // and every filed id must belong to a visible space in this workspace.
      final ownPrefs = await client
          .subscribe('prefs.watchOwn', const {})
          .first
          .timeout(const Duration(seconds: 20));
      final folderJson =
          (ownPrefs['prefs'] as Map)['space_folders.$workspaceId'] as String;
      final folders = (jsonDecode(folderJson) as List)
          .cast<Map<String, dynamic>>();
      expect(folders.map((f) => f['name']), ['Evaluation', 'Planning']);
      final idsByName = {
        for (final s in (spaces['spaces'] as List).cast<Map>())
          s['name']: s['id'],
      };
      expect(folders[0]['spaceIds'], [
        idsByName['eval-review'],
        idsByName['eval-progress'],
      ]);
      expect(folders[1]['spaceIds'], [idsByName['eval-reports']]);
      expect(
        {for (final folder in folders) ...folder['spaceIds'] as List},
        isNot(contains(idsByName['general'])),
        reason: 'general remains unfiled in the visitor sidebar',
      );

      final newSpace = await client.call('messaging.createSpace', {
        'name': 'Visitor notes',
        'agent_ids': <String>[],
      });
      final newSpaceId = (newSpace['space'] as Map)['id'] as String;
      expect(
        await client.call('messaging.getSpaceRepos', {'space_id': newSpaceId}),
        {'repo_ids': <String>[]},
        reason: 'omitting repo_ids must not select the four demo repos',
      );
      var ready = false;
      for (var attempt = 0; attempt < 40; attempt++) {
        final current = await client.call('messaging.listSpaces', const {});
        final visitorSpace = (current['spaces'] as List).cast<Map>().firstWhere(
          (space) => space['id'] == newSpaceId,
        );
        if (visitorSpace['provisioning_status'] == 'ready') {
          ready = true;
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      expect(
        ready,
        isTrue,
        reason: 'demo rooms become ready without worktrees',
      );
      await expectLater(
        client.call('messaging.createSpace', {
          'name': 'Cannot check out a repo',
          'agent_ids': <String>[],
          'repo_ids': ['demo-repo-evalkit'],
        }),
        throwsA(isA<RemoteRpcException>()),
      );

      // Messages, in the space the review script is about.
      final reviewSpace =
          (spaces['spaces'] as List).firstWhere(
                (s) => (s as Map)['name'] == 'eval-review',
              )
              as Map;
      final messages = await client.call('messaging.getMessages', {
        'space_id': reviewSpace['space_id'] ?? reviewSpace['id'],
      });
      expect(
        messages['messages'] as List,
        isNotEmpty,
        reason: 'a seeded space with no history is an empty demo',
      );
      final reviewConversations = await client.call('conversation.list', {
        'space_id': reviewSpace['id'],
      });
      final conversations = (reviewConversations['conversations'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        conversations.map((c) => c['title']),
        containsAll([
          'PR #412 · Budget review',
          'Release gate · Shared run groups',
          'Diego’s release timing',
        ]),
      );
      final releaseGate = conversations.firstWhere(
        (c) => c['title'] == 'Release gate · Shared run groups',
      );
      final approvalRunId = '$workspaceId:demo-run-push-approval';
      final gateMessages = await client.call('messaging.getMessages', {
        'space_id': reviewSpace['id'],
        'conversation_id': releaseGate['id'],
      });
      final waitingTurn = (gateMessages['messages'] as List)
          .cast<Map>()
          .singleWhere((message) => message['id'] == approvalRunId);
      expect(waitingTurn['sender_id'], 'demo-agent-reviewer');
      final waitingSegments =
          ((waitingTurn['metadata'] as Map)['segments'] as List).cast<Map>();
      expect(
        (waitingSegments
                .where((segment) => segment['type'] == 'tool')
                .single['inputs']
            as Map)['command'],
        'git push origin feature/eval-budget-ledger',
      );
      expect(
        waitingSegments
            .where((segment) => segment['type'] == 'tool')
            .single['outputs'],
        contains('not executed'),
      );
      final waitingRun =
          (await client.call('agent_run_log.get', {'id': approvalRunId}))['log']
              as Map;
      expect(waitingRun['agent_id'], waitingTurn['sender_id']);
      expect(waitingRun['space_id'], reviewSpace['id']);
      expect(waitingRun['conversation_id'], releaseGate['id']);
      expect(waitingRun['workspace_id'], workspaceId);
      expect(waitingRun['status'], 'running');
      expect(waitingRun['liveness'], 'blocked');
      final replay = await client.call('agent_run_log.getTranscript', {
        'run_id': approvalRunId,
      });
      expect(
        (replay['segments'] as List).cast<Map>().where(
          (segment) => segment['type'] == 'tool',
        ),
        hasLength(1),
      );
      final followUp = conversations.firstWhere(
        (c) => c['title'] == 'Release gate · Shared run groups',
      );
      final followUpMessages = await client.call('messaging.getMessages', {
        'space_id': reviewSpace['id'],
        'conversation_id': followUp['id'],
      });
      expect(
        (followUpMessages['messages'] as List).map(
          (message) => (message as Map)['content'],
        ),
        containsAll([
          contains('parallel retries'),
          contains('cancellation path'),
        ]),
      );
      final thread = conversations.firstWhere(
        (c) => c['title'] == 'Diego’s release timing',
      );
      expect(
        (messages['messages'] as List).map((m) => (m as Map)['id']),
        contains(thread['anchor_message_id']),
        reason: 'the thread anchors to an actual standing-conversation message',
      );
      final threadMessages = await client.call('messaging.getMessages', {
        'space_id': reviewSpace['id'],
        'conversation_id': thread['id'],
      });
      expect(
        (threadMessages['messages'] as List).map(
          (message) => (message as Map)['content'],
        ),
        contains(contains('Wednesday')),
      );
      final threadSummaries = await client
          .subscribe('conversation.watchThreadSummaries', {
            'space_id': reviewSpace['id'],
          })
          .first
          .timeout(const Duration(seconds: 20));
      expect(
        (threadSummaries['threads'] as List).cast<Map>().any(
          (summary) =>
              summary['thread_id'] == thread['id'] &&
              summary['anchor_message_id'] == thread['anchor_message_id'] &&
              summary['reply_count'] == 1,
        ),
        isTrue,
        reason:
            'the standing chat renders a visible reply badge for the thread',
      );
      final progressConversations = await client.call('conversation.list', {
        'space_id': idsByName['eval-progress'],
      });
      expect(
        (progressConversations['conversations'] as List).cast<Map>().map(
          (c) => c['title'],
        ),
        contains('Retriever #88 · Hybrid recall'),
      );

      final approvals = await client
          .subscribe('confirmation.watchPending', const {})
          .first
          .timeout(const Duration(seconds: 20));
      final pushApproval = (approvals['pending'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((entry) => entry['space_id'] == reviewSpace['id']);
      expect(
        pushApproval['command'],
        'git push origin feature/eval-budget-ledger',
      );
      expect(pushApproval['detail'], contains(approvalRunId));
      expect(pushApproval['detail'], contains('/workspace/helix/evalkit'));
      expect(
        await client.call('confirmation.respond', {
          'id': pushApproval['id'],
          'approved': true,
        }),
        {'ok': true},
        reason: 'the fictional approval resolves only a registry entry',
      );
      final remainingApprovals = await client
          .subscribe('confirmation.watchPending', const {})
          .first
          .timeout(const Duration(seconds: 20));
      expect(
        (remainingApprovals['pending'] as List).where(
          (entry) => (entry as Map)['id'] == pushApproval['id'],
        ),
        isEmpty,
        reason: 'approving an inert prompt cannot start a real push',
      );
      Map<String, dynamic>? resolvedRun;
      for (var attempt = 0; attempt < 40; attempt++) {
        resolvedRun =
            (await client.call('agent_run_log.get', {
                  'id': approvalRunId,
                }))['log']
                as Map<String, dynamic>;
        if (resolvedRun['status'] == 'completed') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(resolvedRun!['status'], 'completed');
      expect(resolvedRun['summary'], contains('not executed'));
      final decisionMessages = await client.call('messaging.getMessages', {
        'space_id': reviewSpace['id'],
        'conversation_id': releaseGate['id'],
      });
      expect(
        (decisionMessages['messages'] as List).cast<Map>().map(
          (message) => message['content'],
        ),
        contains(contains('no git push was executed')),
      );

      // Chat on the PR page looks this up by repo + number rather than
      // calling `pr.ensureSpace` (which a demo refuses). Without this row
      // the tab is the red "Unknown op" the visitor used to see.
      final reviewSpaces = await client
          .subscribe('review_space.watchByWorkspace', const {})
          .first
          .timeout(const Duration(seconds: 20));
      final associations = (reviewSpaces['associations'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      expect(
        associations.any(
          (a) =>
              a['pr_number'] == 412 &&
              a['repo_full_name'] == 'helix/evalkit' &&
              a['space_id'] == (reviewSpace['space_id'] ?? reviewSpace['id']),
        ),
        isTrue,
        reason: 'PR #412 chat is the eval-review space, linked by association',
      );

      final tickets = await client.call('tickets.list', const {});
      final ticketList = (tickets['tickets'] as List)
          .cast<Map<String, dynamic>>();
      expect(ticketList, hasLength(16));
      expect(
        ticketList.map((t) => t['key']),
        contains('HX-118'),
        reason: 'the seeded triage ticket the demo script resolves',
      );

      expect(
        ticketList.map((t) => t['key']),
        containsAll(['HX-118', 'HX-124', 'HX-129', 'HX-145', 'HX-160']),
      );
      expect(
        ticketList.map((t) => t['status']).toSet().length,
        greaterThanOrEqualTo(5),
        reason: 'the board must show actual work moving between lanes',
      );
      // Linked repos + the open-PR snapshot the list and inbox both read.
      // The wire key is `prs` (not `pull_requests`): a snapshot that used the
      // wrong key decoded as empty groups, and the client skipped them, so
      // the PR list and Maya's inbox both rendered as a zero state.
      final linkedRepos = await client
          .subscribe('repos.watchAll', const {})
          .first
          .timeout(const Duration(seconds: 20));
      final repoRows = (linkedRepos['repos'] as List)
          .cast<Map<String, dynamic>>();
      expect(
        repoRows,
        hasLength(4),
        reason: 'Helix ships four linked data-science repos',
      );
      expect(
        {for (final r in repoRows) '${r['remote_owner']}/${r['remote_name']}'},
        {
          'helix/evalkit',
          'helix/retriever',
          'helix/features',
          'helix/finetune',
        },
      );

      final openPrs = await client
          .subscribe('pr.watchOpenForWorkspace', const {})
          .first
          .timeout(const Duration(seconds: 20));
      expect(
        openPrs['authenticated'],
        isTrue,
        reason: 'a demo visitor must not land on the signed-out PR empty state',
      );
      final groups = (openPrs['repos'] as List).cast<Map<String, dynamic>>();
      expect(groups, hasLength(4));
      final numbers = <int>{};
      for (final group in groups) {
        expect(
          group.containsKey('prs'),
          isTrue,
          reason: 'the list client reads `prs`, not `pull_requests`',
        );
        expect(group['repo_id'], isNotEmpty);
        final prs = (group['prs'] as List).cast<Map<String, dynamic>>();
        expect(
          prs,
          isNotEmpty,
          reason: '${group['repo_full_name']} would vanish from the list',
        );
        for (final pr in prs) {
          numbers.add((pr['number'] as num).toInt());
        }
      }
      expect(numbers, containsAll({412, 409, 88, 81, 54, 49, 23, 19}));

      // Calendar, meetings and memory: seeded pillars whose READS must stay
      // reachable. These families have their mutations denied wholesale, and
      // an over-broad prefix rule would silently hide the data that was just
      // seeded — an empty screen that looks like a bug rather than a lockdown.
      final meetings = await client.call('meeting.getByWorkspace', const {});
      final meetingList = (meetings['meetings'] as List)
          .cast<Map<String, dynamic>>();
      expect(meetingList, isNotEmpty);
      final segments = await client.call('meeting.getSegments', {
        'meeting_id':
            meetingList.first['id'] ?? meetingList.first['meeting_id'],
      });
      expect(
        segments['segments'] as List,
        isNotEmpty,
        reason: 'a meeting with no transcript is an empty meeting',
      );

      final accounts = await client.call('calendar.getAccounts', const {});
      expect(
        accounts['accounts'] as List,
        isNotEmpty,
        reason:
            'a calendar source and event both FK to an account — without one '
            'the whole calendar is unseedable',
      );

      final facts = await client.call('memory_fact.getByWorkspace', const {});
      expect(facts['facts'] as List, isNotEmpty);
      final policies = await client.call(
        'memory_policy.getByWorkspace',
        const {},
      );
      expect(
        policies['policies'] as List,
        isNotEmpty,
        reason: 'facts without policies leaves half the memory surface empty',
      );

      // The whole `forge.*` family is absent, and that is deliberate even
      // though the client's onboarding gate reads it: the ops live behind the
      // `forgeCredentials` port, which the demo nulls, so making them answer
      // would mean wiring a CREDENTIAL port into a public server to improve a
      // settings message. The client copes instead — `onboardingGateProvider`
      // short-circuits to `complete` on a demo server before it ever asks
      // about a forge (see the demo group in test/router/router_test.dart).
      // Without that short-circuit a visitor was shown a sign-in screen for a
      // credential a demo cannot hold.
      for (final op in ['forge.listConnections', 'forge.capabilities']) {
        await expectLater(
          client.call(op, const {}),
          throwsA(
            isA<RemoteRpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.opUnknown,
            ),
          ),
          reason: '$op rides the credential port the demo does not wire',
        );
      }

      // ── The mocked surfaces a demo exists to showcase ──

      // Exactly two pipeline templates (the curated pair), not the product's
      // thirteen — and the boot reconcile must not re-add the rest. The
      // templates are written by the unawaited `WorkspaceCreated` listener,
      // so the first read polls briefly for it to land.
      List<Map<String, dynamic>> templateList = const [];
      for (var attempt = 0; attempt < 40; attempt++) {
        final templates = await client.call(
          'pipeline_template.forWorkspace',
          const {},
        );
        templateList = ((templates['templates'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        if (templateList.isNotEmpty) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(
        templateList,
        hasLength(2),
        reason: 'the demo keeps exactly the two curated pipeline templates',
      );
      expect(templateList.map((t) => t['template_id'] ?? t['id']).toSet(), {
        'pr_review',
        'ticket_to_pr',
      });

      // Finished (and failed) pipeline runs with real step rows.
      // Pipeline run ids are GLOBALLY routed through `workspace_routes`, so
      // the demo scopes them per workspace — a fixed id shared by every pooled
      // workspace pointed the route at whichever wrote it first.
      final runs = await client.call('pipeline_run.getRun', {
        'id': '$workspaceId:demo-pipeline-run-0',
      });
      expect(runs['run'], isNotNull, reason: 'a seeded pipeline run exists');

      // Work products (the artifacts surface) with revision history.
      final artifacts = await client.call(
        'workProduct.listForWorkspace',
        const {},
      );
      final artifactList =
          (artifacts['products'] as List? ??
                  artifacts['work_products'] as List? ??
                  const [])
              .cast<Map<String, dynamic>>();
      expect(
        artifactList,
        isNotEmpty,
        reason: 'the artifacts surface is furnished',
      );

      // The mock model list: the picker must not read as broken on a demo.
      final models = await client.call('providers.listModels', const {});
      expect(
        (models['models'] as List?) ?? const [],
        isNotEmpty,
        reason: 'the demo answers the model list from static data',
      );

      // Same RPC and wire codec as the title-bar usage pill. Every provider
      // here is invented for the demo; the host must never consult a CLI,
      // credential store or provider endpoint to populate this snapshot.
      final usageResponse = await client.call('subscriptions.usage', const {});
      final usage = [
        for (final raw in usageResponse['providers'] as List)
          SubscriptionUsage.fromJson((raw as Map).cast<String, dynamic>()),
      ];
      expect(
        {for (final provider in usage) provider.providerId},
        {'claude', 'codex', 'cursor', 'zai', 'kimi-code'},
      );
      expect(
        usage.every(
          (provider) =>
              provider.status == SubscriptionStatus.ok &&
              provider.hasReading &&
              provider.displayName.contains('(demo)') &&
              provider.windows.every(
                (window) =>
                    window.usedFraction > 0 &&
                    window.usedFraction < 1 &&
                    window.resetsAt != null,
              ),
        ),
        isTrue,
        reason: 'the pill must render configured, explicitly fictional quotas',
      );
      expect(
        usage.every((provider) => provider.accountId == null),
        isTrue,
        reason: 'the demo cannot expose a machine account identity',
      );

      await expectLater(
        client.call('subscriptions.refresh', const {}),
        throwsA(
          isA<RemoteRpcException>().having(
            (error) => error.code,
            'code',
            RpcErrorCodes.opUnknown,
          ),
        ),
        reason: 'only the fictional quota read escapes the denied family',
      );

      // The newsfeed lane: real feeds, read-only (the management verbs are
      // denied, the article reads + state toggles are admitted).
      final articles = await client.call('newsfeed.listArticles', const {});
      expect(
        (articles['articles'] as List?) ?? const [],
        isNotEmpty,
        reason:
            'a visitor lands on a furnished newsfeed (fallback articles '
            'at minimum; real ones within seconds of the claim)',
      );

      // The workspace logo was seeded to disk — the file the signed
      // `/workspace/logo` route serves.
      expect(
        File('$tmpPath/$workspaceId/logo.png').existsSync(),
        isTrue,
        reason: 'the Helix logo is part of the furnished workspace',
      );

      // The workspace a visitor lands in IS Helix, branded, and the logo is
      // a real file the signed `/workspace/logo` route can serve — not a
      // remote URL, which would be the one thing that broke zero-egress.
      final logo = File('${tmp.path}/$workspaceId/logo.png');
      expect(
        logo.existsSync(),
        isTrue,
        reason: 'the Helix logo is written beside the workspace database',
      );
      expect(logo.lengthSync(), greaterThan(0));

      // ── Locked down: absent, not merely denied ──
      for (final op in [
        'terminal.spawn',
        'rig.open',
        'fs.writeString',
        'codeServer.ensure',
        'oauth.begin',
        'credentials.set',
        'worktree.commitAndPush',
        // The whole backup surface. `databaseBackup` is null on a demo, so
        // every operation is absent rather than denied: demo databases are
        // shared public fixtures, not a source for export or restore.
        'server.backupNow',
        'server.listBackups',
        'server.deleteBackup',
        'workspace.export',
        'workspace.import',
        'mcp.callTool',
        // Pipeline host-exec. `pipeline.start` is absent because the engine
        // port is null; template upsert / trigger writes are refused by
        // name even though those ops are always built. A visitor who can
        // author a `bash.script` node and start it — by hand or via an
        // event trigger — is executing code on this host.
        'pipeline.start',
        'pipeline.cancel',
        'pipeline.retry',
        'pipeline.killStep',
        'messaging.retrySpaceProvisioning',
        'messaging.cancelSpaceProvisioning',
        'pipeline_template.upsert',
        'pipeline_trigger.insert',
        'pipeline_trigger.update',
        'pipeline_trigger.markFired',
        'playbook.run',
        'orchestration.approve',
        'orchestration.approveNodes',
        'orchestration.continueNode',
        'plan.approve',
        'review_hub.start',
      ]) {
        await expectLater(
          client.call(op, const {}),
          throwsA(
            isA<RemoteRpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.opUnknown,
            ),
          ),
          reason:
              '$op must be UNKNOWN on a demo server, not merely refused — the '
              'port is null, so the op was never built into the registry',
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'a visitor can replay Ravi and Juno collaborating without execution',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_demo_story');
      addTearDown(() => deleteDirBestEffort(tmp));
      final server = await bootDemo(tmp);
      addTearDown(server.shutdown);
      final env = await redeem(server.rpc.boundPort);
      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: env['device_id'] as String,
        psk: env['psk'] as String,
      );
      addTearDown(client.close);
      await client.initialize();
      client.activeWorkspaceId = env['workspace_id'] as String;
      final spaces =
          (await client.call('messaging.listSpaces', const {}))['spaces']
              as List;
      final reviewSpace = spaces.cast<Map>().singleWhere(
        (space) => space['name'] == 'eval-review',
      );
      final conversations =
          (await client.call('conversation.list', {
                'space_id': reviewSpace['id'],
              }))['conversations']
              as List;
      final walkthrough = conversations.cast<Map>().singleWhere(
        (conversation) =>
            conversation['title'] == 'HX-124 · Shared run-group walkthrough',
      );
      await client.call('dispatch.sendAndDispatch', {
        'space_id': reviewSpace['id'],
        'conversation_id': walkthrough['id'],
        'content': '@Ravi shared run-group walkthrough',
      });

      List<Map> messages = const [];
      for (var attempt = 0; attempt < 120; attempt++) {
        final response = await client.call('messaging.getMessages', {
          'space_id': reviewSpace['id'],
          'conversation_id': walkthrough['id'],
        });
        messages = (response['messages'] as List).cast<Map>();
        if (messages.any(
              (message) =>
                  message['sender_id'] == 'demo-agent-triage' &&
                  (message['content'] as String).contains(
                    'Nothing was written',
                  ),
            ) &&
            messages.any(
              (message) =>
                  message['sender_id'] == 'demo-agent-reviewer' &&
                  (message['content'] as String).contains('Thanks, Juno'),
            )) {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      final juno = messages.singleWhere(
        (message) =>
            message['sender_id'] == 'demo-agent-triage' &&
            message['message_type'] == 'agentTurn',
      );
      final ravi = messages.singleWhere(
        (message) =>
            message['sender_id'] == 'demo-agent-reviewer' &&
            (message['content'] as String).contains('Thanks, Juno'),
      );
      expect(juno['conversation_id'], walkthrough['id']);
      expect(ravi['conversation_id'], walkthrough['id']);
      final segments = ((juno['metadata'] as Map)['segments'] as List)
          .cast<Map>();
      expect(
        segments
            .where((segment) => segment['type'] == 'tool')
            .map((segment) => segment['toolName']),
        containsAllInOrder(['read', 'edit', 'bash']),
      );
      expect(
        segments
            .where((segment) => segment['toolName'] == 'edit')
            .single['outputs'],
        contains('no filesystem write'),
      );
      final run =
          (await client.call('agent_run_log.get', {'id': juno['id']}))['log']
              as Map;
      expect(run['agent_id'], 'demo-agent-triage');
      expect(run['status'], 'completed');
      final transcript = await client.call('agent_run_log.getTranscript', {
        'run_id': juno['id'],
      });
      expect(
        (transcript['segments'] as List).cast<Map>().where(
          (segment) => segment['type'] == 'tool',
        ),
        hasLength(3),
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'two visitors get different workspaces and cannot reach each other\'s',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_demo_isolation');
      addTearDown(() => deleteDirBestEffort(tmp));
      final server = await bootDemo(tmp);
      addTearDown(server.shutdown);
      final port = server.rpc.boundPort;

      final first = await redeem(port);
      final second = await redeem(port);

      expect(
        first['workspace_id'],
        isNot(second['workspace_id']),
        reason: 'each visitor gets their own sandbox',
      );
      expect(first['user'], isNot(second['user']));

      // Visitor two, naming visitor one's workspace.
      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:$port/rpc'),
        deviceId: second['device_id'] as String,
        psk: second['psk'] as String,
      );
      addTearDown(client.close);
      await client.initialize();
      client.activeWorkspaceId = second['workspace_id'] as String;
      final ownPrefs = await client
          .subscribe('prefs.watchOwn', const {})
          .first
          .timeout(const Duration(seconds: 20));
      final prefs = (ownPrefs['prefs'] as Map).cast<String, String>();
      expect(
        prefs.containsKey('space_folders.${second['workspace_id']}'),
        isTrue,
      );
      expect(
        prefs.containsKey('space_folders.${first['workspace_id']}'),
        isFalse,
        reason: 'another visitor’s personal layout is not a global fixture',
      );
      final folders =
          (jsonDecode(prefs['space_folders.${second['workspace_id']}']!)
                  as List)
              .cast<Map<String, dynamic>>();
      final ownSpaces = await client.call('messaging.listSpaces', const {});
      final ownSpaceIds = {
        for (final space in (ownSpaces['spaces'] as List).cast<Map>())
          space['id'],
      };
      expect({
        for (final folder in folders) ...folder['spaceIds'] as List,
      }, everyElement(isIn(ownSpaceIds)));
      final ownApproval = await client
          .subscribe('confirmation.watchPending', const {})
          .first
          .timeout(const Duration(seconds: 20));
      final pending = (ownApproval['pending'] as List).cast<Map>();
      expect(
        pending.map((request) => request['workspace_id']),
        everyElement(second['workspace_id']),
      );
      final denied = pending.singleWhere(
        (request) =>
            request['command'] == 'git push origin feature/eval-budget-ledger',
      );
      await client.call('confirmation.respond', {
        'id': denied['id'],
        'approved': false,
      });
      final ownRunId = '${second['workspace_id']}:demo-run-push-approval';
      Map<String, dynamic>? deniedRun;
      for (var attempt = 0; attempt < 40; attempt++) {
        deniedRun =
            (await client.call('agent_run_log.get', {'id': ownRunId}))['log']
                as Map<String, dynamic>;
        if (deniedRun['status'] == 'completed') {
          break;
        }
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
      expect(deniedRun!['status'], 'completed');
      expect(deniedRun['summary'], contains('denied'));
      expect(deniedRun['summary'], contains('not executed'));
      await expectLater(
        client.call('agent_run_log.getTranscript', {
          'run_id': '${first['workspace_id']}:demo-run-push-approval',
        }),
        throwsA(isA<RemoteRpcException>()),
        reason: 'a run transcript is scoped to its visitor workspace',
      );
      client.activeWorkspaceId = first['workspace_id'] as String;

      await expectLater(
        client.call('tickets.list', const {}),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.unauthorized,
          ),
        ),
        reason: 'membership is the access boundary, not holding a demo code',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('one visitor cannot see another visitor in the user list', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_demo_users');
    addTearDown(() => deleteDirBestEffort(tmp));
    final server = await bootDemo(tmp);
    addTearDown(server.shutdown);
    final port = server.rpc.boundPort;

    final first = await redeem(port);
    final second = await redeem(port);

    final me = (second['user'] as Map)['id'] as String;
    final stranger = (first['user'] as Map)['id'] as String;

    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:$port/rpc'),
      deviceId: second['device_id'] as String,
      psk: second['psk'] as String,
    );
    addTearDown(client.close);
    await client.initialize();
    client.activeWorkspaceId = second['workspace_id'] as String;

    // Identity is global — every visitor is a row in the same `users` table —
    // so the co-membership filter is the ONLY thing separating them. The watch
    // lane used to stream `getAll()` verbatim while the op lane filtered, which
    // made subscribing a way to enumerate every account on the server.
    final listed = await client.call('users.list', const {});
    final ids = {
      for (final u in (listed['users'] as List).cast<Map<String, dynamic>>())
        u['id'] as String,
    };
    expect(ids, contains(me), reason: 'a visitor sees themselves');
    expect(
      ids,
      isNot(contains(stranger)),
      reason: 'and not the stranger who redeemed the same public code',
    );

    final streamed = await client
        .subscribe('users.watchAll', const {})
        .first
        .timeout(const Duration(seconds: 20));
    final streamedIds = {
      for (final u in (streamed['users'] as List).cast<Map<String, dynamic>>())
        u['id'] as String,
    };
    expect(streamedIds, contains(me));
    expect(
      streamedIds,
      isNot(contains(stranger)),
      reason: 'the subscription lane applies the same rule as the op lane',
    );
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('the seeded AI review reads back on the PR', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_demo_review');
    addTearDown(() => deleteDirBestEffort(tmp));
    final server = await bootDemo(tmp);
    addTearDown(server.shutdown);
    final port = server.rpc.boundPort;
    final env = await redeem(port);

    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:$port/rpc'),
      deviceId: env['device_id'] as String,
      psk: env['psk'] as String,
    );
    addTearDown(client.close);
    await client.initialize();
    client.activeWorkspaceId = env['workspace_id'] as String;

    // The review surface reads through the SUBSCRIPTION lane, so seeding rows
    // the op lane can see proves nothing — `review_studio.*` ops are denied on
    // a demo and only the watches are admitted.
    final axes = await client
        .subscribe('review_studio.watchAxisResults', const {
          'owner': 'helix',
          'repo': 'evalkit',
          'pr_number': 412,
        })
        .first
        .timeout(const Duration(seconds: 20));
    final results = axes['axes'] as List;
    expect(
      results,
      isNotEmpty,
      reason: 'the review tab renders its empty state without these rows',
    );
    final verdicts = {
      for (final r in results.cast<Map<String, dynamic>>())
        r['axis'] as String: r['verdict'] as String,
    };
    expect(verdicts['correctness'], 'warn');
    expect(
      verdicts['visual'],
      'unavailable',
      reason: 'an all-green panel shows none of the triage it exists for',
    );

    final cohorts = await client
        .subscribe('review_studio.watchCohorts', const {
          'owner': 'helix',
          'repo': 'evalkit',
          'pr_number': 412,
        })
        .first
        .timeout(const Duration(seconds: 20));
    expect(cohorts['cohorts'] as List, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));

  test('a wrong invite code is refused', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_demo_badcode');
    addTearDown(() => deleteDirBestEffort(tmp));
    final server = await bootDemo(tmp);
    addTearDown(server.shutdown);

    final http = HttpClient();
    addTearDown(() => http.close(force: true));
    final req = await http.postUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/invites/redeem'),
    );
    req.headers.contentType = ContentType.json;
    req.write(jsonEncode({'code': 'not-the-demo-code'}));
    final resp = await req.close();
    await resp.drain<void>();
    expect(resp.statusCode, HttpStatus.forbidden);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
