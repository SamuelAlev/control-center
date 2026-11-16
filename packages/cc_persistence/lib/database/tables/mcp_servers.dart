import 'package:cc_persistence/database/tables/checks/column_checks.dart';
import 'package:cc_persistence/database/tables/checks/stored_values_platform.dart';
import 'package:drift/drift.dart';

/// Drift table of the MCP servers configured by hand for a workspace.
///
/// **Workspace-scoped**, with no `workspace_id` column for the same reason as
/// `repos`: the database file is the scope, so a name is unique within the
/// workspace by being unique within the table.
///
/// It holds no secret. Environment variable and header values live in the
/// server's secrets store; a row keeps only their names ([envNamesJson],
/// [headerNamesJson]).
class McpServersTable extends Table {
  /// Server id.
  TextColumn get id => text()();

  /// Unique within the workspace; namespaces the server's tools
  /// (`mcp__<name>__<tool>`).
  TextColumn get name => text()();

  /// How it is reached: `stdio`, `http` or `sse`.
  TextColumn get transport => text().check(
    // ignore: recursive_getters
    transport.isIn(PlatformStoredValues.mcpServerTransport),
  )();

  /// The executable (stdio only).
  TextColumn get command => text().nullable()();

  /// The executable's arguments, as a JSON array of strings (stdio only).
  TextColumn get argsJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(argsJson))
      .withDefault(const Constant('[]'))();

  /// The endpoint (http and sse only).
  TextColumn get url => text().nullable()();

  /// The names of the environment variables set for the process, as a JSON
  /// array of strings. Their values are secrets and are not stored here.
  TextColumn get envNamesJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(envNamesJson))
      .withDefault(const Constant('[]'))();

  /// The names of the headers sent with every request, as a JSON array of
  /// strings. Their values are secrets and are not stored here.
  TextColumn get headerNamesJson => text()
      // ignore: recursive_getters
      .check(isJsonArray(headerNamesJson))
      .withDefault(const Constant('[]'))();

  /// Whether it is dialled at all.
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Who added it. No foreign key: users live in the global database.
  TextColumn get createdBy => text().nullable()();

  /// The server owner who approved it as it stands, or null. Written only by
  /// the server, never from a client's copy. No foreign key: users live in
  /// the global database.
  TextColumn get hostApprovedBy => text().nullable()();

  /// When it was added.
  DateTimeColumn get createdAt => dateTime()();

  /// When it last changed.
  DateTimeColumn get updatedAt => dateTime()();

  @override
  String get tableName => 'mcp_servers';

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {name},
  ];
}
