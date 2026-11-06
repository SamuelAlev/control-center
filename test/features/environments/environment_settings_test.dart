import 'dart:convert';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart'
    show EnvironmentInstance;
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/settings/environment_argv_text.dart';
import 'package:control_center/features/environments/presentation/settings/environment_definition_editor.dart';
import 'package:control_center/features/environments/presentation/settings/environment_editor_state.dart';
import 'package:control_center/features/environments/presentation/settings/environments_settings_view.dart';
import 'package:control_center/features/environments/providers/environment_compose_services.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/repo_file_content_provider.dart';
import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/router/app_router.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/active_workspace.dart';
import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

const _compose = '''
services:
  web:
    ports: ["8080:80"]
  postgres:
    ports:
      - target: 5432
  worker: {}
''';

const _before = '/before';

/// Pumps Settings → Environments on the app's own routes, reached from
/// [_before] unless [location] lands straight on a URL.
Future<GoRouter> _pump(
  WidgetTester tester,
  FakeEnvironmentRepository repository, {
  bool isDemo = false,
  WorkspaceRole role = WorkspaceRole.admin,
  String? location,
}) async {
  tester.view.physicalSize = const Size(1000, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final router = historyTestRouter(
    initialLocation: location ?? _before,
    routes: [
      GoRoute(path: _before, builder: (context, state) => const Text('Before')),
      ...environmentSettingsRoutes(),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentRepositoryProvider.overrideWithValue(repository),
        activeWorkspaceIdOverride(kWorkspace),
        myWorkspaceRoleProvider.overrideWith((ref, _) => role),
        reposForWorkspaceProvider.overrideWith(
          (ref, _) => Stream.value(const <Repo>[]),
        ),
        repoFileContentProvider.overrideWith(
          (ref, args) async => (content: _compose, binary: false),
        ),
      ],
      child: testRouterWrap(router, isDemo: isDemo),
    ),
  );
  await tester.pumpAndSettle();
  if (location == null) {
    router.go(settingsEnvironmentsRoute(kWorkspace));
    await tester.pumpAndSettle();
  }
  return router;
}

String _at(GoRouter router) => router.state.uri.toString();

Future<void> _openFirst(WidgetTester tester) async {
  await tester.tap(find.text('Shop'));
  await tester.pumpAndSettle();
}

double _trashOpacity(WidgetTester tester) => tester
    .widget<AnimatedOpacity>(
      find
          .descendant(
            of: find.byType(SettingsHoverReveal),
            matching: find.byType(AnimatedOpacity),
          )
          .first,
    )
    .opacity;

/// Expands the first component row.
Future<void> _expandComponent(WidgetTester tester, String title) async {
  await tester.tap(find.text(title));
  await tester.pumpAndSettle();
}

