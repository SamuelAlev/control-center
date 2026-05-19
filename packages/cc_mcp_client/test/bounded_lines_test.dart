import 'dart:convert';

import 'package:cc_mcp_client/src/transports/bounded_lines.dart';
import 'package:test/test.dart';

/// `LineSplitter` buffers a newline-free stream forever, so a hostile or broken
/// MCP server could OOM the client that merely connected to it. These pin the
/// bound and the resynchronization behaviour.
void main() {
  Stream<List<int>> chunks(List<String> parts) =>
      Stream.fromIterable(parts.map(utf8.encode));

  test('splits ordinary lines and joins chunk-split ones', () async {
    final lines = await boundedLines(
      chunks(['{"a":1}\n{"b":', '2}\n', 'tail\n']),
    ).toList();
    expect(lines, ['{"a":1}', '{"b":2}', 'tail']);
  });

  test('an unterminated tail is buffered, not emitted', () async {
    final lines = await boundedLines(chunks(['no newline here'])).toList();
    expect(lines, isEmpty);
  });

  test('drops an oversized line instead of buffering it forever', () async {
    final dropped = <int>[];
    final lines = await boundedLines(
      chunks(['x' * 100, 'y' * 100, '\nrecovered\n']),
      maxLineChars: 50,
      onOverflow: dropped.add,
    ).toList();

    expect(lines, ['recovered'], reason: 'resynchronizes on the next newline');
    expect(dropped, isNotEmpty);
  });

  test('a giant newline-free stream stays bounded', () async {
    var overflows = 0;
    final lines = await boundedLines(
      Stream.fromIterable(List.generate(200, (_) => utf8.encode('z' * 1000))),
      maxLineChars: 1000,
      onOverflow: (_) => overflows++,
    ).toList();

    expect(lines, isEmpty);
    expect(overflows, greaterThan(0));
  });

  test('malformed UTF-8 does not tear down the stream', () async {
    final lines = await boundedLines(
      Stream.fromIterable([
        [0xC3, 0x28], // Invalid 2-byte sequence.
        utf8.encode('ok\n'),
      ]),
    ).toList();
    expect(lines, hasLength(1));
    expect(lines.single, endsWith('ok'));
  });
}
