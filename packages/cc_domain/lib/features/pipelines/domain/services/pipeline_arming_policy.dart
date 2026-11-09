import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart'
    show BuiltInBodyKeys;

/// Step bodies a workspace member may put behind an armed trigger.
///
/// An armed trigger (an enabled event, schedule or webhook trigger) starts its
/// pipeline with **no requester**: nobody pressed run, so the run acts as the
/// workspace's accountable human. Arming one is therefore an admin decision
/// unless every step it can reach is inert in that sense — it routes, waits for
/// a person, posts a notice, or indexes code — and dispatches no agent, runs no
/// shell, deletes nothing and touches no backup. Everything not listed here
/// (`conversation.promptAgent`, `team.dispatch`, `flow.forEach`,
/// `flow.callPipeline`, `messaging.createSpace`, `pipeline.bashScript`,
/// `backup.*`, `repos.cleanup`, the PR-review and skill bodies, …) needs an
/// admin to arm. Deny by default: a body added later is admin-armed until
/// someone decides otherwise here.
const Set<String> kMemberArmableBodyKeys = {
  BuiltInBodyKeys.trigger,
  BuiltInBodyKeys.condition,
  BuiltInBodyKeys.humanGate,
  BuiltInBodyKeys.messagingPostSpace,
  BuiltInBodyKeys.indexCode,
};

/// Whether [template] runs a shell step (`pipeline.bashScript`). Authoring one,
/// or a trigger that points at one, is admin-only regardless of arming.
bool pipelineHasShellStep(PipelineDefinition? template) =>
    template != null &&
    template.steps.any((step) => step.bodyKey == BuiltInBodyKeys.bashScript);

/// Whether arming a trigger on [template] needs a workspace admin: it contains
/// a work step whose body is not in [kMemberArmableBodyKeys].
///
/// Trigger and terminal sentinels do no work and are ignored. A missing
/// template answers `false`; callers reject the trigger for naming no template
/// before they ask.
bool pipelineArmingRequiresAdmin(PipelineDefinition? template) =>
    template != null &&
    template.steps.any(
      (step) =>
          step.kind != StepKind.trigger &&
          step.kind != StepKind.terminal &&
          !kMemberArmableBodyKeys.contains(step.bodyKey),
    );

/// Whether [trigger] fires its pipeline on its own: enabled, and not the
/// `manual` opt-in (a manual run is started by a person, who becomes its
/// requester).
bool pipelineTriggerIsArmed(PipelineTrigger trigger) =>
    trigger.enabled && trigger.eventType != PipelineTrigger.manualEventType;
