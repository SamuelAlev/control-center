import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('mapNotificationFrame', () {
    test('unknown methods (task lifecycle, ticket_reassigned) render null', () {
      expect(
        mapNotificationFrame(
          'notifications/task_failed',
          const {'workspace_id': 'ws-1'},
          l10n: l10n,
        ),
        isNull,
      );
      expect(
        mapNotificationFrame(
          'notifications/ticket_reassigned',
          const {'ticket_id': 't-1', 'workspace_id': 'ws-1'},
          l10n: l10n,
        ),
        isNull,
      );
    });

    test('maps pr_merged with workspace-scoped route', () {
      final n = mapNotificationFrame(
        'notifications/pr_merged',
        const {'pr_id': 'pr-1', 'agent_id': 'a-1', 'workspace_id': 'ws-1'},
        l10n: l10n,
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.prMerged);
      expect(n.workspaceId, 'ws-1');
      expect(n.route, contains('ws-1'));
    });

    test('message_received suppresses someone else\'s requested run '
        'but always notifies a mention', () {
      const base = {
        'channel_id': 'ch-1',
        'message_id': 'm-1',
        'sender_name': 'Bot',
        'content_preview': 'done',
        'workspace_id': 'ws-1',
        'is_agent_message': true,
      };

      // Someone else's run finishing is not mine — suppressed.
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          {...base, 'requested_by_user_id': 'other-user'},
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );

      // But an explicit @mention of me always notifies.
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          {
            ...base,
            'requested_by_user_id': 'other-user',
            'mentions': ['user:me'],
          },
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNotNull,
      );

      // Unknown identity degrades to notify, never silently drops.
      expect(
        mapNotificationFrame(
          'notifications/message_received',
          base,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('meeting_starting_soon is banner-class', () {
      final n = mapNotificationFrame(
        'notifications/meeting_starting_soon',
        const {
          'event_id': 'ev-1',
          'title': 'Standup',
          'start_time': '2026-08-16T10:00:00Z',
          'workspace_id': 'ws-1',
        },
        l10n: l10n,
      );
      expect(n!.presentation, NotificationPresentation.banner);
    });

    test('human ticket assignment pings only the assignee', () {
      const base = {
        'ticket_id': 't-1',
        'ticket_title': 'Fix the leak',
        'workspace_id': 'ws-1',
        'assignee_type': 'user',
        'assigned_agent_id': 'teammate',
      };
      expect(
        mapNotificationFrame(
          'notifications/ticket_assigned',
          base,
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );
      expect(
        mapNotificationFrame(
          'notifications/ticket_assigned',
          {...base, 'assigned_agent_id': 'me'},
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNotNull,
      );
    });

    test('a rig take-over is not reported back to whoever took it', () {
      const base = {
        'rig_id': 'rig-1',
        'workspace_id': 'ws-1',
        'held': true,
        'controller': 'user:me',
      };
      // I took the wheel — I know.
      expect(
        mapNotificationFrame(
          'notifications/rig_control_changed',
          base,
          l10n: l10n,
          currentUserId: 'me',
        ),
        isNull,
      );
      // Somebody else took it — that is exactly what I need to be told.
      final other = mapNotificationFrame(
        'notifications/rig_control_changed',
        {...base, 'controller': 'user:someone-else'},
        l10n: l10n,
        currentUserId: 'me',
      );
      expect(other, isNotNull);
      expect(other!.category, NotificationCategory.rigStatusChanged);
      // A rig has no destination of its own; the link lands on the
      // running-machine list.
      expect(other.route, '/workspaces/ws-1/settings/server/rigs');
      // Unknown identity degrades to notify, never a silently dropped machine
      // event.
      expect(
        mapNotificationFrame(
          'notifications/rig_control_changed',
          base,
          l10n: l10n,
        ),
        isNotNull,
      );
    });

    test('a rig control RELEASE is unfiltered (the event does not record '
        'who let go)', () {
      final n = mapNotificationFrame(
        'notifications/rig_control_changed',
        const {'rig_id': 'rig-1', 'workspace_id': 'ws-1', 'held': false},
        l10n: l10n,
        currentUserId: 'me',
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.rigStatusChanged);
    });

    test('a reap distinguishes a TTL expiry from an idle reclaim', () {
      final ttl = mapNotificationFrame(
        'notifications/rig_reaped',
        const {
          'rig_id': 'rig-1',
          'workspace_id': 'ws-1',
          'reason': 'ttlExpired',
        },
        l10n: l10n,
      );
      final idle = mapNotificationFrame(
        'notifications/rig_reaped',
        const {
          'rig_id': 'rig-1',
          'workspace_id': 'ws-1',
          'reason': 'idleTimeout',
        },
        l10n: l10n,
      );
      expect(ttl, isNotNull);
      expect(idle, isNotNull);
      expect(ttl!.body, isNot(idle!.body));
      expect(ttl.category, NotificationCategory.rigStatusChanged);
    });

    test('a rig that died under an agent renders as a failure', () {
      final n = mapNotificationFrame(
        'notifications/rig_closed',
        const {
          'rig_id': 'rig-1',
          'workspace_id': 'ws-1',
          'reason': 'backendFailure',
        },
        l10n: l10n,
      );
      expect(n, isNotNull);
      expect(n!.category, NotificationCategory.rigStatusChanged);
      expect(n.workspaceId, 'ws-1');
    });
  });
}
