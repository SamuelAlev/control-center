import 'dart:async';

import 'package:cc_domain/core/domain/entities/isolated_repo.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_definition_record.dart';
import 'package:cc_domain/features/environments/domain/entities/environment_run.dart';
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/environment_panel.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

const _hostSetup = EnvironmentError(
  code: 'hosts',
  message: 'Adding the hostnames needs sudo',
  exitCode: 3,
);

/// A definition whose tool can finish a stopped start on a terminal.
EnvironmentDefinitionRecord _setupRecord() => definitionRecord(
  components: [
    {
      'kind': 'cli',
      'id': 'tool',
      'verbs': {
        'create': ['tool', 'create'],
        'status': ['tool', 'status'],
        'destroy': ['tool', 'destroy'],
        'setup': ['tool', 'create'],
      },
    },
  ],
);

Future<void> _pump(
  WidgetTester tester,
  FakeEnvironmentRepository repository, {
  WorkspaceRole role = WorkspaceRole.admin,
  TextDirection? textDirection,
  RecordingHost? host,
}) async {
  tester.view.physicalSize = const Size(380, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentRepositoryProvider.overrideWithValue(repository),
        environmentEndpointsAreRemoteProvider.overrideWithValue(false),
        myWorkspaceRoleProvider.overrideWith((ref, _) => role),
        spaceWorktreesProvider.overrideWith(
          (ref, args) async => const <IsolatedRepo>[],
        ),
      ],
      child: testWrap(
        EnvironmentHostScope(
          host: (host ?? RecordingHost()).host,
          child: const EnvironmentPanel(
            workspaceId: kWorkspace,
            spaceId: kSpace,
          ),
        ),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EnvironmentRun _run(
  String id, {
  String? label,
  EnvironmentRunKind kind = EnvironmentRunKind.task,
  EnvironmentRunStatus status = EnvironmentRunStatus.succeeded,
  String output = '',
  int? exitCode,
  required DateTime startedAt,
}) => EnvironmentRun(
  id: id,
  workspaceId: kWorkspace,
  spaceId: kSpace,
  kind: kind,
  label: label,
  status: status,
  output: output,
  exitCode: exitCode,
  startedAt: startedAt,
);

void main() {
  group('nothing to start', () {
    testWidgets('an admin is offered to set one up', (tester) async {
      await _pump(tester, FakeEnvironmentRepository());

      expect(find.text('No environment for this space'), findsOneWidget);
      expect(find.text('Set up environment'), findsOneWidget);
    });

    testWidgets('a member reads who can, with no button', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(),
        role: WorkspaceRole.member,
      );

      expect(find.text('No environment for this space'), findsOneWidget);
      expect(find.text('Set up environment'), findsNothing);
      expect(
        find.textContaining('Only workspace admins can change definitions.'),
        findsOneWidget,
      );
    });

    testWidgets('a Start that stops for host setup opens its terminal', (
      tester,
    ) async {
      final record = definitionRecord(
        components: [
          {
            'kind': 'cli',
            'id': 'tool',
            'verbs': {
              'create': ['tool', 'create'],
              'status': ['tool', 'status'],
              'destroy': ['tool', 'destroy'],
              'setup': ['tool', 'create'],
            },
          },
        ],
      );
      final repository =
          FakeEnvironmentRepository(
              eligibleDefinitions: [record],
              definitions: [record],
            )
            ..ensureResult = environment(
              status: EnvironmentStatus.failed,
              lastError: const EnvironmentError(
                code: 'hosts',
                message: 'Adding the hostnames needs sudo',
                exitCode: 3,
              ),
            );
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      await tester.tap(find.text('Start').first);
      await tester.pumpAndSettle();

      expect(repository.calls, containsAllInOrder(['ensure', 'startSetup']));
      expect(host.opened, ['setup:setup-session']);
    });

    testWidgets('the row a start creates does not cancel its terminal', (
      tester,
    ) async {
      final record = _setupRecord();
      final rows = StreamController<List<SpaceEnvironment>>();
      addTearDown(rows.close);
      final stopped = environment(
        status: EnvironmentStatus.failed,
        lastError: _hostSetup,
      );
      final repository =
          FakeEnvironmentRepository(
              eligibleDefinitions: [record],
              definitions: [record],
            )
            ..liveRows = rows.stream
            ..ensureGate = Completer<void>()
            ..ensureResult = stopped;
      rows.add(const []);
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      await tester.tap(find.text('Start').first);
      await tester.pump();
      // The server publishes the row long before `ensure` returns, and it
      // replaces the Start button that was pressed.
      rows.add([environment(status: EnvironmentStatus.creating)]);
      await tester.pump();
      await tester.pump();
      expect(find.text('Start'), findsNothing);

      rows.add([stopped]);
      repository.ensureGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.calls, contains('startSetup'));
      expect(host.opened, ['setup:setup-session']);
    });

    testWidgets('a Start that answers after leaving the space opens nothing', (
      tester,
    ) async {
      final record = _setupRecord();
      final repository =
          FakeEnvironmentRepository(
              eligibleDefinitions: [record],
              definitions: [record],
            )
            ..ensureGate = Completer<void>()
            ..ensureResult = environment(
              status: EnvironmentStatus.failed,
              lastError: _hostSetup,
            );
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      await tester.tap(find.text('Start').first);
      await tester.pump();
      host.onSpace = false;
      repository.ensureGate!.complete();
      await tester.pumpAndSettle();

      expect(repository.calls, isNot(contains('startSetup')));
      expect(host.opened, isEmpty);
    });

    testWidgets('a Start that worked opens nothing', (tester) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [definitionRecord()],
        definitions: [definitionRecord()],
      );
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      await tester.tap(find.text('Start').first);
      await tester.pumpAndSettle();

      expect(repository.calls, isNot(contains('startSetup')));
      expect(host.opened, isEmpty);
    });

    testWidgets('a definition the space can start offers Start', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(eligibleDefinitions: [definitionRecord()]),
      );

      expect(find.text('No environment for this space'), findsNothing);
      expect(find.text('Start'), findsWidgets);
    });
  });

  group('a running environment', () {
    FakeEnvironmentRepository running({List<EnvironmentRun> runs = const []}) =>
        FakeEnvironmentRepository(
          definitions: [
            definitionRecord(
              components: [
                {'kind': 'compose', 'id': 'stack'},
                {
                  'kind': 'task',
                  'id': 'seed',
                  'when': ['manual'],
                  'command': ['make', 'seed'],
                },
              ],
            ),
          ],
          environments: [
            environment(
              endpoints: [
                EnvironmentEndpoint(
                  role: 'app',
                  label: 'App',
                  url: 'https://fix-login.acme.test',
                  primary: true,
                ),
              ],
              components: [
                EnvironmentComponentState(
                  id: 'stack',
                  kind: 'compose',
                  state: 'running',
                ),
                EnvironmentComponentState(
                  id: 'seed',
                  kind: 'task',
                  state: 'idle',
                ),
              ],
            ),
          ],
          runs: runs,
        );

    testWidgets('splits URLs, components and scripts into sections', (
      tester,
    ) async {
      await _pump(tester, running());

      expect(find.text('URLS'), findsOneWidget);
      expect(find.text('COMPONENTS'), findsOneWidget);
      expect(find.text('SCRIPTS'), findsOneWidget);
    });

    testWidgets('Destroy is in plain sight, and asks first', (tester) async {
      final repository = running();
      await _pump(tester, repository);

      await tester.tap(find.text('Destroy'));
      await tester.pumpAndSettle();
      expect(repository.calls, isNot(contains('destroy')));

      await tester.tap(find.text('Destroy').last);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('destroy'));
    });

    testWidgets('a failed start can be destroyed too', (tester) async {
      final repository = running();
      repository.environments = [
        environment(
          status: EnvironmentStatus.failed,
          lastError: const EnvironmentError(code: 'x', message: 'Broke'),
        ),
      ];
      await _pump(tester, repository);

      expect(find.text('Destroy'), findsOneWidget);
    });

    testWidgets('a stopped environment lists no URLs to open', (tester) async {
      final repository = running();
      repository.environments = [
        environment(
          status: EnvironmentStatus.stopped,
          endpoints: repository.environments.single.endpoints,
        ),
      ];
      await _pump(tester, repository);

      expect(find.text('URLS'), findsNothing);
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('a failure offers Retry alone, with its reason at the top', (
      tester,
    ) async {
      final repository = running();
      repository.environments = [
        environment(
          status: EnvironmentStatus.failed,
          lastError: const EnvironmentError(
            code: 'failed',
            message: 'The dev server stopped',
            hint: 'app HTTP 502',
          ),
        ),
      ];
      await _pump(tester, repository);

      expect(find.text('The dev server stopped'), findsOneWidget);
      expect(find.text('app HTTP 502'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Start'), findsNothing);
    });

    testWidgets('a run keeps its output closed until asked', (tester) async {
      await _pump(
        tester,
        running(
          runs: [
            _run(
              'new',
              label: 'seed',
              status: EnvironmentRunStatus.failed,
              exitCode: 2,
              output: 'seed: table users missing',
              startedAt: DateTime.utc(2026, 1, 2),
            ),
          ],
        ),
      );

      expect(find.text('ACTIVITY'), findsOneWidget);
      expect(find.text('seed: table users missing'), findsNothing);

      await tester.tap(find.text('seed').last);
      await tester.pumpAndSettle();
      expect(find.text('seed: table users missing'), findsOneWidget);
    });

    testWidgets('a run without a label is named by its kind', (tester) async {
      await _pump(
        tester,
        running(
          runs: [
            _run(
              'start',
              kind: EnvironmentRunKind.start,
              startedAt: DateTime.utc(2026),
            ),
          ],
        ),
      );

      expect(find.text('Start'), findsWidgets);
    });

    testWidgets('a start stopped for host setup reads as needing setup', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          definitions: [definitionRecord()],
          environments: [
            environment(
              status: EnvironmentStatus.failed,
              lastError: const EnvironmentError(
                code: 'hosts',
                message: 'Adding the hostnames needs sudo',
                command: 'tool create',
                exitCode: 3,
              ),
              components: [
                EnvironmentComponentState(
                  id: 'stack',
                  kind: 'cli',
                  state: 'failed',
                ),
              ],
            ),
          ],
        ),
      );

      expect(find.text('Needs setup'), findsNWidgets(2));
      expect(find.text('Failed'), findsNothing);
      expect(find.text('Run in terminal'), findsOneWidget);
    });

    testWidgets('a definition with a setup verb offers its terminal', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        definitions: [
          definitionRecord(
            components: [
              {
                'kind': 'cli',
                'id': 'tool',
                'verbs': {
                  'create': ['tool', 'create'],
                  'status': ['tool', 'status'],
                  'destroy': ['tool', 'destroy'],
                  'setup': ['tool', 'create'],
                },
              },
            ],
          ),
        ],
        environments: [
          environment(
            status: EnvironmentStatus.failed,
            lastError: const EnvironmentError(
              code: 'hosts',
              message: 'Adding the hostnames needs sudo',
              command: 'tool create',
              exitCode: 3,
            ),
            components: [
              EnvironmentComponentState(
                id: 'tool',
                kind: 'cli',
                state: 'failed',
              ),
            ],
          ),
        ],
      );
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      // A row that was already waiting opens nothing by itself, and the tab
      // does the explaining, so this is only the way back to it.
      expect(repository.calls, isNot(contains('startSetup')));
      expect(find.text('This needs setting up on the server'), findsNothing);
      expect(find.text('Needs setup'), findsWidgets);
      expect(find.text('Run in terminal'), findsNothing);
      await tester.tap(find.text('Continue in terminal'));
      await tester.pumpAndSettle();

      expect(repository.calls, contains('startSetup'));
      expect(host.opened, contains('setup:setup-session'));
    });

    testWidgets('lays out right to left', (tester) async {
      await _pump(tester, running(), textDirection: TextDirection.rtl);

      expect(tester.takeException(), isNull);
      expect(find.text('SCRIPTS'), findsOneWidget);
    });
  });
}
