/// An identifier that may appear in analytics only in pseudonymized form.
///
/// Wrap every entity ID (workspace, space, conversation, agent, run, user,
/// device) in an [AnalyticsId] before putting it in an event property.
/// `Analytics` replaces it with a keyed hash under the install's pseudonym
/// salt, so the same workspace always reports the same value (events stay
/// joinable and countable) while the raw ID never leaves the install. A bare
/// ID-shaped string is rejected by `AnalyticsPropertyPolicy`, which is what
/// makes forgetting the wrapper fail closed rather than leak.
class AnalyticsId {
  /// Wraps [raw]. Throws [ArgumentError] when [raw] is empty.
  AnalyticsId(this.raw) {
    if (raw.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'must not be empty');
    }
  }

  /// Wraps [raw], or returns null when it is null or empty, so optional IDs
  /// read as "absent" instead of throwing.
  static AnalyticsId? maybe(String? raw) =>
      raw == null || raw.isEmpty ? null : AnalyticsId(raw);

  /// The unhashed identifier. Never sent.
  final String raw;

  @override
  bool operator ==(Object other) => other is AnalyticsId && other.raw == raw;

  @override
  int get hashCode => raw.hashCode;

  // Deliberately opaque: interpolating an AnalyticsId into a log line or a
  // string property must not print the raw ID.
  @override
  String toString() => 'AnalyticsId(<redacted>)';
}
