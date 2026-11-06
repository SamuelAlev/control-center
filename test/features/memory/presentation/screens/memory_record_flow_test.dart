import 'dart:async';

import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/core/domain/entities/memory_policy.dart';
import 'package:cc_domain/core/domain/value_objects/agent_role.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_fact_repository.dart';
import 'package:cc_domain/features/memory/domain/repositories/memory_policy_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_row.dart';
import 'package:control_center/features/memory/providers/memory_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

const _ws = 'ws1';

class _Workspace extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => _ws;
}

class _FactRepo implements MemoryFactRepository {
  final saved = <MemoryFact>[];
  final deleted = <String>[];

  /// Holds [delete] open until completed.
  final deleteGate = Completer<void>();

  @override
  Future<void> upsert(MemoryFact fact) async => saved.add(fact);

  @override
  Future<void> delete(String workspaceId, String id) async {
    deleted.add(id);
    await deleteGate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _PolicyRepo implements MemoryPolicyRepository {
  final saved = <MemoryPolicy>[];

  @override
  Future<void> upsert(MemoryPolicy policy) async => saved.add(policy);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MemoryFact _fact(String id, {String? supersededBy, String? content}) =>
    MemoryFact(
      id: id,
      workspaceId: _ws,
      domain: 'engineering',
      topic: 'topic $id',
      content: content ?? 'Content of $id',
      supersededBy: supersededBy,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

MemoryPolicy _policy({List<String> sources = const [], AgentRole? role}) =>
    MemoryPolicy(
      id: 'p1',
      workspaceId: _ws,
      domain: 'engineering',
      rule: 'Always write the spec first.',
      sourceFactIds: sources,
      requiredRole: role,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

/// The page the app was on before Memory.
const _before = '/before';

/// Pumps the screen on the app's own routes, reached from [_before] unless
/// [location] lands straight on a URL. Facts arrive through [facts] when given,
/// to change them while a record is open.
Future<({_FactRepo factRepo, _PolicyRepo policyRepo, GoRouter router})> _pump(
  WidgetTester tester, {
  List<MemoryFact> seed = const [],
  List<MemoryPolicy> policies = const [],
  Stream<List<MemoryFact>>? facts,
  String? location,
}) async {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final factRepo = _FactRepo();
  final policyRepo = _PolicyRepo();
  final router = historyTestRouter(
    initialLocation: location ?? _before,
    routes: [
      GoRoute(path: _before, builder: (context, state) => const Text('Before')),
      ...memoryRoutes(),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        activeWorkspaceIdProvider.overrideWith(_Workspace.new),
        memoryFactRepositoryProvider.overrideWithValue(factRepo),
        memoryPolicyRepositoryProvider.overrideWithValue(policyRepo),
        memoryFactsProvider(
          _ws,
        ).overrideWith((ref) => facts ?? Stream.value(seed)),
        memoryPoliciesProvider(
          _ws,
        ).overrideWith((ref) => Stream.value(policies)),
      ],
      child: testRouterWrap(router),
    ),
  );
  await tester.pumpAndSettle();
  if (location == null) {
    router.go(memoryRoute(_ws));
    await tester.pumpAndSettle();
  }
  return (factRepo: factRepo, policyRepo: policyRepo, router: router);
}

String _at(GoRouter router) => router.state.uri.toString();

Future<void> _tapText(WidgetTester tester, String text) async {
  await tester.tap(find.text(text));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a fact opens as a page and Back keeps the search', (
    tester,
  ) async {
    await _pump(tester, seed: [_fact('a'), _fact('b')]);

    await tester.enterText(find.byType(CcTextField), 'topic a');
    await tester.pumpAndSettle();
    expect(find.text('topic b'), findsNothing);
    await tester.tap(find.byType(MemoryFactRow));
    await tester.pumpAndSettle();

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Memory'), findsNothing);

    await _tapText(tester, 'Back');

    expect(find.text('Memory'), findsOneWidget);
    // Still filtered: the list was kept, not rebuilt.
    expect(find.text('topic a'), findsWidgets);
    expect(find.text('topic b'), findsNothing);
  });

  testWidgets('editing a fact saves through the repository', (tester) async {
    final repos = await _pump(tester, seed: [_fact('a')]);

    await _tapText(tester, 'topic a');
    await _tapText(tester, 'Edit');
    await tester.enterText(find.byType(CcTextField).first, 'renamed');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Save');

    expect(repos.factRepo.saved.single.topic, 'renamed');
    expect(repos.factRepo.saved.single.id, 'a');
    // Back on the reading view.
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('Save stays off while a required field is blank', (tester) async {
    final repos = await _pump(tester, seed: [_fact('a')]);

    await _tapText(tester, 'topic a');
    await _tapText(tester, 'Edit');
    await tester.enterText(find.byType(CcTextField).first, '');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(repos.factRepo.saved, isEmpty);
  });

  testWidgets('leaving with unsaved edits asks first', (tester) async {
    await _pump(tester, seed: [_fact('a')]);

    await _tapText(tester, 'topic a');
    await _tapText(tester, 'Edit');
    await tester.enterText(find.byType(CcTextField).first, 'renamed');
    await tester.pumpAndSettle();
    await _tapText(tester, 'Back');

    expect(find.text('Discard changes?'), findsOneWidget);

    await tester.tap(find.widgetWithText(CcButton, 'Cancel').last);
    await tester.pumpAndSettle();
    expect(find.text('Save'), findsOneWidget);

    await _tapText(tester, 'Back');
    await tester.tap(find.widgetWithText(CcButton, 'Discard').last);
    await tester.pumpAndSettle();
    expect(find.text('Memory'), findsOneWidget);
  });

  testWidgets('a policy links to its source fact, and Back returns to it', (
    tester,
  ) async {
    await _pump(
      tester,
      seed: [_fact('a')],
      policies: [
        _policy(sources: ['a', 'gone']),
      ],
    );

    await _tapText(tester, 'Policies');
    await _tapText(tester, 'Always write the spec first.');

    expect(find.text('SOURCE FACTS'), findsOneWidget);
    await _tapText(tester, 'topic a');
    expect(find.text('SOURCE FACTS'), findsNothing);

    await _tapText(tester, 'Back');
    expect(find.text('SOURCE FACTS'), findsOneWidget);

    await _tapText(tester, 'Back');
    expect(find.text('Memory'), findsOneWidget);
  });

  testWidgets('clearing a required role really clears it', (tester) async {
    final repos = await _pump(tester, policies: [_policy(role: AgentRole.qa)]);

    await _tapText(tester, 'Policies');
    await _tapText(tester, 'Always write the spec first.');
    await _tapText(tester, 'Edit');
    await tester.tap(find.byType(CcSelect<AgentRole?>));
    await tester.pumpAndSettle();
    // The list opens on the current value, with "none" scrolled above it.
    await tester.ensureVisible(find.text('None (all roles)'));
    await tester.pumpAndSettle();
    await _tapText(tester, 'None (all roles)');
    await _tapText(tester, 'Save');

    expect(repos.policyRepo.saved.single.requiredRole, isNull);
  });

  testWidgets('the policy list switch turns a policy off', (tester) async {
    final repos = await _pump(tester, policies: [_policy()]);

    await _tapText(tester, 'Policies');
    await tester.tap(find.byType(CcSwitch));
    await tester.pumpAndSettle();

    expect(repos.policyRepo.saved.single.active, isFalse);
    // The switch acts on the row without opening it.
    expect(find.text('Memory'), findsOneWidget);
  });

  testWidgets('an open fact that disappears drops back to the list', (
    tester,
  ) async {
    final facts = StreamController<List<MemoryFact>>();
    addTearDown(facts.close);
    final pumping = _pump(tester, facts: facts.stream);
    facts.add([_fact('a'), _fact('b')]);
    await pumping;
    await tester.pumpAndSettle();

    await _tapText(tester, 'topic a');
    expect(find.text('Edit'), findsOneWidget);

    facts.add([_fact('b')]);
    await tester.pumpAndSettle();

    expect(find.text('Memory'), findsOneWidget);
    expect(find.text('Edit'), findsNothing);
  });

  testWidgets('an open fact has its own URL', (tester) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      seed: [_fact('a')],
    );

    await _tapText(tester, 'topic a');

    expect(_at(router), memoryFactRoute(_ws, 'a'));
  });

  testWidgets('an open policy has its own URL', (tester) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      policies: [_policy()],
    );

    await _tapText(tester, 'Policies');
    await _tapText(tester, 'Always write the spec first.');

    expect(_at(router), memoryPolicyRoute(_ws, 'p1'));
  });

