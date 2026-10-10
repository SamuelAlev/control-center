import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:test/test.dart';

/// A hand-driven [RemoteRpcChannelPort]: records every frame the client sends
/// and lets the test answer each `repo/call` with a scripted response.
class _FakeChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final List<Map<String, dynamic>> sent = [];

  /// Answers the n-th `repo/call` (0-based, retries included — each retry is
  /// a NEW request id, so arrival order is the only stable sequencing key).
  /// Null (default) never answers.
  Map<String, dynamic> Function(int seq, Object id)? onRepoCall;

  int _repoCallsAnswered = 0;

  /// As [onRepoCall], for `sub/subscribe`.
  Map<String, dynamic> Function(int seq, Object id)? onSubscribe;

  int _subscribesAnswered = 0;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state =>
      const Stream<RemoteChannelState>.empty();

  @override
  bool get isOpen => true;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    sent.add(frame);
    final id = frame['id'];
    if (id == null) {
      return;
    }
    final Map<String, dynamic> response;
    if (frame['method'] == RpcMethods.repoCall) {
      final responder = onRepoCall;
      if (responder == null) {
        return;
      }
      response = responder(_repoCallsAnswered++, id);
    } else if (frame['method'] == RpcMethods.subscribe) {
      final responder = onSubscribe;
      if (responder == null) {
        return;
      }
      response = responder(_subscribesAnswered++, id);
    } else {
      return;
    }
    scheduleMicrotask(() => _incoming.add(response));
  }

  void deliver(Map<String, dynamic> frame) => _incoming.add(frame);

  @override
  Future<void> close() async {
    await _incoming.close();
  }

  List<Map<String, dynamic>> get repoCalls =>
      sent.where((f) => f['method'] == RpcMethods.repoCall).toList();

  List<Map<String, dynamic>> get subscribes =>
      sent.where((f) => f['method'] == RpcMethods.subscribe).toList();

  static Map<String, dynamic> subscribed(Object id, String subscriptionId) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': {'subscriptionId': subscriptionId},
  };

  static Map<String, dynamic> refusal(Object id) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': RpcErrorCodes.rateLimited, 'message': 'Too many'},
  };

  static Map<String, dynamic> ok(Object id) => {
    'jsonrpc': '2.0',
    'id': id,
    'result': {
      'op': 'thing.get',
      'data': {'ok': true},
    },
  };

  static Map<String, dynamic> notFound(Object id) => {
    'jsonrpc': '2.0',
    'id': id,
    'error': {'code': RpcErrorCodes.notFound, 'message': 'no such thing'},
  };
}

