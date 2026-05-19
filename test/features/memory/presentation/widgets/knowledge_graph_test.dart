import 'dart:async';
import 'dart:typed_data';

import 'package:control_center/core/domain/entities/memory_fact.dart';
import 'package:control_center/core/domain/entities/memory_policy.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/domain/entities/memory_domain.dart';
import 'package:control_center/features/memory/domain/repositories/memory_domain_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:control_center/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:control_center/features/memory/presentation/widgets/knowledge_graph.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

/// Controlled stream fact repository — seed with data, error, or keep open
/// for perpetual loading.
class _ControlledFactRepository implements MemoryFactRepository {
  _ControlledFactRepository(Stream<List<MemoryFact>> stream)
    : _stream = stream.asBroadcastStream();

  final Stream<List<MemoryFact>> _stream;

  @override
  Stream<List<MemoryFact>> watchByWorkspace(String workspaceId) => _stream;

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  Future<void> upsert(MemoryFact fact) async {}

  @override
  Future<List<MemoryFact>> getByWorkspace(String workspaceId) async => [];

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
  Future<List<MemoryFact>> getByAuthor(
    String workspaceId,
    String agentId,
  ) async => const [];
}

/// Controlled stream policy repository.
class _ControlledPolicyRepository implements MemoryPolicyRepository {
  _ControlledPolicyRepository(Stream<List<MemoryPolicy>> stream)
    : _stream = stream.asBroadcastStream();
  final Stream<List<MemoryPolicy>> _stream;

  @override
  Stream<List<MemoryPolicy>> watchByWorkspace(String workspaceId) => _stream;

  @override
  Future<void> delete(String workspaceId, String id) async {}

  @override
  Future<void> upsert(MemoryPolicy policy) async {}

  @override
  Future<List<MemoryPolicy>> getByWorkspace(String workspaceId) async => [];

  @override
  Future<MemoryPolicy?> getById(String workspaceId, String id) async => null;

  @override
  Future<List<MemoryPolicy>> getActiveByWorkspace(
    String workspaceId, {
    String? domain,
  }) async => const [];
}

/// Controlled stream domain repository.
class _ControlledDomainRepository implements MemoryDomainRepository {
  _ControlledDomainRepository(Stream<List<MemoryDomain>> stream)
    : _stream = stream.asBroadcastStream();

  final Stream<List<MemoryDomain>> _stream;

  @override
  Stream<List<MemoryDomain>> watchByWorkspace(String workspaceId) => _stream;

  @override
  Future<List<MemoryDomain>> getByWorkspace(String workspaceId) async => [];

  @override
  Future<MemoryDomain?> findByName(
    String workspaceId,
    String name,
  ) async => null;

  @override
  Future<void> upsert(MemoryDomain domain) async {}
}

// ---------------------------------------------------------------------------
// Test data helpers
// ---------------------------------------------------------------------------

const _workspaceId = 'ws-1';
final _now = DateTime(2025, 1, 1);

MemoryFact _fact({
  String id = 'f1',
  String domain = 'preferences',
  String topic = 'theme',
  String content = 'User prefers dark theme',
  double confidence = 0.9,
}) {
  return MemoryFact(
    id: id,
    workspaceId: _workspaceId,
    domain: domain,
    topic: topic,
    content: content,
    confidence: confidence,
    createdAt: _now,
    updatedAt: _now,
  );
}

MemoryPolicy _policy({
  String id = 'p1',
  String domain = 'preferences',
  String rule = 'Only user can modify theme',
}) {
  return MemoryPolicy(
    id: id,
    workspaceId: _workspaceId,
    domain: domain,
    rule: rule,
    createdAt: _now,
    updatedAt: _now,
  );
}

MemoryDomain _domain({
  String id = 'd1',
  String name = 'preferences',
  String label = 'Preferences',
}) {
  return MemoryDomain(
    id: id,
    workspaceId: _workspaceId,
    name: name,
    label: label,
    createdAt: _now,
    createdByRole: 'User',
  );
}

// ---------------------------------------------------------------------------
// Pump helper
// ---------------------------------------------------------------------------

