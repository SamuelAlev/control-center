import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/src/ide/code_server_service.dart';
import 'package:cc_server_core/src/catalog/code_server_file_ops.dart';
import 'package:test/test.dart';

void main() {
  test(
    'close RPC denies foreign workspace/device and discards only the last reference',
    () async {
      final tmp = Directory.systemTemp.createTempSync(
        'cc_code_server_close_rpc',
      );
      final worktree = Directory('${tmp.path}/worktree')..createSync();
      final os = Platform.isMacOS ? 'darwin' : 'linux';
      final uname = Process.runSync('uname', ['-m']).stdout as String;
      final arch = uname.contains('arm64') || uname.contains('aarch64')
          ? 'arm64'
          : 'x64';
      final bin = File('${tmp.path}/code-server/$os-$arch/bin/code-server')
        ..createSync(recursive: true)
        ..writeAsStringSync(
          '#!/bin/sh\n'
          'case "\$*" in *--install-extension*) exit 0;; esac\n'
          'printf "%s\\n" "\$\$" >> "${tmp.path}/launches"\n'
          'echo "HTTP server listening on http://127.0.0.1:45678/"\n'
          'exec sleep 60\n',
        );
      Process.runSync('chmod', ['755', bin.path]);
      for (final ext in codeServerCuratedExtensions) {
        Directory(
          '${tmp.path}/code-server/extensions/'
          '${ext.publisher}.${ext.name}-${ext.version}',
        ).createSync(recursive: true);
      }
      final service = CodeServerService(
        isolatedRepos: _Repo(
          IsolatedRepo(
            id: 'worktree',
            workspaceId: 'ws-a',
            spaceId: 'space-a',
            repoId: 'repo-a',
            path: worktree.path,
            branch: 'main',
            backend: RepoIsolationBackend.rift,
            sourcePath: '${tmp.path}/source',
            createdAt: DateTime.utc(2026, 1, 1),
          ),
        ),
        dataRoot: tmp.path,
        attemptManagedDownload: false,
      );
      addTearDown(() async {
        await service.disposeAll();
        tmp.deleteSync(recursive: true);
      });

      final a = await service.ensureSession(
        workspaceId: 'ws-a',
        spaceId: 'space-a',
        repoId: 'repo-a',
        deviceId: 'device-a',
      );
      final b = await service.ensureSession(
        workspaceId: 'ws-a',
        spaceId: 'space-a',
        repoId: 'repo-a',
        deviceId: 'device-b',
      );
      final close = buildCodeServerFileOps(
        codeServer: service,
      ).singleWhere((op) => op.name == 'codeServer.close');
      RepoOpContext request(String workspace, String device, String session) =>
          RepoOpContext(
            args: {
              'workspace_id': workspace,
              'session_id': session,
              'discard_if_unused': true,
            },
            workspaceId: workspace,
            deviceId: device,
            userId: 'user-a',
          );

      await expectLater(
        close.handler(request('ws-b', 'device-a', a.sessionId)),
        throwsStateError,
      );
      await expectLater(
        close.handler(request('ws-a', 'device-b', a.sessionId)),
        throwsStateError,
      );
      expect(service.lookup(a.sessionId), isNotNull);
      expect(service.lookup(b.sessionId), isNotNull);

      expect(await close.handler(request('ws-a', 'device-a', a.sessionId)), {
        'ok': true,
      });
      expect(service.lookup(a.sessionId), isNull);
      expect(service.lookup(b.sessionId), isNotNull);
      expect(File('${tmp.path}/launches').readAsLinesSync(), hasLength(1));

      await close.handler(request('ws-a', 'device-b', b.sessionId));
      expect(service.lookup(b.sessionId), isNull);
      await service.ensureSession(
        workspaceId: 'ws-a',
        spaceId: 'space-a',
        repoId: 'repo-a',
        deviceId: 'device-a',
      );
      expect(File('${tmp.path}/launches').readAsLinesSync(), hasLength(2));
    },
    skip: Platform.isWindows ? 'the stand-in is a POSIX shell script' : null,
  );
}

class _Repo implements IsolatedRepoRepository {
  _Repo(this.worktree);

  final IsolatedRepo worktree;

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async =>
      workspaceId == worktree.workspaceId &&
          spaceId == worktree.spaceId &&
          repoId == worktree.repoId
      ? worktree
      : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
