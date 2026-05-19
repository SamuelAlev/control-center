import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';

/// Registers step bodies for the seeded `hello` demo template.
void registerHelloBodies(PipelineBodyRegistry registry) {
  registry.registerBody(BuiltInBodyKeys.helloGreet, (ctx) async {
    return StepResult.ok(mutatedState: {
      'greeting': 'Hello from pipeline ${ctx.pipelineRunId}!',
    });
  });

  registry.registerBody(BuiltInBodyKeys.helloWorld, (ctx) async {
    final greeting = ctx.state['greeting'] as String? ?? 'Hello';
    return StepResult.ok(mutatedState: {
      'message': '$greeting The pipeline engine is working.',
    });
  });
}
