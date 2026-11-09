import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_connect/src/state_store.dart';

/// The state backend is unreachable or misbehaving. Answered
/// `provider_unavailable`: a transient failure, never a verdict.
final class StateStoreUnavailable implements Exception {
  /// Creates the exception.
  const StateStoreUnavailable(this.reason);

  /// A fixed, secret-free reason.
  final String reason;

  @override
  String toString() => 'StateStoreUnavailable($reason)';
}

/// A Redis error reply (`-ERR …`).
final class RespError {
  /// Creates the error.
  const RespError(this.message);

  /// Redis's message.
  final String message;

  @override
  String toString() => 'RespError($message)';
}

/// One RESP2 connection: pipelined commands, replies matched in order.
final class _RespConnection {
  _RespConnection(this._socket) {
    _subscription = _socket.listen(
      _onData,
      onError: (Object _) => _fail(),
      onDone: _fail,
      cancelOnError: true,
    );
  }

  final Socket _socket;
  late final StreamSubscription<List<int>> _subscription;
  final Queue<Completer<Object?>> _pending = Queue();
  final List<int> _buffer = [];
  bool _closed = false;

  bool get isOpen => !_closed;

  static List<int> _encode(List<String> args) {
    final out = BytesBuilder(copy: false)
      ..add(ascii.encode('*${args.length}\r\n'));
    for (final arg in args) {
      final bytes = utf8.encode(arg);
      out
        ..add(ascii.encode('\$${bytes.length}\r\n'))
        ..add(bytes)
        ..add(const [13, 10]);
    }
    return out.takeBytes();
  }

  /// Sends [commands] in one write and returns their replies in order.
  Future<List<Object?>> send(List<List<String>> commands) {
    if (_closed) {
      return Future.error(const StateStoreUnavailable('redis closed'));
    }
    final futures = <Future<Object?>>[];
    final bytes = BytesBuilder(copy: false);
    for (final command in commands) {
      final completer = Completer<Object?>();
      _pending.add(completer);
      futures.add(completer.future);
      bytes.add(_encode(command));
    }
    _socket.add(bytes.takeBytes());
    return Future.wait(futures);
  }

  void _onData(List<int> data) {
    _buffer.addAll(data);
    var offset = 0;
    while (true) {
      final parsed = _parse(offset);
      if (parsed == null) {
        break;
      }
      offset = parsed.next;
      if (_pending.isEmpty) {
        _fail();
        return;
      }
      _pending.removeFirst().complete(parsed.value);
    }
    if (offset > 0) {
      if (offset == _buffer.length) {
        _buffer.clear();
      } else {
        _buffer.removeRange(0, offset);
      }
    }
    if (_buffer.length > 4 * 1024 * 1024) {
      _fail();
    }
  }

  int _lineEnd(int from) {
    for (var i = from; i + 1 < _buffer.length; i++) {
      if (_buffer[i] == 13 && _buffer[i + 1] == 10) {
        return i;
      }
    }
    return -1;
  }

  ({Object? value, int next})? _parse(int at) {
    if (at >= _buffer.length) {
      return null;
    }
    final end = _lineEnd(at + 1);
    if (end < 0) {
      return null;
    }
    final type = _buffer[at];
    final line = utf8.decode(
      _buffer.sublist(at + 1, end),
      allowMalformed: true,
    );
    final afterLine = end + 2;
    switch (type) {
      case 0x2b: // +
        return (value: line, next: afterLine);
      case 0x2d: // -
        return (value: RespError(line), next: afterLine);
      case 0x3a: // :
        final parsed = int.tryParse(line);
        if (parsed == null) {
          _fail();
          return null;
        }
        return (value: parsed, next: afterLine);
      case 0x24: // $
        final length = int.tryParse(line);
        if (length == null || length < -1) {
          _fail();
          return null;
        }
        if (length < 0) {
          return (value: null, next: afterLine);
        }
        if (afterLine + length + 2 > _buffer.length) {
          return null;
        }
        final text = utf8.decode(
          _buffer.sublist(afterLine, afterLine + length),
          allowMalformed: true,
        );
        return (value: text, next: afterLine + length + 2);
      case 0x2a: // *
        final count = int.tryParse(line);
        if (count == null || count < -1) {
          _fail();
          return null;
        }
        if (count < 0) {
          return (value: null, next: afterLine);
        }
        final items = <Object?>[];
        var cursor = afterLine;
        for (var i = 0; i < count; i++) {
          final item = _parse(cursor);
          if (item == null) {
            return null;
          }
          items.add(item.value);
          cursor = item.next;
        }
        return (value: items, next: cursor);
      default:
        _fail();
        return null;
    }
  }

