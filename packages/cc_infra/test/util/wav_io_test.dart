import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/util/wav_io.dart';
import 'package:test/test.dart';

/// Round-trips the WAV reader/writer pair. WavStreamWriter emits a placeholder
/// header then patches the two size fields on close; readWavToFloat32 parses
/// the fmt + data chunks back into normalized samples. Also covers
/// writeMonoWav (single-pass mono writer) and the malformed-file guards.
void main() {
  late Directory sandbox;
  setUp(() {
    sandbox = Directory.systemTemp.createTempSync('wav_io_');
  });
  tearDown(() => sandbox.deleteSync(recursive: true));

  group('WavStreamWriter + readWavToFloat32 round-trip', () {
    test('writes then reads back mono 16-bit PCM with patched sizes', () async {
      final path = '${sandbox.path}/out.wav';
      final writer = await WavStreamWriter.create(
        path,
        sampleRate: 16000,
        spaces: 1,
      );
      // Two samples: max, min.
      writer.add(_toPcm16([1.0, -1.0]));
      await writer.close();

      final data = await readWavToFloat32(path);
      expect(data.sampleRate, 16000);
      expect(data.samples, hasLength(2));
      expect(data.samples[0], closeTo(1.0, 1e-4));
      expect(data.samples[1], closeTo(-1.0, 1e-4));

      // The header sizes are patched on close — verify by reading the raw bytes.
      final bytes = await File(path).readAsBytes();
      final view = ByteData.sublistView(bytes);
      // RIFF chunk size @ 4 = 36 + dataBytes = 36 + 4 = 40.
      expect(view.getUint32(4, Endian.little), 40);
      // data chunk size @ 40 = 4.
      expect(view.getUint32(40, Endian.little), 4);
      // RIFF / WAVE markers.
      expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE');
    });

    test('an empty stream still produces a valid (zero-data) WAV', () async {
      final path = '${sandbox.path}/empty.wav';
      final writer = await WavStreamWriter.create(path);
      await writer.close();
      final data = await readWavToFloat32(path);
      expect(data.samples, isEmpty);
      expect(data.sampleRate, 16000);
    });

    test('add after close / empty add is a no-op', () async {
      final path = '${sandbox.path}/noop.wav';
      final writer = await WavStreamWriter.create(path);
      await writer.close();
      // Re-add after close: ignored.
      writer.add(_toPcm16([0.5]));
      // Empty add before close: ignored.
      final writer2 = await WavStreamWriter.create('${sandbox.path}/n2.wav');
      writer2.add(Uint8List(0));
      await writer2.close();
      final data = await readWavToFloat32(path);
      expect(data.samples, isEmpty);
    });

    test('multi-channel input averages down to mono on read', () async {
      final path = '${sandbox.path}/stereo.wav';
      final writer = await WavStreamWriter.create(
        path,
        sampleRate: 8000,
        spaces: 2,
      );
      // One stereo frame: left=1.0, right=-1.0 → averages to 0.
      writer.add(_toPcm16([1.0, -1.0]));
      await writer.close();
      final data = await readWavToFloat32(path);
      expect(data.sampleRate, 8000);
      expect(data.samples.single, closeTo(0.0, 1e-4));
    });
  });

  group('readWavToFloat32 — malformed guards', () {
    test('missing file returns empty data with default rate', () async {
      final data = await readWavToFloat32('${sandbox.path}/nope.wav');
      expect(data.samples, isEmpty);
      expect(data.sampleRate, 16000);
    });

    test('non-RIFF file returns empty data', () async {
      final path = '${sandbox.path}/garbage.wav';
      await File(
        path,
      ).writeAsBytes([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
      final data = await readWavToFloat32(path);
      expect(data.samples, isEmpty);
    });

    test('RIFF file with no data chunk returns empty data', () async {
      final path = '${sandbox.path}/nodata.wav';
      // RIFF + WAVE + a fmt chunk but no data chunk.
      final bytes = BytesBuilder()
        ..add([82, 73, 70, 70]) // RIFF
        ..add(_u32(4)) // size (placeholder)
        ..add([87, 65, 86, 69]); // WAVE
      await File(path).writeAsBytes(bytes.toBytes());
      final data = await readWavToFloat32(path);
      expect(data.samples, isEmpty);
    });
  });

  group('writeMonoWav', () {
    test(
      'writes a mono WAV readable by readWavToFloat32, clamping over-range',
      () async {
        final path = '${sandbox.path}/mono.wav';
        // Values outside [-1, 1] must be clamped, not wrapped.
        await writeMonoWav(path, Float32List.fromList([0.5, 5.0, -5.0]));
        final data = await readWavToFloat32(path);
        expect(data.sampleRate, 16000);
        expect(data.samples, hasLength(3));
        expect(data.samples[0], closeTo(0.5, 1e-3));
        expect(data.samples[1], closeTo(1.0, 1e-3));
        expect(data.samples[2], closeTo(-1.0, 1e-3));
      },
    );

    test('honours a custom sample rate', () async {
      final path = '${sandbox.path}/mono8k.wav';
      await writeMonoWav(path, Float32List.fromList([0.0]), sampleRate: 8000);
      final data = await readWavToFloat32(path);
      expect(data.sampleRate, 8000);
    });

    test('creates parent directories as needed', () async {
      final path = '${sandbox.path}/nested/deep/mono.wav';
      await writeMonoWav(path, Float32List.fromList([0.1]));
      expect(File(path).existsSync(), isTrue);
    });
  });
}

Uint8List _toPcm16(List<double> samples) {
  final b = ByteData(samples.length * 2);
  for (var i = 0; i < samples.length; i++) {
    final s = samples[i].clamp(-1.0, 1.0);
    b.setInt16(i * 2, (s * 32767).round(), Endian.little);
  }
  return b.buffer.asUint8List();
}

Uint8List _u32(int v) {
  final b = ByteData(4)..setUint32(0, v, Endian.little);
  return b.buffer.asUint8List();
}
