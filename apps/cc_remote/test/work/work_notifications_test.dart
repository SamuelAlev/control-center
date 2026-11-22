@TestOn('browser')
library;

import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/app_router.dart' show safeRemoteReturn;
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/activity/activity_item_card.dart';
import 'package:cc_remote/widgets/activity/activity_presentation.dart';
import 'package:cc_remote/widgets/activity/work_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

import 'work_test_host.dart';

var _seq = 0;

NotificationFeedItem _item(String method, Map<String, dynamic> params) =>
    NotificationFeedItem(
      id: 'n${++_seq}',
      workspaceId: ws,
      method: 'notifications/$method',
      params: {'workspace_id': ws, ...params},
      createdAt: DateTime.utc(2026, 11, 20, 9),
      seq: _seq,
    );

void main() {
  late AppLocalizations l;
  WorkRpcHost? host;
  // Made inside each test's zone, so its streams run on the test's clock.
  WorkRpcHost rpc() => host ??= WorkRpcHost();

  setUpAll(() async => l = await english());
  setUp(() => host = null);
  tearDown(() => host?.close());

  group('goal_settled', () {
    test('titles per status and hold; opens the goal', () {
      final done = _item('goal_settled', {
        'goal_id': 'g1',
        'space_id': 's1',
        'conversation_id': 'c1',
        'status': 'completed',
        'notification_kind': 'notify',
      });
      expect(activityTitle(done, l), l.notifGoalCompleted);
      expect(workNotificationKind(done), WorkNotificationKind.notify);
      expect(activityDestination(done, const []), '/goals/g1?workspace_id=$ws');
      for (final (status, title) in [
        ('failed', l.notifGoalFailed),
        ('cancelled', l.notifGoalCancelled),
        ('budget_exhausted', l.notifGoalBudgetExhausted),
        ('paused', l.notifGoalOnHold),
      ]) {
        expect(
          activityTitle(_item('goal_settled', {'status': status}), l),
          title,
        );
      }
      final review = _item('goal_settled', {
        'goal_id': 'g1',
        'status': 'paused',
        'hold': 'needs_review',
        'notification_kind': 'review',
      });
      expect(activityTitle(review, l), l.notifGoalNeedsReview);
      expect(workNotificationKind(review), WorkNotificationKind.review);
      expect(
        activityTitle(
          _item('goal_settled', {'status': 'paused', 'hold': 'person'}),
          l,
        ),
        l.notifGoalNeedsPerson,
      );
    });
  });

  test('wake_rule_ended: quiet by its field, opens the schedule', () {
    final ended = _item('wake_rule_ended', {
      'rule_id': 'r1',
      'space_id': 's1',
      'reason': 'expired',
      'notification_kind': 'notify',
      'quiet': true,
    });
    expect(activityTitle(ended, l), l.notifWakeRuleEnded);
    expect(workNotificationKind(ended), WorkNotificationKind.notify);
    expect(isQuietNotification(ended), isTrue);
    expect(
      activityDestination(ended, const []),
      '/schedules/r1?workspace_id=$ws',
    );
  });

  test('quietness is only the quiet field, never the kind or the method', () {
    // A frame with no kind has none: nothing is inferred from its method.
    final bare = _item('goal_settled', {'goal_id': 'g1', 'status': 'paused'});
    expect(workNotificationKind(bare), isNull);
    expect(isQuietNotification(bare), isFalse);
    // A new message is `notify` and still not quiet.
    final message = _item('message_received', {'notification_kind': 'notify'});
    expect(isQuietNotification(message), isFalse);
    expect(workNotificationKind(message), isNull);
    // Only a real `true` is quiet.
    expect(
      isQuietNotification(
        _item('goal_settled', {'notification_kind': 'notify', 'quiet': 'true'}),
      ),
      isFalse,
    );
    expect(
      isQuietNotification(
        _item('goal_settled', {'notification_kind': 'notify', 'quiet': true}),
      ),
      isTrue,
    );
  });

  test('the push routes the worker allows survive the connect redirect', () {
    // `cc_push_worker.js` `safeRoute` passes these; the router has
    // `/goals/:goalId`, `/schedules/:ruleId` and `/activity`, and a tap
    // while disconnected comes back through `return_to`.
    for (final route in [
      '/goals/g1?workspace_id=$ws',
      '/schedules/r1?workspace_id=$ws',
      '/activity?workspace_id=$ws',
    ]) {
      expect(safeRemoteReturn(route), route);
    }
  });

  test('improvement_proposed and pipeline_run_held open the conversation', () {
    final improvement = _item('improvement_proposed', {
      'space_id': 's1',
      'conversation_id': 'c1',
      'count': 2,
      'proposal_ids': ['p1', 'p2'],
    });
    expect(activityTitle(improvement, l), l.notifImprovementProposed(2));
    expect(
      activityDestination(improvement, const []),
      '/spaces/s1?workspace_id=$ws&conversation_id=c1',
    );
    final held = _item('pipeline_run_held', {
      'pipeline_run_id': 'p1',
      'reason': 'budget',
      'cap_micros': 5000000,
      'spent_micros': 5100000,
      'notification_kind': 'review',
    });
    expect(activityTitle(held, l), l.notifPipelineRunHeld);
    expect(workNotificationKind(held), WorkNotificationKind.review);
    expect(activityDestination(held, const []), isNull);
  });

  test('waiting_digest: each item opens its own record', () {
    final digest = _item('waiting_digest', {
      'day': '2026-11-20',
      'count': 4,
      'notification_kind': 'review',
      'items': [
        {'type': 'goal_review', 'id': 'g1', 'summary': 'Fix checkout'},
        {'type': 'goal_person', 'id': 'g2', 'summary': 'Pick a design'},
        {
          'type': 'held_wake',
          'id': 'w1',
          'summary': 'Paused run',
          'space_id': 's1',
          'conversation_id': 'c1',
        },
        {
          'type': 'improvement',
          'id': 'p1',
          'summary': 'A better prompt',
          'space_id': 's1',
          'conversation_id': 'c1',
        },
        {'type': 'something_new', 'id': 'x'},
      ],
    });
    expect(activityTitle(digest, l), l.notifWaitingDigest(4));
    expect(activityDestination(digest, const []), isNull);
    final items = digestItems(digest, l);
    expect(items.map((i) => i.label), [
      l.notifDigestGoalReview,
      l.notifDigestGoalPerson,
      l.notifDigestHeldWake,
      l.notifDigestImprovement,
    ]);
    expect(items.map((i) => i.location), [
      '/goals/g1?workspace_id=$ws',
      '/goals/g2?workspace_id=$ws',
      '/spaces/s1/progress?conversation_id=c1&workspace_id=$ws',
      '/spaces/s1?workspace_id=$ws&conversation_id=c1',
    ]);
  });

  test('other frames keep their mapping', () {
    final pr = _item('pr_ready_to_merge', {});
    expect(workNotificationKind(pr), isNull);
    expect(activityTitle(pr, l), l.activityPrReady);
  });

  Future<void> pumpCard(WidgetTester tester, NotificationFeedItem item) =>
      pumpWork(
        tester,
        ActivityItemCard(
          item: item,
          read: false,
          working: false,
          onOpen: () {},
          onToggleRead: () {},
          onDismiss: () {},
        ),
        overrides: workOverrides(rpc()),
      );

  testWidgets('a review frame carries the Needs you tag; a notify frame '
      'does not', (tester) async {
    await pumpCard(
      tester,
      _item('goal_settled', {
        'goal_id': 'g1',
        'status': 'paused',
        'hold': 'needs_review',
        'notification_kind': 'review',
        'summary': 'Claims **done**',
      }),
    );
    expect(find.text(l.notifNeedsYou), findsOneWidget);
    expect(find.text('Claims **done**'), findsOneWidget);

    await pumpCard(
      tester,
      _item('wake_rule_ended', {
        'rule_id': 'r1',
        'reason': 'run_cap',
        'notification_kind': 'notify',
        'quiet': true,
      }),
    );
    expect(find.text(l.notifNeedsYou), findsNothing);
    expect(find.text(l.wakeRuleEndRunCap), findsOneWidget);
  });

  testWidgets('an unread message marked notify still asks for attention; a '
      'terminal goal marked quiet does not', (tester) async {
    await pumpCard(
      tester,
      _item('message_received', {
        'space_id': 's1',
        'conversation_id': 'c1',
        'notification_kind': 'notify',
        'quiet': false,
      }),
    );
    expect(find.byIcon(AppIcons.triangleAlert), findsOneWidget);
    expect(find.byIcon(AppIcons.circleCheck), findsNothing);

    // An older frame without the field is not quiet either.
    await pumpCard(
      tester,
      _item('message_received', {'notification_kind': 'notify'}),
    );
    expect(find.byIcon(AppIcons.triangleAlert), findsOneWidget);

    await pumpCard(
      tester,
      _item('goal_settled', {
        'goal_id': 'g1',
        'status': 'completed',
        'notification_kind': 'notify',
        'quiet': true,
      }),
    );
    expect(find.byIcon(AppIcons.circleCheck), findsOneWidget);
    expect(find.byIcon(AppIcons.triangleAlert), findsNothing);
    expect(find.text(l.notifNeedsYou), findsNothing);
  });

  testWidgets('a digest lists its items, and an item opens its record', (
    tester,
  ) async {
    await pumpCard(
      tester,
      _item('waiting_digest', {
        'count': 1,
        'items': [
          {'type': 'goal_review', 'id': 'g1', 'summary': 'Fix checkout'},
        ],
      }),
    );
    expect(find.text('Fix checkout'), findsOneWidget);
    await tester.tap(find.text(l.notifDigestGoalReview));
    await tester.pumpAndSettle();
    expect(find.text('Opened /goals/g1?workspace_id=$ws'), findsOneWidget);
  });

  testWidgets('a request in the digest waits for an answer and opens its '
      'conversation', (tester) async {
    await pumpCard(
      tester,
      _item('waiting_digest', {
        'count': 1,
        'items': [
          {
            'type': 'request',
            'id': 'q1',
            'summary': 'May I push to main?',
            'space_id': 's1',
            'conversation_id': 'c1',
            'expires_at': '2026-11-23T09:00:00Z',
          },
        ],
      }),
    );
    expect(find.text('May I push to main?'), findsOneWidget);
    await tester.tap(find.text(l.notifDigestRequest));
    await tester.pumpAndSettle();
    expect(find.textContaining('Opened /spaces/s1'), findsOneWidget);
    expect(find.textContaining('conversation_id=c1'), findsOneWidget);
  });

  testWidgets('a held pipeline run shows its spend against the cap', (
    tester,
  ) async {
    await pumpCard(
      tester,
      _item('pipeline_run_held', {
        'pipeline_run_id': 'p1',
        'cap_micros': 5000000,
        'spent_micros': 5100000,
      }),
    );
    expect(
      find.text(l.notifPipelineRunHeldBody(r'$5.10', r'$5.00')),
      findsOneWidget,
    );
  });
}
