import 'dart:async';
import 'dart:convert';

/// Splits [bytes] into lines with a HARD cap on how much of an unterminated
/// line is buffered.
///
/// `LineSplitter` buffers a newline-free stream indefinitely, so one hostile or
/// broken MCP server — an `npx` package printing a multi-megabyte banner with
/// no newline, a binary that writes a core dump to stdout — can OOM the client
/// that merely connected to it. Past [maxLineChars] the oversized line is
/// abandoned (the transport skips to the next newline and resynchronizes) and
/// [onOverflow] is notified once per dropped line.
///
/// Decoding tolerates malformed UTF-8 (`allowMalformed: true`): one bad byte
/// from a chatty child must not tear down the whole stream with an uncatchable
/// zone error, which is what the throwing decoder does.
Stream<String> boundedLines(
  Stream<List<int>> bytes, {
  int maxLineChars = 1 << 20,
  void Function(int droppedChars)? onOverflow,
}) {
  final buffer = StringBuffer();
  var skipping = false;

  Iterable<String> flush(String chunk) sync* {
    var start = 0;
    while (true) {
      final nl = chunk.indexOf('\n', start);
      if (nl < 0) {
        final tail = chunk.substring(start);
        if (skipping) {
          return;
        }
        if (buffer.length + tail.length > maxLineChars) {
          onOverflow?.call(buffer.length + tail.length);
          buffer.clear();
          skipping = true;
          return;
        }
        buffer.write(tail);
        return;
      }
      final segment = chunk.substring(start, nl);
      start = nl + 1;
      if (skipping) {
        skipping = false; // Resynchronized on the newline.
        buffer.clear();
        continue;
      }
      if (buffer.length + segment.length > maxLineChars) {
        onOverflow?.call(buffer.length + segment.length);
        buffer.clear();
        continue;
      }
      buffer.write(segment);
      final line = buffer.toString();
      buffer.clear();
      yield line;
    }
  }

  return bytes.transform(const Utf8Decoder(allowMalformed: true)).expand(flush);
}
