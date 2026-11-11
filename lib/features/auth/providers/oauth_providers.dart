import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/features/auth/providers/provider_sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pins an unscoped forge/oauth op to the current workspace overlay.
Map<String, dynamic> overlayWorkspaceArgs(String? workspaceId) =>
    workspaceId == null || workspaceId.isEmpty
    ? const <String, dynamic>{}
    : <String, dynamic>{'workspace_id': workspaceId};

/// Who runs each lane's sign-in in a scope (`null` = server-wide), as
/// `oauth.lanes` reports it.
///
/// Completes with the server's error when it cannot answer, so a card can
/// tell an unreachable server from a lane with nothing set up (the contract
/// `RemoteForgeConnections.list` keeps too).
final oauthLanesProvider =
    FutureProvider.family<Map<ConnectOAuthLane, SignInLaneInfo>, String?>((
      ref,
      workspaceId,
    ) async {
      final lanes = await ref
          .watch(providerSignInRepositoryProvider)
          .lanes(workspaceId: workspaceId);
      return {for (final lane in lanes) lane.lane: lane};
    });

/// The caller's own grants (GitHub, Linear) in a scope, plus that
/// workspace's grants (the Linear app actor, Slack) when it is a workspace.
///
/// Re-reads whenever any sign-in in this app succeeds, so a grant that lands
/// after its dialog was closed still shows up. Completes with the server's
/// error when it cannot answer: an unreachable server is not "not
/// connected".
final oauthConnectionsProvider =
    FutureProvider.family<Map<ConnectOAuthLane, ProviderConnection>, String?>((
      ref,
      workspaceId,
    ) async {
      ref.watch(
        providerSignInControllerProvider.select(
          (s) => s.successes.values.fold(0, (a, b) => a + b),
        ),
      );
      final list = await ref
          .watch(providerSignInRepositoryProvider)
          .connections(workspaceId: workspaceId);
      return {for (final c in list) c.lane: c};
    });

/// Whether [connection]'s grant is kept for one workspace only (that
/// workspace signs in through its own app or its own Connect) rather than
/// following the person into every workspace on this server. With no grant,
/// where a sign-in from that workspace would land.
bool isWorkspaceOnlyGrant(ProviderConnection connection) =>
    connection.slot == SignInSlot.workspace;

/// Revokes [lane]'s grant in [workspaceId]'s scope and refreshes the
/// connection list.
Future<void> disconnectProviderLane(
  WidgetRef ref,
  ConnectOAuthLane lane, {
  String? workspaceId,
}) async {
  await ref
      .read(providerSignInRepositoryProvider)
      .disconnect(lane, workspaceId: workspaceId);
  ref.invalidate(oauthConnectionsProvider);
}

/// The `data.kind` an interactive action's RPC error carries when the acting
/// person has no usable credential of their own for the provider.
const String kNeedsSignInKind = 'needs_sign_in';

/// What a person has to do before an action refused with `needs_sign_in`
/// can run: sign in through a browser lane, or paste a token for a
/// token-only forge (GitLab, Bitbucket).
sealed class SignInNeed {
  const SignInNeed();

  /// The need for [forge]: its sign-in lane, or its token when it has none.
  factory SignInNeed.forForge(ForgeHost forge) {
    final lane = ConnectOAuthLane.fromWire(forge.wire);
    return lane == null ? TokenSignInNeed(forge) : LaneSignInNeed(lane);
  }
}

/// Sign in to [lane] through the browser.
final class LaneSignInNeed extends SignInNeed {
  /// Creates a [LaneSignInNeed].
  const LaneSignInNeed(this.lane);

  /// The lane to sign in to.
  final ConnectOAuthLane lane;

  @override
  bool operator ==(Object other) =>
      other is LaneSignInNeed && other.lane == lane;

  @override
  int get hashCode => lane.hashCode;
}

/// Paste a token for [forge], which has no browser sign-in.
final class TokenSignInNeed extends SignInNeed {
  /// Creates a [TokenSignInNeed].
  const TokenSignInNeed(this.forge);

  /// The token-only forge.
  final ForgeHost forge;

  @override
  bool operator ==(Object other) =>
      other is TokenSignInNeed && other.forge == forge;

  @override
  int get hashCode => forge.hashCode;
}

/// What [error] asks of the person when it is the server refusing an action
/// with `needs_sign_in`; null for every other failure.
///
/// The refusal arrives as [RpcErrorCodes.unauthorized] with
/// `data: {kind: 'needs_sign_in', lane: '<lane>'}`, where the lane is a
/// browser sign-in lane (`github`, `linear`, `google`) or a token-only forge
/// (`gitlab`, `bitbucket`). A refusal that names neither falls back to
/// [fallback] — the provider the action was about — so a GitHub merge still
/// offers "Sign in to GitHub".
SignInNeed? needsSignIn(Object? error, {SignInNeed? fallback}) {
  if (error is! RemoteRpcException ||
      error.code != RpcErrorCodes.unauthorized) {
    return null;
  }
  final data = error.data;
  if (data is! Map || data['kind'] != kNeedsSignInKind) {
    return null;
  }
  final wire = data['lane'];
  final lane = ConnectOAuthLane.fromWire(wire as String?);
  if (lane != null) {
    return LaneSignInNeed(lane);
  }
  for (final forge in ForgeHost.supported) {
    if (forge.wire == wire) {
      return SignInNeed.forForge(forge);
    }
  }
  return fallback;
}
