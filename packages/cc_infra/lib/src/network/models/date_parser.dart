/// Parses a date string into a [DateTime].
///
/// Returns `null` if the input is not a non-empty string or cannot be parsed.
DateTime? parseDate(Object? value) {
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}
