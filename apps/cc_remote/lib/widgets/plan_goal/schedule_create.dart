import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/widgets/plan_goal/confirm_operation.dart';
import 'package:cc_remote/widgets/plan_goal/plan_review.dart';
import 'package:cc_remote/widgets/plan_goal/work_target_picker.dart';
import 'package:cc_remote/widgets/work/work_text.dart';
import 'package:cc_remote/work_kind_text.dart';
import 'package:cc_remote/work_launcher.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum _Cadence { minutes, hours, selfPaced }

/// Repeats a prompt in a conversation (`wakeRules.create`): every N minutes
/// or hours starting now, or self-paced (the agent picks each delay), with
/// what each run should do, an optional cost cap and an optional expiry in
/// days. The server checks the floors and ceilings and refuses with a kind.
class PhoneScheduleCreate extends ConsumerStatefulWidget {
  const PhoneScheduleCreate({
    super.key,
    required this.workspaceId,
    this.conversationId,
  });

  final String workspaceId;
  final String? conversationId;

  @override
  ConsumerState<PhoneScheduleCreate> createState() =>
      _PhoneScheduleCreateState();
}

class _PhoneScheduleCreateState extends ConsumerState<PhoneScheduleCreate> {
  final _note = TextEditingController();
  final _interval = TextEditingController(text: '30');
  final _cap = TextEditingController();
  final _days = TextEditingController();
  _Cadence _cadence = _Cadence.minutes;
  String? _spaceId;
  String? _agentId;
  bool _busy = false;
  ({String text, String? code})? _failure;
  String? _notice;

  @override
  void dispose() {
    for (final c in [_note, _interval, _cap, _days]) {
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

  static int? _positive(String raw) {
    final value = int.tryParse(raw.trim());
    return value != null && value >= 1 ? value : null;
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context);
    final note = _note.text.trim();
    final interval = _positive(_interval.text);
    final selfPaced = _cadence == _Cadence.selfPaced;
    final capText = _cap.text.trim();
    final cap = capText.isEmpty
        ? null
        : parsePlanBudgetMicros(context, capText);
    final daysText = _days.text.trim();
    final days = daysText.isEmpty ? null : _positive(daysText);
    final agentId = _agentId;
    if (note.isEmpty ||
        agentId == null ||
        (widget.conversationId == null && _spaceId == null) ||
        (!selfPaced && interval == null) ||
        (capText.isNotEmpty && cap == null) ||
        (daysText.isNotEmpty && days == null)) {
      return _fail(l10n.scheduleCreateInvalid);
    }
    final when = switch (_cadence) {
      _Cadence.minutes => 'every:${interval}m',
      _Cadence.hours => 'every:${interval}h',
      _Cadence.selfPaced => 'next',
    };
    final confirmed = await confirmOperation(
      context,
      title: l10n.scheduleCreateConfirmTitle,
      description: switch (_cadence) {
        _Cadence.minutes => l10n.scheduleCreateConfirmEveryMinutes(interval!),
        _Cadence.hours => l10n.scheduleCreateConfirmEveryHours(interval!),
        _Cadence.selfPaced => l10n.scheduleCreateConfirmSelfPaced,
      },
      action: l10n.scheduleCreateButton,
    );
    final launcher = ref.read(phoneWorkLauncherProvider);
    final repo = ref.read(phoneSchedulesRepositoryProvider);
    if (!confirmed || !_allowed) return;
    if (launcher == null || repo == null) {
      return _fail(l10n.mobileGoalUnavailable);
    }
    setState(() {
      _busy = true;
      _failure = null;
      _notice = null;
    });
    try {
      final target = await launcher.target(
        workspaceId: widget.workspaceId,
        conversationId: widget.conversationId,
        spaceId: _spaceId,
      );
      if (!_allowed) return;
      await repo.create(
        widget.workspaceId,
        WakeRuleDraft(
          conversationId: target.conversationId,
          agentId: agentId,
          note: note,
          when: when,
          costCapMicros: cap,
          expiresIn: days == null ? null : '${days}d',
          fireNow: !selfPaced,
        ),
      );
      if (!mounted) return;
      _note.clear();
      setState(() => _notice = l10n.scheduleCreated);
    } on WorkTargetMissing {
      if (mounted) _fail(l10n.mobileGoalConversationMissing);
    } catch (e) {
      if (!mounted) return;
      final failure = workFailure(l10n, e, schedule: true);
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
    Widget cadence(_Cadence which, String label) => CcButton(
      size: CcButtonSize.lg,
      variant: _cadence == which
          ? CcButtonVariant.primary
          : CcButtonVariant.secondary,
      onPressed: enabled ? () => setState(() => _cadence = which) : null,
      child: Text(label),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.scheduleCreateTitle,
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
        Text(l10n.scheduleCadence, style: secondary),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            cadence(_Cadence.minutes, l10n.scheduleEveryMinutes),
            cadence(_Cadence.hours, l10n.scheduleEveryHours),
            cadence(_Cadence.selfPaced, l10n.scheduleSelfPaced),
          ],
        ),
        const SizedBox(height: 12),
        if (_cadence == _Cadence.selfPaced)
          Text(l10n.scheduleSelfPacedHint, style: secondary)
        else
          CcTextField(
            controller: _interval,
            label: l10n.scheduleInterval,
            enabled: enabled,
            keyboardType: TextInputType.number,
          ),
        const SizedBox(height: 12),
        CcTextArea(
          controller: _note,
          minLines: 3,
          maxLines: 6,
          enabled: enabled,
          hintText: l10n.scheduleNote,
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _cap,
          label: l10n.scheduleCostCap,
          enabled: enabled,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        ),
        const SizedBox(height: 12),
        CcTextField(
          controller: _days,
          label: l10n.scheduleExpiryDays,
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
          child: Text(l10n.scheduleCreateButton),
        ),
      ],
    );
  }
}