Future<void> _settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  test('a -32005 refusal is retried with backoff and succeeds', () async {
    final channel = _FakeChannel();
    channel.onRepoCall = (seq, id) =>
        seq < 2 ? _FakeChannel.refusal(id) : _FakeChannel.ok(id);
    final client = RemoteRpcClient(channel)..start();

    final data = await client.call('thing.get', const {});

    expect(data, {'ok': true});
    // Two refusals rode out, third attempt served.
    expect(channel.repoCalls, hasLength(3));
    // Every attempt is a fresh request (a new id), never a stale replay.
    expect(channel.repoCalls.map((f) => f['id']).toSet(), hasLength(3));
    await client.close();
  });

  test(
    'a refusal that never clears surfaces -32005 after the retries',
    () async {
      final channel = _FakeChannel();
      channel.onRepoCall = (seq, id) => _FakeChannel.refusal(id);
      final client = RemoteRpcClient(channel)..start();

      await expectLater(
        client.call('thing.get', const {}),
        throwsA(
          isA<RemoteRpcException>().having(
            (e) => e.code,
            'code',
            RpcErrorCodes.rateLimited,
          ),
        ),
      );
      expect(channel.repoCalls, hasLength(3));
      await client.close();
    },
  );

  test('only -32005 is retried — every other error surfaces at once', () async {
    final channel = _FakeChannel();
    channel.onRepoCall = (seq, id) => _FakeChannel.notFound(id);
    final client = RemoteRpcClient(channel)..start();

    await expectLater(
      client.call('thing.get', const {}),
      throwsA(
        isA<RemoteRpcException>().having(
          (e) => e.code,
          'code',
          RpcErrorCodes.notFound,
        ),
      ),
    );
    expect(channel.repoCalls, hasLength(1));
    await client.close();
  });

  group('subscribe', () {
    const query = 'pr.watchForSpaceBranches';
    const args = {'space_id': 's1'};

    test(
      'a -32005 refusal is retried until the subscription is live',
      () async {
        final channel = _FakeChannel()
          ..onSubscribe = (seq, id) => seq < 3
              ? _FakeChannel.refusal(id)
              : _FakeChannel.subscribed(id, 'sub-1');
        final client = RemoteRpcClient(channel)..start();
        addTearDown(client.close);
        final values = <Map<String, dynamic>>[];
        final errors = <Object>[];
        final sub = client
            .subscribe(query, args)
            .listen(values.add, onError: errors.add);

        // Three refusals back off 125-250ms, 250-500ms and 500ms-1s.
        await Future<void>.delayed(const Duration(milliseconds: 1900));
        expect(channel.subscribes, hasLength(4));
        expect(channel.subscribes.map((f) => f['id']).toSet(), hasLength(4));

        channel.deliver({
          'jsonrpc': '2.0',
          'method': RpcMethods.subSnapshot,
          'params': {
            'subscriptionId': 'sub-1',
            'data': {'matches': <Object>[]},
          },
        });
        await _settle();
        expect(errors, isEmpty);
        expect(values, [
          {'matches': <Object>[]},
        ]);
        await sub.cancel();
      },
    );

    test('cancelled rate-limit backoff never resubscribes', () async {
      final channel = _FakeChannel()
        ..onSubscribe = (seq, id) => _FakeChannel.refusal(id);
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);
      final sub = client.subscribe(query, args).listen((_) {});
      await _settle();
      expect(channel.subscribes, hasLength(1));
      await sub.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(channel.subscribes, hasLength(1));
      expect(
        channel.sent.where((f) => f['method'] == RpcMethods.unsubscribe),
        isEmpty,
      );
    });

    test(
      'only -32005 is retried — every other error surfaces at once',
      () async {
        final channel = _FakeChannel()
          ..onSubscribe = (seq, id) => _FakeChannel.notFound(id);
        final client = RemoteRpcClient(channel)..start();
        addTearDown(client.close);

        await expectLater(
          client.subscribe(query, args),
          emitsError(
            isA<RemoteRpcException>().having(
              (e) => e.code,
              'code',
              RpcErrorCodes.notFound,
            ),
          ),
        );
        expect(channel.subscribes, hasLength(1));
      },
    );
  });

  group('watchCall request ownership', () {
    const op = 'messaging.getMessageById';
    const args = {'message_id': 'm1'};

    test('abandoning a pending response cancels its request and ignores the '
        'obsolete reply; revisiting starts a new read', () async {
      final channel = _FakeChannel();
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);
      final abandoned = <Map<String, dynamic>>[];
      final old = client.watchCall(op, args).listen(abandoned.add);
      await _settle();
      final first = channel.repoCalls.single['id'];

      await old.cancel();
      await _settle();
      expect(channel.sent.last, {
        'jsonrpc': '2.0',
        'method': RpcMethods.cancelRequest,
        'params': {'id': first},
      });
      channel.deliver({
        'jsonrpc': '2.0',
        'id': first,
        'result': {
          'op': op,
          'data': {'value': 'obsolete'},
        },
      });
      await _settle();

      final fresh = <Map<String, dynamic>>[];
      final next = client.watchCall(op, args).listen(fresh.add);
      await _settle();
      expect(channel.repoCalls, hasLength(2));
      channel.deliver({
        'jsonrpc': '2.0',
        'id': channel.repoCalls.last['id'],
        'result': {
          'op': op,
          'data': {'value': 'fresh'},
        },
      });
      await _settle();
      expect(abandoned, isEmpty);
      expect(fresh, [
        {'value': 'fresh'},
      ]);
      await next.cancel();
    });

    test('cancelled rate-limit backoff never retries', () async {
      final channel = _FakeChannel()
        ..onRepoCall = (seq, id) => _FakeChannel.refusal(id);
      final client = RemoteRpcClient(channel)..start();
      addTearDown(client.close);
      final sub = client.watchCall(op, args).listen((_) {});
      await _settle();
      expect(channel.repoCalls, hasLength(1));
      await sub.cancel();
      await Future<void>.delayed(const Duration(milliseconds: 350));
      expect(channel.repoCalls, hasLength(1));
      expect(
        channel.sent.where((f) => f['method'] == RpcMethods.cancelRequest),
        isEmpty,
      );
    });

    test(
      'one departing watcher does not cancel the remaining live read',
      () async {
        final channel = _FakeChannel();
        final client = RemoteRpcClient(channel)..start();
        addTearDown(client.close);
        final values = <Map<String, dynamic>>[];
        final leaving = client.watchCall(op, args).listen((_) {});
        final staying = client.watchCall(op, args).listen(values.add);
        await _settle();
        expect(channel.repoCalls, hasLength(1));
        await leaving.cancel();
        expect(
          channel.sent.where((f) => f['method'] == RpcMethods.cancelRequest),
          isEmpty,
        );
        channel.deliver({
          'jsonrpc': '2.0',
          'id': channel.repoCalls.single['id'],
          'result': {
            'op': op,
            'data': {'value': 'current'},
          },
        });
        await _settle();
        expect(values, [
          {'value': 'current'},
        ]);
        await staying.cancel();
      },
    );
  });
}
