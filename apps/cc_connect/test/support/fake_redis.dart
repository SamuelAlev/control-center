import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

/// A tiny in-test RESP2 server: enough of Redis for `RedisStateStore`
/// (strings with PX/NX, GETDEL, INCR, lists, MULTI/EXEC, AUTH, SELECT).
final class FakeRedis {
  FakeRedis._(this._server) {
    _server.listen(_serve);
  }

  static Future<FakeRedis> start() async =>
      FakeRedis._(await ServerSocket.bind(InternetAddress.loopbackIPv4, 0));

  final ServerSocket _server;
  final List<Socket> _clients = [];
  final Map<String, Object> _data = {};
  final Map<String, DateTime> _expiry = {};

  /// Every command received, as sent.
  final List<List<String>> commands = [];

  /// The password AUTH must carry (null: AUTH not required).
  String? password;

  /// Answer GETDEL with "unknown command" (Redis before 6.2).
  bool oldServer = false;

  int get port => _server.port;

  Future<void> close() async {
    for (final client in [..._clients]) {
      client.destroy();
    }
    await _server.close();
  }

  /// Drops every client connection (the store must reconnect).
  void dropClients() {
    for (final client in [..._clients]) {
      client.destroy();
    }
    _clients.clear();
  }

  void _serve(Socket socket) {
    _clients.add(socket);
    final buffer = BytesBuilder(copy: false);
    var authed = password == null;
    List<List<int>>? queued;
    socket.listen(
      (chunk) {
        buffer.add(chunk);
        var bytes = buffer.takeBytes();
        while (true) {
          final parsed = _parse(bytes);
          if (parsed == null) {
            break;
          }
          bytes = bytes.sublist(parsed.next);
          final command = parsed.args;
          commands.add(command);
          final name = command.first.toUpperCase();
          List<int> reply;
          if (name == 'AUTH') {
            authed = command.last == password;
            reply = authed ? _simple('OK') : _error('WRONGPASS invalid');
          } else if (!authed) {
            reply = _error('NOAUTH Authentication required.');
          } else if (name == 'MULTI') {
            queued = [];
            reply = _simple('OK');
          } else if (name == 'EXEC') {
            final results = queued ?? const [];
            queued = null;
            reply = [
              ...utf8.encode('*${results.length}\r\n'),
              for (final r in results) ...r,
            ];
          } else if (queued != null) {
            queued!.add(_run(command));
            reply = _simple('QUEUED');
          } else {
            reply = _run(command);
          }
          socket.add(reply);
        }
        buffer.add(bytes);
      },
      onError: (Object _) {},
      onDone: () => _clients.remove(socket),
    );
  }

  static ({List<String> args, int next})? _parse(Uint8List bytes) {
    int? lineEnd(int from) {
      for (var i = from; i + 1 < bytes.length; i++) {
        if (bytes[i] == 13 && bytes[i + 1] == 10) {
          return i;
        }
      }
      return null;
    }

    if (bytes.isEmpty || bytes[0] != 42) {
      return null;
    }
    final end = lineEnd(0);
    if (end == null) {
      return null;
    }
    final count = int.parse(ascii.decode(bytes.sublist(1, end)));
    var cursor = end + 2;
    final args = <String>[];
    for (var i = 0; i < count; i++) {
      if (cursor >= bytes.length) {
        return null;
      }
      final lenEnd = lineEnd(cursor);
      if (lenEnd == null) {
        return null;
      }
      final length = int.parse(ascii.decode(bytes.sublist(cursor + 1, lenEnd)));
      final start = lenEnd + 2;
      if (start + length + 2 > bytes.length) {
        return null;
      }
      args.add(utf8.decode(bytes.sublist(start, start + length)));
      cursor = start + length + 2;
    }
    return (args: args, next: cursor);
  }

  static List<int> _simple(String value) => utf8.encode('+$value\r\n');

  static List<int> _error(String value) => utf8.encode('-$value\r\n');

  static List<int> _int(int value) => utf8.encode(':$value\r\n');

