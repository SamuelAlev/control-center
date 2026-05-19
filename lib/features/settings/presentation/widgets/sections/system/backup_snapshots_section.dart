import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore: the whole-install snapshots.
///
/// `server.backupNow` has existed for as long as the database has been split,
/// and until now nothing in the app called it — the only trace a backup left
/// was an activity-log line after the fact. So this card does two things that
/// have to go together: it takes a snapshot, and it says which ones exist.
/// A button that writes a folder the operator cannot then find is not a backup
/// feature, it is a way to fill a disk.
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
  String? _downloading;
  ({int transferred, int? total})? _downloadProgress;

  Future<void> _backupNow() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _backingUp = true);
    try {
      final path = await ref.read(backupActionsProvider).backupNow();
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.backupSnapshotWritten(path), variant: CcToastVariant.success);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _backingUp = false);
      }
    }
  }

  /// Adopts one workspace file out of a snapshot.
  ///
  /// This IS `workspace.import` — the snapshot's per-workspace path is exactly
  /// what that op takes as its source — so restoring and importing cannot drift
  /// into two mechanisms that treat the same file differently.
  Future<void> _restore(
    BackupSnapshotWorkspaceView entry,
    String workspaceName,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.backupRestoreTitle,
      message: l10n.backupRestoreBody(workspaceName),
      confirmLabel: l10n.backupRestoreAction,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: workspaceName,
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() => _restoring = '${entry.workspaceId}:${entry.path}');
    try {
      await ref
          .read(backupActionsProvider)
          .importWorkspace(
            workspaceId: entry.workspaceId,
            sourcePath: entry.path,
          );
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        l10n.backupRestoreDone(workspaceName),
        variant: CcToastVariant.success,
      );
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(
        context,
      )?.show(l10n.failedWithError('$e'), variant: CcToastVariant.danger);
    } finally {
      if (mounted) {
        setState(() => _restoring = null);
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
      for (final w in ref.watch(workspacesProvider).value ?? const <Workspace>[])
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
              l10n.failedWithError('$error'),
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
                  _SnapshotRow(
                    snapshot: snapshot,
                    workspaceNames: workspaces,
                    expanded: _expanded.contains(snapshot.path),
                    restoringKey: _restoring,
                    downloading: _downloading == snapshot.path,
                    progress: _downloading == snapshot.path
                        ? _downloadProgress
                        : null,
                    canTransfer: canTransfer,
                    onDownload: _downloadSnapshot,
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

/// One snapshot: when it was taken, what it holds, and what can be restored.
class _SnapshotRow extends StatelessWidget {
  const _SnapshotRow({
    required this.snapshot,
    required this.workspaceNames,
    required this.expanded,
    required this.restoringKey,
    required this.downloading,
    required this.progress,
    required this.canTransfer,
    required this.onExpandedChanged,
    required this.onRestore,
    required this.onDownload,
  });

  final BackupSnapshotView snapshot;
  final Map<String, String> workspaceNames;
  final bool expanded;
  final String? restoringKey;
  final bool downloading;
  final ({int transferred, int? total})? progress;
  final bool canTransfer;
  final ValueChanged<bool> onExpandedChanged;
  final Future<void> Function(BackupSnapshotWorkspaceView, String) onRestore;
  final Future<void> Function(BackupSnapshotView) onDownload;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final createdAt = snapshot.createdAt;

    return SettingsEntityRow(
      title: snapshot.name,
      icon: AppIcons.archive,
      tone: snapshot.complete ? CcStatusTone.positive : CcStatusTone.caution,
      statusLabel: snapshot.complete
          ? l10n.backupSnapshotComplete
          : l10n.backupSnapshotIncomplete,
      subtitleWidget: createdAt == null
          ? null
          : AppTimestamp.relative(createdAt),
      meta: [
        SettingsMetaFact(value: humanBytes(snapshot.bytes)),
        SettingsMetaFact(
          value: l10n.backupSnapshotWorkspaces(snapshot.workspaces.length),
        ),
        if (snapshot.skippedWorkspaceIds.isNotEmpty)
          SettingsMetaFact(
            value: l10n.backupSnapshotSkipped(
              snapshot.skippedWorkspaceIds.length,
            ),
          ),
      ],
      expanded: expanded,
      onExpandedChanged: onExpandedChanged,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!snapshot.complete) ...[
            Text(
              l10n.backupSnapshotIncompleteNote,
              style: CcTypography.caption.copyWith(color: tokens.textWarningPrimary),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcButton(
              size: CcButtonSize.sm,
              icon: AppIcons.download,
              loading: downloading,
              onPressed: !canTransfer || downloading
                  ? null
                  : () => onDownload(snapshot),
              child: Text(l10n.backupDownloadAction),
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackupTransferProgressBar(
              transferred: progress!.transferred,
              total: progress!.total,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.backupServerPathLabel,
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          SettingsCopyField(value: snapshot.path),
          const SizedBox(height: AppSpacing.md),
          for (final entry in snapshot.workspaces)
            _SnapshotWorkspaceRow(
              entry: entry,
              // A snapshot outlives the registry: a workspace can be deleted,
              // or the whole file moved to another install. Naming the id and
              // refusing the restore beats an import that fails server-side
              // with "unknown workspace" after a type-to-confirm.
              name: workspaceNames[entry.workspaceId],
              busy: restoringKey == '${entry.workspaceId}:${entry.path}',
              onRestore: onRestore,
            ),
        ],
      ),
    );
  }
}

class _SnapshotWorkspaceRow extends StatelessWidget {
  const _SnapshotWorkspaceRow({
    required this.entry,
    required this.name,
    required this.busy,
    required this.onRestore,
  });

  final BackupSnapshotWorkspaceView entry;
  final String? name;
  final bool busy;
  final Future<void> Function(BackupSnapshotWorkspaceView, String) onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final known = name != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name ?? entry.workspaceId,
                  style: CcTypography.bodySm.copyWith(
                    color: known ? tokens.textPrimary : tokens.textTertiary,
                  ),
                ),
                Text(
                  known
                      ? humanBytes(entry.bytes)
                      : l10n.backupWorkspaceUnknown,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          CcButton(
            size: CcButtonSize.sm,
            variant: CcButtonVariant.secondary,
            loading: busy,
            onPressed: known && !busy ? () => onRestore(entry, name!) : null,
            child: Text(l10n.backupRestoreAction),
          ),
        ],
      ),
    );
  }
}
