import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The connected server's build identity, as stamped on the RPC client by the
/// connection's own `initialize` handshake.
///
/// This MUST stay reactive. `RemoteRpcClient.serverBuild` is a mutable field
/// that is re-stamped on every reconnect/failover, while `rpcClientProvider`
/// is installed once via `overrideWithValue` and never changes identity — so a
/// plain `Provider` reading the field would compute exactly once, for the
/// lifetime of the app. Read before the first handshake completes (the normal
/// case: the About panel can be built mid-connect) it would cache `null`
/// forever and the panel would show "Not reported" permanently.
///
/// Watching the client's own `connectionState` stream fixes both: every
/// session transition re-reads the field. The stream is seeded with the
/// current value so a late subscriber (or a client with no supervisor, as in
/// tests) still gets an answer instead of hanging on [AsyncLoading].
final serverBuildStreamProvider = StreamProvider<ServerBuild?>((ref) {
  final client = ref.watch(rpcClientProvider);
  return Stream<ServerBuild?>.multi((controller) {
    controller.add(client.serverBuild);
    final sub = client.connectionState.listen(
      (_) => controller.add(client.serverBuild),
      onError: (Object _) => controller.add(client.serverBuild),
    );
    controller.onCancel = sub.cancel;
  });
});

/// The connected server's build identity, or null when no session has
/// completed its handshake (or the server advertises nothing). Recomputes on
/// every connection transition — see [serverBuildStreamProvider].
final serverBuildProvider = Provider<ServerBuild?>((ref) {
  return ref.watch(serverBuildStreamProvider).value;
});

/// Whether the connected server's build is older than this client's — the
/// stale-binary signal (a prebuilt `cc_server` bundled with an app that moved
/// ahead of it). Only meaningful against servers that advertise a version;
/// `null` means "cannot tell", which is never shown as a warning.
bool? serverOlderThanClient(ServerBuild? server) {
  final version = server?.version;
  if (version == null || version.isEmpty) {
    return null;
  }
  if (version == BuildInfo.buildVersion) {
    return false;
  }
  return _versionLess(version, BuildInfo.buildVersion);
}

/// Dotted-numeric comparison with semver pre-release handling: `1.2.0-beta`
/// sorts BEFORE `1.2.0`. Without the split, `int.tryParse('0-beta')` returns
/// null → 0, making a pre-release compare equal to its release and hiding a
/// genuine "your server is a build behind" warning.
bool _versionLess(String a, String b) {
  final (coreA, preA) = _splitPreRelease(a);
  final (coreB, preB) = _splitPreRelease(b);
  final pa = coreA.split('.').map(int.tryParse).toList();
  final pb = coreB.split('.').map(int.tryParse).toList();
  for (var i = 0; i < pa.length && i < pb.length; i++) {
    final x = pa[i] ?? 0;
    final y = pb[i] ?? 0;
    if (x != y) {
      return x < y;
    }
  }
  if (pa.length != pb.length) {
    return pa.length < pb.length;
  }
  // Same numeric core: a pre-release precedes the release it leads up to.
  if (preA == null && preB == null) {
    return false;
  }
  if (preA != null && preB == null) {
    return true;
  }
  if (preA == null && preB != null) {
    return false;
  }
  return preA!.compareTo(preB!) < 0;
}

/// Splits `1.2.0-beta.1+build` into (`1.2.0`, `beta.1`). Build metadata is
/// dropped: semver says it never affects precedence.
(String, String?) _splitPreRelease(String version) {
  final withoutBuild = version.split('+').first;
  final dash = withoutBuild.indexOf('-');
  if (dash < 0) {
    return (withoutBuild, null);
  }
  return (withoutBuild.substring(0, dash), withoutBuild.substring(dash + 1));
}
