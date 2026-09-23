import 'dart:io';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/repositories/repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/features/messaging/domain/entities/space_stack_entry.dart';
import 'package:cc_domain/features/messaging/domain/repositories/space_stack_repository.dart';
import 'package:cc_server_core/src/space_stack_service.dart';
import 'package:test/test.dart';

void main() {
  late Directory root;
  late _Isolated isolated;
  late _Stacks stacks;
  late SpaceStackService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('space_stack_');
    await _git(root.path, ['init', '-b', 'main']);
    await _git(root.path, ['config', 'user.email', 'stack@example.com']);
    await _git(root.path, ['config', 'user.name', 'Stack']);
    await _git(root.path, ['commit', '--allow-empty', '-m', 'base']);
    await _git(root.path, ['switch', '-c', 'space/abcd1234']);
    isolated = _Isolated(
      IsolatedRepo(
        id: 'iso-1',
        workspaceId: 'ws',
        spaceId: 'space-1',
        repoId: 'repo-1',
        path: root.path,
        branch: 'space/abcd1234',
        backend: RepoIsolationBackend.rift,
        sourcePath: '/src/repo',
        createdAt: DateTime.utc(2026),
      ),
    );
    stacks = _Stacks();
    service = _service(isolated: isolated, stacks: stacks);
  });

  tearDown(() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  test('the first cut records the current branch and checks out the new part', () async {
    await _commit(root.path, 'one.txt', 'one');

    final view = await service.cut(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      name: 'UI',
    );

    expect(view.ok, isTrue, reason: view.error);
    expect(view.entries.map((e) => e.position), [0, 1]);
    expect(view.entries[0].branch, 'space/abcd1234');
    expect(view.entries[0].baseBranch, 'release');
    expect(view.entries[1].branch, 'space/abcd1234--ui');
    expect(view.entries[1].baseBranch, 'space/abcd1234');
    expect(view.checkedOut['repo-1'], 'space/abcd1234--ui');
    expect(isolated.row.branch, 'space/abcd1234--ui');
    expect(await _head(root.path), 'space/abcd1234--ui');
  });

  test('a cut at an ancestor keeps only the commits above it on the new part', () async {
    await _commit(root.path, 'one.txt', 'one');
    final at = await _sha(root.path);
    await _commit(root.path, 'two.txt', 'two');
    final tip = await _sha(root.path);

    final view = await service.cut(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      name: 'ui',
      at: at,
    );

    expect(view.ok, isTrue, reason: view.error);
    expect(await _sha(root.path, 'space/abcd1234'), at);
    expect(await _sha(root.path, 'space/abcd1234--ui'), tip);
    expect(await _head(root.path), 'space/abcd1234--ui');
    expect(isolated.row.branch, 'space/abcd1234--ui');
  });

  test('a dirty checkout refuses cut and checkout', () async {
    await File('${root.path}/dirty.txt').writeAsString('wip');

    final cut = await service.cut(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      name: 'ui',
    );
    expect(cut.ok, isFalse);
    expect(cut.dirty, isTrue);
    expect(stacks.rows, isEmpty);
    expect(await _head(root.path), 'space/abcd1234');

    await File('${root.path}/dirty.txt').delete();
    final started = await service.cut(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      name: 'ui',
    );
    expect(started.ok, isTrue, reason: started.error);
    await File('${root.path}/dirty.txt').writeAsString('wip');

    final checkout = await service.checkout(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      branch: 'space/abcd1234',
    );
    expect(checkout.ok, isFalse);
    expect(checkout.dirty, isTrue);
    expect(await _head(root.path), 'space/abcd1234--ui');
    expect(isolated.row.branch, 'space/abcd1234--ui');
  });

  test('publish opens each pull request against the branch below it', () async {
    final origin = await Directory.systemTemp.createTemp('space_stack_origin_');
    addTearDown(() async {
      if (origin.existsSync()) {
        await origin.delete(recursive: true);
      }
    });
    await _git(origin.path, ['init', '--bare', '-b', 'main']);
    await _git(root.path, ['remote', 'add', 'origin', origin.path]);
    await _commit(root.path, 'migration.txt', 'migration');
    final cut = await service.cut(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      name: 'ui',
    );
    expect(cut.ok, isTrue, reason: cut.error);
    await _commit(root.path, 'ui.txt', 'ui');

    final opened = <({String head, String base, bool draft})>[];
    final grouped = <List<int>>[];
    service = _service(
      isolated: isolated,
      stacks: stacks,
      open: (call) async {
        opened.add(call);
        return (number: opened.length, externalId: 'pr-${opened.length}');
      },
      group: (numbers) async => grouped.add(numbers),
      stacksSupported: true,
    );

    final view = await service.publish(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
    );

    expect(view.ok, isTrue, reason: view.error);
    expect(view.opened, 2);
    expect(view.grouped, isTrue);
    expect(opened, [
      (head: 'space/abcd1234', base: 'release', draft: true),
      (head: 'space/abcd1234--ui', base: 'space/abcd1234', draft: true),
    ]);
    expect(grouped, [
      [1, 2],
    ]);
  });

  test('a forge without stacks still gets chained pull requests', () async {
    final origin = await Directory.systemTemp.createTemp('space_stack_origin_');
    addTearDown(() async {
      if (origin.existsSync()) {
        await origin.delete(recursive: true);
      }
    });
    await _git(origin.path, ['init', '--bare', '-b', 'main']);
    await _git(root.path, ['remote', 'add', 'origin', origin.path]);
    await _commit(root.path, 'migration.txt', 'migration');
    expect(
      (await service.cut(
        workspaceId: 'ws',
        spaceId: 'space-1',
        repoId: 'repo-1',
        name: 'ui',
      )).ok,
      isTrue,
    );
    await _commit(root.path, 'ui.txt', 'ui');

    var grouped = false;
    service = _service(
      isolated: isolated,
      stacks: stacks,
      open: (_) async => (number: 7, externalId: 'gl-7'),
      group: (_) async => grouped = true,
      stacksSupported: false,
    );

    final view = await service.publish(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
    );

    expect(view.ok, isTrue, reason: view.error);
    expect(view.opened, 2);
    expect(view.grouped, isFalse);
    expect(grouped, isFalse);
  });

  test('nothing to publish leaves the forge untouched', () async {
    service = _service(isolated: isolated, stacks: stacks, pinned: null);
    final cut = await service.cut(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
      name: 'ui',
    );
    expect(cut.ok, isTrue, reason: cut.error);
    var opened = 0;
    service = _service(
      isolated: isolated,
      stacks: stacks,
      open: (_) async {
        opened++;
        return (number: 1, externalId: 'x');
      },
      stacksSupported: true,
    );

    final view = await service.publish(
      workspaceId: 'ws',
      spaceId: 'space-1',
      repoId: 'repo-1',
    );

    expect(view.ok, isFalse);
    expect(view.error, 'nothing to publish yet');
    expect(opened, 0);
  });
}

