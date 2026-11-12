import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/presentation/widgets/repo_access_banner.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:flutter/widgets.dart';

/// After linking repositories: what automation cannot reach in them yet, with
/// the same fixes the pull request views offer (install the GitHub App on
/// the owner, add the repository to its installation). Does nothing when
/// [issues] is empty.
///
/// The link itself succeeded, so this informs rather than asks: the only
/// action besides each fix is closing.
Future<void> showRepoAccessWarnings(
  BuildContext context,
  List<RepoAccessIssue> issues,
) async {
  if (issues.isEmpty || !context.mounted) {
    return;
  }
  await showCcDialog<void>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      return CcDialog(
        title: l10n.repoLinkAccessWarningsTitle,
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: RepoAccessBanner(issues: issues)),
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.close),
          ),
        ],
      );
    },
  );
}

/// A refused link or relink in words: a path the server refuses is
/// localized by its `data.kind` (`repo_path.*`), anything else is the
/// server's own sentence (the person's forge account cannot see the
/// repository, the checkout is not a repository), never the exception's type
/// name. Never matched by message text.
String describeRepoLinkError(AppLocalizations l10n, Object error) {
  if (error is! RemoteRpcException) {
    return '$error';
  }
  final data = error.data;
  final kind = data is Map ? data['kind'] : null;
  return switch (kind) {
    'repo_path.host_path' => l10n.repoPathHostPath,
    'repo_path.missing' => l10n.repoPathMissing,
    'repo_path.data_dir' => l10n.repoPathDataDir,
    'repo_path.workspace_root' => l10n.repoPathWorkspaceRoot,
    'repo_path.origin_mismatch' => l10n.repoPathOriginMismatch,
    'repo_link.forge_remote_required' => l10n.repoLinkForgeRemoteRequired,
    _ => storageRefusalMessage(l10n, error) ?? error.message,
  };
}
