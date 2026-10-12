import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cc_rpc/cc_rpc.dart';

/// Only these first-party byte paths may cross an authenticated resource lane.
/// Public web assets, OAuth callbacks, webhooks and third-party MCP are separate
/// protocols and must never be reachable through this loopback adapter.
bool isSecureResourcePath(String path) =>
    const {
      '/proxy/media',
      '/proxy/font',
      '/meeting/audio',
      '/workspace/logo',
      '/blob',
      '/backup/workspace',
      '/backup/snapshot',
      '/backup/restore',
      '/soundscape/stream',
      '/soundscape/playlist.m3u8',
      '/soundscape/seg',
    }.contains(path) ||
    path.startsWith('/proxy/vscode/') ||
    path.startsWith('/rig/stream/') ||
    path.startsWith('/rig/clipboard/') ||
    path.startsWith('/rig/files/');

/// Identity comes from the Noise-authenticated device, not a resource header.
final class SecureResourcePrincipal {
  const SecureResourcePrincipal({required this.deviceId, required this.userId});
  final String deviceId;
  final String userId;
}

/// Reuses the server's HTTP handlers without putting plaintext on a remote
/// socket. The private listener is loopback-only and requires a random,
/// server-internal session capability which is never sent to a client.
final class SecureResourceHost {
  SecureResourceHost._(this._listener, this._handle, this._editorBridge);

  static const _capabilityHeader = 'x-cc-sealed-resource';
  static const _operationHeader = 'x-cc-resource-operation';
  final HttpServer _listener;
  final Future<void> Function(
    HttpRequest,
    SecureResourcePrincipal,
    RemoteResourceRequest,
  )
  _handle;
  final Future<void> Function(HttpRequest, String, bool) _editorBridge;
  final _editorCapability = RemoteControlCrypto.generatePsk();
  final _bindings = <String, _ResourceBinding>{};
  final _operations = <String, _ResourceOperation>{};
  final _activeByUser = <String, int>{};
  bool _closed = false;

  static Future<SecureResourceHost> start({
    required Future<void> Function(
      HttpRequest,
      SecureResourcePrincipal,
      RemoteResourceRequest,
    )
    handleRequest,
    required Future<void> Function(HttpRequest, String, bool)
    handleEditorBridge,
  }) async {
    final listener = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final host = SecureResourceHost._(
      listener,
      handleRequest,
      handleEditorBridge,
    );
    listener.listen((request) => unawaited(host._accept(request)));
    return host;
  }

  /// Server-launched editor extensions receive this loopback-only IPC address.
  /// Its secret prefix is not a client capability and never crosses the relay.
  Uri get editorBridgeBase => Uri(
    scheme: 'http',
    host: InternetAddress.loopbackIPv4.address,
    port: _listener.port,
    path: '/__cc_editor_bridge/$_editorCapability/',
  );

  void attach(
    SecureRpcChannel channel, {
    required String deviceId,
    required String userId,
    DateTime? expiresAt,
  }) {
    if (_closed || !channel.isOpen) {
      throw StateError('Secure resource host is closed');
    }
    final capability = RemoteControlCrypto.generatePsk();
    final principal = SecureResourcePrincipal(
      deviceId: deviceId,
      userId: userId,
    );
    final server = RemoteResourceServer(
      channel,
      onRequest: (request) => _forwardHttp(request, capability),
      onWebSocket: (request) => _forwardWebSocket(request, capability),
    );
    final binding = _ResourceBinding(principal, channel, server);
    _bindings[capability] = binding;
    binding.setExpiry(expiresAt);
    unawaited(
      server.done.then((_) {
        binding.expiry?.cancel();
        _bindings.remove(capability);
      }),
    );
  }

  /// Cancels existing streams on membership loss. New streams go through the
  /// original handler's registered-workspace and membership checks again.
  Future<void> cancelForUser(String userId) async {
    await Future.wait([
      for (final binding in _bindings.values.toList())
        if (binding.principal.userId == userId) binding.server.cancelAll(),
    ]);
  }

  /// Also covers relayed connections, which share this resource host.
  void reconcileDevices(Map<String, DateTime?> activeDevices) {
    for (final binding in _bindings.values.toList()) {
      final id = binding.principal.deviceId;
      if (!activeDevices.containsKey(id)) {
        unawaited(binding.channel.close());
      } else {
        binding.setExpiry(activeDevices[id]);
      }
    }
  }

