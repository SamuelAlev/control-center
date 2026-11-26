import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart'
    show agentRunLogRepositoryProvider;
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/steering_queue_list.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart'
    show ActiveWorkspaceIdNotifier, activeWorkspaceIdProvider;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const String _kWorkspaceId = 'ws-1';
const String _kSpaceId = 'space-1';
const String _kConversationId = 'conv-1';
const _kRef = (spaceId: _kSpaceId, conversationId: _kConversationId);

/// Captures the steering port calls the strip makes; everything else on the
/// port is unreachable in these tests.
class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

/// Captures the steering port calls the strip makes; everything else on the
/// port is unreachable in these tests.
class _SteeringPort implements MessagingPort {
  final edits = <(String, String)>[];
  final deletes = <String>[];
  final reorders = <List<String>>[];
  final delivers = <String>[];
  final stops = <String>[];
  bool deliverResult = true;

  /// Every call in order, for what must happen before a run is stopped.
  final calls = <String>[];

  @override
  Future<bool> editSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
    required String content,
  }) async {
    edits.add((messageId, content));
    return true;
  }

  @override
  Future<bool> deleteSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async {
    deletes.add(messageId);
    return true;
  }

  @override
  Future<void> reorderSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required List<String> orderedIds,
  }) async {
    calls.add('reorder');
    reorders.add(orderedIds);
  }

  @override
  Future<bool> deliverSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async {
    calls.add('deliver');
    delivers.add(messageId);
    if (deliverError case final error?) {
      throw error;
    }
    return deliverResult;
  }

  /// A non-null [deliverError] is thrown by `steering.deliver`.
  RemoteRpcException? deliverError;

  /// What `steering.forceSend` answers; a non-null [forceError] throws it.
  String forceOutcome = 'stopping';
  RemoteRpcException? forceError;
  final forced = <String>[];

  @override
  Future<String> forceSendSteering({
    required String workspaceId,
    required String spaceId,
    required String conversationId,
    required String messageId,
  }) async {
    calls.add('forceSend');
    forced.add(messageId);
    if (forceError case final error?) {
      throw error;
    }
    return forceOutcome;
  }

  @override
  Future<void> stopRun(String workspaceId, String runLogId) async {
    calls.add('stop');
    stops.add(runLogId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

/// Answers the one run-log query the force path makes.
class _ActiveRuns implements AgentRunLogRepository {
  _ActiveRuns(this.ids);

  final List<String> ids;

  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => [
    for (final id in ids)
      AgentRunLog(
        id: id,
        agentId: 'agent-1',
        workspaceId: workspaceId,
        conversationId: conversationId,
        startedAt: DateTime.utc(2026, 8, 29),
        status: RunStatus.running,
      ),
  ];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

Message _queued(
  String id,
  String content, {
  int order = 0,
  String sender = 'user-1',
}) => Message(
  id: id,
  spaceId: _kSpaceId,
  conversationId: _kConversationId,
  senderId: sender,
  senderType: SenderType.user,
  content: content,
  messageType: MessageType.steering,
  metadata: {'steerState': 'queued', 'steerOrder': order},
  createdAt: DateTime.utc(2026, 8, 29, 12, 0, id.hashCode % 60),
);

Widget _host(Widget child, {TextDirection? textDirection}) => MaterialApp(
  localizationsDelegates: appLocalizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: CcTheme(
      data: CcThemeData.light(),
      child: textDirection == null
          ? child
          : Directionality(textDirection: textDirection, child: child),
    ),
  ),
);

Future<ProviderContainer> _pump(
  WidgetTester tester, {
  required List<Message> windowMessages,
  _SteeringPort? port,
  List<String> activeRunIds = const [],
  TextDirection? textDirection,
}) async {
  final container = ProviderContainer(
    overrides: [
      // The viewer wrote the cards `_queued` makes by default; user-2 is a
      // member the client knows by name.
      currentUserIdProvider.overrideWithValue('user-1'),
      usersByIdProvider.overrideWith(
        (ref) => Stream.value({
          'user-2': UserDto(id: 'user-2', handle: 'grace', displayName: 'Grace'),
        }),
      ),
      activeWorkspaceIdProvider.overrideWith(
        () => _TestActiveWorkspaceNotifier(_kWorkspaceId),
      ),
      spaceFeedWindowedProvider(_kRef).overrideWith(
        (ref) => Stream.value((messages: windowMessages, hasMore: false)),
      ),
      if (port != null) messagingServiceProvider.overrideWith((ref) => port),
      agentRunLogRepositoryProvider.overrideWithValue(
        _ActiveRuns(activeRunIds),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: _host(
        const CcToastScope(
          child: SteeringQueueList(
            spaceId: _kSpaceId,
            conversationId: _kConversationId,
          ),
        ),
        textDirection: textDirection,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  test('steeringQueueProvider keeps only queued rows, in steerOrder', () async {
    final container = ProviderContainer(
      overrides: [
        spaceFeedWindowedProvider(_kRef).overrideWith(
          (ref) => Stream.value((
            messages: [
              _queued('a', 'first typed', order: 2),
              Message(
                id: 'plain',
                spaceId: _kSpaceId,
                conversationId: _kConversationId,
                senderId: 'user-1',
                senderType: SenderType.user,
                content: 'a normal message',
                messageType: MessageType.text,
                createdAt: DateTime.utc(2026, 8, 29),
              ),
              _queued('b', 'second typed', order: 1),
              Message(
                id: 'injected',
                spaceId: _kSpaceId,
                conversationId: _kConversationId,
                senderId: 'user-1',
                senderType: SenderType.user,
                content: 'already steered in',
                messageType: MessageType.steering,
                metadata: const {'steerState': 'injected', 'steerOrder': 0},
                createdAt: DateTime.utc(2026, 8, 29),
              ),
            ],
            hasMore: false,
          )),
        ),
      ],
    );
    addTearDown(container.dispose);
    // A listener, not a read: these are autoDispose providers, and a one-shot
    // read tears the chain down before the stream value lands.
    final sub = container.listen(steeringQueueProvider(_kRef), (_, _) {});
    addTearDown(sub.close);
    await container.pump();
    final queued = container.read(steeringQueueProvider(_kRef));
    expect(queued.map((m) => m.id), [
      'b',
      'a',
    ], reason: 'queued only, ascending steerOrder regardless of createdAt');
  });

  test(
    'steeringQueueProvider stays quiet while the queue is unchanged',
    () async {
      final windows =
          StreamController<({List<Message> messages, bool hasMore})>();
      final container = ProviderContainer(
        overrides: [
          spaceFeedWindowedProvider(
            _kRef,
          ).overrideWith((ref) => windows.stream),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(windows.close);
      var notified = 0;
      final sub = container.listen(
        steeringQueueProvider(_kRef),
        (_, _) => notified++,
      );
      addTearDown(sub.close);

      windows.add((messages: const <Message>[], hasMore: false));
      await settle(container);
      // Nothing queued: the shared const empty list, before and after.
      expect(notified, 0);

      windows.add((
        messages: [_queued('a', 'typed', order: 1)],
        hasMore: false,
      ));
      await settle(container);
      expect(notified, 1);

      // The window re-emits per streaming flush with fresh-but-equal rows.
      windows.add((
        messages: [_queued('a', 'typed', order: 1)],
        hasMore: false,
      ));
      await settle(container);
      expect(notified, 1);

      windows.add((
        messages: [_queued('a', 'edited', order: 1)],
        hasMore: false,
      ));
      await settle(container);
      expect(notified, 2);
      expect(
        container.read(steeringQueueProvider(_kRef)).single.content,
        'edited',
      );
    },
  );

  testWidgets('renders nothing when the queue is empty', (tester) async {
    await _pump(tester, windowMessages: const []);
    expect(find.byType(SteeringQueueList), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('the pencil opens the card for typing', (tester) async {
    await _pump(
      tester,
      windowMessages: [_queued('a', 'check the flaky test', order: 0)],
    );
    await tester.tap(find.byIcon(AppIcons.pencil));
    await tester.pumpAndSettle();
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>(),
      isNotNull,
    );
  });

  testWidgets('renders one card per queued message', (tester) async {
    await _pump(
      tester,
      windowMessages: [
        _queued('a', 'check the flaky test', order: 0),
        _queued('b', 'and the migration', order: 1),
      ],
    );
    expect(find.text('check the flaky test'), findsOneWidget);
    expect(find.text('and the migration'), findsOneWidget);
  });

  testWidgets('offers to stop the run when nothing can take the card', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      windowMessages: [_queued('a', 'nudge', order: 0)],
    );
    container.read(steeringSteerableProvider(_kRef).notifier).set(false);
    await tester.pumpAndSettle();
    expect(
      find.text('Stop and send'),
      findsOneWidget,
      reason: 'without a lane, stopping is the only way to get the card in',
    );
    expect(
      find.text('Steer'),
      findsNothing,
      reason: 'the button must say it ends the run before it does',
    );
  });

  group("someone else's card", () {
    testWidgets('no lane can take it: no forced send, and it says whose it '
        'is; delete stays', (tester) async {
      final container = await _pump(
        tester,
        windowMessages: [_queued('a', 'their nudge', sender: 'user-2')],
      );
      container.read(steeringSteerableProvider(_kRef).notifier).set(false);
      await tester.pumpAndSettle();
      expect(find.text('Stop and send'), findsNothing);
      expect(find.text('Steer'), findsNothing);
      expect(find.text('From Grace'), findsOneWidget);
      expect(find.byIcon(AppIcons.trash2), findsOneWidget);
    });

    testWidgets('a lane can take it: Steer stays and delivers it', (
      tester,
    ) async {
      final port = _SteeringPort();
      await _pump(
        tester,
        windowMessages: [_queued('a', 'their nudge', sender: 'user-9')],
        port: port,
      );
      expect(find.text('From someone else'), findsOneWidget);
      await tester.tap(find.text('Steer'));
      await tester.pump();
      await tester.pump();
      expect(port.delivers, ['a']);
      expect(port.forced, isEmpty);
    });

    testWidgets('my own card beside it keeps Stop and send', (tester) async {
      final container = await _pump(
        tester,
        windowMessages: [
          _queued('a', 'their nudge', sender: 'user-2'),
          _queued('b', 'my nudge', order: 1),
        ],
      );
      container.read(steeringSteerableProvider(_kRef).notifier).set(false);
      await tester.pumpAndSettle();
      expect(find.text('Stop and send'), findsOneWidget);
      expect(find.text('From Grace'), findsOneWidget);
    });

    testWidgets('right to left: the writer mark sits on the start side of '
        'the actions, after the text', (tester) async {
      await _pump(
        tester,
        windowMessages: [_queued('a', 'their nudge', sender: 'user-2')],
        textDirection: TextDirection.rtl,
      );
      final text = tester.getCenter(find.text('their nudge'));
      final mark = tester.getCenter(find.text('From Grace'));
      final steer = tester.getCenter(find.text('Steer'));
      expect(mark.dx, lessThan(text.dx));
      expect(steer.dx, lessThan(mark.dx));
    });
  });

  group('getting a card in', () {
    Future<_SteeringPort> pressOn(
      WidgetTester tester, {
      required bool? steerable,
      required bool deliverResult,
      List<String> activeRunIds = const ['run-1', 'run-2'],
    }) async {
      final port = _SteeringPort()..deliverResult = deliverResult;
      final container = await _pump(
        tester,
        windowMessages: [
          _queued('a', 'first', order: 0),
          _queued('b', 'second', order: 1),
        ],
        port: port,
        activeRunIds: activeRunIds,
      );
      if (steerable != null) {
        container
            .read(steeringSteerableProvider(_kRef).notifier)
            .set(steerable);
        await tester.pumpAndSettle();
      }
      await tester.tap(
        find.text(steerable == false ? 'Stop and send' : 'Steer').last,
      );
      await tester.pump();
      await tester.pump();
      return port;
    }

    /// Lets a toast time out so no timer outlives the test.
    Future<void> drainToast(WidgetTester tester) async {
      await tester.pump(const Duration(seconds: 6));
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('Stop and send is one server call, never a client stop', (
      tester,
    ) async {
      final port = await pressOn(tester, steerable: false, deliverResult: true);
      expect(port.forced, ['b']);
      expect(port.calls, ['forceSend'], reason: 'the server orders the steps');
      expect(port.stops, isEmpty);
    });

    testWidgets('a card no longer queued says so', (tester) async {
      final port = _SteeringPort()..forceOutcome = 'not_queued';
      final container = await _pump(
        tester,
        windowMessages: [_queued('a', 'first', order: 0)],
        port: port,
      );
      container.read(steeringSteerableProvider(_kRef).notifier).set(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop and send').last);
      await tester.pump();
      await tester.pump();
      expect(
        find.text(
          'No running agent can take that right now — it stays queued.',
        ),
        findsOneWidget,
      );
      await drainToast(tester);
    });

    testWidgets('a refused stop is shown, not swallowed', (tester) async {
      final port = _SteeringPort()
        ..forceError = RemoteRpcException(
          -32001,
          'your role may not stop runs',
        );
      final container = await _pump(
        tester,
        windowMessages: [_queued('a', 'first', order: 0)],
        port: port,
      );
      container.read(steeringSteerableProvider(_kRef).notifier).set(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop and send').last);
      await tester.pump();
      await tester.pump();
      expect(
        find.text("Couldn't send that now: your role may not stop runs"),
        findsOneWidget,
      );
      await drainToast(tester);
    });

    testWidgets('a steering_not_yours refusal reads by its kind, never the '
        "server's sentence", (tester) async {
      final port = _SteeringPort()
        ..forceError = RemoteRpcException(-33004, 'server words: not yours', {
          'kind': 'steering_not_yours',
          'others_held': 1,
        });
      final container = await _pump(
        tester,
        windowMessages: [_queued('a', 'first', order: 0)],
        port: port,
      );
      container.read(steeringSteerableProvider(_kRef).notifier).set(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop and send').last);
      await tester.pump();
      await tester.pump();
      expect(
        find.text(
          'No running agent can take that right now — it stays queued.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('server words'), findsNothing);
      await drainToast(tester);
    });

    testWidgets('a refused Steer stops nothing, then offers to', (
      tester,
    ) async {
      final port = await pressOn(tester, steerable: null, deliverResult: false);
      expect(
        port.stops,
        isEmpty,
        reason: 'the button said Steer, so it must not end a run',
      );
      await tester.pump();
      expect(find.text('Stop and send'), findsNWidgets(2));
      await drainToast(tester);
    });
  });

  testWidgets('shows the steer button while steerability is unknown', (
    tester,
  ) async {
    await _pump(tester, windowMessages: [_queued('a', 'nudge', order: 0)]);
    expect(
      find.text('Steer'),
      findsOneWidget,
      reason:
          'a card can outlive the client that typed it (reload, second '
          'device); unknown is not the same as "cannot"',
    );
  });

  testWidgets('shows the steer button once an enqueue stamps steerable', (
    tester,
  ) async {
    final container = await _pump(
      tester,
      windowMessages: [_queued('a', 'nudge', order: 0)],
    );
    container.read(steeringSteerableProvider(_kRef).notifier).set(true);
    await tester.pumpAndSettle();
    expect(find.text('Steer'), findsOneWidget);
  });

  testWidgets('cards carry no bottom border, so the strip melts down', (
    tester,
  ) async {
    await _pump(
      tester,
      windowMessages: [
        _queued('a', 'first', order: 0),
        _queued('b', 'second', order: 1),
      ],
    );
    final borders = [
      for (final text in ['first', 'second'])
        ...tester
            .widgetList<Container>(
              find.ancestor(
                of: find.text(text),
                matching: find.byType(Container),
              ),
            )
            .map((c) => c.decoration)
            .whereType<BoxDecoration>()
            .map((d) => d.border)
            .whereType<Border>(),
    ];
    expect(borders, hasLength(2), reason: 'one outlined box per queued card');
    for (final border in borders) {
      expect(
        border.bottom,
        BorderSide.none,
        reason:
            'the next card\'s top border separates two cards, and the '
            "composer's own top border closes the last one — a bottom "
            'border here would double every hairline',
      );
      expect(border.top, isNot(BorderSide.none));
    }
  });

  testWidgets('delete calls the port for that card', (tester) async {
    final port = _SteeringPort();
    await _pump(
      tester,
      windowMessages: [_queued('a', 'gone soon', order: 0)],
      port: port,
    );
    await tester.tap(find.byIcon(AppIcons.trash2));
    await tester.pumpAndSettle();
    expect(port.deletes, ['a']);
  });

  testWidgets("edit is offered only on the viewer's own cards", (tester) async {
    await _pump(
      tester,
      windowMessages: [
        _queued('a', 'my nudge', order: 0),
        _queued('b', 'their nudge', order: 1, sender: 'user-2'),
      ],
    );
    expect(find.byIcon(AppIcons.pencil), findsOneWidget);
    expect(find.byIcon(AppIcons.trash2), findsNWidgets(2));
    final pencil = tester.getCenter(find.byIcon(AppIcons.pencil));
    final mine = tester.getCenter(find.text('my nudge'));
    final theirs = tester.getCenter(find.text('their nudge'));
    expect(
      (pencil.dy - mine.dy).abs(),
      lessThan((pencil.dy - theirs.dy).abs()),
      reason: "the pencil sits on the viewer's own card",
    );
  });

  group('a run acting for someone else needs the write grant', () {
    RemoteRpcException noWrite() => RemoteRpcException(
      -33002,
      'server words: write needed',
      {'kind': 'repo_grant_required', 'level': 'write'},
    );
    const wording =
        'You can read this repository but not change it. A workspace admin '
        'can grant write access.';

    testWidgets('Steer: worded as the forge refusals are; the card stays', (
      tester,
    ) async {
      final port = _SteeringPort()..deliverError = noWrite();
      await _pump(
        tester,
        windowMessages: [_queued('a', 'nudge', order: 0)],
        port: port,
      );
      await tester.tap(find.text('Steer'));
      await tester.pump();
      await tester.pump();
      expect(find.text(wording), findsOneWidget);
      expect(find.textContaining('server words'), findsNothing);
      expect(find.text('nudge'), findsOneWidget);
      await tester.pump(const Duration(seconds: 7));
    });

    testWidgets('Stop and send: worded the same way', (tester) async {
      final port = _SteeringPort()..forceError = noWrite();
      final container = await _pump(
        tester,
        windowMessages: [_queued('a', 'nudge', order: 0)],
        port: port,
      );
      container.read(steeringSteerableProvider(_kRef).notifier).set(false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Stop and send'));
      await tester.pump();
      await tester.pump();
      expect(find.text(wording), findsOneWidget);
      expect(find.textContaining('server words'), findsNothing);
      await tester.pump(const Duration(seconds: 7));
    });
  });

  testWidgets('edit rewrites the card through the port', (tester) async {
    final port = _SteeringPort();
    await _pump(
      tester,
      windowMessages: [_queued('a', 'old text', order: 0)],
      port: port,
    );
    await tester.tap(find.byIcon(AppIcons.pencil));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CcTextField), 'new text');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(port.edits, [('a', 'new text')]);
  });

  testWidgets('a card with attachments reads by name, never as raw tokens', (
    tester,
  ) async {
    Message withShot(String id, String content) => Message(
      id: id,
      spaceId: _kSpaceId,
      conversationId: _kConversationId,
      senderId: 'user-1',
      senderType: SenderType.user,
      content: content,
      messageType: MessageType.steering,
      metadata: const {
        'steerState': 'queued',
        'steerOrder': 0,
        'attachments': [
          {
            'id': 'a1',
            'path': 'blob:sha256:x',
            'name': 'shot.png',
            'kind': 'image',
          },
        ],
      },
      createdAt: DateTime.utc(2026, 8, 29),
    );

    await _pump(
      tester,
      windowMessages: [
        withShot('a', 'too big: @[file:shot.png]'),
        withShot('b', ''),
      ],
    );

    expect(find.text('too big: shot.png'), findsOneWidget);
    expect(find.text('shot.png'), findsOneWidget);
    expect(find.textContaining('@[file:'), findsNothing);
    expect(find.byIcon(AppIcons.image), findsNWidgets(2));
  });
}

/// Lets a stream event reach its provider, then flushes the container: one
/// `pump` alone can run before the event is delivered, which would make a
/// "nothing notified" assertion pass for the wrong reason.
Future<void> settle(ProviderContainer container) async {
  await Future<void>.delayed(Duration.zero);
  await container.pump();
}
