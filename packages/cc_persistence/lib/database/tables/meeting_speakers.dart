import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/meetings.dart';
import 'package:drift/drift.dart';

@TableIndex(
  name: 'uq_meeting_speakers_meeting_channel_label',
  columns: {#meetingId, #channel, #label},
  unique: true,
)
/// Drift table for diarized speakers within a meeting.
///
/// The post-recording diarization step clusters a channel's audio into distinct
/// speakers and writes one row per (meeting, channel, label) — e.g.
/// `(meeting, them, "Person 1")`. The user can rename a speaker by setting
/// [displayName]. Workspace-scoped via [workspaceId] in addition to the
/// [meetingId] foreign key. `(meeting_id, channel, label)` is a speaker's
/// identity and is unique; a rename by label is one `INSERT … ON CONFLICT`.
class MeetingSpeakersTable extends Table {
  /// Unique speaker-row identifier.
  TextColumn get id => text()();

  /// Parent meeting.
  TextColumn get meetingId =>
      text().references(MeetingsTable, #id, onDelete: KeyAction.cascade)();

  /// Owning workspace (denormalized for workspace-scoped reads).
  TextColumn get workspaceId => text()();

  /// Coarse channel this speaker belongs to: `me` or `them`
  /// (`MeetingSpeaker.toStorage()`).
  TextColumn get channel => text().check(
    // ignore: recursive_getters
    channel.isIn(SpacesStoredValues.meetingSpeaker),
  )();

  /// Diarization label, e.g. `Person 1` — unique within (meeting, channel).
  TextColumn get label => text()();

  /// User-assigned display name; null until the user renames the speaker.
  TextColumn get displayName => text().nullable()();

  /// JSON-encoded representative WeSpeaker embedding (an L2-normalized float
  /// vector) for this speaker cluster, captured at diarization. Persisted to
  /// enable future cross-meeting speaker re-identification. Null when the
  /// embedding model wasn't available or extraction failed.
  TextColumn get embedding => text().nullable().check(
    // ignore: recursive_getters
    isJsonArray(embedding),
  )();

  /// The `displayName` of the cross-meeting voice profile this speaker's
  /// [embedding] was enrolled into (via the "Save voice profile" prompt), or
  /// null when never enrolled. Provenance for un-enrollment: when the user
  /// renames the speaker to a different name, we remove this embedding's sample
  /// from the *previously* enrolled profile (and only that one) so a corrected
  /// name doesn't leave a stale voiceprint behind. Carried forward across
  /// re-diarization by `(channel, label)`, alongside [displayName]. No
  /// foreign key: profiles are renamed and deleted on their own, and this is
  /// the name the voiceprint went into at the time.
  TextColumn get enrolledProfileName => text().nullable()();

  /// When the row was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'meeting_speakers';

  @override
  Set<Column> get primaryKey => {id};
}