  Future<void> _accept(HttpRequest request) async {
    _ResourceOperation? accepted;
    try {
      if (_closed || request.connectionInfo?.remoteAddress.isLoopback != true) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }
      final parts = request.uri.pathSegments;
      if (parts.length == 6 &&
          parts[0] == '__cc_editor_bridge' &&
          parts[1] == _editorCapability &&
          parts[2] == 'proxy' &&
          parts[3] == 'vscode' &&
          ((parts[5] == '__cc_open__' && request.method == 'POST') ||
              (parts[5] == '__cc_commands__' && request.method == 'GET'))) {
        await _editorBridge(request, parts[4], parts[5] == '__cc_commands__');
        return;
      }
      final capability = request.headers.value(_capabilityHeader);
      final binding = _bindings[capability];
      final operation = _operations[request.headers.value(_operationHeader)];
      if (binding == null ||
          !binding.channel.isOpen ||
          operation == null ||
          operation.capability != capability ||
          operation.accepted ||
          operation.finished ||
          operation.transfer.isCancelled ||
          !isSecureResourcePath(request.uri.path)) {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
        return;
      }
      operation.accepted = true;
      accepted = operation;
      // Live resource streams must not wait for dart:io's response buffer
      // to fill before their first bytes reach the encrypted channel.
      request.response.bufferOutput = false;
      // Incoming HttpRequest headers are immutable. Egress proxies strip the
      // internal capability headers rather than mutating this request.
      await _handle(request, binding.principal, operation.transfer);
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } catch (_) {
        // A canceled transfer may already have closed the response.
      }
    } finally {
      if (accepted != null) _finishOperation(accepted);
    }
  }

  _ResourceOperation _register(
    RemoteResourceRequest request,
    String capability,
  ) {
    final binding = _bindings[capability];
    if (binding == null || !binding.channel.isOpen || request.isCancelled) {
      throw const HttpException('Resource session closed');
    }
    final userId = binding.principal.userId;
    final active = _activeByUser[userId] ?? 0;
    // Count actual private handlers, not just reusable tunnel IDs. Canceling
    // and immediately reopening cannot evade limits while old work unwinds.
    if (active >= 32 || _operations.length >= 128) {
      throw const HttpException('Resource capacity exhausted');
    }
    final operation = _ResourceOperation(
      RemoteControlCrypto.generatePsk(),
      capability,
      userId,
      request,
    );
    _operations[operation.id] = operation;
    _activeByUser[userId] = active + 1;
    return operation;
  }

  void _finishOperation(_ResourceOperation operation) {
    if (operation.finished) return;
    operation.finished = true;
    _operations.remove(operation.id);
    final remaining = (_activeByUser[operation.userId] ?? 1) - 1;
    if (remaining == 0) {
      _activeByUser.remove(operation.userId);
    } else {
      _activeByUser[operation.userId] = remaining;
    }
  }

  void _finishUnaccepted(_ResourceOperation operation) {
    if (!operation.accepted) _finishOperation(operation);
  }

  Uri _target(Uri uri, {bool webSocket = false}) {
    if (uri.hasScheme ||
        uri.hasAuthority ||
        uri.hasFragment ||
        !uri.path.startsWith('/') ||
        uri.path.contains('\\') ||
        uri.path.contains('\u0000') ||
        uri.pathSegments.any((part) => part == '.' || part == '..') ||
        !isSecureResourcePath(uri.path) ||
        (webSocket && !uri.path.startsWith('/proxy/vscode/'))) {
      throw const FormatException('Resource route is not allowed');
    }
    return Uri(
      scheme: webSocket ? 'ws' : 'http',
      host: InternetAddress.loopbackIPv4.address,
      port: _listener.port,
    ).resolveUri(uri);
  }

  Future<RemoteResourceResponse> _forwardHttp(
    RemoteResourceRequest request,
    String capability,
  ) async {
    final target = _target(request.uri);
    final operation = _register(request, capability);
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..userAgent = 'control-center-sealed-resource';
    unawaited(
      request.cancelled.then((_) {
        if (request.isCancelled) {
          client.close(force: true);
          _finishUnaccepted(operation);
        }
      }),
    );
    try {
      final upstream = await client.openUrl(request.method, target);
      upstream.followRedirects = false;
      for (final entry in request.headers.entries) {
        if (!_stripRequestHeader(entry.key)) {
          upstream.headers.set(entry.key, entry.value);
        }
      }
      upstream.headers.set(_capabilityHeader, capability);
      upstream.headers.set(_operationHeader, operation.id);
      if (request.isCancelled) throw const HttpException('Resource canceled');
      await upstream.addStream(request.body);
      final response = await upstream.close();
      final headers = <String, List<String>>{};
      response.headers.forEach((name, values) {
        if (!_hopByHop(name)) headers[name] = List.of(values);
      });
      if (response.compressionState ==
          HttpClientResponseCompressionState.decompressed) {
        headers.remove(HttpHeaders.contentEncodingHeader);
        headers.remove(HttpHeaders.contentLengthHeader);
      }
      // A redirect must stay inside the client's capability-bound virtual
      // resource origin. Never hand a browser an absolute readable fallback.
      final locations = headers[HttpHeaders.locationHeader];
      if (locations != null &&
          locations.any((value) {
            final location = Uri.tryParse(value);
            return location == null ||
                location.hasScheme ||
                location.hasAuthority;
          })) {
        throw const HttpException('External resource redirect refused');
      }
      Stream<Uint8List> body() async* {
        try {
          await for (final chunk in response) {
            yield chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
          }
        } catch (_) {
          // Closing a canceled transfer intentionally aborts its private
          // HttpClient. Do not leak that expected teardown error to the zone.
          if (!request.isCancelled) rethrow;
        } finally {
          client.close(force: true);
        }
      }

      return RemoteResourceResponse(
        statusCode: response.statusCode,
        headers: headers,
        body: body(),
        onClose: () async {
          client.close(force: true);
          _finishUnaccepted(operation);
        },
      );
    } catch (_) {
      client.close(force: true);
      _finishUnaccepted(operation);
      rethrow;
    }
  }

  Future<RemoteResourceSocket> _forwardWebSocket(
    RemoteResourceRequest request,
    String capability,
  ) async {
    final target = _target(request.uri, webSocket: true);
    final operation = _register(request, capability);
    final headers = <String, dynamic>{
      for (final entry in request.headers.entries)
        if (!_stripRequestHeader(entry.key)) entry.key: entry.value,
      _capabilityHeader: capability,
      _operationHeader: operation.id,
    };
    var abandoned = false;
    final connecting =
        WebSocket.connect(
          target.toString(),
          headers: headers,
          protocols: request.protocols,
          compression: CompressionOptions.compressionOff,
        ).then((socket) async {
          if (abandoned || request.isCancelled) {
            await socket.close(WebSocketStatus.goingAway);
            throw const HttpException('Resource canceled');
          }
          return socket;
        });
    final WebSocket socket;
    try {
      socket = await connecting.timeout(const Duration(seconds: 15));
    } catch (_) {
      abandoned = true;
      _finishUnaccepted(operation);
      rethrow;
    }
    unawaited(
      request.cancelled.then((_) async {
        if (request.isCancelled) await socket.close(WebSocketStatus.goingAway);
      }),
    );
    return RemoteResourceSocket(
      protocol: socket.protocol ?? '',
      incoming: socket.map<Object>(
        (data) => data is String || data is Uint8List
            ? data as Object
            : Uint8List.fromList(data as List<int>),
      ),
      onSend: (data) => socket.addStream(Stream<Object>.value(data)),
      onClose: (code, reason) => socket.close(code, reason),
      readCloseCode: () => socket.closeCode,
      readCloseReason: () => socket.closeReason,
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    final bindings = _bindings.values.toList();
    _bindings.clear();
    for (final binding in bindings) {
      binding.expiry?.cancel();
      await binding.channel.close();
      await binding.server.close();
    }
    for (final operation in _operations.values.toList()) {
      _finishUnaccepted(operation);
    }
    await _listener.close(force: true);
  }

  static bool _stripRequestHeader(String name) {
    final lower = name.toLowerCase();
    return _hopByHop(lower) ||
        lower == HttpHeaders.hostHeader ||
        lower == HttpHeaders.contentLengthHeader ||
        // Synthetic browser responses carry decoded bytes. Restrict the private
        // HTTP hop to encodings supported by Dart's automatic decompressor.
        lower == HttpHeaders.acceptEncodingHeader ||
        lower == HttpHeaders.authorizationHeader ||
        lower == 'origin' ||
        lower == HttpHeaders.refererHeader ||
        (lower.startsWith('x-cc-') && lower != 'x-cc-file-name') ||
        lower.startsWith('x-forwarded-') ||
        lower.startsWith('sec-websocket-');
  }

  static bool _hopByHop(String name) => const {
    'connection',
    'keep-alive',
    'proxy-authenticate',
    'proxy-authorization',
    'te',
    'trailer',
    'transfer-encoding',
    'upgrade',
  }.contains(name.toLowerCase());
}

final class _ResourceOperation {
  _ResourceOperation(this.id, this.capability, this.userId, this.transfer);
  final String id;
  final String capability;
  final String userId;
  final RemoteResourceRequest transfer;
  bool accepted = false;
  bool finished = false;
}

final class _ResourceBinding {
  _ResourceBinding(this.principal, this.channel, this.server);
  final SecureResourcePrincipal principal;
  final SecureRpcChannel channel;
  final RemoteResourceServer server;
  Timer? expiry;

  void setExpiry(DateTime? expiresAt) {
    expiry?.cancel();
    if (expiresAt != null) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        unawaited(channel.close());
      } else {
        expiry = Timer(remaining, () => unawaited(channel.close()));
      }
    }
  }
}
