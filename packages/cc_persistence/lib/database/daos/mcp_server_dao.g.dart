// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mcp_server_dao.dart';

// ignore_for_file: type=lint
mixin _$McpServerDaoMixin on DatabaseAccessor<WorkspaceDatabase> {
  $McpServersTableTable get mcpServersTable => attachedDatabase.mcpServersTable;
  McpServerDaoManager get managers => McpServerDaoManager(this);
}

class McpServerDaoManager {
  final _$McpServerDaoMixin _db;
  McpServerDaoManager(this._db);
  $$McpServersTableTableTableManager get mcpServersTable =>
      $$McpServersTableTableTableManager(
        _db.attachedDatabase,
        _db.mcpServersTable,
      );
}
