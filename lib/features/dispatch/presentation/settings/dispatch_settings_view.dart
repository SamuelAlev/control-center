import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/settings/schedule_limits_section.dart';
import 'package:control_center/features/dispatch/presentation/settings/unattended_section.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Schedules: the workspace's limits on schedules and
/// watches, and what happens to requests nobody answers. Admins edit; a
/// member reads the values and is told who can change them. A demo server
/// refuses the writes, and its refusal shows on Save.
class DispatchSettingsView extends ConsumerWidget {
  /// Creates the view.
  const DispatchSettingsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null || workspaceId.isEmpty) {
      return const SizedBox.shrink();
    }
    final admin =
        ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false;
    final demo = ref.watch(isDemoServerProvider);
    final limits = ref.watch(wakeRuleLimitsProvider(workspaceId));
    final List<Widget> sections;
    if (limits.value case final l?) {
      sections = [
        ScheduleLimitsSection(
          workspaceId: workspaceId,
          limits: l,
          canEdit: admin && !demo,
        ),
        UnattendedSection(canEdit: admin && !demo, zone: l.defaultTimeZone),
      ];
    } else if (limits.hasError) {
      sections = [
        SectionCard(
          child: CcAlert(
            title: dispatchFailureMessage(l10n, limits.error!),
            variant: CcAlertVariant.danger,
          ),
        ),
      ];
    } else {
      sections = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CcSpinner()),
        ),
      ];
    }
    return SettingsPage(
      title: l10n.dispatchSettingsTitle,
      subtitle: l10n.dispatchSettingsSubtitle,
      sections: sections,
    );
  }
}
