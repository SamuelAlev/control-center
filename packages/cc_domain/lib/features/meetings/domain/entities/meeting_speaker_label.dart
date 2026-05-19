import 'package:cc_domain/features/meetings/domain/entities/meeting_segment.dart';

/// A diarized speaker within a meeting — the result of clustering one channel's
/// audio into distinct voices. The coarse [MeetingSpeaker] channel (me/them) is
/// always known from the capture; this refines it into an individual speaker
/// the summarizer (and the user) can refer to.
class MeetingSpeakerLabel {
  /// Creates a [MeetingSpeakerLabel].
  MeetingSpeakerLabel({
    required this.id,
    required this.meetingId,
    required this.workspaceId,
    required this.channel,
    required this.label,
    required this.createdAt,
    this.displayName,
    this.embedding,
    this.enrolledProfileName,
  }) : assert(
          workspaceId.isNotEmpty,
          'MeetingSpeakerLabel workspaceId must not be empty',
        );

  /// Unique identifier.
  final String id;

  /// Parent meeting id.
  final String meetingId;

  /// Owning workspace.
  final String workspaceId;

  /// Coarse channel this speaker belongs to (`me` or `them`).
  final MeetingSpeaker channel;

  /// Diarization label, e.g. `Person 1`.
  final String label;

  /// User-assigned display name, or null until renamed.
  final String? displayName;

  /// Representative WeSpeaker embedding (L2-normalized float vector) for this
  /// speaker cluster, captured at diarization for future cross-meeting
  /// re-identification. Null when the embedding model was unavailable.
  final List<double>? embedding;

  /// The display name of the voice profile this speaker's [embedding] was
  /// enrolled into (via "Save voice profile"), or null when never enrolled.
  /// Lets a later rename un-enroll the embedding from the right profile.
  final String? enrolledProfileName;

  /// When the row was created.
  final DateTime createdAt;

  /// The name to show: the user's [displayName] if set, else the [label].
  String get displayLabel =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingSpeakerLabel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          meetingId == other.meetingId &&
          workspaceId == other.workspaceId &&
          channel == other.channel &&
          label == other.label &&
          displayName == other.displayName;

  @override
  int get hashCode => Object.hash(
        id,
        meetingId,
        workspaceId,
        channel,
        label,
        displayName,
      );
}
