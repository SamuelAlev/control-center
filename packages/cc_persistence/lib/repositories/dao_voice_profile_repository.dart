import 'package:cc_domain/features/meetings/domain/entities/voice_profile.dart';
import 'package:cc_domain/features/meetings/domain/repositories/voice_profile_repository.dart';
import 'package:cc_domain/features/meetings/domain/services/meeting_diarization.dart';
import 'package:cc_domain/features/meetings/domain/services/voice_profile_matching.dart';
import 'package:cc_persistence/database/app_database.dart' as db;
import 'package:cc_persistence/database/daos/voice_profile_dao.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// DAO-based repository for persistent, cross-meeting voice profiles.
class DaoVoiceProfileRepository implements VoiceProfileRepository {
  /// Creates a [DaoVoiceProfileRepository].
  DaoVoiceProfileRepository(this._dao);

  final VoiceProfileDao _dao;
  static const _uuid = Uuid();

  @override
  Stream<List<VoiceProfile>> watchByWorkspace(String workspaceId) =>
      _dao.watchByWorkspace(workspaceId).map(
            (rows) => rows.map(_toDomain).whereType<VoiceProfile>().toList(),
          );

  @override
  Future<List<VoiceProfile>> getByWorkspace(String workspaceId) =>
      _dao.getByWorkspace(workspaceId).then(
            (rows) => rows.map(_toDomain).whereType<VoiceProfile>().toList(),
          );

  @override
  Future<VoiceProfile?> getByName(String workspaceId, String displayName) =>
      _dao
          .getByName(workspaceId, displayName)
          .then((row) => row == null ? null : _toDomain(row));

  @override
  Future<void> upsert(VoiceProfile profile) =>
      _dao.upsertProfile(_companion(profile));

  @override
  Future<void> enroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty || sampleEmbedding.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final existing = await _dao.getByName(workspaceId, name);
    if (existing != null) {
      // Blend the new sample into the running centroid (weighted by how many
      // samples already contributed), so the profile sharpens over time.
      final old = decodeSpeakerEmbedding(existing.embedding) ?? sampleEmbedding;
      final blended = blendCentroid(old, existing.sampleCount, sampleEmbedding);
      await _dao.upsertProfile(
        db.VoiceProfilesTableCompanion(
          id: Value(existing.id),
          workspaceId: Value(workspaceId),
          displayName: Value(name),
          embedding: Value(encodeSpeakerEmbedding(blended)!),
          sampleCount: Value(existing.sampleCount + 1),
          createdAt: Value(existing.createdAt),
          updatedAt: Value(now),
        ),
      );
      return;
    }
    await _dao.upsertProfile(
      db.VoiceProfilesTableCompanion(
        id: Value(_uuid.v4()),
        workspaceId: Value(workspaceId),
        displayName: Value(name),
        embedding: Value(encodeSpeakerEmbedding(sampleEmbedding)!),
        sampleCount: const Value(1),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> unenroll({
    required String workspaceId,
    required String displayName,
    required List<double> sampleEmbedding,
  }) async {
    final name = displayName.trim();
    if (name.isEmpty || sampleEmbedding.isEmpty) {
      return;
    }
    final existing = await _dao.getByName(workspaceId, name);
    if (existing == null) {
      return;
    }
    final centroid = decodeSpeakerEmbedding(existing.embedding);
    final remaining = centroid == null
        ? null
        : unblendCentroid(centroid, existing.sampleCount, sampleEmbedding);
    if (remaining == null) {
      // The sample was the profile's only contribution (or the stored centroid
      // can't be decoded): nothing meaningful remains, so drop the profile
      // rather than keep an empty/zero-count husk.
      await _dao.deleteProfile(workspaceId, existing.id);
      return;
    }
    await _dao.upsertProfile(
      db.VoiceProfilesTableCompanion(
        id: Value(existing.id),
        workspaceId: Value(workspaceId),
        displayName: Value(name),
        embedding: Value(encodeSpeakerEmbedding(remaining)!),
        sampleCount: Value(existing.sampleCount - 1),
        createdAt: Value(existing.createdAt),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  @override
  Future<void> rename({
    required String workspaceId,
    required String id,
    required String displayName,
  }) =>
      _dao.rename(workspaceId, id, displayName.trim());

  @override
  Future<void> delete(String workspaceId, String id) =>
      _dao.deleteProfile(workspaceId, id);

  db.VoiceProfilesTableCompanion _companion(VoiceProfile profile) =>
      db.VoiceProfilesTableCompanion(
        id: Value(profile.id),
        workspaceId: Value(profile.workspaceId),
        displayName: Value(profile.displayName),
        embedding: Value(encodeSpeakerEmbedding(profile.embedding)!),
        sampleCount: Value(profile.sampleCount),
        createdAt: Value(profile.createdAt),
        updatedAt: Value(profile.updatedAt),
      );

  /// Maps a row to a [VoiceProfile], or null when its embedding can't be decoded
  /// (a corrupt row is skipped rather than crashing a list read).
  VoiceProfile? _toDomain(db.VoiceProfilesTableData row) {
    final embedding = decodeSpeakerEmbedding(row.embedding);
    if (embedding == null || embedding.isEmpty) {
      return null;
    }
    return VoiceProfile(
      id: row.id,
      workspaceId: row.workspaceId,
      displayName: row.displayName,
      embedding: embedding,
      sampleCount: row.sampleCount,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
