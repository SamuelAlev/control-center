import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/utils/money_format.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/schedule_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/work_section.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_kind_text.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A schedule's own wakes and the runs they started (`wakeRules.listRuns`),
/// newest first, 50 at a time: what each wake was for, how it settled and
/// why, and the run it started with its status and cost, linking to the
/// conversation. Reloads its first page when the rule's run or skip count
/// changes.
class ScheduleRunsSection extends ConsumerStatefulWidget {
  /// Creates the section.
  const ScheduleRunsSection({super.key, required this.rule});

  /// The schedule.
  final WakeRuleView rule;

  @override
  ConsumerState<ScheduleRunsSection> createState() => _State();
}

class _State extends ConsumerState<ScheduleRunsSection> {
  final _wakes = <WakeRuleRunView>[];
  String? _next;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load(null);
  }

  @override
  void didUpdateWidget(ScheduleRunsSection old) {
    super.didUpdateWidget(old);
    if (old.rule.runCount != widget.rule.runCount ||
        old.rule.skipCount != widget.rule.skipCount ||
        old.rule.status != widget.rule.status) {
      _load(null);
    }
  }

  Future<void> _load(String? cursor) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await ref
          .read(wakeRuleScheduleRepositoryProvider)
          .listRuns(widget.rule.workspaceId, widget.rule.id, cursor: cursor);
      if (!mounted) {
        return;
      }
      setState(() {
        if (cursor == null) {
          _wakes.clear();
        }
        _wakes.addAll(page.wakes);
        _next = page.nextCursor;
      });
    } on Object catch (e) {
      if (mounted) {
        setState(() => _error = e);
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    return WorkSection(
      title: l10n.scheduleSectionHistory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final w in _wakes) _WakeRow(rule: widget.rule, wake: w),
          if (_error case final e?)
            CcAlert(
              variant: CcAlertVariant.danger,
              title: dispatchFailureMessage(l10n, e),
            )
          else if (_loading)
            const Padding(
              padding: EdgeInsetsDirectional.all(AppSpacing.md),
              child: Center(child: CcSpinner()),
            )
          else if (_wakes.isEmpty)
            Text(l10n.scheduleWakesNone, style: body),
          if (_next != null && !_loading)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: CcButton(
                variant: CcButtonVariant.ghost,
                size: CcButtonSize.sm,
                onPressed: () => _load(_next),
                child: Text(l10n.scheduleWakesOlder),
              ),
            ),
        ],
      ),
    );
  }
}

class _WakeRow extends StatelessWidget {
  const _WakeRow({required this.rule, required this.wake});

  final WakeRuleView rule;
  final WakeRuleRunView wake;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final label = workSectionLabelStyle(ds);
    final body = CcTypography.bodySm.copyWith(color: ds.textSecondary);
    final at = wake.slot ?? wake.dueAt;
    final reason = wake.stateReason;
    final reasonText = wakeKindSentence(l10n, reason);
    final state = scheduleWakeStateLabel(l10n, wake.state);
    final event = [
      ?wake.eventKind,
      ?wake.status,
      ?wake.subject,
      ?wake.item,
      if (wake.exitCode case final code?) l10n.scheduleWakeExit(code),
      if ((wake.events ?? 0) > 1) l10n.scheduleWakeEvents(wake.events!),
    ];
    final run = wake.run;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      l10n.scheduleWakeLine(
                        scheduleWakeReasonLabel(l10n, wake.reason),
                        state ?? '',
                      ),
                      style: CcTypography.bodySm.copyWith(
                        color: ds.textPrimary,
                      ),
                    ),
                    // An unknown state shows as the raw value.
                    if (state == null) WorkCode(wake.state),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              WorkTime(at: at, text: workTimeLabel(context, at), style: label),
            ],
          ),
          if (reason != null && reason.isNotEmpty)
            reasonText != null
                ? Text(reasonText, style: body)
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: WorkCode(reason),
                  ),
          if (event.isNotEmpty)
            Text(
              inertText(event.join(' · '), singleLine: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: body,
            ),
          if (run != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.scheduleRunLine(
                      scheduleRunStatusLabel(l10n, run.status),
                      fmtMicros(run.costMicros, decimals: 2, locale: locale),
                    ),
                    style: body,
                  ),
                ),
                CcButton(
                  variant: CcButtonVariant.ghost,
                  size: CcButtonSize.sm,
                  onPressed: () => context.go(
                    spaceRoute(
                      rule.workspaceId,
                      rule.spaceId,
                      tab: conversationTabKey(rule.conversationId),
                    ),
                  ),
                  child: Text(l10n.goalOpenConversation),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
