import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// The caller's connection to every supported forge — the ONE model the
/// desktop and the phone both read "am I signed in, and as whom?" from.
///
/// `forge.listConnections` answers each forge's status (connected, not
/// connected, needs sign-in, paused, unreachable) and the scope of the
/// credential in effect; the server decides both. Never carries a token.
class RemoteForgeConnections {
  /// Creates a [RemoteForgeConnections] over [_client].
  RemoteForgeConnections(this._client);

  final RemoteRpcClient _client;

  /// The connections in effect in [workspaceId] (server-wide when null).
  ///
  /// Throws when the server could not answer: an unreachable host is not "no
  /// forge connected", and callers that treat it as one demote a signed-in
  /// person to signed-out.
  Future<List<ForgeConnection>> list({String? workspaceId}) async {
    final data = await _client.call('forge.listConnections', {
      if (workspaceId != null && workspaceId.isNotEmpty)
        'workspace_id': workspaceId,
    });
    final raw = data['connections'];
    if (raw is! List) {
      throw const FormatException('forge.listConnections: no connections');
    }
    return [
      for (final c in raw.whereType<Map<Object?, Object?>>())
        ForgeConnection.fromJson(c.cast<String, dynamic>()),
    ];
  }

  /// The lower-cased login per connected forge (absent = not connected), for
  /// every "is this mine?" test.
  static Map<ForgeHost, String> viewerLogins(
    Iterable<ForgeConnection> connections,
  ) => {
    for (final c in connections)
      if (c.isUsable && c.username.isNotEmpty)
        c.forge: c.username.toLowerCase(),
  };
}
