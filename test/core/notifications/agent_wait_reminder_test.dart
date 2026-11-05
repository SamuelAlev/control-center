import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:control_center/core/notifications/agent_wait_reminder.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingPort implements NotificationPort {
  final List<AppNotification> shown = [];
  final List<String> withdrawn = [];

  @override
  void show(AppNotification notification) => shown.add(notification);

  @override
  void withdraw(NotificationWait wait) => withdrawn.add(wait.id);

  @override
  void dispose() {}
}

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  late _RecordingPort port;
  late bool appFocused;

  setUp(() {
    port = _RecordingPort();
    appFocused = false;
  });

  AgentWaitReminder createReminder(DateTime Function() now) =>
      AgentWaitReminder(
        port: port,
        render: (item) =>
            mapNotificationFrame(item.method, item.params, l10n: l10n),
        reminderTitle: l10n.notificationWaitReminder,
        isAppFocused: () => appFocused,
        clock: now,
      );

  NotificationFeedItem wait(
    String waitId, {
    required DateTime createdAt,
    String kind = 'approval',
    bool resolved = false,
    String method = agentAwaitingInputMethod,
  }) => NotificationFeedItem(
    id: 'row-$waitId',
    workspaceId: 'ws-1',
    method: method,
    params: {
      'workspace_id': 'ws-1',
      'space_id': 'sp-1',
      'wait_id': waitId,
      'kind': kind,
      'agent_name': 'engineer',
      'summary': 'Push to a Git remote',
      if (resolved) NotificationFeedItem.resolvedAtKey: '2026-11-04T10:00:00Z',
    },
    createdAt: createdAt,
  );

  test('re-raises an unanswered wait on schedule, as a reminder', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      final reminder = createReminder(now)
        ..update([wait('cf_1', createdAt: now())]);

      async.elapse(const Duration(minutes: 2, seconds: 59));
      expect(port.shown, isEmpty);

      async.elapse(const Duration(seconds: 1));
      final first = port.shown.single;
      expect(
        first.title,
        l10n.notificationWaitReminder(
          l10n.notificationAgentNeedsApproval('engineer'),
        ),
      );
      expect(first.body, 'Push to a Git remote');
      expect(first.wait?.id, 'cf_1');
      expect(first.wait?.approvable, isTrue);

      async.elapse(const Duration(minutes: 60));
      expect(
        port.shown,
        hasLength(kAgentWaitReminderSchedule.length),
        reason: 'One reminder per scheduled step, then silence.',
      );
      reminder.dispose();
    });
  });

  test('stops reminding and withdraws once the wait resolves', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      final created = now();
      final reminder = createReminder(now)
        ..update([wait('cf_1', createdAt: created)]);

      async.elapse(const Duration(minutes: 1));
      reminder.update([wait('cf_1', createdAt: created, resolved: true)]);
      expect(port.withdrawn, ['cf_1']);

      async.elapse(const Duration(minutes: 60));
      expect(port.shown, isEmpty);

      reminder.update([wait('cf_1', createdAt: created, resolved: true)]);
      expect(port.withdrawn, ['cf_1'], reason: 'Withdrawn once per session.');
      reminder.dispose();
    });
  });

  test('withdraws a wait that ended before this session saw it open', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      final reminder = createReminder(now)
        ..update([
          wait(
            'cf_old',
            createdAt: now().subtract(const Duration(hours: 2)),
            resolved: true,
          ),
        ]);
      expect(port.withdrawn, ['cf_old']);
      reminder.dispose();
    });
  });

  test('skips reminders while the app has focus, keeps the schedule', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      appFocused = true;
      final reminder = createReminder(now)
        ..update([wait('cf_1', createdAt: now())]);

      async.elapse(const Duration(minutes: 3));
      expect(port.shown, isEmpty);

      appFocused = false;
      async.elapse(const Duration(minutes: 7));
      expect(port.shown, hasLength(1));
      reminder.dispose();
    });
  });

  test('an old open wait resumes at its next step, without a burst', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      final reminder = createReminder(now)
        ..update([
          wait('cf_1', createdAt: now().subtract(const Duration(minutes: 12))),
        ]);

      async.elapse(const Duration(minutes: 1));
      expect(port.shown, isEmpty);

      // The 25-minute step is 13 minutes after the wait was 12 minutes old.
      async.elapse(const Duration(minutes: 12));
      expect(port.shown, hasLength(1));
      reminder.dispose();
    });
  });

  test('a wait that leaves the feed unresolved stops but is not withdrawn', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      final reminder = createReminder(now)
        ..update([wait('cf_1', createdAt: now())])
        // Switched to another workspace: its feed does not list this wait.
        ..update(const []);

      async.elapse(const Duration(minutes: 60));
      expect(port.shown, isEmpty);
      expect(port.withdrawn, isEmpty);
      reminder.dispose();
    });
  });

  test('reminds for questions too, and ignores other feed rows', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      final reminder = createReminder(now)
        ..update([
          wait('msg-1', createdAt: now(), kind: 'question'),
          wait(
            'x',
            createdAt: now(),
            method: 'notifications/agent_run_completed',
          ),
        ]);

      async.elapse(const Duration(minutes: 3));
      final shown = port.shown.single;
      expect(shown.wait?.id, 'msg-1');
      expect(shown.wait?.approvable, isFalse);
      reminder.dispose();
    });
  });

  test('dispose cancels pending reminders', () {
    fakeAsync((async) {
      final now = async.getClock(DateTime.utc(2026, 11, 4, 10)).now;
      createReminder(now)
        ..update([wait('cf_1', createdAt: now())])
        ..dispose();
      async.elapse(const Duration(minutes: 60));
      expect(port.shown, isEmpty);
    });
  });
}
