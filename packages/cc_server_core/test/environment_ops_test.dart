import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/repositories/isolated_repo_repository.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/core/domain/value_objects/repo_isolation_backend.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_infra/cc_infra.dart' show EnvironmentDriverException;
import 'package:cc_natives/cc_natives.dart' show RigWorktreeGuard;
import 'package:cc_server_core/src/catalog/environment_ops.dart';
import 'package:cc_server_core/src/environments/server_environment_adapters.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

const _password = 'hunter2';

EnvironmentDefinitionRecord _record(String workspaceId) =>
    EnvironmentDefinitionRecord(
      id: 'def-$workspaceId',
      workspaceId: workspaceId,
      name: 'Shop',
      definitionJson: jsonEncode({
        'contract': 1,
        'name': 'Shop',
        'env': {'DATABASE_URL': 'postgres://app:$_password@db'},
        'repos': {
          'app': {'repoId': 'repo-a', 'anchor': true},
        },
        'components': [
          {
            'kind': 'process',
            'id': 'web',
            'command': ['pnpm', 'dev'],
            'env': {'API_KEY': _password},
          },
        ],
      }),
      overridesJson: jsonEncode({
        'env': {'SECRET_ID': _password},
        'limits': [
          {'token': _password},
        ],
      }),
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

class _FakeEnvironments implements EnvironmentPort {
  @override
  Future<List<EnvironmentInstance>> definitionEnvironments(
    String workspaceId,
    String definitionId,
  ) async => const [];

  @override
  Future<String> startSetup(
    String workspaceId,
    String spaceId, {
    required Principal by,
  }) async => 'session-1';

  int watches = 0;
  int logFollows = 0;
  int runReads = 0;

  @override
  Future<List<EnvironmentDefinitionRecord>> listDefinitions(
    String workspaceId,
  ) async => [_record(workspaceId)];

  @override
  Future<EnvironmentDefinitionRecord?> definition(
    String workspaceId,
    String definitionId,
  ) async => definitionId == 'def-$workspaceId' ? _record(workspaceId) : null;

  @override
  Future<List<EnvironmentDefinitionRecord>> eligibleDefinitions(
    String workspaceId,
    String spaceId,
  ) async => [_record(workspaceId)];

  @override
  Stream<List<SpaceEnvironment>> watch(String workspaceId, String spaceId) {
    watches++;
    return Stream.value(const []);
  }

  @override
  Stream<String> followLogs(
    String workspaceId,
    String spaceId, {
    required String target,
    int tail = 200,
  }) {
    logFollows++;
    return Stream.value('line');
  }

  @override
  Future<List<EnvironmentRun>> runs(String workspaceId, String spaceId) async {
    runReads++;
    return const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _FakeIsolated implements IsolatedRepoRepository {
  _FakeIsolated(this.rows);

  final List<IsolatedRepo> rows;

  @override
  Future<List<IsolatedRepo>> forSpace(
    String workspaceId,
    String spaceId,
  ) async => rows;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  group('definitions', () {
    late _FakeEnvironments environments;
    late Map<String, RepoOp> ops;

    setUp(() {
      environments = _FakeEnvironments();
      ops = {
        for (final op in buildEnvironmentOps(
          environments: environments,
          reposExposedBySpace: (_) async => const [],
          assertSpaceOwned: (workspaceId, spaceId) async {
            if (workspaceId != 'ws-a') {
              throw const WorkspaceMismatchException('Not this workspace');
            }
          },
        ))
          op.name: op,
      };
    });

    Future<Map<String, dynamic>> call(
      String name,
      WorkspaceRole? role, {
      String workspaceId = 'ws-a',
      Map<String, dynamic> args = const {},
    }) => ops[name]!.handler(
      RepoOpContext(
        args: args,
        workspaceId: workspaceId,
        deviceId: 'device',
        userId: 'user',
        role: role,
      ),
    );

    final reads = <String, Map<String, dynamic>>{
      'environments.listDefinitions': const {},
      'environments.getDefinition': const {'definition_id': 'def-ws-a'},
      'environments.eligible': const {'space_id': 'space-1'},
    };

    for (final entry in reads.entries) {
      test('${entry.key} hides values from a member', () async {
        final body = jsonEncode(
          await call(entry.key, WorkspaceRole.member, args: entry.value),
        );
        expect(body, isNot(contains(_password)));
        expect(body, contains(kEnvironmentRedactedValue));
        // What the panel needs is all there.
        expect(body, contains('DATABASE_URL'));
        expect(body, contains('pnpm'));
      });

      test('${entry.key} hides values from a guest', () async {
        final body = jsonEncode(
          await call(entry.key, WorkspaceRole.guest, args: entry.value),
        );
        expect(body, isNot(contains(_password)));
      });

      test('${entry.key} hides values when no role was resolved', () async {
        final body = jsonEncode(await call(entry.key, null, args: entry.value));
        expect(body, isNot(contains(_password)));
      });

      test('${entry.key} shows an admin everything', () async {
        final body = jsonEncode(
          await call(entry.key, WorkspaceRole.admin, args: entry.value),
        );
        expect(body, contains(_password));
        expect(body, isNot(contains(kEnvironmentRedactedValue)));
      });
    }

    test('a member reads only their own workspace', () async {
      final body = await call(
        'environments.listDefinitions',
        WorkspaceRole.member,
        workspaceId: 'ws-b',
      );
      expect(jsonEncode(body), isNot(contains('ws-a')));
      await expectLater(
        call(
          'environments.getDefinition',
          WorkspaceRole.admin,
          workspaceId: 'ws-b',
          args: const {'definition_id': 'def-ws-a'},
        ),
        throwsA(isA<NotFoundException>()),
      );
      await expectLater(
        call(
          'environments.eligible',
          WorkspaceRole.member,
          workspaceId: 'ws-b',
          args: const {'space_id': 'space-1'},
        ),
        throwsA(isA<WorkspaceMismatchException>()),
      );
    });

    test('what runs across every space is for admins', () {
      expect(
        ops['environments.listInstances']!.effectiveMinRole,
        WorkspaceRole.admin,
      );
    });

    test('writing stays admin-only', () {
      expect(
        ops['environments.setDefinition']!.effectiveMinRole,
        WorkspaceRole.admin,
      );
      expect(
        ops['environments.approveSource']!.effectiveMinRole,
        WorkspaceRole.admin,
      );
    });
  });

  group('watches', () {
    late _FakeEnvironments environments;
    late Map<String, WatchQuery> queries;
    late Map<String, Set<String>> grants;
    late List<String> exposed;
    late List<({String? workspace, Object? space})> asked;

    setUp(() {
      environments = _FakeEnvironments();
      grants = {
        'reader': {'repo-a', 'repo-b'},
        'partial': {'repo-a'},
      };
      exposed = ['repo-a', 'repo-b'];
      asked = [];
      queries = {
        for (final query in buildEnvironmentWatchQueries(
          environments: environments,
          reposExposedBySpace: (ctx) async {
            asked.add((
              workspace: ctx.workspaceId,
              space: ctx.args['space_id'],
            ));
            return exposed;
          },
          requireRepoReadGrant:
              ({
                required String workspaceId,
                required String userId,
                required String repoId,
              }) async {
                if (!(grants[userId]?.contains(repoId) ?? false)) {
                  throw const AuthException('No read access to this repo');
                }
              },
          assertSpaceOwned: (workspaceId, spaceId) async {
            if (workspaceId != 'ws-a') {
              throw const WorkspaceMismatchException('Not this workspace');
            }
          },
        ))
          query.name: query,
      };
    });

    Stream<Map<String, dynamic>> open(
      String name, {
      String userId = 'reader',
      String workspaceId = 'ws-a',
    }) => queries[name]!.handler(
      WatchQueryContext(
        args: const {'space_id': 'space-1', 'target': 'web'},
        workspaceId: workspaceId,
        deviceId: 'device',
        userId: userId,
      ),
    );

    int reads() =>
        environments.watches + environments.logFollows + environments.runReads;

    for (final name in const [
      'environment.watch',
      'environment.watchLogs',
      'environment.watchRuns',
    ]) {
      test('$name opens with read access to every repo', () async {
        await open(name).first;
        expect(reads(), greaterThan(0));
        expect(asked.single, (workspace: 'ws-a', space: 'space-1'));
      });

      test('$name refuses a member with no grant', () async {
        await expectLater(
          open(name, userId: 'nobody').first,
          throwsA(isA<AuthException>()),
        );
        expect(reads(), 0);
      });

      test('$name refuses a grant on only some repos', () async {
        await expectLater(
          open(name, userId: 'partial').first,
          throwsA(isA<AuthException>()),
        );
        expect(reads(), 0);
      });

      test('$name refuses a space of another workspace first', () async {
        await expectLater(
          open(name, workspaceId: 'ws-b').first,
          throwsA(isA<WorkspaceMismatchException>()),
        );
        expect(asked, isEmpty);
        expect(reads(), 0);
      });

      test('$name asks for no grant on a space with no repos', () async {
        exposed = [];
        await open(name, userId: 'nobody').first;
        expect(reads(), greaterThan(0));
      });
    }
  });

  group('guardedPrSync', () {
    Future<Map<String, dynamic>> sync(
      Future<Map<String, dynamic>> Function(
        String,
        String,
        Future<Map<String, dynamic>> Function(),
      )
      whileHeadMoves,
      void Function() onSync,
    ) => guardedPrSync(whileHeadMoves, ({
      required String workspaceId,
      required String spaceId,
      required String repoId,
    }) async {
      onSync();
      return {'ok': true, 'synced': true};
    })(workspaceId: 'ws-a', spaceId: 'space-1', repoId: 'repo-a');

    test('a refusal never reaches the sync, and reads as a failure', () async {
      var synced = false;
      final res = await sync(
        (_, _, _) => throw const EnvironmentDriverException(
          EnvironmentError(code: 'fork-running-on-host', message: 'Stop it'),
        ),
        () => synced = true,
      );
      expect(res, {'ok': false, 'error': 'Stop it'});
      expect(synced, isFalse);
    });

    test('anything else is not swallowed', () async {
      var synced = false;
      await expectLater(
        sync(
          (_, _, _) => throw const NotFoundException('Space not found'),
          () => synced = true,
        ),
        throwsA(isA<NotFoundException>()),
      );
      expect(synced, isFalse);
    });

    test('a server with no environments has no sync', () {
      expect(
        clientPrSync(
          null,
          ({
            required String workspaceId,
            required String spaceId,
            required String repoId,
          }) async => const {},
        ),
        isNull,
      );
    });

    test('runs the sync when allowed', () async {
      var synced = false;
      final res = await sync((_, _, move) => move(), () => synced = true);
      expect(res['synced'], isTrue);
      expect(synced, isTrue);
    });
  });

  group('syncEnvironmentWorktrees on a quarantined worktree', () {
    late Directory tmp;
    late String wt;

    Future<void> git(List<String> args) async {
      final result = await Process.run('git', args, workingDirectory: wt);
      if (result.exitCode != 0) {
        throw StateError('git ${args.join(' ')}: ${result.stderr}');
      }
    }

    Future<void> commit(String file) async {
      File(p.join(wt, file)).writeAsStringSync('$file\n');
      await git(['add', '-A']);
      await git(['commit', '-q', '-m', file]);
    }

    setUp(() async {
      tmp = Directory.systemTemp.createTempSync('environment_sync_test_');
      wt = tmp.path;
      await git(['init', '-q']);
      await git(['config', 'user.email', 'test@example.com']);
      await git(['config', 'user.name', 'Test']);
      await git(['config', 'commit.gpgsign', 'false']);
      await commit('first.txt');
      RigWorktreeGuard.debugReset();
      RigWorktreeGuard.quarantine(wt);
    });

    tearDown(() {
      RigWorktreeGuard.forceRelease(wt);
      RigWorktreeGuard.debugReset();
      tmp.deleteSync(recursive: true);
    });

    Future<List<String>?> sync() => syncEnvironmentWorktrees(
      isolated: _FakeIsolated([
        IsolatedRepo(
          id: 'wt',
          workspaceId: 'ws-a',
          spaceId: 'space-1',
          repoId: 'repo-a',
          backend: RepoIsolationBackend.gitWorktree,
          path: wt,
          branch: 'main',
          sourcePath: '/src/repo-a',
          createdAt: DateTime(2026),
        ),
      ]),
      syncPrWorktree:
          ({
            required String workspaceId,
            required String spaceId,
            required String repoId,
          }) async {
            await commit('second.txt');
            return {'ok': true, 'synced': true};
          },
      workspaceId: 'ws-a',
      spaceId: 'space-1',
    );

    test('reports what moved while the metadata is intact', () async {
      expect(await sync(), ['second.txt']);
    });

    test('runs no git once the metadata changed', () async {
      File(p.join(wt, '.git', 'config')).writeAsStringSync(
        '[alias]\n\tplanted = !true\n',
        mode: FileMode.append,
      );
      expect(await sync(), isEmpty);
    });
  });
}
