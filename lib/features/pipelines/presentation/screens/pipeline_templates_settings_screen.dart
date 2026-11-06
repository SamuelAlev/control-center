import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_start.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_template_list.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

/// Lists every pipeline template stored in the DB for the active workspace.
class PipelineTemplatesSettingsScreen extends ConsumerWidget {
  /// Creates a [PipelineTemplatesSettingsScreen].
  const PipelineTemplatesSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.pipelineTemplatesTitle,
        subtitle: l10n.pipelineTemplatesSubtitle,
        child: Center(
          child: Text(
            l10n.pipelinesNoActiveWorkspace,
            style: TextStyle(color: ds.textTertiary),
          ),
        ),
      );
    }

    final templatesAsync = ref.watch(pipelineTemplatesProvider(workspaceId));

    return PageWrapper(
      title: l10n.pipelineTemplatesTitle,
      subtitle: l10n.pipelineTemplatesSubtitle,
      actions: [
        CcButton(
          onPressed: () => _createTemplate(context, ref, workspaceId),
          icon: AppIcons.plus,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.primary,
          child: Text(l10n.pipelineTemplatesNew),
        ),
      ],
      child: PipelineTemplateList(templates: templatesAsync),
    );
  }

  Future<void> _createTemplate(
    BuildContext context,
    WidgetRef ref,
    String workspaceId,
  ) async {
    final l10n = AppLocalizations.of(context);
    final loaded = ref
        .read(pipelineTemplatesProvider(workspaceId))
        .asData
        ?.value;
    final templateId = _allocatePipelineTemplateId(
      loaded?.map((t) => t.templateId),
    );

    final triggerId = const Uuid().v4();

    final empty = PipelineDefinition(
      templateId: templateId,
      workspaceId: workspaceId,
      name: l10n.pipelineNewDefaultName,
      description: null,
      steps: [
        PipelineStepDefinition(
          id: triggerId,
          kind: StepKind.trigger,
          bodyKey: 'pipeline.trigger',
          config: const PipelineNodeConfig(
            extras: {
              kPipelineStartEventTypeKey: PipelineTrigger.manualEventType,
            },
          ),
          x: 0,
          y: 0,
        ),
        PipelineStepDefinition(
          id: r'trigger$terminal',
          kind: StepKind.terminal,
          bodyKey: '_terminal_trigger',
          triggers: [
            StepTrigger(sourceStepIds: [triggerId]),
          ],
        ),
      ],
    );
    await ref.read(pipelineTemplateRepositoryProvider).upsert(empty);
    try {
      await ref
          .read(pipelineTriggerRepositoryProvider)
          .insert(
            PipelineTrigger(
              id: triggerId,
              eventType: PipelineTrigger.manualEventType,
              templateId: templateId,
              workspaceId: workspaceId,
              enabled: true,
            ),
          );
    } on Object {
      // The editor canvas shows an "Add a trigger" ghost tile until a
      // trigger exists; don't block navigation on a failed seed.
    }
    if (context.mounted) {
      context.go(pipelineTemplateEditorRoute(workspaceId, templateId));
    }
  }
}

/// First unused `pipeline_N` id. A timestamp suffix is used only when the
/// list has not loaded yet — guessing `pipeline_1` against an unknown set is
/// how two clicks would collide.
String _allocatePipelineTemplateId(Iterable<String>? existingIds) {
  if (existingIds == null) {
    return 'pipeline_${DateTime.now().millisecondsSinceEpoch}';
  }
  final taken = existingIds.toSet();
  var i = 1;
  var candidate = 'pipeline_$i';
  while (taken.contains(candidate)) {
    i += 1;
    candidate = 'pipeline_$i';
  }
  return candidate;
}
