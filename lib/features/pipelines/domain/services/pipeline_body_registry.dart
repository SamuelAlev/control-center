import 'package:control_center/features/pipelines/domain/entities/pipeline_step_definition.dart' show PipelineStepDefinition;
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart' show PipelineTemplateRepository;
import 'package:control_center/features/pipelines/domain/services/pipeline_context.dart';

/// Maps `bodyKey` strings to step body closures.
///
/// Templates live in the database (see [PipelineTemplateRepository]); only
/// the executable bodies stay in code, registered here at app startup.
/// The engine looks up a step's body by [PipelineStepDefinition.bodyKey].
class PipelineBodyRegistry {
  final Map<String, StepBodyFn> _bodies = {};

  /// Registers a step body closure by [bodyKey].
  void registerBody(String bodyKey, StepBodyFn fn) {
    _bodies[bodyKey] = fn;
  }

  /// Looks up a step body by [bodyKey]. Throws [StateError] if not found.
  StepBodyFn body(String bodyKey) {
    final fn = _bodies[bodyKey];
    if (fn == null) {
      throw StateError('Pipeline body "$bodyKey" not registered');
    }
    return fn;
  }

  /// Whether a body is registered under [bodyKey].
  bool hasBody(String bodyKey) => _bodies.containsKey(bodyKey);

  /// All registered body keys.
  Iterable<String> get bodyKeys => _bodies.keys;
}

/// Signature for a step body closure.
typedef StepBodyFn = Future<StepResult> Function(PipelineContext ctx);
