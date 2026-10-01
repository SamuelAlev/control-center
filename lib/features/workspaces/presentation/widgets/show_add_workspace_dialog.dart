import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Shows the add-workspace dialog, its name field starting at [initialName].
///
/// Returns the new workspace id when one is created, or null when cancelled.
Future<String?> showAddWorkspaceDialog(
  BuildContext context, {
  String? initialName,
}) {
  final l10n = AppLocalizations.of(context);
  return showCcDialog<String?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addWorkspace,
      content: SizedBox(
        width: 420,
        child: AddWorkspaceForm(
          initialName: initialName,
          onCreated: (id) => Navigator.pop(dialogContext, id),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
    ),
  );
}
