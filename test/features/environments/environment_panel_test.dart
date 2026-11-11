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

/// A definition whose tool can carry a start on at a terminal.
EnvironmentDefinitionRecord _interactiveRecord() => definitionRecord(
  components: [
    {
      'kind': 'cli',
      'id': 'tool',
      'verbs': {
        'create': ['tool', 'create'],
        'status': ['tool', 'status'],
        'destroy': ['tool', 'destroy'],
      },
      'interactive': ['create'],
    },
  ],
);

/// A start that waits for someone on terminal [sessionId].
SpaceEnvironment _waiting([String sessionId = 'session-1']) => environment(
  status: EnvironmentStatus.creating,
  components: [
    EnvironmentComponentState(
      id: 'tool',
      kind: 'cli',
      state: 'interactive',
      sessionId: sessionId,
      detail: _hostSetup.message,
    ),
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

    /// A start in flight: its rows arrive as the server publishes them.
    Future<
      ({
        FakeEnvironmentRepository repository,
        StreamController<List<SpaceEnvironment>> rows,
        RecordingHost host,
      })
    >
    pressStart(WidgetTester tester) async {
      final record = _interactiveRecord();
      final rows = StreamController<List<SpaceEnvironment>>();
      addTearDown(rows.close);
      final repository =
          FakeEnvironmentRepository(
              eligibleDefinitions: [record],
              definitions: [record],
            )
            ..liveRows = rows.stream
            ..ensureGate = Completer<void>();
      rows.add(const []);
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      await tester.tap(find.text('Start').first);
      await tester.pump();
      return (repository: repository, rows: rows, host: host);
    }

    Future<void> publish(
      WidgetTester tester,
      StreamController<List<SpaceEnvironment>> rows,
      SpaceEnvironment row,
    ) async {
      rows.add([row]);
      await tester.pump();
      await tester.pump();
    }

    testWidgets('a Start says someone is there to answer', (tester) async {
      final start = await pressStart(tester);

      expect(start.repository.lastAttended, isTrue);

      start.repository.ensureGate!.complete();
      await publish(tester, start.rows, environment());
    });

    testWidgets('a start that needs someone opens the terminal it waits on', (
      tester,
    ) async {
      final start = await pressStart(tester);
      // The server publishes the row long before `ensure` returns, and it
      // replaces the Start button that was pressed.
      await publish(
        tester,
        start.rows,
        environment(status: EnvironmentStatus.creating),
      );
      expect(find.text('Start'), findsNothing);
      expect(start.host.opened, isEmpty);

      await publish(tester, start.rows, _waiting());
      expect(start.host.opened, ['start-terminal:session-1']);
      // The start is still the one start: nothing asked for a second.
      expect(
        start.repository.calls.where((call) => call == 'ensure').length,
        1,
      );

      // However often the row is published, the tab opens once.
      await publish(tester, start.rows, _waiting());
      expect(start.host.opened, ['start-terminal:session-1']);

      start.repository.ensureGate!.complete();
      await publish(tester, start.rows, environment());
      expect(start.host.opened, ['start-terminal:session-1']);
    });

    testWidgets('a second wait in the same start opens its own terminal', (
      tester,
    ) async {
      final start = await pressStart(tester);

      await publish(tester, start.rows, _waiting());
      await publish(
        tester,
        start.rows,
        environment(status: EnvironmentStatus.creating),
      );
      await publish(tester, start.rows, _waiting('session-2'));

      expect(start.host.opened, [
        'start-terminal:session-1',
        'start-terminal:session-2',
      ]);

      start.repository.ensureGate!.complete();
      await publish(tester, start.rows, environment());
    });

    testWidgets('someone who left the space gets no tab, and a way back', (
      tester,
    ) async {
      final start = await pressStart(tester);
      start.host.onSpace = false;

      await publish(tester, start.rows, _waiting());

      expect(start.host.opened, isEmpty);
      expect(find.text('Waiting for you in a terminal'), findsOneWidget);
      expect(
        find.textContaining('Adding the hostnames needs sudo'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open terminal'));
      await tester.pump();
      expect(start.host.opened, ['start-terminal:session-1']);

      start.repository.ensureGate!.complete();
      await publish(tester, start.rows, environment());
    });

    testWidgets('a wait that began before this start is not opened after it', (
      tester,
    ) async {
      final start = await pressStart(tester);
      start.repository.ensureGate!.complete();
      await publish(tester, start.rows, environment());

      // Someone else's start, later: this press is over.
      await publish(tester, start.rows, _waiting('session-9'));

      expect(start.host.opened, isEmpty);
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

      expect(repository.calls, contains('ensure'));
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

    /// A start that stopped for someone, on the component named [stopped].
    SpaceEnvironment blocked({String stopped = 'tool'}) => environment(
      status: EnvironmentStatus.blocked,
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
          state: stopped == 'tool' ? 'failed' : 'ready',
        ),
        EnvironmentComponentState(
          id: 'seed',
          kind: 'task',
          state: stopped == 'seed' ? 'failed' : 'pending',
        ),
      ],
    );

    testWidgets('a start that waits on someone reads as action needed', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          definitions: [definitionRecord()],
          environments: [blocked()],
        ),
      );

      expect(find.text('Action needed'), findsWidgets);
      expect(find.text('Failed'), findsNothing);
      expect(find.text('This needs setting up on the server'), findsOneWidget);
      // Nothing in this definition runs on a terminal, so it says how by hand.
      expect(find.text('Continue in terminal'), findsNothing);
      expect(find.text('Run in terminal'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('a tool that can ask for itself is continued on a terminal', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        definitions: [_interactiveRecord()],
        environments: [blocked()],
      );
      final host = RecordingHost();
      await _pump(tester, repository, host: host);

      // A row that was already waiting starts nothing by itself.
      expect(repository.calls, isNot(contains('ensure')));
      expect(find.text('Run in terminal'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      // The tool's own command is not shown: it is never what runs.
      expect(find.text('tool create'), findsNothing);
      await tester.tap(find.text('Continue in terminal'));
      await tester.pumpAndSettle();

      // The same start again, this time with someone there.
      expect(repository.calls, contains('ensure'));
      expect(repository.lastAttended, isTrue);
    });

    testWidgets('a task that needs someone says how, since only a tool\'s '
        'verb runs on a terminal', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          definitions: [_interactiveRecord()],
          environments: [blocked(stopped: 'seed')],
        ),
      );

      expect(find.text('Continue in terminal'), findsNothing);
      expect(find.text('Run in terminal'), findsOneWidget);
    });

    testWidgets('a sign-in and a missing dependency say which', (tester) async {
      Future<void> pumpWith(int exitCode) => _pump(
        tester,
        FakeEnvironmentRepository(
          definitions: [definitionRecord()],
          environments: [
            environment(
              status: EnvironmentStatus.blocked,
              lastError: EnvironmentError(
                code: 'blocked',
                message: 'Stopped',
                exitCode: exitCode,
              ),
            ),
          ],
        ),
      );

      await pumpWith(4);
      expect(find.text('This needs you to sign in'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpWith(5);
      expect(
        find.text('Something this needs is not available'),
        findsOneWidget,
      );
    });

    testWidgets('lays out right to left', (tester) async {
      await _pump(tester, running(), textDirection: TextDirection.rtl);

      expect(tester.takeException(), isNull);
      expect(find.text('SCRIPTS'), findsOneWidget);
    });
  });
}
