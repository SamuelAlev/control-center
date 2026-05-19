import 'dart:typed_data';

import 'package:control_center/features/rigs/presentation/mjpeg_frame_reader.dart';
import 'package:flutter_test/flutter_test.dart';

/// One JPEG-shaped blob: SOI, [body] filler, EOI.
Uint8List _jpeg(int body, {int fill = 0x41}) => Uint8List.fromList([
  0xFF,
  0xD8,
  ...List<int>.filled(body, fill),
  0xFF,
  0xD9,
]);

/// The watch lane's framing runs on the UI isolate for every chunk of a
/// 24 fps 1080p stream, so it is both the hot path and the one place a
/// desynchronised stream can never recover from. Both properties are pinned
/// here because the widget itself cannot be driven without a live server.
void main() {
  group('MjpegFrameReader', () {
    test('yields a frame once its EOI arrives', () {
      final reader = MjpegFrameReader();
      final frame = _jpeg(16);
      expect(reader.add(frame.sublist(0, 8)), isNull);
      final out = reader.add(frame.sublist(8));
      expect(out, isNotNull);
      expect(out, frame);
      expect(reader.bufferedBytes, 0);
    });

    test('a marker pair split across two chunks is still found', () {
      // The reason the scan resumes one byte back rather than at the new
      // tail: `FF` can land at the end of one chunk and `D9` at the start of
      // the next, and a naive resume-from-here never sees the pair.
      final reader = MjpegFrameReader();
      final frame = _jpeg(8);
      expect(reader.add(frame.sublist(0, frame.length - 1)), isNull);
      expect(reader.add(frame.sublist(frame.length - 1)), frame);
    });

    test('several frames coalesced into one chunk yield the NEWEST', () {
      // TCP routinely merges frames. Painting the older ones costs a decode
      // each for pictures that are already stale; taking the first SOI with
      // the last EOI is worse still — `Image.memory` stops at the first EOI,
      // so that slice paints the OLDEST frame.
      final reader = MjpegFrameReader();
      final first = _jpeg(4, fill: 0x11);
      final second = _jpeg(4, fill: 0x22);
      final third = _jpeg(4, fill: 0x33);
      final out = reader.add([...first, ...second, ...third]);
      expect(out, third);
      expect(reader.bufferedBytes, 0);
    });

    test('junk between frames resynchronises at the next SOI', () {
      final reader = MjpegFrameReader();
      final frame = _jpeg(8);
      expect(reader.add([0x00, 0x01, 0x02, ...frame]), frame);
    });

    test('a stream with no SOI at all does not grow without bound', () {
      final reader = MjpegFrameReader();
      for (var i = 0; i < 50; i++) {
        expect(reader.add(List<int>.filled(1000, 0x00)), isNull);
      }
      // Only the straddle byte is kept.
      expect(reader.bufferedBytes, lessThanOrEqualTo(1));
    });

    test('an unterminated frame is capped, then the stream resynchronises', () {
      final reader = MjpegFrameReader(maxBufferBytes: 4096);
      // An SOI followed by megabytes that never terminate is what a wrong
      // content type looks like; the buffer must not be the thing that grows.
      expect(reader.add([0xFF, 0xD8, ...List<int>.filled(3000, 0x41)]), isNull);
      expect(reader.add(List<int>.filled(3000, 0x41)), isNull);
      expect(reader.bufferedBytes, lessThanOrEqualTo(4096));
      final frame = _jpeg(8);
      expect(reader.add(frame), frame);
    });

    test('the returned frame is a COPY, not a view into the buffer', () {
      // A view would be repainted as whatever landed in those bytes after the
      // next compaction — a decoded picture of the following frame's noise.
      final reader = MjpegFrameReader();
      final first = _jpeg(4, fill: 0x11);
      final out = reader.add(first)!;
      final snapshot = Uint8List.fromList(out);
      reader.add(_jpeg(4, fill: 0x22));
      expect(out, snapshot);
    });

    test('reset drops a partial frame', () {
      final reader = MjpegFrameReader();
      reader.add([0xFF, 0xD8, 0x41, 0x41]);
      expect(reader.bufferedBytes, greaterThan(0));
      reader.reset();
      expect(reader.bufferedBytes, 0);
      final frame = _jpeg(4);
      expect(reader.add(frame), frame);
    });

    test('a byte-at-a-time stream still frames correctly', () {
      final reader = MjpegFrameReader();
      final frame = _jpeg(32);
      Uint8List? out;
      for (final byte in frame) {
        out = reader.add([byte]) ?? out;
      }
      expect(out, frame);
    });
  });
}
