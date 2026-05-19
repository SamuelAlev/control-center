import 'package:control_center/features/pipelines/domain/entities/step_kind.dart' show StepKind;
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers the no-op body for [StepKind.trigger] entry nodes.
///
/// A trigger node carries no work — it exists so every pipeline has a single,
/// explicit entry that declares *what starts it* (manual / event / schedule,
/// tracked as `PipelineTrigger` rows). The body completes immediately so the
/// engine fans out to the trigger's downstream listeners with the run's
/// trigger payload already in state.
void registerTriggerBody(PipelineBodyRegistry registry) {
  registry.registerBody(
    BuiltInBodyKeys.trigger,
    (ctx) async => StepResult.ok(),
  );
}
