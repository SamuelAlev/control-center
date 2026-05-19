/// Keeps Claude Code's internal API calls out of the relay's public output.
///
/// Dart port of the upstream relay's `message-request-filter.ts`. Claude Code makes a side
/// request to generate a session title; that response must not be surfaced as
/// agent output.
library;

const List<String> _sessionTitlePromptMarkers = [
  'Generate a concise, sentence-case title',
  'Return JSON with a single "title" field',
];

/// Returns whether the `/v1/messages` request body should be observed (teed
/// into the relay's output). Internal title-generation requests are skipped.
bool shouldObserveMessagesRequest(Map<String, Object?> body) {
  return !_isClaudeSessionTitleRequest(body);
}

bool _isClaudeSessionTitleRequest(Map<String, Object?> body) {
  return _hasAnyTextMarker(body['system'], _sessionTitlePromptMarkers) &&
      _hasSingleTitleJsonSchema(body);
}

bool _hasAnyTextMarker(Object? value, List<String> markers) {
  if (value is String) {
    return markers.any(value.contains);
  }
  if (value is List) {
    return value.any((item) => _hasAnyTextMarker(item, markers));
  }
  if (value is Map) {
    return value.values.any((item) => _hasAnyTextMarker(item, markers));
  }
  return false;
}

bool _hasSingleTitleJsonSchema(Object? value) {
  if (value is List) {
    return value.any(_hasSingleTitleJsonSchema);
  }
  if (value is! Map) {
    return false;
  }
  final obj = value.cast<String, Object?>();
  if (obj['type'] == 'json_schema' && _schemaOnlyAllowsTitle(obj['schema'])) {
    return true;
  }
  return obj.values.any(_hasSingleTitleJsonSchema);
}

bool _schemaOnlyAllowsTitle(Object? schema) {
  if (schema is! Map) {
    return false;
  }
  final obj = schema.cast<String, Object?>();
  final properties = obj['properties'];
  if (properties is! Map) {
    return false;
  }
  final propertyNames = properties.keys.toList();
  if (propertyNames.length != 1 || propertyNames.first != 'title') {
    return false;
  }
  final required = obj['required'];
  return required is! List ||
      (required.length == 1 && required.first == 'title');
}
