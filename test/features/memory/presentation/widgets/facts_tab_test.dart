import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/facts_tab.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory fact repository returning a fixed list for the workspace.
class _FakeFactRepository implements MemoryFactRepository {
  _FakeFactRepository(this._facts);

  final List<MemoryFact> _facts;

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) =>
      Stream.value(_facts);

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  Future<void> upsert(MemoryFact fact) async {}

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async => _facts;

  @override
  Future<MemoryFact?> getById(String workspaceId, String id) async => null;

  @override
  Future<List<MemoryFact>> getActiveByTopic(
    String workspaceId,
    String topic,
  ) async => const [];

  @override
  Future<List<MemoryFact>> search(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
  }) async => const [];

  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
  }) async => const [];

  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async =>
      _facts.where((f) => f.workspaceId == workspaceId && !f.isSuperseded).toList();

  @override
  Future<void> markRecalled(String workspaceId, List<String> ids) async {}

  @override
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async => const [];
}

MemoryFact _fact({
  required String topic,
  required String content,
  double confidence = 1.0,
}) {
  final now = DateTime(2026, 1, 1);
  return MemoryFact(
    id: 'id-$topic',
    workspaceId: 'ws-1',
    domain: 'engineering',
    topic: topic,
    content: content,
    confidence: confidence,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pump(WidgetTester tester, List<MemoryFact> facts) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memoryFactRepositoryProvider.overrideWithValue(
          _FakeFactRepository(facts),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData.light(),
          child: const Scaffold(body: FactsTab(workspaceId: 'ws-1')),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('renders facts with confidence percentages', (tester) async {
    await _pump(tester, [
      _fact(topic: 'caching', content: 'Redis is the cache', confidence: 0.9),
      _fact(topic: 'auth', content: 'Tokens expire hourly', confidence: 0.4),
    ]);

    expect(find.text('Redis is the cache'), findsOneWidget);
    expect(find.text('Tokens expire hourly'), findsOneWidget);
    expect(find.text('90%'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
  });

  testWidgets('search filters the list by content', (tester) async {
    await _pump(tester, [
      _fact(topic: 'caching', content: 'Redis is the cache'),
      _fact(topic: 'auth', content: 'Tokens expire hourly'),
    ]);

    await tester.enterText(find.byType(TextField), 'redis');
    await tester.pumpAndSettle();

    expect(find.text('Redis is the cache'), findsOneWidget);
    expect(find.text('Tokens expire hourly'), findsNothing);
  });

  testWidgets('shows no-match empty state when search yields nothing', (
    tester,
  ) async {
    await _pump(tester, [
      _fact(topic: 'caching', content: 'Redis is the cache'),
    ]);

    await tester.enterText(find.byType(TextField), 'zzzznomatch');
    await tester.pumpAndSettle();

    expect(find.text('No facts match your search'), findsOneWidget);
  });
}
