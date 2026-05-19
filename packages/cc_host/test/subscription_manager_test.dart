import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_host/src/errors/rpc_error_mapping.dart';
import 'package:cc_host/src/repo_rpc/repo_op.dart';
import 'package:cc_host/src/repo_rpc/repo_op_dispatcher.dart'
    show WorkspaceRoleResolver;
import 'package:cc_host/src/repo_rpc/subscription_manager.dart';
import 'package:cc_host/src/repo_rpc/watch_query.dart';
import 'package:test/test.dart';

/// Unit coverage for [SubscriptionManager]: the subscribe/unsubscribe surface,
/// the per-session cap, the workspace_id chokepoint, snapshot/error pushes and
/// teardown (invalidateAll / dispose). Drives the manager directly (the session
/// wiring is covered in remote_rpc_session_test.dart).
void main() {
  group('SubscriptionManager.subscribe', () {
    test('rejects a missing/empty query name with invalidParams', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);

      final res = mgr.subscribe(id: 1, params: const {});
      expect(_code(res), RpcErrorCodes.invalidParams);
      expect(_msg(res), 'Missing query');

      final empty = mgr.subscribe(id: 2, params: const {'query': ''});
      expect(_code(empty), RpcErrorCodes.invalidParams);
    });

    test('rejects an unknown query with opUnknown (default-deny)', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(id: 1, params: const {'query': 'nope'});
      expect(_code(res), RpcErrorCodes.opUnknown);
      expect(_msg(res), contains('Unknown query'));
    });

    test('a workspace-scoped query without workspace_id is rejected', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(id: 1, params: const {'query': 'scoped.watch'});
      expect(_code(res), RpcErrorCodes.validation);
      expect(_msg(res), 'Missing required argument: workspace_id');
    });

    test('rejects an empty workspace_id as missing', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(
        id: 1,
        params: const {
          'query': 'scoped.watch',
          'args': {'workspace_id': ''},
        },
      );
      expect(_code(res), RpcErrorCodes.validation);
    });

    test('a global query subscribes with no workspace_id required', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(id: 1, params: const {'query': 'newsfeed'});
      expect(res['error'], isNull);
      final result = res['result'] as Map<String, dynamic>;
      expect(result['subscriptionId'], isA<String>());
      expect(result['rev'], 0);
    });

    test(
      'a scoped query subscribes and emits a sub/snapshot on each change',
      () async {
        final mgr = _harness();
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(
          id: 1,
          params: const {
            'query': 'scoped.watch',
            'args': {'workspace_id': 'ws-1'},
          },
        );
        final subId = (res['result'] as Map)['subscriptionId'] as String;

        // The handler emits an initial snapshot synchronously; let it land.
        await pumpEventQueue(times: 10);
        final snapshot = mgr.sent.lastWhere(
          (f) => f['method'] == RpcMethods.subSnapshot,
        );
        final params = snapshot['params'] as Map<String, dynamic>;
        expect(params['subscriptionId'], subId);
        expect(params['rev'], 1);
        expect(params['full'], isTrue);
        expect(params['data'], {
          'rows': ['ws-1'],
        });
      },
    );

    test('a handler that throws synchronously returns internalError', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(id: 1, params: const {'query': 'throws'});
      expect(_code(res), RpcErrorCodes.internalError);
      expect(_msg(res), 'Subscription failed');
    });

    test('a synchronous domain rejection is classified by mapException', () {
      final mgr = _harness(
        mapException: (e) => e is NotFoundException
            ? RpcErrorMapping(RpcErrorCodes.notFound, e.message)
            : null,
      );
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(
        id: 1,
        params: const {'query': 'throws_not_found'},
      );
      // A handler can reject BEFORE returning a stream (an unknown terminal
      // session id after a server restart). As internalError the client read it
      // as transient and resubscribed forever; notFound is unrecoverable, so the
      // client stops after one attempt.
      expect(_code(res), RpcErrorCodes.notFound);
      expect(_msg(res), 'Terminal session not found: tty1-abc');
    });

    test(
      'a stream error pushes sub/error and cancels the subscription',
      () async {
        final mgr = _harness();
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(id: 1, params: const {'query': 'errors'});
        expect(res['error'], isNull);
        await pumpEventQueue(times: 15);

        final err = mgr.sent.lastWhere(
          (f) => f['method'] == RpcMethods.subError,
        );
        final errParams = err['params'] as Map<String, dynamic>;
        expect(errParams['code'], RpcErrorCodes.internalError);
        expect((errParams['data'] as Map)['kind'], 'stream_error');
      },
    );

    test(
      'a classified NetworkException stream error forwards its RPC code',
      () async {
        final mgr = _harness();
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(
          id: 1,
          params: const {'query': 'rate_limited'},
        );
        expect(res['error'], isNull);
        await pumpEventQueue(times: 15);

        final err = mgr.sent.lastWhere(
          (f) => f['method'] == RpcMethods.subError,
        );
        final errParams = err['params'] as Map<String, dynamic>;
        // A rate limit must reach the client as rateLimited (not the generic
        // internalError) so the client's retry policy does NOT resubscribe.
        expect(errParams['code'], RpcErrorCodes.rateLimited);
        expect((errParams['data'] as Map)['kind'], 'stream_error');
      },
    );

    test('an upstream 404 stream error forwards notFound', () async {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(id: 1, params: const {'query': 'not_found'});
      expect(res['error'], isNull);
      await pumpEventQueue(times: 15);

      final err = mgr.sent.lastWhere((f) => f['method'] == RpcMethods.subError);
      final errParams = err['params'] as Map<String, dynamic>;
      // A 404 (a PR that does not exist upstream) is unrecoverable: it must
      // reach the client as notFound so its retry policy does NOT resubscribe
      // (each resubscribe re-issues the doomed GitHub fetch).
      expect(errParams['code'], RpcErrorCodes.notFound);
      expect((errParams['data'] as Map)['kind'], 'stream_error');
    });

    test(
      'a domain exception classified by mapException forwards its code',
      () async {
        final mgr = _harness(
          mapException: (e) => e is WorkspaceMismatchException
              ? RpcErrorMapping(RpcErrorCodes.workspaceMismatch, e.message)
              : null,
        );
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(
          id: 1,
          params: const {'query': 'workspace_mismatch'},
        );
        expect(res['error'], isNull);
        await pumpEventQueue(times: 15);

        final err = mgr.sent.lastWhere(
          (f) => f['method'] == RpcMethods.subError,
        );
        final errParams = err['params'] as Map<String, dynamic>;
        // The workspace chokepoint rejection must reach the client as
        // workspaceMismatch — an error a resubscribe can never fix — not as the
        // retryable generic internalError.
        expect(errParams['code'], RpcErrorCodes.workspaceMismatch);
        expect((errParams['data'] as Map)['kind'], 'stream_error');
      },
    );

    test('rejects past the per-session cap with tooManySubscriptions', () {
      final mgr = _harness(maxPerSession: 2);
      addTearDown(mgr.dispose);
      for (var i = 0; i < 2; i++) {
        final res = mgr.subscribe(id: i, params: const {'query': 'newsfeed'});
        expect(res['error'], isNull, reason: 'subscription $i should succeed');
      }
      final over = mgr.subscribe(id: 99, params: const {'query': 'newsfeed'});
      expect(_code(over), RpcErrorCodes.tooManySubscriptions);
      expect(_msg(over), contains('Subscription limit (2)'));
    });
  });

  group('SubscriptionManager.unsubscribe', () {
    test('cancels a known subscription and returns ok', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(
        id: 1,
        params: const {
          'query': 'scoped.watch',
          'args': {'workspace_id': 'ws-1'},
        },
      );
      final subId = (res['result'] as Map)['subscriptionId'] as String;

      final unsub = mgr.unsubscribe(id: 2, params: {'subscriptionId': subId});
      expect(unsub['result'], {'ok': true});
    });

    test('a non-string subscriptionId is a harmless ok (no crash)', () {
      final mgr = _harness();
      addTearDown(mgr.dispose);
      final res = mgr.unsubscribe(id: 2, params: const {'subscriptionId': 42});
      expect(res['result'], {'ok': true});
    });
  });

  group('SubscriptionManager.invalidateAll', () {
    test(
      'pushes a sub/error per live subscription and tears them all down',
      () async {
        final mgr = _harness();
        addTearDown(mgr.dispose);
        mgr.subscribe(
          id: 1,
          params: const {
            'query': 'scoped.watch',
            'args': {'workspace_id': 'ws-1'},
          },
        );
        mgr.subscribe(id: 2, params: const {'query': 'newsfeed'});
        mgr.sent.clear();

        mgr.invalidateAll('workspace_changed');
        await pumpEventQueue(times: 10);

        final errs = mgr.sent.where((f) => f['method'] == RpcMethods.subError);
        expect(errs, hasLength(2));
        for (final e in errs) {
          final params = e['params'] as Map<String, dynamic>;
          expect(params['code'], RpcErrorCodes.workspaceMismatch);
          expect((params['data'] as Map)['kind'], 'workspace_changed');
        }

        // After invalidateAll, the manager holds no subscriptions: a re-invalidate
        // emits nothing.
        mgr.sent.clear();
        mgr.invalidateAll('again');
        expect(
          mgr.sent.where((f) => f['method'] == RpcMethods.subError),
          isEmpty,
        );
      },
    );
  });

  group('SubscriptionManager.dispose', () {
    test('cancels every subscription with no client notification', () async {
      final mgr = _harness();
      mgr.subscribe(
        id: 1,
        params: const {
          'query': 'scoped.watch',
          'args': {'workspace_id': 'ws-1'},
        },
      );
      mgr.sent.clear();

      await mgr.dispose();
      // The underlying stream is cancelled — pumping more data emits nothing.
      mgr.scopedController.add({
        'rows': ['never'],
      });
      await pumpEventQueue(times: 10);
      expect(mgr.sent, isEmpty);
    });
  });

  group('SubscriptionManager workspace existence gate', () {
    test(
      'an unregistered workspace is refused as not-found and the handler '
      'never runs',
      () async {
        final mgr = _harness(workspaceExists: (_) async => false);
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(
          id: 1,
          params: const {
            'query': 'scoped.watch',
            'args': {'workspace_id': 'ws-ghost'},
          },
        );
        // The ack lands synchronously; the refusal follows asynchronously as
        // a sub/error push (the client surfaces it as a stream error).
        expect(res['error'], isNull);
        expect((res['result'] as Map)['subscriptionId'], isA<String>());

        await pumpEventQueue(times: 10);
        final error = mgr.sent.lastWhere(
          (f) => f['method'] == RpcMethods.subError,
        );
        expect((error['params'] as Map)['code'], RpcErrorCodes.notFound);
        // The handler never attached: no snapshot was pushed and nothing is
        // listening on the scoped stream (attaching opens the workspace's
        // database — the ghost-file bug this gate exists to prevent).
        expect(
          mgr.sent.where((f) => f['method'] == RpcMethods.subSnapshot),
          isEmpty,
        );
        expect(mgr.scopedController.hasListener, isFalse);
      },
    );

    test('a registered workspace attaches and emits normally', () async {
      final mgr = _harness(workspaceExists: (_) async => true);
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(
        id: 1,
        params: const {
          'query': 'scoped.watch',
          'args': {'workspace_id': 'ws-1'},
        },
      );
      expect(res['error'], isNull);
      await pumpEventQueue(times: 10);
      final snapshot = mgr.sent.lastWhere(
        (f) => f['method'] == RpcMethods.subSnapshot,
      );
      expect(snapshot['params'], isNotNull);
    });

    test(
      'unsubscribing while the gate resolves attaches nothing and sends no '
      'error',
      () async {
        final gate = Completer<bool>();
        final mgr = _harness(workspaceExists: (_) => gate.future);
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(
          id: 1,
          params: const {
            'query': 'scoped.watch',
            'args': {'workspace_id': 'ws-1'},
          },
        );
        final subId = (res['result'] as Map)['subscriptionId'] as String;
        mgr.unsubscribe(id: 2, params: {'subscriptionId': subId});
        gate.complete(true);
        await pumpEventQueue(times: 10);
        expect(
          mgr.sent.where((f) => f['method'] == RpcMethods.subError),
          isEmpty,
        );
        expect(
          mgr.sent.where((f) => f['method'] == RpcMethods.subSnapshot),
          isEmpty,
        );
        expect(mgr.scopedController.hasListener, isFalse);
      },
    );
  });

  group('SubscriptionManager membership gate', () {
    test(
      'a non-member is refused with unauthorized and the handler never runs',
      () async {
        final mgr = _harness(
          workspaceExists: (_) async => true,
          resolveRole: (workspaceId, userId) async => null, // not a member
        );
        addTearDown(mgr.dispose);
        final res = mgr.subscribe(
          id: 1,
          params: const {
            'query': 'scoped.watch',
            'args': {'workspace_id': 'ws-1'},
          },
        );
        // The ack lands synchronously; the refusal follows asynchronously as
        // a sub/error push, exactly like the existence gate.
        expect(res['error'], isNull);
        expect((res['result'] as Map)['subscriptionId'], isA<String>());

        await pumpEventQueue(times: 10);
        final error = mgr.sent.lastWhere(
          (f) => f['method'] == RpcMethods.subError,
        );
        expect((error['params'] as Map)['code'], RpcErrorCodes.unauthorized);
        // The handler never attached: no snapshot, no listener on the scoped
        // stream — a non-member streams nothing from the workspace.
        expect(
          mgr.sent.where((f) => f['method'] == RpcMethods.subSnapshot),
          isEmpty,
        );
        expect(mgr.scopedController.hasListener, isFalse);
      },
    );

    test('a member attaches and emits normally', () async {
      final mgr = _harness(
        workspaceExists: (_) async => true,
        resolveRole: (workspaceId, userId) async => WorkspaceRole.member,
      );
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(
        id: 1,
        params: const {
          'query': 'scoped.watch',
          'args': {'workspace_id': 'ws-1'},
        },
      );
      expect(res['error'], isNull);
      await pumpEventQueue(times: 10);
      final snapshot = mgr.sent.lastWhere(
        (f) => f['method'] == RpcMethods.subSnapshot,
      );
      expect((snapshot['params'] as Map)['data'], {
        'rows': ['ws-1'],
      });
    });

    test('global queries skip the membership gate entirely', () async {
      var roleChecks = 0;
      final mgr = _harness(
        resolveRole: (workspaceId, userId) async {
          roleChecks++;
          return null;
        },
      );
      addTearDown(mgr.dispose);
      final res = mgr.subscribe(id: 1, params: const {'query': 'newsfeed'});
      expect(res['error'], isNull);
      await pumpEventQueue(times: 10);
      expect(roleChecks, 0);
      expect(
        mgr.sent.where((f) => f['method'] == RpcMethods.subSnapshot),
        isNotEmpty,
      );
    });
  });

  group('SubscriptionManager.dropWorkspace', () {
    test(
      'tears down only the named workspace’s subscriptions with an '
      'unauthorized sub/error',
      () async {
        final mgr = _harness();
        addTearDown(mgr.dispose);
        mgr.subscribe(
          id: 1,
          params: const {
            'query': 'scoped.watch',
            'args': {'workspace_id': 'ws-1'},
          },
        );
        // Global subscription must survive a workspace-scoped drop.
        mgr.subscribe(id: 2, params: const {'query': 'newsfeed'});
        await pumpEventQueue(times: 10);
        mgr.sent.clear();

        mgr.mgr.dropWorkspace('ws-1');
        await pumpEventQueue(times: 10);

        final errs = mgr.sent
            .where((f) => f['method'] == RpcMethods.subError)
            .toList();
        expect(errs, hasLength(1));
        final params = errs.single['params'] as Map<String, dynamic>;
        expect(params['code'], RpcErrorCodes.unauthorized);
        expect((params['data'] as Map)['kind'], 'member_removed');

        // The dropped subscription is gone: pushing to its stream emits
        // nothing more, while the global one stays attached.
        mgr.scopedController.add({
          'rows': ['after-revoke'],
        });
        mgr.newsfeedController.add(const {'rows': ['global']});
        await pumpEventQueue(times: 10);
        final snapshots = mgr.sent
            .where((f) => f['method'] == RpcMethods.subSnapshot)
            .toList();
        expect(snapshots, hasLength(1));
        expect(
          (snapshots.single['params'] as Map)['data'],
          {
            'rows': ['global'],
          },
        );
      },
    );
  });
}

