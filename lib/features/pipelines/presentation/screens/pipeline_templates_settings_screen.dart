import 'package:control_center/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:control_center/features/pipelines/domain/entities/step_kind.dart';
import 'package:control_center/features/pipelines/domain/entities/step_trigger.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Lists every pipeline template stored in the DB for the active workspace.
class PipelineTemplatesSettingsScreen extends ConsumerWidget {
  /// Creates a [PipelineTemplatesSettingsScreen].
  const PipelineTemplatesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.pipelineTemplatesTitle,
        subtitle: l10n.pipelineTemplatesSubtitle,
        child: Center(
          child: Text(
            l10n.pipelinesNoActiveWorkspace,
            style: TextStyle(color: colors.mutedForeground),
          ),
        ),
      );
    }

    final templatesAsync = ref.watch(pipelineTemplatesProvider(workspaceId));

    return PageWrapper(
      title: l10n.pipelineTemplatesTitle,
      subtitle: l10n.pipelineTemplatesSubtitle,
      actions: [
        FButton(
          onPress: () => _createTemplate(context, ref, workspaceId),
          prefix: const Icon(LucideIcons.plus, size: 14),
          size: FButtonSizeVariant.sm,
          variant: FButtonVariant.primary,
          child: Text(l10n.pipelineTemplatesNew),
        ),
      ],
      child: templatesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('$e', style: TextStyle(color: colors.mutedForeground)),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return Center(
              child: Text(
                l10n.pipelineTemplatesEmpty,
                style: TextStyle(color: colors.mutedForeground),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            itemCount: templates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _TemplateTile(template: templates[index]);
            },
          );
        },
      ),
    );
  }

  Future<void> _createTemplate(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController();
    final templateId = await showFDialog<String>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.pipelineTemplatesNew),
        body: FTextField(
          control: FTextFieldControl.managed(controller: controller),
          label: Text(l10n.pipelineTemplateIdLabel),
          hint: 'my_pipeline',
          autofocus: true,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.pop(ctx),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.pop(ctx, controller.text.trim()),
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.create),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (templateId == null || templateId.isEmpty) {
      return;
    }

    final empty = PipelineDefinition(
      templateId: templateId,
      workspaceId: workspaceId,
      name: templateId,
      description: null,
      steps: [
        PipelineStepDefinition(
          id: 'trigger',
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
          config: const PipelineNodeConfig(label: 'Trigger'),
          x: 0,
          y: 0,
        ),
        PipelineStepDefinition(
          id: 'step',
          kind: StepKind.listen,
          bodyKey: 'pipeline.promptAgent',
          triggers: const [StepTrigger(sourceStepIds: ['trigger'])],
          config: const PipelineNodeConfig(
            label: 'Step',
            prompt: 'Describe what this step should do.',
          ),
          x: 240,
          y: 0,
        ),
        PipelineStepDefinition(
          id: 'step\$terminal',
          kind: StepKind.terminal,
          bodyKey: '_terminal_step',
          triggers: const [StepTrigger(sourceStepIds: ['step'])],
        ),
      ],
    );
    await ref.read(pipelineTemplateRepositoryProvider).upsert(empty);
    if (context.mounted) {
      context.go(pipelineTemplateEditorRoute(templateId));
    }
  }
}

class _TemplateTile extends ConsumerWidget {
  const _TemplateTile({required this.template});

  final PipelineDefinition template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    return FCard.raw(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              template.isBuiltIn ? LucideIcons.boxes : LucideIcons.workflow,
              size: 20,
              color: colors.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          template.name,
                          style: TextStyle(
                            color: colors.foreground,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (template.isBuiltIn) ...[
                        const SizedBox(width: 8),
                        FBadge(
                          variant: FBadgeVariant.secondary,
                          child: Text(l10n.pipelineTemplateBuiltInBadge),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.description == null
                        ? template.templateId
                        : '${template.templateId} — ${template.description}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedForeground,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _TemplateTriggerChips(template: template),
                ],
              ),
            ),
            FSwitch(
              value: template.isEnabled,
              onChange: (value) async {
                final repo = ref.read(pipelineTemplateRepositoryProvider);
                final full = await repo.getById(
                  template.workspaceId,
                  template.templateId,
                );
                if (full == null) {
                  return;
                }
                await repo.upsert(
                  PipelineDefinition(
                    templateId: full.templateId,
                    workspaceId: full.workspaceId,
                    name: full.name,
                    description: full.description,
                    steps: full.steps,
                    isBuiltIn: full.isBuiltIn,
                    isEnabled: value,
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            FButton.icon(
              onPress: () =>
                  context.go(pipelineTemplateEditorRoute(template.templateId)),
              variant: FButtonVariant.ghost,
              child: const Icon(LucideIcons.pencil, size: 16),
            ),
            if (!template.isBuiltIn) ...[
              const SizedBox(width: 4),
              FButton.icon(
                onPress: () => _confirmDelete(context, ref),
                variant: FButtonVariant.ghost,
                child: Icon(
                  LucideIcons.trash2,
                  size: 16,
                  color: colors.destructive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final ok = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.pipelineTemplateDeleteConfirmTitle),
        body: Text(l10n.pipelineTemplateDeleteConfirmBody(template.name)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.pop(ctx, false),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.pop(ctx, true),
                  variant: FButtonVariant.destructive,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.delete),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref
          .read(pipelineTemplateRepositoryProvider)
          .deleteById(template.workspaceId, template.templateId);
    }
  }
}

/// Compact, read-only summary of a template's triggers, shown on each template
/// tile so the trigger is visible at a glance. Shows *all* configured triggers
/// — enabled ones filled, disabled ones muted/outlined (with their schedule or
/// match detail) so a configured-but-off trigger (e.g. an opt-in cron) is still
/// discoverable.
class _TemplateTriggerChips extends ConsumerWidget {
  const _TemplateTriggerChips({required this.template});

  final PipelineDefinition template;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colors = context.theme.colors;
    final triggers = ref
            .watch(pipelineTriggersForWorkspaceProvider(template.workspaceId))
            .value
            ?.where((t) => t.templateId == template.templateId)
            .toList() ??
        const [];
    if (triggers.isEmpty) {
      return Text(
        l10n.triggerSummaryNone,
        style: TextStyle(color: colors.mutedForeground, fontSize: 11),
      );
    }
    triggers.sort((a, b) {
      if (a.enabled != b.enabled) {
        return a.enabled ? -1 : 1;
      }
      return a.eventType.compareTo(b.eventType);
    });
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final t in triggers)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.enabled ? colors.secondary : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
              border: t.enabled
                  ? null
                  : Border.all(color: colors.border),
            ),
            child: Text(
              t.enabled
                  ? triggerDetailLabel(l10n, t)
                  : '${triggerDetailLabel(l10n, t)} · ${l10n.triggerDisabledTag}',
              style: TextStyle(
                color: t.enabled ? colors.foreground : colors.mutedForeground,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
