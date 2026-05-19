import 'package:cc_domain/features/meetings/domain/entities/meeting.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_action_item.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_decision.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';
import 'package:cc_domain/features/meetings/domain/entities/meeting_speaker_label.dart';
import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Streams all meetings for a workspace, newest first.
final meetingsProvider =
    StreamProvider.family<List<Meeting>, String>((ref, workspaceId) {
  return ref.watch(meetingRepositoryProvider).watchByWorkspace(workspaceId);
});

/// Identifies a single meeting within a workspace.
typedef MeetingRef = ({String workspaceId, String meetingId});

/// Streams a single meeting reactively (derived from the workspace stream,
/// since the repository exposes a reactive list but a one-shot get-by-id).
final meetingDetailProvider =
    StreamProvider.family<Meeting?, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchByWorkspace(args.workspaceId)
      .map((meetings) {
    for (final m in meetings) {
      if (m.id == args.meetingId) {
        return m;
      }
    }
    return null;
  });
});

/// Streams transcript segments for a meeting, oldest first.
final meetingSegmentsProvider =
    StreamProvider.family<List<MeetingSegment>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchSegments(args.workspaceId, args.meetingId);
});

/// Streams a meeting's diarized speakers (DB-backed). Populated by the
/// `meeting.diarize` pipeline step; empty until/unless diarization has run.
final meetingSpeakersProvider =
    StreamProvider.family<List<MeetingSpeakerLabel>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchSpeakers(args.workspaceId, args.meetingId);
});

/// Streams a workspace's saved voice profiles, ordered by name. Powers the
/// settings management surface and the rename dialog's voiceprint suggestions.
final voiceProfilesProvider =
    StreamProvider.family<List<VoiceProfile>, String>((ref, workspaceId) {
  return ref
      .watch(voiceProfileRepositoryProvider)
      .watchByWorkspace(workspaceId);
});

/// Streams a meeting's action items (DB-backed, in the agent's order).
final meetingActionItemsProvider =
    StreamProvider.family<List<MeetingActionItem>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchActionItems(args.workspaceId, args.meetingId);
});

/// Streams a meeting's decisions (DB-backed, in the agent's order).
final meetingDecisionsProvider =
    StreamProvider.family<List<MeetingDecision>, MeetingRef>((ref, args) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchDecisions(args.workspaceId, args.meetingId);
});

/// Playback metadata for a meeting's retained audio: the scrubber waveform +
/// total duration. The audio *bytes* are streamed from the host over
/// `/meeting/audio` (see `MediaProxyConfig.meetingAudioUrl`), so this carries no
/// local path — playback works identically on web and desktop, local or remote.
@immutable
class MeetingAudioInfo {
  /// Creates a [MeetingAudioInfo].
  const MeetingAudioInfo({required this.waveform, required this.durationMs});

  /// Per-bucket peak amplitudes in `[0, 1]` for the scrubber.
  final List<double> waveform;

  /// Total duration in milliseconds.
  final int durationMs;
}

/// Identifies the audio to load for a meeting. The `status` is part of the key
/// on purpose: the per-channel WAVs only become complete after the
/// `meeting_summary` pipeline finishes (status reaches [MeetingStatus.done]).
/// Including `status` busts the cache on the finalization edge so the clip is
/// re-fetched against the finished files. (Notes/title edits keep the same
/// status, so they do not trigger a redundant reload.)
typedef MeetingAudioRef = ({
  String workspaceId,
  String meetingId,
  MeetingStatus status,
});

/// Fetches a meeting's playback metadata from the host (`meeting.audioClip`),
/// which assembles the mixed track + computes the waveform server-side. Null
/// when the meeting kept no audio or its files are gone (the player hides). The
/// host owns all audio I/O; the client only renders the waveform and points the
/// player at the `/meeting/audio` URL.
final meetingAudioClipProvider =
    FutureProvider.family<MeetingAudioInfo?, MeetingAudioRef>((ref, args) async {
  final client = ref.watch(rpcClientProvider);
  final res = await client.call('meeting.audioClip', {
    'meeting_id': args.meetingId,
  });
  if (res['available'] != true) {
    return null;
  }
  final waveform = ((res['waveform'] as List?) ?? const <dynamic>[])
      .map((e) => (e as num).toDouble())
      .toList(growable: false);
  return MeetingAudioInfo(
    waveform: waveform,
    durationMs: (res['duration_ms'] as num?)?.toInt() ?? 0,
  );
});

