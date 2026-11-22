import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pause (active), resume (paused, only when the server says this viewer may:
/// `canChange`, with a sentence otherwise) and delete; an ended schedule
/// offers only to remove it from the list (a second delete).
class ScheduleActions extends ConsumerStatefulWidget {
  const ScheduleActions({
    super.key,
    required this.rule,
    required this.workspaceId,
  });

  final WakeRuleView rule;
  final String workspaceId;

  @override
  ConsumerState<ScheduleActions> createState() => _ScheduleActionsState();
}

class _ScheduleActionsState extends ConsumerState<ScheduleActions> {
  bool _busy = false;
  Object? _error;

  Future<void> _act(
    Future<bool> Function(WakeRuleScheduleRepository repo) action,
  ) async {
    final repo = ref.read(phoneSchedulesRepositoryProvider);
    final allowed =
        ref.read(activeWorkspaceIdProvider).value == widget.workspaceId &&
        (ref.read(workspaceRoleProvider).value?.canWrite ?? false);
    if (_busy || !allowed || repo == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action(repo);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(bool ended) async {
    final l = AppLocalizations.of(context);
    final ok = await confirmOperation(
      context,
      title: ended ? l.scheduleRemoveTitle : l.scheduleDeleteTitle,
      description: ended ? l.scheduleRemoveBody : l.scheduleDeleteBody,
      action: ended ? l.scheduleRemove : l.scheduleDelete,
      destructive: true,
    );
    if (ok && mounted) {
      await _act((r) => r.delete(widget.workspaceId, widget.rule.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l = AppLocalizations.of(context);
    ref.watch(activeWorkspaceIdProvider);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final rule = widget.rule;
    if (!writable) return const SizedBox.shrink();
    final ws = widget.workspaceId;
    final ended = rule.status == WakeRuleStatus.ended;
    final paused = rule.status == WakeRuleStatus.paused;
    Widget button(String label, VoidCallback onPressed, CcButtonVariant v) =>
        CcButton(
          size: CcButtonSize.lg,
          variant: v,
          onPressed: _busy ? null : onPressed,
          child: Text(label),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (paused && !rule.canChange)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              rule.ownerUserId == null
                  ? l.scheduleResumeAdminOnly
                  : l.scheduleResumeNotYours,
              style: CcTypography.bodySm.copyWith(color: t.textSecondary),
            ),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (rule.status == WakeRuleStatus.active)
              button(
                l.schedulePause,
                () => _act((r) => r.pause(ws, rule.id)),
                CcButtonVariant.secondary,
              ),
            if (paused && rule.canChange)
              button(
                l.scheduleResume,
                () => _act((r) => r.resume(ws, rule.id)),
                CcButtonVariant.primary,
              ),
            button(
              ended ? l.scheduleRemove : l.scheduleDelete,
              () => _delete(ended),
              ended ? CcButtonVariant.secondary : CcButtonVariant.destructive,
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: WorkFailureLine(error: _error!, schedule: true),
          ),
      ],
    );
  }
}
