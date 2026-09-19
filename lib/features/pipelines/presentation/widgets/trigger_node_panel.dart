import 'dart:async' show unawaited;

import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/presentation/widgets/node_field_label.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _prStatuses = ['merged', 'closed', 'approved', 'opened', 'reopened'];

/// Right-hand inspector for one selected start-trigger on the canvas.
///
/// Hidden until a trigger proxy is selected. Kind-specific fields (schedule
/// expression, webhook path, PR status chips) live here so they can be edited
/// after the node is dropped, not only at insert time.
class TriggerNodePanel extends ConsumerWidget {
  /// Creates a [TriggerNodePanel] for [triggerId].
  const TriggerNodePanel({
    super.key,
    required this.workspaceId,
    required this.templateId,
    required this.triggerId,
    required this.onDelete,
  });

  /// Workspace the template belongs to.
  final String workspaceId;

  /// Template whose trigger is shown.
  final String templateId;

  /// The canvas-selected trigger row.
  final String triggerId;

  /// Removes this trigger (parent also clears the selection).
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final triggersAsync = ref.watch(
      pipelineTriggersForWorkspaceProvider(workspaceId),
    );
    final trigger = triggersAsync.value?.firstWhereOrNull(
      (t) => t.id == triggerId && t.templateId == templateId,
    );
    if (trigger == null) {
      return const SizedBox.shrink();
    }
    return _TriggerInspector(
      key: ValueKey(trigger.id),
      trigger: trigger,
      onDelete: onDelete,
    );
  }
}

class _TriggerInspector extends ConsumerStatefulWidget {
  const _TriggerInspector({
    super.key,
    required this.trigger,
    required this.onDelete,
  });

  final PipelineTrigger trigger;
  final VoidCallback onDelete;

  @override
  ConsumerState<_TriggerInspector> createState() => _TriggerInspectorState();
}

class _TriggerInspectorState extends ConsumerState<_TriggerInspector> {
  late final TextEditingController _scheduleCtrl;
  late final TextEditingController _timezoneCtrl;
  late CronCatchUpPolicy _catchUp;

  @override
  void initState() {
    super.initState();
    _scheduleCtrl = TextEditingController(
      text: widget.trigger.cronExpression ?? 'every:86400',
    );
    _timezoneCtrl = TextEditingController(text: widget.trigger.timezone ?? '');
    _catchUp = widget.trigger.catchUpPolicy;
  }

