import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/type_to_confirm_labels.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Picks a database file on THIS device and uploads it for the server to
/// adopt as [workspace]'s database. The server owner's
/// (`canRestoreBackups`); the caller shows it only to them.
///
/// A refused file is worded in place under the button, not in a toast: the
/// server answers `400 {error, kind}` and the kind says what is wrong with
/// the file (damaged, newer, not a workspace database), which the person
/// needs while choosing another one.
class WorkspaceUploadRestoreField extends ConsumerStatefulWidget {
  /// Creates the field for [workspace].
  const WorkspaceUploadRestoreField({super.key, required this.workspace});

  /// The workspace the file replaces.
  final Workspace workspace;

  /// Picks the file to upload. A seam: a test has no native open dialog.
  static Future<XFile?> Function() pickFile = _pickDatabase;

  static Future<XFile?> _pickDatabase() => openFile(
    acceptedTypeGroups: const [
      XTypeGroup(label: 'databases', extensions: ['db']),
    ],
  );

  @override
  ConsumerState<WorkspaceUploadRestoreField> createState() =>
      _WorkspaceUploadRestoreFieldState();
}

class _WorkspaceUploadRestoreFieldState
    extends ConsumerState<WorkspaceUploadRestoreField> {
  bool _uploading = false;
  ({int transferred, int? total})? _progress;
  String? _refusal;

  /// The confirmation comes before the upload, not after: the body is a whole
  /// workspace database, and asking "are you sure" once it has already
  /// crossed the network is asking too late.
  Future<void> _uploadAndRestore() async {
    final file = await WorkspaceUploadRestoreField.pickFile();
    if (file == null || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final workspaceId = widget.workspace.id;
    final name = widget.workspace.name;
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.backupImportTitle(name),
      message: l10n.backupImportBody(name),
      confirmLabel: l10n.backupImportAction,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: name,
      typeToConfirmLabels: appTypeToConfirmLabels(context),
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _uploading = true;
      _refusal = null;
    });
    try {
      await ref
          .read(backupTransferProvider)
          .restoreFromFile(
            workspaceId: workspaceId,
            file: file,
            onProgress: (transferred, total) {
              if (mounted) {
                setState(
                  () => _progress = (transferred: transferred, total: total),
                );
              }
            },
          );
      final held = await ref
          .read(backupActionsProvider)
          .settleRestore(workspaceId);
      if (mounted) {
        reportRestoreDone(
          context,
          done: l10n.backupImportDone(name),
          held: held,
        );
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() => _refusal = describeBackupTransferError(l10n, e));
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
          _progress = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canTransfer = ref.watch(backupTransferAvailableProvider);
    final progress = _progress;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SettingsField(
          label: l10n.backupRestoreFromDeviceLabel,
          description: l10n.backupRestoreFromDeviceDescription,
          centerControl: true,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              icon: AppIcons.upload,
              loading: _uploading,
              onPressed: !canTransfer || _uploading ? null : _uploadAndRestore,
              child: Text(l10n.backupUploadAction),
            ),
          ),
        ),
        if (progress != null) ...[
          const SizedBox(height: AppSpacing.sm),
          BackupTransferProgressBar(
            transferred: progress.transferred,
            total: progress.total,
          ),
        ],
        if (_refusal case final message?)
          BackupRestoreRefusal(message: message),
      ],
    );
  }
}
