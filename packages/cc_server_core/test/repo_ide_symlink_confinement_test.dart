import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_natives/cc_natives.dart' show DartFileSearch;
import 'package:cc_server_core/src/repo_ide_data_service.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// A symlink in a checkout or a worktree — committed to the repository, or
/// made by an agent in its space — keeps a joined path lexically inside the
/// tree while the file it reaches is anywhere on the host. The IDE file
/// reads, the directory listing and the worktree write all resolve links
/// before they touch the disk.
void main() {
  late Directory tmp;
  late String tree;
  late String outside;
  late RepoIdeDataService svc;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('repo_ide_symlink_');
    tree = p.join(tmp.path, 'tree');
    Directory(p.join(tree, 'lib')).createSync(recursive: true);
    File(p.join(tree, 'lib', 'main.dart')).writeAsStringSync('main');
    outside = p.join(tmp.path, 'outside');
    Directory(outside).createSync();
    File(p.join(outside, 'id_rsa')).writeAsStringSync('PRIVATE KEY');
    Link(p.join(tree, 'escape')).createSync(outside);
    Link(p.join(tree, 'key')).createSync(p.join(outside, 'id_rsa'));
    Link(p.join(tree, 'src')).createSync(p.join(tree, 'lib'));
    svc = RepoIdeDataService(
      repoRepository: _Repos(
        Repo(
          id: 'r',
          name: 'r',
          path: tree,
          remoteOwner: 'o',
          remoteName: 'r',
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ),
      workspaceRepository: _Workspaces(),
      isolatedRepoRepository: _Worktrees(
        IsolatedRepo(
          id: 'iso',
          workspaceId: 'ws',
          spaceId: 'sp',
          repoId: 'r',
          path: tree,
          branch: 'b',
          backend: RepoIsolationBackend.gitWorktree,
          sourcePath: tree,
          createdAt: DateTime(2026),
        ),
      ),
      fileSearch: DartFileSearch(),
    );
  });

  tearDown(() => tmp.deleteSync(recursive: true));

  test(
    'repos.readFile never reads through a link out of the checkout',
    () async {
      for (final path in ['escape/id_rsa', 'key']) {
        final read = await svc.readFile('ws', 'r', path);
        expect(read.content, isEmpty, reason: path);
      }
      expect((await svc.readFile('ws', 'r', 'src/main.dart')).content, 'main');
    },
  );

  test(
    'worktree.readFile never reads through a link out of the worktree',
    () async {
      for (final path in ['escape/id_rsa', 'key']) {
        expect(
          await svc.readFileFromWorktree('ws', 'sp', 'r', path),
          isNull,
          reason: path,
        );
      }
      expect(
        (await svc.readFileFromWorktree(
          'ws',
          'sp',
          'r',
          'src/main.dart',
        ))!.content,
        'main',
      );
    },
  );

  test(
    'repos.listDirectory never lists a directory out of the checkout',
    () async {
      final page = await svc.listDirectory('ws', 'r', path: 'escape');
      expect(page['entries'] as List, isEmpty);
    },
  );

  test(
    'worktree.writeFile never writes through a link out of the worktree',
    () async {
      expect(
        await svc.writeFile('ws', 'sp', 'r', 'escape/authorized_keys', 'k'),
        isNull,
      );
      expect(
        await svc.writeFile('ws', 'sp', 'r', 'key', 'overwritten'),
        isNull,
      );
      expect(File(p.join(outside, 'authorized_keys')).existsSync(), isFalse);
      expect(File(p.join(outside, 'id_rsa')).readAsStringSync(), 'PRIVATE KEY');
      // Inside the tree, writes still land.
      final ok = await svc.writeFile('ws', 'sp', 'r', 'lib/new.dart', 'n');
      expect(ok!.path, 'lib/new.dart');
      expect(File(p.join(tree, 'lib', 'new.dart')).readAsStringSync(), 'n');
    },
  );
}

class _Repos implements RepoRepository {
  _Repos(this.repo);

  final Repo repo;

  @override
  Future<Repo?> getById(String workspaceId, String id) async =>
      id == repo.id ? repo : null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Workspaces implements WorkspaceRepository {
  @override
  Future<bool> isRepoLinkedToWorkspace(
    String workspaceId,
    String repoId,
  ) async => workspaceId == 'ws' && repoId == 'r';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Worktrees implements IsolatedRepoRepository {
  _Worktrees(this.worktree);

  final IsolatedRepo worktree;

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => workspaceId == 'ws' && spaceId == 'sp' ? [worktree] : const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
