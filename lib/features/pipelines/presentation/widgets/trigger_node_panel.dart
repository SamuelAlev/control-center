import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart' show StepKind;
import 'package:control_center/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:control_center/features/pipelines/domain/services/event_payload_mapper.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:uuid/uuid.dart';

/// Side panel shown in the template editor when the [StepKind.trigger] entry
/// node is selected. Lists and edits the pipeline's `PipelineTrigger` rows —
/// the source of truth for what starts it: a manual run, domain events (with
/// an optional payload filter), or a schedule.
class TriggerNodePanel extends ConsumerWidget {
  /// Creates a [TriggerNodePanel].
  const TriggerNodePanel({
    super.key,
    required this.workspaceId,
    required this.templateId,
  });

  /// Workspace the template belongs to.
  final String workspaceId;

  /// Template whose triggers are edited.
  final String templateId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final triggersAsync =
        ref.watch(pipelineTriggersForWorkspaceProvider(workspaceId));
    final all = triggersAsync.value
            ?.where((t) => t.templateId == templateId)
            .toList() ??
        const <PipelineTrigger>[];
    final manual = all.firstWhereOrNull(
      (t) => t.eventType == PipelineTrigger.manualEventType,
    );
    final autos = all
        .where((t) => t.eventType != PipelineTrigger.manualEventType)
        .toList()
      ..sort((a, b) => a.eventType.compareTo(b.eventType));
    final repo = ref.read(pipelineTriggerRepositoryProvider);

    return Container(
      color: colors.background,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(LucideIcons.zap, size: 16, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                l10n.triggerPanelTitle,
                style: TextStyle(
                  color: colors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            l10n.triggerPanelHelp,
            style: TextStyle(color: colors.mutedForeground, fontSize: 12),
          ),
          const SizedBox(height: 16),
          // ── Manual run ────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FSwitch(
                value: manual?.enabled ?? false,
                onChange: (allow) =>
                    _setManual(repo, ref, manual, allow: allow),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.triggerEventManual,
                      style: TextStyle(
                        color: colors.foreground,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      l10n.triggerManualHelp,
                      style: TextStyle(
                        color: colors.mutedForeground,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          // ── Automatic triggers ────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.triggerSectionAutomatic,
                  style: TextStyle(
                    color: colors.foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              FButton(
                onPress: () => _showAddDialog(context, ref, autos),
                size: FButtonSizeVariant.sm,
                variant: FButtonVariant.outline,
                prefix: const Icon(LucideIcons.plus, size: 14),
                child: Text(l10n.triggerAddButton),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (autos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.triggerNoneYet,
                style: TextStyle(color: colors.mutedForeground, fontSize: 13),
              ),
            )
          else
            for (final trigger in autos)
              _TriggerRow(
                trigger: trigger,
                onToggle: (v) => repo.update(trigger.copyWith(enabled: v)),
                onDelete: () => repo.deleteById(trigger.id),
              ),
        ],
      ),
    );
  }

  Future<void> _setManual(
    PipelineTriggerRepository repo,
    WidgetRef ref,
    PipelineTrigger? manual, {
    required bool allow,
  }) async {
    if (allow) {
      if (manual == null) {
        await repo.insert(PipelineTrigger(
          id: const Uuid().v4(),
          eventType: PipelineTrigger.manualEventType,
          templateId: templateId,
          workspaceId: workspaceId,
          enabled: true,
        ));
      } else if (!manual.enabled) {
        await repo.update(manual.copyWith(enabled: true));
      }
    } else if (manual != null) {
      await repo.deleteById(manual.id);
    }
  }

  Future<void> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    List<PipelineTrigger> existing,
  ) async {
    final spec = await showFDialog<_NewTriggerSpec>(
      context: context,
      builder: (ctx, style, animation) => _AddTriggerDialog(
        style: style,
        animation: animation,
        existingEventTypes:
            existing.map((t) => t.eventType).toSet(),
      ),
    );
    if (spec == null) {
      return;
    }
    await ref.read(pipelineTriggerRepositoryProvider).insert(PipelineTrigger(
          id: const Uuid().v4(),
          eventType: spec.eventType,
          templateId: templateId,
          workspaceId: workspaceId,
          enabled: true,
          cronExpression: spec.cronExpression,
          match: spec.match,
        ));
  }
}

class _TriggerRow extends StatelessWidget {
  const _TriggerRow({
    required this.trigger,
    required this.onToggle,
    required this.onDelete,
  });

