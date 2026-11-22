import 'package:cc_persistence/database/tables/agents.dart';
import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_agents.dart';
import 'package:cc_persistence/database/tables/conversations.dart';
import 'package:drift/drift.dart';

/// One agent asking another (`PeerAsk`): `ask_agent`, `consult_agent`,
/// `request_peer_review`. Written before the recipient is dispatched, so
/// depth, cycle, repeat and pending-count checks read rows instead of a map
/// that lives only as long as one blocking call.
///
/// An ask goes with its asker, its recipient and the conversation it was
/// asked from (`CASCADE`): the reply has nowhere to go without them. The
/// recipient's conversation, the runs and the messages are values, not keys.
@TableIndex(
  name: 'idx_peer_asks_recipient_status',
  columns: {#recipientAgentId, #status},
)
@TableIndex(
  name: 'idx_peer_asks_asker_status',
  columns: {#askerAgentId, #status},
)
@TableIndex(name: 'idx_peer_asks_dispatched_run', columns: {#dispatchedRunId})
@TableIndex(
  name: 'idx_peer_asks_asker_conversation_status',
  columns: {#askerConversationId, #status},
)
@TableIndex(
  name: 'idx_peer_asks_status_expires',
  columns: {#status, #expiresAt},
)
class PeerAsksTable extends Table {
  /// Unique ask id.
  TextColumn get id => text()();

  /// Owning workspace (this file's workspace).
  TextColumn get workspaceId => text()();

  /// `ask`, `consult` or `review`: a `PeerAskKind` wire name.
  TextColumn get kind => text()
      .check(
        // ignore: recursive_getters
        kind.isIn(AgentsStoredValues.peerAskKind),
      )
      .withDefault(const Constant('ask'))();

  /// `wait` or `background`: a `PeerAskMode` wire name.
  TextColumn get mode => text()
      .check(
        // ignore: recursive_getters
        mode.isIn(AgentsStoredValues.peerAskMode),
      )
      .withDefault(const Constant('wait'))();

  /// The asking agent. `CASCADE`.
  @ReferenceName('peerAsksMade')
  TextColumn get askerAgentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The asking agent's run. A value, not a key.
  TextColumn get askerRunId => text().nullable()();

  /// The conversation the asker asked from; the reply wake goes here.
  /// `CASCADE`.
  TextColumn get askerConversationId =>
      text().references(ConversationsTable, #id, onDelete: KeyAction.cascade)();

  /// That conversation's space. Not a key: the conversation goes with it.
  TextColumn get askerSpaceId => text()();

  /// The agent asked. `CASCADE`.
  @ReferenceName('peerAsksReceived')
  TextColumn get recipientAgentId =>
      text().references(AgentsTable, #id, onDelete: KeyAction.cascade)();

  /// The conversation the recipient answers in, once known. A value.
  TextColumn get recipientConversationId => text().nullable()();

  /// That conversation's space, once known. A value.
  TextColumn get recipientSpaceId => text().nullable()();

  /// The question's message id. A value.
  TextColumn get questionMessageId => text().nullable()();

  /// A hash of the question text (the 10-minute repeat refusal).
  TextColumn get questionHash => text()();

  /// The recipient's run that answers. A value.
  TextColumn get dispatchedRunId => text().nullable()();

  /// JSON array of the agent ids that led to this ask, oldest first.
  TextColumn get chain => text()
      // ignore: recursive_getters
      .check(isJsonArray(chain))
      .withDefault(const Constant('[]'))();

  /// Where it is: a `PeerAskStatus` wire name.
  TextColumn get status => text()
      .check(
        // ignore: recursive_getters
        status.isIn(AgentsStoredValues.peerAskStatus),
      )
      .withDefault(const Constant('pending'))();

  /// The recipient's final message (the answer). A value.
  TextColumn get replyMessageId => text().nullable()();

  /// Whether the blocking call already returned the reply, so no wake is
  /// owed.
  BoolColumn get replyInline => boolean().withDefault(const Constant(false))();

  /// Why it failed.
  TextColumn get error => text().nullable()();

  /// The accountable person, or null for the bot.
  TextColumn get requestedByUserId => text().nullable()();

  /// When it was written.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// When it expires if nothing came back.
  DateTimeColumn get expiresAt => dateTime()();

  /// When it settled.
  DateTimeColumn get settledAt => dateTime().nullable()();

  /// When the recipient ended a run without the answer but with a wake set
  /// (set once, while pending).
  DateTimeColumn get promisedAt => dateTime().nullable()();

  /// When the asker was told the recipient waits on a person (set once,
  /// while pending).
  DateTimeColumn get blockedNoticedAt => dateTime().nullable()();

  /// The recipient's run that was reminded that somebody waits for its
  /// answer (set once, while pending). No foreign key: a run id is a value.
  TextColumn get stallNoticedRunId => text().nullable()();

  @override
  String get tableName => 'peer_asks';

  @override
  Set<Column> get primaryKey => {id};

  // The entity's rules that cost nothing to keep here as well, so an import
  // or a hand edit cannot leave an ask no reader can map. Times are whole
  // seconds here, so the ordering allows equality.
  @override
  List<String> get customConstraints => [
    'CHECK (asker_agent_id <> recipient_agent_id)',
    'CHECK (expires_at >= created_at)',
    'CHECK (error IS NULL OR length(error) <= 2000)',
  ];
}
