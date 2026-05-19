import 'dart:async';

import 'package:cc_infra/src/jsonrpc_process/framed_process_channel.dart';

/// A server-initiated request or notification.
typedef JsonRpcInbound = ({String method, Map<String, dynamic> params, int? id});

/// Signals a JSON-RPC error response.
class JsonRpcException implements Exception {
  /// Creates a [JsonRpcException].
  const JsonRpcException(this.code, this.message, [this.data]);

  /// The JSON-RPC error code.
  final int code;

  /// The error message.
  final String message;

  /// Optional structured payload.
  final Object? data;

  @override
  String toString() => 'JsonRpcException($code): $message';
}

/// JSON-RPC 2.0 over a child process's stdio, on a [FramedProcessChannel].
///
/// This is what the Language Server Protocol speaks. Correlation by `id`,
/// errors as an `error` object, server-initiated traffic as `method` with or
/// without an `id`.
///
/// The Debug Adapter Protocol shares the FRAMING and nothing above it — see
/// `DapClient`, which sits on the same channel with `seq` correlation.
class JsonRpcProcessClient {
  /// Wraps an already-started framed channel.
  JsonRpcProcessClient(this._channel) {
    _sub = _channel.messages.listen(_dispatch);
    unawaited(_channel.done.then(_fail));
  }

  /// Spawns [command] with [args] in [workingDirectory] and returns a client
  /// speaking to it.
  static Future<JsonRpcProcessClient> start({
    required String command,
    required List<String> args,
    required String workingDirectory,
    Map<String, String>? environment,
    String? name,
  }) async => JsonRpcProcessClient(
    await FramedProcessChannel.start(
      command: command,
      args: args,
      workingDirectory: workingDirectory,
      environment: environment,
      name: name,
    ),
  );

  final FramedProcessChannel _channel;
  late final StreamSubscription<Map<String, dynamic>> _sub;
  final _pending = <int, Completer<Object?>>{};
  final _inbound = StreamController<JsonRpcInbound>.broadcast();
  int _nextId = 1;

  /// Server-initiated requests and notifications.
  Stream<JsonRpcInbound> get inbound => _inbound.stream;

  /// The most recent stderr lines, oldest first.
  List<String> get stderrLog => _channel.stderrLog;

  /// Whether the child process has exited.
  bool get isDead => _channel.isDead;

  /// Sends a request and awaits its result.
  ///
  /// [timeout] bounds the wait: a wedged server must surface as a tool error,
  /// never as a turn that never ends.
  Future<Object?> request(
    String method,
    Map<String, dynamic>? params, {
    Duration timeout = const Duration(seconds: 30),
  }) {
    if (isDead) {
      return Future.error(StateError('${_channel.name} is not running'));
    }
    final id = _nextId++;
    final completer = Completer<Object?>();
    _pending[id] = completer;
    _channel.send({
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': ?params,
    });
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException(
          '${_channel.name} did not answer $method',
          timeout,
        );
      },
    );
  }

  /// Sends a notification (no reply expected).
  void notify(String method, [Map<String, dynamic>? params]) {
    if (isDead) {
      return;
    }
    _channel.send({'jsonrpc': '2.0', 'method': method, 'params': ?params});
  }

  /// Replies to a server-initiated request.
  void respond(int id, Object? result) {
    if (isDead) {
      return;
    }
    _channel.send({'jsonrpc': '2.0', 'id': id, 'result': result});
  }

  /// Terminates the child and fails every in-flight request.
  Future<void> close() async {
    await _sub.cancel();
    await _channel.close();
    _fail(StateError('${_channel.name} was closed'));
    await _inbound.close();
  }

  void _dispatch(Map<String, dynamic> decoded) {
    final id = decoded['id'];
    final method = decoded['method'];
    if (method is String) {
      // Server-initiated: a request (has id) or a notification (does not).
      _inbound.add((
        method: method,
        params: (decoded['params'] as Map?)?.cast<String, dynamic>() ?? const {},
        id: id is int ? id : null,
      ));
      return;
    }
    if (id is! int) {
      return;
    }
    final completer = _pending.remove(id);
    if (completer == null || completer.isCompleted) {
      return;
    }
    final error = decoded['error'];
    if (error is Map) {
      completer.completeError(
        JsonRpcException(
          (error['code'] as num?)?.toInt() ?? -1,
          error['message'] as String? ?? 'unknown error',
          error['data'],
        ),
      );
    } else {
      completer.complete(decoded['result']);
    }
  }

  void _fail(Object error) {
    final pending = List.of(_pending.entries);
    _pending.clear();
    for (final entry in pending) {
      if (!entry.value.isCompleted) {
        entry.value.completeError(error);
      }
    }
  }
}
