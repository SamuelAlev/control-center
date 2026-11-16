import 'package:cc_domain/core/domain/repositories/workspace_repository.dart'
    show DeletedWorkspaceException;
import 'package:cc_domain/features/mcp/domain/entities/mcp_server_definition.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/database/utils/storage_errors.dart';
import 'package:cc_persistence/mappers/mcp_server_mapper.dart';
import 'package:sqlite3/common.dart' show SqlExtendedError;
import 'package:test/test.dart';

import 'helpers/seed_platform.dart';
import 'helpers/test_database.dart';

/// Round trips, name uniqueness and isolation for the workspace MCP server
/// repository, against real per-workspace databases so a server in one
/// workspace really is in another file.
void main() {
  final createdAt = DateTime.utc(2026, 3, 4, 5, 6, 7);
  final updatedAt = DateTime.utc(2026, 3, 5, 6, 7, 8);

  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoWorkspaceMcpServerRepository repository;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    for (final workspaceId in ['ws-a', 'ws-b']) {
      await seedWorkspaceRow(global, workspaceId);
    }
    repository = DaoWorkspaceMcpServerRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  McpServerDefinition stdio({
    String id = 'mcp-1',
    String? workspaceId = 'ws-a',
    String name = 'files',
    bool enabled = true,
    String? hostApprovedBy,
  }) => McpServerDefinition(
    id: id,
    workspaceId: workspaceId,
    name: name,
    transport: McpServerTransport.stdio,
    command: 'npx',
    args: const ['-y', '@scope/files-server', '--root', '/srv/data'],
    envNames: const ['TOKEN', 'API_KEY'],
    enabled: enabled,
    createdBy: 'user-1',
    hostApprovedBy: hostApprovedBy,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  McpServerDefinition remote({
    String id = 'mcp-2',
    String workspaceId = 'ws-a',
    String name = 'tracker',
    McpServerTransport transport = McpServerTransport.http,
  }) => McpServerDefinition(
    id: id,
    workspaceId: workspaceId,
    name: name,
    transport: transport,
    url: 'https://mcp.example.com/v1',
    headerNames: const ['X-Api-Key', 'Authorization'],
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  group('round trip', () {
    test('a stdio server comes back equal to what was saved', () async {
      final server = stdio(hostApprovedBy: 'owner-1');
      await repository.save(server);

      final loaded = await repository.get('ws-a', 'mcp-1');

      expect(loaded, server);
      expect(loaded!.workspaceId, 'ws-a');
      expect(loaded.args, ['-y', '@scope/files-server', '--root', '/srv/data']);
      expect(loaded.envNames, ['API_KEY', 'TOKEN']);
      expect(loaded.createdAt.isUtc, isTrue);
    });

    test('remote servers come back equal to what was saved', () async {
      final http = remote();
      final sse = remote(
        id: 'mcp-3',
        name: 'legacy',
        transport: McpServerTransport.sse,
      );
      await repository.save(http);
      await repository.save(sse);

      expect(await repository.get('ws-a', 'mcp-2'), http);
      expect(await repository.get('ws-a', 'mcp-3'), sse);
    });

    test('list returns every server of the workspace by name', () async {
      await repository.save(remote(id: 'z', name: 'zeta'));
      await repository.save(stdio(id: 'a', name: 'alpha'));
      await repository.save(remote(id: 'm', name: 'mid'));

      final names = [for (final s in await repository.list('ws-a')) s.name];

      expect(names, ['alpha', 'mid', 'zeta']);
    });

    test('saving an existing id replaces it in place', () async {
      await repository.save(stdio(hostApprovedBy: 'owner-1'));
      final edited = stdio(
        name: 'renamed',
        enabled: false,
      ).copyWith(updatedAt: DateTime.utc(2026, 4));

      await repository.save(edited);

      expect(await repository.get('ws-a', 'mcp-1'), edited);
      expect(await repository.list('ws-a'), [edited]);
    });

    test('switching transport leaves no stale launch fields', () async {
      await repository.save(stdio());
      final switched = remote(id: 'mcp-1', name: 'files');

      await repository.save(switched);

      final loaded = await repository.get('ws-a', 'mcp-1');
      expect(loaded, switched);
      expect(loaded!.command, isNull);
      expect(loaded.args, isEmpty);
      expect(loaded.envNames, isEmpty);
    });

    test('get answers null for an unknown id', () async {
      expect(await repository.get('ws-a', 'missing'), isNull);
    });

    test('delete removes the server and reports it', () async {
      await repository.save(stdio());

      expect(await repository.delete('ws-a', 'mcp-1'), isTrue);
      expect(await repository.get('ws-a', 'mcp-1'), isNull);
      expect(await repository.list('ws-a'), isEmpty);
    });

    test('delete answers false when there is no such server', () async {
      expect(await repository.delete('ws-a', 'missing'), isFalse);
    });
  });

  group('name uniqueness', () {
    test('a second server with a taken name is refused', () async {
      await repository.save(stdio());

      await expectLater(
        repository.save(remote(id: 'mcp-2', name: 'files')),
        throwsA(
          isA<McpServerDefinitionException>().having(
            (e) => e.code,
            'code',
            'mcp_server.name_taken',
          ),
        ),
      );
      expect(await repository.list('ws-a'), [stdio()]);
    });

    test('a rename onto a taken name is refused and changes nothing', () async {
      await repository.save(stdio());
      await repository.save(remote());

      await expectLater(
        repository.save(remote(name: 'files')),
        throwsA(isA<McpServerDefinitionException>()),
      );
      expect(await repository.get('ws-a', 'mcp-2'), remote());
      expect(await repository.get('ws-a', 'mcp-1'), stdio());
    });

    test('the DAO reports a clash instead of writing it', () async {
      await repository.save(stdio());

      final saved = await dbs
          .of('ws-a')
          .mcpServerDao
          .upsert(
            const McpServerMapper().toCompanion(remote(id: 'x', name: 'files')),
          );

      expect(saved, isFalse);
      expect(await repository.get('ws-a', 'x'), isNull);
    });

    test('the schema refuses a clash that skips the check', () async {
      await repository.save(stdio());
      final db = dbs.of('ws-a');

      await expectLater(
        db
            .into(db.mcpServersTable)
            .insert(
              const McpServerMapper().toCompanion(
                remote(id: 'x', name: 'files'),
              ),
            ),
        throwsA(
          predicate(
            (Object? e) =>
                sqliteCauseOf(e)?.extendedResultCode ==
                SqlExtendedError.SQLITE_CONSTRAINT_UNIQUE,
            'a UNIQUE constraint failure',
          ),
        ),
      );
    });

    test('the same name may be used in another workspace', () async {
      await repository.save(stdio());
      await repository.save(stdio(workspaceId: 'ws-b'));

      expect(await repository.list('ws-a'), hasLength(1));
      expect(await repository.list('ws-b'), hasLength(1));
    });
  });

  group('workspace isolation', () {
    test('a server saved in one workspace is invisible to another', () async {
      await repository.save(stdio());

      expect(await repository.list('ws-b'), isEmpty);
      expect(await repository.get('ws-b', 'mcp-1'), isNull);
      expect(await repository.delete('ws-b', 'mcp-1'), isFalse);
      expect(await repository.get('ws-a', 'mcp-1'), stdio());
    });

    test('each workspace reads its own copy of a shared id', () async {
      await repository.save(stdio());
      final other = stdio(workspaceId: 'ws-b', name: 'other');
      await repository.save(other);

      expect(await repository.get('ws-a', 'mcp-1'), stdio());
      expect(await repository.get('ws-b', 'mcp-1'), other);

      expect(await repository.delete('ws-b', 'mcp-1'), isTrue);
      expect(await repository.get('ws-a', 'mcp-1'), stdio());
    });

    test('a server is written to the database of its own workspace', () async {
      await repository.save(stdio(workspaceId: 'ws-b'));

      expect(await dbs.of('ws-a').mcpServerDao.all(), isEmpty);
      expect(await dbs.of('ws-b').mcpServerDao.all(), hasLength(1));
    });

    test('save refuses a definition without a workspace', () async {
      await expectLater(
        repository.save(stdio(workspaceId: null)),
        throwsArgumentError,
      );
    });

    test('a deleted workspace is refused before its file opens', () async {
      dbs.markDeleted('ws-b');

      await expectLater(
        repository.list('ws-b'),
        throwsA(isA<DeletedWorkspaceException>()),
      );
      await expectLater(
        repository.save(stdio(workspaceId: 'ws-b')),
        throwsA(isA<DeletedWorkspaceException>()),
      );
    });
  });
}
