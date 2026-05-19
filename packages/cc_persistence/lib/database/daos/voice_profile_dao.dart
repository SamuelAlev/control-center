import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/tables/voice_profiles.dart';
import 'package:drift/drift.dart';

part 'voice_profile_dao.g.dart';

@DriftAccessor(tables: [VoiceProfilesTable])
/// Data access for persistent, cross-meeting voice profiles.
///
/// Every query is scoped to a `workspaceId` (a profile from one workspace must
/// never surface in another); ids are global UUIDs, so the workspace clause —
/// not id uniqueness — is the isolation boundary.
class VoiceProfileDao extends DatabaseAccessor<AppDatabase>
    with _$VoiceProfileDaoMixin {
  /// Creates a [VoiceProfileDao].
  VoiceProfileDao(super.attachedDatabase);

  /// Watches a workspace's voice profiles, ordered by name.
  Stream<List<VoiceProfilesTableData>> watchByWorkspace(String workspaceId) =>
      (select(voiceProfilesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
          .watch();

  /// Reads a workspace's voice profiles, ordered by name.
  Future<List<VoiceProfilesTableData>> getByWorkspace(String workspaceId) =>
      (select(voiceProfilesTable)
            ..where((t) => t.workspaceId.equals(workspaceId))
            ..orderBy([(t) => OrderingTerm.asc(t.displayName)]))
          .get();

  /// Looks up a profile by [displayName] within [workspaceId] (the enrollment
  /// upsert key). A profile owned by another workspace is simply not found.
  Future<VoiceProfilesTableData?> getByName(
    String workspaceId,
    String displayName,
  ) =>
      (select(voiceProfilesTable)..where(
            (t) =>
                t.workspaceId.equals(workspaceId) &
                t.displayName.equals(displayName),
          ))
          .getSingleOrNull();

  /// Inserts or updates a voice profile.
  Future<void> upsertProfile(VoiceProfilesTableCompanion entry) =>
      into(voiceProfilesTable).insertOnConflictUpdate(entry);

  /// Renames a profile, scoped to [workspaceId]. A profile owned by another
  /// workspace is not touched.
  Future<void> rename(String workspaceId, String id, String displayName) =>
      (update(voiceProfilesTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .write(
        VoiceProfilesTableCompanion(
          displayName: Value(displayName),
          updatedAt: Value(DateTime.now()),
        ),
      );

  /// Deletes a profile, scoped to [workspaceId]. A profile owned by another
  /// workspace is not touched.
  Future<void> deleteProfile(String workspaceId, String id) =>
      (delete(voiceProfilesTable)..where(
            (t) => t.id.equals(id) & t.workspaceId.equals(workspaceId),
          ))
          .go();
}
