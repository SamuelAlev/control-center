import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/src/repositories/remote_provider_sign_in.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The caller's connection to every supported forge — the ONE model the
/// desktop and the phone both read "am I signed in, and as whom?" from.
///
/// `forge.listConnections` answers who the credential is; a forge with a
/// browser sign-in lane (GitHub) also reports, through `oauth.connections`,
/// whether that sign-in has lapsed. Folding the two here is what keeps
/// Settings from saying "Signed in as X" while the PR banner says "sign in
/// again". Never carries a token.
class RemoteForgeConnections {
  /// Creates a [RemoteForgeConnections] over [_client].
  RemoteForgeConnections(this._client);

  final RemoteRpcClient _client;

  /// The connections in [workspaceId]'s overlay (server-wide when null).
  ///
  /// Throws when the server could not answer: an unreachable host is not "no
  /// forge connected", and callers that treat it as one demote a signed-in
  /// person to signed-out. The lapse overlay is best-effort — failing it
  /// leaves the flags unset, never the list empty.
  Future<List<ForgeConnection>> list({String? workspaceId}) async {
    final data = await _client.call('forge.listConnections', {
      if (workspaceId != null && workspaceId.isNotEmpty)
        'workspace_id': workspaceId,
    });
    final raw = data['connections'];
    if (raw is! List) {
      throw const FormatException('forge.listConnections: no connections');
    }
    final connections = [
      for (final c in raw.whereType<Map<Object?, Object?>>())
        ForgeConnection.fromJson(c.cast<String, dynamic>()),
    ];
    final lapsed = await _lapsedLanes(workspaceId);
    if (lapsed.isEmpty) {
      return connections;
    }
    return [
      for (final c in connections)
        lapsed.contains(ConnectOAuthLane.fromWire(c.forge.wire))
            ? c.copyWith(needsSignIn: true)
            : c,
    ];
  }

  Future<Set<ConnectOAuthLane>> _lapsedLanes(String? workspaceId) async {
    try {
      final grants = await RemoteProviderSignIn(
        _client,
      ).connections(workspaceId: workspaceId);
      return {
        for (final g in grants)
          if (g.needsSignIn) g.lane,
      };
    } on Object {
      return const {};
    }
  }

  /// The lower-cased login per connected forge (absent = not connected), for
  /// every "is this mine?" test.
  static Map<ForgeHost, String> viewerLogins(
    Iterable<ForgeConnection> connections,
  ) => {
    for (final c in connections)
      if (c.authenticated && c.username.isNotEmpty)
        c.forge: c.username.toLowerCase(),
  };
}