Future<void> _pump(
  WidgetTester tester, {
  Stream<List<MemoryFact>> facts = const Stream.empty(),
  Stream<List<MemoryPolicy>> policies = const Stream.empty(),
  Stream<List<MemoryDomain>> domains = const Stream.empty(),
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memoryFactRepositoryProvider.overrideWith(
          (ref) => _ControlledFactRepository(facts),
        ),
        memoryPolicyRepositoryProvider.overrideWith(
          (ref) => _ControlledPolicyRepository(policies),
        ),
        memoryDomainRepositoryProvider.overrideWith(
          (ref) => _ControlledDomainRepository(domains),
        ),
      ],
      child: testWrap(
        const KnowledgeGraph(workspaceId: _workspaceId),
      ),
    ),
  );
  // Let stream providers settle.
  await tester.pump();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('KnowledgeGraph', () {
    testWidgets('renders loading state while providers are awaiting data',
        (tester) async {
      // StreamControllers that never emit keep the providers in loading.
      final factsController = StreamController<List<MemoryFact>>();
      final policiesController = StreamController<List<MemoryPolicy>>();
      final domainsController = StreamController<List<MemoryDomain>>();

      await _pump(
        tester,
        facts: factsController.stream,
        policies: policiesController.stream,
        domains: domainsController.stream,
      );

      expect(find.byType(FCircularProgress), findsOneWidget);

      unawaited(factsController.close());
      unawaited(policiesController.close());
      unawaited(domainsController.close());
    });

    testWidgets('renders loading when only facts are loading', (tester) async {
      final factsController = StreamController<List<MemoryFact>>();

      await _pump(
        tester,
        facts: factsController.stream,
        policies: Stream.value(<MemoryPolicy>[]),
        domains: Stream.value(<MemoryDomain>[]),
      );

      expect(find.byType(FCircularProgress), findsOneWidget);

      unawaited(factsController.close());
    });

    testWidgets('renders empty state when all providers yield empty lists',
        (tester) async {
      await _pump(
        tester,
        facts: Stream.value(<MemoryFact>[]),
        policies: Stream.value(<MemoryPolicy>[]),
        domains: Stream.value(<MemoryDomain>[]),
      );

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('renders domain and topic nodes from facts and domains',
        (tester) async {
      final facts = [
        _fact(
          id: 'f1',
          domain: 'preferences',
          topic: 'theme',
          content: 'Dark theme preferred',
        ),
        _fact(
          id: 'f2',
          domain: 'preferences',
          topic: 'notifications',
          content: 'Quiet hours 22-06',
        ),
      ];
      final domains = [_domain(name: 'preferences', label: 'Preferences')];

      await _pump(
        tester,
        facts: Stream.value(facts),
        policies: Stream.value(<MemoryPolicy>[]),
        domains: Stream.value(domains),
      );

      // Domain node should be visible.
      expect(find.text('Preferences'), findsOneWidget);
      // Topic nodes should be visible.
      expect(find.text('theme'), findsAtLeastNWidgets(1));
      expect(find.text('notifications'), findsAtLeastNWidgets(1));
      // EmptyState should not be present.
      expect(find.byType(EmptyState), findsNothing);
    });

    testWidgets('renders fact content in fact nodes', (tester) async {
      final facts = [
        _fact(
          id: 'f1',
          domain: 'codebase',
          topic: 'architecture',
          content: 'Uses Clean Architecture',
        ),
      ];
      final domains = [_domain(name: 'codebase', label: 'Codebase')];

      await _pump(
        tester,
        facts: Stream.value(facts),
        policies: Stream.value(<MemoryPolicy>[]),
        domains: Stream.value(domains),
      );

      // The fact content should appear somewhere in the rendered graph.
      expect(find.text('Uses Clean Architecture'), findsOneWidget);
    });

    testWidgets('renders policy nodes', (tester) async {
      final policies = [
        _policy(
          id: 'p1',
          domain: 'preferences',
          rule: 'Agents may not modify user preferences',
        ),
      ];
      final domains = [_domain(name: 'preferences', label: 'Preferences')];

      await _pump(
        tester,
        facts: Stream.value(<MemoryFact>[]),
        policies: Stream.value(policies),
        domains: Stream.value(domains),
      );

      // Policy rule text should be visible.
      expect(
        find.text('Agents may not modify user preferences'),
        findsOneWidget,
      );
    });

    testWidgets('renders multiple domains as separate clusters',
        (tester) async {
      final facts = [
        _fact(
          id: 'f1',
          domain: 'preferences',
          topic: 'ui',
          content: 'Prefers compact layout',
        ),
        _fact(
          id: 'f2',
          domain: 'codebase',
          topic: 'style',
          content: 'Uses 4-space indentation',
        ),
      ];
      final domains = [
        _domain(name: 'preferences', label: 'Preferences'),
        _domain(name: 'codebase', label: 'Codebase'),
      ];

      await _pump(
        tester,
        facts: Stream.value(facts),
        policies: Stream.value(<MemoryPolicy>[]),
        domains: Stream.value(domains),
      );

      // Both domain labels should be visible.
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Codebase'), findsOneWidget);
    });

    testWidgets('renders domain from fact when domain entity is absent',
        (tester) async {
      final facts = [
        _fact(
          id: 'f1',
          domain: 'auto-detected',
          topic: 'config',
          content: 'Some config fact',
        ),
      ];

      await _pump(
        tester,
        facts: Stream.value(facts),
        policies: Stream.value(<MemoryPolicy>[]),
        domains: Stream.value(<MemoryDomain>[]),
      );

      // The domain slug (name) is used as fallback label when no domain entity
      // exists. The auto-detected domain cluster should appear.
      expect(find.text('auto-detected'), findsAtLeastNWidgets(1));
      expect(find.text('config'), findsAtLeastNWidgets(1));
    });
  });
}