  final PipelineTrigger trigger;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          FSwitch(value: trigger.enabled, onChange: onToggle),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              triggerDetailLabel(l10n, trigger),
              style: TextStyle(color: colors.foreground, fontSize: 13),
            ),
          ),
          FButton.icon(
            onPress: onDelete,
            variant: FButtonVariant.ghost,
            child: Icon(LucideIcons.trash2, size: 14, color: colors.destructive),
          ),
        ],
      ),
    );
  }
}

/// The result of the add-trigger dialog.
class _NewTriggerSpec {
  const _NewTriggerSpec({
    required this.eventType,
    this.cronExpression,
    this.match = const {},
  });

  final String eventType;
  final String? cronExpression;
  final Map<String, dynamic> match;
}

class _AddTriggerDialog extends StatefulWidget {
  const _AddTriggerDialog({
    required this.style,
    required this.animation,
    required this.existingEventTypes,
  });

  final FDialogStyle style;
  final Animation<double> animation;
  final Set<String> existingEventTypes;

  @override
  State<_AddTriggerDialog> createState() => _AddTriggerDialogState();
}

class _AddTriggerDialogState extends State<_AddTriggerDialog> {
  bool _scheduled = false;
  String? _eventType;
  final _intervalCtrl = TextEditingController(text: '86400');
  // PR status filter (only shown for PullRequestStatusChanged).
  final Set<String> _statuses = {'merged'};

  static const _prStatuses = ['merged', 'closed', 'opened', 'reopened'];

  @override
  void dispose() {
    _intervalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    // Event types selectable here: the real domain events (manual + schedule
    // are handled separately). Hide ones already wired so we don't collide
    // with the unique (template, event) constraint.
    final eventOptions = {
      for (final e in EventPayloadMapper.knownEventTypes)
        if (!widget.existingEventTypes.contains(e))
          triggerEventLabel(l10n, e): e,
    };
    final isPrStatus = _eventType == 'PullRequestStatusChanged';

    return FDialog(
      style: widget.style,
      animation: widget.animation,
      title: Text(l10n.triggerAddDialogTitle),
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 420),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Kind: event vs schedule.
              FSelect<bool>(
                items: {
                  l10n.triggerKindEvent: false,
                  l10n.triggerKindSchedule: true,
                },
                label: Text(l10n.triggerKindLabel),
                control: FSelectControl<bool>.lifted(
                  value: _scheduled,
                  onChange: (v) => setState(() => _scheduled = v ?? false),
                ),
              ),
              const SizedBox(height: 12),
              if (_scheduled)
                FTextField(
                  control:
                      FTextFieldControl.managed(controller: _intervalCtrl),
                  label: Text(l10n.triggerIntervalLabel),
                  hint: '86400',
                  keyboardType: TextInputType.number,
                  size: FTextFieldSizeVariant.sm,
                )
              else ...[
                if (eventOptions.isEmpty)
                  Text(
                    l10n.triggerNoMoreEvents,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 13,
                    ),
                  )
                else
                  FSelect<String>(
                    items: eventOptions,
                    label: Text(l10n.triggerEventFieldLabel),
                    control: FSelectControl<String>.lifted(
                      value: _eventType,
                      onChange: (v) => setState(() => _eventType = v),
                    ),
                  ),
                if (isPrStatus) ...[
                  const SizedBox(height: 12),
                  Text(
                    l10n.triggerMatchStatusLabel,
                    style: TextStyle(color: colors.foreground, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final s in _prStatuses)
                        _StatusChip(
                          label: s,
                          selected: _statuses.contains(s),
                          onTap: () => setState(() {
                            if (!_statuses.add(s)) {
                              _statuses.remove(s);
                            }
                          }),
                        ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FButton(
                onPress: () => Navigator.pop(context),
                variant: FButtonVariant.outline,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 8),
              FButton(
                onPress: _canSubmit ? () => Navigator.pop(context, _build()) : null,
                mainAxisSize: MainAxisSize.min,
                child: Text(l10n.add),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool get _canSubmit {
    if (_scheduled) {
      return int.tryParse(_intervalCtrl.text.trim()) != null;
    }
    return _eventType != null;
  }

  _NewTriggerSpec _build() {
    if (_scheduled) {
      final secs = int.tryParse(_intervalCtrl.text.trim()) ?? 86400;
      return _NewTriggerSpec(
        eventType: PipelineTrigger.scheduleEventType,
        cronExpression: 'every:$secs',
      );
    }
    final match = (_eventType == 'PullRequestStatusChanged' &&
            _statuses.isNotEmpty)
        ? <String, dynamic>{'status': _statuses.toList()}
        : const <String, dynamic>{};
    return _NewTriggerSpec(eventType: _eventType!, match: match);
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.primary : colors.background,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? colors.primary : colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? colors.primaryForeground : colors.foreground,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
