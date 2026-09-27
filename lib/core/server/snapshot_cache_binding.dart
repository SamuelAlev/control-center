import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/storage/client_snapshot_store.dart';

/// Arms offline render snapshots only after a verified server handshake AND an
/// uncached, authenticated identity.me response. Device IDs and local boot
/// credentials are not human identities and must never select a cache scope.
///
/// A slow or inaccessible cache must not delay the live app: discard this
/// hydration on timeout rather than exposing data from an unhydrated scope.
Future<void> attachVerifiedSnapshotCache({
  required ResilientRpcClient client,
  required String serverId,
  required String fingerprint,
  required ServerConnectionSupervisor supervisor,
  bool persist = true,
}) async {
  if (serverId.isEmpty || fingerprint.isEmpty) {
    return;
  }
  final Map<String, dynamic> identity;
  try {
    identity = await client.call('identity.me', const {});
  } on RemoteRpcException catch (error) {
    if (error.code == RpcErrorCodes.unauthorized ||
        error.code == RpcErrorCodes.notFound) {
      await forgetSnapshotServer(serverId);
    }
    return;
  } on Object {
    // A failed identity lookup must never select a previously saved user.
    return;
  }
  final user = identity['user'];
  final userId = user is Map ? user['id'] : null;
  if (userId is! String || userId.isEmpty) {
    return;
  }
  final memberships = identity['memberships'];
  if (memberships is! List) {
    return;
  }
  final allowedWorkspaces = <String>{
    for (final member in memberships)
      if (member is Map && member['workspace_id'] is String)
        member['workspace_id'] as String,
  };

  try {
    final store = persist
        ? await snapshotStoreFor(
            serverId: serverId,
            fingerprint: fingerprint,
            userId: userId,
          )
        : null;
    var cache = RpcSnapshotCache(store: store, maxBytes: snapshotCacheMaxBytes);
    try {
      await cache.hydrate().timeout(const Duration(milliseconds: 300));
    } on TimeoutException {
      // Discard the late load, not the live cache: a slow disk/browser cannot
      // hold network data behind its hydration, yet fresh reads still persist.
      cache = RpcSnapshotCache(store: store, maxBytes: snapshotCacheMaxBytes);
    }
    cache.retainWorkspaces(allowedWorkspaces);
    if (supervisor.current.phase == ServerConnectionPhase.identityMismatch ||
        supervisor.current.authenticationRejected) {
      cache.clear();
      await cache.flush();
      if (supervisor.current.authenticationRejected) {
        await forgetSnapshotServer(serverId);
      }
      return;
    }
    client.setSnapshotCache(cache);
    late final StreamSubscription<ServerConnectionStatus> statusSubscription;
    statusSubscription = supervisor.status.listen((status) {
      if (status.phase == ServerConnectionPhase.identityMismatch ||
          status.authenticationRejected) {
        client.setSnapshotCache(null);
        cache.clear();
        final flushed = cache.flush();
        if (status.authenticationRejected) {
          unawaited(flushed.then((_) => forgetSnapshotServer(serverId)));
        } else {
          unawaited(flushed);
        }
        unawaited(statusSubscription.cancel());
      } else if (status.phase == ServerConnectionPhase.closed) {
        unawaited(statusSubscription.cancel());
      }
    });
  } on Object {
    // File permissions, corrupted JSON, and disabled browser storage must not
    // block authenticated live reads or expose another user's snapshots.
  }
}
