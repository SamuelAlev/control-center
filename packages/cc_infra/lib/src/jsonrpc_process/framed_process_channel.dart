import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// `Content-Length`-framed JSON messages over a child process's stdio.
///
/// **What it deliberately does not know.** This is FRAMING and process
/// lifetime, nothing else: it has no opinion about `id`, `seq`, `method`,
/// `command`, requests or responses. That split is the whole point — the two
/// protocols we speak over a spawned tool server share their wire format and
/// share nothing above it. The Language Server Protocol is JSON-RPC 2.0
/// (`id`/`method`/`result`); the Debug Adapter Protocol is not JSON-RPC at all
/// (`seq`/`type`/`command`/`body`, with its own `success` flag instead of an
/// `error` object). Writing the framing twice would mean two answers to "a
/// message spans two chunks", "a chunk holds three messages" and "the server
/// wrote a banner to stdout before its first frame" — and only one of them
/// would get the fix.
class FramedProcessChannel {
  FramedProcessChannel._(this._process, this.name) {
    _stdoutSub = _process.stdout.listen(
      _onBytes,
      onDone: () => _closeWith(StateError('$name closed its stdout')),
    );
    // A tool server's stderr is where it explains why it is about to be
    // useless (missing SDK, bad config). Kept bounded and surfaced rather than
    // discarded, because "the server just does not answer" is the least
    // debuggable failure there is.
    _stderrSub = _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (_stderr.length >= _maxStderrLines) {
            _stderr.removeAt(0);
          }
          _stderr.add(line);
        });
    unawaited(
      _process.exitCode.then((code) {
        _exited = true;
        _closeWith(StateError('$name exited with code $code'));
      }),
    );
    // dart:io reports a broken-pipe write on the sink's `done` future, not on
    // `add` — an error completing that future with no listener is an unhandled
    // async error that outlives whoever wrote. A dead child's stdin failing to
    // flush is already reported through [done]; swallow the pipe error here.
    unawaited(_process.stdin.done.then<void>((_) {}, onError: (Object _) {}));
  }

  /// Spawns [command] and returns a channel speaking to it.
  static Future<FramedProcessChannel> start({
    required String command,
    required List<String> args,
    required String workingDirectory,
    Map<String, String>? environment,
    String? name,
  }) async {
    final process = await Process.start(
      command,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
      // Inherit, so a server that needs PATH or a language SDK finds it.
      includeParentEnvironment: true,
    );
    return FramedProcessChannel._(process, name ?? command);
  }

  static const int _maxStderrLines = 100;

  /// A human label for errors.
  final String name;

  final Process _process;
  late final StreamSubscription<List<int>> _stdoutSub;
  late final StreamSubscription<String> _stderrSub;
  final _messages = StreamController<Map<String, dynamic>>.broadcast();
  final _stderr = <String>[];
  final _buffer = BytesBuilder(copy: false);
  Uint8List _carry = Uint8List(0);
  bool _exited = false;
  bool _closed = false;

  /// Decoded messages, in arrival order.
  Stream<Map<String, dynamic>> get messages => _messages.stream;

  /// Fires once with why the channel ended (exit, stdout close, or [close]).
  Future<Object> get done => _doneCompleter.future;
  final _doneCompleter = Completer<Object>();

  /// The most recent stderr lines, oldest first.
  List<String> get stderrLog => List.unmodifiable(_stderr);

  /// Whether the child has exited or the channel was closed.
  bool get isDead => _exited || _closed;

  /// Frames and writes [message].
  void send(Map<String, dynamic> message) {
    if (isDead) {
      return;
    }
    final body = utf8.encode(jsonEncode(message));
    try {
      _process.stdin
        ..add(utf8.encode('Content-Length: ${body.length}\r\n\r\n'))
        ..add(body);
    } on Object {
      // The process died between the liveness check and the write. Whoever
      // owns correlation fails its pending work from [done]; nothing useful to
      // add here.
    }
  }

  /// Terminates the child.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _stdoutSub.cancel();
    await _stderrSub.cancel();
    _process.kill();
    _closeWith(StateError('$name was closed'));
    await _messages.close();
  }

  void _closeWith(Object reason) {
    if (!_doneCompleter.isCompleted) {
      _doneCompleter.complete(reason);
    }
  }

  void _onBytes(List<int> chunk) {
    // Framing is length-prefixed, so a message can span chunks and a chunk can
    // hold several messages. Both happen in practice with a chatty server.
    _buffer.add(chunk);
    var data = _buffer.takeBytes();
    if (_carry.isNotEmpty) {
      data = Uint8List.fromList([..._carry, ...data]);
      _carry = Uint8List(0);
    }
    var offset = 0;
    while (true) {
      final headerEnd = findHeaderEnd(data, offset);
      if (headerEnd < 0) {
        break;
      }
      final header = utf8.decode(
        data.sublist(offset, headerEnd),
        allowMalformed: true,
      );
      final length = parseContentLength(header);
      if (length == null) {
        // Unparseable header: skip past it rather than stalling forever on a
        // server that wrote a banner to stdout.
        offset = headerEnd + 4;
        continue;
      }
      final bodyStart = headerEnd + 4;
      if (data.length - bodyStart < length) {
        break; // Body incomplete; wait for more bytes.
      }
      final body = utf8.decode(
        data.sublist(bodyStart, bodyStart + length),
        allowMalformed: true,
      );
      offset = bodyStart + length;
      final decoded = _decode(body);
      if (decoded != null && !_messages.isClosed) {
        _messages.add(decoded);
      }
    }
    if (offset < data.length) {
      _carry = Uint8List.fromList(data.sublist(offset));
    }
  }

  static Map<String, dynamic>? _decode(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null; // A malformed frame is dropped; the stream continues.
    }
  }

  /// Index of the `\r\n\r\n` that ends a header block, or -1.
  static int findHeaderEnd(Uint8List data, int from) {
    for (var i = from; i + 3 < data.length; i++) {
      if (data[i] == 13 &&
          data[i + 1] == 10 &&
          data[i + 2] == 13 &&
          data[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }

  /// The `Content-Length` value in a header block, or null.
  static int? parseContentLength(String header) {
    for (final line in header.split('\r\n')) {
      final idx = line.indexOf(':');
      if (idx < 0) {
        continue;
      }
      if (line.substring(0, idx).trim().toLowerCase() == 'content-length') {
        return int.tryParse(line.substring(idx + 1).trim());
      }
    }
    return null;
  }
}
