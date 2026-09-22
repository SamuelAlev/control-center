import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_trigger_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_start.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/pipelines/presentation/screens/pipeline_templates_settings_screen.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_wrap.dart';

const _workspaceId = 'ws-1';

// ── Test doubles ─────────────────────────────────────────────────────────────

class _FixedWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceIdNotifier(this._id);
  final String _id;

  @override
  String? build() => _id;
}

class _NullWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => null;
}

class _FakeTemplateRepo implements PipelineTemplateRepository {
  final List<PipelineDefinition> upserted = [];

  @override
  Future<void> upsert(PipelineDefinition definition) async {
    upserted.add(definition);
  }

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => null;

  @override
  Future<List<PipelineDefinition>> forWorkspace(String workspaceId) async =>
      const [];

  @override
  Stream<List<PipelineDefinition>> watchForWorkspace(String workspaceId) =>
      const Stream.empty();

  @override
  Future<int> deleteById(String workspaceId, String templateId) async => 0;
}

class _FakeTriggerRepo implements PipelineTriggerRepository {
  final List<PipelineTrigger> inserted = [];

  @override
  Future<void> insert(PipelineTrigger trigger) async {
    inserted.add(trigger);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

PipelineDefinition _template({
  String templateId = 'hello',
  String name = 'Hello Pipeline',
}) {
  return PipelineDefinition(
    templateId: templateId,
    workspaceId: _workspaceId,
    name: name,
    steps: [
      PipelineStepDefinition(
        id: 'trigger',
        kind: StepKind.trigger,
        bodyKey: 'pipeline.trigger',
      ),
    ],
    isEnabled: true,
  );
}

/// Wraps [PipelineTemplatesSettingsScreen] with provider overrides.
///
/// [templates] drives [pipelineTemplatesProvider].
/// [workspaceId] drives [activeWorkspaceIdProvider]; pass null for no workspace.
Widget _wrap({
  List<PipelineDefinition> templates = const [],
  String? workspaceId,
  PipelineTemplateRepository? repo,
}) {
  final workspaceOverride = workspaceId == null
      ? activeWorkspaceIdProvider.overrideWith(_NullWorkspaceIdNotifier.new)
      : activeWorkspaceIdProvider.overrideWith(
          () => _FixedWorkspaceIdNotifier(workspaceId),
        );

  final overrides = [workspaceOverride];

  if (workspaceId != null) {
    overrides.add(
      pipelineTemplatesProvider(
        workspaceId,
      ).overrideWith((ref) => Stream.value(templates)),
    );
    overrides.add(
      pipelineTriggersForWorkspaceProvider(
        workspaceId,
      ).overrideWith((ref) => const Stream.empty()),
    );
  }
  if (repo != null) {
    overrides.add(pipelineTemplateRepositoryProvider.overrideWithValue(repo));
  }

  return ProviderScope(
    overrides: overrides,
    child: testWrap(const PipelineTemplatesSettingsScreen()),
  );
}

Widget _routedShell(GoRouter router) {
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp.router(
      localizationsDelegates: const [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
      ],
      supportedLocales: kSupportedAppLocales,
      routerConfig: router,
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('PipelineTemplatesSettingsScreen', () {
    testWidgets('renders no-workspace message when workspaceId is null', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      expect(
        find.text('Select a workspace to view its pipelines'),
        findsOneWidget,
      );
    });

    testWidgets('renders template names when templates exist', (tester) async {
      final templates = [
        _template(templateId: 'hello', name: 'Hello Pipeline'),
        _template(templateId: 'world', name: 'World Pipeline'),
      ];

      await tester.pumpWidget(
        _wrap(templates: templates, workspaceId: _workspaceId),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello Pipeline'), findsOneWidget);
      expect(find.text('World Pipeline'), findsOneWidget);
    });

    testWidgets('New template upserts a draft and opens the editor', (
      tester,
    ) async {
      final repo = _FakeTemplateRepo();
      final triggers = _FakeTriggerRepo();
      final router = GoRouter(
        initialLocation: '/workspaces/$_workspaceId/settings/pipelines',
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/settings/pipelines',
            builder: (_, _) => const PipelineTemplatesSettingsScreen(),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/settings/pipelines/:templateId',
            builder: (_, state) =>
                Text('editor:${state.pathParameters['templateId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(
              () => _FixedWorkspaceIdNotifier(_workspaceId),
            ),
            pipelineTemplatesProvider(
              _workspaceId,
            ).overrideWith((ref) => Stream.value(const [])),
            pipelineTriggersForWorkspaceProvider(
              _workspaceId,
            ).overrideWith((ref) => const Stream.empty()),
            pipelineTemplateRepositoryProvider.overrideWithValue(repo),
            pipelineTriggerRepositoryProvider.overrideWithValue(triggers),
            isDemoServerProvider.overrideWith((ref) => false),
          ],
          child: _routedShell(router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New template'));
      await tester.pumpAndSettle();

      expect(repo.upserted, hasLength(1));
      final created = repo.upserted.single;
      expect(created.templateId, 'pipeline_1');
      expect(created.name, 'New pipeline');
      expect(created.maxParallelRuns, isNull);
      expect(created.steps, hasLength(2));
      expect(created.steps.first.kind, StepKind.trigger);
      expect(created.steps.first.bodyKey, 'pipeline.trigger');
      expect(created.steps.first.x, 0);
      expect(created.steps.first.y, 0);
      expect(
        created.steps.first.config.extras[kPipelineStartEventTypeKey],
        PipelineTrigger.manualEventType,
      );
      final terminal = created.steps.last;
      expect(terminal.kind, StepKind.terminal);
      expect(terminal.bodyKey, '_terminal_trigger');
      expect(terminal.triggers, hasLength(1));
      expect(terminal.triggers.single.sourceStepIds, [created.steps.first.id]);
      expect(triggers.inserted, hasLength(1));
      final seeded = triggers.inserted.single;
      expect(seeded.id, created.steps.first.id);
      expect(seeded.eventType, PipelineTrigger.manualEventType);
      expect(seeded.enabled, isTrue);
      expect(seeded.templateId, 'pipeline_1');
      expect(seeded.workspaceId, _workspaceId);
      expect(find.text('editor:pipeline_1'), findsOneWidget);
      expect(find.text('Max parallel runs'), findsNothing);
    });

    testWidgets('New template skips ids already in the list', (tester) async {
      final repo = _FakeTemplateRepo();
      final router = GoRouter(
        initialLocation: '/workspaces/$_workspaceId/settings/pipelines',
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/settings/pipelines',
            builder: (_, _) => const PipelineTemplatesSettingsScreen(),
          ),
          GoRoute(
            path: '/workspaces/:workspaceId/settings/pipelines/:templateId',
            builder: (_, state) =>
                Text('editor:${state.pathParameters['templateId']}'),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeWorkspaceIdProvider.overrideWith(
              () => _FixedWorkspaceIdNotifier(_workspaceId),
            ),
            pipelineTemplatesProvider(_workspaceId).overrideWith(
              (ref) => Stream.value([
                _template(templateId: 'pipeline_1', name: 'Existing'),
                _template(templateId: 'pipeline_3', name: 'Other'),
              ]),
            ),
            pipelineTriggersForWorkspaceProvider(
              _workspaceId,
            ).overrideWith((ref) => const Stream.empty()),
            pipelineTemplateRepositoryProvider.overrideWithValue(repo),
            pipelineTriggerRepositoryProvider.overrideWithValue(
              _FakeTriggerRepo(),
            ),
            isDemoServerProvider.overrideWith((ref) => false),
          ],
          child: _routedShell(router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('New template'));
      await tester.pumpAndSettle();

      expect(repo.upserted.single.templateId, 'pipeline_2');
      expect(find.text('editor:pipeline_2'), findsOneWidget);
    });

    testWidgets('renders empty state when no templates exist', (tester) async {
      await tester.pumpWidget(
        _wrap(templates: const [], workspaceId: _workspaceId),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No pipeline templates yet. Create one to get started.'),
        findsOneWidget,
      );
    });
  });
}
