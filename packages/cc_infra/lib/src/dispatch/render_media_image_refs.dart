import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Extracts only durable render_media refs, never image bytes or arbitrary tool text.
List<ToolImageRef> renderMediaImageRefs(String? toolName, Object? content) {
  if (toolName != 'render_media' &&
      toolName != 'mcp__control-center__render_media') {
    return const [];
  }
  final texts = content is List
      ? content
            .whereType<Map>()
            .where((piece) => piece['type'] == 'text')
            .map((piece) => piece['text'])
            .whereType<String>()
      : content is String
      ? [content]
      : const <String>[];
  for (final text in texts) {
    try {
      final data = jsonDecode(text);
      if (data is! Map || data['images'] is! List) {
        continue;
      }
      return [
        for (final item in data['images'] as List)
          if (item is Map<String, dynamic>) ?ToolImageRef.fromJson(item),
      ];
    } on FormatException {
      continue;
    } on TypeError {
      continue;
    }
  }
  return const [];
}
