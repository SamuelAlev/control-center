import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';

/// Minimal no-op [RemoteRpcChannelPort] for tests that only need a
/// [RemoteRpcClient] to exist (e.g. to satisfy `rpcClientProvider` so a
/// provider under test can be constructed) without ever making a real call.
///
/// Any `repo/call` or `sub/subscribe` actually sent through this channel never
/// receives a reply — tests that exercise real round trips should build their
/// own responder instead (see `terminal_panel_test.dart` for an example).
class NoopRpcChannel implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<RemoteChannelState>.broadcast();

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => true;

  @override
  Future<void> send(Map<String, dynamic> frame) async {}

  @override
  Future<void> close() async {
    await _incoming.close();
    await _state.close();
  }
}

/// Builds a started [RemoteRpcClient] over a [NoopRpcChannel] — enough to
/// override `rpcClientProvider` in tests that construct RPC-backed providers
/// but never invoke them.
RemoteRpcClient fakeRpcClient() => RemoteRpcClient(NoopRpcChannel())..start();

/// In-memory JSON-RPC host: answers `sub/subscribe` for a fixed set of
/// `query` names with snapshots the test pushes via [emit] and acknowledges
/// `repo/call` for a fixed set of `op` names via a handler the test supplies.
///
/// Enough to drive `RemoteRpcClient.subscribe`/`call` round trips in tests
/// without a real `cc_server` — see `RemoteRpcClient.subscribe` for the wire
/// shapes this mirrors (`sub/subscribe` → `{subscriptionId}`, pushed snapshots
/// via `sub/snapshot` notifications).
class FakeRpcHost implements RemoteRpcChannelPort {
  final _incoming = StreamController<Map<String, dynamic>>.broadcast();
  final _state = StreamController<RemoteChannelState>.broadcast();

  /// Maps a subscribed `query` name to its live subscription ids.
  final Map<String, Set<String>> _subsByQuery = {};
  int _subCounter = 0;

  /// Optional per-op handler for `repo/call`. Returns the `data` map for a
  /// successful response; throw to simulate a JSON-RPC error (caught and
  /// reported as a generic internal error).
  Map<String, dynamic> Function(String op, Map<String, dynamic> args)? onCall;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => true;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    final method = frame['method'] as String?;
    final id = frame['id'];
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};

    if (method == 'sub/subscribe') {
      final query = params['query'] as String;
      final subId = 'fake-sub-${++_subCounter}';
      _subsByQuery.putIfAbsent(query, () => {}).add(subId);
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': {'subscriptionId': subId},
      });
      return;
    }
    if (method == 'sub/unsubscribe') {
      final subId = params['subscriptionId'] as String?;
      _subsByQuery.forEach((_, ids) => ids.remove(subId));
      _incoming.add({
        'jsonrpc': '2.0',
        'id': id,
        'result': <String, dynamic>{},
      });
      return;
    }
    if (method == 'repo/call') {
      final op = params['op'] as String;
      final args = (params['args'] as Map?)?.cast<String, dynamic>() ?? {};
      final handler = onCall;
      if (handler == null) {
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32601, 'message': 'op not faked: $op'},
        });
        return;
      }
      try {
        final data = handler(op, args);
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'data': data},
        });
      } catch (e) {
        _incoming.add({
          'jsonrpc': '2.0',
          'id': id,
          'error': {'code': -32000, 'message': '$e'},
        });
      }
    }
  }

  /// Pushes a snapshot to every live subscriber of [query]. [data] is the
  /// raw map the corresponding `Remote*Repository` decodes (e.g.
  /// `{'workspaces': [...]}` for `workspace.watchAll`).
  void emit(String query, Map<String, dynamic> data) {
    for (final subId in _subsByQuery[query] ?? const <String>{}) {
      _incoming.add({
        'jsonrpc': '2.0',
        'method': 'sub/snapshot',
        'params': {'subscriptionId': subId, 'data': data},
      });
    }
  }

  @override
  Future<void> close() async {
    await _incoming.close();
    await _state.close();
  }

  /// Builds a started [RemoteRpcClient] over this host — call [emit] /
  /// configure [onCall] either before or after, the subscription map is keyed
  /// by query name so ordering with respect to `subscribe()` doesn't matter.
  RemoteRpcClient client() => RemoteRpcClient(this)..start();
}
