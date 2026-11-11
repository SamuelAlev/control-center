import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// The server-scope trail: the dispatcher records every install-wide mutating
/// call with its argument names and outcome, never an argument value.
void main() {
  late List<Map<String, Object?>> records;

  setUp(() => records = []);

  Future<void> record({
    required String userId,
    required String deviceId,
    required String op,
    required List<String> argNames,
    required String outcome,
    String? ip,
  }) async {
    records.add({
      'userId': userId,
      'deviceId': deviceId,
      'op': op,
      'argNames': argNames,
      'outcome': outcome,
      'ip': ip,
    });
  }

  RepoOp op(
    String name, {
    RepoOpKind kind = RepoOpKind.mutate,
    bool workspaceScoped = false,
    bool audited = true,
    ServerAuthority authority = ServerAuthority.none,
    Future<Map<String, dynamic>> Function(RepoOpContext)? handler,
  }) => RepoOp(
    name: name,
    kind: kind,
    workspaceScoped: workspaceScoped,
    audited: audited,
    serverAuthority: authority,
    preview: (ctx) async => const ActionPreview(summary: 'would change'),
    handler: handler ?? (ctx) async => {'saved': true},
  );

  RepoOpDispatcher dispatcher(
    List<RepoOp> ops, {
    bool owner = true,
    ServerAuditRecorder? recorder,
  }) => RepoOpDispatcher(
    registry: RepoOpRegistry(ops),
    resolveServerOwner: (_) async => owner,
    resolveRole: (_, _) async => WorkspaceRole.admin,
    recordServerAudit: recorder ?? record,
  );

  Future<Map<String, dynamic>> call(
    RepoOpDispatcher d,
    String name, {
    Map<String, dynamic> args = const {},
    bool dryRun = false,
  }) async {
    final res = await d.call(
      id: 1,
      params: {'op': name, 'args': args, if (dryRun) 'dry_run': true},
      deviceId: 'device-1',
      userId: 'user-1',
      sessionCapability: SessionCapability.fullClient,
      remoteAddress: '127.0.0.1',
    );
    // The write is fire and forget; let it land.
    await Future<void>.delayed(Duration.zero);
    return res;
  }

  test('a successful call is recorded with argument names only', () async {
    final d = dispatcher([op('connect.rotateKey')]);
    final res = await call(
      d,
      'connect.rotateKey',
      args: {'url': 'https://connect.example', 'key': 'CONNECT-KEY-VALUE'},
    );

    expect(res['result'], isNotNull);
    expect(records, [
      {
        'userId': 'user-1',
        'deviceId': 'device-1',
        'op': 'connect.rotateKey',
        'argNames': ['url', 'key'],
        'outcome': 'ok',
        'ip': '127.0.0.1',
      },
    ]);
    expect('$records', isNot(contains('CONNECT-KEY-VALUE')));
  });

  test('a refusal by a gate is recorded as denied', () async {
    final d = dispatcher([
      op('server.set', authority: ServerAuthority.serverOwner),
    ], owner: false);
    final res = await call(d, 'server.set', args: {'value': 1});

    expect((res['error'] as Map)['code'], RpcErrorCodes.unauthorized);
    expect(records.single['outcome'], 'denied');
  });

  test('a handler that throws is recorded as failed', () async {
    final d = dispatcher([
      op('server.set', handler: (_) async => throw StateError('boom')),
    ]);
    final res = await call(d, 'server.set');

    expect((res['error'] as Map)['code'], RpcErrorCodes.internalError);
    expect(records.single['outcome'], 'failed');
  });

  test(
    'reads, workspace ops, opted-out ops and dry runs are not recorded',
    () async {
      final d = dispatcher([
        op('server.get', kind: RepoOpKind.read),
        op('tickets.assign', workspaceScoped: true),
        op('cache.write', audited: false),
        op('server.set'),
      ]);
      await call(d, 'server.get');
      await call(d, 'tickets.assign', args: {'workspace_id': 'ws-1'});
      await call(d, 'cache.write');
      final preview = await call(d, 'server.set', dryRun: true);

      expect(preview['result'], isNotNull);
      expect(records, isEmpty);
    },
  );

  test(
    'an op that is not found or misses an argument is not recorded',
    () async {
      final d = dispatcher([
        RepoOp(
          name: 'server.set',
          kind: RepoOpKind.mutate,
          workspaceScoped: false,
          requiredArgs: const ['value'],
          handler: (_) async => {},
        ),
      ]);
      await call(d, 'server.nope');
      await call(d, 'server.set');

      expect(records, isEmpty);
    },
  );

  test('a failed write never changes the answer', () async {
    final d = dispatcher(
      [op('server.set')],
      recorder:
          ({
            required userId,
            required deviceId,
            required op,
            required argNames,
            required outcome,
            ip,
          }) => Future.error(StateError('disk full')),
    );
    final res = await call(d, 'server.set');

    expect(res['result'], isNotNull);
  });

  test('serverAudited names exactly the unscoped, audited mutations', () {
    expect(RepoOpDispatcher.serverAudited(op('a.set')), isTrue);
    expect(
      RepoOpDispatcher.serverAudited(
        op('a.drop', kind: RepoOpKind.destructive),
      ),
      isTrue,
    );
    expect(
      RepoOpDispatcher.serverAudited(op('a.get', kind: RepoOpKind.read)),
      isFalse,
    );
    expect(
      RepoOpDispatcher.serverAudited(op('a.set', workspaceScoped: true)),
      isFalse,
    );
    expect(
      RepoOpDispatcher.serverAudited(op('a.set', audited: false)),
      isFalse,
    );
  });
}
