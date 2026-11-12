import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/import_hold_review.dart';
import 'package:cc_domain/core/domain/repositories/server_notice_repository.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The server owner's open notices, oldest first.
///
/// Empty without a call for anyone but the server owner: the op is
/// owner-only, and a refusal is not something to show anyone. Auto-disposed,
/// so opening the Backups page asks again; a restore invalidates it (see
/// `BackupActions.settleRestore`).
final serverNoticesProvider = FutureProvider.autoDispose<List<ServerNotice>>((
  ref,
) async {
  if (!ref.watch(isServerOwnerProvider)) {
    return const [];
  }
  return ref.watch(serverNoticeFeedProvider).open();
});

/// The grants a restore of a workspace held back, oldest first.
///
/// Empty without a call for anyone but the server owner. The server also
/// requires the owner role on the workspace, so a server owner who does not
/// own one gets a refusal here, which the section renders as nothing.
final importHoldsProvider = FutureProvider.autoDispose
    .family<List<ImportHoldView>, String>((ref, workspaceId) async {
      if (!ref.watch(isServerOwnerProvider)) {
        return const [];
      }
      return ref.watch(importHoldReviewProvider).list(workspaceId);
    });

/// One workspace's held grants as the Backups page shows them: the holds, or
/// the error that kept them from loading.
typedef HeldGrants = ({
  Workspace workspace,
  List<ImportHoldView> holds,
  Object? error,
});

/// Every workspace with grants waiting for the server owner, in workspace
/// order. Empty for anyone else.
///
/// A workspace whose list was refused (the server owner is not its owner) is
/// left out: those holds are not this person's to review. Any other failure
/// is kept, so a hold that could not be read is not mistaken for none.
final heldGrantsProvider = Provider.autoDispose<List<HeldGrants>>((ref) {
  if (!ref.watch(isServerOwnerProvider)) {
    return const [];
  }
  final workspaces = ref.watch(workspacesProvider).value ?? const <Workspace>[];
  final held = <HeldGrants>[];
  for (final workspace in workspaces) {
    switch (ref.watch(importHoldsProvider(workspace.id))) {
      case AsyncData(:final value) when value.isNotEmpty:
        held.add((workspace: workspace, holds: value, error: null));
      case AsyncError(:final error) when !_isRefusal(error):
        held.add((workspace: workspace, holds: const [], error: error));
      default:
        break;
    }
  }
  return held;
});

bool _isRefusal(Object error) =>
    error is RemoteRpcException && error.code == RpcErrorCodes.unauthorized;

/// Accepting and dismissing held grants.
final importHoldActionsProvider = Provider<ImportHoldActions>(
  ImportHoldActions.new,
);

/// Forwards the server owner's decision on a held grant.
class ImportHoldActions {
  /// Creates the actions bound to [_ref].
  ImportHoldActions(this._ref);

  final Ref _ref;

  /// Accepts ([accept] true) or dismisses [hold] of [workspaceId]. Returns
  /// whether a grant was applied; the list reloads either way.
  Future<bool> resolve({
    required String workspaceId,
    required ImportHoldView hold,
    required bool accept,
  }) async {
    try {
      return await _ref
          .read(importHoldReviewProvider)
          .resolve(workspaceId: workspaceId, holdId: hold.id, accept: accept);
    } finally {
      _ref.invalidate(importHoldsProvider(workspaceId));
    }
  }
}
