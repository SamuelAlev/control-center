import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_command.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_remote/analytics.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/plan_goal/work_target_picker.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_remote/work_launcher.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

/// Starts a goal the way a conversation's `/goal` does: an objective, the
/// optional checks (commands that pass when the work is done), a required
/// budget shown before sending, and an optional segment cap. The body is
/// read locally first, so a refusal shows before anything is sent; the
/// server reads it again and decides.
class PhoneGoalCreate extends ConsumerStatefulWidget {
  const PhoneGoalCreate({
    super.key,
    required this.workspaceId,
    this.conversationId,
  });

  final String workspaceId;
  final String? conversationId;

  @override
  ConsumerState<PhoneGoalCreate> createState() => _PhoneGoalCreateState();
}

class _PhoneGoalCreateState extends ConsumerState<PhoneGoalCreate> {
  final _objective = TextEditingController();
  final _budget = TextEditingController();
  final _segments = TextEditingController();
  final _checks = <TextEditingController>[TextEditingController()];
  String? _spaceId;
  String? _agentId;
  bool _busy = false;
  ({String text, String? code})? _failure;
  String? _notice;

  @override
  void dispose() {
    for (final c in [_objective, _budget, _segments, ..._checks]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _allowed =>
      mounted &&
      ref.read(activeWorkspaceIdProvider).value == widget.workspaceId &&
      (ref.read(workspaceRoleProvider).value?.canWrite ?? false);

  void _fail(String text, [String? code]) =>
      setState(() => _failure = (text: text, code: code));

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final objective = _objective.text.trim();
    final micros = parsePlanBudgetMicros(context, _budget.text);
    final agentId = _agentId;
    if (objective.isEmpty ||
        micros == null ||
        agentId == null ||
        (widget.conversationId == null && _spaceId == null)) {
      return _fail(l10n.mobileGoalCreateInvalid);
    }
    final segmentsText = _segments.text.trim();
    final maxRuns = segmentsText.isEmpty ? null : int.tryParse(segmentsText);
    if (segmentsText.isNotEmpty && (maxRuns == null || maxRuns < 1)) {
      return _fail(l10n.goalCreateSegmentInvalid);
    }
    final String body;
    try {
      body = phoneGoalCommandBody(
        objective: objective,
        budgetMicros: micros,
        maxRuns: maxRuns,
        checks: [for (final c in _checks) c.text],
      );
      GoalCommand.parse(body);
    } on ValidationException catch (e) {
      return _fail(l10n.goalRefusalCommandInvalid, e.message);
    } on ArgumentError catch (e) {
      return _fail(l10n.goalRefusalCommandInvalid, '${e.message}');
    }
    final confirmed = await confirmOperation(
      context,
      title: l10n.mobileGoalCreate,
      description: l10n.mobileGoalCreateConfirm(planMoney(context, micros)),
      action: l10n.mobileGoalCreate,
    );
    final launcher = ref.read(phoneWorkLauncherProvider);
    if (!confirmed || !_allowed) return;
    if (launcher == null) return _fail(l10n.mobileGoalUnavailable);
    setState(() {
      _busy = true;
      _failure = null;
      _notice = null;
    });
    final analytics = ref.read(analyticsProvider);
    try {
      final target = await launcher.target(
        workspaceId: widget.workspaceId,
        conversationId: widget.conversationId,
        spaceId: _spaceId,
      );
      if (!_allowed) return;
      final runId = await launcher.startGoal(
        workspaceId: widget.workspaceId,
        target: target,
        agentId: agentId,
        body: body,
      );
      analytics.track(
        AnalyticsEvents.goalStarted(
          kind: 'goal',
          workspaceId: widget.workspaceId,
          spaceId: target.spaceId,
          conversationId: target.conversationId,
          agentId: agentId,
          budgetMicros: micros,
          accepted: runId != null,
        ),
      );
      if (!mounted) return;
      if (runId == null) return _fail(l10n.mobileGoalStartRefused);
      _objective.clear();
      for (final c in _checks) {
        c.clear();
      }
      setState(() => _notice = l10n.mobileGoalCreateSent);
    } on WorkTargetMissing {
      if (mounted) _fail(l10n.mobileGoalConversationMissing);
    } catch (e) {
      if (!mounted) return;
      final failure = workFailure(l10n, e);
      _fail(failure.text, failure.code);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    ref.watch(activeWorkspaceIdProvider);
    final writable = ref.watch(workspaceRoleProvider).value?.canWrite ?? false;
    final enabled = writable && !_busy;
    final secondary = CcTypography.bodySm.copyWith(color: t.textSecondary);
    final failure = _failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.mobileGoalCreate,
          style: CcTypography.body.copyWith(
            color: t.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        WorkTargetPicker(
          workspaceId: widget.workspaceId,
          askSpace: widget.conversationId == null,
          spaceId: _spaceId,
          agentId: _agentId,
          onSpace: (id) => setState(() => _spaceId = id),
          onAgent: (id) => setState(() => _agentId = id),
        ),
        const SizedBox(height: 12),
        CcTextArea(
          controller: _objective,
          minLines: 3,
          maxLines: 6,
          enabled: enabled,
          hintText: l10n.mobileGoalObjectiveHint,
        ),
        const SizedBox(height: 16),
        Text(l10n.goalCreateChecks, style: secondary),
        const SizedBox(height: 6),
        for (var i = 0; i < _checks.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  // RTL carve-out: a check is a shell command.
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: CcTextField(
                      controller: _checks[i],
                      hintText: l10n.goalCreateCheckHint,
                      enabled: enabled,
                    ),
                  ),
                ),
                if (_checks.length > 1)
                  PhoneIconButton(
                    icon: AppIcons.x,
                    semanticLabel: l10n.goalCreateRemoveCheck,
                    onPressed: enabled
                        ? () => setState(() => _checks.removeAt(i).dispose())
                        : null,
                  ),
              ],
            ),
          ),
        if (_checks.length < GoalCommand.maxChecks)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.ghost,
              onPressed: enabled
                  ? () => setState(() => _checks.add(TextEditingController()))
                  : null,
              child: Text(l10n.goalCreateAddCheck),
            ),
          ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _budget,
          label: l10n.mobileGoalBudgetUsd,
          hintText: NumberFormat.decimalPatternDigits(
            locale: Localizations.localeOf(context).toLanguageTag(),
            decimalDigits: 2,
          ).format(50),
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _segments,
          label: l10n.goalCreateSegmentCap,
          enabled: enabled,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 12),
        if (failure != null)
          WorkKindLine(
            sentence: failure.code == null ? failure.text : null,
            kind: failure.code ?? '',
            lead: failure.text,
            color: t.textErrorPrimary,
          ),
        if (_notice != null)
          Text(
            _notice!,
            style: CcTypography.bodySm.copyWith(color: t.textPrimary),
          ),
        const SizedBox(height: 8),
        CcButton(
          fullWidth: true,
          size: CcButtonSize.lg,
          loading: _busy,
          onPressed: enabled ? _send : null,
          child: Text(l10n.mobileGoalCreate),
        ),
      ],
    );
  }
}
