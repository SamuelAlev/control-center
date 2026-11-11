import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// Code follows the caller's own forge access: on top of the grant, every
/// repository a code-bearing op exposes must be one the caller's forge
/// sign-in can read, and workspace admins are not exempt.
void main() {
  const roles = {
    'admin': WorkspaceRole.admin,
    'granted': WorkspaceRole.member,
    'nogrant': WorkspaceRole.member,
  };
  late Set<String> forgeReadable;
  late List<String> asked;
  late List<Map<String, Object?>> decisions;
  late int handled;

  RepoOpDispatcher dispatcher({RepoForgeReadGate? gate}) => RepoOpDispatcher(
    registry: RepoOpRegistry([
      RepoOp(
        name: 'repo.readFile',
        kind: RepoOpKind.read,
        repoAccess: RepoGrantLevel.read,
        handler: (ctx) async {
          handled++;
          return {'ok': true};
        },
      ),
      RepoOp(
        name: 'space.terminal',
        kind: RepoOpKind.read,
        requiredArgs: const ['space_id'],
        repoAccess: RepoGrantLevel.read,
        repoAccessVia: (ctx) async => const ['r-open', 'r-closed'],
        handler: (ctx) async {
          handled++;
          return {'ok': true};
        },
      ),
    ]),
    resolveRole: (workspaceId, userId) async => roles[userId],
    resolveRepoGrant: (workspaceId, userId, repoId) async =>
        userId == 'granted' ? RepoGrantLevel.read : RepoGrantLevel.none,
    requireForgeRead:
        gate ??
        (workspaceId, userId, repoId) async {
          asked.add('$userId:$repoId');
          if (!forgeReadable.contains('$userId:$repoId')) {
            throw const AuthException('Your sign-in cannot read this.');
          }
        },
    mapException: (e) => e is AuthException
        ? RpcErrorMapping(RpcErrorCodes.unauthorized, e.message)
        : null,
    recordGuardDecision:
        ({
          required String workspaceId,
          required String userId,
          required String deviceId,
          required String opName,
          required String permission,
          required bool allowed,
          required String sourceScope,
          String? reason,
          String? ip,
          String? correlationId,
          List<String> actionClasses = const [],
        }) => decisions.add({
          'user': userId,
          'allowed': allowed,
          'scope': sourceScope,
        }),
  );

  setUp(() {
    forgeReadable = {};
    asked = [];
    decisions = [];
    handled = 0;
  });

  Future<Map<String, dynamic>> call(
    RepoOpDispatcher d,
    String op,
    String userId,
    Map<String, dynamic> args,
  ) => d.call(
    id: 1,
    params: {
      'op': op,
      'args': {'workspace_id': 'ws-1', ...args},
    },
    deviceId: 'dev-$userId',
    userId: userId,
    sessionCapability: SessionCapability.fullClient,
  );

  Object? code(Map<String, dynamic> res) => (res['error'] as Map?)?['code'];

  group('named repository', () {
    test('a granted member whose sign-in cannot read it is refused, and the '
        'refusal is audited', () async {
      final res = await call(dispatcher(), 'repo.readFile', 'granted', {
        'repo_id': 'r-closed',
      });
      expect(code(res), RpcErrorCodes.unauthorized);
      expect(handled, 0);
      expect(decisions.single, {
        'user': 'granted',
        'allowed': false,
        'scope': 'forge',
      });
    });

    test('a granted member whose sign-in reads it passes', () async {
      forgeReadable.add('granted:r-open');
      final res = await call(dispatcher(), 'repo.readFile', 'granted', {
        'repo_id': 'r-open',
      });
      expect(res['result'], isNotNull);
      expect(handled, 1);
    });

    test('an admin is not exempt from the forge', () async {
      final res = await call(dispatcher(), 'repo.readFile', 'admin', {
        'repo_id': 'r-closed',
      });
      expect(code(res), RpcErrorCodes.unauthorized);
      expect(asked, ['admin:r-closed']);
      forgeReadable.add('admin:r-closed');
      final ok = await call(dispatcher(), 'repo.readFile', 'admin', {
        'repo_id': 'r-closed',
      });
      expect(ok['result'], isNotNull);
    });

    test(
      'the grant is still checked first: no grant, no forge question',
      () async {
        forgeReadable.add('nogrant:r-open');
        final res = await call(dispatcher(), 'repo.readFile', 'nogrant', {
          'repo_id': 'r-open',
        });
        expect(code(res), RpcErrorCodes.unauthorized);
        expect(asked, isEmpty);
      },
    );

    test('a refusal the app maps differently keeps its code', () async {
      final res = await call(
        dispatcher(
          gate: (workspaceId, userId, repoId) async =>
              throw const ValidationException('Sign in to GitHub'),
        ),
        'repo.readFile',
        'granted',
        {'repo_id': 'r-open'},
      );
      expect(res['error'], isNotNull);
      expect(handled, 0);
    });
  });

  group('repositories an op derives', () {
    test('every exposed repository must be readable by the sign-in', () async {
      forgeReadable.addAll(['granted:r-open']);
      final res = await call(dispatcher(), 'space.terminal', 'granted', {
        'space_id': 's1',
      });
      expect(code(res), RpcErrorCodes.unauthorized);
      expect(asked, ['granted:r-open', 'granted:r-closed']);
      expect(handled, 0);
    });

    test('admins are asked about every exposed repository too', () async {
      forgeReadable.addAll(['admin:r-open']);
      final refused = await call(dispatcher(), 'space.terminal', 'admin', {
        'space_id': 's1',
      });
      expect(code(refused), RpcErrorCodes.unauthorized);
      forgeReadable.add('admin:r-closed');
      final ok = await call(dispatcher(), 'space.terminal', 'admin', {
        'space_id': 's1',
      });
      expect(ok['result'], isNotNull);
    });

    test('a member is not refused for lacking the single-repo argument such '
        'an op never carries', () async {
      forgeReadable.addAll(['granted:r-open', 'granted:r-closed']);
      final res = await call(dispatcher(), 'space.terminal', 'granted', {
        'space_id': 's1',
      });
      expect(res['result'], isNotNull);
      expect(handled, 1);
    });
  });
}
