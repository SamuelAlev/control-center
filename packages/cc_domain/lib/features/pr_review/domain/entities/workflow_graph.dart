/// One job node of a parsed workflow file. [needs] holds upstream job ids.
class WorkflowJobNode {
  /// Creates a [WorkflowJobNode].
  WorkflowJobNode({
    required this.id,
    required this.name,
    this.needs = const [],
  });

  /// Job id (the YAML key under `jobs:`).
  final String id;

  /// Display name (`name:` when present, else the job id).
  final String name;

  /// Upstream job ids this job depends on.
  final List<String> needs;

  @override
  /// Equality comparison.
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkflowJobNode && id == other.id;

  /// Hash code.
  @override
  int get hashCode => id.hashCode;
}

/// Parsed job graph of one workflow run (from its YAML at the head SHA).
class WorkflowGraph {
  /// Creates a [WorkflowGraph].
  WorkflowGraph({required this.name, this.jobs = const []});

  /// Workflow display name (the YAML `name:`).
  final String name;

  /// Job nodes in YAML declaration order.
  final List<WorkflowJobNode> jobs;

  @override
  /// Equality comparison.
  bool operator ==(Object other) =>
      identical(this, other) || other is WorkflowGraph && name == other.name;

  /// Hash code.
  @override
  int get hashCode => name.hashCode;
}