  void _fail() {
    if (_closed) {
      return;
    }
    _closed = true;
    while (_pending.isNotEmpty) {
      _pending.removeFirst().completeError(
        const StateStoreUnavailable('redis connection lost'),
      );
    }
    unawaited(_subscription.cancel());
    _socket.destroy();
  }

  void close() => _fail();
}

/// [StateStore] on Redis / Memorystore over a minimal RESP2 client. Every key
/// is namespaced under `cc_connect:`. One pipelined connection, reopened on
/// failure; multi-step operations run as `MULTI`/`EXEC` written in a single
/// socket write so no other command can interleave.
final class RedisStateStore implements StateStore {
  /// Creates the store for [url] (`redis://[user:password@]host[:port][/db]`
  /// or `rediss://…`). [tlsContext] overrides the trusted roots for
  /// `rediss://` (Memorystore's server CA).
  RedisStateStore(
    this.url, {
    SecurityContext? tlsContext,
    this.commandTimeout = const Duration(seconds: 5),
  }) : _tls = tlsContext;

  /// The server.
  final Uri url;

  /// Bound on each round trip.
  final Duration commandTimeout;

  final SecurityContext? _tls;
  _RespConnection? _connection;
  Future<_RespConnection>? _connecting;
  bool _noGetDel = false;

  static const String _prefix = 'cc_connect:';

  Future<_RespConnection> _open() async {
    final port = url.hasPort ? url.port : 6379;
    // Owned by the connection, which destroys it on close.
    // ignore: close_sinks
    final Socket socket;
    try {
      socket = url.scheme == 'rediss'
          ? await SecureSocket.connect(
              url.host,
              port,
              context: _tls,
              timeout: commandTimeout,
            )
          : await Socket.connect(url.host, port, timeout: commandTimeout);
    } on Object {
      throw const StateStoreUnavailable('redis connect');
    }
    socket.setOption(SocketOption.tcpNoDelay, true);
    final connection = _RespConnection(socket);
    final setup = <List<String>>[];
    if (url.userInfo.isNotEmpty) {
      final colon = url.userInfo.indexOf(':');
      final user = colon < 0
          ? ''
          : Uri.decodeComponent(url.userInfo.substring(0, colon));
      final password = Uri.decodeComponent(
        colon < 0 ? url.userInfo : url.userInfo.substring(colon + 1),
      );
      setup.add(['AUTH', if (user.isNotEmpty) user, password]);
    }
    final db = url.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
    if (db != null && int.tryParse(db) != null) {
      setup.add(['SELECT', db]);
    }
    if (setup.isNotEmpty) {
      final replies = await connection
          .send(setup)
          .timeout(
            commandTimeout,
            onTimeout: () {
              connection.close();
              throw const StateStoreUnavailable('redis auth timeout');
            },
          );
      if (replies.any((r) => r is RespError)) {
        connection.close();
        throw const StateStoreUnavailable('redis auth');
      }
    }
    return connection;
  }

  Future<_RespConnection> _conn() async {
    final existing = _connection;
    if (existing != null && existing.isOpen) {
      return existing;
    }
    final connection = await (_connecting ??= _open().whenComplete(
      () => _connecting = null,
    ));
    _connection = connection;
    return connection;
  }

