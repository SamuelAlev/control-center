import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_domain/features/mcp/domain/repositories/mcp_server_definition_repository.dart';
import 'package:cc_infra/cc_paths.dart' show writePrivateFile;
import 'package:path/path.dart' as p;

/// The server owner's hand-added MCP servers, in `mcp_personal_servers.json`
/// under the data directory (owner-only, like the rest of the host's own
/// MCP state). Holds definitions only; their values live in the secrets file.
///
/// A row that no longer validates is skipped on read rather than failing the
/// whole list, so one bad entry never hides the others.
class FilePersonalMcpServerRepository implements PersonalMcpServerRepository {
  /// Creates the store under [dataDir].
  FilePersonalMcpServerRepository({required String dataDir})
    : _file = File(p.join(dataDir, fileName));

  /// The file's name under the data directory.
  static const fileName = 'mcp_personal_servers.json';

  final File _file;
  Future<void> _writes = Future<void>.value();

  Future<Map<String, McpServerDefinition>> _read() async {
    final String raw;
    try {
      raw = await _file.readAsString();
    } on FileSystemException {
      return {};
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return {};
    }
    final servers = decoded is Map ? decoded['servers'] : null;
    if (servers is! List) {
      return {};
    }
    final byId = <String, McpServerDefinition>{};
    for (final entry in servers) {
      if (entry is! Map) {
        continue;
      }
      try {
        final definition = McpServerDefinition.fromJson(
          entry.cast<String, dynamic>(),
        );
        if (definition.workspaceId == null) {
          byId[definition.id] = definition;
        }
      } on Object {
        // A row this build cannot read is skipped, not fatal.
      }
    }
    return byId;
  }

  /// Runs [change] on the current rows and writes the result, one change at
  /// a time so two saves never lose each other.
  Future<T> _mutate<T>(
    Future<T> Function(Map<String, McpServerDefinition> rows) change,
  ) {
    late T result;
    final run = _writes.then((_) async {
      final rows = await _read();
      result = await change(rows);
      final sorted = rows.values.toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      await _file.parent.create(recursive: true);
      await writePrivateFile(
        _file.path,
        utf8.encode(
          jsonEncode({
            'servers': [for (final d in sorted) d.toJson()],
          }),
        ),
      );
    });
    _writes = run.catchError((_) {});
    return run.then((_) => result);
  }

  @override
  Future<List<McpServerDefinition>> list() async =>
      (await _read()).values.toList()..sort((a, b) => a.name.compareTo(b.name));

  @override
  Future<McpServerDefinition?> get(String id) async => (await _read())[id];

  @override
  Future<void> save(McpServerDefinition definition) {
    if (definition.workspaceId != null) {
      throw ArgumentError.value(
        definition.workspaceId,
        'definition.workspaceId',
        'a personal server has no workspace',
      );
    }
    return _mutate((rows) async {
      final clash = rows.values.any(
        (d) => d.id != definition.id && d.name == definition.name,
      );
      if (clash) {
        throw const McpServerDefinitionException.nameTaken();
      }
      rows[definition.id] = definition;
    });
  }

  @override
  Future<bool> delete(String id) =>
      _mutate((rows) async => rows.remove(id) != null);
}
