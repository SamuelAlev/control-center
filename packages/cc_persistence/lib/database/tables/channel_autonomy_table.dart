import 'package:cc_persistence/database/tables/channels.dart';
import 'package:drift/drift.dart';

/// Graduated per-channel agent autonomy (PRD 16 §12): each agent's autonomy
/// is a first-class, adjustable per-channel control — `proposeOnly` /
/// `actWithApproval` / `actFreely` — enforced at the harness's fail-closed
/// approval gate.
@TableIndex(name: 'idx_channel_autonomy_workspaceId', columns: {#workspaceId})
class ChannelAutonomyTable extends Table {
  /// Id.
  TextColumn get id => text()();

  /// Workspace id (isolation invariant).
  TextColumn get workspaceId => text()();

  /// The channel this dial applies to.
  TextColumn get channelId =>
      text().references(ChannelsTable, #id, onDelete: KeyAction.cascade)();

  /// The agent the dial applies to.
  TextColumn get agentId => text()();

  /// `proposeOnly` | `actWithApproval` | `actFreely`.
  TextColumn get autonomyLevel => text()();

  /// Last change time.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'channel_autonomy';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, channelId, agentId},
  ];
}
