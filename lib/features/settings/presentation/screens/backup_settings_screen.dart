import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/backup_snapshots_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/import_holds_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/server_notices_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_backups_section.dart';
import 'package:control_center/features/settings/presentation/widgets/sections/system/workspace_data_section.dart';
import 'package:control_center/features/settings/providers/backup_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/demo_unavailable.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Server → Backup & restore.
///
/// Install snapshots are owner-scoped; workspace export/import and deletion
/// use their own workspace role gates. The server owner's open notices and
/// the grants restored copies held back lead the page while there are any. This client renders server state and
/// forwards actions without reading databases or snapshot files locally.
class BackupSettingsScreen extends ConsumerWidget {
  /// Creates a [BackupSettingsScreen].
  const BackupSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    // Demo servers do not expose backup operations. Keep the page chrome
    // discoverable without offering actions that the server rejects.
    if (ref.watch(isDemoServerProvider)) {
      return PageWrapper(
        title: l10n.settingsBackupRestore,
        subtitle: l10n.settingsBackupRestoreDescription,
        child: const DemoUnavailable(capability: DemoCapability.serverAdmin),
      );
    }
    // What needs the server owner leads, and only when there is something:
    // an empty section would still take a gap in the page's list.
    return SettingsPage(
      title: l10n.settingsBackupRestore,
      subtitle: l10n.settingsBackupRestoreDescription,
      sections: [
        if (showServerNotices(ref)) const ServerNoticesSection(),
        if (ref.watch(heldGrantsProvider).isNotEmpty)
          const ImportHoldsSection(),
        const BackupSnapshotsSection(),
        const WorkspaceBackupsSection(),
        const WorkspaceDataSection(),
      ],
    );
  }
}
