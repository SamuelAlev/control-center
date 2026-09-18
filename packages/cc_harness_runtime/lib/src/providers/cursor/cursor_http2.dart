import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cc_harness_runtime/src/oauth/cursor_oauth.dart';
import 'package:cc_harness_runtime/src/providers/cursor/connect_framing.dart';
import 'package:cc_harness_runtime/src/providers/cursor/cursor_transport.dart';
import 'package:http2/http2.dart';

/// HTTP/2 Connect transport for Cursor AgentService.
///
/// Cursor's host rejects HTTP/1 (`464`), so every request speaks `h2` over
/// TLS ALPN. Unary GetUsableModels uses Connect's `application/proto` unary
/// encoding; the bidirectional Run stream uses `application/connect+proto`.
class Http2CursorAgentTransport implements CursorAgentTransport {
  /// Creates a transport.
  const Http2CursorAgentTransport();

  @override
  Future<CursorRunSession> openRun({
    required String accessToken,
    Uri? baseUrl,
  }) async {
    final uri = _resolveBase(baseUrl);
    final connection = await _connect(uri);
    final stream = connection.makeRequest(
      _headers(
        uri: uri,
        path: CursorAgentPaths.run,
        accessToken: accessToken,
        contentType: 'application/connect+proto',
        connectProtocol: true,
      ),
    );
    // Closed when the HTTP/2 stream ends or CursorRunSession.close runs.
    // ignore: close_sinks
    final frames = StreamController<CursorRunFrame>();
    final decoder = ConnectFrameDecoder();
    var opened = false;

    stream.incomingMessages.listen(
      (message) {
        if (message is HeadersStreamMessage && !opened) {
          opened = true;
          final status = _statusOf(message.headers);
          if (status != null && (status < 200 || status >= 300)) {
            frames.addError(
              CursorTransportException(
                'Cursor AgentService Run failed with HTTP $status.',
                statusCode: status,
              ),
            );
            unawaited(frames.close());
            return;
          }
        }
        if (message is DataStreamMessage) {
          for (final frame in decoder.add(message.bytes)) {
            frames.add(
              CursorRunFrame(flags: frame.flags, payload: frame.payload),
            );
          }
        }
      },
      onError: frames.addError,
      onDone: () {
        if (!frames.isClosed) {
          unawaited(frames.close());
        }
      },
      cancelOnError: false,
    );

    return CursorRunSession(
      send: (proto) {
        stream.sendData(frameConnectMessage(proto));
      },
      frames: frames.stream,
      close: () async {
        if (!frames.isClosed) {
          await frames.close();
        }
        try {
          await stream.outgoingMessages.close();
        } on Object {
          // Already closed by the peer.
        }
        stream.terminate();
        await connection.finish();
      },
    );
  }

  @override
  Future<List<int>> getUsableModels({
    required String accessToken,
    required List<int> request,
    Uri? baseUrl,
  }) async {
    final uri = _resolveBase(baseUrl);
    final connection = await _connect(uri);
    try {
      final stream = connection.makeRequest(
        _headers(
          uri: uri,
          path: CursorAgentPaths.getUsableModels,
          accessToken: accessToken,
          contentType: 'application/proto',
        ),
      );
      if (request.isNotEmpty) {
        stream.sendData(request, endStream: true);
      } else {
        await stream.outgoingMessages.close();
      }
      final body = BytesBuilder(copy: false);
      var status = 200;
      await for (final message in stream.incomingMessages) {
        if (message is HeadersStreamMessage) {
          status = _statusOf(message.headers) ?? status;
        } else if (message is DataStreamMessage) {
          body.add(message.bytes);
        }
      }
      if (status < 200 || status >= 300) {
        throw CursorTransportException(
          'Cursor GetUsableModels failed with HTTP $status.',
          statusCode: status,
        );
      }
      return decodeConnectUnaryBody(body.takeBytes());
    } finally {
      await connection.finish();
    }
  }
}

/// Transport-level failure (HTTP status, ALPN miss, socket).
class CursorTransportException implements Exception {
  /// Creates an exception.
  const CursorTransportException(this.message, {this.statusCode});

  /// Human-readable cause.
  final String message;

  /// HTTP status, when the request reached the host.
  final int? statusCode;

  @override
  String toString() => message;
}

Uri _resolveBase(Uri? baseUrl) {
  if (baseUrl != null) {
    return baseUrl;
  }
  return Uri.parse(CursorOAuth.defaultApiBase);
}

Future<ClientTransportConnection> _connect(Uri uri) async {
  final host = uri.host;
  final port = uri.hasPort ? uri.port : (uri.scheme == 'http' ? 80 : 443);
  if (uri.scheme == 'http') {
    // Owned by ClientTransportConnection.viaSocket.
    // ignore: close_sinks
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 20),
    );
    return ClientTransportConnection.viaSocket(socket);
  }
  // Owned by ClientTransportConnection.viaSocket after ALPN succeeds.
  // ignore: close_sinks
  final socket = await SecureSocket.connect(
    host,
    port,
    timeout: const Duration(seconds: 20),
    supportedProtocols: const ['h2'],
  );
  if (socket.selectedProtocol != 'h2') {
    await socket.close();
    throw CursorTransportException(
      'Cursor AgentService requires HTTP/2 (ALPN h2); '
      'negotiated ${socket.selectedProtocol ?? 'none'}.',
    );
  }
  return ClientTransportConnection.viaSocket(socket);
}

List<Header> _headers({
  required Uri uri,
  required String path,
  required String accessToken,
  required String contentType,
  bool connectProtocol = false,
}) {
  final authority = uri.hasPort && uri.port != 443 && uri.port != 80
      ? '${uri.host}:${uri.port}'
      : uri.host;
  return [
    Header.ascii(':method', 'POST'),
    Header.ascii(':scheme', uri.scheme.isEmpty ? 'https' : uri.scheme),
    Header.ascii(':path', path),
    Header.ascii(':authority', authority),
    Header.ascii('content-type', contentType),
    if (connectProtocol) Header.ascii('connect-protocol-version', '1'),
    Header.ascii('te', 'trailers'),
    Header.ascii('authorization', 'Bearer $accessToken'),
    Header.ascii('x-ghost-mode', 'true'),
    Header.ascii('x-cursor-client-version', kCursorClientVersion),
    Header.ascii('x-cursor-client-type', 'cli'),
    Header.ascii('x-request-id', _uuidV4()),
  ];
}

int? _statusOf(List<Header> headers) {
  for (final header in headers) {
    if (ascii.decode(header.name) == ':status') {
      return int.tryParse(ascii.decode(header.value));
    }
  }
  return null;
}

String _uuidV4() {
  final rnd = Random.secure();
  final bytes = Uint8List.fromList(
    List<int>.generate(16, (_) => rnd.nextInt(256)),
  );
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int i) => bytes[i].toRadixString(16).padLeft(2, '0');
  return '${hex(0)}${hex(1)}${hex(2)}${hex(3)}-'
      '${hex(4)}${hex(5)}-'
      '${hex(6)}${hex(7)}-'
      '${hex(8)}${hex(9)}-'
      '${hex(10)}${hex(11)}${hex(12)}${hex(13)}${hex(14)}${hex(15)}';
}