/// A wired [SubscriptionManager] with a few declared queries and a recorder for
/// every frame it pushes.
_Harness _harness({
  int? maxPerSession,
  RpcExceptionMapper? mapException,
  WorkspaceExistsChecker? workspaceExists,
  WorkspaceRoleResolver? resolveRole,
}) {
  final scopedController = StreamController<Map<String, dynamic>>.broadcast();
  final newsfeedController = StreamController<Map<String, dynamic>>.broadcast();
  final queries = WatchQueryRegistry([
    WatchQuery(
      name: 'scoped.watch',
      handler: _controllable(scopedController, scoped: true),
    ),
    WatchQuery(
      name: 'newsfeed',
      workspaceScoped: false,
      handler: _controllable(
        newsfeedController,
        scoped: false,
        seed: const {'rows': <String>[]},
      ),
    ),
    WatchQuery(
      name: 'throws',
      workspaceScoped: false,
      handler: (_) => throw StateError('handler exploded'),
    ),
    WatchQuery(
      name: 'throws_not_found',
      workspaceScoped: false,
      handler: (_) =>
          throw const NotFoundException('Terminal session not found: tty1-abc'),
    ),
    WatchQuery(
      name: 'errors',
      workspaceScoped: false,
      handler: (ctx) => _ErrorStream().stream,
    ),
    WatchQuery(
      name: 'rate_limited',
      workspaceScoped: false,
      handler: (ctx) => _ErrorStream(
        error: const NetworkException('rate limited', code: 'rate_limited'),
      ).stream,
    ),
    WatchQuery(
      name: 'not_found',
      workspaceScoped: false,
      handler: (ctx) => _ErrorStream(
        error: const NetworkException('no such PR', code: 'not_found'),
      ).stream,
    ),
    WatchQuery(
      name: 'workspace_mismatch',
      workspaceScoped: false,
      handler: (ctx) => _ErrorStream(
        error: const WorkspaceMismatchException(
          'Repository is not linked to this workspace',
        ),
      ).stream,
    ),
  ]);
  final sent = <Map<String, dynamic>>[];
  final mgr = SubscriptionManager(
    registry: queries,
    send: sent.add,
    deviceId: 'device-1',
    userId: 'user-1',
    mapException: mapException,
    workspaceExists: workspaceExists,
    resolveRole: resolveRole,
    maxPerSession: maxPerSession ?? 128,
  );
  return _Harness(mgr, queries, sent, scopedController, newsfeedController);
}

