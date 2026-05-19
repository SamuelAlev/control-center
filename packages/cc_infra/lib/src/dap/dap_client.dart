import 'dart:async';

import 'package:cc_infra/src/jsonrpc_process/framed_process_channel.dart';

/// An event the adapter pushed: `stopped`, `output`, `terminated`, `exited`, …
typedef DapEvent = ({String event, Map<String, dynamic> body});

/// A failed DAP request.
///
/// DAP does not use JSON-RPC's `error` object: a response carries
/// `success: false` plus an optional human `message`, and the useful detail is
/// usually in `body.error.format`. Modelled separately from
/// [JsonRpcException](../jsonrpc_process/jsonrpc_process_client.dart) for that
/// reason — collapsing them would mean inventing a code that means nothing.
class DapException implements Exception {
  /// Creates a [DapException].
  const DapException(this.command, this.message);

  /// The command that failed.
  final String command;

  /// What the adapter said.
  final String message;

  @override
  String toString() => 'DapException($command): $message';
}

/// Speaks the Debug Adapter Protocol to a spawned adapter.
///
/// **Why this is not the JSON-RPC client.** DAP shares LSP's `Content-Length`
/// framing and nothing else. Its messages are
/// `{seq, type: request|response|event, command, arguments|body}`, correlation
/// is by `request_seq` rather than `id`, failure is a `success: false` flag
/// rather than an `error` object, and events are a first-class third message
/// type with no JSON-RPC equivalent. Both sit on `FramedProcessChannel`, which
/// is where the genuinely shared part lives.
class DapClient {
  /// Wraps an already-started framed channel.
  DapClient(this._channel) {
    _sub = _channel.messages.listen(_dispatch);
    unawaited(_channel.done.then(_fail));
  }

  /// Spawns [command] and returns a client speaking to it.
  static Future<DapClient> start({
    required String command,
    required List<String> args,
    required String workingDirectory,
    Map<String, String>? environment,
    String? name,
  }) async => DapClient(
    await FramedProcessChannel.start(
      command: command,
      args: args,
      workingDirectory: workingDirectory,
      environment: environment,
      name: name ?? command,
    ),
  );

  final FramedProcessChannel _channel;
  late final StreamSubscription<Map<String, dynamic>> _sub;
  final _pending = <int, Completer<Map<String, dynamic>>>{};
  final _events = StreamController<DapEvent>.broadcast();
  final _reverseRequests = StreamController<
    ({String command, Map<String, dynamic> arguments, int seq})
  >.broadcast();
  int _nextSeq = 1;

  /// Adapter-pushed events.
  Stream<DapEvent> get events => _events.stream;

  /// Adapter-initiated requests (`runInTerminal`, `startDebugging`).
  ///
  /// Surfaced rather than swallowed because an unanswered reverse request is
  /// how a launch silently never starts: the adapter waits for a reply that is
  /// never coming and reports nothing.
  Stream<({String command, Map<String, dynamic> arguments, int seq})>
  get reverseRequests => _reverseRequests.stream;

  /// The most recent stderr lines, oldest first.
  List<String> get stderrLog => _channel.stderrLog;

  /// Whether the adapter process is gone.
  bool get isDead => _channel.isDead;

  /// Sends a request and awaits its `body`.
  ///
  /// Throws [DapException] on `success: false` and [TimeoutException] on a
  /// wedged adapter — a debug session that never answers must surface as a
  /// tool error, never as a turn that never ends.
  Future<Map<String, dynamic>> request(
    String command, [
    Map<String, dynamic>? arguments,
    Duration timeout = const Duration(seconds: 30),
  ]) {
    if (isDead) {
      return Future.error(StateError('${_channel.name} is not running'));
    }
    final seq = _nextSeq++;
    final completer = Completer<Map<String, dynamic>>();
    _pending[seq] = completer;
    _channel.send({
      'seq': seq,
      'type': 'request',
      'command': command,
      // Always present, even when empty: several adapters reject a request
      // whose `arguments` key is missing entirely.
      'arguments': arguments ?? const <String, dynamic>{},
    });
    return completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(seq);
        throw TimeoutException(
          '${_channel.name} did not answer $command',
          timeout,
        );
      },
    );
  }

  /// Replies to an adapter-initiated request.
  void respond(int requestSeq, String command, {Map<String, dynamic>? body}) {
    if (isDead) {
      return;
    }
    _channel.send({
      'seq': _nextSeq++,
      'type': 'response',
      'request_seq': requestSeq,
      'success': true,
      'command': command,
      'body': ?body,
    });
  }

  /// Waits for the next [name] event, or throws on timeout.
  Future<Map<String, dynamic>> nextEvent(
    String name, {
    Duration timeout = const Duration(seconds: 30),
  }) => events
      .firstWhere((e) => e.event == name)
      .timeout(timeout)
      .then((e) => e.body);

  /// Terminates the adapter and fails every in-flight request.
  Future<void> close() async {
    await _sub.cancel();
    await _channel.close();
    _fail(StateError('${_channel.name} was closed'));
    await _events.close();
    await _reverseRequests.close();
  }

  void _dispatch(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'event':
        final name = message['event'];
        if (name is String && !_events.isClosed) {
          _events.add((
            event: name,
            body: (message['body'] as Map?)?.cast<String, dynamic>() ?? const {},
          ));
        }
      case 'response':
        final requestSeq = message['request_seq'];
        if (requestSeq is! int) {
          return;
        }
        final completer = _pending.remove(requestSeq);
        if (completer == null || completer.isCompleted) {
          return;
        }
        if (message['success'] == true) {
          completer.complete(
            (message['body'] as Map?)?.cast<String, dynamic>() ?? const {},
          );
        } else {
          completer.completeError(
            DapException(
              message['command'] as String? ?? 'request',
              _errorText(message),
            ),
          );
        }
      case 'request':
        final command = message['command'];
        final seq = message['seq'];
        if (command is String && seq is int && !_reverseRequests.isClosed) {
          _reverseRequests.add((
            command: command,
            arguments:
                (message['arguments'] as Map?)?.cast<String, dynamic>() ??
                const {},
            seq: seq,
          ));
        }
    }
  }

  /// The most specific text an adapter offers for a failure.
  ///
  /// `body.error.format` is where the actionable detail lives (the file it
  /// could not find, the port already in use); the top-level `message` is often
  /// just the command name repeated.
  static String _errorText(Map<String, dynamic> message) {
    final body = message['body'];
    if (body is Map) {
      final error = body['error'];
      if (error is Map) {
        final format = error['format'];
        if (format is String && format.isNotEmpty) {
          final variables = error['variables'];
          if (variables is Map) {
            var text = format;
            for (final entry in variables.entries) {
              text = text.replaceAll('{${entry.key}}', '${entry.value}');
            }
            return text;
          }
          return format;
        }
      }
    }
    final top = message['message'];
    return top is String && top.isNotEmpty ? top : 'request failed';
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
