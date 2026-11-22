import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/core/notifications/work_notification_frames.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/app_localizations_en.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final AppLocalizations l10n = AppLocalizationsEn();

  AppNotification? map(String method, Map<String, dynamic> params) =>
      mapNotificationFrame(method, params, l10n: l10n);

  test('a settled goal opens its page; notify is quiet, review asks', () {
    final done = map('notifications/goal_settled', {
      'workspace_id': 'ws',
      'goal_id': 'g1',
      'status': 'completed',
      'notification_kind': 'notify',
      'quiet': true,
      'summary': 'Shipped\u001b[2J the **release**',
    })!;
    expect(done.title, 'Goal done');
    expect(done.body, 'Shipped [2J the **release**');
    expect(done.route, '/workspaces/ws/goals/g1');
    expect(done.category, NotificationCategory.agentRunCompleted);
    expect(done.presentation, NotificationPresentation.centerOnly);

    final review = map('notifications/goal_settled', {
      'workspace_id': 'ws',
      'goal_id': 'g1',
      'status': 'paused',
      'hold': 'needs_review',
      'notification_kind': 'review',
    })!;
    expect(review.title, 'A goal waits for your review');
    expect(review.category, NotificationCategory.agentAwaitingInput);
    expect(review.presentation, NotificationPresentation.notification);
  });

  test('quiet is only the server field; the kind never decides it', () {
    expect(isQuietFrame({'quiet': true}), isTrue);
    expect(
      isQuietFrame({'quiet': false, 'notification_kind': 'notify'}),
      isFalse,
    );
    expect(isQuietFrame({'notification_kind': 'notify'}), isFalse);
    expect(isQuietFrame({'quiet': 'true'}), isFalse);
    final loud = map('notifications/goal_settled', {
      'workspace_id': 'ws',
      'goal_id': 'g1',
      'status': 'completed',
      'notification_kind': 'notify',
      'quiet': false,
    })!;
    expect(loud.presentation, NotificationPresentation.notification);
  });

  test('every goal outcome has its title', () {
    String title(String status, [String? hold]) => map(
      'notifications/goal_settled',
      {'workspace_id': 'ws', 'goal_id': 'g', 'status': status, 'hold': ?hold},
    )!.title;
    expect(title('failed'), 'Goal failed');
    expect(title('cancelled'), 'Goal cancelled');
    expect(title('budget_exhausted'), 'Goal used its budget');
    expect(title('paused', 'person'), 'A goal needs you');
    expect(title('paused', 'limit'), 'A goal is on hold');
  });

  test('a schedule end opens the schedule', () {
    final n = map('notifications/wake_rule_ended', {
      'workspace_id': 'ws',
      'rule_id': 'r1',
      'notification_kind': 'notify',
    })!;
    expect(n.title, 'A schedule ended');
    expect(n.route, '/workspaces/ws/schedules/r1');
    expect(n.category, NotificationCategory.agentRunCompleted);
  });

  test('the digest opens the inbox and lists its first items', () {
    final n = map('notifications/waiting_digest', {
      'workspace_id': 'ws',
      'notification_kind': 'question',
      'count': 4,
      'items': [
        {'type': 'goal_review', 'id': 'g1', 'summary': 'Release goal'},
        {'type': 'improvement', 'id': 'p1', 'summary': 'Tighten the prompt'},
      ],
    })!;
    expect(n.title, '4 things wait for you');
    expect(n.body, 'Release goal\nTighten the prompt');
    expect(n.route, '/workspaces/ws/inbox');
    expect(
      waitingDigestItemRoute('ws', {'type': 'goal_review', 'id': 'g1'}),
      '/workspaces/ws/goals/g1',
    );
    expect(
      waitingDigestItemRoute('ws', {'type': 'improvement', 'id': 'p1'}),
      '/workspaces/ws/improvements/p1',
    );
    // A request (an approval or question of a run the server started) is
    // answered where it was asked: its conversation.
    expect(
      waitingDigestItemRoute('ws', {
        'type': 'request',
        'id': 'wait-1',
        'space_id': 's1',
        'conversation_id': 'c1',
        'expires_at': '2026-11-20T10:00:00.000Z',
      }),
      spaceRoute('ws', 's1', tab: conversationTabKey('c1')),
    );
    expect(
      waitingDigestItemRoute('ws', {'type': 'request', 'id': 'wait-2'}),
      '/workspaces/ws/inbox',
    );
  });

  test('proposals open the one proposal, or the list', () {
    final one = map('notifications/improvement_proposed', {
      'workspace_id': 'ws',
      'proposal_ids': ['p1'],
    })!;
    expect(one.title, 'An improvement was proposed');
    expect(one.route, '/workspaces/ws/improvements/p1');
    final many = map('notifications/improvement_proposed', {
      'workspace_id': 'ws',
      'proposal_ids': ['p1', 'p2'],
    })!;
    expect(many.title, '2 improvements were proposed');
    expect(many.route, '/workspaces/ws/improvements');
  });

  test('a held pipeline run opens its conversation, money in the body', () {
    final n = map('notifications/pipeline_run_held', {
      'workspace_id': 'ws',
      'space_id': 'sp',
      'conversation_id': 'c1',
      'spent_micros': 2500000,
      'cap_micros': 2000000,
    })!;
    expect(n.title, 'A pipeline run is held at its budget');
    expect(n.body, r'Spent $2.50 of $2.00');
    expect(n.route, startsWith('/workspaces/ws/spaces/sp'));
    expect(n.spaceId, 'sp');
  });

  test(
    'a frame without a workspace, or an unknown method, maps to nothing',
    () {
      expect(map('notifications/goal_settled', {'goal_id': 'g'}), isNull);
      expect(
        map('notifications/nothing_like_it', {'workspace_id': 'ws'}),
        isNull,
      );
    },
  );
}
