import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// The name + description a team was created or edited with.
typedef TeamFormResult = ({String name, String? description});

/// Shows the create/edit dialog for a team's name and description.
///
/// When [initialName] is non-null the dialog is in **edit** mode (title and
/// confirm label change accordingly); otherwise it creates a new team. Returns
/// `null` when dismissed, or the trimmed [TeamFormResult] on confirm.
Future<TeamFormResult?> showTeamFormDialog(
  BuildContext context, {
  String? initialName,
  String? initialDescription,
}) {
  final isEditing = initialName != null;
  final nameCtrl = TextEditingController(text: initialName ?? '');
  final descCtrl = TextEditingController(text: initialDescription ?? '');

  return showCcDialog<TeamFormResult>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext);
      final tokens = dialogContext.designSystem;

      void submit() {
        final name = nameCtrl.text.trim();
        if (name.isEmpty) {
          return;
        }
        final desc = descCtrl.text.trim();
        Navigator.pop(dialogContext, (
          name: name,
          description: desc.isEmpty ? null : desc,
        ));
      }

      return CcDialog(
        title: isEditing ? l10n.teamEditTitle : l10n.teamCreateTitle,
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.teamNameLabel,
                style: CcTypography.caption.copyWith(
                  color: tokens?.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              CcTextField(
                controller: nameCtrl,
                autofocus: true,
                hintText: l10n.teamNameHint,
                onSubmitted: (_) => submit(),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.teamDescriptionLabel,
                style: CcTypography.caption.copyWith(
                  color: tokens?.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              CcTextArea(
                controller: descCtrl,
                hintText: l10n.teamDescriptionHint,
                minLines: 2,
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(dialogContext),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: submit,
            child: Text(isEditing ? l10n.save : l10n.create),
          ),
        ],
      );
    },
  );
}
