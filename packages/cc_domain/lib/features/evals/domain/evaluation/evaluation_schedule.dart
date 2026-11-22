import 'dart:math' as math;

import 'package:cc_domain/features/evals/domain/evaluation/evaluation_plan.dart';
import 'package:cc_domain/features/evals/domain/evaluation/evaluation_task.dart';

/// One scheduled trial: which task, which arm, in which stratum, at which
/// repetition, with which derived repeat seed.
class EvaluationTrial {
  /// Creates an [EvaluationTrial].
  const EvaluationTrial({
    required this.ordinal,
    required this.taskId,
    required this.armId,
    required this.stratum,
    required this.repetition,
    required this.seed,
    this.executionMode = EvaluationExecutionMode.live,
  });

  /// Parses from JSON.
  factory EvaluationTrial.fromJson(Map<String, dynamic> json) =>
      EvaluationTrial(
        ordinal: (json['ordinal'] as num?)?.toInt() ?? 0,
        taskId: json['taskId'] as String? ?? '',
        armId: json['armId'] as String? ?? '',
        stratum: CacheStratum.fromWire(json['stratum'] as String?),
        repetition: (json['repetition'] as num?)?.toInt() ?? 0,
        seed: (json['seed'] as num?)?.toInt() ?? 0,
        executionMode: EvaluationExecutionMode.fromWire(
          json['executionMode'] as String?,
        ),
      );

  /// Position in the randomized execution order.
  final int ordinal;

  /// The task to run.
  final String taskId;

  /// The arm to run it under.
  final String armId;

  /// The cache stratum this trial belongs to.
  final CacheStratum stratum;

  /// Repetition index within (task, arm, stratum).
  final int repetition;

  /// The derived repeat seed handed to the backend.
  final int seed;

  /// Whether this trial is live or a replay.
  final EvaluationExecutionMode executionMode;

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'ordinal': ordinal,
    'taskId': taskId,
    'armId': armId,
    'stratum': stratum.wire,
    'repetition': repetition,
    'seed': seed,
    'executionMode': executionMode.wire,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EvaluationTrial &&
          ordinal == other.ordinal &&
          taskId == other.taskId &&
          armId == other.armId &&
          stratum == other.stratum &&
          repetition == other.repetition &&
          seed == other.seed &&
          executionMode == other.executionMode;

  @override
  int get hashCode => Object.hash(
    ordinal,
    taskId,
    armId,
    stratum,
    repetition,
    seed,
    executionMode,
  );
}

/// The order a plan's trials run in.
extension EvaluationPlanSchedule on EvaluationPlan {
  /// The deterministic, seeded trial schedule for [tasks].
  ///
  /// Task-blocked: the tasks run in a seeded order, and each task runs every
  /// repetition of every arm (cold before warm) before the next task starts.
  /// Within a repetition the arms run adjacently, the first arm of a seeded
  /// order rotating each repetition, so neither arm always runs first. A spend
  /// ceiling therefore stops at a task boundary, wasting at most one block,
  /// and the tasks that ran are a random subset.
  ///
  /// A plan with a post-idle stratum keeps the global order (strata cold →
  /// warm → post-idle, trials shuffled inside each), because idling between
  /// every block would cost hours; it is analysed only when complete.
  List<EvaluationTrial> schedule(
    List<EvaluationTask> tasks, {
    EvaluationExecutionMode executionMode = EvaluationExecutionMode.live,
  }) {
    final ordered = <EvaluationTrial>[];
    EvaluationTrial trial(
      EvaluationTask task,
      EvaluationArm arm,
      StratumSpec spec,
      int rep,
    ) => EvaluationTrial(
      ordinal: ordered.length,
      taskId: task.id,
      armId: arm.id,
      stratum: spec.stratum,
      repetition: rep,
      seed: _deriveSeed(seed, task.id, arm.id, spec, rep),
      executionMode: executionMode,
    );
    if (hasPostIdleStratum) {
      for (var s = 0; s < strata.length; s++) {
        final spec = strata[s];
        final bucket = <(EvaluationTask, EvaluationArm, int)>[
          for (final task in tasks)
            for (final arm in arms)
              for (var rep = 0; rep < spec.repetitions; rep++) (task, arm, rep),
        ];
        if (randomizedOrder) {
          bucket.shuffle(math.Random(_mix(seed ^ (s * 0x9e3779b1))));
        }
        for (final (task, arm, rep) in bucket) {
          ordered.add(trial(task, arm, spec, rep));
        }
      }
      return ordered;
    }
    final taskOrder = [...tasks];
    if (randomizedOrder) {
      taskOrder.shuffle(math.Random(_mix(seed ^ 0x7f4a7c15)));
    }
    final ordinalStrata = [...strata]
      ..sort((a, b) => a.stratum.index.compareTo(b.stratum.index));
    for (final task in taskOrder) {
      final armOrder = [...arms];
      if (randomizedOrder) {
        var h = _mix(seed ^ 0x2545f491);
        for (final unit in task.id.codeUnits) {
          h = _mix(h ^ unit);
        }
        armOrder.shuffle(math.Random(h));
      }
      var block = 0;
      for (final spec in ordinalStrata) {
        for (var rep = 0; rep < spec.repetitions; rep++) {
          for (var i = 0; i < armOrder.length; i++) {
            final arm = armOrder[(i + block) % armOrder.length];
            ordered.add(trial(task, arm, spec, rep));
          }
          block++;
        }
      }
    }
    return ordered;
  }

  /// A per-trial seed derived from the campaign seed and the trial identity,
  /// so the seed is stable no matter what order the schedule is executed in.
  static int _deriveSeed(
    int seed,
    String taskId,
    String armId,
    StratumSpec spec,
    int repetition,
  ) {
    var h = _mix(seed);
    for (final unit in taskId.codeUnits) {
      h = _mix(h ^ unit);
    }
    for (final unit in armId.codeUnits) {
      h = _mix(h ^ (unit + 0x9e37));
    }
    h = _mix(h ^ spec.stratum.index + 0x85eb);
    return _mix(h ^ repetition) & 0x7fffffff;
  }

  /// A small deterministic integer mixer (the murmur3 finalizer).
  static int _mix(int value) {
    var h = value & 0xffffffff;
    h ^= h >> 16;
    h = (h * 0x85ebca6b) & 0xffffffff;
    h ^= h >> 13;
    h = (h * 0xc2b2ae35) & 0xffffffff;
    h ^= h >> 16;
    return h & 0x7fffffff;
  }
}
