import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _result(Map<String, dynamic> r) =>
    (r['result'] as Map)['data'] as Map<String, dynamic>;
int _errorCode(Map<String, dynamic> r) => (r['error'] as Map)['code'] as int;

void main() {
  final registry = RepoOpRegistry([
    RepoOp(
      name: 'tickets.list',
      kind: RepoOpKind.read,
      handler: (ctx) async => {
        'workspace_id': ctx.workspaceId,
        'args_ws': ctx.args['workspace_id'],
      },
    ),
    RepoOp(
      name: 'feeds.list',
      kind: RepoOpKind.read,
      workspaceScoped: false,
      handler: (ctx) async => {
        'global': true,
        'has_ws': ctx.args.containsKey('workspace_id'),
      },
    ),
    RepoOp(
      name: 'tickets.assign',
      kind: RepoOpKind.mutate,
      requiredArgs: ['ticket_id'],
      handler: (ctx) async => {'ok': true},
    ),
    RepoOp(
      name: 'tickets.delete',
      kind: RepoOpKind.destructive,
      handler: (ctx) async => {'deleted': true},
    ),
    RepoOp(
      name: 'tickets.getStale',
      kind: RepoOpKind.read,
      handler: (ctx) async =>
          throw const ConcurrencyConflictException('changed since load'),
    ),
  ], catalogVersion: 3);
  // No approver; inject the app's exception→code mapper (cc_host is generic).
  final dispatcher = RepoOpDispatcher(
    registry: registry,
    mapException: mapAppExceptionToRpc,
  );

  // The server is stateless: a workspace-scoped op carries its target
  // `workspace_id` per-request inside `args`. The helper injects `ws` into args
  // (unless the caller already supplied one, or [ws] is null) so the
  // protocol-semantics tests below exercise scoped ops without restating it.
  Future<Map<String, dynamic>> call(
    Map<String, dynamic> params, {
    String? ws = 'ws1',
  }) {
    if (ws != null) {
      final rawArgs = params['args'];
      final args = rawArgs is Map
          ? Map<String, dynamic>.from(rawArgs)
          : <String, dynamic>{};
      args.putIfAbsent('workspace_id', () => ws);
      params = {...params, 'args': args};
    }
    return dispatcher.call(
      id: 1,
      params: params,
      deviceId: 'dev-1',
      sessionCapability: SessionCapability.fullClient,
    );
  }

  group('RepoOpDispatcher — workspace isolation', () {
    test(
      'uses the client-supplied workspace_id from args (no override)',
      () async {
        // The server is stateless — whatever workspace the client names in args
        // is exactly what the handler scopes to; nothing overwrites it.
        final r = await call({
          'op': 'tickets.list',
          'args': {'workspace_id': 'client-ws'},
        }, ws: null);
        expect(_result(r)['workspace_id'], 'client-ws');
        expect(_result(r)['args_ws'], 'client-ws');
      },
    );

    test(
      'denies a workspace-scoped op when args lack workspace_id',
      () async {
        final r = await call({'op': 'tickets.list', 'args': {}}, ws: null);
        expect(_errorCode(r), RpcErrorCodes.validation);
        expect(
          (r['error'] as Map)['message'],
          'Missing required argument: workspace_id',
        );
      },
    );

    test('global op leaves a client workspace_id untouched', () async {
      // An unscoped (workspaceScoped: false) op never gates on workspace, so any
      // client-supplied workspace_id passes through to the handler verbatim — it
      // is a plain selector, not stripped — while ctx.workspaceId stays null.
      final r = await call({
        'op': 'feeds.list',
        'args': {'workspace_id': 'x'},
      }, ws: null);
      expect(_result(r)['global'], true);
      expect(_result(r)['has_ws'], true); // not stripped
    });
  });

  group('RepoOpDispatcher — protocol semantics', () {
    test('unknown op is default-denied', () async {
      final r = await call({'op': 'nope.nope'});
      expect(_errorCode(r), RpcErrorCodes.opUnknown);
    });

    test('missing required arg fails validation', () async {
      final r = await call({'op': 'tickets.assign', 'args': {}});
      expect(_errorCode(r), RpcErrorCodes.validation);
    });

    test('destructive op with no approver is denied', () async {
      final r = await call({'op': 'tickets.delete', 'args': {}});
      expect(_errorCode(r), RpcErrorCodes.unauthorized);
    });

    test('op-version mismatch is reported', () async {
      final r = await call({'op': 'tickets.list', 'opVersion': 99, 'args': {}});
      expect(_errorCode(r), RpcErrorCodes.opVersionUnsupported);
    });

    test(
      'handler ConcurrencyConflictException maps to conflict code',
      () async {
        final r = await call({'op': 'tickets.getStale', 'args': {}});
        expect(_errorCode(r), RpcErrorCodes.conflict);
      },
    );

    test('op/list returns the catalog + version', () {
      final r = dispatcher.list(9);
      final result = r['result'] as Map<String, dynamic>;
      expect(result['catalog_version'], 3);
      expect(result['ops'] as List, hasLength(5));
    });

    test('destructive op runs when the approver grants it', () async {
      final approving = RepoOpDispatcher(
        registry: registry,
        confirm: (op, args) async => true,
      );
      final r = await approving.call(
        id: 1,
        params: {
          'op': 'tickets.delete',
          'args': {'workspace_id': 'ws1'},
        },
        deviceId: 'dev-1',
        sessionCapability: SessionCapability.fullClient,
      );
      expect((r['result'] as Map)['data'], {'deleted': true});
    });
  });
}
