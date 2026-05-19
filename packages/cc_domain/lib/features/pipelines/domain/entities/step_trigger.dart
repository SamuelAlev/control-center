import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart' show StepKind;
import 'package:collection/collection.dart';

/// Describes when a step should fire, relative to its source steps.
///
/// All sources in [sourceStepIds] must complete before the step fires.
///
/// When [routeKey] is non-null the edge is *conditional*: the step only
/// fires if the (single) source step is a [StepKind.router] that selected
/// this exact key via `StepResult.route(key)`. Non-selected branches are
/// marked skipped. A null [routeKey] is an unconditional edge.
class StepTrigger {
  /// Creates a [StepTrigger].
  const StepTrigger({
    required this.sourceStepIds,
    this.routeKey,
  });

  /// Step IDs that must reach terminal state before this step fires.
  final List<String> sourceStepIds;

  /// Optional router branch label. When set, this edge only activates if the
  /// upstream router chose this key. Null means an unconditional edge.
  final String? routeKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepTrigger &&
          const DeepCollectionEquality()
              .equals(sourceStepIds, other.sourceStepIds) &&
          routeKey == other.routeKey;

  @override
  int get hashCode => Object.hash(
        const DeepCollectionEquality().hash(sourceStepIds),
        routeKey,
      );
}