  testWidgets('the mouse back button leaves a fact for the list', (
    tester,
  ) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      seed: [_fact('a'), _fact('b')],
    );
    await tester.enterText(find.byType(CcTextField), 'topic a');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MemoryFactRow));
    await tester.pumpAndSettle();

    await pressMouseHistoryButton(tester);

    expect(_at(router), memoryRoute(_ws));
    expect(find.text('Memory'), findsOneWidget);
    // Still filtered: back on the same list, not a new one.
    expect(find.text('topic b'), findsNothing);

    await pressMouseHistoryButton(tester, forward: true);
    expect(_at(router), memoryFactRoute(_ws, 'a'));
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('the mouse back button leaves a policy for its tab', (
    tester,
  ) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      policies: [_policy()],
    );
    await _tapText(tester, 'Policies');
    await _tapText(tester, 'Always write the spec first.');

    await pressMouseHistoryButton(tester);

    expect(_at(router), memoryRoute(_ws));
    expect(find.text('Always write the spec first.'), findsOneWidget);
  });

  testWidgets('Back from a record stops at the list, then leaves Memory', (
    tester,
  ) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      seed: [_fact('a')],
    );
    await _tapText(tester, 'topic a');

    await _tapText(tester, 'Back');
    expect(_at(router), memoryRoute(_ws));

    await pressMouseHistoryButton(tester);
    expect(_at(router), _before);
  });

  testWidgets('a URL opens its record, and Back falls to the list', (
    tester,
  ) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      seed: [_fact('a')],
      location: memoryFactRoute(_ws, 'a'),
    );

    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Content of a'), findsOneWidget);

    await _tapText(tester, 'Back');

    expect(_at(router), memoryRoute(_ws));
    expect(find.text('Memory'), findsOneWidget);
  });

  testWidgets('a URL for a record that is gone lands on the list', (
    tester,
  ) async {
    final (:router, factRepo: _, policyRepo: _) = await _pump(
      tester,
      seed: [_fact('a')],
      location: memoryFactRoute(_ws, 'gone'),
    );

    expect(_at(router), memoryRoute(_ws));
    expect(find.text('Memory'), findsOneWidget);
  });

  testWidgets('deleting a record steps back once, not twice', (tester) async {
    final facts = StreamController<List<MemoryFact>>();
    addTearDown(facts.close);
    final pumping = _pump(tester, facts: facts.stream);
    facts.add([_fact('a')]);
    final (:router, :factRepo, policyRepo: _) = await pumping;

    await _tapText(tester, 'topic a');
    await _tapText(tester, 'Delete');
    await tester.tap(find.widgetWithText(CcButton, 'Delete').last);
    await tester.pumpAndSettle();
    expect(factRepo.deleted, ['a']);

    // The fact goes from the stream a frame before the delete returns, so its
    // two ways out both fire ahead of the route landing.
    facts.add(const []);
    await tester.pump();
    await tester.pump();
    factRepo.deleteGate.complete();
    await tester.pumpAndSettle();

    expect(_at(router), memoryRoute(_ws));
  });

  testWidgets('a superseded fact points at its replacement', (tester) async {
    await _pump(
      tester,
      seed: [
        _fact('old', supersededBy: 'new'),
        _fact('new'),
      ],
    );

    // Open the replacement: the fact it replaced is listed under it.
    await _tapText(tester, 'topic new');
    expect(find.text('topic old'), findsOneWidget);

    await _tapText(tester, 'topic old');
    expect(find.text('A newer fact has replaced this one.'), findsOneWidget);

    await _tapText(tester, 'Open');
    expect(find.text('topic new'), findsOneWidget);
  });
}
