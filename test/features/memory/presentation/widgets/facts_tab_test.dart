import 'dart:typed_data';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/value_objects/memory_type.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/confidence_meter.dart';
import 'package:control_center/features/memory/presentation/widgets/facts_tab.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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
    String? boostRepoSlug,
  }) async => const [];

  @override
  Future<List<MemoryFact>> recallPolyphonic(
    String workspaceId,
    String query, {
    Float32List? queryEmbedding,
    int topK = 10,
    bool markRecalled = true,
    String? boostRepoSlug,
  }) async => const [];

  @override
  Future<List<MemoryFact>> getActiveByWorkspace(String workspaceId) async =>
      _facts
          .where((f) => f.workspaceId == workspaceId && !f.isSuperseded)
          .toList();

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
  MemoryType memoryType = MemoryType.fact,
  String? supersededBy,
}) {
  final now = DateTime(2026, 1, 1);
  return MemoryFact(
    id: 'id-$topic',
    workspaceId: 'ws-1',
    domain: 'engineering',
    topic: topic,
    content: content,
    confidence: confidence,
    memoryType: memoryType,
    supersededBy: supersededBy,
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

    await tester.enterText(find.byType(CcTextField), 'redis');
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

    await tester.enterText(find.byType(CcTextField), 'zzzznomatch');
    await tester.pumpAndSettle();

    expect(find.text('No facts match your search'), findsOneWidget);
  });

  testWidgets('shows a record without its markdown syntax', (tester) async {
    await _pump(tester, [
      _fact(topic: 'layout', content: '**Use** the `Flyout` body gap.'),
    ]);

    expect(find.text('Use the Flyout body gap.'), findsOneWidget);
  });

  testWidgets('a type facet narrows the list and counts what it holds', (
    tester,
  ) async {
    await _pump(tester, [
      _fact(topic: 'a', content: 'An instruction', memoryType: MemoryType.instruction),
      _fact(topic: 'b', content: 'A plain fact'),
    ]);

    await tester.tap(find.text('Instruction  1'));
    await tester.pumpAndSettle();

    expect(find.text('An instruction'), findsOneWidget);
    expect(find.text('A plain fact'), findsNothing);
    expect(find.text('1 of 2'), findsOneWidget);
  });

  testWidgets('superseded facts stay out until their facet is picked', (
    tester,
  ) async {
    await _pump(tester, [
      _fact(topic: 'old', content: 'Old claim', supersededBy: 'id-new'),
      _fact(topic: 'new', content: 'New claim'),
    ]);

    expect(find.text('Old claim'), findsNothing);

    await tester.tap(find.text('Superseded  1'));
    await tester.pumpAndSettle();

    expect(find.text('Old claim'), findsOneWidget);
    expect(find.text('New claim'), findsNothing);
  });

  testWidgets('confidence sits with the glyph, not at the end of the row', (
    tester,
  ) async {
    await _pump(tester, [
      _fact(topic: 'caching', content: 'Redis is the cache', confidence: 0.9),
    ]);

    final marker = tester.getCenter(find.byType(MemoryConfidenceMarker));
    final title = tester.getTopLeft(find.text('caching'));
    expect(marker.dx, lessThan(title.dx));
    expect(
      tester.getTopLeft(find.text('90%')).dx,
      moreOrLessEquals(title.dx, epsilon: 1),
    );
  });

  testWidgets('the list builds only what is on screen', (tester) async {
    await _pump(tester, [
      for (var i = 0; i < 300; i++)
        _fact(topic: 'topic-$i', content: 'Content $i'),
    ]);

    expect(find.byType(MemoryFactRow).evaluate().length, lessThan(40));
  });
}
