import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

import 'helpers/best_effort_delete.dart';
import 'helpers/booted_rpc.dart';
import 'helpers/native_staging.dart';
import 'helpers/test_database.dart';

/// Ops that reach the server host, against a booted server.
///
/// - An op that takes a host path from the wire is the server owner's, or
///   what it opens stays inside the workspace's own directory with symlinks
///   resolved. The owner-only refusals run as a workspace admin; the
///   confinement cases run as the server owner, so no authority gate can be
///   what stops them.
/// - The agent process matrix shows and stops only runs of a workspace the
///   caller belongs to (all of them for the owner), and signals no pid that is
///   not a live agent run.
void main() {
  if (!hostHasServerNatives) {
    test(
      'native libraries are staged for server boot',
      () {
        fail(
          'Native libraries not found — run scripts/natives/build_natives.sh. '
          'They are REQUIRED; cc_server refuses to boot without them.',
        );
      },
      skip: skipServerBootWithoutNatives(
        reason: 'Native libraries are not built on CI runners',
      ),
    );
    return;
  }

  late Directory tmp;
  late CcServer server;
  late RemoteRpcClient owner;
  late RemoteRpcClient admin;
  late RemoteRpcClient phone;
  late String workspaceId;
  late String workspaceDir;
  late String secret;

  setUpAll(() async {
    tmp = Directory.systemTemp.createTempSync('cc_host_path_ops');
    await stageServerNatives(tmp.path);
    secret = p.join(tmp.path, 'host-secret.txt');
    File(secret).writeAsStringSync('host secret');

    const ownerDeviceId = 'owner-device';
    final ownerPsk = RemoteControlCrypto.generatePsk();
    const adminDeviceId = 'admin-device';
    final adminPsk = RemoteControlCrypto.generatePsk();
    const phoneDeviceId = 'admin-phone';
    final phonePsk = RemoteControlCrypto.generatePsk();
    final seed = openSeedDatabases(tmp.path);
    final seededOwnerId = await seedServerOwner(seed);
    await seed.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(ownerDeviceId),
        label: const Value('owner'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        userId: Value(seededOwnerId),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    await seed.close();
    final secrets = FileSecretsStore(dataDir: tmp.path);
    await secrets.writePsk(ownerDeviceId, ownerPsk);
    await secrets.writePsk(adminDeviceId, adminPsk);
    await secrets.writePsk(phoneDeviceId, phonePsk);

    server = await runCcServer(args: ['--data-dir', tmp.path, '--port', '0']);
    final uri = Uri.parse('ws://127.0.0.1:${server.rpc.boundPort}/rpc');
    owner = await connectBootedServer(
      uri: uri,
      deviceId: ownerDeviceId,
      psk: ownerPsk,
    );
    await owner.initialize();
    final created = await owner.call('workspace.create', const {
      'name': 'Team',
    });
    workspaceId = (created['workspace'] as Map)['id'] as String;
    workspaceDir = workspaceDirPath(tmp.path, workspaceId);

    // An admin of the workspace who is not the server owner.
    final later = openSeedDatabases(tmp.path);
    await later.global.userDao.upsert(
      const UsersTableCompanion(
        id: Value('user-admin'),
        handle: Value('admin'),
        displayName: Value('Admin'),
      ),
    );
    await later.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(adminDeviceId),
        userId: const Value('user-admin'),
        label: const Value('admin'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    // The same person's companion phone.
    await later.global.pairedDeviceDao.upsert(
      PairedDevicesTableCompanion(
        id: const Value(phoneDeviceId),
        userId: const Value('user-admin'),
        label: const Value('phone'),
        platform: const Value('ios'),
        pskRef: const Value('file'),
        status: const Value(PairedDeviceStatus.active),
        expiresAt: Value(seededDeviceExpiry()),
      ),
    );
    await DaoWorkspaceMembershipRepository(later.workspaces).upsert(
      WorkspaceMember(
        id: 'm-admin',
        workspaceId: workspaceId,
        userId: 'user-admin',
        role: WorkspaceRole.admin,
        joinedAt: DateTime.utc(2026),
      ),
    );
    await later.close();
    admin = await connectBootedServer(
      uri: uri,
      deviceId: adminDeviceId,
      psk: adminPsk,
    );
    await admin.initialize();
    phone = await connectBootedServer(
      uri: uri,
      deviceId: phoneDeviceId,
      psk: phonePsk,
    );
    await phone.initialize();
  });

  tearDownAll(() async {
    await phone.close();
    await admin.close();
    await owner.close();
    await server.shutdown();
    await deleteDirBestEffort(tmp);
  });

  Matcher refused(int code, {String? kind}) => throwsA(
    isA<RemoteRpcException>()
        .having((e) => e.code, 'code', code)
        .having(
          (e) => (e.data as Map?)?['kind'],
          'data.kind',
          kind == null ? anything : equals(kind),
        ),
  );

  test('ops that open a host path the caller names are the server '
      "owner's", () async {
    for (final (op, args) in [
      ('fs.browseDirectory', <String, dynamic>{'path': tmp.path}),
      // Wrapped `fullClientOnly`, which used to drop the declaration.
      ('fs.persistLogo', {'workspace_id': workspaceId, 'source_path': secret}),
      (
        'workspace.import',
        {'workspace_id': workspaceId, 'source_path': secret},
      ),
      ('connectivity.setTunnel', <String, dynamic>{'provider': 'off'}),
    ]) {
      await expectLater(
        admin.call(op, args),
        refused(RpcErrorCodes.unauthorized, kind: 'server_owner_required'),
        reason: op,
      );
    }
    expect(
      Directory(workspaceDir).listSync().map((e) => p.basename(e.path)),
      isNot(contains(startsWith('logo'))),
    );
  });

  test(
    'a logo extension cannot carry the write out of the workspace',
    () async {
      final bytes = base64Encode(utf8.encode('png'));
      await expectLater(
        owner.call('fs.persistLogoBytes', {
          'workspace_id': workspaceId,
          'bytes': bytes,
          'extension': '/../../escaped',
        }),
        refused(RpcErrorCodes.validation),
      );
      expect(File(p.join(tmp.path, 'escaped')).existsSync(), isFalse);
    },
  );

  test("a workspace's logo is only its own logo file, and the logo route "
      'serves nothing else', () async {
    final persisted =
        (await owner.call('fs.persistLogoBytes', {
              'workspace_id': workspaceId,
              'bytes': base64Encode(utf8.encode('png')),
              'extension': '.png',
            }))['path']
            as String;
    await expectLater(
      admin.call('workspace.upsert', {
        'workspace': {'id': workspaceId, 'name': 'Team', 'logo_path': secret},
      }),
      refused(RpcErrorCodes.validation),
    );
    await admin.call('workspace.upsert', {
      'workspace': {'id': workspaceId, 'name': 'Team', 'logo_path': persisted},
    });
    expect(
      (await owner.call('workspace.logo', {
        'workspace_id': workspaceId,
      }))['bytes'],
      isNotNull,
    );

    // A path stored before this rule, written straight to the row.
    final seed = openSeedDatabases(tmp.path);
    final workspaces = DaoWorkspaceRepository(
      seed.global.workspaceRegistryDao,
      seed.workspaces,
    );
    final stored = (await workspaces.getById(workspaceId))!;
    await workspaces.upsert(stored.copyWith(logoPath: secret));
    await seed.close();
    expect(
      (await owner.call('workspace.logo', {
        'workspace_id': workspaceId,
      }))['bytes'],
      isNull,
    );
  });

  test(
    "an agent's file moves only to the one the server keeps for its name",
    () async {
      final agent =
          ((await owner.call('agents.create', {
                    'workspace_id': workspaceId,
                    'name': 'Coder',
                    'title': 'Engineer',
                  }))
                  as Map)['agent']
              as Map<String, dynamic>;
      await expectLater(
        owner.call('agents.upsert', {
          'workspace_id': workspaceId,
          'agent': {...agent, 'agent_md_path': p.join(tmp.path, 'AGENTS.md')},
        }),
        refused(RpcErrorCodes.validation),
      );
      await owner.call('agents.upsert', {
        'workspace_id': workspaceId,
        'agent': {...agent, 'title': 'Staff engineer'},
      });
    },
  );

  test('no op writes a worktree row, whose paths release destroys', () async {
    await expectLater(
      owner.call('isolated_repo.upsert', {
        'workspace_id': workspaceId,
        'repo': {
          'id': 'iso-1',
          'workspace_id': workspaceId,
          'space_id': 'sp',
          'repo_id': 'r',
          'path': tmp.path,
          'source_path': tmp.path,
        },
      }),
      throwsA(isA<RemoteRpcException>()),
    );
  });

  test('the run viewer never opens a log path a caller wrote', () async {
    final foreign = p.join(tmp.path, 'foreign.ndjson');
    File(foreign).writeAsStringSync('{"type":"stolen"}\n');
    final agent =
        (await owner.call('agents.create', {
              'workspace_id': workspaceId,
              'name': 'Runner',
              'title': 'Engineer',
            }))['agent']
            as Map;
    await owner.call('agent_run_log.upsert', {
      'workspace_id': workspaceId,
      'log': {
        'id': 'run-1',
        'agent_id': agent['id'],
        'workspace_id': workspaceId,
        'started_at': DateTime.utc(2026).toIso8601String(),
        'status': 'running',
        'log_path': foreign,
      },
    });
    await owner.call('agent_run_log.updateRuntime', {
      'workspace_id': workspaceId,
      'run_id': 'run-1',
      'log_path': foreign,
    });
    final stored = await owner.call('agent_run_log.get', {
      'workspace_id': workspaceId,
      'id': 'run-1',
    });
    expect((stored['log'] as Map).containsKey('log_path'), isFalse);
    final events = await owner.call('agent_run_log.readEvents', {
      'workspace_id': workspaceId,
      'run_id': 'run-1',
    });
    expect(events['events'], isEmpty);
  });

  test('fs.writeString does not follow a link out of the workspace', () async {
    final outside = Directory(p.join(tmp.path, 'outside'))..createSync();
    Link(p.join(workspaceDir, 'link')).createSync(outside.path);
    await expectLater(
      owner.call('fs.writeString', {
        'workspace_id': workspaceId,
        'path': p.join(workspaceDir, 'link', 'pwn.txt'),
        'content': 'x',
      }),
      refused(RpcErrorCodes.workspaceMismatch),
    );
    expect(File(p.join(outside.path, 'pwn.txt')).existsSync(), isFalse);
  });
  group('agent processes', skip: Platform.isWindows ? 'POSIX kill' : false, () {
    final children = <Process>[];
    tearDownAll(() {
      for (final child in children) {
        child.kill(ProcessSignal.sigkill);
      }
    });

    bool alive(int pid) =>
        Process.runSync('kill', ['-0', '$pid']).exitCode == 0;

    // A live running agent run in [workspace], backed by a real process.
    Future<Process> runIn(String workspace, String agentName) async {
      final child = await Process.start('sleep', ['300']);
      children.add(child);
      final agent =
          (await owner.call('agents.create', {
                'workspace_id': workspace,
                'name': agentName,
                'title': 'Engineer',
              }))['agent']
              as Map;
      await owner.call('agent_run_log.upsert', {
        'workspace_id': workspace,
        'log': {
          'id': 'run-$agentName',
          'agent_id': agent['id'],
          'workspace_id': workspace,
          'started_at': DateTime.now().toUtc().toIso8601String(),
          'status': 'running',
          'pid': child.pid,
        },
      });
      return child;
    }

    Future<Set<int>> detected(RemoteRpcClient client) async {
      final found = await client.call('process.detect', const {});
      return {
        for (final p in found['processes'] as List) (p as Map)['pid'] as int,
      };
    }

    test('a member sees and stops only runs of their own workspace; the '
        'owner sees and stops all; no other pid is signalled', () async {
      final other =
          ((await owner.call('workspace.create', const {
                    'name': 'Other',
                  }))['workspace']
                  as Map)['id']
              as String;
      final mine = await runIn(workspaceId, 'MineRunner');
      final theirs = await runIn(other, 'TheirRunner');

      expect(await detected(admin), contains(mine.pid));
      expect(await detected(admin), isNot(contains(theirs.pid)));
      expect(await detected(owner), containsAll([mine.pid, theirs.pid]));

      // Not theirs, and not an agent run at all, answer the same way.
      for (final target in [theirs.pid, pid]) {
        await expectLater(
          admin.call('process.kill', {'pid': target}),
          refused(RpcErrorCodes.notFound),
        );
      }
      expect(alive(theirs.pid), isTrue);
      expect(alive(pid), isTrue);

      // A companion phone reaches neither op, even for its own workspace.
      for (final (op, args) in [
        ('process.detect', <String, dynamic>{}),
        ('process.kill', <String, dynamic>{'pid': mine.pid}),
      ]) {
        await expectLater(
          phone.call(op, args),
          refused(RpcErrorCodes.unauthorized),
          reason: op,
        );
      }
      expect(alive(mine.pid), isTrue);

      await admin.call('process.kill', {'pid': mine.pid});
      await mine.exitCode.timeout(const Duration(seconds: 10));
      await owner.call('process.kill', {'pid': theirs.pid});
      await theirs.exitCode.timeout(const Duration(seconds: 10));
    });
  });
}
