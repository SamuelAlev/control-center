import 'package:collection/collection.dart';

/// Result returned by a step body closure.
///
/// The engine reads this to decide what to do next: continue, suspend,
/// or terminate.
class StepResult {
  const StepResult._({
    this.mutatedState,
    this.nextRouterKey,
    this.suspendUntilEvent,
    this.suspendUntilTaskIds,
    this.isTerminal = false,
    this.errorMessage,
  });

  /// A normal completion — mutated state is merged into the pipeline state,
  /// and downstream listeners are evaluated.
  ///
  /// [mutatedState] is merged into the pipeline's state map.
  factory StepResult.ok({Map<String, dynamic>? mutatedState}) =>
      StepResult._(mutatedState: mutatedState);

  /// A router completion — [nextRouterKey] selects which downstream branch
  /// to activate. Reserved for Phase 5.
  factory StepResult.route(String nextRouterKey,
          {Map<String, dynamic>? mutatedState}) =>
      StepResult._(mutatedState: mutatedState, nextRouterKey: nextRouterKey);

  /// Suspend the step until a specific domain event type fires.
  /// Reserved for Phase 2+.
  factory StepResult.suspendUntilEvent(String eventType,
          {Map<String, dynamic>? mutatedState}) =>
      StepResult._(
          mutatedState: mutatedState, suspendUntilEvent: eventType);

  /// Suspend the step until all listed tasks reach terminal state.
  /// Reserved for Phase 3 (Tasks layer).
  factory StepResult.suspendUntilTasksComplete(List<String> taskIds,
          {Map<String, dynamic>? mutatedState}) =>
      StepResult._(
          mutatedState: mutatedState, suspendUntilTaskIds: taskIds);

  /// The pipeline has finished — no more steps to run.
  factory StepResult.terminal({Map<String, dynamic>? mutatedState}) =>
      StepResult._(mutatedState: mutatedState, isTerminal: true);

  /// The step failed with [errorMessage].
  factory StepResult.failed(String errorMessage) =>
      StepResult._(errorMessage: errorMessage);

  /// State mutations to merge into the pipeline run's state map.
  final Map<String, dynamic>? mutatedState;

  /// Router key selecting the downstream branch (Phase 5).
  final String? nextRouterKey;

  /// Event type to wait for before resuming (Phase 2+).
  final String? suspendUntilEvent;

  /// Task IDs to wait for before resuming (Phase 3).
  final List<String>? suspendUntilTaskIds;

  /// Whether this result marks the pipeline as complete.
  final bool isTerminal;

  /// Error message for failed steps.
  final String? errorMessage;

  /// Whether this result represents a failure.
  bool get isFailed => errorMessage != null;

  /// Whether this result represents a suspension.
  bool get isSuspended =>
      suspendUntilEvent != null || suspendUntilTaskIds != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StepResult &&
          const DeepCollectionEquality()
              .equals(mutatedState, other.mutatedState) &&
          nextRouterKey == other.nextRouterKey &&
          suspendUntilEvent == other.suspendUntilEvent &&
          const DeepCollectionEquality()
              .equals(suspendUntilTaskIds, other.suspendUntilTaskIds) &&
          isTerminal == other.isTerminal &&
          errorMessage == other.errorMessage;

  @override
  int get hashCode => Object.hash(
        const DeepCollectionEquality().hash(mutatedState),
        nextRouterKey,
        suspendUntilEvent,
        const DeepCollectionEquality().hash(suspendUntilTaskIds),
        isTerminal,
        errorMessage,
      );
}
