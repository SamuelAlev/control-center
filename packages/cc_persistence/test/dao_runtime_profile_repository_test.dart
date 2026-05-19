import 'package:cc_domain/features/governance/domain/entities/runtime_profile.dart';
import 'package:cc_domain/features/governance/domain/value_objects/protocol_family.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/mappers/runtime_profile_mapper.dart'
    show RuntimeProfileMapper;
import 'package:test/test.dart';

import 'helpers/test_database.dart';

/// Covers [DaoRuntimeProfileRepository] + [RuntimeProfileMapper] end to end,
/// including the fixedArgs JSON round trip and workspace isolation.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoRuntimeProfileRepository repo;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'w-1');
    await seedTestWorkspace(global, dbs, 'w-2');
    repo = DaoRuntimeProfileRepository(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  RuntimeProfile profile({
    required String id,
    String ws = 'w-1',
    ProtocolFamily family = ProtocolFamily.cli,
    List<String> fixedArgs = const [],
    String? description,
  }) => RuntimeProfile(
    id: id,
    workspaceId: ws,
    name: 'p-$id',
    protocolFamily: family,
    command: 'run',
    fixedArgs: fixedArgs,
    description: description,
    createdAt: DateTime.utc(2025, 1, 1),
    updatedAt: DateTime.utc(2025, 1, 1),
  );

  group('DaoRuntimeProfileRepository round trip', () {
    test('upsert + getById maps the row back', () async {
      await repo.upsert(
        profile(
          id: 'rp-1',
          family: ProtocolFamily.codex,
          fixedArgs: ['--fast', '--no-color'],
          description: 'codex profile',
        ),
      );
      final fetched = await repo.getById('w-1', 'rp-1');
      expect(fetched?.protocolFamily, ProtocolFamily.codex);
      expect(fetched?.fixedArgs, ['--fast', '--no-color']);
      expect(fetched?.description, 'codex profile');
    });

    test('empty fixedArgs round-trips (mapper handles empty json)', () async {
      await repo.upsert(profile(id: 'rp-1', fixedArgs: const []));
      final fetched = await repo.getById('w-1', 'rp-1');
      expect(fetched?.fixedArgs, isEmpty);
    });

    test('listByWorkspace + watchByWorkspace are scoped', () async {
      await repo.upsert(profile(id: 'rp-1', ws: 'w-1'));
      await repo.upsert(profile(id: 'rp-2', ws: 'w-2'));
      expect(await repo.listByWorkspace('w-1'), hasLength(1));
      expect(await repo.watchByWorkspace('w-2').first, hasLength(1));
    });

    test('getById returns null for unknown / foreign workspace', () async {
      await repo.upsert(profile(id: 'rp-1', ws: 'w-1'));
      expect(await repo.getById('w-2', 'rp-1'), isNull);
      expect(await repo.getById('w-1', 'missing'), isNull);
    });

    test('delete is workspace-scoped via the DAO', () async {
      await repo.upsert(profile(id: 'rp-1', ws: 'w-1'));
      await repo.delete('w-1', 'rp-1');
      expect(await repo.getById('w-1', 'rp-1'), isNull);
    });
  });
}
