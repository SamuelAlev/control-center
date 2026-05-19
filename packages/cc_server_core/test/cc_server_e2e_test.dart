import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart' show BuildInfo, RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// End-to-end proof of the pure-Dart server: seed a real database, boot the
/// actual [runCcServer] composition, connect a real RPC client through the full
/// PSK handshake and read a seeded ticket back over `repo/call`.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh. '
          'They are REQUIRED; '
          'cc_server refuses to boot without them.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  test(
    'RPC client reads a seeded ticket from the running pure-Dart cc_server',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_e2e');
      // The boot preflight refuses to start without the native libraries;
      // stage whatever this machine has into the data dir (see the helper).
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'web-test-device';
      const psk = 'test-psk-please-and-thank-you-0123456789';
      const workspaceId = 'ws-alpha';

      // --- Seed the server's DB + secrets exactly as a paired device would exist.
      final seed = openSeedDatabases(tmp.path);
      await seed.global.workspaceRegistryDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Alpha'),
        ),
      );
      await DaoTicketRepository(
        seed.workspaces,
        seed.global.workspaceRouteDao,
      ).insert(
        Ticket(
          id: 't1',
          workspaceId: workspaceId,
          title: 'Seeded over the wire',
          status: TicketStatus.open,
          createdAt: DateTime.utc(2026),
          updatedAt: DateTime.utc(2026),
        ),
      );
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(workspaceId),
          label: Value('e2e'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      // --- Boot the REAL pure-Dart server on an ephemeral loopback port.
      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      // --- Connect a real client through the PSK handshake and read tickets.
      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();
      client.activeWorkspaceId = workspaceId;

      final data = await client.call('tickets.list', const {});
      final tickets = (data['tickets'] as List).cast<Map<String, dynamic>>();

      expect(tickets, hasLength(1));
      expect(tickets.single['ticket_id'], 't1');
      expect(tickets.single['title'], 'Seeded over the wire');
      expect(tickets.single['workspace_id'], workspaceId);
    },
  );

  test('GET /healthz returns liveness JSON without auth', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_server_health');
    // The boot preflight refuses to start without the native libraries;
    // stage whatever this machine has into the data dir (see the helper).
    await stageServerNatives(tmp.path);
    addTearDown(() => tmp.deleteSync(recursive: true));

    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);

    final http = HttpClient();
    addTearDown(() => http.close(force: true));
    final req = await http.getUrl(
      Uri.parse('http://127.0.0.1:${server.rpc.boundPort}/healthz'),
    );
    final resp = await req.close();
    expect(resp.statusCode, 200);
    final body = await resp.transform(utf8.decoder).join();
    final json = jsonDecode(body) as Map<String, dynamic>;
    expect(json['status'], 'ok');
    expect(json['uptimeSeconds'], isA<int>());
    expect(json['connections'], 0);
    expect(json['port'], server.rpc.boundPort);
    // Build/compat identity (stale-binary detection): the CI-stamped consts
    // + the workspace schema + the repo-RPC catalog the server speaks.
    expect(json['version'], BuildInfo.buildVersion);
    expect(json['gitSha'], BuildInfo.buildGitSha);
    expect(json['schemaVersion'], isA<int>());
    expect(json['catalogVersion'], isA<int>());
  });

  test('conversation revert/unrevert (undo/redo) round-trips over RPC', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_server_revert_e2e');
    // The boot preflight refuses to start without the native libraries;
    // stage whatever this machine has into the data dir (see the helper).
    await stageServerNatives(tmp.path);
    addTearDown(() => tmp.deleteSync(recursive: true));

    const deviceId = 'web-test-device';
    const psk = 'test-psk-please-and-thank-you-0123456789';
    const workspaceId = 'ws-alpha';

    // Seed a workspace + a channel with three messages.
    final seed = openSeedDatabases(tmp.path);
    await seed.global.workspaceRegistryDao.upsertWorkspace(
      const WorkspacesTableCompanion(
        id: Value(workspaceId),
        name: Value('Alpha'),
      ),
    );
    final messaging = DaoMessagingRepository(seed.workspaces);
    final channel = await messaging.createChannel(
      workspaceId,
      'Build',
      const [],
    );
    for (final id in ['m1', 'm2', 'm3']) {
      await messaging.sendMessage(
        workspaceId: workspaceId,
        channelId: channel.id,
        content: id,
        senderId: 'user',
        senderType: 'user',
        id: id,
      );
    }
    await seed.global.pairedDeviceDao.upsert(
      const PairedDevicesTableCompanion(
        id: Value(deviceId),
        workspaceId: Value(workspaceId),
        label: Value('e2e'),
        pskRef: Value('file'),
        status: Value(PairedDeviceStatus.active),
      ),
    );
    await seed.close();
    await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);

    final client = await connectRemoteRpc(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: deviceId,
      psk: psk,
    );
    addTearDown(client.close);
    await client.initialize();
    client.activeWorkspaceId = workspaceId;

    Future<List<String>> liveMessageIds() async {
      final data = await client.call('messaging.getMessages', {
        'channel_id': channel.id,
      });
      return [
        for (final m in (data['messages'] as List).cast<Map<String, dynamic>>())
          m['id'] as String,
      ];
    }

    expect(await liveMessageIds(), ['m1', 'm2', 'm3']);

    // Revert to just after m1: m2 + m3 are hidden. No agent worktree resolves,
    // so the filesystem rollback is a graceful no-op (transcript revert holds).
    final reverted = await client.call('messaging.revertConversationTo', {
      'channel_id': channel.id,
      'message_id': 'm1',
    });
    expect((reverted['affected_message_ids'] as List).cast<String>(), [
      'm2',
      'm3',
    ]);
    expect(reverted['filesystem_restored'], isFalse);
    expect(await liveMessageIds(), ['m1']);

    // Undo the revert: m2 + m3 reappear.
    final restored = await client.call('messaging.unrevertConversation', {
      'channel_id': channel.id,
    });
    expect((restored['affected_message_ids'] as List).cast<String>(), [
      'm2',
      'm3',
    ]);
    expect(await liveMessageIds(), ['m1', 'm2', 'm3']);
  });

  test(
    'an active device with no stored PSK is rejected fast with a clear message',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_denied_e2e');
      // The boot preflight refuses to start without the native libraries;
      // stage whatever this machine has into the data dir (see the helper).
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'unpaired-device';
      const workspaceId = 'ws-alpha';

      // Seed an ACTIVE device row but never write its PSK — exactly the server's
      // "row=active, psk=missing" state (a device that was registered but never
      // had a pairing key minted/stored for it).
      final seed = openSeedDatabases(tmp.path);
      await seed.global.workspaceRegistryDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Alpha'),
        ),
      );
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(workspaceId),
          label: Value('unpaired'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      // The client must fail fast with the explicit "rejected" message (via the
      // server's `auth_denied` frame), NOT stall until the handshake timeout and
      // surface an opaque "Server did not complete auth".
      await expectLater(
        connectRemoteRpc(
          uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
          deviceId: deviceId,
          psk: 'whatever-the-user-typed-0123456789',
          timeout: const Duration(seconds: 5),
        ),
        throwsA(
          isA<AuthRejectedException>().having(
            (e) => e.message,
            'message',
            contains('rejected'),
          ),
        ),
      );
    },
  );

  test('a fullClient mints a pairing and a SECOND client connects with it; a '
      'phone-tier device is denied pairing.mint (capability gate)', () async {
    final tmp = Directory.systemTemp.createTempSync('cc_server_pair_e2e');
    // The boot preflight refuses to start without the native libraries;
    // stage whatever this machine has into the data dir (see the helper).
    await stageServerNatives(tmp.path);
    addTearDown(() => tmp.deleteSync(recursive: true));

    const adminId = 'web-admin';
    const adminPsk = 'admin-psk-please-and-thank-you-0123456789';
    const phoneId = 'phone-device';
    const phonePsk = 'phone-psk-please-and-thank-you-0123456789';
    const workspaceId = 'ws-alpha';

    final seed = openSeedDatabases(tmp.path);
    await seed.global.workspaceRegistryDao.upsertWorkspace(
      const WorkspacesTableCompanion(
        id: Value(workspaceId),
        name: Value('Alpha'),
      ),
    );
    // A first-party web client (platform 'web' → fullClient) ...
    await seed.global.pairedDeviceDao.upsert(
      const PairedDevicesTableCompanion(
        id: Value(adminId),
        workspaceId: Value(workspaceId),
        label: Value('admin'),
        platform: Value('web'),
        pskRef: Value('file'),
        status: Value(PairedDeviceStatus.active),
      ),
    );
    // ... and a phone (platform 'ios' → restricted).
    await seed.global.pairedDeviceDao.upsert(
      const PairedDevicesTableCompanion(
        id: Value(phoneId),
        workspaceId: Value(workspaceId),
        label: Value('phone'),
        platform: Value('ios'),
        pskRef: Value('file'),
        status: Value(PairedDeviceStatus.active),
      ),
    );
    await seed.close();
    final secrets = FileSecretsStore(dataDir: tmp.path);
    await secrets.writePsk(adminId, adminPsk);
    await secrets.writePsk(phoneId, phonePsk);

    final server = await runCcServer(
      args: ['--data-dir', tmp.path, '--port', '0'],
    );
    addTearDown(server.shutdown);
    final url = Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc');

    // The fullClient mints a pairing for a NEW desktop client.
    final admin = await connectRemoteRpc(
      uri: url,
      deviceId: adminId,
      psk: adminPsk,
    );
    addTearDown(admin.close);
    await admin.initialize();
    admin.activeWorkspaceId = workspaceId;

    final minted = await admin.call('pairing.mint', {
      'label': 'New laptop',
      'platform': 'desktop',
    });
    final newDeviceId = minted['device_id'] as String;
    final newPsk = minted['psk'] as String;
    expect(newDeviceId, isNotEmpty);
    expect(newPsk, isNotEmpty);
    expect(minted['platform'], 'desktop');

    // The newly-paired client connects to the SAME running server and drives
    // a working session.
    final second = await connectRemoteRpc(
      uri: url,
      deviceId: newDeviceId,
      psk: newPsk,
    );
    addTearDown(second.close);
    await second.initialize();
    second.activeWorkspaceId = workspaceId;
    final listed = await second.call('pairing.list', const {});
    final ids = (listed['devices'] as List)
        .map((d) => (d as Map)['device_id'])
        .toSet();
    expect(ids, containsAll(<String>[adminId, phoneId, newDeviceId]));

    // The phone (restricted) is DENIED pairing.mint by the capability gate,
    // even though it authenticated and is bound to a workspace.
    final phone = await connectRemoteRpc(
      uri: url,
      deviceId: phoneId,
      psk: phonePsk,
    );
    addTearDown(phone.close);
    await phone.initialize();
    phone.activeWorkspaceId = workspaceId;
    await expectLater(
      phone.call('pairing.mint', {'label': 'sneaky'}),
      throwsA(
        isA<RemoteRpcException>().having(
          (e) => e.code,
          'code',
          RpcErrorCodes.unauthorized,
        ),
      ),
    );
  });

  test(
    'image proxy gates: rejects missing params, bad signatures and SSRF targets',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_proxy_e2e');
      // The boot preflight refuses to start without the native libraries;
      // stage whatever this machine has into the data dir (see the helper).
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'web-proxy-device';
      const psk = 'proxy-psk-please-and-thank-you-0123456789';
      const workspaceId = 'ws-alpha';

      final seed = openSeedDatabases(tmp.path);
      await seed.global.workspaceRegistryDao.upsertWorkspace(
        const WorkspacesTableCompanion(
          id: Value(workspaceId),
          name: Value('Alpha'),
        ),
      );
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(workspaceId),
          label: Value('proxy'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final base = 'http://127.0.0.1:${server.rpc.boundPort}';
      final http = HttpClient();
      addTearDown(() => http.close(force: true));

      Future<int> statusOf(Uri uri) async {
        final resp = await (await http.getUrl(uri)).close();
        await resp.drain<void>();
        return resp.statusCode;
      }

      Uri proxyUri(String target, String signature) => Uri.parse(base).replace(
        path: '/proxy/media',
        queryParameters: {
          'u': base64Url.encode(utf8.encode(target)),
          'd': deviceId,
          's': signature,
        },
      );

      // Missing the required query params → 400.
      expect(await statusOf(Uri.parse('$base/proxy/media')), 400);

      // A well-formed request whose signature does not match the PSK → 403
      // (the endpoint is not an open relay).
      expect(
        await statusOf(
          proxyUri('https://images.example.com/cover.jpg', 'not-the-signature'),
        ),
        403,
      );

      // A correctly-signed request whose TARGET is the cloud-metadata endpoint
      // is refused by the SSRF guard — even though auth passes → 403 and no
      // outbound fetch is made.
      const ssrf = 'http://169.254.169.254/latest/meta-data/';
      expect(
        await statusOf(
          proxyUri(ssrf, RemoteControlCrypto.signProxyTarget(ssrf, psk)),
        ),
        403,
      );
    },
  );

  test(
    'agent_run_log.getTranscript serves a subagent run and refuses a foreign one',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_server_run_tx');
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'tx-test-device';
      const psk = 'test-psk-please-and-thank-you-0123456789';
      const ownWorkspace = 'ws-own';
      const otherWorkspace = 'ws-other';

      final seed = openSeedDatabases(tmp.path);
      for (final ws in [ownWorkspace, otherWorkspace]) {
        await seed.global.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion(id: Value(ws), name: Value(ws)),
        );
      }
      // One subagent run per workspace, each with a recorded transcript, each
      // seeded into ITS OWN workspace's database — a run and its transcript are
      // in the same file and the run log's FK is what forces that.
      for (final (runId, ws) in [
        ('run-own', ownWorkspace),
        ('run-other', otherWorkspace),
      ]) {
        final wsDb = seed.workspaces.of(ws);
        await wsDb
            .into(wsDb.agentsTable)
            .insert(
              AgentsTableCompanion.insert(
                id: 'agent-1',
                name: 'scout',
                title: 'Scout',
                agentMdPath: '/agents/scout.md',
                workspaceId: ws,
                skills: 'dart',
              ),
            );
        await wsDb
            .into(wsDb.agentRunLogsTable)
            .insert(
              AgentRunLogsTableCompanion.insert(
                id: runId,
                agentId: 'agent-1',
                workspaceId: Value(ws),
                startedAt: Value(DateTime.utc(2026, 7, 26)),
                status: const Value('completed'),
                completedAt: Value(DateTime.utc(2026, 7, 26, 0, 1)),
                agentRole: const Value('sub'),
                parentRunId: const Value('run-parent'),
                spawnToolCallId: const Value('call-task-1'),
              ),
            );
        await DaoRunTranscriptRepository(seed.workspaces).upsert(
          runId: runId,
          workspaceId: ws,
          segmentsJson: encodeTranscript([
            ToolSegment(
              toolName: 'Read',
              toolCallId: 'c1',
              outputs: '$ws body',
              status: ToolSegmentStatus.ok,
              startedAt: DateTime.utc(2026, 7, 26),
            ),
          ]),
          transcriptChars: 20,
          startedAt: DateTime.utc(2026, 7, 26),
          updatedAt: DateTime.utc(2026, 7, 26, 0, 1),
          outcome: TurnOutcome.completed,
          complete: true,
        );
      }
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(ownWorkspace),
          label: Value('e2e'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();
      client.activeWorkspaceId = ownWorkspace;

      // The bound workspace's own subagent run reads back in full.
      final data = await client.call('agent_run_log.getTranscript', const {
        'run_id': 'run-own',
      });
      expect(data['run_id'], 'run-own');
      expect(data['complete'], isTrue);
      expect(data['outcome'], 'completed');
      final segments = decodeTranscript(data['segments']);
      expect(segments, hasLength(1));
      expect((segments.single as ToolSegment).outputs, '$ownWorkspace body');

      // A run in another workspace must not surface, even by exact id.
      await expectLater(
        client.call('agent_run_log.getTranscript', const {
          'run_id': 'run-other',
        }),
        throwsA(isA<RemoteRpcException>()),
      );

      // A run that does not exist at all is a not-found, not an empty read.
      await expectLater(
        client.call('agent_run_log.getTranscript', const {
          'run_id': 'run-nope',
        }),
        throwsA(isA<RemoteRpcException>()),
      );
    },
  );

  test(
    'agent_run_log.getTranscript replays a top-level run from its agent_turn '
    'message when no run_transcripts row exists',
    () async {
      // A top-level run is never written to `run_transcripts` — only subagents
      // are. Its timeline lives on the `agent_turn` message the run posts,
      // whose id IS the run log id. While the run streams, the in-memory
      // registry (keyed by that same id) serves it; after a restart the
      // registry is empty and replay must find the message, or the activity tab
      // reads "No activity was recorded for this run" for every finished run.
      final tmp = Directory.systemTemp.createTempSync('cc_server_run_tx_msg');
      await stageServerNatives(tmp.path);
      addTearDown(() => tmp.deleteSync(recursive: true));

      const deviceId = 'tx-msg-device';
      const psk = 'test-psk-please-and-thank-you-0123456789';
      const ownWorkspace = 'ws-own';
      const otherWorkspace = 'ws-other';

      final seed = openSeedDatabases(tmp.path);
      for (final ws in [ownWorkspace, otherWorkspace]) {
        await seed.global.workspaceRegistryDao.upsertWorkspace(
          WorkspacesTableCompanion(id: Value(ws), name: Value(ws)),
        );
      }
      // The rows below belong to the session's own workspace; the other one
      // exists purely so the test can prove a foreign id is refused.
      final wsDb = seed.workspaces.of(ownWorkspace);
      await wsDb
          .into(wsDb.agentsTable)
          .insert(
            AgentsTableCompanion.insert(
              id: 'agent-1',
              name: 'scout',
              title: 'Scout',
              agentMdPath: '/agents/scout.md',
              workspaceId: ownWorkspace,
              skills: 'dart',
            ),
          );

      // One top-level run per workspace. No transcript row for either — the
      // segments ride the message, exactly as MessagingService writes them.
      for (final (runId, ws) in [
        ('top-own', ownWorkspace),
        ('top-other', otherWorkspace),
      ]) {
        final channelId = 'chan-$ws';
        await wsDb
            .into(wsDb.channelsTable)
            .insert(
              ChannelsTableCompanion.insert(
                id: channelId,
                name: 'general',
                workspaceId: Value(ws),
              ),
            );
        await wsDb
            .into(wsDb.conversationsTable)
            .insert(
              ConversationsTableCompanion.insert(
                id: channelId,
                channelId: channelId,
                workspaceId: Value(ws),
              ),
            );
        await wsDb
            .into(wsDb.agentRunLogsTable)
            .insert(
              AgentRunLogsTableCompanion.insert(
                id: runId,
                agentId: 'agent-1',
                workspaceId: Value(ws),
                channelId: Value(channelId),
                conversationId: Value(channelId),
                startedAt: Value(DateTime.utc(2026, 7, 26)),
                status: const Value('completed'),
                completedAt: Value(DateTime.utc(2026, 7, 26, 0, 1)),
              ),
            );
        // `id: runId` is the whole point — the turn message and the run log
        // share one id, which is how replay finds it.
        await wsDb
            .into(wsDb.channelMessagesTable)
            .insert(
              ChannelMessagesTableCompanion.insert(
                id: runId,
                channelId: channelId,
                conversationId: channelId,
                senderId: 'agent-1',
                senderType: 'agent',
                content: '',
                messageType: const Value('agent_turn'),
                metadata: Value(
                  jsonEncode({
                    'agentName': 'scout',
                    'streamComplete': true,
                    'segments': encodeTranscript([
                      ToolSegment(
                        toolName: 'Read',
                        toolCallId: 'c1',
                        outputs: '$ws body',
                        status: ToolSegmentStatus.ok,
                        startedAt: DateTime.utc(2026, 7, 26),
                      ),
                    ]),
                  }),
                ),
              ),
            );
      }
      await seed.global.pairedDeviceDao.upsert(
        const PairedDevicesTableCompanion(
          id: Value(deviceId),
          workspaceId: Value(ownWorkspace),
          label: Value('e2e'),
          pskRef: Value('file'),
          status: Value(PairedDeviceStatus.active),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(deviceId, psk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0'],
      );
      addTearDown(server.shutdown);

      final client = await connectRemoteRpc(
        uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
        deviceId: deviceId,
        psk: psk,
      );
      addTearDown(client.close);
      await client.initialize();
      client.activeWorkspaceId = ownWorkspace;

      final data = await client.call('agent_run_log.getTranscript', const {
        'run_id': 'top-own',
      });
      final segments = decodeTranscript(data['segments']);
      expect(segments, hasLength(1));
      expect((segments.single as ToolSegment).outputs, '$ownWorkspace body');
      // A terminal run with no transcript row still reads as finished, so the
      // client stops showing streaming affordances.
      expect(data['complete'], isTrue);

      // The message-backed path is scoped by the owning channel, so a foreign
      // run stays invisible even though its id is known.
      await expectLater(
        client.call('agent_run_log.getTranscript', const {
          'run_id': 'top-other',
        }),
        throwsA(isA<RemoteRpcException>()),
      );
    },
  );
}