  static List<int> _bulk(String? value) {
    if (value == null) {
      return utf8.encode('\$-1\r\n');
    }
    final bytes = utf8.encode(value);
    return [...utf8.encode('\$${bytes.length}\r\n'), ...bytes, 13, 10];
  }

  Object? _live(String key) {
    final expiry = _expiry[key];
    if (expiry != null && !DateTime.now().isBefore(expiry)) {
      _data.remove(key);
      _expiry.remove(key);
    }
    return _data[key];
  }

  List<int> _run(List<String> c) {
    final name = c.first.toUpperCase();
    switch (name) {
      case 'SELECT':
        return _simple('OK');
      case 'GET':
        final value = _live(c[1]);
        return _bulk(value is String ? value : null);
      case 'SET':
        final key = c[1];
        final nx = c.any((a) => a.toUpperCase() == 'NX');
        final px = c.indexWhere((a) => a.toUpperCase() == 'PX');
        if (nx && _live(key) != null) {
          return _bulk(null);
        }
        _data[key] = c[2];
        if (px > 0) {
          _expiry[key] = DateTime.now().add(
            Duration(milliseconds: int.parse(c[px + 1])),
          );
        } else {
          _expiry.remove(key);
        }
        return _simple('OK');
      case 'GETDEL':
        if (oldServer) {
          return _error("ERR unknown command 'GETDEL'");
        }
        final value = _live(c[1]);
        _data.remove(c[1]);
        _expiry.remove(c[1]);
        return _bulk(value is String ? value : null);
      case 'DEL':
        final existed = _live(c[1]) != null;
        _data.remove(c[1]);
        _expiry.remove(c[1]);
        return _int(existed ? 1 : 0);
      case 'INCR':
        final value = _live(c[1]);
        final next = (value is String ? int.parse(value) : 0) + 1;
        _data[c[1]] = '$next';
        return _int(next);
      case 'RPUSH':
        final list = (_live(c[1]) as List<String>?) ?? <String>[];
        list.addAll(c.skip(2));
        _data[c[1]] = list;
        return _int(list.length);
      case 'LTRIM':
        final list = _live(c[1]) as List<String>?;
        if (list != null) {
          final kept = _range(list, int.parse(c[2]), int.parse(c[3]));
          if (kept.isEmpty) {
            _data.remove(c[1]);
          } else {
            _data[c[1]] = kept;
          }
        }
        return _simple('OK');
      case 'LRANGE':
        final list = (_live(c[1]) as List<String>?) ?? const <String>[];
        final items = _range(list, int.parse(c[2]), int.parse(c[3]));
        return [
          ...utf8.encode('*${items.length}\r\n'),
          for (final item in items) ..._bulk(item),
        ];
      case 'EVAL':
        // The two compare-and-* scripts RedisStateStore sends, recognised by
        // what they call: `EVAL script 1 key expected [value ttl]`.
        final script = c[1];
        final key = c[3];
        final current = _live(key);
        if (current != c[4]) {
          return _int(0);
        }
        if (script.contains("'SET'")) {
          _data[key] = c[5];
          _expiry[key] = DateTime.now().add(
            Duration(milliseconds: int.parse(c[6])),
          );
          return _int(1);
        }
        if (script.contains("'DEL'")) {
          _data.remove(key);
          _expiry.remove(key);
          return _int(1);
        }
        return _error('ERR unknown script');
      case 'PEXPIRE':
        if (_live(c[1]) == null) {
          return _int(0);
        }
        _expiry[c[1]] = DateTime.now().add(
          Duration(milliseconds: int.parse(c[2])),
        );
        return _int(1);
    }
    return _error("ERR unknown command '$name'");
  }

  static List<String> _range(List<String> list, int start, int stop) {
    final n = list.length;
    var from = start < 0 ? n + start : start;
    var to = stop < 0 ? n + stop : stop;
    if (from < 0) {
      from = 0;
    }
    if (to >= n) {
      to = n - 1;
    }
    if (from > to || from >= n) {
      return <String>[];
    }
    return list.sublist(from, to + 1);
  }
}
