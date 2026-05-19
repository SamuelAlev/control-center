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
    if (id == null || frame['method'] != RpcMethods.repoCall) {
      return;
    }
    final responder = onRepoCall;
    if (responder == null) {
      return;
    }
    final response = responder(_repoCallsAnswered++, id);
    scheduleMicrotask(() => _incoming.add(response));
  }

  @override
  Future<void> close() async {
    await _incoming.close();
  }

  List<Map<String, dynamic>> get repoCalls =>
      sent.where((f) => f['method'] == RpcMethods.repoCall).toList();

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
}
