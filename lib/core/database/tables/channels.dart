import 'package:control_center/core/database/tables/workspaces.dart';
import 'package:drift/drift.dart';

@TableIndex(name: 'idx_channels_workspaceId', columns: {#workspaceId})
/// Drift table definition for messaging channels (DMs and group channels).
class ChannelsTable extends Table {
  /// Id.
  TextColumn get id => text()();
  /// Name.
  TextColumn get name => text()();
  /// Workspace id.
  TextColumn get workspaceId => text().nullable().references(
    WorkspacesTable,
    #id,
    onDelete: KeyAction.cascade,
  )();
  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  /// Conversation mode. Stored as the `name` of the `ConversationMode` enum
  /// (`chat`, `review`, `plan`). Defaults to `chat` for legacy rows.
  TextColumn get mode => text().withDefault(const Constant('chat'))();

  @override
  String get tableName => 'channels';

  @override
  Set<Column> get primaryKey => {id};
}

