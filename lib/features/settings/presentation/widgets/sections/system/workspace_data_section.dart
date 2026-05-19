import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_data_row.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore: exporting, importing and deleting one
/// workspace.
///
/// Server-scoped rather than workspace-scoped on purpose. Each action is about
/// a workspace, but the question they answer — "what data does this install
/// hold and how do I move it?" — is about the install, and hanging export next
/// to the workspace's own settings would mean the operator visits five pages to
/// take five files. Every action is still gated per workspace server-side
/// (admin to export, owner to import or delete), so the page listing them all
/// widens nothing.
class WorkspaceDataSection extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceDataSection].
  const WorkspaceDataSection({super.key});

  @override
  ConsumerState<WorkspaceDataSection> createState() =>
      _WorkspaceDataSectionState();
}

class _WorkspaceDataSectionState extends ConsumerState<WorkspaceDataSection> {
  /// The workspace whose actions are open, if any. One at a time: these are
  /// three destructive controls per row, and two rows open at once is how the
  /// wrong "Delete workspace" gets pressed.
  String? _open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaces = ref.watch(workspacesProvider);

    return SectionCard(
      label: l10n.backupWorkspaceDataLabel,
      count: workspaces.value?.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.backupWorkspaceDataExplainer,
            style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          switch (workspaces) {
            AsyncError(:final error) => Text(
              l10n.failedWithError('$error'),
              style: CcTypography.bodySm.copyWith(
                color: tokens.textErrorPrimary,
              ),
            ),
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final workspace in value)
                  WorkspaceDataRow(
                    key: ValueKey(workspace.id),
                    workspace: workspace,
                    expanded: _open == workspace.id,
                    onExpandedChanged: (open) =>
                        setState(() => _open = open ? workspace.id : null),
                  ),
              ],
            ),
            _ => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: Center(child: CcSpinner(size: 16)),
            ),
          },
        ],
      ),
    );
  }
}
