import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Shows a dialog for editing a repository's GitHub owner and name. Save
/// stays off until both are filled in.
Future<(String, String)?> showEditGitHubLinkDialog(
  BuildContext context, {
  required Repo repo,
}) {
  final ownerCtrl = TextEditingController(text: repo.remoteOwner);
  final repoNameCtrl = TextEditingController(text: repo.remoteName);
  final l10n = AppLocalizations.of(context);

  return showCcDialog<(String, String)?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.githubLink,
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.setGithubLinkDescription(repo.name),
              style: CcTypography.caption.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            CcTextField(
              controller: ownerCtrl,
              label: l10n.ownerOrganization,
              hintText: l10n.egSamuelAlev,
            ),
            const SizedBox(height: 12),
            CcTextField(
              controller: repoNameCtrl,
              label: l10n.repositoryName,
              hintText: l10n.egControlCenter,
            ),
          ],
        ),
      ),
      actions: [
        CcButton(
          onPressed: () => Navigator.pop(dialogContext),
          variant: CcButtonVariant.ghost,
          child: Text(AppLocalizations.of(context).cancel),
        ),
        // A linked repository keeps its forge remote: both halves or nothing
        // to save (the server refuses clearing either one).
        ListenableBuilder(
          listenable: Listenable.merge([ownerCtrl, repoNameCtrl]),
          builder: (_, _) {
            final owner = ownerCtrl.text.trim();
            final name = repoNameCtrl.text.trim();
            return CcButton(
              onPressed: owner.isEmpty || name.isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, (owner, name)),
              child: Text(AppLocalizations.of(context).save),
            );
          },
        ),
      ],
    ),
  );
}
