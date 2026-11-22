import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/wake_rule_schedule_repository.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/dispatch/presentation/dispatch_text.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_delivery_fields.dart';
import 'package:control_center/features/dispatch/presentation/widgets/schedules/schedule_when_fields.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Creates a person's schedule (`wakeRules.create`): which conversation and
/// agent it wakes, when, what its runs start from, and its limits. A
/// refusal shows its sentence and keeps the dialog open; success opens the
/// new schedule's page.
Future<void> showScheduleCreateDialog(
  BuildContext context,
  String workspaceId,
) => showCcDialog<void>(
  context: context,
  builder: (_) => _CreateDialog(workspaceId: workspaceId),
);

const _maxDollars = WakeRuleLimits.maxCostCapMicros ~/ 1000000;

class _CreateDialog extends ConsumerStatefulWidget {
  const _CreateDialog({required this.workspaceId});

  final String workspaceId;

  @override
  ConsumerState<_CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends ConsumerState<_CreateDialog> {
  final _when = ScheduleWhenDraft();
  final _note = TextEditingController();
  final _days = TextEditingController();
  final _maxRuns = TextEditingController();
  final _dollars = TextEditingController();
  String? _spaceId, _conversationId, _agentId;
  WakeWhenBusy? _whenBusy;
  WakeDeliver _deliver = WakeDeliver.run;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _when.dispose();
    for (final c in [_note, _days, _maxRuns, _dollars]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _optional(TextEditingController c, int max) {
    final v = int.tryParse(c.text.trim());
    return v != null && v >= 1 && v <= max ? v : null;
  }

  bool _optionalOk(TextEditingController c, int max) =>
      c.text.trim().isEmpty || _optional(c, max) != null;

  bool get _valid =>
      _conversationId != null &&
      _agentId != null &&
      _note.text.trim().isNotEmpty &&
      _when.valid &&
      _optionalOk(_days, WakeRuleBounds.personMaxExpiry.inDays) &&
      _optionalOk(_maxRuns, WakeRuleBounds.maxRunsCeiling) &&
      _optionalOk(_dollars, _maxDollars);

  Future<void> _submit() async {
    final zone = _when.zone.text.trim();
    final clock = _when.kind == ScheduleWhenKind.onceAt;
    final days = _optional(_days, WakeRuleBounds.personMaxExpiry.inDays);
    final dollars = _optional(_dollars, _maxDollars);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final rule = await ref
          .read(wakeRuleScheduleRepositoryProvider)
          .create(
            widget.workspaceId,
            WakeRuleDraft(
              conversationId: _conversationId!,
              agentId: _agentId!,
              note: _note.text.trim(),
              when: clock ? null : _when.when,
              hour: clock ? _when.clockHour : null,
              minute: clock ? _when.clockMinute : null,
              timeZone: zone.isEmpty ? null : zone,
              maxRuns: _optional(_maxRuns, WakeRuleBounds.maxRunsCeiling),
              expiresIn: days == null ? null : '${days}d',
              costCapMicros: dollars == null ? null : dollars * 1000000,
              whenBusy: _whenBusy,
              deliver: _deliver,
            ),
          );
      if (mounted) {
        Navigator.of(context).pop();
        GoRouter.maybeOf(
          context,
        )?.go(scheduleRoute(widget.workspaceId, rule.id));
      }
    } on Object catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _error = dispatchFailureMessage(l10n, e));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ws = widget.workspaceId;
    final spaces =
        ref.watch(workspaceSpacesProvider(ws)).value ?? const <Space>[];
    final conversations = _spaceId == null
        ? const <Conversation>[]
        : ref.watch(spaceConversationsProvider(_spaceId!)).value ??
              const <Conversation>[];
    final agents =
        ref.watch(workspaceAgentsProvider(ws)).value ?? const <Agent>[];
    void changed() => setState(() {});
    Widget number(TextEditingController c, String label, String help) =>
        Expanded(
          child: CcTextField(
            controller: c,
            label: label,
            helperText: help,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => changed(),
          ),
        );
    const gap = SizedBox(height: AppSpacing.md);
    return CcDialog(
      title: l10n.scheduleCreateTitle,
      maxWidth: 640,
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              CcSelect<String>(
                label: l10n.scheduleSpaceLabel,
                hintText: l10n.scheduleSpaceHint,
                value: _spaceId,
                options: [
                  for (final s in spaces)
                    CcSelectOption(value: s.id, label: s.name),
                ],
                onChanged: (v) => setState(() {
                  _spaceId = v;
                  _conversationId = null;
                }),
              ),
              gap,
              CcSelect<String>(
                label: l10n.scheduleConversationLabel,
                hintText: l10n.scheduleConversationHint,
                enabled: _spaceId != null,
                value: _conversationId,
                options: [
                  for (final c in conversations)
                    CcSelectOption(value: c.id, label: c.title),
                ],
                onChanged: (v) => setState(() => _conversationId = v),
              ),
              gap,
              CcSelect<String>(
                label: l10n.scheduleAgentLabel,
                hintText: l10n.scheduleAgentHint,
                value: _agentId,
                options: [
                  for (final a in agents)
                    CcSelectOption(value: a.id, label: a.name),
                ],
                onChanged: (v) => setState(() => _agentId = v),
              ),
              gap,
              ScheduleWhenFields(
                workspaceId: ws,
                draft: _when,
                onChanged: changed,
              ),
              gap,
              CcTextArea(
                controller: _note,
                label: l10n.scheduleNoteLabel,
                hintText: l10n.scheduleNoteHint,
                maxLength: WakeRule.maxNoteLength,
                minLines: 2,
                maxLines: 6,
                onChanged: (_) => changed(),
              ),
              gap,
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  number(
                    _days,
                    l10n.scheduleExpiresInDays,
                    l10n.scheduleExpiresInDaysHelp,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  number(
                    _maxRuns,
                    l10n.scheduleMaxRuns,
                    l10n.scheduleMaxRunsHelp(WakeRuleBounds.maxRunsCeiling),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  number(
                    _dollars,
                    l10n.scheduleCostCap,
                    l10n.scheduleCostCapHelp,
                  ),
                ],
              ),
              gap,
              ScheduleDeliveryFields(
                whenBusy: _whenBusy,
                deliver: _deliver,
                onWhenBusyChanged: (v) => setState(() => _whenBusy = v),
                onDeliverChanged: (v) => setState(() => _deliver = v),
              ),
              if (_error case final error?) ...[
                gap,
                CcAlert(variant: CcAlertVariant.danger, title: error),
              ],
            ],
          ),
        ),
      ),
      actions: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        CcButton(
          loading: _busy,
          onPressed: _valid && !_busy ? _submit : null,
          child: Text(l10n.scheduleCreate),
        ),
      ],
    );
  }
}
