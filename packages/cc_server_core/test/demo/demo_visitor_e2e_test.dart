import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
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
      expect(spaceNames, contains('escrow-review'));

      // Messages, in the space the review script is about.
      final reviewSpace = (spaces['spaces'] as List).firstWhere(
        (s) => (s as Map)['name'] == 'escrow-review',
      ) as Map;
      final messages = await client.call('messaging.getMessages', {
        'space_id': reviewSpace['space_id'] ?? reviewSpace['id'],
      });
      expect(
        messages['messages'] as List,
        isNotEmpty,
        reason: 'a seeded space with no history is an empty demo',
      );

      final tickets = await client.call('tickets.list', const {});
      final ticketList = (tickets['tickets'] as List)
          .cast<Map<String, dynamic>>();
      expect(ticketList, isNotEmpty);
      expect(
        ticketList.map((t) => t['key']),
        contains('PD-124'),
        reason: 'the seeded triage ticket the demo script resolves',
      );

      // Calendar, meetings and memory: seeded pillars whose READS must stay
      // reachable. These families have their mutations denied wholesale, and
      // an over-broad prefix rule would silently hide the data that was just
      // seeded — an empty screen that looks like a bug rather than a lockdown.
      final meetings = await client.call('meeting.getByWorkspace', const {});
      final meetingList = (meetings['meetings'] as List)
          .cast<Map<String, dynamic>>();
      expect(meetingList, isNotEmpty);
      final segments = await client.call('meeting.getSegments', {
        'meeting_id': meetingList.first['id'] ?? meetingList.first['meeting_id'],
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
      expect(templateList, hasLength(2),
          reason: 'the demo keeps exactly the two curated pipeline templates');
      expect(
        templateList.map((t) => t['template_id'] ?? t['id']).toSet(),
        {'pr_review', 'ticket_to_pr'},
      );

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
      final artifactList = (artifacts['products'] as List? ??
              artifacts['work_products'] as List? ??
              const [])
          .cast<Map<String, dynamic>>();
      expect(artifactList, isNotEmpty, reason: 'the artifacts surface is furnished');

      // The mock model list: the picker must not read as broken on a demo.
      final models = await client.call('providers.listModels', const {});
      expect(
        (models['models'] as List?) ?? const [],
        isNotEmpty,
        reason: 'the demo answers the model list from static data',
      );

      // The newsfeed lane: real feeds, read-only (the management verbs are
      // denied, the article reads + state toggles are admitted).
      final articles = await client.call('newsfeed.listArticles', const {});
      expect(
        (articles['articles'] as List?) ?? const [],
        isNotEmpty,
        reason: 'a visitor lands on a furnished newsfeed (fallback articles '
            'at minimum; real ones within seconds of the claim)',
      );

      // The workspace logo was seeded to disk — the file the signed
      // `/workspace/logo` route serves.
      expect(
        File('$tmpPath/$workspaceId/logo.png').existsSync(),
        isTrue,
        reason: 'the Parced logo is part of the furnished workspace',
      );

      // The workspace a visitor lands in IS Parced, branded, and the logo is
      // a real file the signed `/workspace/logo` route can serve — not a
      // remote URL, which would be the one thing that broke zero-egress.
      final logo = File('${tmp.path}/$workspaceId/logo.png');
      expect(
        logo.existsSync(),
        isTrue,
        reason: 'the Parced logo is written beside the workspace database',
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
        // The whole backup surface. `databaseBackup` is null on a demo, so all
        // four are absent rather than denied — a demo's databases are shared
        // public fixtures and `workspace.export` would VACUUM one of them into
        // a file it then hands the caller.
        'server.backupNow',
        'server.listBackups',
        'workspace.export',
        'workspace.import',
        'mcp.callTool',
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

  test('two visitors get different workspaces and cannot reach each other\'s', () async {
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
  }, timeout: const Timeout(Duration(minutes: 3)));

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
          'owner': 'parced',
          'repo': 'closing',
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
          'owner': 'parced',
          'repo': 'closing',
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
