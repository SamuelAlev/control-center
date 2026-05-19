import 'dart:async';
import 'dart:convert';

/// One parsed Server-Sent-Event (`event:` + accumulated `data:` lines + `id:`).
class SseEvent {
  /// Creates an [SseEvent].
  const SseEvent({required this.event, required this.data, this.id});

  /// The event type (defaults to `message` when the stream omits `event:`).
  final String event;

  /// The concatenated `data:` payload (newline-joined per the SSE spec).
  final String data;

  /// The optional `id:` field (used for `Last-Event-ID` resumption).
  final String? id;
}

/// A `StreamTransformer` that turns a raw byte stream into [SseEvent]s,
/// following the WHATWG event-stream framing (fields separated by `\n`, events
/// separated by a blank line). Comment lines (`:`-prefixed, e.g. heartbeats)
/// are ignored.
StreamTransformer<List<int>, SseEvent> sseTransformer() {
  String eventType = 'message';
  final dataLines = <String>[];
  String? lastId;

  return StreamTransformer<List<int>, SseEvent>.fromBind((byteStream) {
    final controller = StreamController<SseEvent>();
    late StreamSubscription<String> sub;

    void dispatch() {
      if (dataLines.isEmpty && eventType == 'message') {
        // Nothing buffered — a stray blank line.
        eventType = 'message';
        return;
      }
      if (dataLines.isNotEmpty || eventType != 'message') {
        controller.add(
          SseEvent(
            event: eventType,
            data: dataLines.join('\n'),
            id: lastId,
          ),
        );
      }
      eventType = 'message';
      dataLines.clear();
    }

    void onLine(String line) {
      if (line.isEmpty) {
        dispatch();
        return;
      }
      if (line.startsWith(':')) {
        return; // comment / heartbeat
      }
      final colon = line.indexOf(':');
      final field = colon == -1 ? line : line.substring(0, colon);
      var value = colon == -1 ? '' : line.substring(colon + 1);
      if (value.startsWith(' ')) {
        value = value.substring(1);
      }
      switch (field) {
        case 'event':
          eventType = value;
        case 'data':
          dataLines.add(value);
        case 'id':
          lastId = value;
        case 'retry':
          break;
      }
    }

    sub = byteStream
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          onLine,
          onError: controller.addError,
          onDone: () {
            dispatch();
            controller.close();
          },
          cancelOnError: false,
        );
    controller.onCancel = sub.cancel;
    return controller.stream;
  });
}
