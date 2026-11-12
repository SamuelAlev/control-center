/// The kind of a row in the hash-chained guard audit
/// (`guard_decisions.kind`, `GuardDecision.kind`).
enum GuardDecisionKind {
  /// A recorded verdict.
  decision,

  /// The marker export-then-truncate writes in place of a removed segment.
  checkpoint;

  /// Stable storage string.
  String get wire => name;

  /// The value stored as [value]; throws [ArgumentError] for any other
  /// string, so a writer cannot store a value the column refuses.
  static GuardDecisionKind parse(String value) => values.firstWhere(
    (v) => v.wire == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'not a GuardDecisionKind'),
  );
}
