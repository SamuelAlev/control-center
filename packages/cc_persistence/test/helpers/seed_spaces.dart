import 'package:cc_persistence/cc_persistence.dart';

import 'seed_agents.dart';

// Parent rows for tests of the space, conversation, notification, calendar,
// meeting and memory tables, whose foreign keys are enforced.
//
// Each helper inserts the smallest valid row with `INSERT OR IGNORE`, so a
// test can seed a parent it may already have created. The rows carry the
// database's own workspace id. Spaces, conversations and agents come from
// `seed_agents.dart`.

/// Seeds message [id] in [conversationId] (seeded too, in a space of the same
/// id unless [spaceId] names one), sent by an agent.
Future<void> seedMessage(
  WorkspaceDatabase db,
  String id, {
  String conversationId = 'conversation',
  String? spaceId,
  String? parentMessageId,
}) async {
  final space = spaceId ?? conversationId;
  await seedConversation(db, conversationId, spaceId: space);
  await db.customStatement(
    'INSERT OR IGNORE INTO conversation_messages '
    '(id, space_id, conversation_id, sender_id, sender_type, content, '
    'parent_message_id) '
    "VALUES (?, ?, ?, 'agent', 'agent', ?, ?)",
    [id, space, conversationId, 'Message $id', parentMessageId],
  );
}

/// Seeds notification feed item [id].
Future<void> seedFeedItem(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO notification_feed '
      '(id, workspace_id, method, params_json) VALUES (?, ?, ?, ?)',
      [id, db.workspaceId, 'notifications/test', '{}'],
    );

/// Seeds memory fact [id].
Future<void> seedMemoryFact(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO memory_facts '
      '(id, workspace_id, domain, topic, content) VALUES (?, ?, ?, ?, ?)',
      [id, db.workspaceId, 'domain', 'topic', 'Fact $id'],
    );

/// Seeds meeting [id].
Future<void> seedMeeting(WorkspaceDatabase db, String id) => db.customStatement(
  'INSERT OR IGNORE INTO meetings (id, workspace_id, title) VALUES (?, ?, ?)',
  [id, db.workspaceId, 'Meeting $id'],
);

/// Seeds calendar account [id]; its email is derived from the id, so
/// several accounts stay distinct.
Future<void> seedCalendarAccount(WorkspaceDatabase db, String id) =>
    db.customStatement(
      'INSERT OR IGNORE INTO calendar_accounts '
      '(id, workspace_id, account_email) VALUES (?, ?, ?)',
      [id, db.workspaceId, '$id@example.com'],
    );

/// Seeds calendar event [id] of account [accountId] (seeded too).
Future<void> seedCalendarEvent(
  WorkspaceDatabase db,
  String id, {
  String accountId = 'account',
}) async {
  await seedCalendarAccount(db, accountId);
  await db.customStatement(
    'INSERT OR IGNORE INTO calendar_events '
    '(id, workspace_id, account_id, external_event_id, calendar_id, title, '
    'start_time, end_time) VALUES (?, ?, ?, ?, ?, ?, 0, 0)',
    [id, db.workspaceId, accountId, id, 'primary', 'Event $id'],
  );
}
