import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart'
    show AgentDto, RpcMethods, SpaceDto, UserDto;
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/l10n/phone_widgets_localizations.dart';
import 'package:cc_remote/l10n/remote_locales.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/providers.dart';
import 'package:cc_remote/work_providers.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

const ws = 'ws1';

/// One op the phone sent.
typedef SentOp = ({String op, Map<String, dynamic> args});

/// An in-process server: records every op and answers it, or refuses it
/// with a `data.kind` when [refuse] names one.
class WorkRpcHost {
  WorkRpcHost() {
    final (host, channel) = InProcessRpcChannel.pair();
    _server = host;
    _server.incoming.listen(_handle);
    client = RemoteRpcClient(channel)..start();
  }

  late final RemoteRpcChannelPort _server;
  late final RemoteRpcClient client;
  final sent = <SentOp>[];
  String? refuse;
  Map<String, dynamic> Function(String op, Map<String, dynamic> args)? answer;

  List<String> get ops => [for (final s in sent) s.op];

  void _handle(Map<String, dynamic> frame) {
    final id = frame['id'];
    if (id == null) return;
    final params = (frame['params'] as Map?)?.cast<String, dynamic>() ?? {};
    if (frame['method'] != RpcMethods.repoCall) {
      unawaited(
        _server.send({
          'jsonrpc': '2.0',
          'id': id,
          'result': {'capabilities': <String, dynamic>{}},
        }),
      );
      return;
    }
    final op = params['op'] as String;
    final args = (params['args'] as Map).cast<String, dynamic>();
    sent.add((op: op, args: args));
    final kind = refuse;
    unawaited(
      _server.send(
        kind != null
            ? {
                'jsonrpc': '2.0',
                'id': id,
                'error': {
                  'code': -32000,
                  'message': 'Refused in English',
                  'data': {'kind': kind},
                },
              }
            : {
                'jsonrpc': '2.0',
                'id': id,
                'result': {
                  'op': op,
                  'data': answer?.call(op, args) ?? _defaults(op),
                },
              },
      ),
    );
  }

  static Map<String, dynamic> _defaults(String op) => switch (op) {
    'wakeRules.pause' => {'paused': true},
    'wakeRules.resume' => {'resumed': true},
    'wakeRules.delete' => {'deleted': true},
    'wakes.cancel' => {'cancelled': true},
    'wakes.release' => {'released': 1},
    'steering.release' => {'released': 2},
    'wakeRules.create' => {
      'rule': {
        'id': 'r1',
        'workspace_id': ws,
        'space_id': 's1',
        'conversation_id': 'c1',
        'agent_id': 'a1',
        'origin': 'person',
        'trigger': 'every:30m',
        'trigger_kind': 'every',
        'note': 'note',
        'deliver': 'run',
        'when_busy': 'skip',
        'status': 'active',
        'expires_at': '2026-11-27T10:00:00Z',
        'created_at': '2026-11-20T10:00:00Z',
        'can_change': true,
      },
    },
    'wakes.deliverNow' => {'outcome': 'started', 'run_id': 'r9'},
    'agentGoalRuns.approveCompletion' || 'agentGoalRuns.setChecker' => {
      'goal': {
        'id': 'g1',
        'status': 'completed',
        'created_at': '2026-11-20T10:00:00Z',
        'updated_at': '2026-11-20T10:00:00Z',
      },
    },
    _ => {'ok': true},
  };

  Future<void> close() => _server.close();
}

AgentDto agent(String id, String name) => AgentDto(
  id: id,
  name: name,
  title: name,
  agentMdPath: '',
  workspaceId: ws,
  skills: const [],
  lifecycleStatus: 'active',
);

SpaceDto space(String id, String name) => SpaceDto(
  id: id,
  name: name,
  workspaceId: ws,
  provisioningStatus: 'ready',
  kind: 'topic',
);

/// The overrides every work screen needs: the active workspace, the role,
/// agents, spaces, people and the repositories over [rpc].
List<Override> workOverrides(
  WorkRpcHost rpc, {
  WorkspaceRole role = WorkspaceRole.member,
  List<AgentDto>? agents,
  List<SpaceDto> spaces = const [],
  Map<String, UserDto> users = const {},
  String userId = 'u1',
}) => [
  activeWorkspaceIdProvider.overrideWith((ref) async* {
    yield ws;
  }),
  remoteIdentityProvider.overrideWith(
    (ref) async =>
        RemoteIdentity(userId: userId, deviceId: 'd1', isServerOwner: false),
  ),
  rpcClientProvider.overrideWith((ref) => Stream.value(rpc.client)),
  workspaceRoleProvider.overrideWith((ref) => Stream.value(role)),
  agentsProvider.overrideWith(
    (ref) => Stream.value(
      agents ?? [agent('a1', 'Builder'), agent('a2', 'Reviewer')],
    ),
  ),
  spacesProvider.overrideWith((ref) => Stream.value(spaces)),
  remoteUsersProvider.overrideWith((ref) => Stream.value(users)),
  phoneGoalRunsRepositoryProvider.overrideWithValue(
    RpcAgentGoalRunRepository(rpc.client),
  ),
  phoneWakesRepositoryProvider.overrideWithValue(
    RpcConversationWakesRepository(rpc.client),
  ),
  phoneSchedulesRepositoryProvider.overrideWithValue(
    RpcWakeRuleScheduleRepository(rpc.client),
  ),
  phoneHeldSteeringRepositoryProvider.overrideWithValue(
    RpcHeldSteeringRepository(rpc.client),
  ),
];

/// Pumps [child] at `/` in a router whose record routes print where they
/// were opened, so navigation can be asserted.
Future<void> pumpWork(
  WidgetTester tester,
  Widget child, {
  required List<Override> overrides,
  TextDirection? direction,
  bool scroll = true,
}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => scroll
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              )
            : child,
      ),
      GoRoute(
        path: '/:a/:b',
        builder: (_, state) => Text('Opened ${state.uri}'),
      ),
      GoRoute(
        path: '/:a/:b/:c',
        builder: (_, state) => Text('Opened ${state.uri}'),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      // A fresh scope per pump, so a second pump in one test starts over.
      key: UniqueKey(),
      overrides: overrides,
      child: WidgetsApp.router(
        color: const Color(0xFFFFFFFF),
        locale: const Locale('en'),
        supportedLocales: kSupportedRemoteLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          PhoneWidgetsLocalizationsDelegate(),
        ],
        textStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF202020),
          decoration: TextDecoration.none,
        ),
        routerConfig: router,
        builder: (_, routed) => CcTheme(
          data: CcThemeData.light(),
          child: direction == null
              ? routed!
              : Directionality(textDirection: direction, child: routed!),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<AppLocalizations> english() async {
  await initializeDateFormatting();
  return AppLocalizations.delegate.load(const Locale('en'));
}

/// Taps the button labelled [label] (the last one, so a dialog's action
/// wins over the button that opened it).
Future<void> tapLabel(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}
