import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/settings/schedule_limits_section.dart';
import 'package:control_center/features/dispatch/presentation/settings/unattended_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_page.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedules_list.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/screens/settings_page.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Settings → Workspace → Schedules: every schedule, loop and watch of the
/// workspace with the way to create one, then the workspace's limits on them
/// and what happens to requests nobody answers. Anyone creates and reads
/// schedules; admins edit the limits, and a member reads the values and is
/// told who can change them. A demo server refuses the writes, and its
/// refusal shows on Save.
///
/// The page and one schedule are sibling routes sharing one page, so the list
/// stays mounted under an open schedule.
class DispatchSettingsView extends ConsumerWidget {
  /// Creates the view, showing schedule [ruleId] when given.
  const DispatchSettingsView({super.key, this.ruleId});

  /// The schedule the URL has open, or null for the page itself.
  final String? ruleId;

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
    final List<Widget> limitSections;
    if (limits.value case final l?) {
      limitSections = [
        ScheduleLimitsSection(
          workspaceId: workspaceId,
          limits: l,
          canEdit: admin && !demo,
        ),
        UnattendedSection(canEdit: admin && !demo, zone: l.defaultTimeZone),
      ];
    } else if (limits.hasError) {
      limitSections = [
        SectionCard(
          child: CcAlert(
            title: dispatchFailureMessage(l10n, limits.error!),
            variant: CcAlertVariant.danger,
          ),
        ),
      ];
    } else {
      limitSections = const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
          child: Center(child: CcSpinner()),
        ),
      ];
    }
    final id = ruleId;
    return IndexedStack(
      index: id == null ? 0 : 1,
      sizing: StackFit.expand,
      children: [
        SettingsPage(
          title: l10n.dispatchSettingsTitle,
          subtitle: l10n.schedulesSubtitle,
          actions: [NewScheduleButton(workspaceId: workspaceId)],
          sections: [
            SchedulesList(workspaceId: workspaceId),
            ...limitSections,
          ],
        ),
        if (id == null)
          const SizedBox.shrink()
        else
          PageWrapper(
            title: l10n.dispatchSettingsTitle,
            subtitle: l10n.schedulesSubtitle,
            child: SchedulePage(
              key: ValueKey(id),
              workspaceId: workspaceId,
              ruleId: id,
            ),
          ),
      ],
    );
  }
}
