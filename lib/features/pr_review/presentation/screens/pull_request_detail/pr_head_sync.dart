import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show SignInNeed;
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/features/messaging/providers/worktree_file_ops_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pulls the latest PR commits into a PR space's worktree
/// (`worktree.syncToPrHead`) and says how it went; true when the tree
/// advanced.
///
/// Skips with a warning when the tree has uncommitted edits. The fetch runs
/// on the person's own GitHub sign-in, so a `needs_sign_in` refusal offers
/// that sign-in instead of a failed sync.
Future<bool> syncPrWorktreeToHead(
  BuildContext context,
  WidgetRef ref, {
  required String workspaceId,
  required String spaceId,
  required String repoId,
}) async {
  final l10n = AppLocalizations.of(context);
  final PrWorktreeSyncOutcome? res;
  try {
    res = await syncWorktreeToPrHead(
      ref.read(rpcClientProvider),
      workspaceId: workspaceId,
      spaceId: spaceId,
      repoId: repoId,
    );
  } on Object catch (e) {
    // Only refusals are rethrown: a sign-in is offered, any other is worded.
    if (context.mounted &&
        !offerSignInForRefusal(
          context,
          e,
          fallback: SignInNeed.forForge(ForgeHost.github),
          workspaceId: workspaceId,
        )) {
      CcToastScope.maybeOf(context)?.show(
        repoRefusalOf(l10n, e) ?? l10n.syncPrHeadFailed,
        variant: CcToastVariant.danger,
      );
    }
    return false;
  }
  if (!context.mounted) {
    return false;
  }
  final toast = CcToastScope.maybeOf(context);
  if (res == null) {
    toast?.show(l10n.syncPrHeadFailed, variant: CcToastVariant.danger);
    return false;
  }
  if (res.dirty) {
    toast?.show(l10n.syncPrHeadDirty, variant: CcToastVariant.warning);
    return false;
  }
  if (!res.synced) {
    toast?.show(
      res.error ?? l10n.syncPrHeadFailed,
      variant: CcToastVariant.danger,
    );
    return false;
  }
  toast?.show(l10n.syncedToPrHead, variant: CcToastVariant.success);
  return true;
}
