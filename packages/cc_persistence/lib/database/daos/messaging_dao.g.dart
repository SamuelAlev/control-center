// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'messaging_dao.dart';

// ignore_for_file: type=lint
mixin _$MessagingDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $PipelineRunsTableTable get pipelineRunsTable =>
      attachedDatabase.pipelineRunsTable;
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $ConversationsTableTable get conversationsTable =>
      attachedDatabase.conversationsTable;
  $SpaceParticipantsTableTable get spaceParticipantsTable =>
      attachedDatabase.spaceParticipantsTable;
  $ConversationMessagesTableTable get conversationMessagesTable =>
      attachedDatabase.conversationMessagesTable;
  $ConversationActivityTableTable get conversationActivityTable =>
      attachedDatabase.conversationActivityTable;
  $ConversationMessageEmbeddingsTableTable
  get conversationMessageEmbeddingsTable =>
      attachedDatabase.conversationMessageEmbeddingsTable;
  MessagingDaoManager get managers => MessagingDaoManager(this);
}

class MessagingDaoManager {
  final _$MessagingDaoMixin _db;
  MessagingDaoManager(this._db);
  $$PipelineRunsTableTableTableManager get pipelineRunsTable =>
      $$PipelineRunsTableTableTableManager(
        _db.attachedDatabase,
        _db.pipelineRunsTable,
      );
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$ConversationsTableTableTableManager get conversationsTable =>
      $$ConversationsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationsTable,
      );
  $$SpaceParticipantsTableTableTableManager get spaceParticipantsTable =>
      $$SpaceParticipantsTableTableTableManager(
        _db.attachedDatabase,
        _db.spaceParticipantsTable,
      );
  $$ConversationMessagesTableTableTableManager get conversationMessagesTable =>
      $$ConversationMessagesTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationMessagesTable,
      );
  $$ConversationActivityTableTableTableManager get conversationActivityTable =>
      $$ConversationActivityTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationActivityTable,
      );
  $$ConversationMessageEmbeddingsTableTableTableManager
  get conversationMessageEmbeddingsTable =>
      $$ConversationMessageEmbeddingsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationMessageEmbeddingsTable,
      );
}
