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
  });
}
