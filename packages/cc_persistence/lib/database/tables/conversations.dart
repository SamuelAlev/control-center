import 'package:cc_persistence/database/tables/channels.dart';
import 'package:drift/drift.dart';

/// Drift table for conversations (message streams) inside a channel.
///
/// A channel owns the worktree, participants, autonomy, and provisioning; a
/// conversation owns a stream of messages and the agent run sessions bound to
/// it. Every channel has exactly one `main` conversation whose **id equals the
/// channel id**; users open additional `parenthesis` conversations that share
/// the channel worktree but keep their own history + agent sessions.
///
/// Workspace-scoped (isolation invariant): every read filters on `workspaceId`.
@TableIndex(name: 'idx_conversations_channelId', columns: {#channelId})
@TableIndex(name: 'idx_conversations_workspaceId', columns: {#workspaceId})
class ConversationsTable extends Table {
  /// Conversation id. For the `main` conversation this equals the channel id.
  TextColumn get id => text()();

  /// Owning workspace (isolation scope). Nullable to mirror [ChannelsTable]
  /// (a conversation can never be more strictly scoped than its channel; some
  /// system/legacy channels carry a null workspace).
  TextColumn get workspaceId => text().nullable()();

  /// The channel this conversation belongs to.
  TextColumn get channelId =>
      text().references(ChannelsTable, #id, onDelete: KeyAction.cascade)();

  /// Human-readable title (sentence case).
  TextColumn get title => text().withDefault(const Constant('Main'))();

  /// `main` | `parenthesis`.
  TextColumn get kind => text().withDefault(const Constant('main'))();

  /// `active` | `archived`.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Principal that opened this conversation, when known.
  TextColumn get createdByPrincipalId => text().nullable()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'conversations';

  @override
  Set<Column> get primaryKey => {id};
}
