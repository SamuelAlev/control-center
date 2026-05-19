import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A hand-driven [RemoteRpcChannelPort] for the client: records every frame the
/// client sends and lets the test deliver inbound frames on demand. The key
/// capability the in-process / fake-host harnesses lack is *withholding* the
/// `sub/subscribe` response, so the cancel-mid-round-trip race can be staged.
class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<RemoteChannelState>.broadcast();

  /// Every frame the client handed to the transport, in order.
  final List<Map<String, dynamic>> sent = [];

  bool _open = true;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    sent.add(frame);
    // Auto-acknowledge unsubscribes so an awaited `sub.cancel()` (which awaits
    // the `sub/unsubscribe` round-trip) completes, like a real server would.
    if (frame['method'] == RpcMethods.unsubscribe) {
      final id = frame['id'];
      scheduleMicrotask(
        () => deliver({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'ok': true},
        }),
      );
    }
  }

  @override
  Future<void> close() async {
    _open = false;
    await _incoming.close();
    await _state.close();
  }

  /// Pushes an inbound frame to the client.
  void deliver(Map<String, dynamic> frame) => _incoming.add(frame);

  /// The `id` of the last request the client sent for [method].
  Object? lastRequestId(String method) =>
      sent.lastWhere((f) => f['method'] == method)['id'];

  /// All `sub/unsubscribe` frames sent so far.
  List<Map<String, dynamic>> get unsubscribes =>
      sent.where((f) => f['method'] == RpcMethods.unsubscribe).toList();
}

/// Drains pending microtasks and zero-duration timers so async controller
/// callbacks (`onListen`/`onCancel`) and the request continuations settle.
Future<void> _flush() async {
  for (var i = 0; i < 10; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('RemoteRpcClient.subscribe lifecycle', () {
    test(
      'unsubscribes a subscription cancelled while the subscribe round-trip is '
      'still in flight (no server-side leak)',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)
          ..activeWorkspaceId = 'ws1'
          ..start();

        // Listen, then let onListen fire the `sub/subscribe` request — but
        // withhold the response so the subscription id is not yet known.
        final sub = client
            .subscribe('tickets.watchForWorkspace', const {})
            .listen((_) {});
        await _flush();
        final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
        expect(subscribeId, isNotNull, reason: 'subscribe request was sent');

        // Cancel mid-round-trip: onCancel runs before the id exists.
        await sub.cancel();
        expect(
          channel.unsubscribes,
          isEmpty,
          reason: 'nothing to unsubscribe yet — the id is unknown',
        );

        // The server now answers; the onListen continuation learns the id.
        channel.deliver({
          'jsonrpc': '2.0',
          'id': subscribeId,
          'result': {'subscriptionId': 's1', 'rev': 0},
        });
        await _flush();

        // REGRESSION: the granted subscription must be torn down, not leaked.
        expect(channel.unsubscribes, hasLength(1));
        expect(
          (channel.unsubscribes.single['params'] as Map)['subscriptionId'],
          's1',
        );

        await client.close();
      },
    );

    test('normal subscribe → snapshot → cancel unsubscribes exactly once',
        () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)
        ..activeWorkspaceId = 'ws1'
        ..start();

      final snapshots = <Map<String, dynamic>>[];
      final sub = client
          .subscribe('tickets.watchForWorkspace', const {})
          .listen(snapshots.add);
      await _flush();

      final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
      channel.deliver({
        'jsonrpc': '2.0',
        'id': subscribeId,
        'result': {'subscriptionId': 's7', 'rev': 0},
      });
      await _flush();

      channel.deliver({
        'jsonrpc': '2.0',
        'method': RpcMethods.subSnapshot,
        'params': {
          'subscriptionId': 's7',
          'rev': 1,
          'full': true,
          'data': {'tickets': 3},
        },
      });
      await _flush();
      expect(snapshots, hasLength(1));
      expect(snapshots.single['tickets'], 3);

      await sub.cancel();
      await _flush();
      expect(channel.unsubscribes, hasLength(1));
      expect(
        (channel.unsubscribes.single['params'] as Map)['subscriptionId'],
        's7',
      );

      await client.close();
    });

    test('an error response to a cancelled subscribe sends no unsubscribe',
        () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)
        ..activeWorkspaceId = 'ws1'
        ..start();

      final sub = client
          .subscribe('tickets.watchForWorkspace', const {})
          .listen((_) {}, onError: (_) {});
      await _flush();
      final subscribeId = channel.lastRequestId(RpcMethods.subscribe);

      await sub.cancel();

      // The server rejected the subscribe (e.g. cap reached) — it created NO
      // subscription, so the client must not send an unsubscribe for an id the
      // server never issued.
      channel.deliver({
        'jsonrpc': '2.0',
        'id': subscribeId,
        'error': {
          'code': RpcErrorCodes.tooManySubscriptions,
          'message': 'Subscription limit (128) reached',
        },
      });
      await _flush();

      expect(channel.unsubscribes, isEmpty);

      await client.close();
    });
  });
}
