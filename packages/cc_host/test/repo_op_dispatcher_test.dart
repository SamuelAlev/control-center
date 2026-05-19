import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/cc_host.dart';
import 'package:test/test.dart';

/// Dispatcher-level invariants for `repo/call` (FINDINGS §284): the closed
/// allow-list (the historical `opUnknown` footgun), the per-request
/// `workspace_id` chokepoint, fail-closed destructive approval, version
/// negotiation and that raw handler exceptions never leak to clients.
void main() {
  RepoOpDispatcher dispatcher({
    List<RepoOp>? ops,
    Future<bool> Function(RepoOp, Map<String, dynamic>)? confirm,
    RpcExceptionMapper? mapException,
  }) => RepoOpDispatcher(
    registry: RepoOpRegistry(
      ops ??
          [
            RepoOp(
              name: 'thing.get',
              kind: RepoOpKind.read,
              workspaceScoped: false,
              handler: (ctx) async => {'ok': true},
            ),
          ],
    ),
    confirm: confirm,
    mapException: mapException,
  );

  Future<Map<String, dynamic>> call(
    RepoOpDispatcher d,
    String op, {
    Map<String, dynamic> args = const {},
    int? opVersion,
  }) => d.call(
    id: 1,
    params: {'op': op, 'opVersion': ?opVersion, 'args': args},
    deviceId: 'caller',
    userId: 'user-1',
    sessionCapability: SessionCapability.fullClient,
  );

  int errorCode(Map<String, dynamic> res) =>
      (res['error'] as Map)['code'] as int;

  test('an unknown op is default-denied with opUnknown', () async {
    final res = await call(dispatcher(), 'thing.nope');
    expect(res['result'], isNull);
    expect(errorCode(res), RpcErrorCodes.opUnknown);
  });

  test('a missing op name is invalidParams', () async {
    final res = await dispatcher().call(
      id: 1,
      params: const {'args': <String, dynamic>{}},
      deviceId: 'caller',
      userId: 'user-1',
      sessionCapability: SessionCapability.fullClient,
    );
    expect(errorCode(res), RpcErrorCodes.invalidParams);
  });

  group('workspace existence gate', () {
    RepoOpDispatcher gated({
      required Future<bool> Function(String) workspaceExists,
      void Function()? onRoleLookup,
      void Function()? onHandler,
    }) => RepoOpDispatcher(
      registry: RepoOpRegistry([
        RepoOp(
          name: 'scoped.op',
          kind: RepoOpKind.read,
          handler: (ctx) async {
            onHandler?.call();
            return {'ok': true};
          },
        ),
      ]),
      workspaceExists: workspaceExists,
      resolveRole: (workspaceId, userId) async {
        onRoleLookup?.call();
        return WorkspaceRole.owner;
      },
    );

    test(
      'an unregistered workspace is refused not-found BEFORE role resolution',
      () async {
        // The role lookup opens the named workspace's database (creating the
        // file for an unknown id), so the gate must run first and the handler
        // must never run.
        var roleLookups = 0;
        var handlerRuns = 0;
        final res = await call(
          gated(
            workspaceExists: (_) async => false,
            onRoleLookup: () => roleLookups++,
            onHandler: () => handlerRuns++,
          ),
          'scoped.op',
          args: const {'workspace_id': 'ws-ghost'},
        );
        expect(errorCode(res), RpcErrorCodes.notFound);
        expect(roleLookups, 0);
        expect(handlerRuns, 0);
      },
    );

    test('a registered workspace flows through to role resolution', () async {
      var handlerRuns = 0;
      final res = await call(
        gated(
          workspaceExists: (_) async => true,
          onHandler: () => handlerRuns++,
        ),
        'scoped.op',
        args: const {'workspace_id': 'ws-1'},
      );
      expect(res['error'], isNull);
      expect(handlerRuns, 1);
    });
  });

  group('workspace_id chokepoint', () {
    RepoOpDispatcher scoped(void Function(String?) capture) => dispatcher(
      ops: [
        RepoOp(
          name: 'scoped.op',
          kind: RepoOpKind.read,
          // workspaceScoped defaults to true.
          handler: (ctx) async {
            capture(ctx.workspaceId);
            return {'ws': ctx.workspaceId};
          },
        ),
      ],
    );

    test('a workspace-scoped op without workspace_id is rejected', () async {
      String? seen = 'unset';
      final res = await call(scoped((w) => seen = w), 'scoped.op');
      expect(errorCode(res), RpcErrorCodes.validation);
      expect(
        (res['error'] as Map<String, dynamic>)['message'],
        contains('workspace_id'),
      );
      // The handler never ran — nothing leaked past the gate.
      expect(seen, 'unset');
    });

    test(
      'a workspace-scoped op threads workspace_id into the handler',
      () async {
        String? seen;
        final res = await call(
          scoped((w) => seen = w),
          'scoped.op',
          args: {'workspace_id': 'ws-1'},
        );
        expect(res['error'], isNull);
        expect(seen, 'ws-1');
        expect((res['result'] as Map)['data'], {'ws': 'ws-1'});
      },
    );
  });

  test(
    'an unsupported op version is rejected with the supported set',
    () async {
      final d = dispatcher(
        ops: [
          RepoOp(
            name: 'v.op',
            kind: RepoOpKind.read,
            workspaceScoped: false,
            version: 2,
            handler: (ctx) async => {'ok': true},
          ),
        ],
      );
      final res = await call(d, 'v.op', opVersion: 1);
      expect(errorCode(res), RpcErrorCodes.opVersionUnsupported);
      expect(((res['error'] as Map)['data'] as Map)['supported_versions'], [2]);
    },
  );

  test('a missing required arg is rejected before the handler', () async {
    var ran = false;
    final d = dispatcher(
      ops: [
        RepoOp(
          name: 'need.arg',
          kind: RepoOpKind.read,
          workspaceScoped: false,
          requiredArgs: const ['foo'],
          handler: (ctx) async {
            ran = true;
            return {'ok': true};
          },
        ),
      ],
    );
    final res = await call(d, 'need.arg');
    expect(errorCode(res), RpcErrorCodes.validation);
    expect(ran, isFalse);
  });

  group('destructive ops fail closed', () {
    RepoOp destructive(void Function() onRun) => RepoOp(
      name: 'danger.drop',
      kind: RepoOpKind.destructive,
      workspaceScoped: false,
      handler: (ctx) async {
        onRun();
        return {'dropped': true};
      },
    );

    test(
      'with no approver, a destructive op is denied and never runs',
      () async {
        var ran = false;
        final res = await call(
          dispatcher(ops: [destructive(() => ran = true)]),
          'danger.drop',
        );
        expect(errorCode(res), RpcErrorCodes.unauthorized);
        expect(ran, isFalse);
      },
    );

    test('a rejected approval denies the destructive op', () async {
      var ran = false;
      final res = await call(
        dispatcher(
          ops: [destructive(() => ran = true)],
          confirm: (_, _) async => false,
        ),
        'danger.drop',
      );
      expect(errorCode(res), RpcErrorCodes.unauthorized);
      expect(ran, isFalse);
    });

    test('an approved destructive op runs', () async {
      var ran = false;
      final res = await call(
        dispatcher(
          ops: [destructive(() => ran = true)],
          confirm: (_, _) async => true,
        ),
        'danger.drop',
      );
      expect(res['error'], isNull);
      expect(ran, isTrue);
      expect((res['result'] as Map)['data'], {'dropped': true});
    });
  });

  group('handler exceptions', () {
    RepoOpDispatcher throwing({RpcExceptionMapper? mapException}) => dispatcher(
      ops: [
        RepoOp(
          name: 'boom',
          kind: RepoOpKind.read,
          workspaceScoped: false,
          handler: (ctx) async =>
              throw StateError('secret /var/db/control_center.db leaked'),
        ),
      ],
      mapException: mapException,
    );

    test(
      'an unmapped exception surfaces internalError with no raw text',
      () async {
        final res = await call(throwing(), 'boom');
        expect(errorCode(res), RpcErrorCodes.internalError);
        expect(
          (res['error'] as Map<String, dynamic>)['message'],
          'Internal error',
        );
        // The raw exception text (with a path) must never reach the client.
        expect('$res', isNot(contains('control_center.db')));
        // …but a greppable diagnostic id IS returned for log correlation (§126).
        final diagId =
            ((res['error'] as Map)['data'] as Map)['diagnostic_id'] as String;
        expect(diagId, isNotEmpty);
      },
    );

    test('each internal error gets a distinct diagnostic id', () async {
      final d = throwing();
      final a =
          (((await call(d, 'boom'))['error'] as Map)['data']
              as Map)['diagnostic_id'];
      final b =
          (((await call(d, 'boom'))['error'] as Map)['data']
              as Map)['diagnostic_id'];
      expect(a, isNot(b));
    });

    test('a mapped exception surfaces its stable code + message', () async {
      final res = await call(
        throwing(
          mapException: (e) => const RpcErrorMapping(
            RpcErrorCodes.conflict,
            'Conflicting write',
          ),
        ),
        'boom',
      );
      expect(errorCode(res), RpcErrorCodes.conflict);
      expect(
        (res['error'] as Map<String, dynamic>)['message'],
        'Conflicting write',
      );
    });
  });
}
