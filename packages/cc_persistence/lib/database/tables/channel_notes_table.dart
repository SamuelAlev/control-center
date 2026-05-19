import 'package:cc_persistence/database/tables/channels.dart';
import 'package:drift/drift.dart';

/// The shared per-channel Notes / context doc (PRD 16 §11): a living
/// handoff document both humans and agents read/write. One doc per channel.
///
/// Authoritative-LWW at the column level with soft-claims for conflict
/// visibility — deliberately NOT a CRDT (the burden of proof is on the CRDT;
/// see the PRD's adversarial notes). `version` increments per write so
/// clients can detect their own echoes.
@TableIndex(name: 'idx_channel_notes_workspaceId', columns: {#workspaceId})
class ChannelNotesTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Workspace id — notes are workspace-scoped (isolation invariant).
  TextColumn get workspaceId => text()();

  /// The channel this doc belongs to (one doc per channel).
  TextColumn get channelId =>
      text().references(ChannelsTable, #id, onDelete: KeyAction.cascade)();

  /// The document body (markdown).
  TextColumn get contentMarkdown => text().withDefault(const Constant(''))();

  /// The last writer (`user:<id>` / `agent:<id>` principal wire form).
  TextColumn get updatedByPrincipal => text()();

  /// Last write time (display only — ordering is the sync seq).
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  /// Monotonic per-doc write counter.
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  String get tableName => 'channel_notes';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, channelId},
  ];
}
