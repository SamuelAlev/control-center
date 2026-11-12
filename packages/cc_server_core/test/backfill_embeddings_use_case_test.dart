import 'dart:async';
import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:test/test.dart';

import 'helpers/seed_spaces.dart';
import 'helpers/test_database.dart';

class _FakeEmbedder extends EmbeddingPort {
  _FakeEmbedder({this.isReady = true});

  @override
  bool isReady;

  int calls = 0;

  @override
  int get dimension => 384;

  @override
  Future<Float32List> embed(String text) async {
    calls++;
    return Float32List(384)..[0] = 1;
  }
}

void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1', name: 'ws1-name');
    await seedTestWorkspace(global, dbs, 'ws2', name: 'ws2-name');
  });
  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  BackfillEmbeddingsUseCase useCase(
    EmbeddingPort? embedder, {
    void Function(String, Object, StackTrace)? onError,
  }) => BackfillEmbeddingsUseCase(
    workspaces: dbs,
    facts: DaoMemoryFactRepository(dbs, embeddingService: embedder),
    messages: DaoMessagingRepository(dbs),
    codeGraph: DaoCodeGraphRepository(dbs, embeddingService: embedder),
    embedder: embedder,
    onError: onError,
  );

  Future<void> addFact(String workspaceId, String id) => dbs
      .of(workspaceId)
      .memoryFactDao
      .upsert(
        MemoryFactsTableCompanion.insert(
          id: id,
          workspaceId: workspaceId,
          domain: 'test',
          topic: 'auth',
          content: 'uses JWT tokens $id',
        ),
      );

  Future<void> addSymbol(String workspaceId, String id) =>
      dbs.codeIndexOf(workspaceId).codeGraphDao.upsertSymbols([
        CodeSymbolsTableCompanion.insert(
          id: id,
          repoId: 'repo1',
          kind: 'method',
          name: id,
          qualifiedName: 'A.$id',
          filePath: 'lib/a.dart',
          language: 'dart',
          startLine: 1,
          endLine: 2,
        ),
      ]);

  Future<void> addMessage(String workspaceId, String id) async {
    await seedConversation(
      dbs.of(workspaceId),
      'c-$workspaceId',
      spaceId: 's-$workspaceId',
    );
    await DaoMessagingRepository(dbs).sendMessage(
      workspaceId: workspaceId,
      spaceId: 's-$workspaceId',
      conversationId: 'c-$workspaceId',
      content: 'what was said in $id',
      senderId: 'user',
      senderType: 'user',
      id: id,
    );
  }

  Future<int> messageVectors(String workspaceId) async =>
      (await dbs
              .of(workspaceId)
              .customSelect(
                'SELECT COUNT(*) AS n FROM conversation_message_embeddings',
              )
              .getSingle())
          .read<int>('n');

  Future<int> factVectors(String workspaceId) async =>
      (await dbs
              .of(workspaceId)
              .customSelect('SELECT COUNT(*) AS n FROM memory_fact_embeddings')
              .getSingle())
          .read<int>('n');

  Future<int> symbolVectors(String workspaceId) async =>
      (await dbs
              .codeIndexOf(workspaceId)
              .customSelect('SELECT COUNT(*) AS n FROM code_symbol_embeddings')
              .getSingle())
          .read<int>('n');

  Future<void> seed() async {
    await addFact('ws1', 'f1');
    await addFact('ws1', 'f2');
    await addFact('ws2', 'f3');
    await addSymbol('ws1', 's1');
    await addSymbol('ws2', 's2');
  }

  test('embeds the facts and symbols of every live workspace that have no '
      'vector', () async {
    await seed();
    final embedder = _FakeEmbedder();

    expect(await useCase(embedder).execute(), 5);

    expect(await factVectors('ws1'), 2);
    expect(await factVectors('ws2'), 1);
    expect(await symbolVectors('ws1'), 1);
    expect(await symbolVectors('ws2'), 1);

    // A second run finds nothing left to embed.
    embedder.calls = 0;
    expect(await useCase(embedder).execute(), 0);
    expect(embedder.calls, 0);
  });

  test(
    'embeds the messages of every live workspace that have no vector',
    () async {
      await addMessage('ws1', 'm1');
      await addMessage('ws1', 'm2');
      await addMessage('ws2', 'm3');
      final embedder = _FakeEmbedder();

      expect(await useCase(embedder).execute(), 3);

      expect(await messageVectors('ws1'), 2);
      expect(await messageVectors('ws2'), 1);
      embedder.calls = 0;
      expect(await useCase(embedder).execute(), 0);
      expect(embedder.calls, 0);
    },
  );

  test('embeds nothing without a model', () async {
    await addMessage('ws1', 'm1');
    await seed();
    final embedder = _FakeEmbedder(isReady: false);

    expect(await useCase(null).execute(), 0);
    expect(await useCase(embedder).execute(), 0);
    expect(embedder.calls, 0);
    expect(await factVectors('ws1'), 0);
    expect(await messageVectors('ws1'), 0);
  });

  test('a workspace that fails does not stop the others', () async {
    await seed();
    final failed = <String>[];
    await dbs.of('ws1').customStatement('PRAGMA query_only = ON');

    final stored = await useCase(
      _FakeEmbedder(),
      onError: (workspaceId, _, _) => failed.add(workspaceId),
    ).execute();

    expect(failed, ['ws1']);
    expect(stored, 2);
    expect(await factVectors('ws2'), 1);
  });

  test('a run starts when the model reports installed', () async {
    await seed();
    final statuses = StreamController<ModelStatusSnapshot>();
    addTearDown(statuses.close);
    final backfill = useCase(_FakeEmbedder());
    final subscription = backfill.runWhenInstalled(statuses.stream);
    addTearDown(subscription.cancel);

    statuses.add(
      const ModelStatusSnapshot(status: ModelLifecycleStatus.downloading),
    );
    await pumpEventQueue();
    expect(await factVectors('ws1'), 0);

    statuses.add(
      const ModelStatusSnapshot(status: ModelLifecycleStatus.installed),
    );
    await pumpEventQueue();
    // Joins the run the status started, or finds nothing left after it.
    await backfill.execute();
    expect(await factVectors('ws1'), 2);
    expect(await symbolVectors('ws2'), 1);
  });

  test('a call during a run joins it', () async {
    await seed();
    final backfill = useCase(_FakeEmbedder());

    final first = backfill.execute();
    final second = backfill.execute();

    expect(identical(first, second), isTrue);
    expect(await second, 5);
  });
}
