import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/messaging/detail_header.dart';
import 'package:cc_remote/widgets/schedules/schedule_actions.dart';
import 'package:cc_remote/widgets/schedules/schedule_summary.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The workspace's schedules and watches (`/schedules`): live ones first,
/// each with its next run, runs, money and status and the controls this
/// viewer has. [ruleId] opens one schedule's own route.
class SchedulesScreen extends ConsumerWidget {
  const SchedulesScreen({super.key, this.ruleId});

  final String? ruleId;

  static int _rank(WakeRuleView r) => switch (r.status) {
    WakeRuleStatus.active => 0,
    WakeRuleStatus.paused => 1,
    WakeRuleStatus.ended => 2,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final workspace = ref.watch(activeWorkspaceIdProvider);
    final workspaceId = workspace.value;
    final rules = workspaceId == null
        ? null
        : ref.watch(phoneSchedulesProvider(workspaceId));
    final Widget body;
    if (workspace.hasError || (rules?.hasError ?? false)) {
      body = CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l.schedulesLoadFailed,
        description: (workspace.error ?? rules?.error).toString(),
      );
    } else if (workspaceId == null || rules == null || rules.isLoading) {
      body = const Center(child: CcSpinner(size: 24));
    } else if (ruleId != null) {
      final rule = rules.value!.where((r) => r.id == ruleId).firstOrNull;
      body = rule == null
          ? CcEmptyState(
              icon: AppIcons.triangleAlert,
              message: l.scheduleMissing,
            )
          : _detail(context, rule, workspaceId);
    } else {
      final sorted = [...rules.value!]
        ..sort((a, b) {
          final rank = _rank(a).compareTo(_rank(b));
          return rank != 0 ? rank : b.createdAt.compareTo(a.createdAt);
        });
      body = sorted.isEmpty
          ? CcEmptyState(
              icon: AppIcons.repeat,
              message: l.schedulesEmpty,
              description: l.schedulesEmptyDescription,
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final rule in sorted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ScheduleRow(rule: rule, workspaceId: workspaceId),
                  ),
              ],
            );
    }
    return SafeArea(
      child: ColoredBox(
        color: t.canvas,
        child: Column(
          children: [
            if (ruleId != null) DetailHeader(title: l.schedulesTitle),
            Expanded(child: body),
          ],
        ),
      ),
    );
  }

  Widget _detail(BuildContext context, WakeRuleView rule, String workspaceId) {
    final l = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScheduleSummary(rule: rule, full: true),
        const SizedBox(height: 16),
        ScheduleActions(
          key: ValueKey('$workspaceId:${rule.id}'),
          rule: rule,
          workspaceId: workspaceId,
        ),
        const SizedBox(height: 12),
        CcButton(
          fullWidth: true,
          size: CcButtonSize.lg,
          variant: CcButtonVariant.secondary,
          icon: AppIcons.arrowRight,
          onPressed: () => context.push(
            remoteSpaceLocation(
              workspaceId: workspaceId,
              spaceId: rule.spaceId,
              conversationId: rule.conversationId,
            ),
          ),
          child: Text(l.scheduleOpenConversation),
        ),
      ],
    );
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({required this.rule, required this.workspaceId});

  final WakeRuleView rule;
  final String workspaceId;

  @override
  Widget build(BuildContext context) => CcCard(
    interactive: true,
    semanticLabel:
        scheduleTriggerText(context, rule) ??
        AppLocalizations.of(context).schedulesTitle,
    onPressed: () => context.push(
      remoteWorkspaceLocation(
        '/schedules/${Uri.encodeComponent(rule.id)}',
        workspaceId,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScheduleSummary(rule: rule),
        const SizedBox(height: 10),
        ScheduleActions(
          key: ValueKey('$workspaceId:${rule.id}'),
          rule: rule,
          workspaceId: workspaceId,
        ),
      ],
    ),
  );
}
