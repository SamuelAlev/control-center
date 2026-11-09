import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
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
/// Never completes with an error: an unreachable server resolves to an empty
/// map, which every row renders as "sign-in unavailable" rather than as a
/// broken card.
final oauthLanesProvider =
    FutureProvider.family<Map<ConnectOAuthLane, SignInLaneInfo>, String?>((
      ref,
      workspaceId,
    ) async {
      try {
        final lanes = await ref
            .watch(providerSignInRepositoryProvider)
            .lanes(workspaceId: workspaceId);
        return {for (final lane in lanes) lane.lane: lane};
      } on Object {
        return const {};
      }
    });

/// The caller's own grants (GitHub, Linear) in a scope, plus that
/// workspace's grants (the Linear app actor, Slack) when it is a workspace.
///
/// Re-reads whenever any sign-in in this app succeeds, so a grant that lands
/// after its dialog was closed still shows up. Never completes with an error.
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
      try {
        final list = await ref
            .watch(providerSignInRepositoryProvider)
            .connections(workspaceId: workspaceId);
        return {for (final c in list) c.lane: c};
      } on Object {
        return const {};
      }
    });

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
/// person has no usable grant of their own for the provider.
const String kNeedsSignInKind = 'needs_sign_in';

/// The lane an interactive action needs a sign-in for, when [error] is the
/// server refusing it with `needs_sign_in`; null for every other failure.
///
/// The refusal arrives as [RpcErrorCodes.unauthorized] with
/// `data: {kind: 'needs_sign_in', lane: '<lane>'}`. A refusal that names no
/// lane falls back to [fallback] — the provider the action was about — so a
/// GitHub merge still offers "Sign in to GitHub".
ConnectOAuthLane? needsSignInLane(Object? error, {ConnectOAuthLane? fallback}) {
  if (error is! RemoteRpcException ||
      error.code != RpcErrorCodes.unauthorized) {
    return null;
  }
  final data = error.data;
  if (data is! Map || data['kind'] != kNeedsSignInKind) {
    return null;
  }
  return ConnectOAuthLane.fromWire(data['lane'] as String?) ?? fallback;
}
