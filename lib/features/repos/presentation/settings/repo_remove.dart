import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Asks, then removes [repo] from [workspaceId]: the row's Remove action, and
/// the fix a repository whose folder the server cannot use offers.
Future<void> confirmRemoveRepo(
  BuildContext context,
  WidgetRef ref, {
  required Repo repo,
  required String workspaceId,
}) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showCcDialog<bool>(
    context: context,
    builder: (ctx) => CcDialog(
      title: l10n.removeRepoFromWorkspace,
      content: Text(l10n.repoRemovedFromWorkspace(repo.name)),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(ctx, false),
          variant: CcButtonVariant.secondary,
          child: Text(AppLocalizations.of(context).cancel),
        ),
        CcButton(
          onPressed: () => Navigator.pop(ctx, true),
          variant: CcButtonVariant.destructive,
          child: Text(AppLocalizations.of(context).remove),
        ),
      ],
    ),
  );
  if (confirmed != true) {
    return;
  }

  await ref
      .read(workspaceRepositoryProvider)
      .unlinkRepoFromWorkspace(workspaceId, repo.id);
  await ref.read(repoRepositoryProvider).delete(workspaceId, repo.id);
}
