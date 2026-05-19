/// Validates a value against a JSON-Schema-subset declaration.
///
/// A shared-kernel port so ticketing, dispatch, and pipelines all validate
/// structured agent output against the same implementation. Implemented in the
/// infrastructure layer so the domain stays free of any concrete schema
/// library.
abstract interface class SchemaValidatorPort {
  /// Returns a list of human-readable violation messages, or an empty list if
  /// [value] satisfies [schema]. Never throws on a malformed schema — it
  /// returns a single violation describing the problem instead.
  List<String> validate(Object? value, Map<String, dynamic> schema);

  /// Validates the schema *document itself* — unknown `type` values, non-map
  /// `properties`, non-list `required`, malformed nested schemas. Used at
  /// template-save time and when a hand-authored ticket declares an
  /// `expectedOutputSchema`, so a malformed contract is rejected loudly
  /// instead of silently validating nothing.
  ///
  /// Returns a list of human-readable problems, or empty if the schema is
  /// well-formed.
  List<String> validateSchema(Map<String, dynamic> schema);
}
