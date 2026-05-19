import 'dart:convert';

/// A single Server-Sent Event parsed off the Anthropic streaming response.
///
/// Dart port of the upstream relay's `SSEEvent` (src/proxy.ts). [parsed] holds the decoded
/// JSON payload (a `Map`/`List`) when the `data:` line is valid JSON, otherwise
/// `null`.
class SseEvent {
  /// Creates an [SseEvent].
  const SseEvent({this.event, required this.data, this.parsed});

  /// The `event:` field, if present.
  final String? event;

  /// The raw `data:` payload (joined across multiple `data:` lines).
  final String data;

  /// The decoded JSON payload, or `null` when [data] is not valid JSON.
  final Object? parsed;
}

/// Result of [extractSseEvents]: the complete events plus any trailing partial
/// block that should be carried over to the next chunk.
class SseExtractResult {
  /// Creates an [SseExtractResult].
  const SseExtractResult(this.complete, this.remainder);

  /// Complete SSE events parsed out of the buffer.
  final List<SseEvent> complete;

  /// The trailing partial block (no terminating blank line yet).
  final String remainder;
}

/// Extracts complete Server-Sent Event blocks and returns any trailing partial
/// block so callers can parse across arbitrary network chunks.
///
/// Faithful Dart port of the upstream relay's `extractSSEEvents` (src/proxy.ts).
SseExtractResult extractSseEvents(String buffer) {
  final complete = <SseEvent>[];
  final blocks = buffer.split('\n\n');
  // `split` always yields at least one element, so removeLast is safe.
  final remainder = blocks.removeLast();

  for (final block in blocks) {
    if (block.trim().isEmpty) {
      continue;
    }
    String? eventType;
    final dataLines = <String>[];
    for (final line in block.split('\n')) {
      if (line.startsWith('event: ')) {
        eventType = line.substring(7).trim();
      } else if (line.startsWith('data: ')) {
        dataLines.add(line.substring(6));
      } else if (line.startsWith('data:')) {
        dataLines.add(line.substring(5));
      }
    }
    if (dataLines.isNotEmpty) {
      final data = dataLines.join('\n');
      Object? parsed;
      try {
        parsed = jsonDecode(data);
      } catch (_) {
        parsed = null;
      }
      complete.add(SseEvent(event: eventType, data: data, parsed: parsed));
    }
  }

  return SseExtractResult(complete, remainder);
}
