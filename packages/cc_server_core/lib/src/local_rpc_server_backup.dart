part of 'local_rpc_server.dart';

extension _BackupMethods on LocalRpcServer {
  Future<void> _serveBackupWorkspace(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(
          'backup-workspace:$workspaceId',
          psk,
          sig,
        )) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    if (await _lacksRoleForUser(
      device?.userId,
      workspaceId,
      WorkspaceRole.admin,
    )) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final writer = backupExport;
    if (writer == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    File? file;
    try {
      file = await writer(workspaceId: workspaceId);
    } on Object catch (e) {
      _w('backup export failed for $workspaceId: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (file == null || !file.existsSync()) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    await _streamDownload(res, file, file.uri.pathSegments.last);
  }

  Future<void> _serveBackupSnapshot(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }

    final q = request.uri.queryParameters;
    final name = q['n'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (name == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(
          'backup-snapshot:$name',
          psk,
          sig,
        )) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    final ownerCheck = isServerOwner;
    final userId = device?.userId;
    if (ownerCheck != null &&
        (userId == null || userId.isEmpty || !await ownerCheck(userId))) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final archiver = backupSnapshotArchive;
    if (archiver == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    File? archive;
    try {
      archive = await archiver(name: name);
    } on Object catch (e) {
      _w('backup snapshot archive failed for $name: $e');
      await _closeProxy(res, HttpStatus.internalServerError);
      return;
    }
    if (archive == null || !archive.existsSync()) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    await _streamDownload(res, archive, archive.uri.pathSegments.last);
  }

  Future<void> _serveBackupRestore(HttpRequest request) async {
    final res = request.response;
    _setProxyCors(request, res);
    if (request.method == 'OPTIONS') {
      res.statusCode = HttpStatus.noContent;
      await res.close();
      return;
    }
    if (request.method != 'POST') {
      await _closeProxy(res, HttpStatus.methodNotAllowed);
      return;
    }

    final q = request.uri.queryParameters;
    final workspaceId = q['w'];
    final deviceId = q['d'];
    final sig = q['s'];
    if (workspaceId == null || deviceId == null || sig == null) {
      await _closeProxy(res, HttpStatus.badRequest);
      return;
    }

    final device = await _activeDevice(deviceId);
    final psk = device?.psk;
    if (psk == null ||
        !RemoteControlCrypto.verifyProxyTarget(
          'backup-restore:$workspaceId',
          psk,
          sig,
        )) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }
    if (await _lacksRoleForUser(
      device?.userId,
      workspaceId,
      WorkspaceRole.owner,
    )) {
      await _closeProxy(res, HttpStatus.forbidden);
      return;
    }

    final adopt = backupRestore;
    final stagingDir = backupUploadDir;
    if (adopt == null || stagingDir == null) {
      await _closeProxy(res, HttpStatus.notFound);
      return;
    }
    if (request.contentLength > LocalRpcServer._maxBackupUploadBytes) {
      await _closeProxy(res, HttpStatus.requestEntityTooLarge);
      return;
    }

    final staged = File(
      '$stagingDir${Platform.pathSeparator}'
      'upload-${DateTime.now().microsecondsSinceEpoch}-$workspaceId.db',
    );
    try {
      await staged.parent.create(recursive: true);
      var written = 0;
      final sink = staged.openWrite();
      try {
        await for (final chunk in request) {
          written += chunk.length;
          if (written > LocalRpcServer._maxBackupUploadBytes) {
            await sink.close();
            await _closeProxy(res, HttpStatus.requestEntityTooLarge);
            return;
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
      if (written == 0) {
        await _closeProxy(res, HttpStatus.badRequest);
        return;
      }
      await adopt(workspaceId: workspaceId, sourcePath: staged.path);
    } on Object catch (e) {
      _w('backup restore failed for $workspaceId: $e');
      res
        ..statusCode = HttpStatus.badRequest
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'error': '$e'}));
      await res.close();
      return;
    } finally {
      await _deleteBestEffort(staged);
    }

    res
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode({'ok': true, 'workspace_id': workspaceId}));
    await res.close();
  }

  Future<void> _streamDownload(
    HttpResponse res,
    File file,
    String filename,
  ) async {
    try {
      res
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.binary
        ..headers.set(HttpHeaders.acceptRangesHeader, 'none')
        ..headers.set('Cache-Control', 'no-store')
        ..headers.set(
          'Content-Disposition',
          'attachment; filename="${filename.replaceAll('"', '')}"',
        )
        ..headers.contentLength = file.lengthSync();
      final raf = await file.open();
      try {
        await res.addStream(_rafChunks(raf));
      } finally {
        await raf.close();
      }
      await _deleteBestEffort(file);
      await res.close();
    } on Object catch (e) {
      _w('backup download stream failed for ${file.path}: $e');
      try {
        await res.close();
      } on Object {
        // Already closed.
      }
      await _deleteBestEffort(file);
    }
  }

  static Stream<List<int>> _rafChunks(RandomAccessFile raf) async* {
    const chunkSize = 64 * 1024;
    while (true) {
      final chunk = await raf.read(chunkSize);
      if (chunk.isEmpty) {
        return;
      }
      yield chunk;
    }
  }

  Future<void> _deleteBestEffort(File file) async {
    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        if (!file.existsSync()) {
          return;
        }
        await file.delete();
        return;
      } on Object catch (e) {
        if (attempt == 7) {
          _w('could not remove ${file.path}: $e');
          return;
        }
        await Future<void>.delayed(Duration(milliseconds: 25 * (attempt + 1)));
      }
    }
  }

  Future<bool> _lacksRoleForUser(
    String? userId,
    String workspaceId,
    WorkspaceRole floor,
  ) async {
    if (await _lacksMembershipForUser(userId, workspaceId)) {
      return true;
    }
    final roleResolver = resolveRole;
    if (roleResolver == null) {
      return false;
    }
    final role = await roleResolver(workspaceId, userId!);
    return role == null || !role.atLeast(floor);
  }
}
