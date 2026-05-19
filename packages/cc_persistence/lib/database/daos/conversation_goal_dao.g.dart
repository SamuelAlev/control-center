// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation_goal_dao.dart';

// ignore_for_file: type=lint
mixin _$ConversationGoalDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $ChannelsTableTable get channelsTable => attachedDatabase.channelsTable;
  $ConversationGoalsTableTable get conversationGoalsTable =>
      attachedDatabase.conversationGoalsTable;
  ConversationGoalDaoManager get managers => ConversationGoalDaoManager(this);
}

class ConversationGoalDaoManager {
  final _$ConversationGoalDaoMixin _db;
  ConversationGoalDaoManager(this._db);
  $$ChannelsTableTableTableManager get channelsTable =>
      $$ChannelsTableTableTableManager(_db.attachedDatabase, _db.channelsTable);
  $$ConversationGoalsTableTableTableManager get conversationGoalsTable =>
      $$ConversationGoalsTableTableTableManager(
        _db.attachedDatabase,
        _db.conversationGoalsTable,
      );
}
