import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A request/response lane over one `claude` process's stdin/stdout, speaking
/// the stream-json control protocol the Agent SDK speaks.
class ClaudeControlSession {
  /// Opens a lane over [_process]. Takes over its stdout and stderr.
  ClaudeControlSession(this._process, this._requestTimeout) {
    _sub = _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(_onLine, onDone: _onDone, onError: (_) => _onDone());
    // Drained so a chatty stderr can never fill its pipe and stall the CLI.
    _process.stderr.listen((_) {});
  }

  final Process _process;
  final Duration _requestTimeout;
  late final StreamSubscription<String> _sub;
  final _pending = <String, Completer<Map<String, dynamic>>>{};
  var _next = 0;
  var _closed = false;

  void _onLine(String line) {
    final Object? decoded;
    try {
      decoded = jsonDecode(line);
    } on FormatException {
      return;
    }
    if (decoded is! Map || decoded['type'] != 'control_response') {
      return;
    }
    final response = decoded['response'];
    if (response is! Map) {
      return;
    }
    final completer = _pending.remove(response['request_id']);
    if (completer == null || completer.isCompleted) {
      return;
    }
    if (response['subtype'] == 'success') {
      final body = response['response'];
      completer.complete(
        body is Map ? Map<String, dynamic>.from(body) : const {},
      );
    } else {
      completer.completeError(
        StateError('${response['error'] ?? 'control request failed'}'),
      );
    }
  }

  void _onDone() {
    _closed = true;
    for (final c in _pending.values) {
      if (!c.isCompleted) {
        c.completeError(StateError('claude exited mid-probe'));
      }
    }
    _pending.clear();
    unawaited(_sub.cancel());
  }

  /// Sends one control request and waits for its answer. Throws when the CLI
  /// refuses it, exits, or does not answer in time.
  Future<Map<String, dynamic>> request(Map<String, Object?> body) {
    if (_closed) {
      return Future.error(StateError('claude exited mid-probe'));
    }
    final id = 'cc-control-${_next++}';
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;
    _process.stdin.writeln(
      jsonEncode({
        'type': 'control_request',
        'request_id': id,
        'request': body,
      }),
    );
    return completer.future.timeout(
      _requestTimeout,
      onTimeout: () {
        _pending.remove(id);
        throw TimeoutException('claude control request timed out');
      },
    );
  }
}
