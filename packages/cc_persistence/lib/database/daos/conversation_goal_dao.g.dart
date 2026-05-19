// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_goal_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationGoalDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $SpacesTableTable get spacesTable => attachedDatabase.spacesTable;
  $ConversationGoalsTableTable get conversationGoalsTable =>
      attachedDatabase.conversationGoalsTable;
  ConversationGoalDaoManager get managers => ConversationGoalDaoManager(this);
}

class ConversationGoalDaoManager {
  final _$ConversationGoalDaoMixin _db;
  ConversationGoalDaoManager(this._db);
  $$SpacesTableTableTableManager get spacesTable =>
      $$SpacesTableTableTableManager(_db.attachedDatabase, _db.spacesTable);
  $$ConversationGoalsTableTableTableManager get conversationGoalsTable =>
      $$ConversationGoalsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationGoalsTable,
      );
}
