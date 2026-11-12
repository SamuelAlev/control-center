import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';
import 'helpers/booted_rpc.dart';
import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// The four CROSS-WORKSPACE BY DESIGN lookups are unscoped, so the
/// dispatcher's membership gate never runs for them. Each row they return
/// carries its own workspace; a caller who is not a member of it must not
/// receive it. Before the per-row filter, any signed-in guest could list
/// every workspace's approved orchestrations and worktree rows.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () => fail('run scripts/natives/build_natives.sh'),
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  test(
    'cross-workspace lookups return only the caller\'s workspaces',
    () async {
      final tmp = Directory.systemTemp.createTempSync('cc_cross_ws_lookup');
      await stageServerNatives(tmp.path);
      addTearDown(() => deleteDirBestEffort(tmp));

      const ownerDevice = 'owner-device';
      final ownerPsk = RemoteControlCrypto.generatePsk();
      const workspaceId = 'ws-private';
      final now = DateTime.utc(2026, 11);
      const proposal = OrchestrationProposal(
        goal: 'Private plan',
        roles: [],
        subTickets: [],
        synthesis: SynthesisSpec(
          roleKey: 'lead',
          prompt: 'Wrap up',
          outputSchema: {},
        ),
      );

      final seed = openSeedDatabases(tmp.path);
      final seededOwnerId = await seedServerOwner(seed);
      await seed.global.workspaceRegistryDao.upsertWorkspace(
        WorkspacesTableCompanion(
          id: const Value(workspaceId),
          name: const Value('Private'),
          ownerUserId: Value(seededOwnerId),
        ),
      );
      await seed.workspaces
          .of(workspaceId)
          .workspaceMemberDao
          .upsert(
            WorkspaceMembersTableCompanion(
              id: const Value('m-owner'),
              workspaceId: const Value(workspaceId),
              userId: Value(seededOwnerId),
              role: const Value('owner'),
            ),
          );
      // The run the executing orchestration points at.
      await seed.workspaces.of(workspaceId).customStatement(
        'INSERT INTO pipeline_runs (id, template_id, workspace_id) '
        'VALUES (?, ?, ?)',
        ['run-private', 'template', workspaceId],
      );
      final orchestrations = DaoOrchestrationRepository(seed.workspaces);
      await orchestrations.insert(
        Orchestration(
          id: 'orch-approved',
          workspaceId: workspaceId,
          proposal: proposal,
          status: OrchestrationStatus.approved,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await orchestrations.insert(
        Orchestration(
          id: 'orch-running',
          workspaceId: workspaceId,
          proposal: proposal,
          status: OrchestrationStatus.executing,
          pipelineRunId: 'run-private',
          createdAt: now,
          updatedAt: now,
        ),
      );
      // The worktree row's parent: a plain empty directory, not a checkout.
      final source = Directory('${tmp.path}/private-source')..createSync();
      await DaoRepoRepository(seed.workspaces).upsert(
        workspaceId,
        Repo(
          id: 'repo-private',
          name: 'acme/private',
          path: source.path,
          remoteOwner: 'acme',
          remoteName: 'private',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await seed.workspaces.of(workspaceId).customStatement(
        'INSERT INTO tickets (id, workspace_id, title) VALUES (?, ?, ?)',
        ['ticket-private', workspaceId, 'Private ticket'],
      );
      await DaoIsolatedRepoRepository(seed.workspaces).upsert(
        IsolatedRepo(
          id: 'iso-private',
          workspaceId: workspaceId,
          spaceId: 'space-private',
          repoId: 'repo-private',
          path: '/srv/private/worktree',
          branch: 'main',
          backend: RepoIsolationBackend.rift,
          sourcePath: '/srv/private/source',
          ticketId: 'ticket-private',
          createdAt: now,
        ),
      );
      await seed.global.pairedDeviceDao.upsert(
        PairedDevicesTableCompanion(
          id: const Value(ownerDevice),
          landingWorkspaceId: const Value(workspaceId),
          label: const Value('owner'),
          pskRef: const Value('file'),
          status: const Value(PairedDeviceStatus.active),
          userId: Value(seededOwnerId),
          expiresAt: Value(seededDeviceExpiry()),
        ),
      );
      await seed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(ownerDevice, ownerPsk);

      final server = await runCcServer(
        args: ['--data-dir', tmp.path, '--port', '0', '--code-index', 'off'],
      );
      addTearDown(server.shutdown);
      final uri = Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc');

      // A second account with no membership in the private workspace, added
      // after boot.
      const guestDevice = 'guest-device';
      final guestPsk = RemoteControlCrypto.generatePsk();
      final guestSeed = openSeedDatabases(tmp.path);
      await guestSeed.global.userDao.upsert(
        const UsersTableCompanion(
          id: Value('user-guest'),
          handle: Value('guest'),
          displayName: Value('Guest'),
        ),
      );
      await guestSeed.global.pairedDeviceDao.upsert(
        PairedDevicesTableCompanion(
          id: const Value(guestDevice),
          userId: const Value('user-guest'),
          label: const Value('guest'),
          pskRef: const Value('file'),
          status: const Value(PairedDeviceStatus.active),
          expiresAt: Value(seededDeviceExpiry()),
        ),
      );
      await guestSeed.close();
      await FileSecretsStore(dataDir: tmp.path).writePsk(guestDevice, guestPsk);

      Future<Map<String, Object?>> lookups(RemoteRpcClient client) async => {
        'approved': await client.call(
          'orchestration.approvedNeedingMaterialization',
          const {},
        ),
        'byRun': await client.call('orchestration.forPipelineRunAnyWorkspace', {
          'pipeline_run_id': 'run-private',
        }),
        'bySpace': await client.call('isolated_repo.forSpaceAcrossWorkspaces', {
          'space_id': 'space-private',
        }),
        'byTicket': await client.call(
          'isolated_repo.forTicketAcrossWorkspaces',
          {'ticket_id': 'ticket-private'},
        ),
      };

      final owner = await connectBootedServer(
        uri: uri,
        deviceId: ownerDevice,
        psk: ownerPsk,
      );
      addTearDown(owner.close);
      await owner.initialize();
      final mine = await lookups(owner);
      // Positive control: a member still finds its own rows.
      expect((mine['approved']! as Map)['orchestrations'], hasLength(1));
      expect((mine['byRun']! as Map)['orchestration'], isNotNull);
      expect((mine['bySpace']! as Map)['repos'], hasLength(1));
      expect((mine['byTicket']! as Map)['repos'], hasLength(1));

      final guest = await connectBootedServer(
        uri: uri,
        deviceId: guestDevice,
        psk: guestPsk,
      );
      addTearDown(guest.close);
      await guest.initialize();
      final theirs = await lookups(guest);
      expect(
        (theirs['approved']! as Map)['orchestrations'],
        isEmpty,
        reason: 'a non-member must not list another workspace\'s plans',
      );
      expect((theirs['byRun']! as Map)['orchestration'], isNull);
      expect(
        (theirs['bySpace']! as Map)['repos'],
        isEmpty,
        reason: 'worktree paths of a foreign workspace stay hidden',
      );
      expect((theirs['byTicket']! as Map)['repos'], isEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
