import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';
import 'package:cc_domain/features/evals/domain/evaluation/routing_decision.dart';

/// An OPT-IN, task-boundary routing policy (report 4A + §6).
///
/// The policy is inert unless [enabled] is explicitly set, and even then it
/// may only route *away* from the pinned quality default for task classes the
/// operator enumerated AND whose acceptance evidence is independently
/// checkable. [violations] enumerates every way a policy would silently
/// degrade a user-selected default; the runner refuses to apply a policy that
/// reports any.
class TaskRoutePolicy {
  /// Creates a [TaskRoutePolicy].
  const TaskRoutePolicy({
    required this.id,
    this.version = 1,
    this.enabled = false,
    this.description = '',
    this.optedInBy = '',
    this.byTaskKind = const {},
    this.byTaskId = const {},
    this.defaultDecision = const RoutingDecision(),
    this.allowUncheckedRouting = false,
  });

  /// Parses from JSON.
  factory TaskRoutePolicy.fromJson(Map<String, dynamic> json) =>
      TaskRoutePolicy(
        id: json['id'] as String? ?? '',
        version: (json['version'] as num?)?.toInt() ?? 1,
        enabled: json['enabled'] as bool? ?? false,
        description: json['description'] as String? ?? '',
        optedInBy: json['optedInBy'] as String? ?? '',
        byTaskKind: {
          for (final e
              in (json['byTaskKind'] as Map?)?.entries ??
                  const Iterable<MapEntry<dynamic, dynamic>>.empty())
            EvaluationTaskKind.fromWire('${e.key}'): RoutingDecision.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
        },
        byTaskId: {
          for (final e
              in (json['byTaskId'] as Map?)?.entries ??
                  const Iterable<MapEntry<dynamic, dynamic>>.empty())
            '${e.key}': RoutingDecision.fromJson(
              (e.value as Map).cast<String, dynamic>(),
            ),
        },
        defaultDecision: json['defaultDecision'] == null
            ? const RoutingDecision()
            : RoutingDecision.fromJson(
                (json['defaultDecision'] as Map).cast<String, dynamic>(),
              ),
        allowUncheckedRouting: json['allowUncheckedRouting'] as bool? ?? false,
      );

  /// Stable policy id.
  final String id;

  /// Policy revision — recorded with every routed trial.
  final int version;

  /// Whether the operator explicitly turned routing on. Defaults to false:
  /// an unconfigured policy never routes.
  final bool enabled;

  /// What the policy is for.
  final String description;

  /// Who opted in (an audit string: operator/account).
  final String optedInBy;

  /// Per-task-class routes.
  final Map<EvaluationTaskKind, RoutingDecision> byTaskKind;

  /// Per-task-id routes (win over [byTaskKind]).
  final Map<String, RoutingDecision> byTaskId;

  /// The route for a task with no explicit entry. Kept empty by design: the
  /// default route is the pinned quality default.
  final RoutingDecision defaultDecision;

  /// Whether to allow routing a task whose acceptance evidence is not fully
  /// behavioral. Off by default; turning it on is recorded as a caveat rather
  /// than silently accepted.
  final bool allowUncheckedRouting;

  /// The route for [task], or null to keep the quality default.
  RoutingDecision? decisionFor(EvaluationTask task) {
    if (!enabled) {
      return null;
    }
    final byId = byTaskId[task.id];
    if (byId != null) {
      return byId;
    }
    return byTaskKind[task.kind];
  }

  /// Every way this policy would silently replace the pinned quality default.
  ///
  /// Empty when the policy is inert, or when it only routes task classes the
  /// operator enumerated whose evidence is independently checkable.
  List<String> violations({
    required List<EvaluationTask> tasks,
    required List<EvaluationArm> arms,
  }) {
    final problems = <String>[];
    if (!enabled) {
      return problems;
    }
    if (optedInBy.trim().isEmpty) {
      problems.add(
        'policy "$id" is enabled without an opt-in record (optedInBy)',
      );
    }
    if (byTaskKind.isEmpty && byTaskId.isEmpty) {
      problems.add('policy "$id" is enabled but routes nothing');
    }
    if (arms.where((a) => a.isBaseline).isEmpty) {
      problems.add(
        'policy "$id" has no baseline arm, so non-inferiority cannot be '
        'established',
      );
    }
    for (final task in tasks) {
      final decision = decisionFor(task);
      if (decision == null) {
        continue;
      }
      if (!task.independentlyCheckable && !allowUncheckedRouting) {
        problems.add(
          'policy "$id" routes task "${task.id}" (${task.kind.wire}) whose '
          'acceptance evidence is not fully behavioral',
        );
      }
      if ((decision.modelId == null || decision.modelId!.trim().isEmpty) &&
          (decision.effortLevel == null ||
              decision.effortLevel!.trim().isEmpty) &&
          decision.note.trim().isEmpty) {
        problems.add('policy "$id" has an empty route for task "${task.id}"');
      }
    }
    return problems;
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'version': version,
    'enabled': enabled,
    if (description.isNotEmpty) 'description': description,
    if (optedInBy.isNotEmpty) 'optedInBy': optedInBy,
    if (byTaskKind.isNotEmpty)
      'byTaskKind': {
        for (final e in byTaskKind.entries) e.key.wire: e.value.toJson(),
      },
    if (byTaskId.isNotEmpty)
      'byTaskId': {for (final e in byTaskId.entries) e.key: e.value.toJson()},
    if (defaultDecision != const RoutingDecision())
      'defaultDecision': defaultDecision.toJson(),
    if (allowUncheckedRouting) 'allowUncheckedRouting': true,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskRoutePolicy &&
          id == other.id &&
          version == other.version &&
          enabled == other.enabled &&
          description == other.description &&
          optedInBy == other.optedInBy &&
          defaultDecision == other.defaultDecision &&
          allowUncheckedRouting == other.allowUncheckedRouting &&
          _mapEq(byTaskKind, other.byTaskKind) &&
          _mapEq(byTaskId, other.byTaskId);

  @override
  int get hashCode => Object.hash(
    id,
    version,
    enabled,
    description,
    optedInBy,
    defaultDecision,
    allowUncheckedRouting,
    byTaskKind.length,
    byTaskId.length,
  );
}

bool _mapEq(Map<Object?, Object?> a, Map<Object?, Object?> b) {
  if (a.length != b.length) {
    return false;
  }
  for (final e in a.entries) {
    if (b[e.key] != e.value) {
      return false;
    }
  }
  return true;
}
