import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/features/settings/providers/backup_transfer.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One workspace's data operations: export it, adopt a file into it, delete it.
///
/// All three are server-side by construction — the databases live with
/// `cc_server` and never leave it — so this row asks and reports, and every
/// path it shows is a path on the server's filesystem, not on this device.
class WorkspaceDataRow extends ConsumerStatefulWidget {
  /// Creates a [WorkspaceDataRow].
  const WorkspaceDataRow({
    super.key,
    required this.workspace,
    required this.expanded,
    required this.onExpandedChanged,
  });

  /// The workspace this row acts on.
  final Workspace workspace;

  /// Whether the detail (the three actions) is showing.
  final bool expanded;

  /// Fired when the header is activated.
  final ValueChanged<bool> onExpandedChanged;

  @override
  ConsumerState<WorkspaceDataRow> createState() => _WorkspaceDataRowState();
}

class _WorkspaceDataRowState extends ConsumerState<WorkspaceDataRow> {
  final TextEditingController _source = TextEditingController();
  bool _exporting = false;
  bool _downloading = false;
  bool _importing = false;
  bool _uploading = false;
  bool _deleting = false;
  String? _lastExportPath;
  ({int transferred, int? total})? _downloadProgress;
  ({int transferred, int? total})? _uploadProgress;

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
  }

  void _toast(String message, {required bool ok}) {
    if (!mounted) {
      return;
    }
    CcToastScope.maybeOf(context)?.show(
      message,
      variant: ok ? CcToastVariant.success : CcToastVariant.danger,
    );
  }

  /// Runs [action], reporting whatever it throws instead of swallowing it.
  ///
  /// Every one of these is role-gated server-side — export and download need
  /// admin on the workspace, restore needs owner — and both lanes enforce it
  /// separately, because the RPC gate never runs for an HTTP request. The
  /// refusals therefore arrive in two shapes: an RPC exception carrying the
  /// server's sentence, and an HTTP status carrying none. See
  /// [describeBackupTransferError] for how the second one gets its words.
  Future<void> _run(
    Future<void> Function() action,
    void Function({required bool busy}) setBusy,
  ) async {
    final l10n = AppLocalizations.of(context);
    setBusy(busy: true);
    try {
      await action();
    } on Object catch (e) {
      _toast(describeBackupTransferError(l10n, e), ok: false);
    } finally {
      if (mounted) {
        setBusy(busy: false);
      }
    }
  }

  Future<void> _export() => _run(() async {
    final l10n = AppLocalizations.of(context);
    final path = await ref
        .read(backupActionsProvider)
        .exportWorkspace(widget.workspace.id);
    if (!mounted) {
      return;
    }
    setState(() => _lastExportPath = path);
    _toast(l10n.backupExportDone(path), ok: true);
  }, ({required busy}) => setState(() => _exporting = busy));

  /// Downloads this workspace's database to a place the person picks.
  Future<void> _download() => _run(() async {
    final result = await ref
        .read(backupTransferProvider)
        .downloadWorkspace(
          workspaceId: widget.workspace.id,
          suggestedName: '${widget.workspace.id}.db',
          onProgress: (transferred, total) {
            if (mounted) {
              setState(
                () => _downloadProgress = (transferred: transferred, total: total),
              );
            }
          },
        );
    if (mounted) {
      reportBackupDownload(context, result);
    }
  }, ({required busy}) {
    setState(() {
      _downloading = busy;
      // Cleared when the transfer ends, so a finished bar does not sit at 100%
      // under a button that is ready to be pressed again.
      if (!busy) {
        _downloadProgress = null;
      }
    });
  });

  /// Picks a file on THIS device and uploads it for the server to adopt.
  ///
  /// The confirmation comes before the upload, not after: the body is a whole
  /// workspace database, and asking "are you sure" once it has already crossed
  /// the network is asking too late.
  Future<void> _uploadAndRestore() async {
    const typeGroup = XTypeGroup(label: 'databases', extensions: ['db']);
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final name = widget.workspace.name;
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.backupImportTitle(name),
      message: l10n.backupImportBody(name),
      confirmLabel: l10n.backupImportAction,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: name,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _run(() async {
      await ref
          .read(backupTransferProvider)
          .restoreFromFile(
            workspaceId: widget.workspace.id,
            file: file,
            onProgress: (transferred, total) {
              if (mounted) {
                setState(
                  () =>
                      _uploadProgress = (transferred: transferred, total: total),
                );
              }
            },
          );
      _toast(l10n.backupImportDone(name), ok: true);
    }, ({required busy}) {
      setState(() {
        _uploading = busy;
        if (!busy) {
          _uploadProgress = null;
        }
      });
    });
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    final name = widget.workspace.name;
    final source = _source.text.trim();
    if (source.isEmpty) {
      return;
    }
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.backupImportTitle(name),
      message: l10n.backupImportBody(name),
      confirmLabel: l10n.backupImportAction,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: name,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _run(() async {
      await ref
          .read(backupActionsProvider)
          .importWorkspace(
            workspaceId: widget.workspace.id,
            sourcePath: source,
          );
      _toast(l10n.backupImportDone(name), ok: true);
    }, ({required busy}) => setState(() => _importing = busy));
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final name = widget.workspace.name;
    final confirmed = await showCcConfirmDialog(
      context: context,
      title: l10n.deleteWorkspace,
      message: l10n.backupDeleteBody(name),
      confirmLabel: l10n.deleteWorkspace,
      cancelLabel: l10n.cancel,
      danger: true,
      typeToConfirm: name,
    );
    if (!confirmed || !mounted) {
      return;
    }
    await _run(
      () => ref.read(backupActionsProvider).deleteWorkspace(widget.workspace.id),
      ({required busy}) => setState(() => _deleting = busy),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // Files move over the server's HTTP lane, which a relayed connection does
    // not have. Disabled with a reason beats a button that cannot work.
    final canTransfer = ref.watch(backupTransferAvailableProvider);

    return SettingsEntityRow(
      title: widget.workspace.name,
      subtitle: widget.workspace.id,
      icon: AppIcons.boxes,
      expanded: widget.expanded,
      onExpandedChanged: widget.onExpandedChanged,
      detail: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsField(
            label: l10n.backupExportAction,
            description: l10n.backupExportDescription,
            centerControl: true,
            // Flush right, on the label block's centre line: these are actions
            // on the row, not a value the label introduces, so they belong at
            // the far edge rather than starting a second column mid-card.
            // A `Wrap` and not a `Row`: the pair is close to the width of the
            // control column already, and a translated label overflows it —
            // this drops the second button onto its own line instead.
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                CcButton(
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  icon: AppIcons.save,
                  loading: _exporting,
                  onPressed: _exporting ? null : _export,
                  child: Text(l10n.backupExportOnServerAction),
                ),
                CcButton(
                  size: CcButtonSize.sm,
                  icon: AppIcons.download,
                  loading: _downloading,
                  onPressed: !canTransfer || _downloading ? null : _download,
                  child: Text(l10n.backupDownloadAction),
                ),
              ],
            ),
          ),
          if (_downloadProgress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackupTransferProgressBar(
              transferred: _downloadProgress!.transferred,
              total: _downloadProgress!.total,
            ),
          ],
          if (_lastExportPath != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.backupExportedFileLabel,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
            const SizedBox(height: AppSpacing.xs),
            SettingsCopyField(value: _lastExportPath),
          ],
          const SizedBox(height: AppSpacing.lg),
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
          if (_uploadProgress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            BackupTransferProgressBar(
              transferred: _uploadProgress!.transferred,
              total: _uploadProgress!.total,
            ),
          ],
          if (!canTransfer) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.backupTransferUnavailable,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          // The other direction, for a file that is ALREADY on the server —
          // one an operator dropped in over ssh, or a per-workspace file inside
          // a snapshot directory. Uploading a file the server already holds
          // would be a round trip for nothing.
          SettingsField(
            label: l10n.backupImportSourceLabel,
            description: l10n.backupImportSourceDescription,
            layout: SettingsFieldLayout.stacked,
            child: Row(
              children: [
                Expanded(
                  child: CcTextField(
                    controller: _source,
                    hintText: '/path/to/workspace.db',
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                CcButton(
                  size: CcButtonSize.md,
                  variant: CcButtonVariant.secondary,
                  loading: _importing,
                  onPressed: _source.text.trim().isEmpty || _importing
                      ? null
                      : _import,
                  child: Text(l10n.backupImportAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.backupDeleteBody(widget.workspace.name),
            style: CcTypography.caption.copyWith(color: tokens.textTertiary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.destructive,
              icon: AppIcons.trash2,
              loading: _deleting,
              onPressed: _deleting ? null : _delete,
              child: Text(l10n.deleteWorkspace),
            ),
          ),
        ],
      ),
    );
  }
}