  Future<List<Object?>> _run(List<List<String>> commands) async {
    final connection = await _conn();
    try {
      return await connection.send(commands).timeout(commandTimeout);
    } on TimeoutException {
      connection.close();
      throw const StateStoreUnavailable('redis timeout');
    }
  }

  Future<Object?> _one(List<String> command) async {
    final reply = (await _run([command])).single;
    if (reply is RespError) {
      throw StateStoreUnavailable('redis ${command.first}');
    }
    return reply;
  }

  String _k(String key) => '$_prefix$key';

  String _ms(Duration ttl) =>
      '${ttl.inMilliseconds < 1 ? 1 : ttl.inMilliseconds}';

  /// Runs [commands] inside MULTI/EXEC and returns EXEC's reply array.
  Future<List<Object?>> _transaction(List<List<String>> commands) async {
    final replies = await _run([
      ['MULTI'],
      ...commands,
      ['EXEC'],
    ]);
    final exec = replies.last;
    if (exec is! List<Object?> || replies.any((r) => r is RespError)) {
      throw const StateStoreUnavailable('redis transaction');
    }
    return exec;
  }

  @override
  Future<String?> get(String key) async {
    final reply = await _one(['GET', _k(key)]);
    return reply is String ? reply : null;
  }

  @override
  Future<void> set(String key, String value, Duration ttl) async {
    await _one(['SET', _k(key), value, 'PX', _ms(ttl)]);
  }

  @override
  Future<bool> putIfAbsent(String key, String value, Duration ttl) async {
    final reply = await _one(['SET', _k(key), value, 'NX', 'PX', _ms(ttl)]);
    return reply == 'OK';
  }

  @override
  Future<String?> take(String key) async {
    if (!_noGetDel) {
      final reply = (await _run([
        ['GETDEL', _k(key)],
      ])).single;
      if (reply is RespError) {
        if (!reply.message.toLowerCase().contains('unknown command')) {
          throw const StateStoreUnavailable('redis GETDEL');
        }
        _noGetDel = true; // Redis < 6.2: fall through to MULTI GET DEL.
      } else {
        return reply is String ? reply : null;
      }
    }
    final exec = await _transaction([
      ['GET', _k(key)],
      ['DEL', _k(key)],
    ]);
    final value = exec.first;
    return value is String ? value : null;
  }

  @override
  Future<void> delete(String key) async {
    await _one(['DEL', _k(key)]);
  }

  @override
  Future<int> increment(String key, Duration ttl) async {
    // Atomic MULTI/EXEC: SET NX gives a new counter its expiry; INCR bumps it.
    // If an expiring key vanished right before INCR, SET NX returned null yet
    // INCR recreated it at 1 without a TTL, so PEXPIRE restores the window.
    final exec = await _transaction([
      ['SET', _k(key), '0', 'NX', 'PX', _ms(ttl)],
      ['INCR', _k(key)],
    ]);
    final count = exec.length >= 2 ? exec[1] : null;
    if (count is! int) {
      throw const StateStoreUnavailable('redis INCR');
    }
    if (exec.first == null && count == 1) {
      await _one(['PEXPIRE', _k(key), _ms(ttl)]);
    }
    return count;
  }

  @override
  Future<void> push(
    String key,
    String value,
    Duration ttl, {
    int maxLength = 1000,
  }) async {
    await _transaction([
      ['RPUSH', _k(key), value],
      ['LTRIM', _k(key), '-$maxLength', '-1'],
      ['PEXPIRE', _k(key), _ms(ttl)],
    ]);
  }

  @override
  Future<List<String>> drain(String key, {int max = 100}) async {
    final exec = await _transaction([
      ['LRANGE', _k(key), '0', '${max - 1}'],
      ['LTRIM', _k(key), '$max', '-1'],
    ]);
    final items = exec.first;
    return items is List
        ? [
            for (final item in items)
              if (item is String) item,
          ]
        : const [];
  }

  @override
  Future<void> close() async {
    _connection?.close();
    _connection = null;
  }
}
