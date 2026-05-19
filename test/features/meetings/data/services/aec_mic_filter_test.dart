import 'dart:typed_data';

import 'package:control_center/core/infrastructure/audio/aec/aec_processor.dart';
import 'package:control_center/features/meetings/data/services/aec_mic_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records every block it sees and applies a reversible transform to capture
/// blocks (byte-wise XOR 0xFF) so output is distinguishable from input yet
/// verifiable.
class _FakeAecEngine implements AecEngine {
  final List<Uint8List> reverseBlocks = [];
  final List<Uint8List> captureBlocks = [];
  final List<int> captureDelays = [];
  int disposeCount = 0;

  @override
  void processReverse(Uint8List block) =>
      reverseBlocks.add(Uint8List.fromList(block));

  @override
  Uint8List processCapture(Uint8List block, int streamDelayMs) {
    captureBlocks.add(Uint8List.fromList(block));
    captureDelays.add(streamDelayMs);
    final out = Uint8List(block.length);
    for (var i = 0; i < block.length; i++) {
      out[i] = block[i] ^ 0xFF;
    }
    return out;
  }

  @override
  AecMetrics metrics() => AecMetrics.empty;

  @override
  void dispose() => disposeCount++;
}

/// A deterministic byte sequence of [n] bytes (value = index % 256).
Uint8List _ramp(int n) =>
    Uint8List.fromList(List<int>.generate(n, (i) => i % 256));

/// Splits [data] into successive chunks of the given [sizes] (a fresh copy
/// each), as the OS capture callbacks would deliver them.
List<Uint8List> _chunk(Uint8List data, List<int> sizes) {
  final out = <Uint8List>[];
  var off = 0;
  for (final s in sizes) {
    out.add(Uint8List.sublistView(data, off, off + s));
    off += s;
  }
  return out;
}

Uint8List _concat(List<Uint8List> parts) {
  final b = BytesBuilder();
  for (final p in parts) {
    b.add(p);
  }
  return b.takeBytes();
}

void main() {
  const block = AecProcessor.blockBytes; // 320

  group('AecMicFilter.cleanMic', () {
    test('re-blocks mismatched chunk sizes into exact blocks, drops the tail',
        () async {
      final fake = _FakeAecEngine();
      final filter = AecMicFilter(processor: fake);
      // 3 full blocks + a 160-byte remainder.
      const total = block * 3 + 160;
      final data = _ramp(total);
      final chunks = _chunk(data, [100, 700, 50, total - 850]);

      final out = _concat(
        await filter.cleanMic(Stream.fromIterable(chunks)).toList(),
      );

      // Exactly 3 capture blocks of `block` bytes, in order, reconstructing the
      // first 3 blocks of input (the trailing 160-byte partial is dropped).
      expect(fake.captureBlocks, hasLength(3));
      for (final b in fake.captureBlocks) {
        expect(b, hasLength(block));
      }
      expect(_concat(fake.captureBlocks), equals(data.sublist(0, block * 3)));

      // Output is the cleaned (XOR-inverted) bytes of those 3 blocks.
      expect(out, hasLength(block * 3));
      final reInverted = Uint8List.fromList(out.map((b) => b ^ 0xFF).toList());
      expect(reInverted, equals(data.sublist(0, block * 3)));
    });

    test('a single multi-block chunk yields all contained blocks', () async {
      final fake = _FakeAecEngine();
      final filter = AecMicFilter(processor: fake);
      final data = _ramp(block * 4);
      final out = _concat(
        await filter.cleanMic(Stream.fromIterable([data])).toList(),
      );
      expect(fake.captureBlocks, hasLength(4));
      expect(out, hasLength(block * 4));
    });

    test('null processor → identity passthrough (same stream, same bytes)',
        () async {
      final filter = AecMicFilter();
      final chunks = [_ramp(100), _ramp(50)];
      final src = Stream.fromIterable(chunks);
      // Identity: the very same stream object is returned.
      expect(identical(filter.cleanMic(src), src), isTrue);
      final out = await filter.cleanMic(Stream.fromIterable(chunks)).toList();
      expect(_concat(out), equals(_concat(chunks)));
    });
  });

  group('AecMicFilter.referenceTap', () {
    test('feeds far-end blocks and re-emits "them" chunks UNCHANGED', () async {
      final fake = _FakeAecEngine();
      final filter = AecMicFilter(processor: fake);
      final data = _ramp(block * 2 + 64);
      final chunks = _chunk(data, [block, block, 64]);

      final out = await filter.referenceTap(Stream.fromIterable(chunks)).toList();

      // "them" passthrough is byte-for-byte identical and in order.
      expect(out, hasLength(chunks.length));
      expect(_concat(out), equals(data));
      // Two full far-end blocks fed; the 64-byte tail is buffered (not fed).
      expect(fake.reverseBlocks, hasLength(2));
      expect(_concat(fake.reverseBlocks), equals(data.sublist(0, block * 2)));
    });

    test('null processor → identity passthrough', () async {
      final filter = AecMicFilter();
      final chunks = [_ramp(block), _ramp(10)];
      final src = Stream.fromIterable(chunks);
      expect(identical(filter.referenceTap(src), src), isTrue);
    });
  });

  group('AecMicFilter lifecycle', () {
    test('isActive reflects whether a processor is present', () {
      expect(AecMicFilter(processor: _FakeAecEngine()).isActive, isTrue);
      expect(AecMicFilter().isActive, isFalse);
    });

    test('dispose frees the engine exactly once (idempotent)', () async {
      final fake = _FakeAecEngine();
      final filter = AecMicFilter(processor: fake);
      await filter.dispose();
      await filter.dispose();
      expect(fake.disposeCount, 1);
    });

    test('null-processor dispose is a safe no-op', () async {
      await AecMicFilter().dispose();
    });
  });
}