class _Harness {
  _Harness(
    this.mgr,
    this.queries,
    this.sent,
    this.scopedController,
    this.newsfeedController,
  );

  final SubscriptionManager mgr;
  final WatchQueryRegistry queries;
  final List<Map<String, dynamic>> sent;
  final StreamController<Map<String, dynamic>> scopedController;
  final StreamController<Map<String, dynamic>> newsfeedController;

  Map<String, dynamic> subscribe({
    required dynamic id,
    required Map<String, dynamic> params,
  }) => mgr.subscribe(id: id, params: params);

  Map<String, dynamic> unsubscribe({
    required dynamic id,
    required Map<String, dynamic> params,
  }) => mgr.unsubscribe(id: id, params: params);

  void invalidateAll(String kind) => mgr.invalidateAll(kind);

  Future<void> dispose() => mgr.dispose();
}

/// Builds a [WatchQueryHandler] backed by [controller], so a test can both
/// seed an initial snapshot and pump later emissions. When [scoped] is true it
/// tags snapshots with the bound workspace to prove scoping.
WatchQueryHandler _controllable(
  StreamController<Map<String, dynamic>> controller, {
  required bool scoped,
  Map<String, dynamic>? seed,
}) {
  return (ctx) {
    if (seed != null) {
      scheduleMicrotask(() => controller.add(Map<String, dynamic>.from(seed)));
    } else if (scoped) {
      scheduleMicrotask(
        () => controller.add({
          'rows': <String>[ctx.workspaceId ?? '?'],
        }),
      );
    }
    return controller.stream;
  };
}

/// A handler whose stream errors on first delivery. Defaults to a generic
/// [StateError]; pass `error` to simulate a classified upstream failure (e.g. a
/// `NetworkException` rate limit).
class _ErrorStream {
  _ErrorStream({Object? error})
    : _error = error ?? StateError('stream blew up');
  final Object _error;
  final _controller = StreamController<Map<String, dynamic>>();

  Stream<Map<String, dynamic>> get stream {
    scheduleMicrotask(() => _controller.addError(_error));
    return _controller.stream;
  }
}

int _code(Map<String, dynamic> res) => (res['error'] as Map)['code'] as int;
String _msg(Map<String, dynamic> res) =>
    (res['error'] as Map<String, dynamic>)['message'] as String;
