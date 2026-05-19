/// Json content extractor.
class JsonContentExtractor {
  /// Creates a new [JsonContentExtractor].
  const JsonContentExtractor();

  /// Extract content.
  String extractContent({required String content, Map<String, dynamic>? metadata}) {
    if (content.isNotEmpty) {
      return content;
    }

    if (metadata == null) {
      return '';
    }

    final text = findTextInMap(metadata);
    if (text.isNotEmpty) {
      return text;
    }

    final result = metadata['result'];
    if (result is String && result.isNotEmpty) {
      return result;
    }

    return '';
  }

  /// Find text in map.
  String findTextInMap(Map<String, dynamic> map) {
    for (final key in ['text', 'content', 'message', 'result']) {
      final val = map[key];
      if (val is String && val.isNotEmpty) {
        return val;
      }
    }

    for (final value in map.values) {
      if (value is List) {
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final found = findTextInMap(item);
            if (found.isNotEmpty) {
              return found;
            }
          } else if (item is String && item.isNotEmpty) {
            return item;
          }
        }
      } else if (value is Map<String, dynamic>) {
        final found = findTextInMap(value);
        if (found.isNotEmpty) {
          return found;
        }
      }
    }

    return '';
  }
}

