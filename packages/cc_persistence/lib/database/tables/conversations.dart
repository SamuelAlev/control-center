import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for conversations (message streams) inside a space.
///
/// A space owns the worktree, participants, autonomy and provisioning; a conversation owns
/// a stream of messages and the agent run sessions bound to it.
/// A space holds MANY conversations, all sharing its one worktree while keeping their own
/// history + agent sessions.
@TableIndex(name: 'idx_conversations_spaceId', columns: {#spaceId})
@TableIndex(
  name: 'idx_conversations_anchorMessageId',
  columns: {#anchorMessageId},
)
@TableIndex(name: 'idx_conversations_leafMessageId', columns: {#leafMessageId})
class ConversationsTable extends Table {
  /// Conversation id — its own uuid, never the owning space's.
  TextColumn get id => text()();

  /// Owning workspace (isolation scope), the same as its space's.
  TextColumn get workspaceId => text()();

  /// The space this conversation belongs to.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// Human-readable title (sentence case). Empty ⇒ untitled: the UI renders
  /// the untitled placeholder and the workspace's title model names the
  /// conversation from its first human message. There is no 'Main' default —
  /// every mint path writes its title explicitly.
  TextColumn get title => text().withDefault(const Constant(''))();

  /// `active` | `archived` (`ConversationStatus.wire`).
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(SpacesStoredValues.conversationStatus),
      )
      .withDefault(const Constant('active'))();

  /// Anchor message when this conversation is a thread: a message in a
  /// sibling conversation of the same space that seeds the thread's fresh
  /// agent context. Threads never nest — the anchor's own conversation must
  /// be unanchored.
  ///
  /// `ON DELETE SET NULL`: deleting the anchor deletes that one message, not
  /// the thread hanging off it and every reply in it. The thread lives on as
  /// an ordinary conversation of the space; a caller that means "this message
  /// and its threads" says so (`MessagingDao.clearSpaceMessages`).
  TextColumn get anchorMessageId => text().nullable().customConstraint(
    'REFERENCES conversation_messages(id) ON DELETE SET NULL',
  )();

  /// Principal that opened this conversation, when known. No foreign key:
  /// a principal is a user (in `global.db`) or an agent.
  TextColumn get createdByPrincipalId => text().nullable()();

  /// The tip of the branch this conversation is currently on.
  ///
  /// Branching writes nothing: it moves this pointer, and the next message
  /// appended takes whatever it names as its parent. That one decision is what
  /// makes rewind, fork and `/tree` non-destructive by construction, and what
  /// makes a failed branch switch a pointer move back rather than a restore.
  ///
  /// Null means "the newest message", which is what every conversation written
  /// before the tree existed means.
  ///
  /// `ON DELETE SET NULL`: deleting the tip message falls back to that.
  TextColumn get leafMessageId => text().nullable().customConstraint(
    'REFERENCES conversation_messages(id) ON DELETE SET NULL',
  )();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'conversations';

  @override
  Set<Column> get primaryKey => {id};
}
