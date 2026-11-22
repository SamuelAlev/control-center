import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show CodeExecutionPageDto, CodeModeStatusDto, RpcErrorCodes;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import '../helpers/best_effort_delete.dart';
import '../helpers/booted_rpc.dart';
import '../helpers/native_staging.dart';
import '../helpers/test_database.dart';

/// Code mode on a booted server: the runtime builds the runner, its self-test
/// decides availability, `codeMode.*` answers over the wire, and the generic
/// settings op refuses code mode's keys. There is no setting that turns
/// scripts on or off: a run has `repl` exactly when the runner passed.
///
/// The runner comes from `CC_CODEMODE_RUNNER` (an absolute path to a built
/// `cc_codemode`) or a staged `build/natives/codemode/`; without either the
/// server refuses to boot, which is the point of the preflight.
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

  const workspaceId = 'ws-code';
  const ownerDevice = 'owner-device';

  Future<RemoteRpcClient> boot(List<String> extraArgs) async {
    final tmp = Directory.systemTemp.createTempSync('cc_code_mode_boot');
    await stageServerNatives(tmp.path);
    addTearDown(() => deleteDirBestEffort(tmp));
    final psk = RemoteControlCrypto.generatePsk();

    final seed = openSeedDatabases(tmp.path);
    final ownerId = await seedServerOwner(seed);
    await seed.global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion(
        id: const Value(workspaceId),
        name: const Value('Code'),
        ownerUserId: Value(ownerId),
      ),
    );
    await seed.workspaces
        .of(workspaceId)
        .workspaceMemberDao
        .upsert(
          WorkspaceMembersTableCompanion(
            id: const Value('m-owner'),
            workspaceId: const Value(workspaceId),
            userId: Value(ownerId),
            role: const Value('owner'),
          ),
        );
    await seed.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(ownerDevice),
        landingWorkspaceId: const Value(workspaceId),
        label: const Value('owner'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        userId: Value(ownerId),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    await seed.close();
    await FileSecretsStore(dataDir: tmp.path).writePsk(ownerDevice, psk);

    final server = await runCcServer(
      args: [
        '--data-dir',
        tmp.path,
        '--port',
        '0',
        '--code-index',
        'off',
        // Keeps the booted server off the hosted relay and the local network.
        '--signaling-url',
        'ws://127.0.0.1:9',
        '--mdns',
        'off',
        ...extraArgs,
      ],
    );
    addTearDown(server.shutdown);
    final client = await connectBootedServer(
      uri: Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc'),
      deviceId: ownerDevice,
      psk: psk,
    );
    addTearDown(client.close);
    await client.initialize();
    return client;
  }

  Future<CodeModeStatusDto> status(RemoteRpcClient client) async {
    final data = await client.call('codeMode.status', {
      'workspace_id': workspaceId,
    });
    return CodeModeStatusDto.fromJson(
      (data['status'] as Map).cast<String, dynamic>(),
    );
  }

  Matcher refusedWith(int code, String kind) => isA<RemoteRpcException>()
      .having((e) => e.code, 'code', code)
      .having((e) => (e.data as Map?)?['kind'], 'kind', kind);

  test('the runner passes its self-test, and the only workspace setting is the '
      'limits', () async {
    final client = await boot(const []);

    final before = await status(client);
    expect(before.available, isTrue, reason: before.reason);
    expect(before.runnerVersion, startsWith('cc_codemode '));
    expect(before.maxProcesses, greaterThanOrEqualTo(1));

    // The generic settings op stores raw values; code mode's limits only
    // go through the op that checks them.
    await expectLater(
      client.call('workspace_settings.set', {
        'workspace_id': workspaceId,
        'key': 'code_mode_limits',
        'value': '{}',
      }),
      throwsA(
        refusedWith(RpcErrorCodes.validation, 'code_mode_setting_reserved'),
      ),
    );
    // The mode key is gone: the op names the one key it takes.
    await expectLater(
      client.call('codeMode.setWorkspaceSetting', {
        'workspace_id': workspaceId,
        'key': 'code_mode',
        'value': 'hybrid',
      }),
      throwsA(
        refusedWith(RpcErrorCodes.validation, 'code_mode_unknown_setting'),
      ),
    );

    final page = CodeExecutionPageDto.fromJson(
      await client.call('codeMode.listExecutions', {
        'workspace_id': workspaceId,
      }),
    );
    expect(page.items, isEmpty);
    await expectLater(
      client.call('codeMode.getExecution', {
        'workspace_id': workspaceId,
        'id': 'run-1/call_1',
      }),
      throwsA(
        isA<RemoteRpcException>().having(
          (e) => e.code,
          'code',
          RpcErrorCodes.notFound,
        ),
      ),
    );
  }, timeout: const Timeout(Duration(minutes: 3)));
}
