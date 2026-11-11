import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/backup_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/human_bytes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this person may restore a workspace from a backup.
///
/// Restoring replaces a workspace's database with a file on, or sent to, the
/// server host, so it is the server owner's (`identity.me.can_use_host`), the
/// same right as every other host action. Downloading a backup is not.
bool canRestoreBackups(WidgetRef ref) => ref.watch(canUseHostProvider);

/// The one quiet line, in place of the restore actions, for anyone who may
/// not restore: the server owner does. Renders nothing for the owner.
class BackupRestoreOwnerOnlyNote extends ConsumerWidget {
  /// Creates the note.
  const BackupRestoreOwnerOnlyNote({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (canRestoreBackups(ref)) {
      return const SizedBox.shrink();
    }
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
      child: Text(
        AppLocalizations.of(context).backupRestoreServerOwnerOnly,
        textAlign: TextAlign.start,
        style: CcTypography.caption.copyWith(color: tokens.textTertiary),
      ),
    );
  }
}

/// One workspace inside a whole-install snapshot: its name and size, and
/// Restore for the server owner.
class BackupSnapshotWorkspaceRow extends ConsumerWidget {
  /// Creates the row for [entry].
  const BackupSnapshotWorkspaceRow({
    super.key,
    required this.entry,
    required this.name,
    required this.busy,
    required this.onRestore,
  });

  /// The workspace's file in the snapshot.
  final BackupSnapshotWorkspaceView entry;

  /// The workspace's name, or null when this install no longer knows it.
  final String? name;

  /// Whether a restore of this entry is running.
  final bool busy;

  /// Fired by Restore, with the workspace's name.
  final Future<void> Function(BackupSnapshotWorkspaceView, String) onRestore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final known = name != null;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.sm),
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
                  known ? humanBytes(entry.bytes) : l10n.backupWorkspaceUnknown,
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          if (canRestoreBackups(ref)) ...[
            const SizedBox(width: AppSpacing.md),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              loading: busy,
              onPressed: known && !busy ? () => onRestore(entry, name!) : null,
              child: Text(l10n.backupRestoreAction),
            ),
          ],
        ],
      ),
    );
  }
}
