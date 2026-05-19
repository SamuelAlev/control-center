import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/repo_grant_level.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

void main() {
  const wsArgs = {'workspace_id': 'ws-1'};

  RepoOpDispatcher dispatcher({
    required Map<String, WorkspaceRole> roles,
    Map<String, RepoGrantLevel> grants = const {},
    List<RepoOp>? ops,
    List<Map<String, Object?>>? auditSink,
  }) => RepoOpDispatcher(
    registry: RepoOpRegistry(
      ops ??
          [
            RepoOp(
              name: 'thing.read',
              kind: RepoOpKind.read,
              handler: (ctx) async => {'ok': true},
            ),
            RepoOp(
              name: 'thing.mutate',
              kind: RepoOpKind.mutate,
              handler: (ctx) async => {'ok': true},
            ),
            RepoOp(
              name: 'thing.adminOnly',
              kind: RepoOpKind.mutate,
              minRole: WorkspaceRole.admin,
              handler: (ctx) async => {'ok': true},
            ),
            RepoOp(
              name: 'repo.readFile',
              kind: RepoOpKind.read,
              repoAccess: RepoGrantLevel.read,
              handler: (ctx) async => {'ok': true},
            ),
          ],
    ),
    resolveRole: (workspaceId, userId) async => roles[userId],
    resolveRepoGrant: (workspaceId, userId, repoId) async =>
        grants['$userId:$repoId'] ?? RepoGrantLevel.none,
    recordActivity: auditSink == null
        ? null
        : ({
            required String workspaceId,
            required String userId,
            required String deviceId,
            required String action,
            String? targetType,
            String? targetId,
            String? ip,
          }) async {
            auditSink.add({
              'workspace_id': workspaceId,
              'user_id': userId,
              'action': action,
              'target_id': targetId,
              'ip': ip,
            });
          },
  );

  Future<Map<String, dynamic>> call(
    RepoOpDispatcher d,
    String op,
    String userId, {
    Map<String, dynamic> args = wsArgs,
    String? remoteAddress,
  }) => d.call(
    id: 1,
    params: {'op': op, 'args': args},
    deviceId: 'dev-$userId',
    userId: userId,
    sessionCapability: SessionCapability.fullClient,
    remoteAddress: remoteAddress,
  );

  int errorCode(Map<String, dynamic> res) =>
      (res['error'] as Map)['code'] as int;

  group('role gate', () {
    test('a non-member is refused every workspace-scoped op, loudly', () async {
      final d = dispatcher(roles: {'alice': WorkspaceRole.admin});
      for (final op in ['thing.read', 'thing.mutate']) {
        final res = await call(d, op, 'stranger');
        expect(res['result'], isNull, reason: op);
        expect(errorCode(res), RpcErrorCodes.unauthorized, reason: op);
      }
    });

    test('a viewer reads but is refused mutations with unauthorized', () async {
      final d = dispatcher(roles: {'vera': WorkspaceRole.viewer});
      final read = await call(d, 'thing.read', 'vera');
      expect(read['error'], isNull);
      final mutate = await call(d, 'thing.mutate', 'vera');
      expect(errorCode(mutate), RpcErrorCodes.unauthorized);
      expect(
        ((mutate['error'] as Map)['message'] as String).toLowerCase(),
        contains('role'),
      );
    });

    test('a guest is read-only too', () async {
      final d = dispatcher(roles: {'gus': WorkspaceRole.guest});
      expect((await call(d, 'thing.read', 'gus'))['error'], isNull);
      expect(
        errorCode(await call(d, 'thing.mutate', 'gus')),
        RpcErrorCodes.unauthorized,
      );
    });

    test('a member mutates but is refused an admin-gated op', () async {
      final d = dispatcher(roles: {'mia': WorkspaceRole.member});
      expect((await call(d, 'thing.mutate', 'mia'))['error'], isNull);
      expect(
        errorCode(await call(d, 'thing.adminOnly', 'mia')),
        RpcErrorCodes.unauthorized,
      );
    });

    test('an admin passes the admin-gated op', () async {
      final d = dispatcher(roles: {'ada': WorkspaceRole.admin});
      expect((await call(d, 'thing.adminOnly', 'ada'))['error'], isNull);
    });

    test('an owner passes everything', () async {
      final d = dispatcher(roles: {'omar': WorkspaceRole.owner});
      for (final op in ['thing.read', 'thing.mutate', 'thing.adminOnly']) {
        expect((await call(d, op, 'omar'))['error'], isNull, reason: op);
      }
    });

    test('an unscoped op skips the role gate', () async {
      final d = dispatcher(
        roles: const {},
        ops: [
          RepoOp(
            name: 'global.read',
            kind: RepoOpKind.read,
            workspaceScoped: false,
            handler: (ctx) async => {'ok': true},
          ),
        ],
      );
      final res = await call(d, 'global.read', 'anyone', args: const {});
      expect(res['error'], isNull);
    });
  });

  group('per-repo grant gate', () {
    const repoArgs = {'workspace_id': 'ws-1', 'repo_id': 'r-1'};

    test('a member without a grant is refused the code-bearing op', () async {
      final d = dispatcher(roles: {'mia': WorkspaceRole.member});
      final res = await call(d, 'repo.readFile', 'mia', args: repoArgs);
      expect(errorCode(res), RpcErrorCodes.unauthorized);
    });

    test('a member with a read grant passes', () async {
      final d = dispatcher(
        roles: {'mia': WorkspaceRole.member},
        grants: {'mia:r-1': RepoGrantLevel.read},
      );
      final res = await call(d, 'repo.readFile', 'mia', args: repoArgs);
      expect(res['error'], isNull);
    });

    test('admins hold every grant implicitly', () async {
      final d = dispatcher(roles: {'ada': WorkspaceRole.admin});
      final res = await call(d, 'repo.readFile', 'ada', args: repoArgs);
      expect(res['error'], isNull);
    });

    test('a repo-scoped op with a missing repo_id fails closed', () async {
      final d = dispatcher(
        roles: {'mia': WorkspaceRole.member},
        grants: {'mia:r-1': RepoGrantLevel.read},
      );
      // Same op, but repo_id omitted — must NOT silently bypass the gate.
      final res = await call(
        d,
        'repo.readFile',
        'mia',
        args: {'workspace_id': 'ws-1'},
      );
      expect(errorCode(res), RpcErrorCodes.unauthorized);
    });
  });

  group('audit trail', () {
    test('a successful mutation appends who did what; reads do not', () async {
      final sink = <Map<String, Object?>>[];
      final d = dispatcher(
        roles: {'mia': WorkspaceRole.member},
        auditSink: sink,
      );
      await call(d, 'thing.read', 'mia');
      expect(sink, isEmpty);
      await call(
        d,
        'thing.mutate',
        'mia',
        args: const {'workspace_id': 'ws-1', 'id': 't-9'},
      );
      // Fire-and-forget append — allow the microtask to land.
      await Future<void>.delayed(Duration.zero);
      expect(sink, hasLength(1));
      expect(sink.single['user_id'], 'mia');
      expect(sink.single['action'], 'thing.mutate');
      expect(sink.single['target_id'], 't-9');
    });

    test('a denied mutation appends nothing', () async {
      final sink = <Map<String, Object?>>[];
      final d = dispatcher(
        roles: {'vera': WorkspaceRole.viewer},
        auditSink: sink,
      );
      await call(d, 'thing.mutate', 'vera');
      await Future<void>.delayed(Duration.zero);
      expect(sink, isEmpty);
    });

    test('the session remoteAddress lands on the audit record as ip', () async {
      final sink = <Map<String, Object?>>[];
      final d = dispatcher(
        roles: {'mia': WorkspaceRole.member},
        auditSink: sink,
      );
      await call(
        d,
        'thing.mutate',
        'mia',
        args: const {'workspace_id': 'ws-1', 'id': 't-9'},
        remoteAddress: '203.0.113.7',
      );
      await Future<void>.delayed(Duration.zero);
      expect(sink, hasLength(1));
      expect(sink.single['ip'], '203.0.113.7');
    });

    test('a call with no observable peer audits a null ip', () async {
      final sink = <Map<String, Object?>>[];
      final d = dispatcher(
        roles: {'mia': WorkspaceRole.member},
        auditSink: sink,
      );
      await call(d, 'thing.mutate', 'mia');
      await Future<void>.delayed(Duration.zero);
      expect(sink, hasLength(1));
      expect(sink.single['ip'], isNull);
    });

    test('an op declared unaudited appends nothing', () async {
      final sink = <Map<String, Object?>>[];
      final d = dispatcher(
        roles: {'mia': WorkspaceRole.member},
        auditSink: sink,
        ops: [
          RepoOp(
            name: 'cache.write',
            kind: RepoOpKind.mutate,
            audited: false,
            handler: (ctx) async => {'ok': true},
          ),
        ],
      );
      final res = await call(d, 'cache.write', 'mia');
      await Future<void>.delayed(Duration.zero);
      expect(res['error'], isNull);
      expect(sink, isEmpty);
    });
  });
}
