import 'package:cc_persistence/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_voice_profiles_workspaceId', columns: {#workspaceId})
@TableIndex(
  name: 'uq_voice_profiles_ws_name',
  columns: {#workspaceId, #displayName},
  unique: true,
)
/// Drift table for a persistent, cross-meeting voice profile.
///
/// When the user names a diarized speaker (e.g. "Person 1" → "Alex") and opts
/// to save them, a profile row is created from that speaker's WeSpeaker
/// embedding. Subsequent meetings match each diarized speaker's embedding
/// against these profiles (cosine similarity): a confident match auto-applies
/// the saved [displayName]; a weaker one surfaces as a rename suggestion.
///
/// Workspace-scoped like all meeting data — the unique `(workspaceId,
/// displayName)` index enforces one profile per name within a workspace (so
/// enrollment upserts by name), while the same person can exist independently
/// in two different workspaces. Profiles never cross the workspace boundary.
class VoiceProfilesTable extends Table {
  /// Unique profile identifier (local UUID).
  TextColumn get id => text()();

  /// Owning workspace.
  TextColumn get workspaceId =>
      text().references(WorkspacesTable, #id, onDelete: KeyAction.cascade)();

  /// The person's name, as assigned by the user.
  TextColumn get displayName => text()();

  /// JSON-encoded representative WeSpeaker embedding (an L2-normalized float
  /// vector) — the running centroid of every sample enrolled for this person.
  TextColumn get embedding => text()();

  /// How many speaker samples have been blended into [embedding]. Used to weight
  /// the running-mean update so later samples refine the centroid proportionally.
  IntColumn get sampleCount => integer().withDefault(const Constant(1))();

  /// When the row was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When the row was last updated (a new sample blended in, or a rename).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
