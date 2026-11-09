import 'dart:async';

import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show needsSignInLane;
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart'
    show prEditProvider;
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
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
      workspaceId: ref.watch(githubSignInScopeProvider),
      bottomGap: 16,
    );
  }
}

/// Offers a sign-in when a pull request action was refused for want of the
/// reader's own sign-in; false for every other failure, which the caller
/// reports as before.
///
/// The lane is the one the server's refusal names. A refusal that names none
/// falls back to the sign-in lane of [prRef]'s forge — never to GitHub for a
/// GitLab or Bitbucket PR, whose credential is a token with no sign-in flow.
bool offerPrSignIn(
  BuildContext context,
  WidgetRef ref,
  Object error, {
  PrRef? prRef,
}) {
  final repo = prRef == null ? null : ref.read(prRepoRowProvider(prRef));
  final lane =
      needsSignInLane(error) ??
      (repo == null ? null : signInLaneForForge(repo.forge));
  if (lane == null) {
    return false;
  }
  return offerSignInForRefusal(
    context,
    error,
    lane: lane,
    workspaceId: ref.read(githubSignInScopeProvider),
  );
}

/// Reports a failed pull request action from a mounted [context]: a sign-in
/// offer when [error] was a refusal for want of the reader's own sign-in
/// (see [offerPrSignIn]), else a danger toast saying [message].
void showPrError(
  BuildContext context,
  WidgetRef ref,
  Object error,
  String Function(AppLocalizations l10n) message, {
  PrRef? prRef,
}) {
  if (!offerPrSignIn(context, ref, error, prRef: prRef)) {
    CcToastScope.of(context).show(
      message(AppLocalizations.of(context)),
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
    final lane = ref.read(prEditProvider(prRef)).refusedLane;
    if (next > (previous ?? 0) && lane != null && context.mounted) {
      unawaited(
        showSignInRequiredDialog(
          context,
          lane: lane,
          workspaceId: ref.read(githubSignInScopeProvider),
        ),
      );
    }
  });
}
