import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_host/cc_host.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SubscriptionManager', () {
    late List<Map<String, dynamic>> pushed;
    late StreamController<Map<String, dynamic>> ticketStream;
    late SubscriptionManager manager;

    setUp(() {
      pushed = [];
      ticketStream = StreamController<Map<String, dynamic>>.broadcast();
      manager = SubscriptionManager(
        registry: WatchQueryRegistry([
          WatchQuery(
            name: 'tickets.watchForWorkspace',
            handler: (ctx) => ticketStream.stream.map(
              (d) => {'workspace': ctx.workspaceId, ...d},
            ),
          ),
          WatchQuery(
            name: 'feeds.watch',
            workspaceScoped: false,
            handler: (ctx) => Stream.value({'feeds': []}),
          ),
        ]),
        send: pushed.add,
        deviceId: 'dev-1',
        maxPerSession: 2,
      );
    });

    tearDown(() {
      ticketStream.close();
      manager.dispose();
    });

    test('subscribe returns a subscription id and proxies snapshots', () async {
      // The server is stateless: the scoped query carries its workspace in args.
      final r = manager.subscribe(
        id: 1,
        params: const {
          'query': 'tickets.watchForWorkspace',
          'args': {'workspace_id': 'ws1'},
        },
      );
      expect((r['result'] as Map)['subscriptionId'], isA<String>());

      ticketStream.add({
        'tickets': [1, 2],
      });
      await Future<void>.delayed(Duration.zero);

      final snap = pushed.single;
      expect(snap['method'], RpcMethods.subSnapshot);
      final params = snap['params'] as Map;
      expect(params['rev'], 1);
      // The handler scoped to exactly the workspace the client named in args.
      expect((params['data'] as Map)['workspace'], 'ws1');
    });

    test('rejects a workspace-scoped subscribe when args lack workspace_id', () {
      final r = manager.subscribe(
        id: 1,
        params: const {'query': 'tickets.watchForWorkspace', 'args': {}},
      );
      expect((r['error'] as Map)['code'], RpcErrorCodes.validation);
      expect(
        (r['error'] as Map)['message'],
        'Missing required argument: workspace_id',
      );
    });

    test('global query subscribes without a workspace', () {
      final r = manager.subscribe(
        id: 1,
        params: const {'query': 'feeds.watch'},
      );
      expect((r['result'] as Map)['subscriptionId'], isA<String>());
    });

    test('unknown query is default-denied', () {
      final r = manager.subscribe(
        id: 1,
        params: const {'query': 'nope'},
      );
      expect((r['error'] as Map)['code'], RpcErrorCodes.opUnknown);
    });

    test('enforces the per-session subscription cap', () {
      manager.subscribe(
        id: 1,
        params: const {'query': 'feeds.watch'},
      );
      manager.subscribe(
        id: 2,
        params: const {'query': 'feeds.watch'},
      );
      final third = manager.subscribe(
        id: 3,
        params: const {'query': 'feeds.watch'},
      );
      expect(
        (third['error'] as Map)['code'],
        RpcErrorCodes.tooManySubscriptions,
      );
    });

    test(
      'invalidateAll pushes sub/error and stops further snapshots',
      () async {
        manager.subscribe(
          id: 1,
          params: const {
            'query': 'tickets.watchForWorkspace',
            'args': {'workspace_id': 'ws1'},
          },
        );
        manager.invalidateAll('workspace_changed');
        expect(pushed.single['method'], RpcMethods.subError);
        expect((pushed.single['params'] as Map)['data'], {
          'kind': 'workspace_changed',
        });

        pushed.clear();
        ticketStream.add({'tickets': []});
        await Future<void>.delayed(Duration.zero);
        expect(pushed, isEmpty); // subscription was torn down
      },
    );
  });
}
