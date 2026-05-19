import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_snapshots_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_data_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore.
///
/// The three operations behind this page — `server.backupNow`,
/// `workspace.export` and `workspace.import` — plus `workspace.delete` have all
/// existed since persistence was split by workspace, and none of them had a
/// button. They were reachable only by a caller speaking the RPC surface
/// directly, and the only trace in the app was an activity-log entry after the
/// fact. An operation an operator cannot reach is one they do not have, so a
/// backup nobody could take and a snapshot nobody could find were, in practice,
/// no backup at all.
///
/// Server-scoped because that is what a snapshot covers: every database on the
/// install, not the workspace you happen to be standing in.
class BackupSettingsScreen extends ConsumerWidget {
  /// Creates a [BackupSettingsScreen].
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // A demo server refuses all four ops by name — `workspace.export` VACUUMs a
    // whole database onto a public endpoint and the rest are install-wide. The
    // page keeps its chrome so the feature stays discoverable and says why the
    // body is empty, rather than firing three calls that are known to fail.
    if (ref.watch(isDemoServerProvider)) {
      return PageWrapper(
        title: l10n.settingsBackupRestore,
        subtitle: l10n.settingsBackupRestoreDescription,
        child: const DemoUnavailable(capability: DemoCapability.serverAdmin),
      );
    }
    return SettingsPage(
      title: l10n.settingsBackupRestore,
      subtitle: l10n.settingsBackupRestoreDescription,
      sections: const [BackupSnapshotsSection(), WorkspaceDataSection()],
    );
  }
}
