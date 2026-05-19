import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';

/// Repository for persistent, cross-meeting [VoiceProfile]s.
///
/// Every method is scoped to a `workspaceId`; a profile from one workspace must
/// never surface in another.
abstract class VoiceProfileRepository {
  /// Watches a workspace's voice profiles, ordered by name.
  Stream<List<VoiceProfile>> watchByWorkspace(String workspaceId);

  /// Fetches a workspace's voice profiles, ordered by name.
  Future<List<VoiceProfile>> getByWorkspace(String workspaceId);

  /// Looks up a profile by [displayName] within [workspaceId]. A profile owned
  /// by another workspace is not found.
  Future<VoiceProfile?> getByName(String workspaceId, String displayName);

  /// Inserts or updates a voice profile.
  Future<void> upsert(VoiceProfile profile);

  /// Enrolls a [sampleEmbedding] for [displayName] within [workspaceId]: blends
  /// the sample into the existing profile's running centroid (incrementing its
  /// sample count) when one with that name exists, or creates a new profile from
  /// the sample otherwise. This is the primary way profiles are created — when
  /// the user names a diarized speaker and saves them.
  Future<void> enroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  });

  /// Removes a [sampleEmbedding] previously enrolled for [displayName] within
  /// [workspaceId]: backs the sample out of the profile's running centroid and
  /// decrements its sample count, deleting the profile outright when that was its
  /// only sample. A no-op when no profile with that name exists. The inverse of
  /// [enroll] — used when the user renames a speaker away from a name their
  /// voiceprint was saved under, so the corrected name doesn't leave a stale
  /// voiceprint behind.
  Future<void> unenroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  });

  /// Renames a profile, scoped to [workspaceId].
  Future<void> rename({
    required String workspaceId,
    required String id,
    required String displayName,
  });

  /// Deletes a profile, scoped to [workspaceId].
  Future<void> delete(String workspaceId, String id);
}
