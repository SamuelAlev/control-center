import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_transfer_feedback.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/type_to_confirm_labels.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Adopts a workspace database file that is ALREADY on the server into
/// [workspace]: one an operator dropped in over ssh, or a per-workspace file
/// inside a snapshot directory. Uploading a file the server already holds
/// would be a round trip for nothing.
///
/// A restore, so it is offered to the server owner only (see
/// `canRestoreBackups`).
class WorkspaceImportSourceField extends ConsumerStatefulWidget {
  /// Creates the field for [workspace].
  const WorkspaceImportSourceField({super.key, required this.workspace});

  /// The workspace the file replaces.
  final Workspace workspace;

  @override
  ConsumerState<WorkspaceImportSourceField> createState() =>
      _WorkspaceImportSourceFieldState();
}

class _WorkspaceImportSourceFieldState
    extends ConsumerState<WorkspaceImportSourceField> {
  final TextEditingController _source = TextEditingController();
  bool _importing = false;
  String? _refusal;

  @override
  void dispose() {
    _source.dispose();
    super.dispose();
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
      typeToConfirmLabels: appTypeToConfirmLabels(context),
    );
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _importing = true;
      _refusal = null;
    });
    try {
      final held = await ref
          .read(backupActionsProvider)
          .importWorkspace(
            workspaceId: widget.workspace.id,
            sourcePath: source,
          );
      if (mounted) {
        reportRestoreDone(
          context,
          done: l10n.backupImportDone(name),
          held: held,
        );
      }
    } on Object catch (e) {
      // In place, under the path: the sentence says what is wrong with the
      // file there, which the person needs while typing another one.
      if (mounted) {
        setState(() => _refusal = describeBackupTransferError(l10n, e));
      }
    } finally {
      if (mounted) {
        setState(() => _importing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsField(
      label: l10n.backupImportSourceLabel,
      description: l10n.backupImportSourceDescription,
      layout: SettingsFieldLayout.stacked,
      // Top-aligned: a refusal under the field must not drag the button down.
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: CcTextField(
              controller: _source,
              hintText: '/path/to/workspace.db',
              errorText: _refusal,
              onChanged: (_) => setState(() => _refusal = null),
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
    );
  }
}
