import 'dart:async';
import 'dart:io';

import 'package:cc_infra/src/sandboxing/domain_matcher.dart';
import 'package:cc_infra/src/sandboxing/sandbox_config.dart';

/// Minimal SOCKS5 proxy used alongside the HTTP proxy for tools that don't
/// honour `HTTP_PROXY` and dial raw TCP.
///
/// Only implements:
/// - SOCKS5 method negotiation with `NO AUTH` (0x00)
/// - The `CONNECT` (0x01) command
/// - `IPv4` (0x01) and `DOMAIN` (0x03) address types
///
/// IPv6 and `BIND` / `UDP ASSOCIATE` are rejected. Hosts are filtered against
/// the same allow/deny list the HTTP proxy uses.
class SandboxSocksProxy {
  SandboxSocksProxy._(this._server);

  final ServerSocket _server;
  NetworkConfig _network = const NetworkConfig();

  /// Port the SOCKS proxy is listening on. Threaded into the sandbox via
  /// `ALL_PROXY=socks5://127.0.0.1:<port>`.
  int get port => _server.port;

  /// Starts a SOCKS5 listener on `127.0.0.1:0`.
  static Future<SandboxSocksProxy> start() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final proxy = SandboxSocksProxy._(server);
    proxy._listen();
    return proxy;
  }

  /// Replaces the active filter set.
  void updateConfig({required NetworkConfig network}) {
    _network = network;
  }

  /// Stops the listener.
  Future<void> close() async => _server.close();

  void _listen() {
    _server.listen((socket) => unawaited(_handle(socket)), onError: (_) {});
  }

  Future<void> _handle(Socket client) async {
    final reader = _StreamReader(client);
    try {
      // Greeting: VER, NMETHODS, METHODS...
      final greeting = await reader.read(2);
      if (greeting[0] != 0x05) {
        await client.close();
        return;
      }
      final nMethods = greeting[1];
      await reader.read(nMethods); // we ignore the methods list
      client.add([0x05, 0x00]); // VER 5, NO AUTH
      await client.flush();

      // Request: VER, CMD, RSV, ATYP, DST.ADDR, DST.PORT
      final header = await reader.read(4);
      if (header[0] != 0x05 || header[1] != 0x01) {
        client.add(_reply(0x07)); // command not supported
        await client.close();
        return;
      }
      final atyp = header[3];
      String host;
      switch (atyp) {
        case 0x01: // IPv4
          final addr = await reader.read(4);
          host = addr.join('.');
          break;
        case 0x03: // DOMAINNAME
          final lenByte = await reader.read(1);
          final len = lenByte[0];
          final addr = await reader.read(len);
          host = String.fromCharCodes(addr);
          break;
        default:
          client.add(_reply(0x08)); // address type not supported
          await client.close();
          return;
      }
      final portBytes = await reader.read(2);
      final port = (portBytes[0] << 8) | portBytes[1];

      if (!_isAllowed(host)) {
        client.add(_reply(0x02)); // not allowed by ruleset
        await client.close();
        return;
      }

      final Socket upstream;
      try {
        upstream = await Socket.connect(host, port);
      } catch (_) {
        client.add(_reply(0x05)); // connection refused
        await client.close();
        return;
      }

      client.add(_reply(0x00)); // succeeded
      await client.flush();

      // Forward anything we already buffered in the reader, then pipe.
      final pending = reader.drain();
      if (pending.isNotEmpty) {
        upstream.add(pending);
      }
      _pipeBidirectional(client, upstream);
    } catch (_) {
      await client.close();
    }
  }

  bool _isAllowed(String host) {
    if (matchesAny(host, _network.deniedDomains)) {
      return false;
    }
    if (_network.allowAll) {
      return true;
    }
    return matchesAny(host, _network.allowedDomains);
  }

  void _pipeBidirectional(Socket a, Socket b) {
    a.listen(b.add, onError: (_) {}, onDone: () => b.close(), cancelOnError: false);
    b.listen(a.add, onError: (_) {}, onDone: () => a.close(), cancelOnError: false);
  }

  // VER, REP, RSV, ATYP=IPv4, BND.ADDR=0.0.0.0, BND.PORT=0
  static List<int> _reply(int rep) =>
      [0x05, rep, 0x00, 0x01, 0, 0, 0, 0, 0, 0];
}

/// Tiny helper that lets us pull a known number of bytes from a `Socket`
/// without dealing with how many `data` events the OS chunks the stream into.
class _StreamReader {
  _StreamReader(Stream<List<int>> source) {
    _sub = source.listen(
      (chunk) {
        _buffer.addAll(chunk);
        _flush();
      },
      onError: (e) {
        final pending = List<Completer<List<int>>>.from(_pending);
        _pending.clear();
        for (final c in pending) {
          if (!c.isCompleted) {
            c.completeError(e);
          }
        }
      },
      onDone: () {
        _done = true;
        _flush();
      },
    );
  }

  late final StreamSubscription<List<int>> _sub;
  final List<int> _buffer = [];
  final List<_ReadRequest> _pending = [];
  bool _done = false;

  Future<List<int>> read(int n) {
    final req = _ReadRequest(n);
    _pending.add(req);
    _flush();
    return req.completer.future;
  }

  List<int> drain() {
    final out = List<int>.from(_buffer);
    _buffer.clear();
    return out;
  }

  void _flush() {
    while (_pending.isNotEmpty) {
      final req = _pending.first;
      if (_buffer.length >= req.n) {
        final out = _buffer.sublist(0, req.n);
        _buffer.removeRange(0, req.n);
        _pending.removeAt(0);
        req.completer.complete(out);
      } else if (_done) {
        _pending.removeAt(0);
        req.completer.completeError(
          StateError('stream closed before ${req.n} bytes'),
        );
      } else {
        return;
      }
    }
  }

  Future<void> close() async => _sub.cancel();
}

class _ReadRequest {
  _ReadRequest(this.n);
  final int n;
  final completer = Completer<List<int>>();
}
