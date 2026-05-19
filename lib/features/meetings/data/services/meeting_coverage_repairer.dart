import 'dart:typed_data';

import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/repositories/meeting_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_coverage_repair.dart';
import 'package:cc_domain/features/meetings/domain/services/speech_transcriber.dart';
import 'package:cc_infra/src/meetings/meeting_transcription_service.dart';
import 'package:cc_infra/src/util/wav_io.dart';
import 'package:cc_natives/cc_natives.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

/// Post-meeting transcript-coverage repair (#13).
///
/// After a recording stops, runs offline Silero VAD over each retained channel
/// WAV, compares the detected speech to what the live rolling-window transcript
/// already covers, and re-decodes any sizable uncovered gap — recovering speech
/// a stalled/dropped/late-warming live decode missed. The decision policy is the
/// pure [shouldRepairCoverage] (55% coverage floor); only the VAD run, the
/// re-decode, and persistence live here.
///
/// Best-effort: every failure is swallowed (a repair must never block or fail
/// finalization), and the total re-decode is bounded so a pathological recording
/// can't stall `stop()`.
class MeetingCoverageRepairer {
  /// Creates a [MeetingCoverageRepairer].
  const MeetingCoverageRepairer(
    this._repo, {
    MeetingOfflineVad vad = const MeetingOfflineVad(),
  }) : _vad = vad;

  final MeetingRepository _repo;
  final MeetingOfflineVad _vad;

  static const Uuid _uuid = Uuid();

  /// Upper bound on total re-decoded audio per channel, so repair stays bounded.
  static const int _maxRedecodeMs = 90000;

  /// Repairs the retained channels of [meetingId]. Returns the number of
  /// transcript segments recovered (0 when nothing was retained / needed / the
  /// model or transcriber was unavailable). Never throws.
  Future<int> repair({
    required String workspaceId,
    required String meetingId,
    required String? audioDir,
    required MeetingMode mode,
    required String? vadModelPath,
    required SpeechTranscriber? transcriber,
  }) async {
    if (audioDir == null ||
        audioDir.isEmpty ||
        vadModelPath == null ||
        transcriber == null) {
      return 0;
    }
    try {
      if (!transcriber.isReady) {
        await transcriber.initialize();
      }
      final segments = await _repo.getSegments(workspaceId, meetingId);
      // The mic ("me") is always retained; the system loopback ("them") only in
      // remote mode. Diarization aside, each channel's transcript is repaired
      // against that channel's own audio.
      final channels = <(MeetingSpeaker, String)>[
        (MeetingSpeaker.me, 'me.wav'),
        if (mode != MeetingMode.inPerson) (MeetingSpeaker.them, 'them.wav'),
      ];
      var recovered = 0;
      for (final (channel, wavName) in channels) {
        recovered += await _repairChannel(
          workspaceId: workspaceId,
          meetingId: meetingId,
          wavPath: p.join(audioDir, wavName),
          channel: channel,
          segments: segments,
          vadModelPath: vadModelPath,
          transcriber: transcriber,
        );
      }
      return recovered;
    } on Object catch (e, s) {
      AppLog.w('MeetingCoverageRepair', 'skipped: $e\n$s');
      return 0;
    }
  }

  Future<int> _repairChannel({
    required String workspaceId,
    required String meetingId,
    required String wavPath,
    required MeetingSpeaker channel,
    required List<MeetingSegment> segments,
    required String vadModelPath,
    required SpeechTranscriber transcriber,
  }) async {
    final wav = await readWavToFloat32(wavPath);
    if (wav.samples.isEmpty) {
      return 0;
    }
    final sampleRate = wav.sampleRate;
    final speech = await _vad.detect(
      samples: wav.samples,
      modelPath: vadModelPath,
      sampleRate: sampleRate,
    );
    if (speech.isEmpty) {
      return 0;
    }
    final covered = <Span>[
      for (final s in segments)
        if (s.speaker == channel) (startMs: s.startMs, endMs: s.endMs),
    ];
    final ratio = speechCoverageRatio(speech, covered);
    final uncovered = uncoveredSpeechRegions(speech, covered);
    if (!shouldRepairCoverage(ratio: ratio, uncovered: uncovered)) {
      return 0;
    }
    AppLog.i(
      'MeetingCoverageRepair',
      '${channel.name}: coverage ${(ratio * 100).round()}% < 55% — '
          're-decoding ${uncovered.length} uncovered gap(s)',
    );

    var redecodedMs = 0;
    var added = 0;
    var skipped = 0;
    for (final region in uncovered) {
      if (redecodedMs >= _maxRedecodeMs) {
        skipped++;
        continue;
      }
      final startSample =
          (region.startMs * sampleRate / 1000).floor().clamp(0, wav.samples.length);
      final endSample =
          (region.endMs * sampleRate / 1000).ceil().clamp(0, wav.samples.length);
      if (endSample <= startSample) {
        continue;
      }
      final pcm = _float32ToPcm16(
        Float32List.sublistView(wav.samples, startSample, endSample),
      );
      final text = (await transcriber.transcribeChunk(pcm)).trim();
      if (text.isEmpty ||
          MeetingTranscriptionService.isNonSpeechArtifact(text) ||
          MeetingTranscriptionService.isRepetitionHallucination(text) ||
          MeetingTranscriptionService.isHallucinatedBoilerplate(text)) {
        continue;
      }
      await _repo.appendSegment(
        MeetingSegment(
          id: _uuid.v4(),
          meetingId: meetingId,
          workspaceId: workspaceId,
          speaker: channel,
          text: text,
          startMs: region.startMs,
          endMs: region.endMs,
          createdAt: DateTime.now(),
        ),
      );
      added++;
      redecodedMs += region.endMs - region.startMs;
    }
    AppLog.i(
      'MeetingCoverageRepair',
      '${channel.name}: recovered $added segment(s)'
          '${skipped > 0 ? ', skipped $skipped gap(s) past the re-decode cap' : ''}',
    );
    return added;
  }

  static Uint8List _float32ToPcm16(Float32List samples) {
    final out = Uint8List(samples.length * 2);
    final view = ByteData.sublistView(out);
    for (var i = 0; i < samples.length; i++) {
      var v = (samples[i] * 32767).round();
      if (v > 32767) {
        v = 32767;
      } else if (v < -32768) {
        v = -32768;
      }
      view.setInt16(i * 2, v, Endian.little);
    }
    return out;
  }
}
