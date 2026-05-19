/// Value objects and validation for batch agent spawning.
///
/// A single dispatch call can spawn one subagent per [TaskItem] in a
/// [BatchSpawn], all sharing one [BatchSpawn.context]. The two wire shapes are
/// modelled as a sealed [SpawnRequest] hierarchy so they are mutually
/// exclusive: a request is either a [FlatSpawn] (one assignment) or a
/// [BatchSpawn] (many tasks under a shared context), never a mix of both.
///
/// Mirrors oh-my-pi's `task/types.ts` `taskSchemaBatch` validation: the batch
/// schema requires a shared `context`, requires every task to carry a non-empty
/// `assignment`, and rejects a top-level flat `assignment` alongside the batch.
library;

/// A single unit of work in a [BatchSpawn]: one subagent runs one [assignment].
///
/// Fields here are required (unlike the streaming-tolerant wire schema) because
/// a [TaskItem] is the validated, in-memory shape after parsing — by the time
/// one exists it must be complete.
class TaskItem {
  /// Creates a [TaskItem].
  ///
  /// Both [id] and [assignment] must be non-empty once trimmed; [isolated]
  /// defaults to `false` (the spawn runs in the shared worktree).
  TaskItem({
    required this.id,
    required this.assignment,
    this.role,
    this.isolated = false,
  })  : assert(id.trim().isNotEmpty, 'TaskItem.id must not be empty'),
        assert(
          assignment.trim().isNotEmpty,
          'TaskItem.assignment must not be empty',
        );

  /// Stable agent id for this spawn. Unique within a [BatchSpawn].
  final String id;

  /// Specialist role/expertise this subagent embodies; shapes its
  /// system-prompt identity and roster display name. `null` falls back to the
  /// agent type's name.
  final String? role;

  /// The work this subagent is assigned. Required and non-empty.
  final String assignment;

  /// Whether this spawn runs in its own copy-on-write worktree.
  final bool isolated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          assignment == other.assignment &&
          isolated == other.isolated;

  @override
  int get hashCode => Object.hash(id, role, assignment, isolated);

  @override
  String toString() =>
      'TaskItem($id${role == null ? '' : ', role=$role'}, '
      'isolated=$isolated)';
}

/// A request to spawn one or more subagents.
///
/// Sealed so callers exhaustively handle exactly the two mutually exclusive
/// wire shapes: a [FlatSpawn] (a single assignment, optionally isolated) or a
/// [BatchSpawn] (many [TaskItem]s under one shared context). The shapes can
/// never be combined — there is no representation that carries both a flat
/// `assignment` and a `tasks` list, which is how the "no flat assignment
/// alongside a batch" rule is enforced structurally.
sealed class SpawnRequest {
  /// Const base constructor for the sealed hierarchy.
  const SpawnRequest();
}

/// The flat spawn shape: one subagent, one [assignment].
class FlatSpawn extends SpawnRequest {
  /// Creates a [FlatSpawn].
  const FlatSpawn({
    required this.assignment,
    this.id,
    this.role,
    this.isolated = false,
  });

  /// Stable agent id; `null` lets the dispatcher generate one.
  final String? id;

  /// Specialist role/expertise this subagent embodies; `null` falls back to
  /// the agent type's name.
  final String? role;

  /// The work this subagent is assigned.
  final String assignment;

  /// Whether this spawn runs in its own copy-on-write worktree.
  final bool isolated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FlatSpawn &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          role == other.role &&
          assignment == other.assignment &&
          isolated == other.isolated;

  @override
  int get hashCode => Object.hash(id, role, assignment, isolated);

  @override
  String toString() => 'FlatSpawn(${id ?? '<auto>'}, isolated=$isolated)';
}

/// The batch spawn shape: one subagent per [tasks] item, all sharing
/// [context].
///
/// The batch schema *requires* a non-empty shared [context] (prepended to
/// every task assignment) and a non-empty [tasks] list. Because [BatchSpawn]
/// has no flat `assignment` field, a batch can never smuggle a top-level
/// assignment alongside its tasks.
class BatchSpawn extends SpawnRequest {
  /// Creates a [BatchSpawn].
  const BatchSpawn({
    required this.context,
    required this.tasks,
  });

  /// Shared background prepended to every task's assignment. Required and
  /// non-empty by the batch schema.
  final String context;

  /// One [TaskItem] per subagent to spawn. Must be non-empty.
  final List<TaskItem> tasks;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    if (other is! BatchSpawn || runtimeType != other.runtimeType) {
      return false;
    }
    if (context != other.context || tasks.length != other.tasks.length) {
      return false;
    }
    for (var i = 0; i < tasks.length; i++) {
      if (tasks[i] != other.tasks[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(context, Object.hashAll(tasks));

  @override
  String toString() => 'BatchSpawn(${tasks.length} tasks)';
}

/// The result of validating a [SpawnRequest].
///
/// Carries every problem found (validation does not stop at the first error)
/// so a caller can report them all at once. An empty [errors] list means the
/// request is structurally valid.
class SpawnValidation {
  /// Creates a [SpawnValidation] from the given [errors].
  const SpawnValidation(this.errors);

  /// A valid result with no errors.
  const SpawnValidation.valid() : errors = const <String>[];

  /// Human-readable problems found during validation. Empty when valid.
  final List<String> errors;

  /// Whether the validated request is structurally sound.
  bool get isValid => errors.isEmpty;

  @override
  String toString() =>
      isValid ? 'SpawnValidation.valid' : 'SpawnValidation(${errors.join('; ')})';
}

/// Validates a [SpawnRequest], returning every problem found.
///
/// Rules:
///
/// * [FlatSpawn] — [FlatSpawn.assignment] must be non-empty (trimmed).
/// * [BatchSpawn] — [BatchSpawn.tasks] must be non-empty; [BatchSpawn.context]
///   must be non-empty (the batch schema *requires* a shared context); every
///   task's [TaskItem.assignment] must be non-empty; and task [TaskItem.id]s
///   must be unique (each duplicate is reported once).
///
/// Mixing the two shapes is impossible by construction: [SpawnRequest] is
/// sealed and [BatchSpawn] has no flat `assignment` field, so a batch can never
/// carry a top-level flat assignment. That invariant is therefore enforced by
/// the type system rather than re-checked here.
SpawnValidation validateSpawn(SpawnRequest request) {
  final errors = <String>[];
  switch (request) {
    case FlatSpawn(:final assignment):
      if (assignment.trim().isEmpty) {
        errors.add('Flat spawn assignment must not be empty');
      }
    case BatchSpawn(:final context, :final tasks):
      if (context.trim().isEmpty) {
        errors.add('Batch context must not be empty');
      }
      if (tasks.isEmpty) {
        errors.add('Batch must contain at least one task');
      }
      _collectTaskErrors(tasks, errors);
  }
  return SpawnValidation(errors);
}

/// Appends per-task and duplicate-id errors for a batch's [tasks] to [errors].
void _collectTaskErrors(List<TaskItem> tasks, List<String> errors) {
  final seen = <String>{};
  final reportedDuplicates = <String>{};
  for (final task in tasks) {
    if (task.assignment.trim().isEmpty) {
      errors.add('Task ${task.id} assignment must not be empty');
    }
    if (!seen.add(task.id) && reportedDuplicates.add(task.id)) {
      errors.add('Duplicate task id: ${task.id}');
    }
  }
}
