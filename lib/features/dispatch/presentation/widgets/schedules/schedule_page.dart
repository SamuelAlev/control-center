import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_page_header.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_runs_section.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_sections.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_record_states.dart';
import 'package:control_center/features/dispatch/providers/long_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One schedule's page: loading, refused, not found, or the schedule with
/// its facts and recent wakes and runs.
class SchedulePage extends ConsumerWidget {
  /// Creates the page of [ruleId] in [workspaceId].
  const SchedulePage({
    super.key,
    required this.workspaceId,
    required this.ruleId,
  });

  /// The workspace.
  final String workspaceId;

  /// The schedule.
  final String ruleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    void back() => ref
        .read(navigationHistoryProvider.notifier)
        .backOr(schedulesRoute(workspaceId));
    return WorkRecordStates<WakeRuleView>(
      value: ref.watch(
        wakeRuleViewProvider((workspaceId: workspaceId, id: ruleId)),
      ),
      notFound: l10n.scheduleNotFound,
      backLabel: l10n.schedulesBackToList,
      onBack: back,
      builder: (rule) => ListView(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        children: [
          SchedulePageHeader(rule: rule, onBack: back),
          const SizedBox(height: AppSpacing.lg),
          ScheduleFactsSection(rule: rule),
          ScheduleRunsSection(rule: rule),
        ],
      ),
    );
  }
}
