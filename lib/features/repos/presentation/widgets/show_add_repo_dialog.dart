import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/presentation/widgets/sign_in_prompts.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart'
    show LaneSignInNeed, needsSignIn;
import 'package:control_center/features/repos/presentation/widgets/add_repo_dialog.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_access_warnings_dialog.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The add-repo entry point on every platform: shows the server-filesystem
/// browser dialog and returns the batch outcome, or null when cancelled.
///
/// The browse + register dependencies are read from [ref] HERE (under the app's
/// `ProviderScope`) and handed to the dialog, because the dialog itself is
/// mounted in the root overlay above that scope and so cannot read providers.
/// [workspaceId] names the workspace the repos are registered into — repos are
/// workspace-scoped, so it is threaded all the way to the register call rather
/// than resolved from an ambient "active workspace".
Future<RepoAddOutcome?> addRepos(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) => showAddRepoDialog(
  context,
  browser: ref.read(directoryBrowserProvider),
  register: ref.read(addRepoFromServerPathProvider),
  workspaceId: workspaceId,
);

/// [addRepos] for a caller holding the dependencies rather than a [WidgetRef]
/// (a deep link resolved outside the widget tree), with an optional [intro]
/// replacing the generic instructions.
Future<RepoAddOutcome?> showAddRepoDialog(
  BuildContext context, {
  required DirectoryBrowserPort browser,
  required Future<RepoRegistration> Function(String workspaceId, String path)
  register,
  required String workspaceId,
  String? intro,
}) {
  final l10n = AppLocalizations.of(context);
  return showCcDialog<RepoAddOutcome?>(
    context: context,
    presentation: CcDialogPresentation.immediate,
    builder: (dialogContext) => CcDialog(
      title: l10n.addRepository,
      content: SizedBox(
        width: 460,
        child: AddRepoDialog(
          browser: browser,
          register: register,
          workspaceId: workspaceId,
          intro: intro,
          onDone: (outcome) => Navigator.pop(dialogContext, outcome),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}

/// Runs [addRepos] for [workspaceId] and reports its outcome: a toast for
/// what was added and what failed, a sign-in offer when a failure is a
/// missing forge sign-in, then any access warnings for automation.
Future<void> addReposAndReport(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) async {
  // One dialog on every platform: it browses the SERVER's filesystem (the
  // desktop is a thin client — the checkout lives wherever cc_server runs),
  // registers the selected checkouts directly into this workspace and
  // returns the batch outcome to report here.
  final outcome = await addRepos(context, ref, workspaceId);
  if (outcome == null || !context.mounted) {
    return;
  }
  final toasts = CcToastScope.maybeOf(context);
  if (toasts == null) {
    return;
  }
  final l10n = AppLocalizations.of(context);
  if (outcome.added.isNotEmpty) {
    toasts.show(
      l10n.repositoriesAdded(outcome.added.length),
      variant: CcToastVariant.success,
    );
  }
  if (outcome.failed.isNotEmpty) {
    // Not signed in to the repo's forge: the sign-in fixes it, so offer
    // that instead of a bare error.
    final refusal = outcome.failed.values
        .where((e) => needsSignIn(e) != null)
        .firstOrNull;
    if (refusal != null) {
      offerSignInForRefusal(
        context,
        refusal,
        fallback: const LaneSignInNeed(ConnectOAuthLane.github),
        workspaceId: workspaceId,
      );
    }
    final first = outcome.failed.entries.first;
    toasts.show(
      l10n.repositoriesAddFailed(
        outcome.failed.length,
        '${first.key}: ${describeRepoLinkError(l10n, first.value)}',
      ),
      variant: CcToastVariant.danger,
    );
  }
  await showRepoAccessWarnings(context, outcome.issues);
}
