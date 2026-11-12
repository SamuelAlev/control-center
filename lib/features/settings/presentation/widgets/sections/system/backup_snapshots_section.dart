import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_restore_flow.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_snapshot_row.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/failure_message.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:control_center/shared/widgets/type_to_confirm_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore: take, inspect, download and delete
/// whole-install snapshots. Deletion is install-owner gated by the server.
class BackupSnapshotsSection extends ConsumerStatefulWidget {
  /// Creates a [BackupSnapshotsSection].
  const BackupSnapshotsSection({super.key});

  @override
  ConsumerState<BackupSnapshotsSection> createState() =>
      _BackupSnapshotsSectionState();
}

class _BackupSnapshotsSectionState
    extends ConsumerState<BackupSnapshotsSection> {
  bool _backingUp = false;
  final Set<String> _expanded = {};
  String? _restoring;
  ({String key, String message})? _restoreRefusal;
  String? _downloading;
  String? _deleting;
  ({int transferred, int? total})? _downloadProgress;

  Future<void> _backupNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _backingUp = true);
    try {
      final path = await ref.read(backupActionsProvider).backupNow();
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        l10n.backupSnapshotWritten(path),
        variant: CcToastVariant.success,
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(
        context,
      )?.show(failureMessage(l10n, e), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _backingUp = false);
      }
    }
  }

  Future<void> _restore(
    BackupSnapshotWorkspaceView entry,
    String workspaceName,
  ) {
    final key = '${entry.workspaceId}:${entry.path}';
    return restoreWorkspaceFromBackup(
      context,
      actions: ref.read(backupActionsProvider),
      entry: entry,
      workspaceName: workspaceName,
      onBusy: (busy) {
        if (mounted) {
          setState(() => _restoring = busy ? key : null);
        }
      },
      onRefused: (message) {
        if (mounted) {
          setState(
            () => _restoreRefusal = message == null
                ? null
                : (key: key, message: message),
          );
        }
      },
    );
  }

  Future<void> _deleteSnapshot(BackupSnapshotView snapshot) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.backupDeleteSnapshotTitle,
      message: l10n.backupDeleteSnapshotBody(snapshot.name),
      confirmLabel: l10n.backupDeleteSnapshotAction,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: snapshot.name,
      typeToConfirmLabels: appTypeToConfirmLabels(context),
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _deleting = snapshot.name);
    try {
      await ref.read(backupActionsProvider).deleteBackup(snapshot.name);
      if (!mounted) {
        return;
      }
      _expanded.remove(snapshot.path);
      CcToastScope.maybeOf(context)?.show(
        l10n.backupDeleteSnapshotDone(snapshot.name),
        variant: CcToastVariant.success,
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(
        context,
      )?.show(failureMessage(l10n, e), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _deleting = null);
      }
    }
  }

  /// Downloads a whole snapshot as one archive.
  ///
  /// The server zips it on the way out: a snapshot is a directory and a
  /// response carries one body, so this is the only way "download the backup"
  /// means the backup rather than its pieces.
  Future<void> _downloadSnapshot(BackupSnapshotView snapshot) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _downloading = snapshot.path);
    try {
      final result = await ref
          .read(backupTransferProvider)
          .downloadSnapshot(
            name: snapshot.name,
            onProgress: (transferred, total) {
              if (mounted) {
                setState(
                  () => _downloadProgress = (
                    transferred: transferred,
                    total: total,
                  ),
                );
              }
            },
          );
      if (mounted) {
        reportBackupDownload(context, result);
      }
    } on Object catch (e) {
      if (mounted) {
        CcToastScope.maybeOf(context)?.show(
          describeBackupTransferError(l10n, e),
          variant: CcToastVariant.danger,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _downloading = null;
          // Cleared with the transfer: a bar left at 100% under a ready button
          // reads as a transfer still running.
          _downloadProgress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final snapshots = ref.watch(backupSnapshotsProvider);
    final canTransfer = ref.watch(backupTransferAvailableProvider);
    final workspaces = {
      for (final w
          in ref.watch(workspacesProvider).value ?? const <Workspace>[])
        w.id: w.name,
    };

    return SectionCard(
      label: l10n.backupSnapshotsLabel,
      trailing: CcButton(
        size: CcButtonSize.sm,
        icon: AppIcons.archive,
        loading: _backingUp,
        onPressed: _backingUp ? null : _backupNow,
        child: Text(l10n.backupNowAction),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.backupSnapshotsExplainer,
            style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          switch (snapshots) {
            AsyncError(:final error) => Text(
              failureMessage(l10n, error),
              style: CcTypography.bodySm.copyWith(
                color: tokens.textErrorPrimary,
              ),
            ),
            AsyncData(:final value) when value.isEmpty => Text(
              l10n.backupNoSnapshots,
              style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
            ),
            AsyncData(:final value) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final snapshot in value)
                  BackupSnapshotRow(
                    snapshot: snapshot,
                    workspaceNames: workspaces,
                    expanded: _expanded.contains(snapshot.path),
                    restoringKey: _restoring,
                    refusal: _restoreRefusal,
                    downloading: _downloading == snapshot.path,
                    deleting: _deleting == snapshot.name,
                    progress: _downloading == snapshot.path
                        ? _downloadProgress
                        : null,
                    canTransfer: canTransfer,
                    onDownload: _downloadSnapshot,
                    onDelete: _deleteSnapshot,
                    onExpandedChanged: (open) => setState(() {
                      if (open) {
                        _expanded.add(snapshot.path);
                      } else {
                        _expanded.remove(snapshot.path);
                      }
                    }),
                    onRestore: _restore,
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
