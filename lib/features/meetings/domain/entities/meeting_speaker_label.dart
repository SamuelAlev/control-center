import 'package:control_center/features/meetings/domain/entities/meeting_segment.dart';

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
