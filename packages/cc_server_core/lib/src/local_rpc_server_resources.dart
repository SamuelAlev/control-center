part of 'local_rpc_server.dart';

extension _SecureResourceMethods on LocalRpcServer {
  Future<void> _handleSealedResource(
    HttpRequest request,
    SecureResourcePrincipal principal,
    RemoteResourceRequest transfer,
  ) async {
    _resourceTransfers[request] = transfer;
    try {
      final device = await _activeDevice(principal.deviceId);
      if (device == null || device.userId != principal.userId) {
        await _closeProxy(request.response, HttpStatus.forbidden);
        return;
      }
      final uri = request.uri;
      if (uri.path.startsWith('/proxy/vscode/')) {
        final parts = uri.pathSegments;
        final session = parts.length >= 3
            ? codeServerLookup?.call(parts[2])
            : null;
        if (session == null ||
            session.deviceId != principal.deviceId ||
            !session.expiresAt.isAfter(DateTime.now()) ||
            await _lacksMembershipForUser(
              principal.userId,
              session.workspaceId,
            )) {
          await _closeProxy(request.response, HttpStatus.forbidden);
          return;
        }
      } else {
        // Signed URLs are not transferable to another device's Noise session,
        // even when both devices belong to the same user.
        final deviceIds = uri.queryParametersAll['d'];
        if (deviceIds == null ||
            deviceIds.length != 1 ||
            deviceIds.single != principal.deviceId) {
          await _closeProxy(request.response, HttpStatus.forbidden);
          return;
        }
      }
      // Route handlers own signatures, workspace membership and operation
      // roles. Query names are route-specific: media `w` means resize width,
      // not the workspace identifier used by some other resources.
      await _handleGuarded(request, sealedResource: true);
    } finally {
      _resourceTransfers[request] = null;
    }
  }

  /// Stops even an idle producer when the authenticated resource is canceled.
  /// Socket write failures alone cannot detach a source that has gone quiet.
  Stream<List<int>> _withResourceCancellation(
    HttpRequest request,
    Stream<List<int>> source,
  ) {
    final transfer = _resourceTransfers[request];
    if (transfer == null) {
      return source;
    }
    return Stream<List<int>>.multi((output) {
      final subscription = source.listen(
        output.addSync,
        onError: output.addErrorSync,
        onDone: output.closeSync,
      );
      output
        ..onPause = subscription.pause
        ..onResume = subscription.resume
        ..onCancel = subscription.cancel;
      unawaited(
        transfer.cancelled.then((_) async {
          if (!transfer.isCancelled) {
            return;
          }
          try {
            await subscription.cancel();
          } catch (error, stack) {
            output.addErrorSync(error, stack);
          } finally {
            output.closeSync();
          }
        }),
      );
    });
  }

  Future<void> _handleEditorBridge(
    HttpRequest request,
    String instanceId,
    bool commands,
  ) async {
    if (codeServerBridgeAllowed?.call(instanceId) != true) {
      await _closeProxy(request.response, HttpStatus.forbidden);
      return;
    }
    if (commands) {
      await _handleCodeServerCommandStream(request.response, instanceId);
    } else {
      await _handleCodeServerOpenReport(request, request.response, instanceId);
    }
  }
}