/// Streams per-meeting action-item counts (total + done) for a workspace,
/// keyed by meeting id. Powers the list signal pills + the stats strip.
final meetingActionItemStatsProvider = StreamProvider.family<
    Map<String, MeetingActionItemStats>, String>((ref, workspaceId) {
  return ref
      .watch(meetingRepositoryProvider)
      .watchActionItemStats(workspaceId);
});

/// Streams per-meeting decision counts for a workspace, keyed by meeting id.
final meetingDecisionCountsProvider =
    StreamProvider.family<Map<String, int>, String>((ref, workspaceId) {
  return ref.watch(meetingRepositoryProvider).watchDecisionCounts(workspaceId);
});

/// Shared playback state for the meeting detail's audio bar (#8): the live
/// position + a seek delegate, so the transcript can highlight / scroll to the
/// playing line and tapping a line can seek the audio. The `AudioPlayer` itself
/// lives in the playback-bar widget, which attaches its seek handler and reports
/// position here; the transcript tab watches the position and calls `seekToMs`.
@immutable
class MeetingPlaybackState {
  /// Creates a [MeetingPlaybackState].
  const MeetingPlaybackState({
    this.positionMs = 0,
    this.durationMs = 0,
    this.playing = false,
    this.ready = false,
  });

  /// Current playback position in milliseconds.
  final int positionMs;

  /// Total duration in milliseconds (0 until known).
  final int durationMs;

  /// Whether audio is currently playing.
  final bool playing;

  /// Whether a player is attached and ready to seek.
  final bool ready;

  /// Returns a copy with the given overrides.
  MeetingPlaybackState copyWith({
    int? positionMs,
    int? durationMs,
    bool? playing,
    bool? ready,
  }) =>
      MeetingPlaybackState(
        positionMs: positionMs ?? this.positionMs,
        durationMs: durationMs ?? this.durationMs,
        playing: playing ?? this.playing,
        ready: ready ?? this.ready,
      );
}

/// Holds [MeetingPlaybackState] and bridges the transcript ↔ the audio player.
class MeetingPlaybackController extends Notifier<MeetingPlaybackState> {
  Future<void> Function(Duration position)? _seek;

  @override
  MeetingPlaybackState build() => const MeetingPlaybackState();

  /// Registers the active player's seek handler (called by the playback bar on
  /// init).
  void attach(Future<void> Function(Duration position) seek) => _seek = seek;

  /// Clears [seek]'s handler and resets state (called when the player disposes,
  /// e.g. navigating away or switching meetings).
  ///
  /// Players dispose during widget-tree finalization, where mutating a provider
  /// synchronously throws ("Tried to modify a provider while the widget tree
  /// was building"), so the reset is deferred to a microtask. The [seek]
  /// identity guards the dispose-old / attach-new race when switching meetings:
  /// if the next player has already attached, this stale detach is a no-op and
  /// the deferred reset bails so it cannot clobber the new player's state.
  void detach(Future<void> Function(Duration position) seek) {
    if (!identical(_seek, seek)) {
      return;
    }
    _seek = null;
    Future(() {
      if (_seek == null) {
        state = const MeetingPlaybackState();
      }
    });
  }

  /// Reports player state changes into the shared store.
  void report({int? positionMs, int? durationMs, bool? playing, bool? ready}) {
    state = state.copyWith(
      positionMs: positionMs,
      durationMs: durationMs,
      playing: playing,
      ready: ready,
    );
  }

  /// Seeks the audio to [ms] (no-op when no player is attached). Tapping a
  /// transcript line calls this.
  Future<void> seekToMs(int ms) async {
    final seek = _seek;
    if (seek == null) {
      return;
    }
    final clamped = ms < 0 ? 0 : ms;
    state = state.copyWith(positionMs: clamped);
    await seek(Duration(milliseconds: clamped));
  }
}

/// Shared meeting-playback state for the detail screen (one player at a time).
final meetingPlaybackProvider =
    NotifierProvider<MeetingPlaybackController, MeetingPlaybackState>(
  MeetingPlaybackController.new,
);