void main() {
  tearDown(SettingsHoverReveal.debugForgetMouse);

  group('the URL', () {
    testWidgets('an open definition has its own URL', (tester) async {
      final router = await _pump(
        tester,
        FakeEnvironmentRepository(definitions: [definitionRecord()]),
      );

      await _openFirst(tester);

      expect(_at(router), settingsEnvironmentRoute(kWorkspace, 'def-1'));
      expect(find.byType(EnvironmentDefinitionEditor), findsOneWidget);
    });

    testWidgets('the mouse back button leaves a definition for the list', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        FakeEnvironmentRepository(definitions: [definitionRecord()]),
      );
      await _openFirst(tester);

      await pressMouseHistoryButton(tester);
      expect(_at(router), settingsEnvironmentsRoute(kWorkspace));
      expect(find.text('1 component · On the host'), findsOneWidget);

      await pressMouseHistoryButton(tester, forward: true);
      expect(_at(router), settingsEnvironmentRoute(kWorkspace, 'def-1'));
      expect(find.byType(EnvironmentDefinitionEditor), findsOneWidget);

      await pressMouseHistoryButton(tester);
      await pressMouseHistoryButton(tester);
      expect(_at(router), _before);
    });

    testWidgets('Back in the editor returns to the list', (tester) async {
      final router = await _pump(
        tester,
        FakeEnvironmentRepository(definitions: [definitionRecord()]),
      );
      await _openFirst(tester);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();

      expect(_at(router), settingsEnvironmentsRoute(kWorkspace));
      expect(find.text('1 component · On the host'), findsOneWidget);
    });

    testWidgets('a URL opens its definition, and Back falls to the list', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        FakeEnvironmentRepository(definitions: [definitionRecord()]),
        location: settingsEnvironmentRoute(kWorkspace, 'def-1'),
      );

      expect(find.byType(EnvironmentDefinitionEditor), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(_at(router), settingsEnvironmentsRoute(kWorkspace));
    });

    testWidgets('a URL for a definition that is gone lands on the list', (
      tester,
    ) async {
      final router = await _pump(
        tester,
        FakeEnvironmentRepository(definitions: [definitionRecord()]),
        location: settingsEnvironmentRoute(kWorkspace, 'gone'),
      );

      expect(_at(router), settingsEnvironmentsRoute(kWorkspace));
      expect(find.text('1 component · On the host'), findsOneWidget);
    });

    testWidgets('leaving a definition drops its edits', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(definitions: [definitionRecord()]),
      );
      await _openFirst(tester);
      await tester.enterText(find.byType(CcTextField).first, 'Renamed');
      await tester.pumpAndSettle();

      await pressMouseHistoryButton(tester);
      await pressMouseHistoryButton(tester, forward: true);

      expect(find.text('Renamed'), findsNothing);
    });

    testWidgets('a new definition takes its id on saving, and Back skips new', (
      tester,
    ) async {
      final router = await _pump(tester, FakeEnvironmentRepository());

      await tester.tap(find.text('New definition'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Blank definition'));
      await tester.pumpAndSettle();
      expect(
        _at(router),
        settingsEnvironmentRoute(kWorkspace, settingsNewEnvironmentId),
      );

      await tester.enterText(find.byType(CcTextField).first, 'Fresh');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(_at(router), settingsEnvironmentRoute(kWorkspace, 'def-new'));
      expect(find.byType(EnvironmentDefinitionEditor), findsOneWidget);

      await pressMouseHistoryButton(tester);
      expect(_at(router), settingsEnvironmentsRoute(kWorkspace));
    });
  });

  testWidgets('lists definitions', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    expect(find.text('Shop'), findsOneWidget);
    expect(find.text('1 component · On the host'), findsOneWidget);
  });

  testWidgets('deleting from the list asks first', (tester) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
    );
    await _pump(tester, repository);

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();
    expect(find.text('Delete Shop?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Shop'), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(CcDialog), matching: find.text('Delete')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shop'), findsNothing);
    expect(find.text('No definitions yet'), findsOneWidget);
  });

  testWidgets('with a mouse, the trash waits for hover or focus', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    await tester.pumpAndSettle();
    double opacity() => _trashOpacity(tester);

    expect(opacity(), 0);
    await mouse.moveTo(tester.getCenter(find.text('Shop')));
    await tester.pumpAndSettle();
    expect(opacity(), 1);
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(opacity(), 0);

    for (var tabs = 0; tabs < 6 && opacity() == 0; tabs++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    expect(opacity(), 1);
    // From the row onto the trash itself: it must not vanish under the focus.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(opacity(), 1);
  });

  testWidgets('the trash stays hidden when the mouse leaves the app', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await tester.pumpAndSettle();
    expect(_trashOpacity(tester), 0);

    // What a desktop engine does when the app loses focus.
    await mouse.removePointer();
    await tester.pumpAndSettle();
    expect(_trashOpacity(tester), 0);
  });

  testWidgets('a desktop hides the trash before any mouse is seen', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    final opacity = _trashOpacity(tester);
    debugDefaultTargetPlatformOverride = null;
    expect(opacity, 0);
  });

  testWidgets('touch keeps the trash in view', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    expect(_trashOpacity(tester), 1);
  });

  testWidgets('an unset fork policy shows the one in effect', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    await _openFirst(tester);
    expect(find.text('Run in a VM'), findsOneWidget);
  });

  testWidgets('a member gets no delete in the list', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
      role: WorkspaceRole.member,
    );
    expect(find.text('Shop'), findsOneWidget);
    expect(find.byIcon(AppIcons.trash2), findsNothing);
  });

  testWidgets('a collapsed row owns up to the problem inside it', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(
        definitions: [
          definitionRecord(
            components: [
              {'kind': 'compose', 'id': 'Bad Id'},
            ],
          ),
        ],
      ),
    );
    await _openFirst(tester);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('Bad Id'),
          matching: find.byType(SettingsEntityRow),
        ),
        matching: find.text('Needs a fix'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('a file check shows its path, not an empty command', (
    tester,
  ) async {
    final record = definitionRecord();
    await _pump(
      tester,
      FakeEnvironmentRepository(
        definitions: [
          EnvironmentDefinitionRecord(
            id: record.id,
            workspaceId: kWorkspace,
            name: record.name,
            definitionJson: jsonEncode({
              ...jsonDecode(record.definitionJson) as Map<String, dynamic>,
              'checks': [
                {'id': 'ca', 'label': 'Local CA', 'file': '~/.ca/root.pem'},
              ],
            }),
            createdAt: DateTime.utc(2026),
            updatedAt: DateTime.utc(2026),
          ),
        ],
      ),
    );
    await _openFirst(tester);
    await tester.tap(find.text('Local CA'));
    await tester.pumpAndSettle();
    expect(find.text('File'), findsOneWidget);
    expect(find.text('Use a shell command'), findsNothing);
  });

  group('the Running tab', () {
    Future<FakeEnvironmentRepository> open(
      WidgetTester tester,
      List<EnvironmentInstance> instances,
    ) async {
      final repository = FakeEnvironmentRepository(
        definitions: [definitionRecord()],
      )..instances = instances;
      await _pump(tester, repository);
      await _openFirst(tester);
      await tester.tap(find.text('Running'));
      // The list polls, so settling would wait forever.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      return repository;
    }

    // The list polls: unmount it and let its last delay run out.
    Future<void> close(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    }

    testWidgets('lists what the definition holds, by space', (tester) async {
      await open(tester, [
        (environment: environment(), spaceName: 'Login fix'),
      ]);

      expect(find.text('Login fix'), findsOneWidget);
      expect(find.text('fix-login'), findsOneWidget);
      await close(tester);
    });

    testWidgets('a space that is gone still shows its environment', (
      tester,
    ) async {
      await open(tester, [(environment: environment(), spaceName: null)]);

      expect(find.text('fix-login'), findsWidgets);
      await close(tester);
    });

    testWidgets('destroys after asking', (tester) async {
      final repository = await open(tester, [
        (environment: environment(), spaceName: 'Login fix'),
      ]);

      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is CcIconButton && widget.tooltip == 'Destroy',
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.calls, isNot(contains('destroy')));

      await tester.tap(find.text('Destroy').last);
      await tester.pump(const Duration(milliseconds: 300));
      expect(repository.calls, contains('destroy'));
      await close(tester);
    });

    testWidgets('says so when nothing is running', (tester) async {
      await open(tester, const []);

      expect(
        find.text('Nothing is running from this definition.'),
        findsOneWidget,
      );
      await close(tester);
    });
  });

  testWidgets('a demo shows the notice and reads nothing', (tester) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
    );
    await _pump(tester, repository, isDemo: true);
    expect(find.text('Shop'), findsNothing);
    expect(
      find.text(
        'Environments run real processes on the host, so the demo has none.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a compose component shows services and ports to check', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    await _openFirst(tester);
    await _expandComponent(tester, 'stack');

    expect(find.text('web'), findsOneWidget);
    expect(find.text('80'), findsOneWidget);
    expect(find.text('postgres'), findsOneWidget);
    expect(find.text('5432'), findsOneWidget);
    expect(find.text('worker'), findsOneWidget);
  });

  testWidgets('checking a service writes it to the definition', (tester) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
    );
    await _pump(tester, repository);
    await _openFirst(tester);
    await _expandComponent(tester, 'stack');

    await tester.tap(find.text('postgres'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final components = repository.savedDefinition!['components'] as List;
    expect((components.single as Map)['services'], ['postgres']);
  });

  testWidgets('shell sits behind its checkbox', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(
        definitions: [
          definitionRecord(
            components: [
              {
                'kind': 'process',
                'id': 'web',
                'command': ['pnpm', 'dev'],
              },
            ],
          ),
        ],
      ),
    );
    await _openFirst(tester);
    await _expandComponent(tester, 'web');

    expect(
      find.text(
        'Arguments are separated by spaces. Quote one that contains a space.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Use a shell command'));
    await tester.pumpAndSettle();
    expect(
      find.text(
        "Placeholders aren't expanded here. Read CC_ENV_* variables instead.",
      ),
      findsOneWidget,
    );
  });

  testWidgets('the validator shows inline on the field', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(
        definitions: [
          definitionRecord(
            components: [
              {'kind': 'compose', 'id': 'Bad Id'},
            ],
          ),
        ],
      ),
    );
    await _openFirst(tester);
    await _expandComponent(tester, 'Bad Id');

    expect(find.textContaining('Must match'), findsWidgets);
    expect(find.text('Fix these before saving'), findsOneWidget);
  });

  testWidgets('server validation lines land on their fields', (tester) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
      setDefinitionError: RemoteRpcException(1, 'name: Taken already'),
    );
    await _pump(tester, repository);
    await _openFirst(tester);

    await tester.enterText(find.byType(EditableText).first, 'Shop two');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(repository.calls, contains('setDefinition'));
    expect(find.text('Taken already'), findsOneWidget);
  });

  testWidgets('the JSON view keeps keys the form has no field for', (
    tester,
  ) async {
    final repository = FakeEnvironmentRepository(
      definitions: [definitionRecord()],
    );
    await _pump(tester, repository);
    await _openFirst(tester);
    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(EditableText).first, '{ nope');
    await tester.pumpAndSettle();
    expect(find.textContaining('Not valid JSON'), findsWidgets);
  });

  testWidgets('the JSON view is highlighted and fills the page', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    await _openFirst(tester);
    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();

    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller, isA<DiffSyntaxTextEditingController>());
    expect(editable.expands, isTrue);
    // Far more room than the short definition needs, and no page scroll.
    expect(tester.getSize(find.byType(CcTextField)).height, greaterThan(1500));
    expect(
      find.ancestor(
        of: find.byType(CcTextField),
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
  });

  testWidgets('a member reads a definition but cannot save', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
      role: WorkspaceRole.member,
    );
    expect(find.text('New definition'), findsNothing);
    await _openFirst(tester);
    expect(
      find.text('Only workspace admins can change definitions.'),
      findsOneWidget,
    );
    expect(find.text('Save'), findsNothing);
  });

  testWidgets('a JSON error disables Save until it parses', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    await _openFirst(tester);
    // An edit first, so there is something Save could commit.
    await tester.enterText(find.byType(EditableText).first, 'Shop two');
    await tester.pumpAndSettle();
    await tester.tap(find.text('JSON'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, '{ nope');
    await tester.pumpAndSettle();

    final save = tester.widget<CcButton>(
      find.ancestor(of: find.text('Save'), matching: find.byType(CcButton)),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('leaving with unsaved edits asks first', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(definitions: [definitionRecord()]),
    );
    await _openFirst(tester);
    await tester.enterText(find.byType(EditableText).first, 'Shop two');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });

  testWidgets('a file-linked definition edits overrides only', (tester) async {
    final linked = EnvironmentDefinitionRecord(
      id: 'def-1',
      workspaceId: kWorkspace,
      name: 'Shop',
      definitionJson: definitionRecord().definitionJson,
      sourceRepoId: 'repo-1',
      sourcePath: '.cc/environment.json',
      approvedBlobHash: 'b1',
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    await _pump(tester, FakeEnvironmentRepository(definitions: [linked]));
    await _openFirst(tester);
    expect(find.text('WORKSPACE OVERRIDES'), findsOneWidget);
  });

  test('a repo opens the definition that owns its worktree tasks', () {
    final binds = definitionRecord(id: 'binds');
    final owns = definitionRecord(
      id: 'owns',
      components: [
        {
          'kind': 'task',
          'id': 'deps',
          'when': ['provision'],
          'command': ['pnpm', 'install'],
        },
      ],
    );
    expect(environmentDefinitionForRepo([binds, owns], 'repo-1')?.id, 'owns');
    expect(environmentDefinitionForRepo([binds], 'repo-2'), isNull);
  });

  group('argv text', () {
    test('round-trips quoted arguments and backslashes', () {
      const argv = ['pnpm', 'run', 'a b', r'c"d', r'C:\tmp', r'a\b'];
      expect(environmentTextToArgv(environmentArgvToText(argv)), argv);
    });

    test('splits like a person typed it', () {
      expect(environmentTextToArgv(r"""a 'b c' "d e" f\ g"""), [
        'a',
        'b c',
        'd e',
        'f g',
      ]);
    });
  });

  group('json paths', () {
    test('a blank value removes the key and leaves the source alone', () {
      final draft = <String, dynamic>{
        'policy': {'maxRunning': 2},
      };
      final next = environmentJsonSet(draft, const [
        'policy',
        'maxRunning',
      ], '');
      expect(next['policy'], isEmpty);
      expect((draft['policy'] as Map)['maxRunning'], 2);
    });

    test('names a path the way the validator does', () {
      expect(
        environmentIssuePath(const ['components', 0, 'cwd', 'role']),
        'components[0].cwd.role',
      );
    });
  });

  test('reads both compose port forms', () {
    final services = parseEnvironmentComposeServices(_compose)!;
    expect(services.map((service) => service.name), [
      'web',
      'postgres',
      'worker',
    ]);
    expect(services[0].ports, ['80']);
    expect(services[1].ports, ['5432']);
    expect(services[2].ports, isEmpty);
  });
}