  @override
  void dispose() {
    if (widget.trigger.eventType == PipelineTrigger.scheduleEventType) {
      final next = _withPendingSchedule(widget.trigger);
      if (next.cronExpression != widget.trigger.cronExpression ||
          (next.timezone ?? '') != (widget.trigger.timezone ?? '') ||
          next.catchUpPolicy != widget.trigger.catchUpPolicy) {
        unawaited(ref.read(pipelineTriggerRepositoryProvider).update(next));
      }
    }
    _scheduleCtrl.dispose();
    _timezoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final trigger = widget.trigger;
    final title = triggerEventLabel(l10n, trigger.eventType);
    final help = _helpFor(l10n, trigger.eventType);
    final showTypeName = title != trigger.eventType;

    return Container(
      color: tokens.bgPrimary,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: tokens.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CcIconButton(
                onPressed: widget.onDelete,
                variant: CcButtonVariant.ghost,
                icon: AppIcons.trash2,
                tooltip: l10n.delete,
              ),
            ],
          ),
          if (showTypeName) ...[
            const SizedBox(height: 4),
            Text(
              trigger.eventType,
              style: TextStyle(color: tokens.textTertiary, fontSize: 12),
            ),
          ],
          if (help != null) ...[
            const SizedBox(height: 4),
            Text(
              help,
              style: TextStyle(color: tokens.textTertiary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.enabled,
                  style: TextStyle(color: tokens.textPrimary, fontSize: 13),
                ),
              ),
              CcSwitch(
                value: trigger.enabled,
                onChanged: (enabled) {
                  unawaited(
                    _save(
                      _withPendingSchedule(trigger.copyWith(enabled: enabled)),
                    ),
                  );
                },
              ),
            ],
          ),
          if (trigger.eventType == PipelineTrigger.scheduleEventType) ...[
            const SizedBox(height: 16),
            NodeFieldLabel(
              label: l10n.triggerScheduleExprLabel,
              child: CcTextField(
                controller: _scheduleCtrl,
                hintText: '0 9 * * 1   ·   every:86400',
                textInputAction: TextInputAction.done,
                onEditingComplete: () => unawaited(_persistSchedule()),
                onSubmitted: (_) => unawaited(_persistSchedule()),
              ),
            ),
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.triggerTimezoneLabel,
              child: CcTextField(
                controller: _timezoneCtrl,
                hintText: 'UTC',
                textInputAction: TextInputAction.done,
                onEditingComplete: () => unawaited(_persistSchedule()),
                onSubmitted: (_) => unawaited(_persistSchedule()),
              ),
            ),
            const SizedBox(height: 12),
            NodeFieldLabel(
              label: l10n.triggerCatchUpLabel,
              child: CcSelect<CronCatchUpPolicy>(
                options: [
                  CcSelectOption(
                    value: CronCatchUpPolicy.catchUpLatestOnly,
                    label: l10n.triggerCatchUpRunOnce,
                  ),
                  CcSelectOption(
                    value: CronCatchUpPolicy.skip,
                    label: l10n.triggerCatchUpSkip,
                  ),
                ],
                value: _catchUp,
                onChanged: (policy) {
                  setState(() => _catchUp = policy);
                  unawaited(_persistSchedule(policy: policy));
                },
              ),
            ),
          ] else if (trigger.eventType == PipelineTrigger.webhookEventType) ...[
            const SizedBox(height: 16),
            NodeFieldLabel(
              label: l10n.triggerWebhookPathLabel,
              description: l10n.triggerWebhookHelp,
              child: _WebhookPathCopy(token: trigger.webhookToken),
            ),
          ] else if (trigger.eventType == 'PullRequestStatusChanged') ...[
            const SizedBox(height: 16),
            Text(
              l10n.triggerMatchStatusLabel,
              style: TextStyle(color: tokens.textPrimary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final status in _prStatuses)
                  CcChip(
                    label: status,
                    selected: _statusesFrom(trigger).contains(status),
                    onPressed: () => unawaited(_toggleStatus(status)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String? _helpFor(AppLocalizations l10n, String eventType) {
    if (eventType == PipelineTrigger.scheduleEventType ||
        eventType == PipelineTrigger.webhookEventType) {
      // Those inspectors already explain themselves with their own fields.
      return null;
    }
    final help = triggerEventHelp(l10n, eventType);
    return help == eventType ? null : help;
  }

  PipelineTrigger _withPendingSchedule(PipelineTrigger base) {
    if (base.eventType != PipelineTrigger.scheduleEventType) {
      return base;
    }
    final cron = _normalizeSchedule(_scheduleCtrl.text) ?? base.cronExpression;
    final tz = _timezoneCtrl.text.trim();
    final cronChanged = cron != base.cronExpression;
    final tzChanged = tz != (base.timezone ?? '');
    return base.copyWith(
      cronExpression: cron,
      timezone: tz,
      catchUpPolicy: _catchUp,
      clearNextRunAt: cronChanged || tzChanged,
    );
  }

  Future<void> _persistSchedule({CronCatchUpPolicy? policy}) async {
    if (policy != null) {
      _catchUp = policy;
    }
    await _save(_withPendingSchedule(widget.trigger));
  }

  Future<void> _toggleStatus(String status) async {
    final next = {..._statusesFrom(widget.trigger)};
    if (!next.add(status)) {
      next.remove(status);
    }
    final match = next.isEmpty
        ? const <String, dynamic>{}
        : <String, dynamic>{'status': next.toList()};
    await _save(widget.trigger.copyWith(match: match));
  }

  Future<void> _save(PipelineTrigger next) async {
    final current = widget.trigger;
    // [PipelineTrigger.==] is identity + enabled only; schedule/match edits
    // have to be compared field-by-field or they look unchanged.
    if (next.enabled == current.enabled &&
        next.cronExpression == current.cronExpression &&
        (next.timezone ?? '') == (current.timezone ?? '') &&
        next.catchUpPolicy == current.catchUpPolicy &&
        const DeepCollectionEquality().equals(next.match, current.match)) {
      return;
    }
    try {
      await ref.read(pipelineTriggerRepositoryProvider).update(next);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.maybeOf(context)?.show(
        AppLocalizations.of(context).errorWithDetail('$e'),
        variant: CcToastVariant.danger,
      );
    }
  }
}

class _WebhookPathCopy extends StatelessWidget {
  const _WebhookPathCopy({required this.token});

  final String? token;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final path = token == null || token!.isEmpty ? null : '/webhooks/$token';
    if (path == null) {
      return Text(
        l10n.triggerWebhookHelp,
        style: TextStyle(color: tokens.textTertiary, fontSize: 12),
      );
    }
    return Row(
      children: [
        Expanded(
          child: Text(
            path,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: CcFonts.code(
              textStyle: CcTypography.caption.copyWith(
                color: tokens.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ),
        CcIconButton(
          icon: AppIcons.copy,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.ghost,
          tooltip: l10n.copy,
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: path));
            if (context.mounted) {
              CcToastScope.maybeOf(context)?.show(l10n.copied);
            }
          },
        ),
      ],
    );
  }
}

String? _normalizeSchedule(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return int.tryParse(trimmed) != null ? 'every:$trimmed' : trimmed;
}

Set<String> _statusesFrom(PipelineTrigger trigger) {
  final raw = trigger.match['status'];
  if (raw is List) {
    return {
      for (final value in raw)
        if (value is String) value,
    };
  }
  if (raw is String && raw.isNotEmpty) {
    return {raw};
  }
  return {};
}
