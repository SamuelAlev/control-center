import 'dart:io';
import 'dart:typed_data';

import 'package:cc_infra/src/meetings/meeting_audio_loader.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// Exercises [loadMeetingAudioClip] against real on-disk WAV fixtures written
/// into a temp dir. Covers: missing dir → null; only-me mix; me+them mix;
/// cached `mixed.wav` reuse when fresh; cache invalidation when a source is
/// newer than the mix; empty audio → null.
void main() {
  late Directory tempRoot;

  setUp(() async {
    tempRoot = await Directory.systemTemp.createTemp('meeting_audio_loader_');
  });

  tearDown(() async {
    if (tempRoot.existsSync()) {
      await tempRoot.delete(recursive: true);
    }
  });

  Future<void> writeMono(
    String path,
    List<double> samples, {
    int sampleRate = 16000,
  }) async {
    await writeMonoWav(
      path,
      Float32List.fromList(samples),
      sampleRate: sampleRate,
    );
  }

  test('returns null when the audio directory does not exist', () async {
    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: p.join(tempRoot.path, 'missing')),
    );
    expect(clip, isNull);
  });

  test('returns null when the directory exists but has no audio', () async {
    final dir = Directory(p.join(tempRoot.path, 'empty'))..createSync();
    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path),
    );
    expect(clip, isNull);
  });

  test('mixes only me.wav when them.wav is absent', () async {
    final dir = Directory(p.join(tempRoot.path, 'me-only'))..createSync();
    await writeMono(p.join(dir.path, 'me.wav'), [0.5, -0.5, 0.25, -0.25]);

    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path, buckets: 4),
    );
    expect(clip, isNotNull);
    expect(clip!.playablePath, p.join(dir.path, 'mixed.wav'));
    // 4 samples @ 16000 Hz = 0.25 ms.
    expect(clip.durationMs, (4 * 1000) ~/ 16000);
    expect(clip.waveform, hasLength(4));
    expect(File(clip.playablePath).existsSync(), isTrue);
  });

  test('mixes me.wav and them.wav into mixed.wav', () async {
    final dir = Directory(p.join(tempRoot.path, 'both'))..createSync();
    await writeMono(p.join(dir.path, 'me.wav'), [0.4, 0.4, 0.4, 0.4]);
    await writeMono(p.join(dir.path, 'them.wav'), [0.2, 0.2, 0.2, 0.2]);

    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path, buckets: 2),
    );
    expect(clip, isNotNull);
    // Sanity: the mixed clip was written and is readable.
    final roundTrip = await readWavToFloat32(clip!.playablePath);
    expect(roundTrip.samples, isNotEmpty);
    // mixTracksToMono sums (clipped) the two tracks → each sample ~0.6.
    expect(roundTrip.samples.first, closeTo(0.6, 0.05));
  });

  test('reuses a fresh cached mixed.wav without rewriting it', () async {
    final dir = Directory(p.join(tempRoot.path, 'cached'))..createSync();
    await writeMono(p.join(dir.path, 'me.wav'), [0.4, 0.4, 0.4, 0.4]);
    await writeMono(p.join(dir.path, 'them.wav'), [0.2, 0.2, 0.2, 0.2]);

    // First call writes mixed.wav.
    final first = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path),
    );
    expect(first, isNotNull);
    final mixedFile = File(first!.playablePath);
    // Make the mix definitively newer than its sources so the cache is hit.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final pinnedMtime = DateTime.now();
    mixedFile.setLastModifiedSync(pinnedMtime);

    // Second call should reuse the cache (no rewrite) → mtime unchanged.
    await loadMeetingAudioClip(MeetingAudioRequest(audioDirPath: dir.path));
    expect(mixedFile.lastModifiedSync().toUtc(), pinnedMtime.toUtc());
  });

  test('invalidates cache when a source is newer than the mix', () async {
    final dir = Directory(p.join(tempRoot.path, 'stale-cache'))..createSync();
    await writeMono(p.join(dir.path, 'me.wav'), [0.4, 0.4, 0.4, 0.4]);
    await writeMono(p.join(dir.path, 'them.wav'), [0.2, 0.2, 0.2, 0.2]);

    // Prime the cache.
    await loadMeetingAudioClip(MeetingAudioRequest(audioDirPath: dir.path));
    final mixedFile = File(p.join(dir.path, 'mixed.wav'));
    expect(mixedFile.existsSync(), isTrue);

    // Touch me.wav so it is newer than mixed.wav.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    await File(
      p.join(dir.path, 'me.wav'),
    ).writeAsBytes(await File(p.join(dir.path, 'me.wav')).readAsBytes());

    // Re-run; should re-mix and overwrite mixed.wav.
    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path),
    );
    expect(clip, isNotNull);
    expect(clip!.playablePath, mixedFile.path);
  });

  test('returns null when mixed audio is empty (me.wav is empty)', () async {
    final dir = Directory(p.join(tempRoot.path, 'empty-me'))..createSync();
    // Write a valid WAV header with zero samples.
    await writeMono(p.join(dir.path, 'me.wav'), const <double>[]);
    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path),
    );
    expect(clip, isNull);
  });

  test('honors the buckets parameter on the waveform', () async {
    final dir = Directory(p.join(tempRoot.path, 'buckets'))..createSync();
    // 8 samples so bucketing into 4 is meaningful.
    await writeMono(p.join(dir.path, 'me.wav'), [
      0.1,
      0.2,
      0.3,
      0.4,
      0.5,
      0.6,
      0.7,
      0.8,
    ]);
    final clip = await loadMeetingAudioClip(
      MeetingAudioRequest(audioDirPath: dir.path, buckets: 4),
    );
    expect(clip!.waveform, hasLength(4));
  });
}
