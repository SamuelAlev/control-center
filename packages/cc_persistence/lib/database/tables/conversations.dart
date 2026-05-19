import 'package:cc_persistence/database/tables/spaces.dart';
import 'package:drift/drift.dart';

/// Drift table for conversations (message streams) inside a space.
///
/// A space owns the worktree, participants, autonomy and provisioning; a
/// conversation owns a stream of messages and the agent run sessions bound to
/// it. A space holds MANY conversations, all sharing its one worktree while
/// keeping their own history + agent sessions.
///
/// There is **no `main` conversation and no id aliasing**. Every conversation
/// carries its own uuid, so a conversation id is never a space id — the two
/// were briefly the same value and every place that still assumes it is a
/// silent bug, not a shortcut (see `ConversationDao.ensureStandingConversation`
/// for what "the space's conversation" resolves to instead). What a space opens
/// on is its STANDING conversation: the oldest active, unanchored one.
///
/// Workspace-scoped (isolation invariant): every read filters on `workspaceId`.
@TableIndex(name: 'idx_conversations_spaceId', columns: {#spaceId})
@TableIndex(name: 'idx_conversations_workspaceId', columns: {#workspaceId})
class ConversationsTable extends Table {
  /// Conversation id — its own uuid, never the owning space's.
  TextColumn get id => text()();

  /// Owning workspace (isolation scope). Nullable to mirror [SpacesTable]
  /// (a conversation can never be more strictly scoped than its space; some
  /// system/legacy spaces carry a null workspace).
  TextColumn get workspaceId => text().nullable()();

  /// The space this conversation belongs to.
  TextColumn get spaceId =>
      text().references(SpacesTable, #id, onDelete: KeyAction.cascade)();

  /// Human-readable title (sentence case). Empty ⇒ untitled: the UI renders
  /// the untitled placeholder and the workspace's title model names the
  /// conversation from its first human message. There is no 'Main' default —
  /// every mint path writes its title explicitly.
  TextColumn get title => text().withDefault(const Constant(''))();

  /// `active` | `archived`.
  TextColumn get status => text().withDefault(const Constant('active'))();

  /// Anchor message when this conversation is a thread: a message in a
  /// sibling conversation of the same space that seeds the thread's fresh
  /// agent context. Threads never nest — the anchor's own conversation must
  /// be unanchored.
  TextColumn get anchorMessageId => text().nullable().customConstraint(
    'REFERENCES conversation_messages(id) ON DELETE CASCADE',
  )();

  /// Principal that opened this conversation, when known.
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
  TextColumn get leafMessageId => text().nullable()();

  /// Created at.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Updated at.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'conversations';

  @override
  Set<Column> get primaryKey => {id};
}
