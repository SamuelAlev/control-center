/// The kind of governed action an approval gates.
enum ApprovalKind {
  /// Exiting plan mode to begin executing a plan.
  planExit('Plan exit', 'plan_exit'),

  /// Merging a pull request / branch.
  merge('Merge', 'merge'),

  /// Cutting or shipping a release.
  release('Release', 'release'),

  /// Hiring (adding) a new agent.
  hire('Hire', 'hire'),

  /// A custom, caller-defined governed action.
  custom('Custom', 'custom');

  /// Creates an [ApprovalKind] with a display [label] and [storage] key.
  const ApprovalKind(this.label, this.storage);

  /// Human-readable display label.
  final String label;

  /// Storage key persisted in the table.
  final String storage;

  /// Parses a stored value, defaulting to [custom].
  static ApprovalKind fromStorage(String? value) {
    if (value == null) {
      return ApprovalKind.custom;
    }
    return ApprovalKind.values
            .where((k) => k.storage == value || k.name == value)
            .firstOrNull ??
        ApprovalKind.custom;
  }
}
