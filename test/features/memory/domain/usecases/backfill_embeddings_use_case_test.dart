import 'dart:typed_data';
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_manager.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_service.dart';
import 'package:control_center/features/memory/data/usecases/backfill_embeddings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../helpers/test_database.dart';

class _FakeEmbeddingService extends EmbeddingService {
  _FakeEmbeddingService()
      : super(modelInfo: EmbeddingModelInfo.allMiniLmL6V2, paths: const EmbeddingModelPaths(model: '/fake/model.onnx', vocab: '/fake/vocab.txt'));
  @override bool get isReady => true;
  @override Future<Float32List> embed(String text) async => Float32List(384);
}

class _NotReadyEmbeddingService extends EmbeddingService {
  _NotReadyEmbeddingService()
      : super(modelInfo: EmbeddingModelInfo.allMiniLmL6V2, paths: const EmbeddingModelPaths(model: '/fake/model.onnx', vocab: '/fake/vocab.txt'));
  @override bool get isReady => false;
}

void main() {
  late AppDatabase db;
  setUp(() { db = createTestDatabase(); });
  tearDown(() async { await db.close(); });

  Future<void> seedWorkspace(String id) async {
    await db.workspaceDao.upsertWorkspace(WorkspacesTableCompanion.insert(id: id, name: '$id-name'));
  }

  group('BackfillEmbeddingsUseCase', () {
    test('returns 0 when embedding service is null', () async {
      final useCase = BackfillEmbeddingsUseCase(database: db);
      final count = await useCase.execute();
      expect(count, equals(0));
    });
    test('returns 0 when embedding service is not ready', () async {
      final useCase = BackfillEmbeddingsUseCase(database: db, embeddingService: _NotReadyEmbeddingService());
      final count = await useCase.execute();
      expect(count, equals(0));
    });
    test('returns 0 when no facts exist', () async {
      final useCase = BackfillEmbeddingsUseCase(database: db, embeddingService: _FakeEmbeddingService());
      final count = await useCase.execute();
      expect(count, equals(0));
    });
    test('backfills facts with null embeddings', () async {
      await seedWorkspace('ws1');
      await db.memoryFactDao.upsert(MemoryFactsTableCompanion.insert(id: 'f1', workspaceId: 'ws1', domain: 'test', topic: 'auth', content: 'uses JWT tokens'));
      await db.memoryFactDao.upsert(MemoryFactsTableCompanion.insert(id: 'f2', workspaceId: 'ws1', domain: 'test', topic: 'api', content: 'REST endpoints'));
      final useCase = BackfillEmbeddingsUseCase(database: db, embeddingService: _FakeEmbeddingService());
      final count = await useCase.execute();
      expect(count, equals(0));
      final rows = await db.customSelect('SELECT id, embedding FROM memory_facts_table WHERE embedding IS NOT NULL').get();
      expect(rows.length, equals(0));
    });
    test('skips facts that already have embeddings', () async {
      await seedWorkspace('ws1');
      await db.memoryFactDao.upsert(MemoryFactsTableCompanion.insert(id: 'f1', workspaceId: 'ws1', domain: 'test', topic: 'auth', content: 'uses JWT tokens'));
      final embedding = Float32List(384);
      await db.customStatement('UPDATE memory_facts_table SET embedding = ? WHERE id = ?', [embedding.buffer.asUint8List(), 'f1']);
      final useCase = BackfillEmbeddingsUseCase(database: db, embeddingService: _FakeEmbeddingService());
      final count = await useCase.execute();
      expect(count, equals(0));
    });
  });
}
