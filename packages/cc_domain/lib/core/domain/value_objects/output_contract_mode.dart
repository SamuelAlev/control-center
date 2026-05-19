/// How strictly an agent's `submit_output` payload is validated against the
/// run's `expectedOutputSchema`.
///
/// The output contract lives on the agent run (one per pipeline-dispatched
/// agent). Only meaningful when the run declares an `expectedOutputSchema`.
enum OutputContractMode {
  /// The output MUST validate against the schema. A non-conforming payload is
  /// rejected at the `submit_output` boundary (the still-running agent reads
  /// the violation list and re-calls). After a rejection cap the step fails.
  strict,

  /// The output is persisted even when it does not validate; the violations
  /// are recorded for later review.
  permissive;

  /// Parses a stored value. Throws on an unknown value — a corrupt row must be
  /// loud, not silently coerced (entity rule).
  static OutputContractMode fromStorage(String? value) {
    if (value == null) {
      return OutputContractMode.strict;
    }
    return switch (value) {
      'strict' => OutputContractMode.strict,
      'permissive' => OutputContractMode.permissive,
      _ => throw ArgumentError('Unknown output contract mode in storage: "$value"'),
    };
  }

  /// Storage representation.
  String toStorageString() => name;
}
