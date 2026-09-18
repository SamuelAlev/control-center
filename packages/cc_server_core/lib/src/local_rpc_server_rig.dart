part of 'local_rpc_server.dart';

const int _maxRigTransferBody = 700 * 1024 * 1024;
const int _maxRigMicrophoneChunk = 128 * 1024;

extension _RigMethods on LocalRpcServer {
  Future<void> _serveRigStream(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    res.headers
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type, Range');
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (request.method != 'GET' && request.method != 'POST') {
      await _closeProxy(res, HttpStatus.methodNotAllowed);
      return;
    }
    final rigId = request.uri.pathSegments.length >= 3
        ? request.uri.pathSegments[2]
        : '';
    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (rigId.isEmpty ||
        workspaceId == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }
    final target = 'rig:$workspaceId/$rigId';
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(target, psk, sig)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    if (request.method == 'POST') {
      final userId = device?.userId;
      final input = rigAudioInput;
      if (q['lane'] != 'microphone' || userId == null || userId.isEmpty) {
        await _closeProxy(res, HttpStatus.forbidden);
        return;
      }
      if (input == null) {
        await _closeProxy(res, HttpStatus.notFound);
        return;
      }
      final declared = request.contentLength;
      if (declared > _maxRigMicrophoneChunk) {
        await _closeProxy(res, HttpStatus.requestEntityTooLarge);
        return;
      }
      final body = BytesBuilder(copy: false);
      var total = 0;
      await for (final chunk in request) {
        total += chunk.length;
        if (total > _maxRigMicrophoneChunk) {
          await _closeProxy(res, HttpStatus.requestEntityTooLarge);
          return;
        }
        body.add(chunk);
      }
      final sampleRate = int.tryParse(q['rate'] ?? '') ?? 16000;
      final channels = int.tryParse(q['channels'] ?? '') ?? 1;
      final sessionId = q['session'];
      if (sessionId == null || sessionId.isEmpty || sessionId.length > 128) {
        await _closeProxy(res, HttpStatus.badRequest);
        return;
      }
      if (sampleRate < 8000 ||
          sampleRate > 48000 ||
          channels < 1 ||
          channels > 2) {
        await _closeProxy(res, HttpStatus.badRequest);
        return;
      }
      try {
        final accepted = await input(
          workspaceId: workspaceId,
          rigId: rigId,
          actor: UserPrincipal(userId),
          sessionId: sessionId,
          bytes: body.takeBytes(),
          sampleRate: sampleRate,
          channels: channels,
          start: q['start'] == '1',
          end: q['end'] == '1',
        );
        await _closeProxy(
          res,
          accepted ? HttpStatus.noContent : HttpStatus.conflict,
        );
      } on Object catch (e, st) {
        _e('rig microphone failed for $workspaceId/$rigId: $e', e, st);
        await _closeProxy(res, HttpStatus.internalServerError);
      }
      return;
    }

    final resolver = rigStream;
    if (resolver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    ({Stream<List<int>> bytes, String contentType})? opened;
    try {
      opened = await resolver(
        workspaceId: workspaceId,
        rigId: rigId,
        request: q,
      );
    } on RigStreamUnavailable catch (e) {
      _w('rig stream unavailable for $workspaceId/$rigId: ${e.message}');
      res.headers.set('x-rig-stream-error', e.code);
      await _closeProxy(res, HttpStatus.serviceUnavailable);
      return;
    } on Object catch (e, st) {
      _e('rig stream failed for $workspaceId/$rigId: $e', e, st);
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (opened == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }

    res.statusCode = HttpStatus.ok;
    res.bufferOutput = false;
    res.headers
      ..contentType = relayContentType(opened.contentType)
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..set(HttpHeaders.connectionHeader, 'keep-alive');
    try {
      await res.addStream(opened.bytes);
    } catch (_) {
      // Viewer disconnected mid-stream; the source was cancelled.
    }
    try {
      await res.close();
    } catch (_) {
      // Already gone.
    }
  }

  void _setRigTransferCors(HttpRequest request, HttpResponse response) {
    final origin = request.headers.value('origin') ?? '*';
    response.headers
      ..set('Access-Control-Allow-Origin', origin)
      ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
      ..set('Access-Control-Allow-Headers', 'Content-Type')
      ..set('Cross-Origin-Resource-Policy', 'cross-origin')
      ..set(
        'Access-Control-Expose-Headers',
        'Content-Disposition, Content-Length, Content-Type',
      )
      ..set('Vary', 'Origin');
  }

  Future<({String workspaceId, String rigId, Principal principal})?>
  _authorizeRigTransfer(HttpRequest request) async {
    final res = request.response;
    final rigId = request.uri.pathSegments.length >= 3
        ? request.uri.pathSegments[2]
        : '';
    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (rigId.isEmpty ||
        workspaceId == null ||
        deviceId == null ||
        sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return null;
    }
    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(
          LocalRpcServer.rigTransferTarget(workspaceId, rigId),
          psk,
          sig,
        )) {
      await _closeProxy(res, HttpStatus.forbidden);
      return null;
    }
    if (await _lacksMembershipForUser(device?.userId, workspaceId)) {
      await _closeProxy(res, HttpStatus.forbidden);
      return null;
    }
    final userId = device?.userId;
    if (userId == null || userId.isEmpty) {
      await _closeProxy(res, HttpStatus.forbidden);
      return null;
    }
    if (rigTransfer == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return null;
    }
    return (
      workspaceId: workspaceId,
      rigId: rigId,
      principal: UserPrincipal(userId),
    );
  }

  Future<Map<String, dynamic>?> _readRigTransferBody(
    HttpRequest request,
  ) async {
    final res = request.response;
    final declared = request.contentLength;
    if (declared > _maxRigTransferBody) {
      await _closeProxy(res, HttpStatus.requestEntityTooLarge);
      return null;
    }
    final builder = BytesBuilder(copy: false);
    try {
      await for (final chunk in request) {
        builder.add(chunk);
        if (builder.length > _maxRigTransferBody) {
          await _closeProxy(res, HttpStatus.requestEntityTooLarge);
          return null;
        }
      }
    } on Object {
      await _closeProxy(res, HttpStatus.badRequest);
      return null;
    }
    try {
      final decoded = jsonDecode(utf8.decode(builder.takeBytes()));
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } on Object {
      // Falls through to the 400 below.
    }
    await _closeProxy(res, HttpStatus.badRequest);
    return null;
  }

  Future<void> _serveRigClipboard(HttpRequest request) async {
    final res = request.response;
    _setRigTransferCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    final auth = await _authorizeRigTransfer(request);
    if (auth == null) {
      return;
    }
    final rigs = rigTransfer!;
    try {
      if (request.method == 'GET') {
        final data = await rigs.readClipboard(
          workspaceId: auth.workspaceId,
          rigId: auth.rigId,
          actor: auth.principal,
          selection: RigClipboardSelection.fromWire(
            request.uri.queryParameters['sel'],
          ),
        );
        await _sendJson(res, data.toJson());
        return;
      }
      if (request.method == 'POST') {
        final body = await _readRigTransferBody(request);
        if (body == null) {
          return;
        }
        final result = await rigs.writeClipboard(
          workspaceId: auth.workspaceId,
          rigId: auth.rigId,
          data: RigClipboardData.fromJson(body),
          actor: auth.principal,
        );
        await _sendJson(res, {
          'ok': !result.isError,
          'is_error': result.isError,
          'summary': result.text,
        });
        return;
      }
      await _closeProxy(res, HttpStatus.methodNotAllowed);
    } on Object catch (e, st) {
      _e(
        'rig clipboard failed for ${auth.workspaceId}/${auth.rigId}: $e',
        e,
        st,
      );
      await _closeProxy(res, HttpStatus.internalServerError);
    }
  }

  Future<void> _serveRigFiles(HttpRequest request) async {
    final res = request.response;
    _setRigTransferCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    final auth = await _authorizeRigTransfer(request);
    if (auth == null) {
      return;
    }
    final rigs = rigTransfer!;
    try {
      if (request.method == 'GET') {
        final encoded = request.uri.queryParameters['p'];
        final guestPath = encoded == null ? null : _decodeBase64Url(encoded);
        if (guestPath == null || guestPath.isEmpty) {
          await _closeProxy(res, HttpStatus.badRequest);
          return;
        }
        final file = await rigs.readFile(
          workspaceId: auth.workspaceId,
          rigId: auth.rigId,
          guestPath: guestPath,
          actor: auth.principal,
        );
        if (file == null) {
          await _closeProxy(res, HttpStatus.notFound);
          return;
        }
        res.statusCode = HttpStatus.ok;
        res.headers
          ..contentType = relayContentType(
            file.mediaType ?? 'application/octet-stream',
          )
          ..set(HttpHeaders.cacheControlHeader, 'no-store')
          ..set(
            'content-disposition',
            "attachment; filename*=UTF-8''${Uri.encodeComponent(file.name)}",
          );
        res.add(file.bytes);
        await res.close();
        return;
      }
      if (request.method == 'POST') {
        final body = await _readRigTransferBody(request);
        if (body == null) {
          return;
        }
        final files = <RigFilePayload>[];
        for (final entry in (body['files'] as List? ?? const [])) {
          if (entry is! Map) {
            continue;
          }
          final name = entry['name'];
          final bytes = entry['bytes'];
          if (name is! String || bytes is! String) {
            continue;
          }
          final Uint8List decoded;
          try {
            decoded = base64Decode(bytes);
          } on FormatException {
            await _closeProxy(res, HttpStatus.badRequest);
            return;
          }
          files.add(
            RigFilePayload(
              name: name,
              bytes: decoded,
              mediaType: entry['media_type'] is String
                  ? entry['media_type'] as String
                  : null,
            ),
          );
        }
        final x = body['x'];
        final y = body['y'];
        final result = await rigs.dropFiles(
          workspaceId: auth.workspaceId,
          rigId: auth.rigId,
          request: RigDropRequest(
            files: files,
            x: x is int ? x : null,
            y: y is int ? y : null,
          ),
          actor: auth.principal,
        );
        await _sendJson(res, result.toJson());
        return;
      }
      await _closeProxy(res, HttpStatus.methodNotAllowed);
    } on Object catch (e, st) {
      _e('rig files failed for ${auth.workspaceId}/${auth.rigId}: $e', e, st);
      await _closeProxy(res, HttpStatus.internalServerError);
    }
  }

  static String? _decodeBase64Url(String value) {
    try {
      final padded = value.padRight((value.length + 3) & ~3, '=');
      return utf8.decode(base64Url.decode(padded));
    } on Object {
      return null;
    }
  }

  Future<void> _sendJson(HttpResponse res, Map<String, dynamic> body) async {
    final bytes = utf8.encode(jsonEncode(body));
    res.statusCode = HttpStatus.ok;
    res.headers
      ..contentType = ContentType.json
      ..set(HttpHeaders.cacheControlHeader, 'no-store')
      ..contentLength = bytes.length;
    res.add(bytes);
    await res.close();
  }
}
