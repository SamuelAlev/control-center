import 'package:cc_persistence/database/tables/checks/stored_values_spaces.dart';
import 'package:drift/drift.dart';

/// Maps one external chat conversation (a space `@mention` thread, or a bot
/// DM) to one Control Center space.
///
/// `(provider, external_channel_id, external_thread_id)` is unique — one CC
/// space per external thread — and `cc_space_id` is the reverse lookup the
/// outbound relay uses to find where an agent turn should stream. Deleting
/// the CC space cascades: the external thread simply loses its bridge and the
/// next `@mention` opens a fresh space.
///
/// `provider` is part of every unique index and every lookup, so two providers
/// whose id spaces collide cannot resolve each other's conversations.
///
/// SQLite treats NULLs as distinct in a UNIQUE index, so the uniqueness of a
/// conversation-level link (null `external_thread_id`, i.e. a bot DM) is
/// enforced by a second, partial index.
@TableIndex(
  name: 'uq_chat_space_links_ws_provider_space_thread',
  columns: {#provider, #externalChannelId, #externalThreadId},
  unique: true,
)
@TableIndex.sql(
  'CREATE UNIQUE INDEX uq_chat_space_links_ws_provider_dm '
  'ON chat_space_links (provider, external_channel_id) '
  'WHERE external_thread_id IS NULL',
)
@TableIndex(name: 'idx_chat_space_links_ccSpaceId', columns: {#ccSpaceId})
class ChatSpaceLinksTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope (isolation invariant).
  TextColumn get workspaceId => text()();

  /// Which chat product the external side lives on (`ChatProvider.wire`).
  TextColumn get provider => text().check(
    // ignore: recursive_getters
    provider.isIn(SpacesStoredValues.chatProvider),
  )();

  /// Provider-side workspace/guild id (Slack `T024BE7LD`). Empty for a provider
  /// with no such concept.
  TextColumn get externalTeamId => text().withDefault(const Constant(''))();

  /// Provider-side conversation id (Slack space `C…`, group `G…`, DM `D…`).
  TextColumn get externalChannelId => text()();

  /// Provider-side thread anchor (Slack's thread-parent `ts`), or null when the
  /// whole conversation is the anchor (bot DMs).
  TextColumn get externalThreadId => text().nullable()();

  /// The Control Center space this external thread drives.
  TextColumn get ccSpaceId => text().customConstraint(
    'NOT NULL REFERENCES spaces (id) ON DELETE CASCADE',
  )();

  /// The CC user whose message created the link, when known. No foreign
  /// key: `users` lives in `global.db`.
  TextColumn get createdByUserId => text().nullable()();

  /// When the link was created.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  /// Last time a message crossed the bridge in either direction.
  DateTimeColumn get lastActivityAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'chat_space_links';

  @override
  Set<Column> get primaryKey => {id};
}

/// Maps one external chat member to one Control Center user inside one
/// workspace.
///
/// This is the bridge's identity resolution — a chat message is attributed to
/// the linked CC user — and it is deliberately NOT an access grant: the bridge
/// re-checks workspace membership on every inbound event, so a link to a user
/// who has since been removed resolves to a refusal.
///
/// `(provider, external_team_id, external_user_id)` is unique (one CC user
/// per external member) and so is `(provider, user_id)` (one identity **per
/// provider** per CC user), which keeps attribution single-valued in both
/// directions while letting one person be linked on Slack and Discord at once.
@TableIndex(
  name: 'uq_chat_user_links_ws_provider_team_user',
  columns: {#provider, #externalTeamId, #externalUserId},
  unique: true,
)
@TableIndex(
  name: 'uq_chat_user_links_ws_provider_user',
  columns: {#provider, #userId},
  unique: true,
)
class ChatUserLinksTable extends Table {
  /// Unique row id (UUID v4).
  TextColumn get id => text()();

  /// Workspace scope (isolation invariant).
  TextColumn get workspaceId => text()();

  /// Which chat product the external identity lives on (`ChatProvider.wire`).
  TextColumn get provider => text().check(
    // ignore: recursive_getters
    provider.isIn(SpacesStoredValues.chatProvider),
  )();

  /// Provider-side workspace/guild id. Empty for a provider with no such
  /// concept.
  TextColumn get externalTeamId => text().withDefault(const Constant(''))();

  /// Provider-side member id (Slack `U024BE7LH`).
  TextColumn get externalUserId => text()();

  /// The Control Center user id. Global (`users` lives in `global.db`), so this
  /// deliberately carries no foreign key.
  TextColumn get userId => text()();

  /// How the link was established (`ChatLinkMethod.wire`).
  TextColumn get method => text()
      .check(
        // ignore: recursive_getters
        method.isIn(SpacesStoredValues.chatLinkMethod),
      )
      .withDefault(const Constant('code'))();

  /// When the link was established.
  DateTimeColumn get linkedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'chat_user_links';

  @override
  Set<Column> get primaryKey => {id};
}
