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

    test(
      'normal subscribe → snapshot → cancel unsubscribes exactly once',
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
      },
    );

    test('a snapshot delivered in the same burst as the subscribe ack is not '
        'dropped', () async {
      // The ack completes `_request`; the onListen continuation that
      // registers `_subs[id]` runs as a microtask. A loopback transport
      // (and any handler that emits on listen) can deliver the snapshot
      // in that gap. Dropping it leaves StreamProviders spinning forever.
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);

      final snapshots = <Map<String, dynamic>>[];
      client.subscribe('models.watchVoice', const {}).listen(snapshots.add);
      await _flush();

      final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
      channel.deliver({
        'jsonrpc': '2.0',
        'id': subscribeId,
        'result': {'subscriptionId': 's-early', 'rev': 0},
      });
      channel.deliver({
        'jsonrpc': '2.0',
        'method': RpcMethods.subSnapshot,
        'params': {
          'subscriptionId': 's-early',
          'rev': 1,
          'full': true,
          'data': {'status': 'notInstalled'},
        },
      });
      await _flush();

      expect(snapshots, hasLength(1));
      expect(snapshots.single['status'], 'notInstalled');
    });

    test('a snapshot arriving before the subscribe ack is replayed', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);

      final snapshots = <Map<String, dynamic>>[];
      client.subscribe('models.watchVoice', const {}).listen(snapshots.add);
      await _flush();

      final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
      channel.deliver({
        'jsonrpc': '2.0',
        'method': RpcMethods.subSnapshot,
        'params': {
          'subscriptionId': 's-before',
          'rev': 1,
          'full': true,
          'data': {'status': 'installed'},
        },
      });
      channel.deliver({
        'jsonrpc': '2.0',
        'id': subscribeId,
        'result': {'subscriptionId': 's-before', 'rev': 0},
      });
      await _flush();

      expect(snapshots, hasLength(1));
      expect(snapshots.single['status'], 'installed');
    });

    test(
      'an error response to a cancelled subscribe sends no unsubscribe',
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
      },
    );

    test(
      'a subscribe error reply surfaces on the stream and closes it',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
        addTearDown(client.close);

        final errors = <Object>[];
        final sub = client
            .subscribe('tickets.watch', const {})
            .listen((_) {}, onError: errors.add);
        await _flush();
        final subscribeId = channel.lastRequestId(RpcMethods.subscribe);

        channel.deliver({
          'jsonrpc': '2.0',
          'id': subscribeId,
          'error': {
            'code': RpcErrorCodes.tooManySubscriptions,
            'message': 'cap',
          },
        });
        await _flush();

        expect(errors, hasLength(1));
        expect(errors.single, isA<RemoteRpcException>());
        await sub.cancel();
      },
    );

    test(
      'a server sub/error push surfaces on the stream and unsubscribes',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
        addTearDown(client.close);

        final errors = <Object>[];
        final sub = client
            .subscribe('tickets.watch', const {})
            .listen((_) {}, onError: errors.add);
        await _flush();
        final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
        channel.deliver({
          'jsonrpc': '2.0',
          'id': subscribeId,
          'result': {'subscriptionId': 's-err'},
        });
        await _flush();

        // Server pushes a sub/error for the live subscription.
        channel.deliver({
          'jsonrpc': '2.0',
          'method': RpcMethods.subError,
          'params': {
            'subscriptionId': 's-err',
            'code': RpcErrorCodes.internalError,
            'data': {'kind': 'backend-down'},
          },
        });
        await _flush();

        expect(errors, hasLength(1));
        expect(errors.single.toString(), contains('backend-down'));
        // The error path auto-unsubscribes the dead subscription.
        expect(channel.unsubscribes, hasLength(1));
        await sub.cancel();
      },
    );

    test('a sub/error for an unknown subscription is a no-op', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);

      client
          .subscribe('tickets.watch', const {})
          .listen((_) {}, onError: (_) {});
      await _flush();

      // Unknown id — must not throw.
      channel.deliver({
        'jsonrpc': '2.0',
        'method': RpcMethods.subError,
        'params': {
          'subscriptionId': 'never-existed',
          'code': RpcErrorCodes.internalError,
        },
      });
      await _flush();
      // No unsubscribe for an id the client never registered.
      expect(channel.unsubscribes, isEmpty);
    });

    test('a sub/subscribe failure surfaces on the stream as an error', () async {
      // A subscribe whose round-trip fails (here: a timeout with the response
      // withheld) surfaces the error on the stream instead of hanging forever.
      final channel = _FakeChannel();
      final client = RemoteRpcClient(
        channel,
        timeout: const Duration(milliseconds: 50),
      )..start();
      addTearDown(client.close);

      final errors = <Object>[];
      client
          .subscribe('tickets.watch', const {})
          .listen((_) {}, onError: errors.add);
      // Wait past the 50ms request timeout so the onListen continuation's
      // _request future throws TimeoutException and is surfaced.
      await Future<void>.delayed(const Duration(milliseconds: 120));
      await _flush();

      expect(errors, hasLength(1));
      expect(errors.single, isA<TimeoutException>());
    });

    test('a per-call timeout overrides the client-wide one', () async {
      // Long-running ops (e.g. newsfeed.refreshAll) pass their own timeout;
      // a withheld response must time out at THAT budget, not the client's.
      final channel = _FakeChannel();
      final client = RemoteRpcClient(
        channel,
        timeout: const Duration(seconds: 30),
      )..start();
      addTearDown(client.close);

      await expectLater(
        client.call(
          'newsfeed.refreshAll',
          const {},
          timeout: const Duration(milliseconds: 50),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });

    test('close fails in-flight requests with a cancellation error', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(
        channel,
        timeout: const Duration(seconds: 5),
      )..start();

      // Issue a call whose response we withhold, then close — the pending
      // request must complete with RemoteRpcClientClosedException.
      final call = client.call('tickets.list', const {});
      final expectation = expectLater(
        call,
        throwsA(isA<RemoteRpcClientClosedException>()),
      );
      await _flush();
      await client.close();
      await expectation;
    });

    test(
      'a request that times out throws TimeoutException and clears pending',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(
          channel,
          timeout: const Duration(milliseconds: 50),
        )..start();
        addTearDown(client.close);

        await expectLater(
          client.call('tickets.list', const {}),
          throwsA(isA<TimeoutException>()),
        );
      },
    );

    test(
      'a frame for an unknown id and non-string method is ignored',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
        addTearDown(client.close);

        // No listener for id 9999 and a non-string method — must be dropped.
        channel.deliver({'jsonrpc': '2.0', 'id': 9999});
        channel.deliver({'jsonrpc': '2.0', 'params': {}});
        await _flush();
        // Reaching here without throwing is the assertion.
      },
    );

    test('callResult and initialize are wired', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);

      final initFuture = client.initialize();
      await _flush();
      channel.deliver({
        'jsonrpc': '2.0',
        'id': channel.lastRequestId('initialize'),
        'result': {
          'capabilities': const {'subs': true},
        },
      });
      final initResult = await initFuture;
      expect(initResult['capabilities'], {'subs': true});

      final crFuture = client.callResult('tickets.list', const {'a': 1});
      await _flush();
      channel.deliver({
        'jsonrpc': '2.0',
        'id': channel.lastRequestId(RpcMethods.repoCall),
        'result': {'op': 'tickets.list', 'data': const <String, dynamic>{}},
      });
      final cr = await crFuture;
      expect(cr['op'], 'tickets.list');

      final wsFuture = client.listWorkspaces();
      await _flush();
      channel.deliver({
        'jsonrpc': '2.0',
        'id': channel.lastRequestId(RpcMethods.listWorkspaces),
        'result': {
          'workspaces': [
            {'id': 'w1', 'name': 'One'},
            'not-a-map',
            {'id': 'w2', 'name': 'Two'},
          ],
        },
      });
      final ws = await wsFuture;
      expect(ws, hasLength(2));
      expect(ws.first['id'], 'w1');
    });
  });

  group('RemoteRpcClient.subscribe deduplication', () {
    List<Map<String, dynamic>> subscribeFrames(_FakeChannel c) =>
        c.sent.where((f) => f['method'] == RpcMethods.subscribe).toList();

    test(
      'identical subscriptions share ONE server subscription; late joiner is '
      'replayed the last snapshot; one unsubscribe only after the last cancel',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)
          ..activeWorkspaceId = 'ws1'
          ..start();

        final snap1 = <Map<String, dynamic>>[];
        final snap2 = <Map<String, dynamic>>[];
        final sub1 = client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 7})
            .listen(snap1.add);
        final sub2 = client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 7})
            .listen(snap2.add);
        await _flush();

        // Dedupe: only ONE `sub/subscribe` went to the server for the two
        // identical listeners.
        expect(subscribeFrames(channel), hasLength(1));

        final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
        channel.deliver({
          'jsonrpc': '2.0',
          'id': subscribeId,
          'result': {'subscriptionId': 's-shared', 'rev': 0},
        });
        channel.deliver({
          'jsonrpc': '2.0',
          'method': RpcMethods.subSnapshot,
          'params': {
            'subscriptionId': 's-shared',
            'data': {'pull_request': 'pr7'},
          },
        });
        await _flush();

        // Both listeners saw the one snapshot.
        expect(snap1, hasLength(1));
        expect(snap2, hasLength(1));
        expect(snap1.single['pull_request'], 'pr7');

        // A late joiner is replayed the last snapshot immediately, with NO new
        // server subscription.
        final snap3 = <Map<String, dynamic>>[];
        final sub3 = client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 7})
            .listen(snap3.add);
        await _flush();
        expect(subscribeFrames(channel), hasLength(1));
        expect(snap3, hasLength(1));
        expect(snap3.single['pull_request'], 'pr7');

        // Cancelling all but the last keeps the shared subscription alive.
        await sub1.cancel();
        await sub2.cancel();
        await _flush();
        expect(channel.unsubscribes, isEmpty);

        // The last cancel tears down the single server subscription exactly once.
        await sub3.cancel();
        await _flush();
        expect(channel.unsubscribes, hasLength(1));
        expect(
          (channel.unsubscribes.single['params'] as Map)['subscriptionId'],
          's-shared',
        );

        // A fresh subscribe after teardown re-establishes (new server sub).
        // No response is delivered, so it errors on close — swallow that.
        client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 7})
            .listen((_) {}, onError: (_) {});
        await _flush();
        expect(subscribeFrames(channel), hasLength(2));

        await client.close();
      },
    );

    test('different args do NOT share a subscription', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)
        ..activeWorkspaceId = 'ws1'
        ..start();
      addTearDown(client.close);

      // No responses are delivered; both error on close — swallow that.
      client
          .subscribe('pr_review.watchPullRequest', const {'pr_number': 1})
          .listen((_) {}, onError: (_) {});
      client
          .subscribe('pr_review.watchPullRequest', const {'pr_number': 2})
          .listen((_) {}, onError: (_) {});
      await _flush();

      expect(subscribeFrames(channel), hasLength(2));
    });

    test(
      'a shared sub/error surfaces to all listeners and drops the entry',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)
          ..activeWorkspaceId = 'ws1'
          ..start();
        addTearDown(client.close);

        final err1 = <Object>[];
        final err2 = <Object>[];
        client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 9})
            .listen((_) {}, onError: err1.add);
        client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 9})
            .listen((_) {}, onError: err2.add);
        await _flush();
        final subscribeId = channel.lastRequestId(RpcMethods.subscribe);
        channel.deliver({
          'jsonrpc': '2.0',
          'id': subscribeId,
          'result': {'subscriptionId': 's-err'},
        });
        await _flush();

        channel.deliver({
          'jsonrpc': '2.0',
          'method': RpcMethods.subError,
          'params': {
            'subscriptionId': 's-err',
            'code': RpcErrorCodes.internalError,
            'data': {'kind': 'boom'},
          },
        });
        await _flush();

        // Both shared listeners saw the error.
        expect(err1, hasLength(1));
        expect(err2, hasLength(1));

        // The entry was dropped, so a fresh subscribe re-establishes.
        client
            .subscribe('pr_review.watchPullRequest', const {'pr_number': 9})
            .listen((_) {}, onError: (_) {});
        await _flush();
        expect(subscribeFrames(channel), hasLength(2));
      },
    );
  });

  // Two widgets mounting in the same frame used to issue two identical RPCs
  // and make the server execute the same handler twice. Coalescing shares the
  // in-flight request — but ONLY for reads, and only briefly; both bounds are
  // load-bearing and pinned here.
  group('RemoteRpcClient.call in-flight coalescing', () {
    List<Map<String, dynamic>> calls(_FakeChannel c) =>
        c.sent.where((f) => f['method'] == RpcMethods.repoCall).toList();

    void answer(_FakeChannel c, Object? id, Map<String, dynamic> data) {
      c.deliver({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'op': 'x', 'data': data},
      });
    }

    test('concurrent identical READS share one request', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      final a = client.call('tickets.list', const {});
      final b = client.call('tickets.list', const {});
      await _flush();

      expect(calls(channel), hasLength(1));
      answer(channel, calls(channel).single['id'], {'tickets': <String>[]});
      expect(await a, equals(await b));
    });

    test('a WRITE is never coalesced', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      // Same op, same args, issued together: two genuinely separate sends
      // must stay two sends.
      unawaited(client.call('messaging.sendMessage', const {'text': 'hi'}));
      unawaited(client.call('messaging.sendMessage', const {'text': 'hi'}));
      await _flush();

      expect(calls(channel), hasLength(2));
    });

    test('different args are not coalesced', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      unawaited(client.call('tickets.list', const {'a': 1}));
      unawaited(client.call('tickets.list', const {'a': 2}));
      await _flush();

      expect(calls(channel), hasLength(2));
    });

    test('a keyed call is never coalesced even when read-shaped', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      unawaited(client.call('tickets.list', const {}, idempotencyKey: 'k'));
      unawaited(client.call('tickets.list', const {}, idempotencyKey: 'k'));
      await _flush();

      expect(calls(channel), hasLength(2));
    });

    test('a completed request is not reused by the next caller', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      final first = client.call('tickets.list', const {});
      await _flush();
      answer(channel, calls(channel).single['id'], {'n': 1});
      await first;

      // The entry is cleared before the future completes, so this must issue
      // its own request rather than be handed the previous ANSWER.
      unawaited(client.call('tickets.list', const {}));
      await _flush();
      expect(calls(channel), hasLength(2));
    });

    test('an explicit coalesce:false opts a read out', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      unawaited(client.call('tickets.list', const {}, coalesce: false));
      unawaited(client.call('tickets.list', const {}, coalesce: false));
      await _flush();

      expect(calls(channel), hasLength(2));
    });

    test('an explicit coalesce:true opts a non-read in', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      unawaited(client.call('agents.ping', const {}, coalesce: true));
      unawaited(client.call('agents.ping', const {}, coalesce: true));
      await _flush();

      expect(calls(channel), hasLength(1));
    });
  });

  group('isReadShapedOp', () {
    test('recognizes the read verbs', () {
      for (final op in const [
        'tickets.list',
        'meeting.getById',
        'code.search',
        'connection.describe',
        'workspace.export',
        'server.status',
        'forge.capabilities',
      ]) {
        expect(isReadShapedOp(op), isTrue, reason: op);
      }
    });

    test('every listed verb is exercised above', () {
      // The list and this test drift apart silently otherwise — and a verb
      // nobody tests is a verb nobody notices is wrong.
      for (final verb in kReadOpVerbPrefixes) {
        expect(isReadShapedOp('ns.${verb}Something'), isTrue, reason: verb);
      }
    });

    test('does not claim mutations', () {
      for (final op in const [
        'messaging.sendMessage',
        'tickets.create',
        'workspace.delete',
        'connection.ping',
        'agent.upsert',
        'noNamespace',
        // Dropped from the prefix list because no catalog op uses them — a
        // prefix that matches nothing protects nothing (see
        // read_shaped_op_names_test.dart, which fails on an unused verb).
        'repo.fetchBranches',
        'link.resolve',
        'op.preview',
        'agents.count',
      ]) {
        expect(isReadShapedOp(op), isFalse, reason: op);
      }
    });
  });
}
