import 'dart:async';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart'
    show AuthException, ValidationException;
import 'package:cc_domain/core/domain/entities/git_repo_info.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace_member.dart';
import 'package:cc_domain/core/domain/ports/git_repo_inspector_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_membership_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/testing/fake_repo_repository.dart';
import 'package:cc_host/cc_host.dart' show RepoOp, RepoOpContext;
import 'package:cc_server_core/src/catalog/catalog_wire.dart' show repoToWire;
import 'package:cc_server_core/src/catalog/granted_repos.dart';
import 'package:cc_server_core/src/catalog/repo_link_ops.dart';
import 'package:cc_server_core/src/repo_path_guard.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A repository's local path is part of its link: only an admin links one,
/// the path must lie in the workspace's own storage (anywhere else on the
/// host only from the server owner), never in the data dir, and a forge
/// checkout's `origin` must be the stored repository. Readers serve only
/// rows that still pass, whenever they were stored.
void main() {
  late Directory root;
  late String dataDir;
  late String wsDir;
  late String otherWsDir;
  late String hostCheckout;
  late FakeRepoRepository repos;
  late _Inspector inspector;
  late RepoPathGuard guard;
  late Map<String, RepoOp> ops;

  const owner = 'u-owner';
  const ada = 'u-ada';
  const mo = 'u-mo';

  String dir(String path) {
    Directory(path).createSync(recursive: true);
    return path;
  }

  setUp(() {
    root = Directory(
      Directory.systemTemp
          .createTempSync('cc_repo_path_')
          .resolveSymbolicLinksSync(),
    );
    addTearDown(() => root.deleteSync(recursive: true));
    dataDir = dir(p.join(root.path, 'data'));
    wsDir = dir(p.join(dataDir, 'ws-a'));
    otherWsDir = dir(p.join(dataDir, 'ws-b'));
    hostCheckout = dir(p.join(root.path, 'host', 'api'));
    repos = FakeRepoRepository();
    inspector = _Inspector();
    guard = RepoPathGuard(
      dataDir: dataDir,
      workspaceDir: (ws) async => p.join(dataDir, ws),
      serverOwnerUserId: owner,
    );
    ops = {
      for (final op in buildRepoLinkOps(
        repos: repos,
        requireRepoRead:
            ({required workspaceId, required userId, required repoId}) async {},
        members: null,
        pathGuard: guard,
        inspector: inspector,
      ))
        op.name: op,
    };
  });

  Repo repo(
    String path, {
    String id = 'r1',
    String remoteOwner = 'acme',
    String remoteName = 'api',
    String linkedBy = '',
  }) => Repo(
    id: id,
    name: 'acme/api',
    path: path,
    remoteOwner: remoteOwner,
    remoteName: remoteName,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    linkedBy: linkedBy,
  );

  Future<Map<String, dynamic>> call(
    String op,
    String userId,
    WorkspaceRole role,
    Map<String, dynamic> args,
  ) => ops[op]!.handler(
    RepoOpContext(
      args: args,
      workspaceId: 'ws-a',
      deviceId: 'd',
      userId: userId,
      role: role,
    ),
  );

  Future<Map<String, dynamic>> upsert(
    String userId,
    WorkspaceRole role,
    Repo r,
  ) => call('repos.upsert', userId, role, {'repo': repoToWire(r)});

  Matcher refused(RepoPathRefusal reason) =>
      throwsA(isA<RepoPathRefused>().having((e) => e.reason, 'reason', reason));

  group('linking', () {
    test('an admin links a checkout in the workspace storage, recorded as '
        'theirs', () async {
      final path = dir(p.join(wsDir, 'repos', 'api'));
      inspector.origins[path] = ('acme', 'api');
      await upsert(ada, WorkspaceRole.admin, repo(path));
      final stored = (await repos.getById('ws-a', 'r1'))!;
      expect(stored.path, path);
      expect(stored.linkedBy, ada);
    });

    test('a member cannot change a path, nor link one', () async {
      final path = dir(p.join(wsDir, 'repos', 'api'));
      final moved = dir(p.join(wsDir, 'repos', 'moved'));
      inspector.origins[path] = ('acme', 'api');
      inspector.origins[moved] = ('acme', 'api');
      await expectLater(
        upsert(mo, WorkspaceRole.member, repo(path)),
        throwsA(isA<AuthException>()),
      );
      repos.seed('ws-a', [repo(path, linkedBy: ada)]);
      await expectLater(
        upsert(mo, WorkspaceRole.member, repo(moved)),
        throwsA(isA<AuthException>()),
      );
      expect((await repos.getById('ws-a', 'r1'))!.path, path);
    });

    test('a rename keeps the link and its linker', () async {
      final path = dir(p.join(wsDir, 'repos', 'api'));
      repos.seed('ws-a', [repo(path, linkedBy: ada)]);
      await upsert(
        mo,
        WorkspaceRole.member,
        repo(path).copyWith(name: 'API service'),
      );
      final stored = (await repos.getById('ws-a', 'r1'))!;
      expect(stored.name, 'API service');
      expect(stored.linkedBy, ada);
    });

    test('a member cannot strip the forge remote of a linked repository, and '
        'a rename keeps every field but the name', () async {
      final path = dir(p.join(wsDir, 'repos', 'api'));
      final linked = repo(path, linkedBy: ada).copyWith(forgeRepoId: '7');
      repos.seed('ws-a', [linked]);
      for (final role in [WorkspaceRole.member, WorkspaceRole.admin]) {
        await expectLater(
          upsert(
            role == WorkspaceRole.admin ? ada : mo,
            role,
            repo(path, remoteOwner: '', remoteName: '', linkedBy: mo),
          ),
          throwsA(
            isA<ValidationException>().having(
              (e) => e.code,
              'code',
              'repo_link.forge_remote_required',
            ),
          ),
        );
      }
      // The wire's linker, pin and timestamps are ignored on a rename.
      await upsert(
        mo,
        WorkspaceRole.member,
        repo(path, linkedBy: mo).copyWith(
          name: 'API',
          remoteOwner: 'ACME',
          forgeRepoId: '666',
          createdAt: DateTime.utc(1999),
        ),
      );
      final stored = (await repos.getById('ws-a', 'r1'))!;
      expect(stored.name, 'API');
      expect(stored.path, path);
      expect(stored.remoteOwner, 'acme');
      expect(stored.remoteName, 'api');
      expect(stored.hasForgeRemote, isTrue);
      expect(stored.linkedBy, ada);
      expect(stored.forgeRepoId, '7');
      expect(stored.createdAt, DateTime.utc(2026));
    });

    test('a repository without a forge remote needs an admin too', () async {
      final path = dir(p.join(wsDir, 'notes'));
      await expectLater(
        upsert(
          mo,
          WorkspaceRole.member,
          repo(path, remoteOwner: '', remoteName: ''),
        ),
        throwsA(isA<AuthException>()),
      );
      await upsert(
        ada,
        WorkspaceRole.admin,
        repo(path, remoteOwner: '', remoteName: ''),
      );
      expect(await repos.exists('ws-a', 'r1'), isTrue);
    });

    test('a path in the data dir, in another workspace, or holding the data '
        'dir is refused, even for the owner', () async {
      for (final path in [
        dir(p.join(dataDir, 'secrets')),
        dir(p.join(otherWsDir, 'repos', 'api')),
        otherWsDir,
        dataDir,
        root.path,
      ]) {
        await expectLater(
          upsert(owner, WorkspaceRole.owner, repo(path)),
          refused(RepoPathRefusal.dataDir),
          reason: path,
        );
      }
      await expectLater(
        upsert(owner, WorkspaceRole.owner, repo(wsDir)),
        refused(RepoPathRefusal.workspaceRoot),
      );
      expect(await repos.getAll('ws-a'), isEmpty);
    });

    test(
      'a symlink in the workspace storage into the data dir is refused',
      () async {
        final link = p.join(wsDir, 'repos', 'sneaky');
        Directory(p.dirname(link)).createSync(recursive: true);
        Link(link).createSync(otherWsDir);
        await expectLater(
          upsert(ada, WorkspaceRole.admin, repo(link)),
          refused(RepoPathRefusal.dataDir),
        );
        final toHost = p.join(wsDir, 'repos', 'to-host');
        Link(toHost).createSync(hostCheckout);
        await expectLater(
          upsert(ada, WorkspaceRole.admin, repo(toHost)),
          refused(RepoPathRefusal.hostPath),
        );
      },
    );

    test('a checkout elsewhere on the host is linked only by the server '
        'owner', () async {
      inspector.origins[hostCheckout] = ('acme', 'api');
      await expectLater(
        upsert(ada, WorkspaceRole.admin, repo(hostCheckout)),
        refused(RepoPathRefusal.hostPath),
      );
      await upsert(owner, WorkspaceRole.owner, repo(hostCheckout));
      expect((await repos.getById('ws-a', 'r1'))!.linkedBy, owner);
    });

    test('a path that does not exist is refused', () async {
      await expectLater(
        upsert(owner, WorkspaceRole.owner, repo(p.join(wsDir, 'nope'))),
        refused(RepoPathRefusal.missing),
      );
    });

    test(
      'a forge checkout whose origin is another repository is refused',
      () async {
        final path = dir(p.join(wsDir, 'repos', 'api'));
        inspector.origins[path] = ('evil', 'api');
        await expectLater(
          upsert(ada, WorkspaceRole.admin, repo(path)),
          refused(RepoPathRefusal.originMismatch),
        );
        inspector.origins[path] = ('ACME', 'API');
        await upsert(ada, WorkspaceRole.admin, repo(path));
      },
    );

    test('addFromPath checks the path before inspecting it', () async {
      await expectLater(
        call('repos.addFromPath', ada, WorkspaceRole.admin, {
          'path': hostCheckout,
        }),
        refused(RepoPathRefusal.hostPath),
      );
      expect(inspector.inspected, isEmpty);
      final path = dir(p.join(wsDir, 'repos', 'api'));
      inspector.origins[path] = ('acme', 'api');
      final added = await call('repos.addFromPath', ada, WorkspaceRole.admin, {
        'path': path,
      });
      expect((added['repo'] as Map)['path'], path);
      expect((await repos.getAll('ws-a')).single.linkedBy, ada);
    });
  });

  group('reading', () {
    test('a stored row is served only while its path still passes', () async {
      final inStorage = dir(p.join(wsDir, 'repos', 'web'));
      repos.seed('ws-a', [
        // Stored before linkers were recorded: storage paths still serve.
        repo(inStorage, id: 'web'),
        // A host path nobody (or a non-owner) is recorded as linking.
        repo(hostCheckout, id: 'host-unknown'),
        repo(hostCheckout, id: 'host-ada', linkedBy: ada),
        repo(hostCheckout, id: 'host-owner', linkedBy: owner),
        repo(otherWsDir, id: 'other-ws', linkedBy: owner),
      ]);
      final served = GuardedRepoRepository(repos, guard);
      expect((await served.getAll('ws-a')).map((r) => r.id), [
        'web',
        'host-owner',
      ]);
      await expectLater(
        served.getById('ws-a', 'host-unknown'),
        refused(RepoPathRefusal.hostPath),
      );
      await expectLater(
        served.getById('ws-a', 'other-ws'),
        refused(RepoPathRefusal.dataDir),
      );
    });

    test(
      'a symlink retargeted into the data dir after linking is refused',
      () async {
        final target = dir(p.join(wsDir, 'checkouts', 'api'));
        final link = p.join(wsDir, 'repos', 'api');
        Directory(p.dirname(link)).createSync(recursive: true);
        Link(link).createSync(target);
        inspector.origins[target] = ('acme', 'api');
        await upsert(ada, WorkspaceRole.admin, repo(link));
        final served = GuardedRepoRepository(repos, guard);
        expect((await served.getById('ws-a', 'r1'))!.path, target);

        // The stored path is the canonical one; point a stored symlink row
        // somewhere else to model a tree that changed underneath.
        await repos.upsert('ws-a', repo(link, linkedBy: ada));
        Link(link).updateSync(otherWsDir);
        await expectLater(
          served.getById('ws-a', 'r1'),
          refused(RepoPathRefusal.dataDir),
        );
      },
    );

    test(
      'the owner re-saving a row that is no longer served links it again',
      () async {
        inspector.origins[hostCheckout] = ('acme', 'api');
        repos.seed('ws-a', [repo(hostCheckout)]);
        final served = GuardedRepoRepository(repos, guard);
        expect(await served.getAll('ws-a'), isEmpty);
        await expectLater(
          upsert(mo, WorkspaceRole.member, repo(hostCheckout)),
          throwsA(isA<AuthException>()),
        );
        await upsert(owner, WorkspaceRole.owner, repo(hostCheckout));
        expect((await served.getAll('ws-a')).single.linkedBy, owner);
      },
    );

    test('another admin re-saving a host-path row is refused, and it stays '
        'unserved', () async {
      inspector.origins[hostCheckout] = ('acme', 'api');
      repos.seed('ws-a', [repo(hostCheckout)]);
      await expectLater(
        upsert(ada, WorkspaceRole.admin, repo(hostCheckout)),
        refused(RepoPathRefusal.hostPath),
      );
      expect((await repos.getById('ws-a', 'r1'))!.linkedBy, '');
      expect(await GuardedRepoRepository(repos, guard).getAll('ws-a'), isEmpty);
    });

    test('the owner adding the folder of a row that is no longer served links '
        'it again, keeping its id; another admin is refused', () async {
      inspector.origins[hostCheckout] = ('acme', 'api');
      repos.seed('ws-a', [repo(hostCheckout, id: 'kept')]);
      await expectLater(
        call('repos.addFromPath', ada, WorkspaceRole.admin, {
          'path': hostCheckout,
        }),
        refused(RepoPathRefusal.hostPath),
      );
      final added = await call('repos.addFromPath', owner, WorkspaceRole.owner, {
        'path': hostCheckout,
      });
      expect((added['repo'] as Map)['id'], 'kept');
      final stored = (await repos.getAll('ws-a')).single;
      expect(stored.id, 'kept');
      expect(stored.linkedBy, owner);
      expect(
        (await GuardedRepoRepository(repos, guard).getAll('ws-a')).single.id,
        'kept',
      );
    });

    test('adding the folder of a served row returns it unchanged', () async {
      final path = dir(p.join(wsDir, 'repos', 'api'));
      inspector.origins[path] = ('acme', 'api');
      repos.seed('ws-a', [repo(path, id: 'kept', linkedBy: ada)]);
      final added = await call('repos.addFromPath', owner, WorkspaceRole.owner, {
        'path': path,
      });
      expect((added['repo'] as Map)['id'], 'kept');
      expect((await repos.getAll('ws-a')).single.linkedBy, ada);
    });
  });

  group('path_issue', () {
    test('each listed repository carries why its path is not served', () async {
      final inStorage = dir(p.join(wsDir, 'repos', 'web'));
      final wire = await reposToListingWire(guard, 'ws-a', [
        repo(inStorage, id: 'web'),
        repo(hostCheckout, id: 'host', linkedBy: ada),
        repo(hostCheckout, id: 'host-owner', linkedBy: owner),
        repo(p.join(wsDir, 'gone'), id: 'gone'),
        repo(otherWsDir, id: 'data', linkedBy: owner),
        repo(wsDir, id: 'root', linkedBy: owner),
      ]);
      expect({for (final r in wire) r['id']: r['path_issue']}, {
        'web': null,
        'host': 'repo_path.host_path',
        'host-owner': null,
        'gone': 'repo_path.missing',
        'data': 'repo_path.data_dir',
        'root': 'repo_path.workspace_root',
      });
      // The stored path is listed as stored, so the row can be fixed.
      expect(wire[1]['path'], hostCheckout);
    });

    test('repos.get carries it', () async {
      repos.seed('ws-a', [repo(hostCheckout)]);
      final got = await call('repos.get', mo, WorkspaceRole.member, {
        'repo_id': 'r1',
      });
      expect((got['repo'] as Map)['path_issue'], 'repo_path.host_path');
    });

    test('a watched listing re-emits when a relink clears it', () async {
      final rows = StreamController<List<Repo>>();
      addTearDown(rows.close);
      final frames = <Map<String, dynamic>>[];
      final sub =
          grantedRepoFrames(
            members: _Admins(),
            workspaceId: 'ws-a',
            userId: ada,
            repos: rows.stream,
            render: (list) async => {
              'repos': await reposToListingWire(guard, 'ws-a', list),
            },
          ).listen(frames.add);
      addTearDown(sub.cancel);
      String? issue() =>
          ((frames.last['repos'] as List).single as Map)['path_issue']
              as String?;

      rows.add([repo(hostCheckout)]);
      await pumpEventQueue();
      expect(issue(), 'repo_path.host_path');
      rows.add([repo(hostCheckout, linkedBy: owner)]);
      await pumpEventQueue();
      expect(frames, hasLength(2));
      expect(issue(), isNull);
    });
  });
}

/// Everyone asked about is a workspace admin.
final class _Admins implements WorkspaceMembershipRepository {
  @override
  Future<WorkspaceMember?> getMember(String workspaceId, String userId) async =>
      WorkspaceMember(
        id: 'm-$userId',
        workspaceId: workspaceId,
        userId: userId,
        role: WorkspaceRole.admin,
        joinedAt: DateTime.utc(2026),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Inspector implements GitRepoInspectorPort {
  final origins = <String, (String, String)>{};
  final inspected = <String>[];

  @override
  Future<GitRepoInfo> inspect(String path) async {
    inspected.add(path);
    final origin = origins[path];
    if (origin == null) {
      throw GitRepoInspectionException('No origin at $path');
    }
    return GitRepoInfo(
      path: path,
      forge: ForgeHost.github,
      owner: origin.$1,
      repoName: origin.$2,
      branch: 'main',
    );
  }
}
