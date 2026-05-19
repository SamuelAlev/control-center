/// The kind of artifact a work product holds.
enum WorkProductType {
  /// A plan (e.g. a plan-mode artifact).
  plan('Plan'),

  /// A free-form document.
  document('Document'),

  /// A code diff / patch.
  diff('Diff'),

  /// A report or summary.
  report('Report'),

  /// A short note.
  note('Note');

  /// Creates a [WorkProductType] with a display [label].
  const WorkProductType(this.label);

  /// Human-readable display label.
  final String label;

  /// Parses a stored value (case-insensitive), defaulting to [document].
  static WorkProductType fromStorage(String? value) {
    if (value == null) {
      return WorkProductType.document;
    }
    return WorkProductType.values
            .where((t) => t.name.toLowerCase() == value.toLowerCase())
            .firstOrNull ??
        WorkProductType.document;
  }
}
