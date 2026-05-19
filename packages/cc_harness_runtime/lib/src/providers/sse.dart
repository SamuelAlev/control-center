import 'dart:async';
import 'dart:convert';

/// A single parsed Server-Sent Event.
class SseMessage {
  /// Creates an SSE message.
  const SseMessage({required this.event, required this.data});

  /// The `event:` field, or null when the stream only sends `data:` lines
  /// (as OpenAI-style chat completions do).
  final String? event;

  /// The concatenated `data:` payload (multiple `data:` lines joined by `\n`).
  final String data;
}

/// Parses a byte stream of `text/event-stream` framing into [SseMessage]s.
///
/// Handles UTF-8 decoding, `\n` / `\r\n` line endings, comment lines (`:`),
/// multi-line `data:` payloads, and blank-line event dispatch. Trailing buffered
/// data without a final blank line is flushed when the stream closes.
Stream<SseMessage> parseSse(Stream<List<int>> bytes) {
  final controller = StreamController<SseMessage>();
  String? event;
  final dataLines = <String>[];
  var sawData = false;

  void dispatch() {
    if (!sawData) {
      event = null;
      dataLines.clear();
      return;
    }
    controller.add(SseMessage(event: event, data: dataLines.join('\n')));
    event = null;
    dataLines.clear();
    sawData = false;
  }

  void handleLine(String line) {
    if (line.isEmpty) {
      dispatch();
      return;
    }
    if (line.startsWith(':')) {
      // Comment / keep-alive line.
      return;
    }
    final colon = line.indexOf(':');
    final String field;
    String value;
    if (colon == -1) {
      field = line;
      value = '';
    } else {
      field = line.substring(0, colon);
      value = line.substring(colon + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
    }
    switch (field) {
      case 'event':
        event = value;
      case 'data':
        dataLines.add(value);
        sawData = true;
      default:
        // Ignore id / retry / unknown fields.
        break;
    }
  }

  late final StreamSubscription<String> sub;
  sub = bytes
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(
        handleLine,
        onError: controller.addError,
        onDone: () {
          // Flush any buffered, un-dispatched event (no trailing blank line).
          dispatch();
          controller.close();
        },
        cancelOnError: true,
      );

  controller.onCancel = sub.cancel;
  return controller.stream;
}
