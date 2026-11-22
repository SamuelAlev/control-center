@TestOn('browser')
library;

import 'package:cc_domain/cc_domain.dart' show MessageDto, UserDto;
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/messaging/conversation_controls.dart';
import 'package:cc_remote/widgets/messaging/held_steering.dart';
import 'package:cc_remote/widgets/work/work_text.dart' show workTime;
import 'package:flutter/widgets.dart' show TextDirection;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

MessageDto _steer(
  String id,
  String state,
  String content,
  int order, {
  String? heldBy = 'stop',
  String? resetsAt,
  String senderId = 'u1',
}) => MessageDto(
  id: id,
  content: content,
  senderId: senderId,
  senderType: 'user',
  messageType: 'steering',
  metadata: {
    'steerState': state,
    'steerOrder': order,
    if (state == 'held' && heldBy != null) 'steerHeldBy': heldBy,
    'steerLimitResetsAt': ?resetsAt,
  },
  spaceId: 's1',
  conversationId: 'c1',
);

void main() {
  late AppLocalizations l;
  WorkRpcHost? host;
  // Made inside each test's zone, so its streams run on the test's clock.
  WorkRpcHost rpc() => host ??= WorkRpcHost();

  setUpAll(() async => l = await english());
  setUp(() => host = null);
  tearDown(() => host?.close());

  test('only held steering counts as held', () {
    expect(isHeldSteering(_steer('m1', 'held', 'x', 0)), isTrue);
    expect(isHeldSteering(_steer('m1', 'queued', 'x', 0)), isFalse);
  });

  Future<void> pump(WidgetTester tester, List<MessageDto> messages) => pumpWork(
    tester,
    HeldSteering(
      scope: (workspaceId: ws, spaceId: 's1', conversationId: 'c1'),
      messages: messages,
      canWrite: true,
    ),
    overrides: workOverrides(
      rpc(),
      users: {'u2': UserDto(id: 'u2', handle: 'ada', displayName: 'Ada')},
    ),
  );

  testWidgets('held messages show in order with Send held messages', (
    tester,
  ) async {
    await pump(tester, [
      _steer('m2', 'held', 'Then run the tests', 2),
      _steer('m1', 'held', 'First fix **the** build', 1),
    ]);
    expect(find.text(l.heldSteeringTitle), findsOneWidget);
    final first = tester.getTopLeft(find.text('First fix **the** build'));
    final second = tester.getTopLeft(find.text('Then run the tests'));
    expect(first.dy, lessThan(second.dy));

    await tapLabel(tester, l.heldSteeringRelease);
    expect(rpc().ops, ['steering.release']);
    expect(rpc().sent.single.args, {
      'workspace_id': ws,
      'space_id': 's1',
      'conversation_id': 'c1',
      'held_by': 'stop',
    });
  });

  testWidgets('a usage-limit pause holds its own cards: when they go out, '
      'no send; Send held messages covers only the Stop cards', (tester) async {
    final resets = DateTime.utc(2026, 11, 20, 14, 30);
    await pump(tester, [
      _steer('m1', 'held', 'Stopped card', 1),
      _steer(
        'm2',
        'held',
        'Paused card',
        2,
        heldBy: 'limit:run-1',
        resetsAt: resets.toIso8601String(),
      ),
    ]);
    expect(find.text(l.heldSteeringTitle), findsOneWidget);
    expect(find.textContaining(l.heldSteeringLimitTitle), findsNothing);
    final at = find.textContaining('Held until the usage limit resets at');
    expect(at, findsOneWidget);
    expect(find.text('Paused card'), findsOneWidget);
    // One send, under the Stop cards.
    expect(find.text(l.heldSteeringRelease), findsOneWidget);
    expect(
      tester.getTopLeft(find.text(l.heldSteeringRelease)).dy,
      lessThan(tester.getTopLeft(at).dy),
    );
    await tapLabel(tester, l.heldSteeringRelease);
    expect(rpc().sent.single.args['held_by'], 'stop');
  });

  testWidgets('only a pause\'s cards: no send, and the reset unknown reads '
      'without a time; a card with no holder can only be removed', (
    tester,
  ) async {
    await pump(tester, [
      _steer('m1', 'held', 'Paused card', 1, heldBy: 'limit:run-1'),
      _steer('m2', 'held', 'Unmarked card', 2, heldBy: null),
    ]);
    expect(find.text(l.heldSteeringLimitTitle), findsOneWidget);
    expect(find.text(l.heldSteeringOtherTitle), findsOneWidget);
    expect(find.text(l.heldSteeringTitle), findsNothing);
    expect(find.text(l.heldSteeringRelease), findsNothing);
    expect(find.text(l.mobileRemove), findsNWidgets(2));
  });

  testWidgets('two pauses are two groups, each with its own reset', (
    tester,
  ) async {
    final early = DateTime.utc(2026, 11, 20, 14, 30);
    final late = DateTime.utc(2026, 11, 20, 18, 45);
    await pump(tester, [
      _steer(
        'm1',
        'held',
        'For the first run',
        1,
        heldBy: 'limit:run-1',
        resetsAt: early.toIso8601String(),
      ),
      _steer(
        'm2',
        'held',
        'For the second run',
        2,
        heldBy: 'limit:run-2',
        resetsAt: late.toIso8601String(),
      ),
      _steer(
        'm3',
        'held',
        'First run again',
        3,
        heldBy: 'limit:run-1',
        resetsAt: early.toIso8601String(),
      ),
    ]);
    final context = tester.element(find.byType(HeldSteering));
    final first = find.text(l.heldSteeringLimitAt(workTime(context, early)));
    final second = find.text(l.heldSteeringLimitAt(workTime(context, late)));
    expect(first, findsOneWidget);
    expect(second, findsOneWidget);
    // Each pause's cards sit under its own heading.
    final firstTop = tester.getTopLeft(first).dy;
    final secondTop = tester.getTopLeft(second).dy;
    expect(firstTop, lessThan(secondTop));
    expect(
      tester.getTopLeft(find.text('First run again')).dy,
      lessThan(secondTop),
    );
    expect(
      tester.getTopLeft(find.text('For the second run')).dy,
      greaterThan(secondTop),
    );
    expect(find.text(l.heldSteeringRelease), findsNothing);
  });

  testWidgets('the three holders lay out in RTL', (tester) async {
    await pumpWork(
      tester,
      HeldSteering(
        scope: (workspaceId: ws, spaceId: 's1', conversationId: 'c1'),
        messages: [
          _steer('m1', 'held', 'Stopped card', 1),
          _steer('m2', 'held', 'Paused card', 2, heldBy: 'limit:run-1'),
          _steer('m3', 'held', 'Unmarked card', 3, heldBy: null),
        ],
        canWrite: true,
      ),
      overrides: workOverrides(rpc()),
      direction: TextDirection.rtl,
    );
    expect(find.text(l.heldSteeringTitle), findsOneWidget);
    expect(find.text(l.heldSteeringLimitTitle), findsOneWidget);
    expect(find.text(l.heldSteeringOtherTitle), findsOneWidget);
    expect(find.text(l.heldSteeringRelease), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('only the writer sends: others\' cards say whose they are, and '
      'Send held messages covers only the viewer\'s own', (tester) async {
    await pump(tester, [
      _steer('m1', 'held', 'Mine', 1),
      _steer('m2', 'held', 'Ada wrote this', 2, senderId: 'u2'),
      _steer('m3', 'held', 'Unknown wrote this', 3, senderId: 'u9'),
    ]);
    expect(find.text(l.heldSteeringTitle), findsOneWidget);
    expect(find.text(l.heldSteeringWrittenBy('Ada')), findsOneWidget);
    expect(find.text(l.heldSteeringWrittenBy(l.teammate)), findsOneWidget);
    expect(find.text(l.heldSteeringOnlyYours), findsOneWidget);
    // Everyone may remove any card.
    expect(find.text(l.mobileRemove), findsNWidgets(3));
    await tapLabel(tester, l.heldSteeringRelease);
    expect(rpc().sent.single.args['held_by'], 'stop');
  });

  testWidgets('with only others\' cards there is no send, and the rest stays '
      'once the viewer\'s own went out', (tester) async {
    await pump(tester, [
      _steer('m2', 'held', 'Ada wrote this', 2, senderId: 'u2'),
      _steer('m3', 'held', 'Ada again', 3, senderId: 'u2', heldBy: 'limit:r1'),
    ]);
    expect(find.text(l.heldSteeringOthersTitle), findsOneWidget);
    expect(find.text(l.heldSteeringTitle), findsNothing);
    expect(find.text(l.heldSteeringRelease), findsNothing);
    expect(find.text(l.heldSteeringOnlyYours), findsNothing);
    expect(find.text(l.heldSteeringWrittenBy('Ada')), findsNWidgets(2));
    expect(find.text(l.mobileRemove), findsNWidgets(2));
  });

  testWidgets('a release refused as not yours has words', (tester) async {
    rpc().refuse = 'steering_not_yours';
    await pump(tester, [_steer('m1', 'held', 'Mine', 1)]);
    await tapLabel(tester, l.heldSteeringRelease);
    expect(find.text(l.steeringRefusalNotYours), findsOneWidget);
  });

  testWidgets('a release refused for a pause has words', (tester) async {
    rpc().refuse = 'steering_held_by_limit';
    await pump(tester, [_steer('m1', 'held', 'Stopped card', 1)]);
    await tapLabel(tester, l.heldSteeringRelease);
    expect(find.text(l.steeringRefusalHeldByLimit), findsOneWidget);
  });

  testWidgets('each held message can be removed', (tester) async {
    await pump(tester, [_steer('m1', 'held', 'Only this', 1)]);
    await tapLabel(tester, l.mobileRemove);
    expect(rpc().ops, ['steering.delete']);
    expect(rpc().sent.single.args['message_id'], 'm1');
  });

  testWidgets('with no live run, held steering still shows under the '
      'conversation controls, apart from the queue', (tester) async {
    await pumpWork(
      tester,
      ConversationControls(
        scope: (workspaceId: ws, spaceId: 's1', conversationId: 'c1'),
        runs: const AsyncData([]),
        queued: [
          _steer('m1', 'held', 'Held one', 1),
          _steer('m2', 'queued', 'Queued one', 2),
        ],
        canWrite: true,
      ),
      overrides: workOverrides(rpc()),
    );
    expect(find.text(l.mobileHeldMessages), findsOneWidget);
    expect(find.text('Held one'), findsOneWidget);
    expect(find.text('Queued one'), findsNothing);
    await tapLabel(tester, l.mobileHeldMessages);
    expect(find.text('Queued one'), findsOneWidget);
    expect(find.text('Held one'), findsOneWidget);
  });

  testWidgets('nothing held renders nothing', (tester) async {
    await pump(tester, const []);
    expect(find.text(l.heldSteeringTitle), findsNothing);
  });
}
