import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/wake_context.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:cc_domain/features/dispatch/domain/services/wake_admission.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_values.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcException;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/conversation_wake_strip.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/wake_card.dart';
import 'package:control_center/features/messaging/providers/conversation_work_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/active_workspace.dart';
import '../../../../../helpers/test_wrap.dart';
import 'work_test_harness.dart';

Message _held(
  String id,
  String text, {
  String? by,
  String? resetsAt,
  String sender = 'u-1',
}) => Message(
  id: id,
  spaceId: 'sp-1',
  conversationId: 'conv-1',
  senderId: sender,
  senderType: SenderType.user,
  content: text,
  messageType: MessageType.steering,
  metadata: {
    'steerState': 'held',
    'steerHeldBy': ?by,
    'steerLimitResetsAt': ?resetsAt,
  },
  createdAt: DateTime(2026, 11, 19),
);

void main() {
  late FakeWakesRepository wakes;
  late FakeHeldSteeringRepository held;

  setUp(() {
    wakes = FakeWakesRepository();
    held = FakeHeldSteeringRepository();
  });

  Future<void> pump(
    WidgetTester tester, {
    List<WakeView> wakeList = const [],
    List<Message> heldCards = const [],
    TextDirection? textDirection,
  }) async {
    // A fresh scope per pump: overrides never carry over.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      testWrap(
        ProviderScope(
          overrides: [
            ...workOverrides(wakes: wakes, held: held, wakeList: wakeList),
            heldSteeringProvider.overrideWith((ref, key) => heldCards),
          ],
          child: const SingleChildScrollView(
            child: ConversationWakeStrip(
              spaceId: 'sp-1',
              conversationId: 'conv-1',
            ),
          ),
        ),
        textDirection: textDirection,
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('renders nothing when nothing waits', (tester) async {
    await pump(tester);
    expect(find.byType(WakeCard), findsNothing);
    expect(find.textContaining('waiting'), findsNothing);
  });

  testWidgets('a pending wake: origin chip, headline, due time, deliver now '
      'and cancel', (tester) async {
    await pump(tester, wakeList: [wakeView()]);
    expect(find.text('1 wake waiting'), findsOneWidget);
    expect(find.text('Goal'), findsOneWidget);
    expect(find.text('your goal continues, segment 3'), findsOneWidget);
    expect(find.textContaining('Due '), findsOneWidget);
    expect(tip('Deliver now'), findsOneWidget);
    expect(tip('Cancel wake'), findsOneWidget);
    expect(tip('Resume'), findsNothing);
  });

  testWidgets('origin chips name the agent a reply or message came from', (
    tester,
  ) async {
    await pump(
      tester,
      wakeList: [
        wakeView(
          id: 'a',
          reason: WakeReason.peerReply,
          sourceAgentId: 'agent-2',
        ),
        wakeView(
          id: 'b',
          reason: WakeReason.peerMessage,
          sourceAgentId: 'agent-3',
        ),
        wakeView(id: 'c', reason: WakeReason.schedule),
        wakeView(id: 'd', reason: WakeReason.watch),
        wakeView(id: 'e', reason: WakeReason.limitReset),
        wakeView(id: 'f', reason: WakeReason.peerReply, sourceAgentId: 'gone'),
      ],
    );
    expect(find.text('Reply from Ada'), findsOneWidget);
    expect(find.text('Message from Ben'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Watch'), findsOneWidget);
    expect(find.text('Limit reset'), findsOneWidget);
    expect(find.text('Reply'), findsOneWidget);
  });

  testWidgets('a wake already due says so; an expiring one says when, and a '
      'retried one its attempt', (tester) async {
    await pump(
      tester,
      wakeList: [wakeView(notBefore: past, expiresAt: future, attempt: 1)],
    );
    expect(find.text('Due now'), findsOneWidget);
    expect(find.textContaining('Expires '), findsOneWidget);
    expect(find.text('Attempt 2'), findsOneWidget);
  });

  testWidgets('a held wake shows Held and why, and Resume only when the '
      'server says this viewer may', (tester) async {
    await pump(
      tester,
      wakeList: [
        wakeView(
          id: 'mine',
          state: WakeState.held,
          stateReason: 'stopped',
          headline: 'mine',
        ),
        wakeView(
          id: 'theirs',
          state: WakeState.held,
          stateReason: 'limit',
          canRelease: false,
          headline: 'theirs',
        ),
      ],
    );
    expect(find.text('Held'), findsNWidgets(2));
    expect(find.text('Held because a person stopped the run.'), findsOneWidget);
    expect(find.text("Waiting at the provider's usage limit."), findsOneWidget);
    expect(tip('Resume'), findsOneWidget);
    expect(tip('Deliver now'), findsNothing);
    expect(tip('Cancel wake'), findsNWidgets(2));
    // Only one releasable: no Resume all.
    expect(find.text('Resume all'), findsNothing);
  });

  testWidgets('an unknown hold kind shows the generic lead-in and the kind', (
    tester,
  ) async {
    await pump(
      tester,
      wakeList: [wakeView(state: WakeState.held, stateReason: 'brand_new')],
    );
    expect(
      find.text("For a reason this version doesn't name:"),
      findsOneWidget,
    );
    expect(find.text('brand_new'), findsOneWidget);
  });

  testWidgets('a recovery wake offers Resume and Dismiss', (tester) async {
    await pump(
      tester,
      wakeList: [
        wakeView(
          reason: WakeReason.recovery,
          state: WakeState.held,
          stateReason: 'server_restarted',
        ),
      ],
    );
    expect(find.text('Recovery'), findsOneWidget);
    expect(tip('Resume'), findsOneWidget);
    expect(tip('Dismiss'), findsOneWidget);
    await tester.tap(tip('Dismiss'));
    await tester.pump();
    expect(wakes.calls, ['cancel:$kTestWorkspaceId:wk-1']);
  });

  testWidgets('actions send their ops with the wake id', (tester) async {
    await pump(
      tester,
      wakeList: [
        wakeView(id: 'p'),
        wakeView(id: 'h1', state: WakeState.held, stateReason: 'stopped'),
        wakeView(id: 'h2', state: WakeState.held, stateReason: 'stopped'),
      ],
    );
    await tester.tap(tip('Deliver now'));
    await tester.pump();
    expect(find.text('Started a run.'), findsOneWidget);
    await tester.tap(tip('Resume').first);
    await tester.pump();
    await tester.tap(tip('Cancel wake').first);
    await tester.pump();
    await tester.tap(find.text('Resume all'));
    await tester.pump();
    expect(wakes.calls, [
      'deliverNow:$kTestWorkspaceId:p',
      'release:$kTestWorkspaceId:h1',
      'cancel:$kTestWorkspaceId:p',
      'release:$kTestWorkspaceId:conv=conv-1',
    ]);
  });

  testWidgets('every deliver-now receipt reads as one sentence', (
    tester,
  ) async {
    final AppLocalizations t = AppLocalizationsEn();
    expect(
      wakeReceiptSentence(t, const WakePushed('r')),
      'Handed to the live run.',
    );
    expect(
      wakeReceiptSentence(t, const WakeWaiting('agent_paused')),
      'Still waiting. The agent is paused.',
    );
    expect(
      wakeReceiptSentence(t, const WakeSkipped('budget_blocked')),
      'Not delivered. A budget blocks a run.',
    );
    expect(wakeReceiptSentence(t, const WakeDuplicate()), 'Already delivered.');
  });

  testWidgets('refusals read by kind: not yours, settled', (tester) async {
    await pump(tester, wakeList: [wakeView(id: 'p')]);
    wakes.error = refusal('wake_not_yours');
    await tester.tap(tip('Deliver now'));
    await tester.pump();
    expect(
      find.text(
        'This wake acts for another person. Only they can deliver or resume it.',
      ),
      findsOneWidget,
    );
    wakes
      ..error = null
      ..cancelResult = false;
    await tester.tap(tip('Cancel wake'));
    await tester.pump();
    expect(find.text('This wake has already settled.'), findsOneWidget);
  });

  testWidgets('wake text with markdown and a control sequence stays inert', (
    tester,
  ) async {
    await pump(
      tester,
      wakeList: [
        wakeView(
          headline: '**bold** [link](https://x.test) \u001b[31mred\u202Eevil',
        ),
      ],
    );
    expect(
      find.text('**bold** [link](https://x.test) \uFFFD[31mred\uFFFDevil'),
      findsOneWidget,
    );
    expect(find.byType(CcLinkText), findsNothing);
  });

  testWidgets('held steering: Send held messages and delete', (tester) async {
    await pump(
      tester,
      heldCards: [
        _held('m1', 'try the other branch'),
        _held('m2', 'and log it'),
      ],
    );
    expect(find.text('2 held messages'), findsOneWidget);
    // All mine: no note that only writers send, no author marks.
    expect(
      find.text('Only the person who wrote a held message can send it.'),
      findsNothing,
    );
    expect(find.text('try the other branch'), findsOneWidget);
    await tester.tap(find.text('Send held messages'));
    await tester.pump();
    expect(held.calls, ['release:$kTestWorkspaceId:sp-1:conv-1']);
    expect(find.text('Sent 2 held messages.'), findsOneWidget);
    expect(tip('Delete held message'), findsNWidgets(2));
  });

  testWidgets('held by a Stop and by a usage-limit pause: Send releases the '
      "Stop's cards even while the pause waits; the pause's cards say when "
      'they go out and offer no send', (tester) async {
    await pump(
      tester,
      wakeList: [
        wakeView(
          id: 'park',
          reason: WakeReason.limitReset,
          state: WakeState.held,
          stateReason: 'limit',
        ),
      ],
      heldCards: [
        _held('m1', 'stopped card', by: 'stop'),
        _held(
          'm2',
          'limit card',
          by: 'limit:run-9',
          resetsAt: future.toUtc().toIso8601String(),
        ),
      ],
    );
    expect(find.text('1 held message'), findsOneWidget);
    expect(find.text('1 message held at the usage limit'), findsOneWidget);
    expect(find.textContaining('The limit resets at '), findsOneWidget);
    expect(find.text('Send held messages'), findsOneWidget);
    expect(tip('Delete held message'), findsNWidgets(2));
    await tester.tap(find.text('Send held messages'));
    await tester.pump();
    expect(held.calls, ['release:$kTestWorkspaceId:sp-1:conv-1']);
  });

  testWidgets('only a pause holds cards: no send, even for their writer; '
      'without a reset it says whose resume sends them', (
    tester,
  ) async {
    await pump(
      tester,
      heldCards: [_held('m2', 'limit card', by: 'limit:run-9')],
    );
    expect(find.text('Send held messages'), findsNothing);
    expect(
      find.text(
        'These are sent when the person the run works for resumes it. If it '
        'is not resumed within 7 days of the reset, they are held for that '
        'person.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('resets at'), findsNothing);
  });

  testWidgets('steering_held_by_limit reads as a sentence with the reset', (
    tester,
  ) async {
    held.error = RemoteRpcException(-32002, 'held by a limit', {
      'kind': 'steering_held_by_limit',
      'resets_at': future.toUtc().toIso8601String(),
    });
    await pump(tester, heldCards: [_held('m1', 'stopped card')]);
    await tester.tap(find.text('Send held messages'));
    await tester.pump();
    expect(
      find.textContaining(
        "Messages a usage-limit pause holds can't be sent by hand while it "
        'waits. The limit resets at ',
      ),
      findsOneWidget,
    );
  });

  testWidgets("someone else's held cards: marked with their writer, no send "
      'for a viewer with none of their own; delete stays', (tester) async {
    await pump(
      tester,
      heldCards: [
        _held('m1', 'their card', sender: 'u-2'),
        _held('m2', 'a stranger card', sender: 'u-9'),
      ],
    );
    expect(find.text('2 held messages'), findsOneWidget);
    expect(find.text('From Grace'), findsOneWidget);
    expect(find.text('From someone else'), findsOneWidget);
    expect(
      find.text('Only the person who wrote a held message can send it.'),
      findsOneWidget,
    );
    expect(find.text('Send held messages'), findsNothing);
    expect(tip('Delete held message'), findsNWidgets(2));
  });

  testWidgets('mine and theirs: Send is offered and sends mine; once mine '
      'are out, theirs stay without a send', (tester) async {
    await pump(
      tester,
      heldCards: [
        _held('m1', 'my card'),
        _held('m2', 'their card', sender: 'u-2'),
      ],
    );
    expect(find.text('From Grace'), findsOneWidget);
    await tester.tap(find.text('Send held messages'));
    await tester.pump();
    expect(held.calls, ['release:$kTestWorkspaceId:sp-1:conv-1']);

    // The feed drops the sent card; the kept one stays held.
    await pump(tester, heldCards: [_held('m2', 'their card', sender: 'u-2')]);
    expect(find.text('1 held message'), findsOneWidget);
    expect(find.text('Send held messages'), findsNothing);
  });

  testWidgets('steering_not_yours reads as its sentence', (tester) async {
    held.error = RemoteRpcException(-33004, 'not yours', {
      'kind': 'steering_not_yours',
      'others_held': 2,
    });
    await pump(tester, heldCards: [_held('m1', 'my card')]);
    await tester.tap(find.text('Send held messages'));
    await tester.pump();
    expect(
      find.text(
        "These held messages are someone else's. Only the person who wrote "
        'one can send it.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('right to left: held groups keep their order and the Send '
      'button sits at the start edge of the header end', (tester) async {
    await pump(
      tester,
      heldCards: [_held('m1', 'try the other branch')],
      textDirection: TextDirection.rtl,
    );
    final header = tester.getCenter(find.text('1 held message'));
    final send = tester.getCenter(find.text('Send held messages'));
    expect(send.dx, lessThan(header.dx));
  });

  testWidgets('right to left: the chip leads from the right edge', (
    tester,
  ) async {
    await pump(
      tester,
      wakeList: [wakeView()],
      textDirection: TextDirection.rtl,
    );
    final chip = tester.getCenter(find.text('Goal'));
    final headline = tester.getCenter(
      find.text('your goal continues, segment 3'),
    );
    expect(chip.dx, greaterThan(headline.dx));
    expect(find.byIcon(AppIcons.target), findsOneWidget);
  });
}
