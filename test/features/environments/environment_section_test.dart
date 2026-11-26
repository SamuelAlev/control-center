import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/environments/domain/entities/space_environment.dart';
import 'package:cc_domain/features/environments/domain/value_objects/environment_status.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_host.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_section.dart';
import 'package:control_center/features/environments/presentation/widgets/environment_step_list.dart';
import 'package:control_center/features/environments/providers/environment_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';
import 'environment_test_support.dart';

/// An icon action, found by the name its tooltip gives it.
Finder _action(String name) => find.byWidgetPredicate(
  (widget) => widget is CcIconButton && widget.tooltip == name,
);

Future<void> _pump(
  WidgetTester tester,
  FakeEnvironmentRepository repository, {
  RecordingHost? host,
  bool remote = false,
  bool isDemo = false,
  TextDirection? textDirection,
}) async {
  tester.view.physicalSize = const Size(420, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        environmentRepositoryProvider.overrideWithValue(repository),
        environmentEndpointsAreRemoteProvider.overrideWithValue(remote),
      ],
      child: testWrap(
        EnvironmentHostScope(
          host: (host ?? RecordingHost()).host,
          child: const SingleChildScrollView(
            child: EnvironmentSection(workspaceId: kWorkspace, spaceId: kSpace),
          ),
        ),
        isDemo: isDemo,
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

EnvironmentComponentState _state(
  String id,
  String kind,
  String state, {
  String? label,
  int restarts = 0,
  List<Map<String, dynamic>> services = const [],
  String? sessionId,
  DateTime? lastRunAt,
  int? lastExitCode,
}) => EnvironmentComponentState(
  id: id,
  kind: kind,
  state: state,
  label: label,
  restarts: restarts,
  services: services,
  sessionId: sessionId,
  lastRunAt: lastRunAt,
  lastExitCode: lastExitCode,
);

void main() {
  group('component rows', () {
    testWidgets('compose lists services, health and ports with its actions', (
      tester,
    ) async {
      final host = RecordingHost();
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [definitionRecord()],
        environments: [
          environment(
            components: [
              _state(
                'stack',
                'compose',
                'ready',
                services: [
                  {
                    'name': 'postgres',
                    'state': 'ready',
                    'health': 'healthy',
                    'ports': [41001],
                  },
                ],
              ),
            ],
          ),
        ],
      );
      await _pump(tester, repository, host: host);

      expect(find.text('postgres'), findsOneWidget);
      expect(find.textContaining('Healthy'), findsOneWidget);
      expect(find.text('41001'), findsOneWidget);
      expect(_action('Exec'), findsOneWidget);

      await tester.tap(_action('Logs'));
      await tester.tap(_action('Restart'));
      await tester.pumpAndSettle();
      expect(host.opened, ['logs:stack']);
      expect(repository.calls, contains('restart:stack'));
    });

    testWidgets('process shows restarts and opens its session', (tester) async {
      final host = RecordingHost();
      final repository = FakeEnvironmentRepository(
        environments: [
          environment(
            components: [
              _state(
                'web',
                'process',
                'running',
                restarts: 2,
                sessionId: 'tty1',
              ),
            ],
          ),
        ],
      );
      await _pump(tester, repository, host: host);

      expect(find.text('2 restarts'), findsOneWidget);
      await tester.tap(_action('Open'));
      await tester.pumpAndSettle();
      expect(host.opened, ['process:tty1']);
    });

    testWidgets('without the operate right the controls are disabled, '
        'with the reason', (tester) async {
      final repository = FakeEnvironmentRepository(
        environments: [
          environment(
            components: [
              _state('web', 'process', 'running', sessionId: 'tty1'),
            ],
          ),
        ],
      )..canOperate = false;
      await _pump(tester, repository);

      expect(
        find.textContaining('You can watch this environment.'),
        findsOneWidget,
      );
      expect(tester.widget<CcIconButton>(_action('Restart')).onPressed, isNull);
      expect(
        tester
            .widget<CcButton>(find.widgetWithText(CcButton, 'Stop'))
            .onPressed,
        isNull,
      );
      // Watching stays open: the process's own terminal opens read-only.
      expect(tester.widget<CcIconButton>(_action('Open')).onPressed, isNotNull);
    });

    testWidgets('with the operate right there is no reason line', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        environments: [
          environment(
            components: [
              _state('web', 'process', 'running', sessionId: 'tty1'),
            ],
          ),
        ],
      );
      await _pump(tester, repository);

      expect(
        find.textContaining('You can watch this environment.'),
        findsNothing,
      );
      expect(
        tester.widget<CcIconButton>(_action('Restart')).onPressed,
        isNotNull,
      );
    });

    testWidgets('a manual task shows its last result and runs on request', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [
          definitionRecord(
            components: [
              {
                'kind': 'task',
                'id': 'migrate',
                'when': ['manual'],
                'command': ['pnpm', 'migrate'],
              },
            ],
          ),
        ],
        environments: [
          environment(
            components: [
              _state(
                'migrate',
                'task',
                'completed',
                lastRunAt: DateTime.utc(2026),
                lastExitCode: 1,
              ),
            ],
          ),
        ],
      );
      await _pump(tester, repository);

      expect(find.text('Exit code 1'), findsOneWidget);
      await tester.tap(_action('Run'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('run:migrate'));
    });

    testWidgets('cli shows mapped endpoints and services', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
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
                _state(
                  'tool',
                  'cli',
                  'ready',
                  services: [
                    {'name': 'api'},
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Its endpoints are listed under URLs, not repeated on the row.
      expect(find.textContaining('Endpoints:'), findsNothing);
      expect(find.text('App'), findsOneWidget);
    });

    testWidgets('a closed app offers Launch and Rebuild, not the viewer', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        environments: [
          environment(components: [_state('desktop', 'app', 'closed')]),
        ],
      );
      await _pump(tester, repository);

      expect(find.text('Closed'), findsOneWidget);
      expect(_action('Open viewer'), findsNothing);
      await tester.tap(_action('Rebuild & relaunch'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('launch:desktop:true'));
      await tester.tap(_action('Launch'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('launch:desktop:false'));
    });

    testWidgets('a task that is not manual has no Run', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          eligibleDefinitions: [
            definitionRecord(
              components: [
                {
                  'kind': 'task',
                  'id': 'seed',
                  'when': ['create'],
                  'command': ['pnpm', 'seed'],
                },
              ],
            ),
          ],
          environments: [
            environment(components: [_state('seed', 'task', 'completed')]),
          ],
        ),
      );
      expect(_action('Run'), findsNothing);
    });

    testWidgets('a running app with a window offers the viewer', (
      tester,
    ) async {
      final host = RecordingHost();
      await _pump(
        tester,
        FakeEnvironmentRepository(
          environments: [
            environment(
              components: [
                _state(
                  'desktop',
                  'app',
                  'running',
                  services: [
                    {'name': 'window', 'rig_id': 'rig-1'},
                  ],
                ),
              ],
            ),
          ],
        ),
        host: host,
      );

      expect(_action('Launch'), findsNothing);
      await tester.tap(_action('Open viewer'));
      expect(host.opened, ['viewer:desktop']);
    });

    testWidgets('a running app without a window explains the missing viewer', (
      tester,
    ) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          environments: [
            environment(components: [_state('desktop', 'app', 'running')]),
          ],
        ),
      );
      expect(_action('Open viewer'), findsNothing);
      expect(find.textContaining('Screen Recording'), findsOneWidget);
      expect(_action('Logs'), findsOneWidget);
    });

    testWidgets('a stopped environment cannot launch its app', (tester) async {
      final repository = FakeEnvironmentRepository(
        environments: [
          environment(
            status: EnvironmentStatus.stopped,
            components: [_state('desktop', 'app', 'closed')],
          ),
        ],
      );
      await _pump(tester, repository);
      await tester.tap(_action('Launch'));
      await tester.pumpAndSettle();
      expect(repository.calls, isNot(contains('launch:desktop:false')));
    });
  });

  group('start', () {
    testWidgets('options go through the form to ensure', (tester) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [
          definitionRecord(
            options: [
              {'key': 'seed', 'type': 'bool', 'default': true, 'label': 'Seed'},
              {
                'key': 'mode',
                'type': 'enum',
                'values': ['web', 'desktop'],
                'default': 'web',
              },
            ],
          ),
        ],
      );
      await _pump(tester, repository);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Start environment'), findsOneWidget);
      expect(find.text('Seed'), findsOneWidget);
      expect(repository.calls, isNot(contains('ensure')));

      await tester.tap(find.text('Start').last);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('ensure'));
      expect(repository.lastDefinitionId, 'def-1');
      expect(repository.lastOptions, {'seed': true, 'mode': 'web'});
    });

    testWidgets('no options and one definition skip the form', (tester) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [definitionRecord()],
      );
      await _pump(tester, repository);

      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('Start environment'), findsNothing);
      expect(repository.calls, contains('ensure'));
    });

    testWidgets('a definition with no stack shows no Start', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          eligibleDefinitions: [
            definitionRecord(
              components: [
                {
                  'kind': 'task',
                  'id': 'deps',
                  'when': ['provision'],
                  'command': ['pnpm', 'install'],
                },
              ],
            ),
          ],
        ),
      );

      expect(find.text('Start'), findsNothing);
      expect(
        find.text('Runs worktree tasks only, so there is nothing to start.'),
        findsOneWidget,
      );
    });

    testWidgets('a space with nothing eligible shows no section', (
      tester,
    ) async {
      await _pump(tester, FakeEnvironmentRepository());
      expect(find.text('Environment'), findsNothing);
      expect(find.text('Start'), findsNothing);
    });
  });

  group('stop', () {
    final losesData = definitionRecord(
      components: [
        {
          'kind': 'cli',
          'id': 'tool',
          'keepsDataOnStop': false,
          'verbs': {
            'create': ['tool', 'up'],
            'status': ['tool', 'status'],
            'destroy': ['tool', 'down'],
          },
        },
      ],
    );

    testWidgets('warns when stopping loses data', (tester) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [losesData],
        environments: [environment()],
      );
      await _pump(tester, repository);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Stop this environment?'), findsOneWidget);
      expect(repository.calls, isNot(contains('down')));

      await tester.tap(find.text('Stop and lose data'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('down'));
    });

    testWidgets('a failed environment with running parts offers Stop', (
      tester,
    ) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [definitionRecord()],
        environments: [
          environment(
            status: EnvironmentStatus.failed,
            components: [
              _state('stack', 'compose', 'ready'),
              _state('web', 'process', 'failed'),
            ],
          ),
        ],
      );
      await _pump(tester, repository);
      await tester.tap(find.text('Stop').last);
      await tester.pumpAndSettle();
      expect(repository.calls, contains('down'));
    });

    testWidgets('stops at once when the data survives', (tester) async {
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [definitionRecord()],
        environments: [environment()],
      );
      await _pump(tester, repository);

      await tester.tap(find.text('Stop'));
      await tester.pumpAndSettle();
      expect(find.text('Stop this environment?'), findsNothing);
      expect(repository.calls, contains('down'));
    });
  });

  group('errors', () {
    const hostSetup = EnvironmentError(
      code: 'needs-setup',
      message: 'The tool is not set up',
      command: 'tool setup',
      exitCode: 3,
    );

    testWidgets('exit 3 types the command in a terminal, then retries', (
      tester,
    ) async {
      final host = RecordingHost();
      final repository = FakeEnvironmentRepository(
        eligibleDefinitions: [definitionRecord()],
        environments: [
          environment(
            status: EnvironmentStatus.failed,
            lastError: hostSetup,
            components: [_state('stack', 'compose', 'failed')],
          ),
        ],
      );
      await _pump(tester, repository, host: host);

      expect(find.text('This needs setting up on the server'), findsOneWidget);
      expect(find.text('tool setup'), findsOneWidget);

      await tester.tap(find.text('Run in terminal'));
      expect(host.opened, ['terminal:tool setup']);
      expect(repository.calls, isNot(contains('ensure')));

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(repository.calls, contains('ensure'));
      expect(repository.lastDefinitionId, 'def-1');
    });

    testWidgets('a multi-line fix is offered for copying only', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          environments: [
            environment(
              status: EnvironmentStatus.failed,
              lastError: const EnvironmentError(
                code: 'needs-setup',
                message: 'Not set up',
                command: 'tool login\ntool setup',
                exitCode: 3,
              ),
              components: [_state('stack', 'compose', 'failed')],
            ),
          ],
        ),
      );
      expect(find.text('Run in terminal'), findsNothing);
      expect(find.byIcon(AppIcons.copy), findsOneWidget);
    });

    testWidgets('any other failure has no terminal action', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          environments: [
            environment(
              status: EnvironmentStatus.failed,
              lastError: const EnvironmentError(
                code: 'boom',
                message: 'Port in use',
                command: 'lsof -i :5432',
                exitCode: 1,
              ),
              components: [_state('stack', 'compose', 'failed')],
            ),
          ],
        ),
      );

      expect(find.text('Port in use'), findsOneWidget);
      expect(find.text('lsof -i :5432'), findsOneWidget);
      expect(find.text('Run in terminal'), findsNothing);
    });
  });

  group('endpoints', () {
    final endpoint = EnvironmentEndpoint(
      role: 'web',
      label: 'Web',
      url: 'http://web--fix--shop.localhost:4100',
      primary: true,
    );

    testWidgets('a local client sees no server label', (tester) async {
      final host = RecordingHost();
      await _pump(
        tester,
        FakeEnvironmentRepository(
          environments: [
            environment(endpoints: [endpoint]),
          ],
        ),
        host: host,
      );

      expect(find.text('On the server'), findsNothing);
      await tester.tap(find.text(endpoint.label));
      await tester.pump();
      expect(host.opened, ['url:${endpoint.url}']);
    });

    testWidgets('a remote client sees them labelled', (tester) async {
      await _pump(
        tester,
        FakeEnvironmentRepository(
          environments: [
            environment(endpoints: [endpoint]),
          ],
        ),
        remote: true,
      );

      // Once for the list, not once per row.
      expect(find.text('On the server'), findsOneWidget);
      expect(find.byIcon(AppIcons.externalLink), findsOneWidget);
    });
  });

  testWidgets('needs_recreate offers Recreate', (tester) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(
        environments: [environment(needsRecreate: true)],
      ),
    );
    expect(find.text('Recreate'), findsOneWidget);
  });

  testWidgets('a server without environments gets one plain notice', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository()
        ..readError = RemoteRpcException(RpcErrorCodes.opUnknown, 'no op'),
    );
    expect(
      find.text("This server doesn't support environments."),
      findsOneWidget,
    );
    expect(find.textContaining('no op'), findsNothing);
  });

  testWidgets('a double tap on Start starts once', (tester) async {
    final gate = Completer<void>();
    final repository = FakeEnvironmentRepository(
      eligibleDefinitions: [definitionRecord()],
    )..ensureGate = gate;
    await _pump(tester, repository);
    await tester.tap(find.text('Start'));
    await tester.pump();
    await tester.tap(find.text('Start'), warnIfMissed: false);
    await tester.pump();
    gate.complete();
    await tester.pumpAndSettle();
    expect(repository.calls.where((call) => call == 'ensure'), hasLength(1));
  });

  testWidgets('a demo calls nothing and shows nothing', (tester) async {
    final repository = FakeEnvironmentRepository(
      eligibleDefinitions: [definitionRecord()],
      environments: [environment()],
    );
    await _pump(tester, repository, isDemo: true);

    expect(find.byType(EnvironmentSection), findsOneWidget);
    expect(find.text('Stop'), findsNothing);
    expect(repository.calls, isEmpty);
  });

  testWidgets('lays out under RTL with machine values left to right', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(
        environments: [
          environment(
            endpoints: [
              EnvironmentEndpoint(
                role: 'web',
                url: 'http://web.localhost:4100',
              ),
            ],
            components: [_state('web', 'process', 'running')],
          ),
        ],
      ),
      textDirection: TextDirection.rtl,
    );

    expect(tester.takeException(), isNull);
    final url = find.text('web.localhost:4100');
    expect(Directionality.of(tester.element(url)), TextDirection.ltr);
    expect(
      Directionality.of(tester.element(find.text('Stop').last)),
      TextDirection.rtl,
    );
  });

  group('the steps of a start', () {
    const pulled = EnvironmentProgress(
      type: 'step',
      id: '1',
      label: 'Pulled 4 images',
      state: 'done',
    );
    const containers = EnvironmentProgress(
      type: 'step',
      id: '2',
      label: 'Starting the containers',
      state: 'running',
    );

    SpaceEnvironment starting() => environment(
      status: EnvironmentStatus.starting,
      components: [
        _state(
          'tool',
          'cli',
          'starting',
          label: 'Stack',
        ).copyWith(steps: const [pulled, containers]),
        _state('web', 'process', 'waiting').copyWith(detail: 'Port 4100'),
        _state('migrate', 'task', 'pending'),
        // What this start never runs is not a step of it.
        _state('e2e', 'task', 'idle'),
        _state('desktop', 'app', 'closed'),
      ],
    );

    test('one row for each part the start goes through', () {
      expect(environmentSteps(starting()), [
        (
          label: 'Stack',
          state: EnvironmentStepState.running,
          detail: 'Starting the containers',
        ),
        (
          label: 'web',
          state: EnvironmentStepState.running,
          detail: 'Port 4100',
        ),
        (label: 'migrate', state: EnvironmentStepState.pending, detail: null),
      ]);
    });

    test('a tool\'s steps never add rows, whatever it reports', () {
      SpaceEnvironment after(List<EnvironmentProgress> steps) => environment(
        status: EnvironmentStatus.starting,
        components: [_state('tool', 'cli', 'starting').copyWith(steps: steps)],
      );
      expect(environmentSteps(after(const [])), [
        (label: 'tool', state: EnvironmentStepState.running, detail: null),
      ]);
      expect(environmentSteps(after(const [pulled])).single.detail, isNull);
      expect(
        environmentSteps(after(const [pulled, containers])).single.detail,
        'Starting the containers',
      );
    });

    test('a part that is done says nothing more', () {
      final ready = environment(
        components: [
          _state(
            'tool',
            'cli',
            'ready',
          ).copyWith(detail: 'post-start: succeeded', steps: const [pulled]),
        ],
      );
      expect(environmentSteps(ready), [
        (label: 'tool', state: EnvironmentStepState.done, detail: null),
      ]);
    });

    testWidgets('the step under way sits beneath its part', (tester) async {
      await tester.pumpWidget(
        testWrap(EnvironmentStepList(environment: starting())),
      );
      await tester.pump();

      expect(find.text('Stack'), findsOneWidget);
      expect(find.text('Starting the containers'), findsOneWidget);
      expect(find.text('Pulled 4 images'), findsNothing);
      expect(find.text('migrate'), findsOneWidget);
      expect(find.text('e2e'), findsNothing);
      expect(find.text('desktop'), findsNothing);
      expect(find.byType(CcSpinner), findsNWidgets(2));
      expect(
        tester.getTopLeft(find.text('Starting the containers')).dy,
        greaterThan(tester.getTopLeft(find.text('Stack')).dy),
      );
    });

    testWidgets('the same under RTL', (tester) async {
      await tester.pumpWidget(
        testWrap(
          EnvironmentStepList(environment: starting()),
          textDirection: TextDirection.rtl,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      // The detail lines up with its part's name, on the reading side.
      expect(
        tester.getTopRight(find.text('Starting the containers')).dx,
        tester.getTopRight(find.text('Stack')).dx,
      );
    });
  });

  testWidgets('a failure shows what the tool printed last, to read and copy', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeEnvironmentRepository(
        environments: [
          environment(
            status: EnvironmentStatus.failed,
            lastError: EnvironmentError(
              code: 'compose.up',
              message: 'The stack did not start',
              exitCode: 1,
              output: [
                for (var i = 1; i <= 8; i++) 'pull $i',
                'denied: the token has expired',
              ].join('\n'),
            ),
            components: [_state('tool', 'cli', 'failed')],
          ),
        ],
      ),
    );

    expect(find.text('The stack did not start'), findsOneWidget);
    final box = find.textContaining('denied: the token has expired');
    expect(box, findsOneWidget);
    // The end of it: the reason is in the last lines.
    final shown = tester.widget<Text>(box).data!.split('\n');
    expect(shown, hasLength(6));
    expect(shown.first, 'pull 4');
    expect(Directionality.of(tester.element(box)), TextDirection.ltr);
  });
}
