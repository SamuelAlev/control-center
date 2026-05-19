/// Which audio channel a transcript segment came from.
enum MeetingSpeaker {
  /// The local user's microphone.
  me,

  /// The system output (everyone else on the call).
  them;

  /// Parses a stored speaker string, defaulting to [MeetingSpeaker.them].
  static MeetingSpeaker fromStorage(String? value) {
    return MeetingSpeaker.values.firstWhere(
      (s) => s.name == value,
      orElse: () => MeetingSpeaker.them,
    );
  }

  /// The string persisted in the database.
  String toStorage() => name;
}

/// One transcribed window within a meeting.
class MeetingSegment {
  /// Creates a [MeetingSegment].
  MeetingSegment({
    required this.id,
    required this.meetingId,
    required this.workspaceId,
    required this.speaker,
    required this.text,
    required this.startMs,
    required this.endMs,
    required this.createdAt,
    this.speakerLabel,
    this.speakerNameOverride,
  }) : assert(
          workspaceId.isNotEmpty,
          'MeetingSegment workspaceId must not be empty',
        );

  /// Unique identifier.
  final String id;

  /// Parent meeting id.
  final String meetingId;

  /// Owning workspace.
  final String workspaceId;

  /// Speaker channel.
  final MeetingSpeaker speaker;

  /// Diarized speaker label (e.g. `Person 1`), or null until diarization runs.
  /// Refines the coarse [speaker] channel into an individual speaker.
  final String? speakerLabel;

  /// A per-segment speaker-name override for THIS line only, set when the user
  /// renames a single transcript block rather than the whole speaker. Null means
  /// the line inherits its speaker group's display name (or `Person N` label).
  final String? speakerNameOverride;

  /// Transcribed text.
  final String text;

  /// Start offset from meeting start, in milliseconds.
  final int startMs;

  /// End offset from meeting start, in milliseconds.
  final int endMs;

  /// When the segment was recorded.
  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingSegment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          meetingId == other.meetingId &&
          workspaceId == other.workspaceId &&
          speaker == other.speaker &&
          speakerLabel == other.speakerLabel &&
          speakerNameOverride == other.speakerNameOverride &&
          text == other.text &&
          startMs == other.startMs &&
          endMs == other.endMs;

  @override
  int get hashCode => Object.hash(
        id,
        meetingId,
        workspaceId,
        speaker,
        speakerLabel,
        speakerNameOverride,
        text,
        startMs,
        endMs,
      );
}