SpaceStackService _service({
  required _Isolated isolated,
  required _Stacks stacks,
  Future<({int number, String externalId})> Function(
    ({String head, String base, bool draft}) call,
  )?
  open,
  Future<void> Function(List<int> numbers)? group,
  bool stacksSupported = true,
  String? pinned = 'release',
}) {
  return SpaceStackService(
    isolatedRepos: isolated,
    stacks: stacks,
    repos: _Repos(),
    pinnedBase: (_, _, _) async => pinned,
    tokenFor: (_, _, _) async => null,
    openPullRequest:
        ({
          required Repo repo,
          required String workspaceId,
          required String title,
          required String body,
          required String head,
          required String base,
          required bool draft,
          String? actingUserId,
        }) async {
          final openCall = open;
          if (openCall == null) {
            return (number: 1, externalId: 'pr-1');
          }
          return openCall((head: head, base: base, draft: draft));
        },
    groupStack:
        ({
          required Repo repo,
          required String workspaceId,
          required List<int> prNumbers,
          String? actingUserId,
        }) async {
          await group?.call(prNumbers);
        },
    stacksSupported: (_) => stacksSupported,
  );
}

Future<void> _git(String cwd, List<String> args) async {
  final result = await Process.run(
    'git',
    args,
    workingDirectory: cwd.isEmpty ? null : cwd,
  );
  if (result.exitCode != 0) {
    fail('${args.join(' ')}\n${result.stdout}\n${result.stderr}');
  }
}

Future<void> _commit(String cwd, String name, String message) async {
  await File('$cwd/$name').writeAsString(message);
  await _git(cwd, ['add', '--', name]);
  await _git(cwd, ['commit', '-m', message]);
}

Future<String> _sha(String cwd, [String rev = 'HEAD']) async {
  final result = await Process.run('git', [
    'rev-parse',
    rev,
  ], workingDirectory: cwd);
  return (result.stdout as String).trim();
}

Future<String> _head(String cwd) async {
  final result = await Process.run('git', [
    'rev-parse',
    '--abbrev-ref',
    'HEAD',
  ], workingDirectory: cwd);
  return (result.stdout as String).trim();
}

class _Isolated implements IsolatedRepoRepository {
  _Isolated(this.row);

  IsolatedRepo row;

  @override
  Future<List<IsolatedRepo>> forSpace(String workspaceId, String spaceId) async {
    if (row.workspaceId == workspaceId && row.spaceId == spaceId) {
      return [row];
    }
    return const [];
  }

  @override
  Future<IsolatedRepo?> forUnitRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    if (row.workspaceId == workspaceId &&
        row.spaceId == spaceId &&
        row.repoId == repoId) {
      return row;
    }
    return null;
  }

  @override
  Future<void> upsert(IsolatedRepo repo) async {
    row = repo;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Stacks implements SpaceStackRepository {
  final List<SpaceStackEntry> rows = [];

  List<SpaceStackEntry> _matching(bool Function(SpaceStackEntry) test) {
    final found = rows.where(test).toList();
    found.sort((a, b) {
      final repo = a.repoId.compareTo(b.repoId);
      if (repo != 0) {
        return repo;
      }
      return a.position.compareTo(b.position);
    });
    return found;
  }

  @override
  Future<List<SpaceStackEntry>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => _matching(
    (row) => row.workspaceId == workspaceId && row.spaceId == spaceId,
  );

  @override
  Future<List<SpaceStackEntry>> forRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async => _matching(
    (row) =>
        row.workspaceId == workspaceId &&
        row.spaceId == spaceId &&
        row.repoId == repoId,
  );

  @override
  Future<void> upsert(SpaceStackEntry entry) async {
    rows.removeWhere((row) => row.id == entry.id);
    rows.add(entry);
  }

  @override
  Future<void> deleteForRepo(
    String workspaceId,
    String spaceId,
    String repoId,
  ) async {
    rows.removeWhere(
      (row) =>
          row.workspaceId == workspaceId &&
          row.spaceId == spaceId &&
          row.repoId == repoId,
    );
  }

  @override
  Future<void> deleteById(String workspaceId, String id) async {
    rows.removeWhere((row) => row.workspaceId == workspaceId && row.id == id);
  }
}

class _Repos implements RepoRepository {
  @override
  Future<Repo?> getById(String workspaceId, String id) async => Repo(
    id: id,
    name: 'app',
    path: '/src/app',
    remoteOwner: 'acme',
    remoteName: 'app',
    forge: ForgeHost.github,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
