/// A persistent, cross-meeting voice profile: a named voiceprint the app uses
/// to recognize a speaker automatically in future meetings.
///
/// Created when the user names a diarized speaker and saves them; refined over
/// time as more samples of the same person are enrolled (the [embedding] is a
/// running centroid weighted by [sampleCount]). Workspace-scoped — a profile
/// belongs to exactly one workspace and never crosses the boundary.
class VoiceProfile {
  /// Creates a [VoiceProfile].
  VoiceProfile({
    required this.id,
    required this.workspaceId,
    required this.displayName,
    required this.embedding,
    required this.createdAt,
    required this.updatedAt,
    this.sampleCount = 1,
  })  : assert(
          workspaceId.isNotEmpty,
          'VoiceProfile workspaceId must not be empty',
        ),
        assert(
          embedding.isNotEmpty,
          'VoiceProfile embedding must not be empty',
        );

  /// Unique identifier.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The person's name, as assigned by the user.
  final String displayName;

  /// Representative WeSpeaker embedding (L2-normalized) — the running centroid
  /// of every sample enrolled for this person.
  final List<double> embedding;

  /// How many speaker samples have been blended into [embedding].
  final int sampleCount;

  /// When the profile was created.
  final DateTime createdAt;

  /// When the profile was last updated.
  final DateTime updatedAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoiceProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          displayName == other.displayName &&
          sampleCount == other.sampleCount;

  @override
  int get hashCode => Object.hash(id, workspaceId, displayName, sampleCount);
}
