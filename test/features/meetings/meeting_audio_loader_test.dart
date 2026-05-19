import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/meetings/meeting_audio_loader.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('writeMonoWav', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('wav_mono_test');
    });
    tearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    test('round-trips through readWavToFloat32 at the given sample rate',
        () async {
      final path = p.join(dir.path, 'out.wav');
      final samples = Float32List.fromList([0.0, 0.5, -0.5, 1.0, -1.0]);
      await writeMonoWav(path, samples, sampleRate: 22050);

      final read = await readWavToFloat32(path);
      expect(read.sampleRate, 22050);
      expect(read.samples.length, samples.length);
      for (var i = 0; i < samples.length; i++) {
        // 16-bit quantization tolerance.
        expect(read.samples[i], closeTo(samples[i], 1 / 32767 + 1e-4));
      }
    });

    test('clamps out-of-range samples', () async {
      final path = p.join(dir.path, 'clip.wav');
      await writeMonoWav(path, Float32List.fromList([2.0, -2.0]));
      final read = await readWavToFloat32(path);
      expect(read.samples[0], closeTo(1.0, 1e-3));
      expect(read.samples[1], closeTo(-1.0, 1e-3));
    });
  });

  group('loadMeetingAudioClip', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('meeting_audio_test');
    });
    tearDown(() async {
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    test('returns null when the directory does not exist', () async {
      final clip = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: p.join(dir.path, 'nope')),
      );
      expect(clip, isNull);
    });

    test('returns null when there is no usable audio', () async {
      final clip = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir.path),
      );
      expect(clip, isNull);
    });

    test('mixes me.wav + them.wav into a playable clip with a waveform',
        () async {
      // me.wav: 1s of mild tone; them.wav: louder, shorter.
      final me = Float32List(16000);
      for (var i = 0; i < me.length; i++) {
        me[i] = 0.2;
      }
      final them = Float32List(8000);
      for (var i = 0; i < them.length; i++) {
        them[i] = 0.5;
      }
      await writeMonoWav(p.join(dir.path, 'me.wav'), me);
      await writeMonoWav(p.join(dir.path, 'them.wav'), them);

      final clip = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir.path, buckets: 64),
      );
      expect(clip, isNotNull);
      expect(File(clip!.playablePath).existsSync(), isTrue);
      expect(p.basename(clip.playablePath), 'mixed.wav');
      expect(clip.waveform.length, 64);
      expect(clip.durationMs, closeTo(1000, 2)); // 16000 samples @ 16kHz
      // First half (me+them=0.7) louder than second half (me only=0.2).
      expect(clip.waveform.first, greaterThan(clip.waveform.last));
    });

    test('works with only me.wav present', () async {
      final me = Float32List.fromList(List.filled(4000, 0.3));
      await writeMonoWav(p.join(dir.path, 'me.wav'), me);
      final clip = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir.path, buckets: 16),
      );
      expect(clip, isNotNull);
      expect(clip!.durationMs, closeTo(250, 2));
    });

    test('reuses a fresh mixed.wav on a second load', () async {
      final me = Float32List.fromList(List.filled(4000, 0.3));
      await writeMonoWav(p.join(dir.path, 'me.wav'), me);
      final first = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir.path, buckets: 16),
      );
      final mixedFile = File(first!.playablePath);
      final firstStamp = mixedFile.lastModifiedSync();

      final second = await loadMeetingAudioClip(
        MeetingAudioRequest(audioDirPath: dir.path, buckets: 16),
      );
      expect(second, isNotNull);
      // Not rewritten (reused the cached mix).
      expect(mixedFile.lastModifiedSync(), firstStamp);
      expect(second!.waveform.length, 16);
    });
  });
}
