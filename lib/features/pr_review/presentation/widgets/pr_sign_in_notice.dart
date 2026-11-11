import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show LaneSignInNeed, SignInNeed;
import 'package:control_center/features/forge/presentation/repo_code_refusal.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart'
    show prEditProvider;
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Sign in to GitHub" above a GitHub pull request, for a reader with no
/// GitHub sign-in of their own.
///
/// Merging, reviewing and commenting run as the person, never as the App, so
/// without a sign-in every one of them would be refused. Saying so up front
/// beats discovering it on the first click. Nothing renders for another
/// forge, for a signed-in reader, or where no GitHub sign-in is available.
class PrSignInNotice extends ConsumerWidget {
  /// Creates the notice for [prRef].
  const PrSignInNotice({super.key, required this.prRef});

  /// The pull request.
  final PrRef prRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(prRepoRowProvider(prRef));
    if (repo == null || repo.forge != ForgeHost.github) {
      return const SizedBox.shrink();
    }
    return SignInRequiredBanner(
      lane: ConnectOAuthLane.github,
      workspaceId: ref.watch(activeWorkspaceIdProvider),
      bottomGap: 16,
    );
  }
}

/// Offers a sign-in when a pull request action was refused for want of the
/// reader's own sign-in; false for every other failure, which the caller
/// reports as before.
///
/// The lane is the one the server's refusal names. A refusal that names none
/// falls back to [prRef]'s forge: its browser sign-in for GitHub, its token
/// dialog for GitLab or Bitbucket, which have no sign-in flow.
bool offerPrSignIn(
  BuildContext context,
  WidgetRef ref,
  Object error, {
  PrRef? prRef,
}) {
  final repo = prRef == null ? null : ref.read(prRepoRowProvider(prRef));
  final fallback = repo == null
      ? const LaneSignInNeed(ConnectOAuthLane.github)
      : SignInNeed.forForge(repo.forge);
  return offerSignInForRefusal(
    context,
    error,
    fallback: fallback,
    workspaceId: ref.read(activeWorkspaceIdProvider),
  );
}

/// What a refused pull request action says: the server's own words when it
/// refused the person (no access on the forge, approving a pull request an
/// agent opened at their request), else [message].
String prErrorMessage(
  AppLocalizations l10n,
  Object error,
  String Function(AppLocalizations l10n) message,
) {
  // The repository replaced on its forge (from any action: a review, a
  // merge, a comment) or unreadable by the person's own account, by kind.
  final refusal = repoCodeRefusalMessage(l10n, error);
  if (refusal != null) {
    return refusal;
  }
  if (error is RemoteRpcException &&
      error.message.isNotEmpty &&
      (error.code == RpcErrorCodes.unauthorized ||
          error.code == RpcErrorCodes.validation)) {
    return error.message;
  }
  return message(l10n);
}

/// Reports a failed pull request action from a mounted [context]: a sign-in
/// offer when [error] was a refusal for want of the reader's own sign-in
/// (see [offerPrSignIn]), else a danger toast saying [message] (or the
/// server's refusal, see [prErrorMessage]).
void showPrError(
  BuildContext context,
  WidgetRef ref,
  Object error,
  String Function(AppLocalizations l10n) message, {
  PrRef? prRef,
}) {
  if (!offerPrSignIn(context, ref, error, prRef: prRef)) {
    CcToastScope.of(context).show(
      prErrorMessage(AppLocalizations.of(context), error, message),
      variant: CcToastVariant.danger,
    );
  }
}

/// Offers a sign-in each time an edit to [prRef] (title, description, labels,
/// assignees, reviewers, comments) is refused for want of the reader's own
/// sign-in, the same way merging and reviewing do. Call from `build`.
void listenForPrEditSignIn(BuildContext context, WidgetRef ref, PrRef prRef) {
  ref.listen(prEditProvider(prRef).select((s) => s.signInRefusals), (
    previous,
    next,
  ) {
    final need = ref.read(prEditProvider(prRef)).refusedNeed;
    if (next > (previous ?? 0) && need != null && context.mounted) {
      unawaited(
        showSignInRequiredDialog(
          context,
          need: need,
          workspaceId: ref.read(activeWorkspaceIdProvider),
        ),
      );
    }
  });
}
