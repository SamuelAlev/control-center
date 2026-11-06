import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_backups_row.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore: what each workspace's backup pipeline
/// has saved.
///
/// One row per workspace, because the question this card answers is "is this
/// workspace being backed up?": the collapsed row says when it last was. Every
/// list is gated per workspace server-side, the same as export.
class WorkspaceBackupsSection extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceBackupsSection].
  const WorkspaceBackupsSection({super.key});

  @override
  ConsumerState<WorkspaceBackupsSection> createState() =>
      _WorkspaceBackupsSectionState();
}

class _WorkspaceBackupsSectionState
    extends ConsumerState<WorkspaceBackupsSection> {
  String? _open;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaces = ref.watch(workspacesProvider);

    return SectionCard(
      label: l10n.backupScheduledLabel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.backupScheduledExplainer,
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
                  _LiveWorkspaceRow(
                    key: ValueKey(workspace.id),
                    workspace: workspace,
                    expanded: _open == workspace.id,
                    onExpandedChanged: (open) =>
                        setState(() => _open = open ? workspace.id : null),
                  ),
                _DeletedWorkspaceRows(
                  open: _open,
                  onExpandedChanged: (id, {required open}) =>
                      setState(() => _open = open ? id : null),
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

class _LiveWorkspaceRow extends ConsumerWidget {
  const _LiveWorkspaceRow({
    super.key,
    required this.workspace,
    required this.expanded,
    required this.onExpandedChanged,
  });

  final Workspace workspace;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return switch (ref.watch(workspaceBackupsProvider(workspace.id))) {
      AsyncData(:final value) when value.isEmpty => SettingsEntityRow(
        title: workspace.name,
        icon: AppIcons.archive,
        tone: CcStatusTone.neutral,
        statusLabel: l10n.backupScheduledNone,
      ),
      AsyncData(:final value) => WorkspaceBackupsRow(
        workspaceId: workspace.id,
        workspaceName: workspace.name,
        backups: value,
        expanded: expanded,
        onExpandedChanged: onExpandedChanged,
      ),
      AsyncError(:final error) => SettingsEntityRow(
        title: workspace.name,
        icon: AppIcons.archive,
        subtitleWidget: Text(
          describeBackupListError(l10n, error),
          style: CcTypography.caption.copyWith(
            // A role this reader lacks is a fact about them, not a failure.
            color: isBackupRefusal(error)
                ? tokens.textTertiary
                : tokens.textErrorPrimary,
          ),
        ),
      ),
      _ => SettingsEntityRow(
        title: workspace.name,
        icon: AppIcons.archive,
        trailing: const CcSpinner(size: 16),
      ),
    };
  }
}

/// Backups whose workspace is gone. Install-owner only, so a refusal renders
/// nothing: for anyone else this list is simply not theirs to see.
class _DeletedWorkspaceRows extends ConsumerWidget {
  const _DeletedWorkspaceRows({
    required this.open,
    required this.onExpandedChanged,
  });

  final String? open;
  final void Function(String workspaceId, {required bool open})
  onExpandedChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return switch (ref.watch(orphanedWorkspaceBackupsProvider)) {
      AsyncData(:final value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final orphan in value)
            WorkspaceBackupsRow(
              key: ValueKey(orphan.workspaceId),
              workspaceId: orphan.workspaceId,
              workspaceName: orphan.workspaceName ?? orphan.workspaceId,
              backups: orphan.backups,
              workspaceDeleted: true,
              expanded: open == orphan.workspaceId,
              onExpandedChanged: (opened) =>
                  onExpandedChanged(orphan.workspaceId, open: opened),
            ),
        ],
      ),
      AsyncError(:final error) when !isBackupRefusal(error) => Text(
        describeBackupTransferError(l10n, error),
        style: CcTypography.bodySm.copyWith(color: tokens.textErrorPrimary),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}
